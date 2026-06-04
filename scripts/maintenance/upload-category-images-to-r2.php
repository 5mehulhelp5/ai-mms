<?php

/**
 * Upload every category banner referenced by the catalog to Cloudflare R2.
 *
 * Why this exists:
 *   media/catalog/category/ is excluded from the Docker image (.dockerignore)
 *   to keep the build context small. Product course-covers already live on R2
 *   (course_image_url attribute), but CATEGORY banners still resolve via stock
 *   Mage_Catalog_Model_Category::getImageUrl() -> /media/catalog/category/<f>.
 *   On prod that path is absent from the container, so the request falls
 *   through media/.htaccess to get.php and 500s -> every category banner breaks.
 *
 * Fix (two parts):
 *   1. This script PUTs each referenced banner to R2 under key
 *      "catalog/category/<filename>", so the public URL becomes
 *      <R2_PUBLIC_URL>/catalog/category/<filename>.
 *   2. media/.htaccess redirects any missing /media/catalog/category/* request
 *      to that R2 public URL (before the get.php fallback).
 *
 * Re-runnable: PutObject overwrites; safe to run repeatedly. Reads the live
 * DB so newly-added category images are picked up on the next run.
 *
 * Usage (inside the web container, where .env R2_* are present):
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/maintenance/upload-category-images-to-r2.php
 *   add --dry-run to list what would upload without touching R2.
 */

require_once __DIR__ . '/../../app/Mage.php';

Mage::app();

$dryRun = in_array('--dry-run', $argv, true);

$mediaDir = realpath(__DIR__ . '/../../media/catalog/category');
$backupDir = realpath(__DIR__ . '/../../.magento/media/catalog/category');

if (!$mediaDir) {
    fwrite(STDERR, "media/catalog/category not found\n");
    exit(1);
}

/** @var MMD_CourseImage_Helper_R2 $r2 */
$r2 = Mage::helper('mmd_courseimage/r2');

$conn = Mage::getSingleton('core/resource')->getConnection('core_read');
$attrId = (int) Mage::getModel('eav/config')
    ->getAttribute('catalog_category', 'image')
    ->getId();

$values = $conn->fetchCol(
    "SELECT DISTINCT value FROM catalog_category_entity_varchar
     WHERE attribute_id = ? AND value IS NOT NULL AND value <> ''",
    [$attrId]
);

$contentTypes = [
    'png'  => 'image/png',
    'jpg'  => 'image/jpeg',
    'jpeg' => 'image/jpeg',
    'gif'  => 'image/gif',
    'webp' => 'image/webp',
];

$uploaded = $skipped = $failed = 0;

foreach ($values as $value) {
    $rel = ltrim((string) $value, '/');

    $path = $mediaDir . '/' . $rel;
    if (!is_file($path) && $backupDir && is_file($backupDir . '/' . $rel)) {
        $path = $backupDir . '/' . $rel; // fall back to the .magento backup copy
    }

    if (!is_file($path)) {
        fwrite(STDERR, "MISSING local file for: {$rel}\n");
        $failed++;
        continue;
    }

    $ext = strtolower(pathinfo($path, PATHINFO_EXTENSION));
    $ct = $contentTypes[$ext] ?? 'application/octet-stream';
    $key = 'catalog/category/' . $rel;

    if ($dryRun) {
        echo "WOULD UPLOAD {$key} ({$ct}, " . filesize($path) . " bytes)\n";
        $skipped++;
        continue;
    }

    try {
        $res = $r2->putObject($key, file_get_contents($path), $ct);
        echo "OK {$res['url']} ({$res['bytes']} bytes)\n";
        $uploaded++;
    } catch (Exception $e) {
        fwrite(STDERR, "FAIL {$key}: " . $e->getMessage() . "\n");
        $failed++;
    }
}

echo "\n--- done: uploaded={$uploaded} skipped={$skipped} failed={$failed} total=" . count($values) . " ---\n";
exit($failed > 0 ? 1 : 0);
