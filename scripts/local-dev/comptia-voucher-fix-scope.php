<?php
/**
 * Repair pass for comptia-move-exam-voucher.php.
 *
 * That script ran at SG store scope (store_id=1), creating per-store
 * overrides on short_description and additional_note. As a result MY/NG/GH/BT/IN
 * still saw the old data. This script promotes both changes to admin scope
 * (store_id=0) so every country store inherits them, and merges the existing
 * admin-scope "Please bring your own laptop..." note ahead of the voucher copy.
 *
 *   --dry-run (default)  show plan, write nothing.
 *   --apply              commit.
 */

require_once __DIR__ . '/../../app/Mage.php';
Mage::app();

$apply = in_array('--apply', $argv ?? [], true);

$res    = Mage::getSingleton('core/resource');
$read   = $res->getConnection('core_read');
$write  = $res->getConnection('core_write');
$table  = $res->getTableName('catalog_product_entity_text');

$attrAddNote = (int) $read->fetchOne("SELECT attribute_id FROM eav_attribute WHERE attribute_code='additional_note' AND entity_type_id=4");
$attrShort   = (int) $read->fetchOne("SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description' AND entity_type_id=4");

// Source-of-truth: every product where the previous run wrote an SG-scope
// additional_note override. That is exactly the set of "touched" CompTIA courses.
$rows = $read->fetchAll(
    "SELECT t.entity_id, t.value AS sg_note, pe.sku
       FROM {$table} t
       JOIN catalog_product_entity pe ON pe.entity_id = t.entity_id
      WHERE t.attribute_id = ?
        AND t.store_id     = 1
        AND pe.sku IN (
            SELECT sku FROM catalog_product_entity pe2
             JOIN catalog_product_entity_varchar v ON v.entity_id = pe2.entity_id
            WHERE 1=0
        )
        OR (t.attribute_id = ? AND t.store_id = 1
            AND (t.value LIKE '%Exam Voucher%' OR t.value LIKE '%exam voucher%')
            AND EXISTS (
              SELECT 1 FROM catalog_product_entity_varchar nv
              JOIN eav_attribute ea ON ea.attribute_id = nv.attribute_id
              WHERE ea.attribute_code='name' AND ea.entity_type_id=4
                AND nv.entity_id = t.entity_id AND nv.value LIKE '%CompTIA%'
            )
        )",
    [$attrAddNote, $attrAddNote]
);

echo "Candidate rows: " . count($rows) . PHP_EOL;

$fixed = 0;
foreach ($rows as $r) {
    $entityId = (int) $r['entity_id'];
    $sku      = $r['sku'];
    $sgNote   = (string) $r['sg_note'];

    // 1. additional_note: merge admin "laptop" note + SG voucher copy, write to admin.
    $adminNote = (string) $read->fetchOne(
        "SELECT value FROM {$table} WHERE entity_id=? AND attribute_id=? AND store_id=0",
        [$entityId, $attrAddNote]
    );
    if (stripos($adminNote, 'Exam Voucher') !== false || stripos($adminNote, 'exam voucher') !== false) {
        $mergedNote = $adminNote; // already merged from a prior run
    } else {
        $mergedNote = trim($adminNote);
        $mergedNote = ($mergedNote === '') ? $sgNote : ($mergedNote . "\n\n" . $sgNote);
    }

    // 2. short_description: copy the cleaned SG version to admin scope.
    $sgShort = (string) $read->fetchOne(
        "SELECT value FROM {$table} WHERE entity_id=? AND attribute_id=? AND store_id=1",
        [$entityId, $attrShort]
    );
    $adminShort = (string) $read->fetchOne(
        "SELECT value FROM {$table} WHERE entity_id=? AND attribute_id=? AND store_id=0",
        [$entityId, $attrShort]
    );

    echo "[" . ($apply ? 'APPLY' : 'DRY') . "] {$sku} (entity={$entityId})" . PHP_EOL;
    echo "    additional_note admin: " . strlen($adminNote) . " -> " . strlen($mergedNote) . " chars" . PHP_EOL;
    if ($sgShort !== '' && $sgShort !== $adminShort) {
        echo "    short_description admin: " . strlen($adminShort) . " -> " . strlen($sgShort) . " chars (voucher section stripped)" . PHP_EOL;
    }

    if ($apply) {
        // Promote additional_note to admin
        $existing = $read->fetchOne(
            "SELECT value_id FROM {$table} WHERE entity_id=? AND attribute_id=? AND store_id=0",
            [$entityId, $attrAddNote]
        );
        if ($existing) {
            $write->update($table, ['value' => $mergedNote], ['value_id = ?' => (int) $existing]);
        } else {
            $write->insert($table, [
                'entity_type_id' => 4,
                'attribute_id'   => $attrAddNote,
                'store_id'       => 0,
                'entity_id'      => $entityId,
                'value'          => $mergedNote,
            ]);
        }
        // Delete SG override so MY/NG/GH/BT/IN/SG all read the admin value
        $write->delete($table, [
            'entity_id = ?'    => $entityId,
            'attribute_id = ?' => $attrAddNote,
            'store_id = ?'     => 1,
        ]);

        // Promote short_description to admin and drop SG override
        if ($sgShort !== '' && $sgShort !== $adminShort) {
            $existingS = $read->fetchOne(
                "SELECT value_id FROM {$table} WHERE entity_id=? AND attribute_id=? AND store_id=0",
                [$entityId, $attrShort]
            );
            if ($existingS) {
                $write->update($table, ['value' => $sgShort], ['value_id = ?' => (int) $existingS]);
            } else {
                $write->insert($table, [
                    'entity_type_id' => 4,
                    'attribute_id'   => $attrShort,
                    'store_id'       => 0,
                    'entity_id'      => $entityId,
                    'value'          => $sgShort,
                ]);
            }
            $write->delete($table, [
                'entity_id = ?'    => $entityId,
                'attribute_id = ?' => $attrShort,
                'store_id = ?'     => 1,
            ]);
        }
    }
    $fixed++;
}

echo PHP_EOL . "Repaired: {$fixed}" . PHP_EOL;

if ($apply && $fixed > 0) {
    echo "Reindexing + cache flush..." . PHP_EOL;
    try {
        $indexer = Mage::getModel('index/process')->load('catalog_product_flat', 'indexer_code');
        if ($indexer && $indexer->getId()) {
            $indexer->reindexEverything();
        }
    } catch (Exception $e) {
        echo "Reindex warning: " . $e->getMessage() . PHP_EOL;
    }
    Mage::app()->getCacheInstance()->cleanType('block_html');
    Mage::app()->getCacheInstance()->cleanType('full_page');
    Mage::app()->getCacheInstance()->cleanType('collections');
    echo "Done." . PHP_EOL;
}
