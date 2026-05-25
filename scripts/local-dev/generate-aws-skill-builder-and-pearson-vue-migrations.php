<?php
/**
 * Backfill generator for the AWS Skill Builder + AWS Pearson Vue moves.
 *
 * The original one-shot scripts (move-aws-skill-builder-to-additional-note.php
 * and move-aws-pearson-vue-to-block.php) ran on local only and produced JSON
 * reports under media/migrations-reports/ that include the per-product backup
 * of short_description and additional_note / cms_block BEFORE the move.
 *
 * Those backup payloads ARE the current prod values (local was in sync with
 * prod when the scripts ran). So we can generate idempotent SQL that hits
 * prod without re-scraping anything:
 *
 *   - REPLACE(short_description, '<exact section captured pre-move>', '')
 *     is a safe no-op on already-stripped rows.
 *   - additional_note / cms_block writes are guarded against repeat appends.
 *
 * Emits two files:
 *   migrations/154-move-aws-skill-builder-to-additional-note.sql
 *   migrations/155-move-aws-pearson-vue-to-cert-block.sql
 */

require_once __DIR__ . '/../../app/Mage.php';
Mage::app('admin');

$conn = Mage::getSingleton('core/resource')->getConnection('core_read');
$attrShort   = (int) $conn->fetchOne("SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description' AND entity_type_id=4");
$attrAddNote = (int) $conn->fetchOne("SELECT attribute_id FROM eav_attribute WHERE attribute_code='additional_note' AND entity_type_id=4");

// ---------------------------------------------------------------------------
// 154 — AWS Skill Builder → additional_note
// ---------------------------------------------------------------------------
$report = json_decode(file_get_contents(__DIR__ . '/../../media/migrations-reports/move-aws-skill-builder-apply-20260525-043423.json'), true);
$WS  = '(?:\s|&nbsp;|\x{00A0}|\x{2007}|\x{202F})';
$pat = '#<h[1-6][^>]*>' . $WS . '*AWS' . $WS . '+Skill' . $WS . '*Builder' . $WS . '*</h[1-6]>(.*?)(?=(?:<[a-z][a-z0-9]*\b[^>]*>' . $WS . '*)*<h[1-6]|\z)#siu';

$out = [];
$out[] = "-- Migration 154: move 'AWS Skill Builder' section out of short_description";
$out[] = "-- and into additional_note for every AWS course that carries it.";
$out[] = "--";
$out[] = "-- Mirrors what scripts/local-dev/move-aws-skill-builder-to-additional-note.php";
$out[] = "-- already did on local. Backup payloads come from";
$out[] = "-- media/migrations-reports/move-aws-skill-builder-apply-20260525-043423.json";
$out[] = "-- (24 products). Each statement is idempotent — REPLACE() no-ops on";
$out[] = "-- already-stripped rows, and the additional_note UPDATE is guarded by";
$out[] = "-- NOT LIKE so a re-run on already-appended values is a no-op.";
$out[] = "";

foreach ($report['rows'] as $row) {
    if ($row['action'] !== 'moved') continue;
    $sku = $row['sku'];
    $sd  = $row['backup_sd'];
    if (!preg_match($pat, $sd, $m, PREG_OFFSET_CAPTURE)) continue;

    $section = $m[0][0];            // exact substring to REPLACE() out
    $body    = trim($m[1][0]);      // body only, appended to additional_note

    $eid = (int) $conn->fetchOne('SELECT entity_id FROM catalog_product_entity WHERE sku=?', [$sku]);
    if (!$eid) continue;

    $qSection   = $conn->quote($section);
    $qBody2x    = $conn->quote("\n\n" . $body);
    $qBodyOnly  = $conn->quote($body);

    $out[] = "-- {$sku} (entity_id={$eid})";

    // Strip the section from every store-scoped short_description row.
    $out[] = "UPDATE catalog_product_entity_text SET value = REPLACE(value, {$qSection}, '')"
           . " WHERE entity_id = {$eid} AND attribute_id = {$attrShort};";

    // Append body to admin-scope additional_note. NOT LIKE guard prevents
    // double-append on re-run.
    $out[] = "UPDATE catalog_product_entity_text SET value = CONCAT(value, {$qBody2x})"
           . " WHERE entity_id = {$eid} AND attribute_id = {$attrAddNote} AND store_id = 0"
           . " AND value NOT LIKE '%AWS Skill Builder%';";

    // Create admin-scope row if missing.
    $out[] = "INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)"
           . " SELECT 4, {$attrAddNote}, 0, {$eid}, {$qBodyOnly} FROM DUAL"
           . " WHERE NOT EXISTS (SELECT 1 FROM catalog_product_entity_text"
           . "                   WHERE entity_id = {$eid} AND attribute_id = {$attrAddNote} AND store_id = 0);";
    $out[] = "";
}

file_put_contents(__DIR__ . '/../../migrations/154-move-aws-skill-builder-to-additional-note.sql', implode("\n", $out));
fwrite(STDERR, "wrote migration 154 with " . substr_count(implode("\n", $out), 'UPDATE catalog_product_entity_text SET value = REPLACE') . " products\n");

// ---------------------------------------------------------------------------
// 155 — AWS Pearson Vue → per-course course_<sku>_certification cms_block
// ---------------------------------------------------------------------------
$report = json_decode(file_get_contents(__DIR__ . '/../../media/migrations-reports/move-aws-pearson-vue-apply-20260525-044053.json'), true);
$pat = '#<h[1-6][^>]*>' . $WS . '*Certification' . $WS . '+Exam' . $WS . '+at' . $WS . '+Pearson' . $WS . '+Vue' . $WS . '*</h[1-6]>.*?(?=<h[1-6]|\z)#siu';

$out = [];
$out[] = "-- Migration 155: move 'Certification Exam at Pearson Vue' section out of";
$out[] = "-- short_description and into the per-course course_<sku>_certification";
$out[] = "-- cms_block for every AWS course that carries it. AWS analogue of the";
$out[] = "-- CompTIA move done by migration 151.";
$out[] = "--";
$out[] = "-- Mirrors what scripts/local-dev/move-aws-pearson-vue-to-block.php already";
$out[] = "-- did on local. Backup payloads come from";
$out[] = "-- media/migrations-reports/move-aws-pearson-vue-apply-20260525-044053.json";
$out[] = "-- (29 products). Final cms_block content is read live from this DB (which";
$out[] = "-- is the post-move state, identical to the target prod state).";
$out[] = "--";
$out[] = "-- Idempotency: REPLACE() no-ops on stripped rows; cms_block UPDATE writes";
$out[] = "-- the final content unconditionally (already-final rows just overwrite";
$out[] = "-- themselves with the same value).";
$out[] = "";

foreach ($report['rows'] as $row) {
    if ($row['action'] !== 'moved') continue;
    $sku = $row['sku'];
    $sd  = $row['backup_sd'];
    if (!preg_match($pat, $sd, $m, PREG_OFFSET_CAPTURE)) continue;

    $section = $m[0][0];
    $eid = (int) $conn->fetchOne('SELECT entity_id FROM catalog_product_entity WHERE sku=?', [$sku]);
    if (!$eid) continue;

    // Final block content from local (post-move).
    $identifier  = 'course_' . $sku . '_certification';
    $finalBlock  = (string) $conn->fetchOne("SELECT content FROM cms_block WHERE identifier=? ORDER BY block_id LIMIT 1", [$identifier]);
    if ($finalBlock === '') continue; // safety: skip if no block exists locally

    $qSection = $conn->quote($section);
    $qContent = $conn->quote($finalBlock);
    $qIdent   = $conn->quote($identifier);
    $qTitle   = $conn->quote('Certification — ' . $sku);

    $out[] = "-- {$sku} (entity_id={$eid})";

    // 1) Strip the section from every store-scoped short_description row.
    $out[] = "UPDATE catalog_product_entity_text SET value = REPLACE(value, {$qSection}, '')"
           . " WHERE entity_id = {$eid} AND attribute_id = {$attrShort};";

    // 2) Upsert cms_block with the final post-move content.
    $out[] = "UPDATE cms_block SET content = {$qContent}, update_time = NOW() WHERE identifier = {$qIdent};";
    $out[] = "INSERT INTO cms_block (title, identifier, content, is_active, creation_time, update_time)"
           . " SELECT {$qTitle}, {$qIdent}, {$qContent}, 1, NOW(), NOW() FROM DUAL"
           . " WHERE NOT EXISTS (SELECT 1 FROM cms_block c WHERE c.identifier = {$qIdent});";
    $out[] = "INSERT IGNORE INTO cms_block_store (block_id, store_id)"
           . " SELECT block_id, 0 FROM cms_block WHERE identifier = {$qIdent};";
    $out[] = "";
}

file_put_contents(__DIR__ . '/../../migrations/155-move-aws-pearson-vue-to-cert-block.sql', implode("\n", $out));
fwrite(STDERR, "wrote migration 155 with " . substr_count(implode("\n", $out), 'UPDATE catalog_product_entity_text SET value = REPLACE') . " products\n");
