<?php
/**
 * Backend cron: walk sales_flat_order looking for orders newer than the
 * "last processed" pointer and call CourseRunEnrolmentService on each
 * item. Materialises classes (course_runs rows) and learner rosters
 * (course_run_enrolments rows) from the existing checkout flow.
 *
 * Frontend invariant (hard requirement):
 *   This class is ONLY invoked by Magento's cron from the admin/CLI
 *   context. No storefront request path runs this code. sales_flat_order
 *   is read-only here. The only state we mutate outside course_runs /
 *   course_run_enrolments is core_config_data['mmd/class_formation/
 *   last_processed_order_id'] — a key/value Magento already uses for
 *   module config, NOT a sales/checkout/quote table.
 *
 * If the cron is paused or fails the storefront's behaviour is identical
 * to before this code existed.
 */
class MMD_RoleManager_Model_Cron_ClassFormation
{
    const POINTER_PATH = 'mmd/class_formation/last_processed_order_id';
    const FAILURES_PATH = 'mmd/class_formation/recent_failures';
    const BATCH_SIZE   = 200;
    const LOG_FILE     = 'class-formation.log';

    /**
     * Cron entry point — wired from config.xml <crontab>.
     */
    public function run()
    {
        $resource = Mage::getSingleton('core/resource');
        $read     = $resource->getConnection('core_read');
        $write    = $resource->getConnection('core_write');
        $orderTbl = $resource->getTableName('sales_flat_order');

        $last = (int) Mage::getStoreConfig(self::POINTER_PATH);

        $orderIds = $read->fetchCol(
            "SELECT entity_id FROM `$orderTbl`
              WHERE entity_id > ?
                AND state IN ('processing','complete')
              ORDER BY entity_id ASC
              LIMIT " . (int) self::BATCH_SIZE,
            array($last)
        );

        if (!$orderIds) {
            return;
        }

        $service = Mage::getSingleton('mmd_rolemanager/courseRunEnrolmentService');
        if (!$service) {
            $this->_log('ERROR: courseRunEnrolmentService alias did not resolve — aborting batch');
            return;
        }

        $processed = 0;
        $failures  = 0;
        $maxId     = $last;
        foreach ($orderIds as $oid) {
            $oid = (int) $oid;
            try {
                /** @var Mage_Sales_Model_Order $order */
                $order = Mage::getModel('sales/order')->load($oid);
                if (!$order || !$order->getId()) {
                    $maxId = max($maxId, $oid);
                    continue;
                }
                foreach ($order->getAllVisibleItems() as $item) {
                    try {
                        $service->assignOrderItem($order, $item);
                    } catch (Exception $e) {
                        $this->_log("ITEM_ERR order=$oid item={$item->getId()} sku={$item->getSku()}: " . $e->getMessage());
                    }
                }
                $processed++;
            } catch (Exception $e) {
                $failures++;
                $this->_log("ORDER_ERR order=$oid: " . $e->getMessage());
            }
            // Advance pointer regardless of per-order failure so a poison
            // pill doesn't block all subsequent orders. Idempotency of
            // course_run_enrolments (UNIQUE KEY) lets us re-run failed
            // orders later via the maintenance script.
            $maxId = max($maxId, $oid);
        }

        if ($maxId > $last) {
            $this->_savePointer($maxId);
        }
        $this->_log("BATCH last=$last new_max=$maxId processed=$processed failures=$failures");
    }

    private function _savePointer($value)
    {
        $cfg = Mage::getModel('core/config');
        $cfg->saveConfig(self::POINTER_PATH, (string) $value, 'default', 0);
        // Flush only the config cache so the next cron tick reads the
        // new pointer immediately. Block cache and FPC are untouched.
        Mage::app()->getCacheInstance()->cleanType('config');
    }

    private function _log($msg)
    {
        Mage::log($msg, null, self::LOG_FILE);
    }
}
