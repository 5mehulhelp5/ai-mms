<?php
/**
 * Auto-sweep cron — twice-weekly, sends trainer invitations for upcoming
 * classes that have enrolled learners but no trainer assigned yet.
 *
 * Mirrors AI-LMS-TMS auto-send-trainer-invitations endpoint logic.
 * Scheduled Mon & Thu at 10:00 SGT via config.xml crontab entry.
 *
 * Idempotent: skip-set in TrainerInvitationService prevents duplicate
 * sends to trainers who already have a pending/accepted invitation.
 */
class MMD_RoleManager_Model_Cron_TrainerInvitation
{
    const LOG_FILE         = 'trainer-invitations.log';
    const DAYS_IN_ADVANCE  = 30;
    const LOCK_CONFIG_PATH = 'mmd/trainer_invitation_sweep/running';

    public function run()
    {
        // Global in-flight lock — prevent overlapping runs.
        $running = Mage::getStoreConfig(self::LOCK_CONFIG_PATH);
        if ($running) {
            Mage::log('TrainerInvitation sweep skipped — previous run still in progress.', Zend_Log::WARN, self::LOG_FILE);
            return;
        }

        try {
            Mage::getConfig()->saveConfig(self::LOCK_CONFIG_PATH, 1, 'default', 0);
            Mage::getConfig()->reinit();
            $this->_sweep();
        } catch (Exception $e) {
            Mage::log('TrainerInvitation sweep error: ' . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE);
        } finally {
            Mage::getConfig()->saveConfig(self::LOCK_CONFIG_PATH, 0, 'default', 0);
            Mage::getConfig()->reinit();
        }
    }

    protected function _sweep()
    {
        $resource  = Mage::getSingleton('core/resource');
        $read      = $resource->getConnection('core_read');
        $invTbl    = $resource->getTableName('course_run_trainer_invitations');
        $runsTbl   = $resource->getTableName('course_runs');
        $enrolTbl  = $resource->getTableName('course_run_enrolments');

        $today     = date('Y-m-d');
        $cutoff    = date('Y-m-d', strtotime('+' . self::DAYS_IN_ADVANCE . ' days'));

        // Eligible runs: upcoming within window, no trainer, not paused, at least 1 enrolment,
        // TGS- SKUs excluded (handled externally).
        $runs = $read->fetchAll(
            "SELECT cr.run_id
               FROM `$runsTbl` cr
               JOIN (SELECT run_id FROM `$enrolTbl` GROUP BY run_id HAVING COUNT(*) >= 1) en
                    ON en.run_id = cr.run_id
              WHERE cr.course_start_date > ?
                AND cr.course_start_date <= ?
                AND (cr.trainer_option_id IS NULL OR cr.trainer_option_id = 0)
                AND cr.invitation_paused = 0
                AND cr.course_sku NOT LIKE 'TGS%'
                AND NOT EXISTS (
                    SELECT 1 FROM `$invTbl` i
                     WHERE i.run_id = cr.run_id
                       AND i.status IN ('pending','accepted')
                )",
            array($today, $cutoff)
        );

        $sent = 0; $skipped = 0; $errors = 0;

        /** @var MMD_RoleManager_Model_TrainerInvitationService $svc */
        $svc = Mage::getModel('mmd_rolemanager/trainerInvitationService');

        foreach ($runs as $row) {
            try {
                $result = $svc->sendNextInvitation((int) $row['run_id']);
                if ($result['success']) {
                    $sent++;
                } else {
                    $skipped++;
                    Mage::log('Sweep skipped run_id=' . $row['run_id'] . ': ' . $result['message'], Zend_Log::DEBUG, self::LOG_FILE);
                }
            } catch (Exception $e) {
                $errors++;
                Mage::log('Sweep error on run_id=' . $row['run_id'] . ': ' . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE);
            }
        }

        Mage::log(
            sprintf('TrainerInvitation sweep complete — sent:%d skipped:%d errors:%d (window: %s to %s)', $sent, $skipped, $errors, $today, $cutoff),
            Zend_Log::INFO, self::LOG_FILE
        );
    }
}
