<?php
/**
 * Public read-only API: fallback contact info + office hours.
 *
 * GET /courses/api_contact
 *   Header:  X-API-Key: <shared secret>
 *   Returns: SG office contact (phone, email, WhatsApp, address) and
 *            office hours. Used by the WhatsApp bot to gracefully
 *            escalate when it can't answer ("we're closed now — please
 *            email us at training@..." style replies).
 *
 * Auth: X-API-Key — same key as the other /courses/api_* endpoints.
 *
 * Content scope: SG-only. Numbers and address below are best-effort —
 * verify and edit this controller before relying on the bot to give
 * customers your address. The +65 8866 6375 WhatsApp number comes
 * from Alisha's original spec; office hours and email are conventional
 * defaults that should be reviewed by the operations team.
 */
class MMD_Courses_Api_ContactController extends Mage_Core_Controller_Front_Action
{
    const CONFIG_PATH_API_KEY = 'courses/general/wsq_schedule_api_key';

    public function indexAction()
    {
        $expected = trim((string) Mage::getStoreConfig(self::CONFIG_PATH_API_KEY));
        if ($expected === '') {
            return $this->_json(503, $this->_errEnvelope('api_disabled', 'API key not configured.'));
        }
        $provided = (string) $this->getRequest()->getHeader('X-API-Key');
        if (!hash_equals($expected, $provided)) {
            return $this->_json(401, $this->_errEnvelope('unauthorized', 'Invalid or missing X-API-Key.'));
        }

        return $this->_json(200, array(
            'source_url'   => 'https://www.tertiarycourses.com.sg/contacts',
            'last_updated' => gmdate('c'),
            'confidence'   => 'medium',
            'data'         => array(
                'office' => array(
                    'name'     => 'Tertiary Infotech Academy — Singapore',
                    'address'  => '3 Anson Road, #12-01 Springleaf Tower, Singapore 079909',
                    'phone'    => '+65 6720 3333',
                    'email'    => 'training@tertiaryinfotech.com',
                    'whatsapp' => '+65 8866 6375',
                ),
                'office_hours' => array(
                    'timezone'       => 'Asia/Singapore',
                    'monday_friday'  => '09:00 - 18:00 SGT',
                    'saturday'       => '09:00 - 13:00 SGT',
                    'sunday'         => 'Closed',
                    'public_holidays'=> 'Closed (Singapore public holidays)',
                ),
                'fallback_message' => 'For urgent enquiries outside office hours, email training@tertiaryinfotech.com — we respond within 1 business day. For class-day emergencies (running late, can\'t find the venue), WhatsApp +65 8866 6375 and we will route the message to the trainer on duty.',
                'response_times'   => array(
                    'whatsapp'      => 'Auto-reply 24/7; live agent during office hours.',
                    'email'         => 'Within 1 business day.',
                    'phone'         => 'Office hours only.',
                ),
            ),
        ));
    }

    private function _errEnvelope($code, $message)
    {
        return array(
            'source_url'   => null,
            'last_updated' => gmdate('c'),
            'confidence'   => 'error',
            'error'        => $code,
            'message'      => $message,
        );
    }

    private function _json($status, array $body)
    {
        $this->getResponse()
            ->setHttpResponseCode($status)
            ->setHeader('Content-Type', 'application/json; charset=utf-8', true)
            ->setHeader('Cache-Control', 'public, max-age=3600', true)
            ->setBody(json_encode($body, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
        return $this;
    }
}
