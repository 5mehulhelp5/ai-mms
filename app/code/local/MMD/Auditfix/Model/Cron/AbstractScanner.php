<?php
/**
 * MMD_Auditfix_Model_Cron_AbstractScanner
 *
 * Shared base: tracks last-run timestamps in core_config_data so the
 * admin Cron Schedule page can show next/last run side-by-side with
 * the static cron_expr from config.xml.
 */
abstract class MMD_Auditfix_Model_Cron_AbstractScanner
{
    /** Override in subclass — used for config path + log lines. */
    abstract protected function scannerCode();

    /** Subclass entrypoint. Return [count_logged, count_fixed]. */
    abstract protected function scan();

    public function run()
    {
        $code = $this->scannerCode();
        $start = microtime(true);
        Mage::log("[auditfix:{$code}] start", null, 'mmd-auditfix.log');
        try {
            list($logged, $fixed) = $this->scan();
            $secs = round(microtime(true) - $start, 2);
            $this->saveRunMeta($logged, $fixed, $secs, 'ok');
            Mage::log("[auditfix:{$code}] done logged={$logged} fixed={$fixed} secs={$secs}", null, 'mmd-auditfix.log');
        } catch (Exception $e) {
            $secs = round(microtime(true) - $start, 2);
            $this->saveRunMeta(0, 0, $secs, 'error: ' . $e->getMessage());
            Mage::logException($e);
        }
    }

    protected function saveRunMeta($logged, $fixed, $secs, $status)
    {
        $code = $this->scannerCode();
        $base = "mmd_auditfix/{$code}/";
        $now  = Mage::getSingleton('core/date')->gmtDate();
        $cfg  = Mage::getModel('core/config');
        $cfg->saveConfig($base . 'last_run_at',     $now,    'default', 0);
        $cfg->saveConfig($base . 'last_run_logged', $logged, 'default', 0);
        $cfg->saveConfig($base . 'last_run_fixed',  $fixed,  'default', 0);
        $cfg->saveConfig($base . 'last_run_secs',   $secs,   'default', 0);
        $cfg->saveConfig($base . 'last_run_status', $status, 'default', 0);
    }

    protected function helper()
    {
        return Mage::helper('mmd_auditfix');
    }
}
