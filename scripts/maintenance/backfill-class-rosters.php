<?php
/**
 * One-shot CLI backfill — walks every order in sales_flat_order oldest-first
 * and runs CourseRunEnrolmentService::assignOrderItem() on each item to
 * materialise the (course_runs + course_run_enrolments) rows that should
 * have been written if the auto-form cron had existed since day 1.
 *
 * Backend-only. The storefront cart / checkout / payment / email flow
 * never invokes this script. It runs inside the web container's PHP CLI:
 *
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/maintenance/backfill-class-rosters.php
 *
 * Resumable: progress is tracked in
 *   core_config_data['mmd/class_formation/backfill_last_id']
 * Re-running is safe — the unique key on course_run_enrolments
 * (product_id, run_id, learner_email) makes inserts idempotent.
 *
 * Flags:
 *   --reset    Reset backfill pointer to 0 (re-process everything).
 *   --limit=N  Process at most N orders this invocation (default: no limit).
 *   --dry-run  Read orders + parse options but skip writes. For sizing.
 */

require_once dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app('admin');

$POINTER_PATH = 'mmd/class_formation/backfill_last_id';
$LOG_FILE     = 'class-backfill.log';

$opts = getopt('', array('reset', 'limit::', 'dry-run'));
$reset  = isset($opts['reset']);
$limit  = isset($opts['limit']) && $opts['limit'] !== false ? (int) $opts['limit'] : 0;
$dryRun = isset($opts['dry-run']);

if ($reset) {
    Mage::getModel('core/config')->saveConfig($POINTER_PATH, '0', 'default', 0);
    Mage::app()->getCacheInstance()->cleanType('config');
    fwrite(STDOUT, "Reset backfill pointer to 0.\n");
}

$resource = Mage::getSingleton('core/resource');
$read     = $resource->getConnection('core_read');
$orderTbl = $resource->getTableName('sales_flat_order');

$last = (int) Mage::getStoreConfig($POINTER_PATH);
fwrite(STDOUT, "Resuming from order_id > $last" . ($dryRun ? ' (DRY RUN)' : '') . "\n");

$service = Mage::getSingleton('mmd_rolemanager/courseRunEnrolmentService');
if (!$service) {
    fwrite(STDERR, "ERROR: mmd_rolemanager/courseRunEnrolmentService alias did not resolve.\n");
    exit(2);
}

$batchSize = 200;
$totalOrders = 0;
$totalItems  = 0;
$totalErrors = 0;
$startedAt   = microtime(true);

while (true) {
    if ($limit && $totalOrders >= $limit) break;

    $orderIds = $read->fetchCol(
        "SELECT entity_id FROM `$orderTbl`
          WHERE entity_id > ?
            AND state IN ('processing','complete')
          ORDER BY entity_id ASC
          LIMIT $batchSize",
        array($last)
    );
    if (!$orderIds) break;

    foreach ($orderIds as $oid) {
        $oid = (int) $oid;
        try {
            $order = Mage::getModel('sales/order')->load($oid);
            if (!$order || !$order->getId()) {
                $last = max($last, $oid);
                continue;
            }
            foreach ($order->getAllVisibleItems() as $item) {
                $totalItems++;
                if ($dryRun) continue;
                try {
                    $service->assignOrderItem($order, $item);
                } catch (Exception $e) {
                    $totalErrors++;
                    Mage::log("backfill item_err order=$oid sku={$item->getSku()}: " . $e->getMessage(), null, $LOG_FILE);
                }
            }
            $totalOrders++;
        } catch (Exception $e) {
            $totalErrors++;
            Mage::log("backfill order_err order=$oid: " . $e->getMessage(), null, $LOG_FILE);
        }
        $last = max($last, $oid);
        if ($limit && $totalOrders >= $limit) break;
    }

    // Persist pointer every batch so a Ctrl-C is recoverable.
    if (!$dryRun) {
        Mage::getModel('core/config')->saveConfig($POINTER_PATH, (string) $last, 'default', 0);
    }
    fwrite(STDOUT, sprintf("  processed=%d items=%d errors=%d last_id=%d\n", $totalOrders, $totalItems, $totalErrors, $last));
}

if (!$dryRun) {
    Mage::app()->getCacheInstance()->cleanType('config');
}
$elapsed = round(microtime(true) - $startedAt, 1);
fwrite(STDOUT, "\nDone. orders=$totalOrders items=$totalItems errors=$totalErrors elapsed={$elapsed}s last_id=$last\n");
fwrite(STDOUT, "Log: var/log/$LOG_FILE\n");
