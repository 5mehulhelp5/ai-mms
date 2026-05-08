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
                $transportConfig['password'] = $this->_decrypt($cfg['password_encrypted']);
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

    private function _collectConfig()
    {
        $store   = Mage::app()->getStore();
        $storeId = $store->getId();

        $get = function ($path) use ($storeId) {
            return Mage::getStoreConfig($path, $storeId);
        };

        $passwordEncrypted = $get('smtppro/general/smtp_password');
        $passwordPlain     = $passwordEncrypted ? $this->_decrypt($passwordEncrypted) : '';

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
                'password_encrypted' => $passwordEncrypted,
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

    private function _decrypt($value)
    {
        try {
            return (string) Mage::helper('core')->decrypt($value);
        } catch (Exception $e) {
            return '';
        }
    }

    private function _emit(array $payload)
    {
        $this->getResponse()
            ->setHeader('Content-Type', 'application/json', true)
            ->setBody(json_encode($payload, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
    }
}
