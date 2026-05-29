<?php
/**
 * Fix missing per-store course_image_url rows.
 *
 * Symptom: on the admin Edit Course page, the Course Images tab on
 * non-SG country tabs (MY/GH/NG/BT/IN) shows nothing — because the
 * dashboard template reads $_editProd->getData('course_image_url') at
 * the active store scope, and many products have NO per-store row at
 * the country scope. Magento returns null at that scope, so the field
 * appears empty even though scope-0 has a valid URL.
 *
 * Fix: for each product that's on a country website but lacks a
 * per-store course_image_url at that website's store_id, INSERT a row
 * that mirrors the scope-0 value. Idempotent — only fills gaps.
 *
 * The website_id and store_id share the same number for our setup:
 *   website_id=2 ↔ store_id=2 (Malaysia), 3↔3 (Ghana), …
 * (verified by core_store query earlier in this session.)
 *
 * Pass --dry-run to print what would change. --apply to commit.
 */

require_once dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app();

$opts = getopt('', ['dry-run', 'apply']);
$apply = isset($opts['apply']);

$COURSE_IMAGE_URL_ATTR = 203;
$COUNTRIES = [
    2 => 'Malaysia',
    3 => 'Ghana',
    4 => 'Nigeria',
    5 => 'Bhutan',
    6 => 'India',
];

$r = Mage::getSingleton('core/resource')->getConnection('core_read');
$w = Mage::getSingleton('core/resource')->getConnection('core_write');

$totalCreated = 0;

foreach ($COUNTRIES as $wid => $country) {
    // Products on this country's website that have a scope-0
    // course_image_url but no per-store row at the country's scope.
    $rows = $r->fetchAll("
        SELECT pw.product_id, v0.value AS scope0_url
        FROM catalog_product_website pw
        JOIN catalog_product_entity_varchar v0
          ON v0.entity_id = pw.product_id
         AND v0.attribute_id = {$COURSE_IMAGE_URL_ATTR}
         AND v0.store_id = 0
         AND v0.value IS NOT NULL
         AND v0.value <> ''
        LEFT JOIN catalog_product_entity_varchar vs
          ON vs.entity_id = pw.product_id
         AND vs.attribute_id = {$COURSE_IMAGE_URL_ATTR}
         AND vs.store_id = {$wid}
        WHERE pw.website_id = {$wid}
          AND vs.value_id IS NULL
    ");

    foreach ($rows as $row) {
        if ($apply) {
            $w->insert('catalog_product_entity_varchar', [
                'entity_type_id' => 4,
                'attribute_id'   => $COURSE_IMAGE_URL_ATTR,
                'store_id'       => $wid,
                'entity_id'      => (int) $row['product_id'],
                'value'          => (string) $row['scope0_url'],
            ]);
        }
        $totalCreated++;
    }

    printf("  store_id=%d (%s): synthesised=%d per-store image rows\n", $wid, $country, count($rows));
}

printf("\n%s mode. total per-store rows %s=%d.\n",
    $apply ? 'APPLY' : 'DRY-RUN',
    $apply ? 'inserted' : 'would insert',
    $totalCreated
);
