<?php
// Reindex catalog_category_product to fix products missing from
// storefront category pages. Local-dev only. The site has no
// shell/indexer.php so this is the substitute.
require_once __DIR__ . '/../../app/Mage.php';
Mage::app();

echo "Reindexing catalog_category_product...\n";
$t0 = microtime(true);
try {
    $process = Mage::getSingleton('index/indexer')
        ->getProcessByCode('catalog_category_product');
    if (!$process) { throw new Exception('Process not found'); }
    $process->reindexAll();
    echo "Done in " . number_format(microtime(true) - $t0, 1) . "s.\n";
} catch (Throwable $e) {
    fwrite(STDERR, "FAILED: " . $e->getMessage() . "\n");
    exit(1);
}
