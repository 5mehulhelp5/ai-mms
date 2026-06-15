<?php
/**
 * Daily course sync sweep from SG (country instances only).
 *
 * FAIL-SAFE: gated by mmd/course_sync/auto_enabled. Absent = OFF, so it
 * ships inert and won't pull even if Magento cron is running, until an admin
 * enables it. Manual "Sync Courses from SG" is unaffected by this flag.
 *
 * Also skips silently when MMS_MODE != country (won't run on SG by accident).
 */
class MMD_RoleManager_Model_Cron_CourseSync
{
    const LOG_FILE         = 'course-sync.log';
    const LOCK_CONFIG_PATH = 'mmd/course_sync_sweep/running';

    public function run()
    {
        if (strtolower((string) getenv('MMS_MODE')) !== 'country') {
            return; // SG instances skip silently
        }

        /** @var MMD_RoleManager_Model_CourseSyncService $svc */
        $svc = Mage::getModel('mmd_rolemanager/courseSyncService');

        if (!$svc->isAutoEnabled()) {
            Mage::log('Course sync skipped — auto-sync disabled.', Zend_Log::INFO, self::LOG_FILE);
            return;
        }
        if (!$svc->isConfigured()) {
            Mage::log('Course sync skipped — SG URL/key not configured.', Zend_Log::WARN, self::LOG_FILE);
            return;
        }
        $running = Mage::getStoreConfig(self::LOCK_CONFIG_PATH);
        if ($running) {
            Mage::log('Course sync skipped — previous run still in progress.', Zend_Log::WARN, self::LOG_FILE);
            return;
        }

        try {
            Mage::getConfig()->saveConfig(self::LOCK_CONFIG_PATH, 1, 'default', 0);
            Mage::getConfig()->reinit();
            $svc->pull('cron');
        } catch (Exception $e) {
            Mage::log('Course sync sweep error: ' . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE);
        } finally {
            Mage::getConfig()->saveConfig(self::LOCK_CONFIG_PATH, 0, 'default', 0);
            Mage::getConfig()->reinit();
        }
    }
}
