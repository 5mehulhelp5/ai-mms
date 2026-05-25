<?php
/**
 * Move the "Exam Voucher" section out of short_description and into
 * the additional_note attribute for every CompTIA course.
 *
 *   --dry-run (default)  show what would change, write nothing.
 *   --apply              perform the writes.
 *
 * Run inside the web container:
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/comptia-move-exam-voucher.php
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/comptia-move-exam-voucher.php --apply
 */

require_once __DIR__ . '/../../app/Mage.php';
Mage::app();

$apply = in_array('--apply', $argv ?? [], true);

$collection = Mage::getModel('catalog/product')->getCollection()
    ->addAttributeToSelect(['name', 'sku', 'short_description', 'additional_note'])
    ->addAttributeToFilter('name', ['like' => '%CompTIA%']);

$touched = 0;
$skipped = 0;
$conflicts = 0;

foreach ($collection as $product) {
    $sku  = $product->getSku();
    $name = $product->getName();
    $sd   = (string) $product->getShortDescription();

    if (!preg_match(
        '#(?:<p>\s*</p>\s*)*<h2[^>]*>\s*Exam\s+Voucher\s*</h2>(?<body>.*?)(?=<h[12][^>]*>|\z)#is',
        $sd,
        $m,
        PREG_OFFSET_CAPTURE
    )) {
        $skipped++;
        continue;
    }

    $body = trim($m['body'][0]);
    // Strip leading/trailing empty <p></p> wrappers the WYSIWYG leaves behind.
    $body = preg_replace('#^(?:<p>(?:\s|&nbsp;)*</p>\s*)+#i', '', $body);
    $body = preg_replace('#(?:<p>(?:\s|&nbsp;)*</p>\s*)+$#i', '', $body);
    $body = trim($body);

    // Fix the well-known copy-paste bug: "Autodesk Exam Voucher" inside a CompTIA course.
    $body = preg_replace('/\bAutodesk\s+Exam\s+Voucher\b/', 'CompTIA Exam Voucher', $body);

    $existingNote = trim((string) $product->getAdditionalNote());
    if ($existingNote !== '' && stripos($existingNote, 'Exam Voucher') === false) {
        // Don't clobber a non-empty unrelated note.
        echo "[CONFLICT] {$sku} | {$name} — additional_note already populated, skipping" . PHP_EOL;
        $conflicts++;
        continue;
    }

    $newSd = substr_replace($sd, '', $m[0][1], strlen($m[0][0]));
    // Collapse runs of empty paragraphs left behind by the removal.
    $newSd = preg_replace('#(?:<p>(?:\s|&nbsp;)*</p>\s*){2,}#i', "<p></p>\n", $newSd);
    $newSd = trim($newSd);

    echo "[" . ($apply ? 'APPLY' : 'DRY')   . "] {$sku} | {$name}" . PHP_EOL;
    echo "  → additional_note (" . strlen($body) . " chars)" . PHP_EOL;

    if ($apply) {
        $product->setShortDescription($newSd);
        $product->setAdditionalNote($body);
        $product->getResource()->saveAttribute($product, 'short_description');
        $product->getResource()->saveAttribute($product, 'additional_note');
    }

    $touched++;
}

echo PHP_EOL;
echo "Touched:   {$touched}" . PHP_EOL;
echo "Skipped:   {$skipped} (no Exam Voucher section)" . PHP_EOL;
echo "Conflicts: {$conflicts} (existing additional_note preserved)" . PHP_EOL;

if ($apply && $touched > 0) {
    echo PHP_EOL . "Reindexing catalog_product_flat + flushing caches..." . PHP_EOL;
    try {
        $indexer = Mage::getModel('index/process')->load('catalog_product_flat', 'indexer_code');
        if ($indexer && $indexer->getId()) {
            $indexer->reindexEverything();
        }
    } catch (Exception $e) {
        echo "Reindex warning: " . $e->getMessage() . PHP_EOL;
    }
    Mage::app()->cleanCache(['block_html', 'collections']);
    Mage::app()->getCacheInstance()->cleanType('block_html');
    Mage::app()->getCacheInstance()->cleanType('full_page');
    echo "Done." . PHP_EOL;
}
