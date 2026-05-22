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
        $data = $this->_getCached('campaigns_ready', function () {
            return $this->_getJson('/campaigns?filter[status]=ready&limit=20');
        });
        if (!is_array($data) || empty($data['data'])) {
            return null;
        }
        $best = null;
        $bestTs = PHP_INT_MAX;
        foreach ($data['data'] as $c) {
            $when = isset($c['scheduled_for']) ? (string)$c['scheduled_for'] : '';
            if ($when === '') continue;
            $ts = strtotime($when);
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
            Mage::log('MailerLite ' . $path . ' http=' . $code . ' err=' . $err, null, 'mailerlite.log', true);
            return null;
        }
        $data = json_decode($raw, true);
        return is_array($data) ? $data : null;
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
