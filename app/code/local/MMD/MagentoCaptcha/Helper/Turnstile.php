<?php
/**
 * Cloudflare Turnstile verifier — replaces Google reCAPTCHA v2 on the
 * Contact Us and Review forms.
 *
 * Keys live in environment variables (TURNSTILE_SITE_KEY / TURNSTILE_SECRET_KEY),
 * propagated to the container by docker-compose locally and by the Coolify
 * environment-variables panel in production. We don't store them in
 * core_config_data because keys are short-lived and project-scoped — keeping
 * them next to R2_* in .env / Coolify makes rotation a single-place change.
 *
 * Fail-open when not configured: in dev environments without keys, verify()
 * returns ok=true so the form keeps working. Production has the keys set, so
 * any genuine verification failure surfaces as an error (no silent accept).
 */
class MMD_MagentoCaptcha_Helper_Turnstile extends Mage_Core_Helper_Abstract
{
    const VERIFY_URL    = 'https://challenges.cloudflare.com/turnstile/v0/siteverify';
    const TOKEN_FIELD   = 'cf-turnstile-response';
    const LOG_FILE      = 'turnstile.log';

    public function getSiteKey()
    {
        return trim((string) getenv('TURNSTILE_SITE_KEY'));
    }

    public function getSecretKey()
    {
        return trim((string) getenv('TURNSTILE_SECRET_KEY'));
    }

    public function isConfigured()
    {
        return $this->getSiteKey() !== '' && $this->getSecretKey() !== '';
    }

    /**
     * Verify a Turnstile response token. Returns:
     *   ['ok' => true]                                — verified, or not configured
     *   ['ok' => false, 'reason' => 'missing-token']  — empty / non-string token
     *   ['ok' => false, 'reason' => 'verify-failed', 'codes' => [...]]
     *
     * @param string|null $token     Value of the `cf-turnstile-response` POST field
     * @param string|null $remoteIp  Visitor IP, attached to the verify request
     * @return array
     */
    public function verify($token, $remoteIp = null)
    {
        if (!$this->isConfigured()) {
            Mage::log('Turnstile not configured — accepting submission (fail-open)', null, self::LOG_FILE, true);
            return array('ok' => true);
        }

        if (!is_string($token) || trim($token) === '') {
            Mage::log('Turnstile rejected: missing token', null, self::LOG_FILE, true);
            return array('ok' => false, 'reason' => 'missing-token');
        }

        $body = http_build_query(array(
            'secret'   => $this->getSecretKey(),
            'response' => $token,
            'remoteip' => $remoteIp ?: '',
        ));

        $ch = curl_init(self::VERIFY_URL);
        curl_setopt_array($ch, array(
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => $body,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 10,
            CURLOPT_CONNECTTIMEOUT => 5,
            CURLOPT_HTTPHEADER     => array('Content-Type: application/x-www-form-urlencoded'),
        ));
        $raw  = curl_exec($ch);
        $http = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err  = curl_error($ch);
        curl_close($ch);

        if ($raw === false || $raw === '') {
            Mage::log('Turnstile verify unreachable: ' . ($err ?: 'no response') . ' (http=' . $http . ')', null, self::LOG_FILE, true);
            return array('ok' => false, 'reason' => 'verify-failed', 'codes' => array('network-error'));
        }

        $data = json_decode($raw, true);
        if (!is_array($data)) {
            Mage::log('Turnstile verify returned non-JSON: ' . substr($raw, 0, 200), null, self::LOG_FILE, true);
            return array('ok' => false, 'reason' => 'verify-failed', 'codes' => array('bad-response'));
        }

        if (!empty($data['success'])) {
            Mage::log('Turnstile verified ok (hostname=' . (isset($data['hostname']) ? $data['hostname'] : '?') . ')', null, self::LOG_FILE, true);
            return array('ok' => true);
        }

        $codes = isset($data['error-codes']) && is_array($data['error-codes']) ? $data['error-codes'] : array();
        Mage::log('Turnstile rejected: ' . implode(',', $codes), null, self::LOG_FILE, true);
        return array('ok' => false, 'reason' => 'verify-failed', 'codes' => $codes);
    }

    /**
     * Best-effort visitor IP. Cloudflare-fronted requests carry
     * CF-Connecting-IP; otherwise fall back to X-Forwarded-For / REMOTE_ADDR.
     */
    public function getRemoteIp()
    {
        $candidates = array(
            'HTTP_CF_CONNECTING_IP',
            'HTTP_X_FORWARDED_FOR',
            'HTTP_X_REAL_IP',
            'REMOTE_ADDR',
        );
        foreach ($candidates as $k) {
            if (!empty($_SERVER[$k])) {
                $ip = $_SERVER[$k];
                if ($k === 'HTTP_X_FORWARDED_FOR') {
                    $ip = trim(explode(',', $ip)[0]);
                }
                return $ip;
            }
        }
        return null;
    }
}
