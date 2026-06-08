<?php
/**
 * LMS-TMS course-runs fetcher (read-only fallback source for trainer reminders).
 *
 * The WhatsApp trainer-reminders bot hits /courses/api_reminders?target_date=X
 * to pull "which trainer is teaching which class on date X". The primary
 * source is MMS course_runs (with Phase 2 admin_user-account trainers and
 * legacy EAV-option trainers). LMS-TMS is the secondary source — used when:
 *
 *  (a) MMS knows about the class but has no trainer assigned, OR
 *  (b) LMS knows about a class on that date that MMS doesn't track at all.
 *
 * In both cases we use the LMS-assigned trainer name + email so the bot can
 * still send a reminder. Reuses the same LMS-TMS API credentials already
 * configured for the roster import (mmd/trainer_import/lms_url + api_key).
 *
 * Read-only. No writes. Failure is non-fatal — if LMS is unreachable the
 * caller gets an empty result and continues with MMS-only data.
 */
class MMD_Courses_Model_LmsTmsCourseRun
{
    const URL_CONFIG_PATH  = 'mmd/trainer_import/lms_url';
    const KEY_CONFIG_PATH  = 'mmd/trainer_import/api_key';
    const CACHE_TAG        = 'MMD_LMS_TMS_COURSE_RUNS';
    const CACHE_TTL_SECS   = 300;        // 5 minutes
    const PAGE_LIMIT       = 200;        // ask for 200 per page
    const MAX_PAGES        = 5;          // safety cap → max 1000 rows per date
    const LOG_FILE         = 'lms-tms-fallback.log';

    /** Was the last call attempted, succeeded, returned data? Filled by getRunsByDate(). */
    protected $_lastAttempted    = false;
    protected $_lastSuccess      = false;
    protected $_lastErrorMessage = '';
    protected $_lastTotalRows    = 0;

    public function isConfigured()
    {
        return $this->_url() !== '' && $this->_key() !== '';
    }

    /** Last-call diagnostic snapshot, surfaced into the API's fallback_check block. */
    public function getLastCallStats()
    {
        return array(
            'attempted'    => $this->_lastAttempted,
            'success'      => $this->_lastSuccess,
            'rows_returned'=> (int) $this->_lastTotalRows,
            'error'        => $this->_lastErrorMessage,
            'configured'   => $this->isConfigured(),
        );
    }

    /**
     * Fetch all course-runs on the given date from LMS-TMS, paginated.
     * Returns an array keyed by course_code (the SKU, e.g. TGS-2020505444 or
     * M1860), each value normalised:
     *
     *   [
     *     'name'              => 'Ken Hiong',
     *     'email'             => 'hiongken@gmail.com',
     *     'course_title'      => '...',
     *     'mode'              => 'Physical' | 'Online' | 'Hybrid' | '',
     *     'lms_course_run_id' => '1068286',
     *     'lms_course_run_uuid'=>'93562a7b-…',
     *     'enrolled_count'    => 7,
     *     'class_status'      => 'Confirmed',
     *   ]
     *
     * Rows without an assigned_trainer_email are dropped — there's no
     * reminder to send if we don't know who to remind.
     *
     * Returns [] on any error (network, auth, JSON), and stashes the error
     * for the caller to surface in the diagnostic.
     *
     * @param string $date YYYY-MM-DD
     * @return array<string, array>
     */
    public function getRunsByDate($date)
    {
        $this->_lastAttempted    = true;
        $this->_lastSuccess      = false;
        $this->_lastErrorMessage = '';
        $this->_lastTotalRows    = 0;

        $date = trim((string) $date);
        if ($date === '' || !preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) {
            $this->_lastErrorMessage = 'invalid_date_param';
            return array();
        }

        if (!$this->isConfigured()) {
            // Silent no-op: LMS-TMS just isn't wired in this env. Not an error.
            $this->_lastAttempted    = false;
            $this->_lastErrorMessage = 'not_configured';
            return array();
        }

        // Short-cache per date to avoid N hits within one bot poll window.
        $cacheKey = 'mmd_lms_tms_runs_' . md5($date);
        $cache    = Mage::app()->getCache();
        $cached   = $cache->load($cacheKey);
        if ($cached !== false) {
            $decoded = @unserialize($cached);
            if (is_array($decoded)) {
                $this->_lastSuccess   = true;
                $this->_lastTotalRows = count($decoded);
                return $decoded;
            }
        }

        $all = array();
        try {
            $offset = 0;
            for ($page = 0; $page < self::MAX_PAGES; $page++) {
                $rows = $this->_fetchPage($date, $offset, self::PAGE_LIMIT);
                if (empty($rows)) {
                    break;
                }
                foreach ($rows as $r) {
                    $code   = trim((string) ($r['course_code'] ?? ''));
                    $email  = trim((string) ($r['assigned_trainer_email'] ?? ''));
                    $name   = trim((string) ($r['assigned_trainer_name']  ?? ''));
                    $status = trim((string) ($r['class_status'] ?? ''));
                    if ($code === '' || $email === '') {
                        continue; // no SKU to match on, or no trainer to remind
                    }
                    // Only "Confirmed" classes get reminders. Drops Cancelled,
                    // Postponed, Pending, Tentative, etc. — bot must never tell
                    // a trainer "your class is tomorrow" if LMS says it isn't.
                    if (strcasecmp($status, 'Confirmed') !== 0) {
                        continue;
                    }
                    // First-write-wins so if LMS returns duplicate course_codes
                    // (multiple runs on same date — rare) we keep the first.
                    if (!isset($all[$code])) {
                        $all[$code] = array(
                            'name'                => $name,
                            'email'               => $email,
                            'course_title'        => (string) ($r['course_title'] ?? ''),
                            'mode'                => (string) ($r['mode_of_learning'] ?? ''),
                            'lms_course_run_id'   => (string) ($r['course_run_id']   ?? ''),
                            'lms_course_run_uuid' => (string) ($r['course_run_uuid'] ?? ''),
                            'enrolled_count'      => (int)    ($r['enrolled_count']  ?? 0),
                            'class_status'        => (string) ($r['class_status']    ?? ''),
                        );
                    }
                }
                if (count($rows) < self::PAGE_LIMIT) {
                    break; // last page
                }
                $offset += self::PAGE_LIMIT;
            }

            $this->_lastSuccess   = true;
            $this->_lastTotalRows = count($all);

            // Cache only on success. Tag so a future admin "flush" can purge.
            $cache->save(serialize($all), $cacheKey, array(self::CACHE_TAG), self::CACHE_TTL_SECS);

        } catch (Exception $e) {
            $this->_lastErrorMessage = $e->getMessage();
            $this->_log('getRunsByDate(' . $date . ') failed: ' . $e->getMessage());
        }

        return $all;
    }

    /**
     * Fetch one page from the LMS course-runs endpoint. Returns array of raw
     * row arrays (un-normalised). Throws on transport / auth failure.
     */
    protected function _fetchPage($date, $offset, $limit)
    {
        $url  = $this->_url() . '/api/external/course-runs?date=' . rawurlencode($date)
              . '&offset=' . (int) $offset . '&limit=' . (int) $limit;
        $ch   = curl_init($url);
        curl_setopt_array($ch, array(
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 15,
            CURLOPT_CONNECTTIMEOUT => 5,
            CURLOPT_HTTPHEADER     => array('x-api-key: ' . $this->_key(), 'Accept: application/json'),
        ));
        $raw  = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err  = curl_error($ch);
        curl_close($ch);

        if ($raw === false || $raw === '') {
            throw new Exception('LMS unreachable: ' . ($err ?: 'no response'));
        }
        if ($code >= 400) {
            throw new Exception('LMS HTTP ' . $code . ': ' . substr($raw, 0, 200));
        }
        $rsp = json_decode($raw, true);
        if (!is_array($rsp) || empty($rsp['success'])) {
            $msg = is_array($rsp) && isset($rsp['error']) ? (string) $rsp['error'] : 'bad envelope';
            throw new Exception('LMS error: ' . $msg);
        }
        return isset($rsp['data']) && is_array($rsp['data']) ? $rsp['data'] : array();
    }

    protected function _url()
    {
        return rtrim(trim((string) Mage::getStoreConfig(self::URL_CONFIG_PATH)), '/');
    }

    protected function _key()
    {
        return trim((string) Mage::getStoreConfig(self::KEY_CONFIG_PATH));
    }

    protected function _log($msg)
    {
        Mage::log('[lms-tms-fallback] ' . $msg, Zend_Log::INFO, self::LOG_FILE, true);
    }
}
