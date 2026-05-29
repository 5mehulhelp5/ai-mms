<?php
require_once dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app();

$r = Mage::getSingleton('core/resource')->getConnection('core_read');
$map = [1 => 'Singapore', 2 => 'Malaysia', 3 => 'Ghana', 4 => 'Nigeria', 5 => 'Bhutan', 6 => 'India'];

$header = <<<'SQL'
-- 181-backfill-per-store-meta-title.sql
--
-- Backfill per-store meta_title rows for every product so each country
-- store_id (1-6) has its own row whose "| Tertiary Courses <Country>"
-- suffix matches the store. Complements migrations 176/177 which fixed
-- existing wrong-country values — this one synthesises the MISSING
-- per-store rows for products that previously only had a scope-0
-- default. Without these rows the admin Edit Course page (and Google,
-- via the storefront <title> tag) shows the SG-suffixed default on
-- non-SG country tabs.
--
SQL;

echo $header . "\n";
echo '-- Generated ' . date('Y-m-d') . " from local DB.\n";
echo "-- Idempotent: INSERT IGNORE skips rows where the (entity_id,\n";
echo "-- attribute_id, store_id) unique key already exists, so it never\n";
echo "-- overwrites a title the prod admin authored later.\n\n";
echo "INSERT IGNORE INTO catalog_product_entity_varchar\n";
echo "    (entity_type_id, attribute_id, store_id, entity_id, value)\n";
echo "VALUES\n";

$first = true;
foreach ($map as $sid => $country) {
    $rows = $r->fetchAll(
        "SELECT entity_id, value FROM catalog_product_entity_varchar
         WHERE attribute_id = 82 AND store_id = {$sid}
           AND value LIKE :pat
         ORDER BY entity_id",
        ['pat' => '%| Tertiary Courses ' . $country . '%']
    );
    foreach ($rows as $row) {
        $val = str_replace('\\', '\\\\', $row['value']);
        $val = str_replace("'", "\\'", $val);
        $line = sprintf("(4,82,%d,%d,'%s')", $sid, (int) $row['entity_id'], $val);
        echo ($first ? '' : ",\n") . $line;
        $first = false;
    }
}
echo ";\n";
