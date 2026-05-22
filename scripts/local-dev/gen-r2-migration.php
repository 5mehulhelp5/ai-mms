<?php
/**
 * Read /tmp/r2-pairs.json and emit a numbered migration file under migrations/
 * that backfills course_image_url onto each SKU's catalog_product_entity_varchar
 * row. Idempotent via INSERT … ON DUPLICATE KEY UPDATE so re-running the same
 * migration on a live DB that's already been backfilled is a no-op.
 *
 * Run: docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/gen-r2-migration.php
 */

$pairs = json_decode((string) file_get_contents('/tmp/r2-pairs.json'), true);
if (!is_array($pairs) || !$pairs) {
    fwrite(STDERR, "No pairs in /tmp/r2-pairs.json\n");
    exit(1);
}

$dir = '/var/www/html/migrations';
$existing = array_filter(scandir($dir) ?: [], fn ($f) => preg_match('/^\d+-/', $f));
$nextNum = 1;
foreach ($existing as $f) {
    if (preg_match('/^(\d+)-/', $f, $m)) {
        $nextNum = max($nextNum, ((int) $m[1]) + 1);
    }
}
$out  = sprintf('%s/%03d-backfill-course-image-url-from-r2.sql', $dir, $nextNum);
$file = fopen($out, 'w');

$header = <<<HEAD
-- Backfill course_image_url with R2 URLs that were generated on localhost.
-- The Bulk AI Covers run on local successfully uploaded 299 PNGs to the
-- shared R2 bucket but the URLs were saved only to the LOCAL DB; live
-- never got them. R2 holds the source of truth for the file paths, so
-- copying the saved mapping into live avoids re-rendering and re-uploading.
--
-- Strategy:
--   1. Look up attribute_id for course_image_url at runtime (avoids
--      hardcoding 203 in case the live install assigned a different id).
--   2. Look up entity_type_id for catalog_product the same way.
--   3. For each SKU we know about, INSERT … ON DUPLICATE KEY UPDATE
--      into catalog_product_entity_varchar at store_id=0 (global scope,
--      matches the attribute's is_global=1 setting).
--
-- Re-runnable: ON DUPLICATE KEY UPDATE makes the second run a no-op.
-- After applying, run "Bulk AI Covers → Refresh storefront" on live to
-- rebuild the flat catalog index and flush block_html / FPC caches.

SET @attr  := (SELECT attribute_id FROM eav_attribute
                WHERE attribute_code='course_image_url' LIMIT 1);
SET @etype := (SELECT entity_type_id FROM eav_entity_type
                WHERE entity_type_code='catalog_product' LIMIT 1);


HEAD;

fwrite($file, $header);

foreach ($pairs as $row) {
    $sku = $row['sku'];
    $url = $row['value'];
    if ($sku === '' || $url === '') {
        continue;
    }
    $skuEsc = str_replace("'", "''", $sku);
    $urlEsc = str_replace("'", "''", $url);
    $stmt = "INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)\n"
          . "SELECT @etype, @attr, 0, entity_id, '{$urlEsc}'\n"
          . "  FROM catalog_product_entity WHERE sku='{$skuEsc}'\n"
          . "ON DUPLICATE KEY UPDATE value=VALUES(value);\n";
    fwrite($file, $stmt);
}

fclose($file);
echo "Wrote {$out} (" . count($pairs) . " statements)\n";
