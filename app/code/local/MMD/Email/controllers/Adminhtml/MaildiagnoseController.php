<?php
/**
 * Mail diagnostics — bypasses every silent try/catch in the SMTPPro stack
 * and reports what the SMTP transport actually does when asked to send.
 *
 * Visit:  /<frontName>/mmd_email_adminhtml_maildiagnose/index
 * Send:   /<frontName>/mmd_email_adminhtml_maildiagnose/send?to=you@example.com
 *
 * The "send" action constructs a Zend_Mail_Transport_Smtp directly using the
 * same config SMTPPro reads, so we see the exact connect/auth/handshake
 * errors instead of the swallowed exception that landed in var/log.
 */
class MMD_Email_Adminhtml_MaildiagnoseController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return true;
    }

    public function indexAction()
    {
        $this->_emit($this->_collectConfig());
    }

    /**
     * One-shot credential writer. The admin form save path is racy enough
     * across scope and cache that two attempts in a row can land on the
     * wrong row; this writes default-scope smtp_username + smtp_password
     * directly, encrypting under the running environment's key (so it
     * round-trips correctly through getStoreConfig later) and clears the
     * config cache.
     *
     *   /maildiagnose/setcreds?username=foo@bar&password=secret
     *
     * Returns the JSON the index action would return, after the write,
     * so you can see the new effective config in the same hop.
     */
    public function setcredsAction()
    {
        $username = trim((string) $this->getRequest()->getParam('username'));
        $password = (string) $this->getRequest()->getParam('password');

        if ($username === '' || $password === '') {
            $this->_emit(['error' => 'Pass ?username=<email>&password=<plain>']);
            return;
        }

        try {
            $encrypted = Mage::helper('core')->encrypt($password);
            $cfg = Mage::getConfig();
            $cfg->saveConfig('smtppro/general/smtp_username', $username, 'default', 0);
            $cfg->saveConfig('smtppro/general/smtp_password', $encrypted, 'default', 0);

            // Belt-and-suspenders: also wipe any website-1 overrides that may
            // have been re-introduced after migration 058.
            $write = Mage::getSingleton('core/resource')->getConnection('core_write');
            $table = Mage::getSingleton('core/resource')->getTableName('core/config_data');
            $write->delete($table, [
                'scope = ?'    => 'websites',
                'scope_id = ?' => 1,
                'path IN (?)'  => ['smtppro/general/smtp_username', 'smtppro/general/smtp_password'],
            ]);

            Mage::app()->getCacheInstance()->cleanType('config');
            Mage::app()->cleanCache();
        } catch (Exception $e) {
            $this->_emit(['error' => $e->getMessage(), 'exception' => get_class($e)]);
            return;
        }

        $report = $this->_collectConfig();
        $report['setcreds_result'] = 'OK — credentials saved at default scope and website-1 overrides cleared. Hit /send?to=... to verify.';
        $this->_emit($report);
    }

    public function sendAction()
    {
        $to = trim((string) $this->getRequest()->getParam('to'));
        $report = $this->_collectConfig();
        $report['send_test'] = ['to' => $to];

        if ($to === '' || !filter_var($to, FILTER_VALIDATE_EMAIL)) {
            $report['send_test']['error'] = 'Pass ?to=<valid email>';
            $this->_emit($report);
            return;
        }

        $cfg = $report['effective_config'];
        try {
            $transportConfig = ['port' => $cfg['port']];
            if ($cfg['authentication'] && $cfg['authentication'] !== 'none') {
                $transportConfig['auth']     = $cfg['authentication'];
                $transportConfig['username'] = $cfg['username'];
                $transportConfig['password'] = (string) Mage::getStoreConfig('smtppro/general/smtp_password');
            }
            if ($cfg['ssl'] && $cfg['ssl'] !== 'none') {
                $transportConfig['ssl'] = $cfg['ssl'];
            }

            $t0 = microtime(true);
            $transport = new Zend_Mail_Transport_Smtp($cfg['host'], $transportConfig);

            $mail = new Zend_Mail('utf-8');
            $mail->setFrom($cfg['from_email'], $cfg['from_name']);
            $mail->addTo($to);
            $mail->setSubject('MMD mail diagnostic ' . date('Y-m-d H:i:s'));
            $mail->setBodyText("If you're reading this, SMTP from the Coolify-hosted box reached your inbox.");
            $mail->send($transport);

            $report['send_test']['result']     = 'OK — accepted by ' . $cfg['host'] . ':' . $cfg['port'];
            $report['send_test']['elapsed_ms'] = round((microtime(true) - $t0) * 1000);
        } catch (Exception $e) {
            $report['send_test']['error']        = $e->getMessage();
            $report['send_test']['exception']    = get_class($e);
            $report['send_test']['trace_first']  = strtok($e->getTraceAsString(), "\n");
        }

        $this->_emit($report);
    }

    /**
     * Probe the same mail server's IMAP-over-TLS endpoint with the same
     * credentials that SMTP is using. cPanel/Exim hosts share one password
     * across SMTP, IMAP, POP3 and webmail, so this disambiguates "password
     * actually wrong" from "SMTP-only lockout / SMTP-disabled-for-mailbox".
     *
     *   /maildiagnose/imapauth
     *
     * IMAP OK   → password is correct; SMTP failure is server-side
     *             (cPHulk lockout, outgoing-mail disabled for mailbox).
     * IMAP fail → password Magento has does not match the mailbox.
     */
    public function imapauthAction()
    {
        $report = $this->_collectConfig();
        $cfg    = $report['effective_config'];
        $host   = (string) $cfg['host'];
        $user   = (string) $cfg['username'];
        $pass   = (string) Mage::getStoreConfig('smtppro/general/smtp_password');

        $report['imap_auth_test'] = ['host' => $host, 'username' => $user];

        if ($host === '' || $user === '' || $pass === '') {
            $report['imap_auth_test']['error'] = 'host / username / password missing';
            $this->_emit($report);
            return;
        }

        // Try implicit TLS on 993 first; if that doesn't connect, fall
        // back to plain 143 with STARTTLS-less LOGIN (cPanel allows it
        // when "secure connection" is disabled).
        $candidates = [
            ['scheme' => 'tls',  'port' => 993],
            ['scheme' => 'tcp',  'port' => 143],
        ];

        $attempts = [];
        foreach ($candidates as $c) {
            $endpoint = $c['scheme'] . '://' . $host . ':' . $c['port'];
            $t0 = microtime(true);
            $errno = 0; $errstr = '';
            $sock = @stream_socket_client($endpoint, $errno, $errstr, 5,
                STREAM_CLIENT_CONNECT,
                stream_context_create(['ssl' => ['verify_peer' => false, 'verify_peer_name' => false]])
            );
            if (!$sock) {
                $attempts[] = ['endpoint' => $endpoint, 'connect' => 'failed', 'error' => $errstr ?: ('errno ' . $errno)];
                continue;
            }
            stream_set_timeout($sock, 5);
            $banner = trim((string) fgets($sock, 1024));

            // IMAP LOGIN — quote any " or \ in user/pass per RFC 3501.
            $qUser = '"' . str_replace(['\\', '"'], ['\\\\', '\\"'], $user) . '"';
            $qPass = '"' . str_replace(['\\', '"'], ['\\\\', '\\"'], $pass) . '"';
            fwrite($sock, "a1 LOGIN {$qUser} {$qPass}\r\n");

            $loginResp = '';
            $deadline = microtime(true) + 5;
            while (microtime(true) < $deadline) {
                $line = fgets($sock, 4096);
                if ($line === false) break;
                $loginResp .= $line;
                if (preg_match('/^a1 (OK|NO|BAD)\b/m', $line)) break;
            }
            @fwrite($sock, "a2 LOGOUT\r\n");
            @fclose($sock);

            $verdict = 'unknown';
            if (preg_match('/^a1 OK\b/m',  $loginResp)) $verdict = 'accepted';
            if (preg_match('/^a1 NO\b/m',  $loginResp)) $verdict = 'rejected';
            if (preg_match('/^a1 BAD\b/m', $loginResp)) $verdict = 'bad_request';

            $attempts[] = [
                'endpoint'    => $endpoint,
                'banner'      => $banner,
                'login_reply' => trim($loginResp),
                'verdict'     => $verdict,
                'elapsed_ms'  => round((microtime(true) - $t0) * 1000),
            ];

            if ($verdict === 'accepted' || $verdict === 'rejected') break;
        }

        $report['imap_auth_test']['attempts'] = $attempts;
        $accepted = false;
        foreach ($attempts as $a) {
            if (isset($a['verdict']) && $a['verdict'] === 'accepted') { $accepted = true; break; }
        }
        $report['imap_auth_test']['interpretation'] = $accepted
            ? 'Password is correct mailbox-side. SMTP rejection is a server-side block (cPHulk lockout, or "outgoing mail" disabled for this mailbox in cPanel > Email Accounts > Restrictions).'
            : 'Password Magento is sending does not match the mailbox. Re-set the password in cPanel and re-enter the SAME value via /maildiagnose/setcreds.';

        $this->_emit($report);
    }

    private function _collectConfig()
    {
        $store   = Mage::app()->getStore();
        $storeId = $store->getId();

        $get = function ($path) use ($storeId) {
            return Mage::getStoreConfig($path, $storeId);
        };

        // getStoreConfig() auto-decrypts encrypted backend fields, so the
        // value here is already plaintext. Don't expose it — mask all but
        // the first and last char to confirm "we're sending something" without
        // leaking the actual secret to anyone who can hit /maildiagnose.
        $passwordPlain = (string) $get('smtppro/general/smtp_password');
        $passwordMasked = $this->_mask($passwordPlain);

        return [
            'now'             => date('c'),
            'magento_store'   => $store->getCode() . ' (id=' . $storeId . ', website=' . $store->getWebsite()->getCode() . ')',
            'php_version'     => PHP_VERSION,
            'effective_config' => [
                'option'             => $get('smtppro/general/option'),
                'host'               => $get('smtppro/general/smtp_host'),
                'port'               => $get('smtppro/general/smtp_port'),
                'ssl'                => $get('smtppro/general/smtp_ssl'),
                'authentication'     => $get('smtppro/general/smtp_authentication'),
                'username'           => $get('smtppro/general/smtp_username'),
                'password_length'    => strlen($passwordPlain),
                'password_masked'    => $passwordMasked,
                'from_email'         => $get('trans_email/ident_sales/email'),
                'from_name'          => $get('trans_email/ident_sales/name'),
                'queue_usage'        => $get('smtppro/queue/usage'),
            ],
            'connect_test'    => $this->_tryConnect($get('smtppro/general/smtp_host'), (int) $get('smtppro/general/smtp_port')),
            'core_email_queue' => $this->_queueSnapshot(),
            'note'             => 'Hit /send?to=<email> to send a real test message. Errors will be shown here verbatim.',
        ];
    }

    private function _tryConnect($host, $port)
    {
        if (!$host || !$port) {
            return ['status' => 'skipped', 'reason' => 'no host/port configured'];
        }
        $t0 = microtime(true);
        $errno = 0;
        $errstr = '';
        $sock = @fsockopen($host, $port, $errno, $errstr, 5);
        $elapsed = round((microtime(true) - $t0) * 1000);
        if (!$sock) {
            return ['status' => 'failed', 'errno' => $errno, 'error' => $errstr, 'elapsed_ms' => $elapsed];
        }
        $banner = '';
        stream_set_timeout($sock, 3);
        $banner = (string) fgets($sock, 1024);
        @fclose($sock);
        return ['status' => 'ok', 'banner' => trim($banner), 'elapsed_ms' => $elapsed];
    }

    private function _queueSnapshot()
    {
        try {
            $read = Mage::getSingleton('core/resource')->getConnection('core_read');
            $table = Mage::getSingleton('core/resource')->getTableName('core/email_queue');
            $row = $read->fetchRow(
                "SELECT
                    COUNT(*) total,
                    SUM(processed_at IS NULL) unsent,
                    MAX(created_at) last_created,
                    MAX(processed_at) last_processed
                 FROM {$table}"
            );
            return $row ?: ['note' => 'queue table empty'];
        } catch (Exception $e) {
            return ['error' => $e->getMessage()];
        }
    }

    private function _mask($value)
    {
        $len = strlen($value);
        if ($len === 0) {
            return '';
        }
        if ($len <= 2) {
            return str_repeat('*', $len);
        }
        return $value[0] . str_repeat('*', $len - 2) . $value[$len - 1];
    }

    private function _emit(array $payload)
    {
        $this->getResponse()
            ->setHeader('Content-Type', 'application/json', true)
            ->setBody(json_encode($payload, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
    }
}
