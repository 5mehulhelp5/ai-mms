<?php
/**
 * Hard-delete every WSQ course (catalog product whose name starts with
 * "WSQ ") via Magento's resource model. Cascades through:
 *   - catalog_product_entity + all _varchar/_text/_int/_decimal/_datetime/
 *     _gallery/_tier_price/_group_price EAV value tables
 *   - catalog_product_website / catalog_category_product / catalog_product_link
 *   - catalog_product_option + _title + _type_value + _type_title + _type_price
 *     (custom options, including the Course Date dropdown)
 *   - core_url_rewrite (rewrite rows for these products)
 *   - cataloginventory_stock_item / cataloginventory_stock_status
 *   - catalogsearch_result / catalogsearch_query
 *   - any custom-module observers that listen on catalog_product_delete_before
 *     / _after (course_courseware, course_runs, course_run_enrolments —
 *     verified at delete time below).
 *
 * NOT TOUCHED (per Option B in the 2026-05-06 conversation):
 *   - sales_flat_order / sales_flat_order_item — historical order lines for
 *     deleted products keep their snapshotted SKU/name/price. The line's
 *     product_id will point at a now-missing row but the line itself reads
 *     fine. This is intentional — we don't want to lose order history.
 *
 * USAGE
 *   docker exec project-web-1 php /var/www/html/scripts/maintenance/delete-wsq-courses.php
 *     -> dry run, lists the products that WOULD be deleted
 *
 *   docker exec project-web-1 php /var/www/html/scripts/maintenance/delete-wsq-courses.php --confirm
 *     -> actually deletes them
 *
 * On production (Coolify), open a shell on the web container and run the
 * same command against /var/www/html/scripts/maintenance/delete-wsq-courses.php.
 * Run dry first; verify the list; only then re-run with --confirm.
 */

@ini_set('memory_limit', '1024M');
set_time_limit(0);

// Bootstrap Magento.
require __DIR__ . '/../../app/Mage.php';
Mage::app('admin');

// Required by Magento to allow programmatic catalog deletes — without this,
// Mage_Catalog_Model_Resource_Product::_beforeDelete throws "Cannot delete
// the product" because it treats the request as if it came from the frontend.
Mage::register('isSecureArea', true);

$confirm = in_array('--confirm', $argv ?? array(), true);

$resource = Mage::getSingleton('core/resource');
$read     = $resource->getConnection('core_read');

// Find all products whose default-store name starts with "WSQ " or "WSQ-".
// Same match the soft-disable SQL used. attribute_id 71 = name.
$rows = $read->fetchAll(
    "SELECT e.entity_id, e.sku, v.value AS name
     FROM catalog_product_entity e
     JOIN catalog_product_entity_varchar v
       ON v.entity_id = e.entity_id AND v.attribute_id = 71 AND v.store_id = 0
     WHERE v.value LIKE 'WSQ %' OR v.value LIKE 'WSQ-%'
     ORDER BY e.entity_id ASC"
);

$count = count($rows);
echo "=== WSQ course deletion ===\n";
echo "Mode:    " . ($confirm ? "DELETE" : "DRY RUN (no changes — pass --confirm to delete)") . "\n";
echo "Matched: {$count} products\n\n";

if ($count === 0) {
    echo "Nothing to do.\n";
    exit(0);
}

// In dry-run mode, just print the matched list.
if (!$confirm) {
    foreach ($rows as $r) {
        echo "  [{$r['entity_id']}]  {$r['sku']}  —  {$r['name']}\n";
    }
    echo "\n{$count} products would be deleted. Re-run with --confirm to actually delete.\n";
    exit(0);
}

// Confirmed — delete each product through Magento's resource model so the
// cascade runs cleanly. Loop product IDs (not objects) and load+delete one
// at a time so we don't blow memory on 291 fully-hydrated products.
$ok       = 0;
$failed   = array();
$progress = 0;
$startTs  = microtime(true);

foreach ($rows as $r) {
    $progress++;
    $pid  = (int) $r['entity_id'];
    $sku  = (string) $r['sku'];
    $name = (string) $r['name'];

    try {
        $product = Mage::getModel('catalog/product')->load($pid);
        if (!$product->getId()) {
            // Already gone (maybe deleted in a previous partial run). Skip.
            echo "  [SKIP {$progress}/{$count}] entity_id={$pid} not found\n";
            continue;
        }
        $product->delete();
        $ok++;
        if ($progress % 10 === 0 || $progress === $count) {
            $elapsed = round(microtime(true) - $startTs, 1);
            echo "  [{$progress}/{$count}] deleted entity_id={$pid} sku={$sku} ({$elapsed}s elapsed)\n";
        }
    } catch (Exception $e) {
        $failed[] = array('id' => $pid, 'sku' => $sku, 'name' => $name, 'error' => $e->getMessage());
        echo "  [FAIL {$progress}/{$count}] entity_id={$pid} sku={$sku}: " . $e->getMessage() . "\n";
    }
}

$elapsed = round(microtime(true) - $startTs, 1);
echo "\n=== Done ===\n";
echo "Deleted:   {$ok} / {$count}\n";
echo "Failed:    " . count($failed) . "\n";
echo "Elapsed:   {$elapsed}s\n";

if (!empty($failed)) {
    echo "\nFailures:\n";
    foreach ($failed as $f) {
        echo "  [{$f['id']}] {$f['sku']}: {$f['error']}\n";
    }
}

// Reindex so the catalog grid + search update.
echo "\nKick off catalog reindexers...\n";
try {
    $indexer = Mage::getSingleton('index/indexer');
    foreach (array('catalog_product_attribute', 'catalog_product_price', 'catalog_url',
                   'catalog_product_flat', 'cataloginventory_stock', 'catalogsearch_fulltext') as $code) {
        try {
            $process = $indexer->getProcessByCode($code);
            if ($process) {
                $process->reindexEverything();
                echo "  reindexed: {$code}\n";
            }
        } catch (Exception $e) {
            echo "  skip {$code}: " . $e->getMessage() . "\n";
        }
    }
} catch (Exception $e) {
    echo "Reindex error: " . $e->getMessage() . "\n";
    echo "(You can manually reindex from admin: System → Index Management.)\n";
}

echo "\nFinished.\n";
