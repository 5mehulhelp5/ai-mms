<?php
/**
 * Trainer invitation service — ported from AI-LMS-TMS trainerInvitationSender.ts.
 *
 * Flow:
 *   1. Admin calls sendNextInvitation($runId) from the Assign Trainer panel.
 *   2. Service resolves the product's trainers list (EAV multiselect option_ids,
 *      in sort_order ASC), looks up each trainer's email from courses_trainers,
 *      and builds a skip-set of already-invited trainers for this run.
 *   3. First eligible trainer (not in skip-set, has email) receives the invitation
 *      email with Accept and Decline button links (token-based, no login required).
 *   4. On accept: course_runs.trainer_option_id is set and a confirmation email
 *      is sent. On decline: a decline email is sent and the next trainer is tried.
 *
 * Email transport: reuses MMD_Email_Helper_Gmail (Gmail OAuth2) — same mechanism
 * as the course registration email. Falls back to Zend_Mail default if Gmail
 * credentials are not configured.
 */
class MMD_RoleManager_Model_TrainerInvitationService
{
    const TABLE_INVITATIONS = 'course_run_trainer_invitations';
    const TABLE_RUNS        = 'course_runs';
    const TABLE_TRAINERS    = 'courses_trainers';
    const LOG_FILE          = 'trainer-invitations.log';

    /** @var Varien_Db_Adapter_Interface */
    protected $_read;
    /** @var Varien_Db_Adapter_Interface */
    protected $_write;
    /** @var Mage_Core_Model_Resource */
    protected $_resource;

    protected function _init()
    {
        if ($this->_resource) return;
        $this->_resource = Mage::getSingleton('core/resource');
        $this->_read     = $this->_resource->getConnection('core_read');
        $this->_write    = $this->_resource->getConnection('core_write');
    }

    /**
     * Send an invitation to the next eligible trainer for the given run.
     *
     * @param int    $runId
     * @param string $overrideTrainerName  Force a specific trainer by name (admin override).
     * @return array { success:bool, message:string, trainer_name?:string, trainer_email?:string }
     */
    public function sendNextInvitation($runId, $overrideTrainerName = '')
    {
        $this->_init();
        $runId = (int) $runId;

        try {
            $run = $this->_loadRun($runId);
            if (!$run) {
                return array('success' => false, 'message' => 'Class run not found.');
            }
            if (!empty($run['invitation_paused'])) {
                return array('success' => false, 'message' => 'Invitations are paused for this class.');
            }

            // Already has an accepted trainer — don't send another invitation.
            $accepted = $this->_read->fetchOne(
                "SELECT id FROM " . $this->_resource->getTableName(self::TABLE_INVITATIONS)
              . " WHERE run_id = ? AND status = 'accepted' LIMIT 1",
                array($runId)
            );
            if ($accepted) {
                return array('success' => false, 'message' => 'This class already has an accepted trainer.');
            }

            $queue   = $this->_buildQueue($run['product_id']);
            $skipSet = $this->_buildSkipSet($runId);

            $trainer = null;
            if ($overrideTrainerName !== '') {
                foreach ($queue as $t) {
                    if (strcasecmp(trim($t['name']), trim($overrideTrainerName)) === 0
                        && !empty($t['email'])) {
                        $trainer = $t;
                        break;
                    }
                }
                if (!$trainer) {
                    return array('success' => false, 'message' => 'Trainer "' . $overrideTrainerName . '" not found or has no email.');
                }
            } else {
                $lastInvited = $this->_getLastInvitedName($runId);
                $startIdx    = 0;
                if ($lastInvited !== '') {
                    foreach ($queue as $i => $t) {
                        if (strcasecmp(trim($t['name']), trim($lastInvited)) === 0) {
                            $startIdx = $i + 1;
                            break;
                        }
                    }
                }
                $n = count($queue);
                for ($i = 0; $i < $n; $i++) {
                    $t = $queue[($startIdx + $i) % $n];
                    if (!isset($skipSet[$t['name']]) && !empty($t['email'])) {
                        $trainer = $t;
                        break;
                    }
                }
            }

            if (!$trainer) {
                return array('success' => false, 'message' => 'No eligible trainer found. All trainers on this course have already been invited.');
            }

            return $this->_dispatchInvitation($run, $trainer);

        } catch (Exception $e) {
            Mage::log('TrainerInvitationService::sendNextInvitation error: ' . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE);
            return array('success' => false, 'message' => 'Error: ' . $e->getMessage());
        }
    }

    /**
     * Handle trainer accepting an invitation (via token-based public URL).
     *
     * @param  string $token
     * @return array  { success:bool, message:string, html:string }
     */
    public function handleAccept($token)
    {
        $this->_init();
        $token = (string) $token;

        $inv = $this->_loadInvitationByToken($token);
        if (!$inv) {
            return array('success' => false, 'message' => 'Invalid or expired invitation link.', 'html' => 'invalid');
        }
        if ($inv['status'] === 'accepted') {
            return array('success' => true, 'message' => 'You have already accepted this invitation.', 'html' => 'already_accepted');
        }
        if (!in_array($inv['status'], array('pending', 'resent'), true)) {
            return array('success' => false, 'message' => 'This invitation is no longer active.', 'html' => 'inactive');
        }

        // Check if the run has replies blocked (admin manually confirmed a trainer externally).
        $run = $this->_loadRun((int)$inv['run_id']);
        if ($run && !empty($run['invitation_replies_blocked'])) {
            $this->_write->update(
                $this->_resource->getTableName(self::TABLE_INVITATIONS),
                array('status' => 'blocked', 'responded_at' => now()),
                array('id = ?' => (int)$inv['id'])
            );
            return array('success' => false, 'message' => 'Another trainer has already been assigned to this class.', 'html' => 'blocked');
        }

        // Check if another trainer has already accepted for this run.
        $otherAccepted = $this->_read->fetchOne(
            "SELECT id FROM " . $this->_resource->getTableName(self::TABLE_INVITATIONS)
          . " WHERE run_id = ? AND status = 'accepted' AND id != ? LIMIT 1",
            array((int)$inv['run_id'], (int)$inv['id'])
        );
        if ($otherAccepted) {
            $this->_write->update(
                $this->_resource->getTableName(self::TABLE_INVITATIONS),
                array('status' => 'blocked', 'responded_at' => now()),
                array('id = ?' => (int)$inv['id'])
            );
            return array('success' => false, 'message' => 'Another trainer has already been assigned to this class.', 'html' => 'blocked');
        }

        // Accept: update invitation, set trainer on course_run.
        $this->_write->update(
            $this->_resource->getTableName(self::TABLE_INVITATIONS),
            array('status' => 'accepted', 'responded_at' => now()),
            array('id = ?' => (int)$inv['id'])
        );
        if (!empty($inv['trainer_option_id'])) {
            $this->_write->update(
                $this->_resource->getTableName(self::TABLE_RUNS),
                array('trainer_option_id' => (int)$inv['trainer_option_id']),
                array('run_id = ?' => (int)$inv['run_id'])
            );
        }

        Mage::log(
            sprintf('Trainer "%s" <%s> accepted invitation for run_id=%d', $inv['trainer_name'], $inv['trainer_email'], $inv['run_id']),
            Zend_Log::INFO, self::LOG_FILE
        );

        $this->_sendConfirmationEmail($inv, 'accept');
        return array('success' => true, 'message' => 'Invitation accepted.', 'html' => 'accepted');
    }

    /**
     * Handle trainer declining an invitation (via token-based public URL).
     *
     * @param  string $token
     * @return array  { success:bool, message:string, html:string }
     */
    public function handleDecline($token)
    {
        $this->_init();
        $token = (string) $token;

        $inv = $this->_loadInvitationByToken($token);
        if (!$inv) {
            return array('success' => false, 'message' => 'Invalid or expired invitation link.', 'html' => 'invalid');
        }
        if ($inv['status'] === 'declined') {
            return array('success' => true, 'message' => 'You have already declined this invitation.', 'html' => 'already_declined');
        }
        if (!in_array($inv['status'], array('pending', 'resent'), true)) {
            return array('success' => false, 'message' => 'This invitation is no longer active.', 'html' => 'inactive');
        }

        $this->_write->update(
            $this->_resource->getTableName(self::TABLE_INVITATIONS),
            array('status' => 'declined', 'responded_at' => now()),
            array('id = ?' => (int)$inv['id'])
        );

        Mage::log(
            sprintf('Trainer "%s" <%s> declined invitation for run_id=%d', $inv['trainer_name'], $inv['trainer_email'], $inv['run_id']),
            Zend_Log::INFO, self::LOG_FILE
        );

        $this->_sendConfirmationEmail($inv, 'decline');

        // Auto-escalate to next trainer — non-fatal if it fails.
        try {
            $this->sendNextInvitation((int)$inv['run_id']);
        } catch (Exception $e) {
            Mage::log('Auto-escalation failed after decline: ' . $e->getMessage(), Zend_Log::WARN, self::LOG_FILE);
        }

        return array('success' => true, 'message' => 'Invitation declined.', 'html' => 'declined');
    }

    // ------------------------------------------------------------------ //
    // Private helpers
    // ------------------------------------------------------------------ //

    protected function _loadRun($runId)
    {
        return $this->_read->fetchRow(
            "SELECT cr.run_id, cr.product_id, cr.course_sku, cr.class_id,
                    cr.course_start_date, cr.course_end_date,
                    cr.course_start_time, cr.course_end_time,
                    cr.trainer_option_id, cr.invitation_paused, cr.invitation_replies_blocked,
                    COALESCE(pv.value, cr.course_sku) AS course_title
               FROM " . $this->_resource->getTableName(self::TABLE_RUNS) . " cr
               LEFT JOIN " . $this->_resource->getTableName('catalog_product_entity_varchar') . " pv
                    ON pv.entity_id = cr.product_id AND pv.store_id = 0
                   AND pv.attribute_id = (
                       SELECT a.attribute_id FROM " . $this->_resource->getTableName('eav_attribute') . " a
                        JOIN " . $this->_resource->getTableName('eav_entity_type') . " t ON t.entity_type_id = a.entity_type_id
                       WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'name'
                   )
              WHERE cr.run_id = ?",
            array($runId)
        ) ?: null;
    }

    /**
     * Ordered list of trainers attached to this product via the `trainers`
     * EAV multiselect attribute.  Each entry: { option_id, name, email }.
     * Order follows EAV sort_order ASC (same order the admin sees in the
     * Assign Trainer dropdown).
     */
    protected function _buildQueue($productId)
    {
        $productId = (int) $productId;

        // 1. Get trainer option_ids for this product (CSV from EAV text attribute).
        $attrId = (int) $this->_read->fetchOne(
            "SELECT attribute_id FROM " . $this->_resource->getTableName('eav_attribute')
          . " WHERE attribute_code = 'trainers' AND entity_type_id = 4"
        );
        if (!$attrId) return array();

        $csv = (string) $this->_read->fetchOne(
            "SELECT value FROM " . $this->_resource->getTableName('catalog_product_entity_text')
          . " WHERE entity_id = ? AND attribute_id = ? AND store_id = 0",
            array($productId, $attrId)
        );
        if (trim($csv) === '') return array();

        $oids = array_filter(array_map('intval', explode(',', $csv)));
        if (empty($oids)) return array();

        // 2. Load option names ordered by sort_order, then resolve emails.
        $oidsCsv = implode(',', $oids);
        $options = $this->_read->fetchAll(
            "SELECT eao.option_id, eaov.value AS name, eao.sort_order
               FROM " . $this->_resource->getTableName('eav_attribute_option') . " eao
               JOIN " . $this->_resource->getTableName('eav_attribute_option_value') . " eaov
                    ON eaov.option_id = eao.option_id AND eaov.store_id = 0
              WHERE eao.option_id IN ($oidsCsv)
              ORDER BY eao.sort_order ASC, eaov.value ASC"
        );

        // 3. Resolve emails from courses_trainers.relation_id = option_id.
        $emailByOid = array();
        if (!empty($options)) {
            $rows = $this->_read->fetchAll(
                "SELECT relation_id, email FROM " . $this->_resource->getTableName(self::TABLE_TRAINERS)
              . " WHERE relation_id IN ($oidsCsv) AND email IS NOT NULL AND email <> '' AND status = 1"
            );
            foreach ($rows as $r) {
                $emailByOid[(int)$r['relation_id']] = $r['email'];
            }
        }

        $queue = array();
        foreach ($options as $opt) {
            $queue[] = array(
                'option_id' => (int) $opt['option_id'],
                'name'      => (string) $opt['name'],
                'email'     => isset($emailByOid[(int)$opt['option_id']]) ? $emailByOid[(int)$opt['option_id']] : '',
            );
        }
        return $queue;
    }

    /**
     * Names of trainers already invited for this run who should be skipped
     * (pending = outstanding invite, accepted = done, declined/blocked = tried).
     * Returns [ trainer_name => true ] for O(1) lookup.
     */
    protected function _buildSkipSet($runId)
    {
        $rows = $this->_read->fetchCol(
            "SELECT trainer_name FROM " . $this->_resource->getTableName(self::TABLE_INVITATIONS)
          . " WHERE run_id = ? AND status IN ('pending','accepted','declined','blocked')",
            array((int) $runId)
        );
        $set = array();
        foreach ($rows as $name) {
            $set[$name] = true;
        }
        return $set;
    }

    protected function _getLastInvitedName($runId)
    {
        return (string) $this->_read->fetchOne(
            "SELECT trainer_name FROM " . $this->_resource->getTableName(self::TABLE_INVITATIONS)
          . " WHERE run_id = ? ORDER BY created_at DESC LIMIT 1",
            array((int) $runId)
        );
    }

    protected function _loadInvitationByToken($token)
    {
        return $this->_read->fetchRow(
            "SELECT * FROM " . $this->_resource->getTableName(self::TABLE_INVITATIONS)
          . " WHERE token = ? LIMIT 1",
            array($token)
        ) ?: null;
    }

    protected function _generateToken()
    {
        return bin2hex(random_bytes(32));
    }

    protected function _dispatchInvitation(array $run, array $trainer)
    {
        $token   = $this->_generateToken();
        $baseUrl = Mage::getBaseUrl(Mage_Core_Model_Store::URL_TYPE_WEB);
        $acceptUrl  = rtrim($baseUrl, '/') . '/trainer_invite/respond?token=' . $token . '&action=accept';
        $declineUrl = rtrim($baseUrl, '/') . '/trainer_invite/respond?token=' . $token . '&action=decline';

        $startDate = $run['course_start_date']
            ? date('d M Y (D)', strtotime($run['course_start_date']))
            : '—';
        $endDate = $run['course_end_date']
            ? date('d M Y (D)', strtotime($run['course_end_date']))
            : $startDate;
        $timeStr = '';
        if (!empty($run['course_start_time'])) {
            $timeStr = date('g:ia', strtotime($run['course_start_time']));
            if (!empty($run['course_end_time'])) {
                $timeStr .= ' – ' . date('g:ia', strtotime($run['course_end_time']));
            }
        }
        $confirmBy = date('d M Y', strtotime('+2 days')) . ' at 23:59 SGT';

        $subject = 'Trainer Invitation: ' . $run['course_title'] . ' (' . $run['course_sku'] . ')';

        $body = $this->_buildInvitationHtml(
            $trainer['name'], $run['course_title'], $run['course_sku'],
            $run['class_id'], $startDate, $endDate, $timeStr, $confirmBy,
            $acceptUrl, $declineUrl
        );

        // Mark any previous pending invitation for this trainer on this run as resent.
        $this->_write->update(
            $this->_resource->getTableName(self::TABLE_INVITATIONS),
            array('status' => 'resent'),
            array(
                'run_id = ?'       => (int) $run['run_id'],
                'trainer_name = ?' => $trainer['name'],
                'status = ?'       => 'pending',
            )
        );

        $this->_write->insert(
            $this->_resource->getTableName(self::TABLE_INVITATIONS),
            array(
                'run_id'            => (int) $run['run_id'],
                'trainer_option_id' => $trainer['option_id'] ?: null,
                'trainer_name'      => $trainer['name'],
                'trainer_email'     => $trainer['email'],
                'token'             => $token,
                'status'            => 'pending',
                'email_subject'     => $subject,
                'email_body'        => $body,
                'sent_at'           => now(),
            )
        );

        $sent = $this->_sendRawEmail($trainer['email'], $trainer['name'], $subject, $body);
        if (!$sent) {
            Mage::log('TrainerInvitationService: email send failed for ' . $trainer['email'], Zend_Log::WARN, self::LOG_FILE);
        }

        Mage::log(
            sprintf('Invitation sent to "%s" <%s> for run_id=%d (token=%s)', $trainer['name'], $trainer['email'], $run['run_id'], substr($token, 0, 8) . '...'),
            Zend_Log::INFO, self::LOG_FILE
        );

        return array(
            'success'       => true,
            'message'       => 'Invitation sent to ' . $trainer['name'] . ' (' . $trainer['email'] . ').',
            'trainer_name'  => $trainer['name'],
            'trainer_email' => $trainer['email'],
        );
    }

    protected function _sendConfirmationEmail(array $inv, $type)
    {
        $run = $this->_loadRun((int)$inv['run_id']);
        if (!$run) return;

        $startDate = $run['course_start_date']
            ? date('d M Y (D)', strtotime($run['course_start_date']))
            : '—';

        if ($type === 'accept') {
            $subject = 'Thank You for Accepting — ' . $run['course_title'] . ' (' . $run['course_sku'] . ')';
            $body    = $this->_buildAcceptHtml($inv['trainer_name'], $run['course_title'], $run['course_sku'], $run['class_id'], $startDate);
        } else {
            $subject = 'Thank You for Your Response — ' . $run['course_title'] . ' (' . $run['course_sku'] . ')';
            $body    = $this->_buildDeclineHtml($inv['trainer_name'], $run['course_title'], $run['course_sku'], $startDate);
        }

        $this->_sendRawEmail($inv['trainer_email'], $inv['trainer_name'], $subject, $body);
    }

    /**
     * Send via Gmail OAuth2 (MMD_Email_Helper_Gmail). Falls back to
     * Zend_Mail default transport if Gmail is not configured.
     */
    protected function _sendRawEmail($toEmail, $toName, $subject, $bodyHtml)
    {
        try {
            /** @var MMD_Email_Helper_Gmail $gmail */
            $gmail = Mage::helper('mmd_email/gmail');
            $gmail->send($toEmail, $subject, $bodyHtml, $toName);
            return true;
        } catch (Exception $e) {
            Mage::log('Gmail send failed, trying Zend_Mail: ' . $e->getMessage(), Zend_Log::WARN, self::LOG_FILE);
        }

        // Fallback: Zend_Mail (uses whatever transport is installed at boot).
        try {
            $mail = new Zend_Mail('UTF-8');
            $mail->addTo($toEmail, $toName);
            $from = Mage::getStoreConfig('trans_email/ident_sales/email');
            $fromName = Mage::getStoreConfig('trans_email/ident_sales/name');
            $mail->setFrom($from ?: 'noreply@tertiarycourses.com.sg', $fromName ?: 'Tertiary Courses');
            $mail->setSubject($subject);
            $mail->setBodyHtml($bodyHtml);
            $mail->send();
            return true;
        } catch (Exception $e) {
            Mage::log('Zend_Mail fallback also failed: ' . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE);
            return false;
        }
    }

    // ------------------------------------------------------------------ //
    // HTML email builders
    // ------------------------------------------------------------------ //

    protected function _buildInvitationHtml($trainerName, $courseTitle, $courseSku, $classId, $startDate, $endDate, $timeStr, $confirmBy, $acceptUrl, $declineUrl)
    {
        $esc = 'htmlspecialchars';
        return '<!DOCTYPE html><html><head><meta charset="UTF-8"></head><body style="margin:0;padding:0;background:#f8fafc;font-family:Arial,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0"><tr><td align="center" style="padding:32px 16px;">
<table width="600" cellpadding="0" cellspacing="0" style="background:#1e2132;border-radius:12px;overflow:hidden;">
  <tr><td style="background:#1a3a6b;padding:24px 32px;">
    <p style="margin:0;color:#60a5fa;font-size:13px;font-weight:600;letter-spacing:1px;text-transform:uppercase;">Tertiary Courses — Trainer Invitation</p>
  </td></tr>
  <tr><td style="padding:32px;">
    <p style="margin:0 0 16px;color:#e2e8f0;font-size:16px;">Dear <strong>' . htmlspecialchars($trainerName) . '</strong>,</p>
    <p style="margin:0 0 24px;color:#94a3b8;font-size:14px;line-height:1.6;">
      You have been selected as a trainer for the following class. Please review the details and confirm your availability.
    </p>
    <table width="100%" cellpadding="12" cellspacing="0" style="background:#0f172a;border-radius:8px;margin-bottom:24px;">
      <tr><td style="color:#64748b;font-size:12px;font-weight:600;text-transform:uppercase;width:120px;">Course</td>
          <td style="color:#e2e8f0;font-size:14px;">' . htmlspecialchars($courseTitle) . '</td></tr>
      <tr><td style="color:#64748b;font-size:12px;font-weight:600;text-transform:uppercase;">Code</td>
          <td style="color:#e2e8f0;font-size:14px;font-family:monospace;">' . htmlspecialchars($courseSku) . '</td></tr>
      <tr><td style="color:#64748b;font-size:12px;font-weight:600;text-transform:uppercase;">Class ID</td>
          <td style="color:#e2e8f0;font-size:14px;font-family:monospace;">' . htmlspecialchars($classId) . '</td></tr>
      <tr><td style="color:#64748b;font-size:12px;font-weight:600;text-transform:uppercase;">Start Date</td>
          <td style="color:#e2e8f0;font-size:14px;">' . htmlspecialchars($startDate) . '</td></tr>
      <tr><td style="color:#64748b;font-size:12px;font-weight:600;text-transform:uppercase;">End Date</td>
          <td style="color:#e2e8f0;font-size:14px;">' . htmlspecialchars($endDate) . '</td></tr>'
      . ($timeStr ? '<tr><td style="color:#64748b;font-size:12px;font-weight:600;text-transform:uppercase;">Time</td>
          <td style="color:#e2e8f0;font-size:14px;">' . htmlspecialchars($timeStr) . '</td></tr>' : '')
      . '<tr><td style="color:#64748b;font-size:12px;font-weight:600;text-transform:uppercase;">Respond By</td>
          <td style="color:#f59e0b;font-size:14px;font-weight:600;">' . htmlspecialchars($confirmBy) . '</td></tr>
    </table>
    <p style="margin:0 0 20px;color:#94a3b8;font-size:13px;">Please click one of the buttons below to confirm your response:</p>
    <table cellpadding="0" cellspacing="0"><tr>
      <td style="padding-right:12px;">
        <a href="' . htmlspecialchars($acceptUrl) . '" style="display:inline-block;padding:12px 28px;background:#16a34a;color:#fff;font-size:14px;font-weight:700;text-decoration:none;border-radius:8px;">✓ Accept</a>
      </td>
      <td>
        <a href="' . htmlspecialchars($declineUrl) . '" style="display:inline-block;padding:12px 28px;background:#dc2626;color:#fff;font-size:14px;font-weight:700;text-decoration:none;border-radius:8px;">✗ Decline</a>
      </td>
    </tr></table>
    <p style="margin:24px 0 0;color:#475569;font-size:11px;">These links are unique to you. Do not share them. If you have questions, reply to this email.</p>
  </td></tr>
  <tr><td style="padding:16px 32px;border-top:1px solid #1e293b;">
    <p style="margin:0;color:#334155;font-size:11px;">Tertiary Courses — <a href="https://tertiarycourses.com.sg" style="color:#60a5fa;text-decoration:none;">tertiarycourses.com.sg</a></p>
  </td></tr>
</table>
</td></tr></table></body></html>';
    }

    protected function _buildAcceptHtml($trainerName, $courseTitle, $courseSku, $classId, $startDate)
    {
        return '<!DOCTYPE html><html><head><meta charset="UTF-8"></head><body style="margin:0;padding:0;background:#f8fafc;font-family:Arial,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0"><tr><td align="center" style="padding:32px 16px;">
<table width="600" cellpadding="0" cellspacing="0" style="background:#1e2132;border-radius:12px;overflow:hidden;">
  <tr><td style="background:#14532d;padding:24px 32px;">
    <p style="margin:0;color:#4ade80;font-size:13px;font-weight:600;letter-spacing:1px;text-transform:uppercase;">✓ Invitation Accepted</p>
  </td></tr>
  <tr><td style="padding:32px;">
    <p style="margin:0 0 16px;color:#e2e8f0;font-size:16px;">Dear <strong>' . htmlspecialchars($trainerName) . '</strong>,</p>
    <p style="margin:0 0 24px;color:#94a3b8;font-size:14px;line-height:1.6;">
      Thank you for accepting the trainer role for <strong>' . htmlspecialchars($courseTitle) . '</strong>
      (' . htmlspecialchars($courseSku) . '). You are now confirmed as the trainer for class <strong>' . htmlspecialchars($classId) . '</strong>
      starting on <strong>' . htmlspecialchars($startDate) . '</strong>.
    </p>
    <p style="margin:0;color:#94a3b8;font-size:14px;">Our team will be in touch with further details. Thank you!</p>
  </td></tr>
  <tr><td style="padding:16px 32px;border-top:1px solid #1e293b;">
    <p style="margin:0;color:#334155;font-size:11px;">Tertiary Courses — <a href="https://tertiarycourses.com.sg" style="color:#60a5fa;text-decoration:none;">tertiarycourses.com.sg</a></p>
  </td></tr>
</table></td></tr></table></body></html>';
    }

    protected function _buildDeclineHtml($trainerName, $courseTitle, $courseSku, $startDate)
    {
        return '<!DOCTYPE html><html><head><meta charset="UTF-8"></head><body style="margin:0;padding:0;background:#f8fafc;font-family:Arial,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0"><tr><td align="center" style="padding:32px 16px;">
<table width="600" cellpadding="0" cellspacing="0" style="background:#1e2132;border-radius:12px;overflow:hidden;">
  <tr><td style="background:#450a0a;padding:24px 32px;">
    <p style="margin:0;color:#f87171;font-size:13px;font-weight:600;letter-spacing:1px;text-transform:uppercase;">Invitation Declined</p>
  </td></tr>
  <tr><td style="padding:32px;">
    <p style="margin:0 0 16px;color:#e2e8f0;font-size:16px;">Dear <strong>' . htmlspecialchars($trainerName) . '</strong>,</p>
    <p style="margin:0 0 24px;color:#94a3b8;font-size:14px;line-height:1.6;">
      Thank you for letting us know. We have noted your unavailability for
      <strong>' . htmlspecialchars($courseTitle) . '</strong> (' . htmlspecialchars($courseSku) . ') on <strong>' . htmlspecialchars($startDate) . '</strong>.
    </p>
    <p style="margin:0;color:#94a3b8;font-size:14px;">We appreciate your prompt response. We hope to work with you on a future class.</p>
  </td></tr>
  <tr><td style="padding:16px 32px;border-top:1px solid #1e293b;">
    <p style="margin:0;color:#334155;font-size:11px;">Tertiary Courses — <a href="https://tertiarycourses.com.sg" style="color:#60a5fa;text-decoration:none;">tertiarycourses.com.sg</a></p>
  </td></tr>
</table></td></tr></table></body></html>';
    }
}
