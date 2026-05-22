<?php
/**
 * Backfill course_run_enrolments + customer accounts for historical orders.
 *
 * Why this exists:
 *   An en-dash character (–) in a PHP double-quoted string caused
 *   CourseRunEnrolmentService to throw an "Undefined variable" on every
 *   non-TGS order since the service was written.  The exception was swallowed
 *   by the observer try/catch, so checkout never broke — but no
 *   course_run_enrolments rows were created for those orders.
 *
 *   This script replays assignOrderItem() for every complete/processing order.
 *   The service is idempotent:
 *     - _findOrCreateRun() selects before inserting (no duplicate runs).
 *     - _insertEnrolment() uses INSERT IGNORE (no duplicate enrolments).
 *     - _ensureCustomerAccount() checks existence before creating.
 *   So running this script multiple times or against a partially-backfilled DB
 *   is safe.
 *
 * Usage (local):
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/backfill-enrolments.php
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/backfill-enrolments.php --run
 *
 * Usage (production via Coolify exec or SSH):
 *   php /var/www/html/scripts/backfill-enrolments.php          # dry-run first
 *   php /var/www/html/scripts/backfill-enrolments.php --run    # apply
 *
 * Default is DRY RUN — pass --run to actually write to the DB.
 */

require '/var/www/html/app/Mage.php';
Mage::app('admin');

$dryRun = !in_array('--run', $argv ?? array());

echo str_repeat('=', 60) . "\n";
if ($dryRun) {
    echo "DRY RUN — no DB writes. Pass --run to apply.\n";
} else {
    echo "LIVE RUN — writing to DB.\n";
}
echo str_repeat('=', 60) . "\n\n";

$resource = Mage::getSingleton('core/resource');
$read     = $resource->getConnection('core_read');

// Count orders that already have at least one enrolment row so we can
// report how many are genuinely missing vs already backfilled.
$alreadyEnrolledIds = array();
foreach ($read->fetchAll(
    "SELECT DISTINCT o.entity_id
     FROM sales_flat_order o
     JOIN sales_flat_order_item oi ON oi.order_id = o.entity_id
     JOIN course_run_enrolments cre ON cre.product_id = oi.product_id
                                    AND LOWER(cre.learner_email) = LOWER(o.customer_email)
     WHERE o.state IN ('complete','processing')"
) as $r) {
    $alreadyEnrolledIds[(int)$r['entity_id']] = true;
}

$orderRows = $read->fetchAll(
    "SELECT o.entity_id, o.increment_id, o.customer_email, o.state
     FROM sales_flat_order o
     WHERE o.state IN ('complete','processing')
     ORDER BY o.entity_id ASC"
);

$totalOrders   = count($orderRows);
$alreadyDone   = 0;
$processed     = 0;
$itemsReplayed = 0;
$tgsSkipped    = 0;
$noDateSkipped = 0;
$errors        = 0;

echo "Total orders in complete/processing: $totalOrders\n";
echo "Orders with existing enrolment rows: " . count($alreadyEnrolledIds) . "\n\n";

$svc = Mage::getModel('mmd_rolemanager/courseRunEnrolmentService');

foreach ($orderRows as $i => $row) {
    $orderId = (int) $row['entity_id'];

    if (isset($alreadyEnrolledIds[$orderId])) {
        $alreadyDone++;
        // Still replay — INSERT IGNORE skips duplicates; this catches
        // orders that were partially enrolled (e.g. multi-item orders
        // where only some items failed).
    }

    $order = Mage::getModel('sales/order')->load($orderId);
    $items = $order->getAllVisibleItems();

    $orderItemCount = 0;
    foreach ($items as $item) {
        $sku = strtoupper(trim((string) $item->getSku()));

        if (substr($sku, 0, 3) === 'TGS') {
            $tgsSkipped++;
            continue;
        }

        // Peek at options to see if Course Date is present.
        $opts = $item->getProductOptions();
        if (!is_array($opts) || empty($opts)) {
            $raw  = (string) $item->getData('product_options');
            $opts = ($raw !== '') ? @unserialize($raw) : array();
        }
        $hasDate = false;
        if (is_array($opts) && isset($opts['options'])) {
            foreach ($opts['options'] as $o) {
                if (isset($o['label']) && trim($o['label']) === 'Course Date') {
                    $hasDate = true;
                    break;
                }
            }
        }
        if (!$hasDate) {
            // Order item has no Course Date option — service would skip it anyway.
            $noDateSkipped++;
            continue;
        }

        if ($dryRun) {
            $itemsReplayed++;
            $orderItemCount++;
            continue;
        }

        try {
            $svc->assignOrderItem($order, $item);
            $itemsReplayed++;
            $orderItemCount++;
        } catch (Exception $e) {
            echo "  ERROR order #{$row['increment_id']} sku=$sku: " . $e->getMessage() . "\n";
            $errors++;
        }
    }

    if ($orderItemCount > 0) {
        $processed++;
        if ($dryRun) {
            echo "  [dry] order #{$row['increment_id']} ({$row['customer_email']}) — $orderItemCount item(s) would be replayed\n";
        }
    }

    // Progress heartbeat every 50 orders.
    if (($i + 1) % 50 === 0) {
        echo "  ... processed " . ($i + 1) . " / $totalOrders orders\n";
    }
}

echo "\n" . str_repeat('=', 60) . "\n";
echo "Summary\n";
echo str_repeat('=', 60) . "\n";
echo "  Total orders scanned       : $totalOrders\n";
echo "  Already had enrolment rows : $alreadyDone\n";
echo "  Orders with items replayed : $processed\n";
echo "  Items replayed             : $itemsReplayed\n";
echo "  TGS items skipped          : $tgsSkipped\n";
echo "  No-date items skipped      : $noDateSkipped\n";
if (!$dryRun) {
    echo "  Errors                     : $errors\n";
}
if ($dryRun) {
    echo "\nThis was a DRY RUN. Run with --run to apply.\n";
} else {
    echo "\nDone. Check var/log/tgs_class_enrolment.log for per-enrolment detail.\n";
}
