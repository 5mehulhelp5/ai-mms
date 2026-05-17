<?php
/**
 * Zend_Mail transport that ships the message over Gmail's REST API
 * instead of opening an SMTP socket.
 *
 * The Coolify container can reach Google (HTTPS) but cannot reliably
 * reach our legacy SMTP relays from every region — that's why every
 * non-SG store was silently dropping order/invoice/shipment mail.
 * Hooking this transport in via SMTPPro's `before_send` events makes
 * the OAuth2 path that already works for MMD_Email's custom
 * registration confirmation cover *every* transactional email.
 *
 * Recipients and the full RFC 2822 message are taken straight from the
 * Zend_Mail instance, so anything Zend_Mail produces (multiple TOs,
 * CC/BCC, attachments, multipart bodies) reaches Gmail intact.
 */
class MMD_Email_Model_Transport_Gmail extends Zend_Mail_Transport_Abstract
{
    /** @var int|null Resolved at construct-time so per-store OAuth overrides apply. */
    protected $_storeId;

    public function __construct($storeId = null)
    {
        $this->_storeId = $storeId;
    }

    /**
     * Called by Zend_Mail::send() after headers + body have been built.
     * $this->header and $this->body are the prepared RFC 2822 sections.
     */
    protected function _sendMail()
    {
        $helper = Mage::helper('mmd_email/gmail');
        if (!$helper || !$helper->isConfigured()) {
            // Caller should have checked isConfigured before installing
            // this transport; failing loud here is better than silently
            // dropping the message.
            throw new Exception('Gmail OAuth2 transport selected but not configured');
        }

        $rfc2822 = $this->header . "\r\n" . $this->body;

        // Gmail expects base64url (RFC 4648 §5).
        $raw = rtrim(strtr(base64_encode($rfc2822), '+/', '-_'), '=');

        $token = $helper->getAccessToken();
        $user  = $helper->getConfig();
        $user  = $user['user'];

        $ch = curl_init('https://gmail.googleapis.com/gmail/v1/users/' . urlencode($user) . '/messages/send');
        curl_setopt_array($ch, array(
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => json_encode(array('raw' => $raw)),
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 30,
            CURLOPT_CONNECTTIMEOUT => 8,
            CURLOPT_HTTPHEADER     => array(
                'Authorization: Bearer ' . $token,
                'Content-Type: application/json',
            ),
        ));
        $rspRaw = curl_exec($ch);
        $code   = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err    = curl_error($ch);
        curl_close($ch);

        if ($rspRaw === false || $rspRaw === '') {
            throw new Exception('Gmail send unreachable: ' . ($err ?: 'no response'));
        }
        $rsp = json_decode($rspRaw, true);
        if ($code >= 400) {
            $msg = isset($rsp['error']['message']) ? $rsp['error']['message'] : substr($rspRaw, 0, 300);
            throw new Exception('Gmail send failed (' . $code . '): ' . $msg);
        }
    }
}
