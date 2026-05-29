<?php
/**
 * Audit + fix meta_title country-suffix mismatch across store views.
 *
 * Problem: many products' meta_title at non-SG store scopes ends with
 * "| Tertiary Courses Singapore" (or some other wrong country), because
 * earlier SG-only generation never produced per-store titles. When a
 * user opens the Edit Course page on the Nigeria tab, they see the SG
 * suffix.
 *
 * This script:
 *   1. Audits every meta_title row at store_ids 1..6.
 *   2. For rows whose value ends with "| Tertiary Courses <Country>"
 *      and Country != the store's expected country, rewrites the suffix
 *      to the correct country.
 *   3. For products missing a per-store row at one of those scopes,
 *      synthesises one from the scope-0 default by swapping the suffix.
 *
 * Pass --dry-run to print counts only. Pass --apply to commit changes.
 */

require_once dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app();

$opts = getopt('', ['dry-run', 'apply']);
$apply = isset($opts['apply']);
$dry   = !$apply;

$META_TITLE_ATTR = 82;
$STORES = [
    1 => 'Singapore',
    2 => 'Malaysia',
    3 => 'Ghana',
    4 => 'Nigeria',
    5 => 'Bhutan',
    6 => 'India',
];

$r = Mage::getSingleton('core/resource')->getConnection('core_read');
$w = Mage::getSingleton('core/resource')->getConnection('core_write');

$suffixRe = '/\s*\|\s*Tertiary\s+Courses\s+(Singapore|Malaysia|Ghana|Nigeria|Bhutan|India)\s*\.?\s*$/i';

$totalWrong = 0;
$totalRewritten = 0;
$totalCreated = 0;

foreach ($STORES as $sid => $expected) {
    $rewrittenThisStore = 0;
    $createdThisStore = 0;

    // ---- Pass 1: fix wrong suffix in existing store-scoped rows ----
    $rows = $r->fetchAll("
        SELECT value_id, entity_id, value
        FROM catalog_product_entity_varchar
        WHERE attribute_id = {$META_TITLE_ATTR} AND store_id = {$sid}
    ");
    foreach ($rows as $row) {
        $val = (string) $row['value'];
        if ($val === '') continue;
        if (!preg_match($suffixRe, $val, $m)) continue;
        if (strcasecmp($m[1], $expected) === 0) continue;
        $newVal = preg_replace($suffixRe, ' | Tertiary Courses ' . $expected, $val);
        if (strlen($newVal) > 255) $newVal = substr($newVal, 0, 255);
        if ($apply) {
            $w->update('catalog_product_entity_varchar', ['value' => $newVal], ['value_id = ?' => (int) $row['value_id']]);
        }
        $rewrittenThisStore++;
    }

    // ---- Pass 2: synthesise missing per-store rows from scope-0 ----
    // Find products whose scope-0 meta_title ends with a country suffix
    // but have NO row at this store_id.
    $missing = $r->fetchAll("
        SELECT v0.entity_id, v0.value
        FROM catalog_product_entity_varchar v0
        LEFT JOIN catalog_product_entity_varchar vs
          ON vs.entity_id = v0.entity_id
         AND vs.attribute_id = {$META_TITLE_ATTR}
         AND vs.store_id = {$sid}
        WHERE v0.attribute_id = {$META_TITLE_ATTR}
          AND v0.store_id = 0
          AND vs.value_id IS NULL
          AND v0.value <> ''
    ");
    foreach ($missing as $row) {
        $val = (string) $row['value'];
        if (!preg_match($suffixRe, $val, $m)) continue;
        if (strcasecmp($m[1], $expected) === 0) continue;
        $newVal = preg_replace($suffixRe, ' | Tertiary Courses ' . $expected, $val);
        if (strlen($newVal) > 255) $newVal = substr($newVal, 0, 255);
        if ($apply) {
            $w->insert('catalog_product_entity_varchar', [
                'entity_type_id' => 4,
                'attribute_id'   => $META_TITLE_ATTR,
                'store_id'       => $sid,
                'entity_id'      => (int) $row['entity_id'],
                'value'          => $newVal,
            ]);
        }
        $createdThisStore++;
    }

    printf(
        "  store_id=%d (%s): rewrote=%d  synthesised=%d\n",
        $sid, $expected, $rewrittenThisStore, $createdThisStore
    );
    $totalRewritten += $rewrittenThisStore;
    $totalCreated   += $createdThisStore;
}

printf("\n%s mode. total rewrote=%d total synthesised=%d.\n",
    $apply ? 'APPLY' : 'DRY-RUN',
    $totalRewritten,
    $totalCreated
);
