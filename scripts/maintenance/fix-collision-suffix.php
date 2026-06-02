<?php
/**
 * Emergency fix for the bug introduced by force-flatten-category-urls.php:
 *
 * That script's getUnusedPathByUrlKey call appended "-1" to every category's
 * canonical request_path because the un-suffixed short path was OCCUPIED at
 * the time by save-history rewrites (reverse-direction "short -> long"
 * redirects from the earlier botched reindex). The script then deleted those
 * save-history rows AFTER doing the canonical update, so now the short path
 * is free but every canonical is stuck at "<key>-1.html".
 *
 * This script:
 *   - For every is_system=1 category rewrite whose request_path ends with
 *     "-<digit(s)>.html", check whether the un-suffixed version is free in
 *     the same store. If yes, RENAME the canonical to drop the suffix.
 *   - Update every redirect row whose target_path was the suffixed form to
 *     point at the un-suffixed form.
 *   - Update the matching url_path EAV attribute too.
 *
 * Safe: skips categories where the un-suffixed path is genuinely taken by
 * a different category (real collision — that one keeps its -N).
 */
declare(strict_types=1);

$repoRoot = dirname(__DIR__, 2);
require $repoRoot . '/app/Mage.php';

Mage::app('admin');
$write = Mage::getSingleton('core/resource')->getConnection('core_write');
$read  = Mage::getSingleton('core/resource')->getConnection('core_read');

// Find all canonical category rewrites with a -<digits>.html suffix.
$rows = $read->fetchAll(
    "SELECT url_rewrite_id, store_id, category_id, request_path
     FROM core_url_rewrite
     WHERE is_system = 1
       AND product_id IS NULL
       AND category_id IS NOT NULL
       AND request_path REGEXP '-[0-9]+\\\\.html$'"
);

echo "fix-collision: found " . count($rows) . " suffixed canonicals to inspect\n";

$renamed = 0;
$kept    = 0;
$errors  = 0;

// url_path attribute id (catalog_category)
$attrUrlPath = (int) $read->fetchOne(
    "SELECT attribute_id FROM eav_attribute
     WHERE attribute_code = 'url_path'
       AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_category')"
);

foreach ($rows as $row) {
    $suffixed = $row['request_path'];
    // Strip "-<digits>.html" -> ".html"
    $stripped = preg_replace('/-[0-9]+\.html$/', '.html', $suffixed);
    if ($stripped === null || $stripped === $suffixed) {
        $errors++;
        continue;
    }

    $storeId = (int) $row['store_id'];
    $catId   = (int) $row['category_id'];

    try {
        // Is the un-suffixed path free in this store? "Free" means either no
        // row at all, or only the row currently being renamed.
        $clash = $read->fetchOne(
            "SELECT url_rewrite_id FROM core_url_rewrite
             WHERE store_id = ? AND request_path = ? AND url_rewrite_id <> ?
             LIMIT 1",
            [$storeId, $stripped, (int) $row['url_rewrite_id']]
        );
        if ($clash) {
            $kept++;
            continue; // real collision — leave -N in place
        }

        $write->beginTransaction();

        // 1. Rename the canonical row
        $write->update('core_url_rewrite',
            ['request_path' => $stripped],
            ['url_rewrite_id = ?' => (int) $row['url_rewrite_id']]
        );

        // 2. Repoint any redirect that targets the suffixed path
        $write->update('core_url_rewrite',
            ['target_path' => $stripped],
            ['store_id = ?' => $storeId, 'target_path = ?' => $suffixed]
        );

        // 3. Update the url_path EAV attribute at this store (and store_id=0 fallback)
        $write->update('catalog_category_entity_varchar',
            ['value' => $stripped],
            [
                'entity_id = ?'    => $catId,
                'attribute_id = ?' => $attrUrlPath,
                'store_id IN (?)'  => [$storeId, 0],
                'value = ?'        => $suffixed,
            ]
        );

        $write->commit();
        $renamed++;
    } catch (Throwable $e) {
        $write->rollBack();
        $errors++;
        echo "  ERR cat {$catId} store {$storeId}: " . $e->getMessage() . "\n";
    }
}

echo "renamed: {$renamed}\n";
echo "kept (real collision): {$kept}\n";
echo "errors: {$errors}\n";

exit($errors > 0 ? 2 : 0);
