<?php
/**
 * Public read-only API: upcoming-class reminder feed for the WhatsApp bot.
 *
 * GET /courses/api_reminders?days_ahead=<n>
 *   Header:  X-API-Key: <shared secret>
 *
 *   Returns every confirmed class starting in exactly N days from today
 *   (where N defaults to 1 = tomorrow), along with the assigned trainer's
 *   name + email + phone and a pre-formatted WhatsApp message the bot can
 *   send verbatim.
 *
 *   Common usage by the bot's scheduler:
 *     - Daily at 6 PM SGT, fetch ?days_ahead=1 (tomorrow's classes)
 *     - For each row in `data.reminders`, send `formatted_message` via
 *       WhatsApp to the trainer's phone number (or skip if phone is blank).
 *
 * Auth: X-API-Key (same key as the other /courses/api_* endpoints).
 *
 * **************************************************************************
 * CRITICAL — READ ONLY. MMS DOES NOT SEND ANYTHING.
 *
 *   This controller returns DATA only. It does not send emails, WhatsApp
 *   messages, or any outbound communication. The decision to actually
 *   deliver a reminder lives entirely on the consumer side (Alisha's
 *   WhatsApp bot). There is no cron job in MMS for this — bot has its
 *   own scheduler.
 *
 *   This separation is deliberate. The 2026-06-03 newsletter incident
 *   showed how dangerous it is for MMS itself to send outbound at scale.
 *   By making MMS a pure data provider, the kill switch lives outside
 *   our system and we can never accidentally spam trainers.
 * **************************************************************************
 *
 * Filter rules for what counts as a "reminder":
 *   - course_runs.course_start_date = today + days_ahead
 *   - course_runs.trainer_option_id IS NOT NULL  (only confirmed classes)
 *   - course_runs.invitation_paused = 0          (admin hasn't paused it)
 *   - Trainer's email must be resolvable (via latest accepted invitation)
 *   - Bot can additionally skip rows where trainer.whatsapp/telephone is
 *     empty if it only sends via WhatsApp.
 */
class MMD_Courses_Api_RemindersController extends Mage_Core_Controller_Front_Action
{
    const CONFIG_PATH_API_KEY         = 'courses/general/wsq_schedule_api_key';
    const CONFIG_PATH_TRAINER_API_KEY = 'courses/general/trainer_reminders_api_key';
    const SG_STORE_ID                 = 1;
    const ESCALATION_WHATSAPP         = '+65 8866 6375';

    public function indexAction()
    {
        // Accept EITHER the customer-reply key or the trainer-reminders role
        // key. This endpoint is dual-purpose: the customer-reply bot may
        // also need schedule data, while the trainer-reminders bot has its
        // own role key for audit/rotation independence.
        $keyCustomer = trim((string) Mage::getStoreConfig(self::CONFIG_PATH_API_KEY));
        $keyTrainer  = trim((string) Mage::getStoreConfig(self::CONFIG_PATH_TRAINER_API_KEY));
        if ($keyCustomer === '' && $keyTrainer === '') {
            return $this->_json(503, $this->_errEnvelope('api_disabled', 'No API keys configured.'));
        }
        $provided = trim((string) $this->getRequest()->getHeader('X-API-Key'));
        $ok = false;
        if ($keyCustomer !== '' && hash_equals($keyCustomer, $provided)) { $ok = true; }
        if ($keyTrainer  !== '' && hash_equals($keyTrainer,  $provided)) { $ok = true; }
        if (!$ok) {
            return $this->_json(401, $this->_errEnvelope('unauthorized', 'Invalid or missing X-API-Key.'));
        }

        // Accept BOTH parameter formats — the bot uses ?target_date=YYYY-MM-DD,
        // the original spec used ?days_ahead=N. If target_date is provided, it
        // wins. Otherwise compute filter date from days_ahead (default 1).
        $targetDate = trim((string) $this->getRequest()->getParam('target_date', ''));
        $daysAhead  = (int)  $this->getRequest()->getParam('days_ahead', 1);

        if ($targetDate !== '') {
            // Strict YYYY-MM-DD validation to avoid SQL injection / malformed dates
            if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $targetDate)) {
                return $this->_json(400, $this->_errEnvelope('bad_request',
                    'target_date must be in YYYY-MM-DD format (e.g. 2026-06-08).'));
            }
            $ts = strtotime($targetDate);
            if ($ts === false) {
                return $this->_json(400, $this->_errEnvelope('bad_request',
                    'target_date is not a valid calendar date.'));
            }
            $filterDate = $targetDate;
            $daysAhead  = (int) round(($ts - strtotime(date('Y-m-d'))) / 86400);
        } else {
            if ($daysAhead < 0 || $daysAhead > 30) {
                return $this->_json(400, $this->_errEnvelope('bad_request',
                    'days_ahead must be between 0 (today) and 30 (one month ahead).'));
            }
            $filterDate = date('Y-m-d', strtotime('+' . $daysAhead . ' days'));
        }

        try {
            $rows = $this->_db()->fetchAll(
                "SELECT cr.run_id, cr.class_id, cr.product_id, cr.course_sku,
                        cr.course_start_date, cr.course_end_date,
                        cr.course_start_time, cr.course_end_time,
                        cr.mode_of_training, cr.venue_building,
                        cr.venue_street, cr.venue_floor, cr.venue_unit,
                        cr.postal_code, cr.room,
                        COALESCE(pn.value, '(deleted product)') AS course_title,
                        COALESCE(en.enrolled, 0) AS enrolled,
                        inv.trainer_name, inv.trainer_email,
                        t.trainer_id AS roster_id, t.telephone AS trainer_phone
                   FROM course_runs cr
              LEFT JOIN catalog_product_entity_varchar pn
                     ON pn.entity_id = cr.product_id
                    AND pn.attribute_id = (SELECT attribute_id FROM eav_attribute
                                            WHERE entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product')
                                              AND attribute_code = 'name' LIMIT 1)
                    AND pn.store_id = 0
              LEFT JOIN (
                    SELECT run_id, COUNT(*) AS enrolled
                      FROM course_run_enrolments
                     GROUP BY run_id
                ) en ON en.run_id = cr.run_id
              LEFT JOIN (
                    SELECT i.run_id, i.trainer_name, i.trainer_email
                      FROM course_run_trainer_invitations i
                     INNER JOIN (
                         SELECT run_id, MAX(id) AS max_id
                           FROM course_run_trainer_invitations
                          WHERE status = 'accepted'
                          GROUP BY run_id
                     ) latest ON latest.run_id = i.run_id AND latest.max_id = i.id
                ) inv ON inv.run_id = cr.run_id
              LEFT JOIN (
                    SELECT trainers_id AS trainer_id, email, telephone
                      FROM courses_trainers
                     WHERE status = 1
                ) t ON t.email = inv.trainer_email
                  WHERE cr.course_start_date = ?
                    AND cr.trainer_option_id IS NOT NULL
                    AND cr.invitation_paused = 0
                  ORDER BY cr.course_start_date ASC, cr.course_start_time ASC",
                array($filterDate)
            );
        } catch (Exception $e) {
            Mage::logException($e);
            return $this->_json(500, $this->_errEnvelope('internal_error', $e->getMessage()));
        }

        $reminders = array();
        foreach ($rows as $r) {
            $reminders[] = $this->_buildReminder($r, $daysAhead);
        }

        return $this->_json(200, array(
            'source_url'   => 'https://www.tertiarycourses.com.sg/',
            'last_updated' => gmdate('c'),
            'confidence'   => count($reminders) === 0 ? 'low' : 'high',
            'data'         => array(
                'filter_date' => $filterDate,
                'days_ahead'  => $daysAhead,
                'count'       => count($reminders),
                'note'        => 'MMS does NOT send these reminders. Pull this endpoint from your scheduler and decide on the consumer side whether to actually deliver each formatted_message.',
                'reminders'   => $reminders,
            ),
        ));
    }

    private function _buildReminder($r, $daysAhead)
    {
        $startDate = $r['course_start_date'];
        $endDate   = $r['course_end_date'] ?: $startDate;
        $startTime = $r['course_start_time'];
        $endTime   = $r['course_end_time'];
        $time = ($startTime && $endTime)
            ? date('g:i A', strtotime($startTime)) . ' - ' . date('g:i A', strtotime($endTime))
            : '9:30 AM - 5:30 PM';

        $venueText = $this->_venueText($r);
        $modeLabel = $this->_modeLabel($r['mode_of_training']);

        $trainerName  = trim((string) ($r['trainer_name']  ?? ''));
        $trainerEmail = trim((string) ($r['trainer_email'] ?? ''));
        $trainerPhone = trim((string) ($r['trainer_phone'] ?? ''));
        $firstName    = $trainerName !== '' ? strtok($trainerName, ' ') : 'Trainer';

        $courseUrl = $this->_courseUrl($r['product_id'], $r['course_sku']);
        $dateLabel = date('D, j M Y', strtotime($startDate));

        $whenLabel = ($daysAhead === 0) ? 'TODAY' : (($daysAhead === 1) ? 'TOMORROW' : 'on ' . $dateLabel);

        $formatted = "Hi {$firstName},\n\n"
            . "This is a friendly reminder that you are scheduled to teach a class {$whenLabel}:\n\n"
            . "📚 Course: " . $r['course_title'] . " (" . $r['course_sku'] . ")\n"
            . "📅 Date: " . $dateLabel . "\n"
            . "🕒 Time: " . $time . " SGT\n"
            . "📍 Venue: " . $venueText . "\n"
            . "💻 Mode: " . $modeLabel . "\n"
            . "👥 Enrolled: " . (int) $r['enrolled'] . " learner" . (((int) $r['enrolled']) === 1 ? '' : 's') . "\n\n"
            . "Course details:\n" . $courseUrl . "\n\n"
            . "Please arrive 15 minutes early to set up.\n\n"
            . "If you CANNOT make it for any reason, WhatsApp " . self::ESCALATION_WHATSAPP
            . " IMMEDIATELY so we can arrange a substitute.\n\n"
            . "— Tertiary Infotech Academy";

        return array(
            'class_id'         => (string) ($r['class_id'] ?? ''),
            'run_id'           => (int)    $r['run_id'],
            'course_code'      => (string) $r['course_sku'],
            'course_name'      => (string) $r['course_title'],
            'course_url'       => $courseUrl,
            'start_date'       => $startDate,
            'end_date'         => $endDate,
            'time'             => $time,
            'mode'             => $modeLabel,
            'venue'            => $venueText,
            'enrolled'         => (int) $r['enrolled'],
            'trainer'          => array(
                'name'      => $trainerName,
                'email'     => $trainerEmail,
                'telephone' => $trainerPhone,
                'roster_id' => isset($r['roster_id']) ? (int) $r['roster_id'] : null,
            ),
            'formatted_message' => $formatted,
        );
    }

    private function _venueText($r)
    {
        $parts = array_filter(array(
            trim((string) ($r['venue_building'] ?? '')),
            trim((string) ($r['venue_street']   ?? '')),
            trim((string) ($r['room']           ?? '')),
        ));
        if (empty($parts)) {
            return 'Woods Square Tower 1, #07-85/86/87, Singapore 737715';
        }
        return implode(', ', $parts);
    }

    private function _courseUrl($productId, $sku)
    {
        try {
            $product = Mage::getModel('catalog/product')->setStoreId(self::SG_STORE_ID)->load((int) $productId);
            if ($product && $product->getId()) {
                $url = (string) $product->getProductUrl(false);
                if ($url !== '') return $url;
            }
        } catch (Exception $e) { /* fall through */ }
        return 'https://www.tertiarycourses.com.sg/catalogsearch/result/?q=' . rawurlencode($sku);
    }

    private function _modeLabel($v)
    {
        switch ((int) $v) {
            case 2: return 'Live Online';
            case 3: return 'Hybrid (Classroom + Online)';
            default: return 'Classroom';
        }
    }

    private function _db()
    {
        return Mage::getSingleton('core/resource')->getConnection('core_read');
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
            ->setHeader('Cache-Control', 'public, max-age=300', true)
            ->setBody(json_encode($body, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
        return $this;
    }
}
