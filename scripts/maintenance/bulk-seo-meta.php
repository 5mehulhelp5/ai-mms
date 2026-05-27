<?php
/**
 * Bulk SEO Meta generator — iterates the product catalog and generates
 * SEO meta for every product across all 6 country stores in one AI call
 * per product (the multi-store prompt at
 * app/code/local/MMD/RoleManager/etc/ai-seo/multi-store.md produces 6
 * country titles + shared keywords + 2 description variants).
 *
 * Resumable via core_config_data['mmd/seo_bulk/last_product_id'] — running
 * this script again picks up where it left off. Reset by passing --reset.
 *
 * Skips products that already have a non-empty meta_title at scope 0
 * (idempotent default) unless --force is passed.
 *
 * Usage (inside the web container):
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/maintenance/bulk-seo-meta.php [--limit=N] [--reset] [--force] [--dry-run]
 *
 * Options:
 *   --limit=N    Process at most N products this run (default: 0 = no limit)
 *   --reset      Reset the resume cursor and start from product_id=0
 *   --force      Regenerate even when scope-0 meta_title is already populated
 *   --dry-run    Don't save — print what would happen
 *   --skus=A,B   Only process these SKUs (comma-separated). Implies --force.
 *
 * Cost: ~1475 products × ~2k tokens prompt + ~1.5k tokens output per
 * product = approximately $50–$150 of Claude API spend depending on
 * model selected in System → Config → Marketing API.
 */

require_once dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app('admin');

$opts = getopt('', ['limit::', 'reset', 'force', 'dry-run', 'skus::']);
$limit  = isset($opts['limit']) ? (int) $opts['limit'] : 0;
$reset  = isset($opts['reset']);
$force  = isset($opts['force']);
$dry    = isset($opts['dry-run']);
$skuArg = isset($opts['skus']) ? trim((string) $opts['skus']) : '';
$skus   = $skuArg !== '' ? array_filter(array_map('trim', explode(',', $skuArg))) : array();
if ($skus) $force = true;   // selecting SKUs always overrides idempotency

$cursorKey = 'mmd/seo_bulk/last_product_id';
if ($reset) {
    Mage::getConfig()->saveConfig($cursorKey, '0');
    Mage::getConfig()->reinit();
    fwrite(STDOUT, "cursor reset.\n");
}
$lastId = (int) Mage::getStoreConfig($cursorKey);

$aiSeo = Mage::getModel('mmd_rolemanager/aiSeo');

$collection = Mage::getModel('catalog/product')->getCollection()
    ->addAttributeToSelect('sku')
    ->addAttributeToSelect('name')
    ->addAttributeToSelect('short_description')
    ->addAttributeToSelect('description')
    ->addAttributeToSelect('meta_title')
    ->setOrder('entity_id', 'ASC');

if (!$skus && $lastId > 0) {
    $collection->addAttributeToFilter('entity_id', array('gt' => $lastId));
}
if ($skus) {
    $collection->addAttributeToFilter('sku', array('in' => $skus));
}

$total     = $collection->getSize();
$processed = 0;
$skipped   = 0;
$failed    = 0;
$start     = time();

fwrite(STDOUT, sprintf(
    "starting bulk SEO meta. candidates=%d cursor=%d limit=%s force=%d dry=%d\n",
    $total, $lastId, $limit ?: 'none', $force ? 1 : 0, $dry ? 1 : 0
));

foreach ($collection as $p) {
    if ($limit > 0 && $processed >= $limit) break;

    $pid = (int) $p->getId();
    $sku = (string) $p->getSku();

    if (!$force && trim((string) $p->getMetaTitle()) !== '') {
        $skipped++;
        if (!$skus) { Mage::getConfig()->saveConfig($cursorKey, (string) $pid); }
        continue;
    }

    fwrite(STDOUT, sprintf("[%d/%d] id=%d sku=%s … ", ($processed + $skipped + $failed + 1), $total, $pid, $sku));

    try {
        $product = Mage::getModel('catalog/product')->load($pid);
        $result  = $aiSeo->generateMultiStore(
            $product,
            (string) $product->getName(),
            strip_tags((string) $product->getData('description')),
            strip_tags((string) $product->getData('short_description'))
        );

        if ($result['stubbed']) {
            $failed++;
            fwrite(STDOUT, "FAILED (" . ($result['stub_reason'] ?? 'no output') . ")\n");
        } else {
            if (!$dry) {
                foreach ($result['per_store'] as $storeId => $row) {
                    $aiSeo->persistToStore(
                        $pid, $storeId, $row['meta_title'], $row['meta_keyword'], $row['meta_description']
                    );
                }
            }
            $processed++;
            fwrite(STDOUT, "OK (" . count($result['per_store']) . " stores)" . ($dry ? " [dry-run]" : "") . "\n");
        }
    } catch (Exception $e) {
        $failed++;
        fwrite(STDOUT, "EXCEPTION: " . $e->getMessage() . "\n");
    }

    if (!$skus && !$dry) {
        Mage::getConfig()->saveConfig($cursorKey, (string) $pid);
    }
}

$elapsed = max(1, time() - $start);
fwrite(STDOUT, sprintf(
    "\ndone. processed=%d skipped=%d failed=%d elapsed=%ds (avg %.1fs/product)\n",
    $processed, $skipped, $failed, $elapsed, $processed > 0 ? $elapsed / $processed : 0
));
