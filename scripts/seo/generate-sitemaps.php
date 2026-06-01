<?php
/**
 * One-shot sitemap generator. Runs all sitemap rows in the `sitemap` table
 * sequentially, the same way the daily cron does — so per-store sitemap files
 * exist as soon as migration 163 has been applied, instead of waiting up to
 * 24 hours for the next cron tick.
 *
 * Usage:
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/seo/generate-sitemaps.php
 */

require_once dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app('admin');

$collection = Mage::getModel('sitemap/sitemap')->getCollection();
$count = 0;
foreach ($collection as $sitemap) {
    $id = $sitemap->getId();
    $store = $sitemap->getStoreId();
    $file = $sitemap->getSitemapFilename();
    try {
        $sitemap->generateXml();
        $count++;
        printf("[ok]   store=%s file=%s\n", $store, $file);
    } catch (Throwable $e) {
        printf("[fail] store=%s file=%s err=%s\n", $store, $file, $e->getMessage());
    }
}
printf("Generated %d sitemap(s).\n", $count);
