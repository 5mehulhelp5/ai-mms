<?php
/**
 * One-shot diagnostic: dump flat-category-URL state to /media/flat-url-debug.json
 * so we can see, without prod shell access, whether MMD_FlatCategoryUrl loaded
 * correctly and whether the reindex actually wrote flat rewrites.
 *
 * Called from docker/entrypoint.sh after the reindex step.
 */
declare(strict_types=1);

$repoRoot = dirname(__DIR__, 2);
require $repoRoot . '/app/Mage.php';

try {
    Mage::app();
    $resource = Mage::getSingleton('core/resource');
    $read     = $resource->getConnection('core_read');

    $cfgNode = Mage::getConfig()->getNode('global/models/catalog/rewrite/url');
    $catalogUrlClass = $cfgNode ? (string) $cfgNode : null;

    $modulesNode = Mage::getConfig()->getNode('modules/MMD_FlatCategoryUrl');
    $moduleActive = $modulesNode ? ((string) $modulesNode->active === 'true') : null;

    $instance = Mage::getModel('catalog/url');
    $instanceClass = $instance ? get_class($instance) : null;

    // Pick a known-deep category (cat 196 = WSQ Agentic AI Courses).
    $catId = 196;
    $rewrites = $read->fetchAll(
        "SELECT store_id, request_path, target_path, is_system, options
         FROM core_url_rewrite
         WHERE category_id = ? AND product_id IS NULL
         ORDER BY store_id, is_system DESC, request_path
         LIMIT 30",
        [$catId]
    );

    $urlPaths = [];
    foreach ([1, 2, 3, 4, 5, 6, 7] as $sid) {
        try {
            $cat = Mage::getModel('catalog/category')->setStoreId($sid)->load($catId);
            $urlPaths[$sid] = $cat->getId() ? (string) $cat->getUrlPath() : null;
        } catch (Throwable $e) {
            $urlPaths[$sid] = 'ERR: ' . $e->getMessage();
        }
    }

    $marker = $repoRoot . '/var/.reindexed-flat-urls';
    $markerInfo = file_exists($marker)
        ? ['exists' => true, 'mtime' => gmdate('c', filemtime($marker))]
        : ['exists' => false];

    $payload = [
        'timestamp'                 => gmdate('c'),
        'module_active'             => $moduleActive,
        'catalog_url_rewrite_class' => $catalogUrlClass,
        'catalog_url_runtime_class' => $instanceClass,
        'reindex_marker'            => $markerInfo,
        'sample_category_196'       => [
            'url_paths_per_store' => $urlPaths,
            'rewrites'            => $rewrites,
        ],
    ];

    $target = $repoRoot . '/media/flat-url-debug.json';
    file_put_contents($target, json_encode($payload, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
    @chmod($target, 0644);
    echo "wrote $target\n";
} catch (Throwable $e) {
    $payload = ['timestamp' => gmdate('c'), 'error' => $e->getMessage()];
    @file_put_contents($repoRoot . '/media/flat-url-debug.json', json_encode($payload));
    echo "ERROR: " . $e->getMessage() . "\n";
    exit(1);
}
