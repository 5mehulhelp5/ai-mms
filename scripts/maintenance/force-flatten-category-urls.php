<?php
/**
 * One-shot force-flatten of every category URL across every store.
 *
 * Why this exists:
 *   On prod, the catalog_url indexer produced deep paths even though the
 *   MMD_FlatCategoryUrl class rewrite was registered — most likely PHP
 *   OPcache + autoload didn't see the class file on the first reindex run
 *   right after deploy, so the override silently fell back to the stock
 *   Mage_Catalog_Model_Url method which prepends parent path.
 *
 * What it does:
 *   For every category in every store, calls MMD_FlatCategoryUrl_Model_Url
 *   ::getCategoryRequestPath (parentPath null) to derive the flat target
 *   request_path (handles url_key collisions via stock getUnusedPathByUrlKey
 *   — appends -1/-2 on real sibling clashes). Then:
 *     - Sets category url_path attribute to the flat path
 *     - Updates the canonical is_system=1 core_url_rewrite row in place
 *     - Adds a save-history is_system=0 rewrite from old long path -> new
 *       short path (preserves link equity / SEO)
 *
 * Idempotent: re-running is a no-op when state is already flat.
 *
 * Triggered by docker/entrypoint.sh after the reindex step, gated by a
 * sentinel at var/.force-flattened-category-urls so it runs ONCE per volume.
 * Delete that sentinel to force a re-run.
 */
declare(strict_types=1);

$repoRoot = dirname(__DIR__, 2);
require $repoRoot . '/app/Mage.php';

Mage::app('admin');
$resource = Mage::getSingleton('core/resource');
$write    = $resource->getConnection('core_write');
$read     = $resource->getConnection('core_read');

$urlModel = Mage::getModel('catalog/url');
$urlClass = get_class($urlModel);
echo "force-flatten: catalog/url runtime class = $urlClass\n";

if ($urlClass !== 'MMD_FlatCategoryUrl_Model_Url') {
    echo "force-flatten: ABORT — MMD_FlatCategoryUrl_Model_Url is NOT the runtime class. Fix module load first.\n";
    exit(1);
}

$stores = Mage::app()->getStores(); // excludes admin store_id=0
echo "force-flatten: " . count($stores) . " stores to process\n";

$changed = 0;
$skipped = 0;
$errors  = 0;

foreach ($stores as $store) {
    $storeId = (int) $store->getId();
    echo "\n--- store {$storeId} ({$store->getCode()}) ---\n";

    // Gather every category for this store's root.
    $rootId = (int) $store->getRootCategoryId();
    if (!$rootId) {
        echo "  no root category, skipping\n";
        continue;
    }

    $catCollection = Mage::getModel('catalog/category')->getCollection()
        ->setStoreId($storeId)
        ->addAttributeToSelect(['url_key', 'url_path', 'name', 'is_active'])
        ->addFieldToFilter('path', ['like' => "1/{$rootId}/%"]);

    foreach ($catCollection as $cat) {
        $catId = (int) $cat->getId();
        if ($catId === $rootId) continue; // skip the root itself

        try {
            // Fresh url model per category so the internal _rewrites cache
            // doesn't carry stale state across categories.
            $u = Mage::getModel('catalog/url');
            $cat->setStoreId($storeId);
            $newPath = $u->getCategoryRequestPath($cat, null);
            $idPath  = 'category/' . $catId;
            $target  = 'catalog/category/view/id/' . $catId;

            // Read existing canonical for this category in this store.
            $existing = $read->fetchRow(
                "SELECT url_rewrite_id, request_path FROM core_url_rewrite
                 WHERE category_id = ? AND product_id IS NULL
                   AND store_id = ? AND is_system = 1
                 LIMIT 1",
                [$catId, $storeId]
            );

            if ($existing && $existing['request_path'] === $newPath) {
                $skipped++;
                continue;
            }

            // Update the canonical row (or insert if missing).
            if ($existing) {
                $oldPath = $existing['request_path'];

                $write->update('core_url_rewrite',
                    ['request_path' => $newPath, 'id_path' => $idPath, 'target_path' => $target],
                    ['url_rewrite_id = ?' => $existing['url_rewrite_id']]
                );

                // Save the old long path as a 301 redirect, if it differs and
                // doesn't already exist. Use ON DUPLICATE for idempotency.
                if ($oldPath && $oldPath !== $newPath) {
                    $write->query(
                        "INSERT INTO core_url_rewrite
                           (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options)
                         VALUES (?, ?, NULL, CONCAT('mmd_flatten_', UUID_SHORT()), ?, ?, 0, 'RP')
                         ON DUPLICATE KEY UPDATE target_path = VALUES(target_path), options = 'RP'",
                        [$storeId, $catId, $oldPath, $newPath]
                    );
                }
            } else {
                $write->insert('core_url_rewrite', [
                    'store_id'     => $storeId,
                    'category_id'  => $catId,
                    'product_id'   => null,
                    'id_path'      => $idPath,
                    'request_path' => $newPath,
                    'target_path'  => $target,
                    'is_system'    => 1,
                    'options'      => null,
                ]);
            }

            // Update the url_path EAV attribute so $category->getUrl() renders flat.
            $cat->setUrlPath($newPath);
            $cat->getResource()->saveAttribute($cat, 'url_path');

            $changed++;
        } catch (Throwable $e) {
            $errors++;
            echo "  ERR cat {$catId}: " . $e->getMessage() . "\n";
        }
    }

    echo "  store {$storeId} done\n";
}

echo "\n--- summary ---\n";
echo "changed: {$changed}\n";
echo "skipped (already flat): {$skipped}\n";
echo "errors: {$errors}\n";

// Drop the reverse-direction save-history rows (short -> long) that the
// botched first reindex created. Keeps only flat-direction redirects.
$cleaned = $write->query(
    "DELETE FROM core_url_rewrite
     WHERE is_system = 0
       AND category_id IS NOT NULL
       AND product_id IS NULL
       AND options = 'RP'
       AND target_path LIKE '%/%'"
);
echo "cleaned reverse-direction redirects: " . $cleaned->rowCount() . "\n";

exit($errors > 0 ? 2 : 0);
