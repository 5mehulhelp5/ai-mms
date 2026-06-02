<?php
/**
 * Thin wrapper over the MailerLite REST API for the Marketing Dashboard
 * KPI tiles. Each method returns scalar / small-array data that the
 * dashboard template renders directly.
 *
 * Bearer key is sourced from MMD_RoleManager_Helper_Data::getMarketingApiConfig()
 * which already resolves the Credentials-page-saved value (config path
 * mmd_marketing/api/mailerlite_key).
 *
 * Responses are cached in Magento's core/cache backend for 300s so the
 * dashboard render doesn't make 4 HTTP round-trips on every page load.
 *
 * If the key is missing or any call fails the helper returns a sentinel
 * (null / 0 / empty array) so the tiles fall back to "—" placeholders —
 * the page must never fatal because of a network blip.
 */
class MMD_Marketing_Helper_Mailerlite extends Mage_Core_Helper_Abstract
{
    const API_BASE        = 'https://connect.mailerlite.com/api';
    const CACHE_TTL       = 300;   // 5 min
    const CACHE_TAG       = 'MMD_MARKETING_MAILERLITE';
    // MailerLite group IDs (one MailerLite account, two country groups).
    // Update here if a group is renamed/recreated; readable via
    // GET /api/groups with the saved key.
    const GROUP_ID_SG     = '97171109342873057';
    const GROUP_ID_MY     = '97171116217337309';

    protected $_keyChecked = false;
    protected $_key        = '';

    public function isConfigured()
    {
        return $this->_getKey() !== '';
    }

    public function getSubscribersSG()
    {
        return $this->getGroupSubscriberCount(self::GROUP_ID_SG);
    }

    public function getSubscribersMY()
    {
        return $this->getGroupSubscriberCount(self::GROUP_ID_MY);
    }

    /**
     * Active subscriber count for a given group.
     *
     * MailerLite's /groups response includes an active_count integer per row,
     * so one /groups call gives us both countries — cheaper than two
     * /groups/{id} round-trips.
     *
     * @return int|null  null if not configured / API failure
     */
    public function getGroupSubscriberCount($groupId)
    {
        $groups = $this->_getCached('groups_index', function () {
            return $this->_getJson('/groups?limit=100');
        });
        if (!is_array($groups) || empty($groups['data'])) {
            return null;
        }
        foreach ($groups['data'] as $g) {
            if ((string)$g['id'] === (string)$groupId) {
                return isset($g['active_count']) ? (int) $g['active_count'] : 0;
            }
        }
        return 0;
    }

    /**
     * Number of campaigns with status "sent" delivered in the last 30 days.
     *
     * @return int|null
     */
    public function getCampaignsSentLast30Days()
    {
        $data = $this->_getCached('campaigns_sent', function () {
            return $this->_getJson('/campaigns?filter[status]=sent&limit=100');
        });
        if (!is_array($data) || empty($data['data'])) {
            return ($data === null) ? null : 0;
        }
        $since = strtotime('-30 days');
        $count = 0;
        foreach ($data['data'] as $c) {
            $ts = isset($c['finished_at']) ? strtotime((string)$c['finished_at']) : null;
            if (!$ts && isset($c['created_at'])) $ts = strtotime((string)$c['created_at']);
            if ($ts && $ts >= $since) $count++;
        }
        return $count;
    }

    /**
     * Next scheduled / ready campaign — earliest scheduled_for in the future.
     * Returns ['name'=>..., 'scheduled_for'=>'YYYY-MM-DD HH:MM:SS UTC'] or null.
     *
     * MailerLite uses "ready" for campaigns that have a scheduled send time
     * and "draft" for unscheduled drafts. We surface "ready" only.
     *
     * @return array|null
     */
    public function getNextCampaign()
    {
        // limit must be one of MailerLite's allowed values; 20 (and 15)
        // are rejected with HTTP 422 "The selected limit is invalid."
        // Allowed: 10, 25, 50, 100. We use 25 here — enough headroom
        // to find the soonest upcoming campaign without paging.
        $data = $this->_getCached('campaigns_ready', function () {
            return $this->_getJson('/campaigns?filter[status]=ready&limit=25');
        });
        if (!is_array($data) || empty($data['data'])) {
            return null;
        }
        // MailerLite returns scheduled_for as a naive UTC timestamp.
        // PHP's strtotime() interprets naive strings in the runtime's
        // default TZ — Asia/Singapore here — which would shift a UTC
        // timestamp 8 hours into the past, causing the "in the future?"
        // check to drop legitimately-upcoming campaigns. Parse with an
        // explicit UTC zone so the comparison is honest.
        $best = null;
        $bestTs = PHP_INT_MAX;
        $utc = new DateTimeZone('UTC');
        foreach ($data['data'] as $c) {
            $when = isset($c['scheduled_for']) ? (string)$c['scheduled_for'] : '';
            if ($when === '') continue;
            try {
                $ts = (new DateTime($when, $utc))->getTimestamp();
            } catch (Exception $e) {
                continue;
            }
            if (!$ts || $ts < time()) continue;
            if ($ts < $bestTs) {
                $bestTs = $ts;
                $best = array(
                    'name'          => (string) ($c['name'] ?? 'Unnamed'),
                    'scheduled_for' => $when,
                    'subject'       => (string) ($c['emails'][0]['subject'] ?? ''),
                );
            }
        }
        return $best;
    }

    // ---------- internal ----------

    protected function _getKey()
    {
        if (!$this->_keyChecked) {
            $this->_keyChecked = true;
            try {
                $cfg = Mage::helper('mmd_rolemanager')->getMarketingApiConfig();
                $this->_key = isset($cfg['mailerlite_key']) ? trim((string)$cfg['mailerlite_key']) : '';
            } catch (Exception $e) {
                // Fallback: read the config path directly.
                $this->_key = trim((string) Mage::getStoreConfig('mmd_marketing/api/mailerlite_key'));
            }
        }
        return $this->_key;
    }

    protected function _getJson($path)
    {
        $key = $this->_getKey();
        if ($key === '') {
            return null;
        }
        $ch = curl_init(self::API_BASE . $path);
        curl_setopt_array($ch, array(
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 12,
            CURLOPT_CONNECTTIMEOUT => 5,
            CURLOPT_HTTPHEADER     => array(
                'Authorization: Bearer ' . $key,
                'Accept: application/json',
            ),
        ));
        $raw  = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err  = curl_error($ch);
        curl_close($ch);

        if ($raw === false || $raw === '' || $code < 200 || $code >= 300) {
            // Mage::log silently drops writes to non-default log files
            // when dev/log/allowedFileExtensions is empty (OpenMage default
            // on this install). Write directly so a future bug like "the
            // limit param was wrong" is visible immediately, not a silent
            // null return.
            @file_put_contents(
                Mage::getBaseDir('var') . '/log/mailerlite.log',
                '[' . date('Y-m-d H:i:s') . '] '
              . 'MailerLite GET ' . $path . ' http=' . $code
              . ' err=' . $err . ' body=' . substr((string) $raw, 0, 600) . "\n",
                FILE_APPEND
            );
            return null;
        }
        $data = json_decode($raw, true);
        return is_array($data) ? $data : null;
    }

    /**
     * Fetch open / click stats for a single campaign.
     *
     * MailerLite returns stats inside data.stats with both raw counts and
     * pre-formatted percentage strings:
     *   stats.opens_count, stats.unique_opens_count,
     *   stats.open_rate.{float,string}
     *   stats.clicks_count, stats.unique_clicks_count,
     *   stats.click_rate.{float,string}
     *
     * Stats only populate meaningfully once a campaign is sent — drafts
     * and ready campaigns return zeros / empty strings.
     *
     * Cached 10 minutes per id under the CACHE_TAG so the dashboard
     * doesn't hammer MailerLite on every render.
     *
     * Returns array with normalised keys, or null when no key / failure.
     */
    public function getCampaignAnalytics($campaignId)
    {
        $campaignId = trim((string) $campaignId);
        if ($campaignId === '') return null;
        return $this->_getCached('campaign_' . $campaignId, function () use ($campaignId) {
            $rsp = $this->_getJson('/campaigns/' . urlencode($campaignId));
            if (!is_array($rsp) || !isset($rsp['data'])) return null;
            $d = $rsp['data'];
            $s = isset($d['stats']) && is_array($d['stats']) ? $d['stats'] : array();
            return array(
                'status'     => isset($d['status']) ? (string) $d['status'] : '',
                'opens'      => isset($s['opens_count'])  ? (int) $s['opens_count']  : null,
                'clicks'     => isset($s['clicks_count']) ? (int) $s['clicks_count'] : null,
                'open_rate'  => isset($s['open_rate']['string'])  ? (string) $s['open_rate']['string']  : '',
                'click_rate' => isset($s['click_rate']['string']) ? (string) $s['click_rate']['string'] : '',
            );
        });
    }

    /**
     * Schedule an existing draft campaign to send at $sendAt (Y-m-d H:i:s
     * in server-local time). MailerLite Connect endpoint:
     *   POST /api/campaigns/{id}/schedule
     *   body: { delivery_schedule: 'scheduled', schedule: { date, hours, minutes } }
     *
     * Returns true on success, false on any failure (the campaign still
     * exists, the admin can schedule it manually in MailerLite).
     */
    public function scheduleCampaign($campaignId, $sendAt)
    {
        $campaignId = trim((string) $campaignId);
        if ($campaignId === '' || $sendAt === '') return false;
        // $sendAt is server-local — convert to UTC because MailerLite
        // Connect interprets the schedule's date/hours/minutes as UTC.
        // Sending "07:00" while the server is Asia/Singapore (+8) reaches
        // MailerLite as UTC 07:00 which is local 15:00 the same day —
        // and if we'd skipped the conversion in the other direction it
        // would land in the past and 422.
        $ts = strtotime($sendAt);
        if (!$ts) return false;
        // MailerLite Connect API interprets schedule.date/hours/minutes in
        // the SENDING ACCOUNT's timezone — Asia/Singapore for this account.
        // Mage::app() forces PHP's default timezone to UTC, so we can't
        // just use date(); convert via DateTime with an explicit zone.
        // Without this MailerLite returns 422 "Please select time in the
        // future" even for far-future timestamps.
        try {
            $dt = new DateTime('@' . $ts);
            $dt->setTimezone(new DateTimeZone('Asia/Singapore'));
        } catch (Exception $e) {
            return false;
        }
        $payload = array(
            'delivery'  => 'scheduled',
            'schedule'  => array(
                'date'    => $dt->format('Y-m-d'),
                'hours'   => (int) $dt->format('G'),
                'minutes' => (int) $dt->format('i'),
            ),
        );
        $result = $this->_sendJson('/campaigns/' . urlencode($campaignId) . '/schedule', 'POST', $payload);
        return $result !== null;
    }

    /**
     * Cache-busting helper used by the dashboard "Refresh analytics"
     * button. Drops every entry under our cache tag so the next render
     * pulls fresh data from MailerLite.
     */
    public function clearAnalyticsCache()
    {
        $cache = Mage::app()->getCache();
        if ($cache) {
            $cache->clean(Zend_Cache::CLEANING_MODE_MATCHING_TAG, array(self::CACHE_TAG));
        }
    }

    /**
     * POST / PATCH / PUT a JSON body to a MailerLite endpoint. Mirrors
     * _getJson but allows specifying the method + payload. Returns the
     * decoded response array on 2xx, null otherwise (also logs).
     */
    protected function _sendJson($path, $method, array $payload)
    {
        $key = $this->_getKey();
        if ($key === '') return null;
        $ch = curl_init(self::API_BASE . $path);
        $opts = array(
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 20,
            CURLOPT_CONNECTTIMEOUT => 5,
            CURLOPT_POSTFIELDS     => json_encode($payload),
            CURLOPT_HTTPHEADER     => array(
                'Authorization: Bearer ' . $key,
                'Content-Type: application/json',
                'Accept: application/json',
            ),
        );
        if (strtoupper($method) === 'POST') {
            $opts[CURLOPT_POST] = true;
        } else {
            $opts[CURLOPT_CUSTOMREQUEST] = strtoupper($method);
        }
        curl_setopt_array($ch, $opts);
        $raw  = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err  = curl_error($ch);
        curl_close($ch);
        if ($raw === false || $code < 200 || $code >= 300) {
            @file_put_contents(
                Mage::getBaseDir('var') . '/log/mailerlite.log',
                '[' . date('Y-m-d H:i:s') . '] '
              . 'MailerLite ' . $method . ' ' . $path . ' http=' . $code
              . ' err=' . $err . ' body=' . substr((string) $raw, 0, 600) . "\n",
                FILE_APPEND
            );
            return null;
        }
        $data = json_decode($raw, true);
        return is_array($data) ? $data : array();
    }

    protected function _getCached($cacheKey, $cb)
    {
        $fullKey = self::CACHE_TAG . '_' . $cacheKey;
        $cache   = Mage::app()->getCache();
        $cached  = $cache ? $cache->load($fullKey) : false;
        if ($cached !== false && $cached !== '') {
            $decoded = @unserialize($cached);
            if ($decoded !== false || $cached === serialize(false)) {
                return $decoded;
            }
        }
        $val = $cb();
        if ($val !== null && $cache) {
            $cache->save(serialize($val), $fullKey, array(self::CACHE_TAG), self::CACHE_TTL);
        }
        return $val;
    }
}
