<?php
/**
 * Daily trainer import sweep from LMS.
 *
 * FAIL-SAFE: gated by mmd/trainer_import/auto_enabled. Absent = OFF, so it
 * ships inert and won't pull even if Magento cron is running, until an admin
 * enables it. Manual "Pull from LMS" is unaffected by this flag.
 */
class MMD_RoleManager_Model_Cron_TrainerImport
{
    const LOG_FILE         = 'trainer-import.log';
    const LOCK_CONFIG_PATH = 'mmd/trainer_import_sweep/running';

    public function run()
    {
        /** @var MMD_RoleManager_Model_TrainerImportService $svc */
        $svc = Mage::getModel('mmd_rolemanager/trainerImportService');

        if (!$svc->isAutoEnabled()) {
            Mage::log('Trainer import skipped — auto-pull disabled.', Zend_Log::INFO, self::LOG_FILE);
            return;
        }
        if (!$svc->isConfigured()) {
            Mage::log('Trainer import skipped — LMS URL/key not configured.', Zend_Log::WARN, self::LOG_FILE);
            return;
        }
        $running = Mage::getStoreConfig(self::LOCK_CONFIG_PATH);
        if ($running) {
            Mage::log('Trainer import skipped — previous run in progress.', Zend_Log::WARN, self::LOG_FILE);
            return;
        }

        try {
            Mage::getConfig()->saveConfig(self::LOCK_CONFIG_PATH, 1, 'default', 0);
            Mage::getConfig()->reinit();
            $svc->pull('cron');
        } catch (Exception $e) {
            Mage::log('Trainer import sweep error: ' . $e->getMessage(), Zend_Log::ERR, self::LOG_FILE);
        } finally {
            Mage::getConfig()->saveConfig(self::LOCK_CONFIG_PATH, 0, 'default', 0);
            Mage::getConfig()->reinit();
        }
    }
}
