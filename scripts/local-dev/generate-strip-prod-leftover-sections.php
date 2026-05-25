<?php
/**
 * Generator for the "strip leftover prod sections" migration.
 *
 * Why this exists:
 *   - Migration 151 was supposed to strip <hN>Certification Exam at Pearson
 *     Vue</hN> from short_description for CompTIA courses, but its generator
 *     only emitted the strip SQL when local STILL had the section. By the
 *     time it ran, local was already pre-migrated by an earlier script, so
 *     the strip statements were never written into 151.
 *   - Migration 152 DID emit REPLACE statements for the Exam Voucher section
 *     and they're byte-for-byte identical to prod's stored content, but the
 *     REPLACE didn't take effect on prod (CONCAT in the same migration did
 *     run — additional_note has the appended voucher). Likely a backslash
 *     escape interpretation difference. UNHEX() side-steps that entirely.
 *
 * Strategy: for every CompTIA product (and any AWS product still showing
 * leftovers), scrape prod, capture the exact section bytes, emit
 * `REPLACE(value, UNHEX('...'), '')`. UNHEX takes a hex literal — no
 * backslash interpretation, no quote escaping, just raw bytes.
 *
 * Run:
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/generate-strip-prod-leftover-sections.php \
 *     > migrations/156-strip-leftover-prod-sections.sql
 */

require_once __DIR__ . '/../../app/Mage.php';
Mage::app('admin');

$conn = Mage::getSingleton('core/resource')->getConnection('core_read');
$attrShort = (int) $conn->fetchOne("SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description' AND entity_type_id=4");

// All courses whose name flags them as CompTIA or AWS. Scrape each, capture
// any <hN> sections left in prod's short_description that should already
// have been moved out (Exam Voucher, Certification Exam at Pearson Vue,
// AWS Skill Builder).
$rows = $conn->fetchAll(
    "SELECT p.entity_id, p.sku, uk.value AS url_key, nm.value AS name"
    . " FROM catalog_product_entity p"
    . " JOIN catalog_product_entity_varchar nm ON nm.entity_id=p.entity_id"
    . "   AND nm.attribute_id=(SELECT attribute_id FROM eav_attribute WHERE attribute_code='name' AND entity_type_id=4)"
    . "   AND nm.store_id=0"
    . " JOIN catalog_product_entity_varchar uk ON uk.entity_id=p.entity_id"
    . "   AND uk.attribute_id=(SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_key' AND entity_type_id=4)"
    . "   AND uk.store_id=0"
    . " WHERE nm.value LIKE '%CompTIA%' OR nm.value LIKE '%AWS%'"
    . " ORDER BY p.entity_id"
);

$out = [];
$out[] = "-- Migration 156: strip leftover prod sections from short_description.";
$out[] = "--";
$out[] = "-- For every CompTIA/AWS course where prod's short_description still";
$out[] = "-- contains an <hN> section that should already have been moved out";
$out[] = "-- (Exam Voucher, Certification Exam at Pearson Vue, AWS Skill Builder),";
$out[] = "-- REPLACE() the exact byte sequence using UNHEX() hex literals so MySQL";
$out[] = "-- string escape interpretation can't drop the match the way it did for";
$out[] = "-- migrations 151 and 152.";
$out[] = "--";
$out[] = "-- Source of truth: live scrape of tertiarycourses.com.sg at generation";
$out[] = "-- time. Re-running on rows where the section has already been stripped";
$out[] = "-- is a safe REPLACE no-op.";
$out[] = "";

$ctx = stream_context_create(['http' => ['timeout' => 15, 'user_agent' => 'mms-migrator/1.0']]);
$stats = ['scraped' => 0, 'stripped' => 0, 'fetch_fail' => 0];

// Each pattern captures heading + body up to the next h1/h2 (or end). The
// optional leading empty <p></p> swallows the blank paragraph the WYSIWYG
// usually leaves above the heading.
$sectionPatterns = [
    'exam-voucher'    => '#(?:<p>\s*</p>\s*)?<h2[^>]*>\s*Exam\s+Voucher\s*</h2>.*?(?=<h[12]\b|\z)#siu',
    'pearson-vue'     => '#(?:<p>\s*</p>\s*)?<h2[^>]*>\s*Certification\s+Exam\s+at\s+Pearson\s+Vue\s*</h2>.*?(?=<h[12]\b|\z)#siu',
    'aws-skill-bldr'  => '#(?:<p>\s*</p>\s*)?<h2[^>]*>\s*AWS\s+Skill\s+Builder\s*</h2>.*?(?=<h[12]\b|\z)#siu',
];

foreach ($rows as $row) {
    $sku    = $row['sku'];
    $eid    = (int) $row['entity_id'];
    $urlKey = $row['url_key'];
    if ($urlKey === '') continue;

    $url  = 'https://www.tertiarycourses.com.sg/' . $urlKey . '.html';
    $html = @file_get_contents($url, false, $ctx);
    if ($html === false) { $stats['fetch_fail']++; fwrite(STDERR, "fetch fail: {$sku}\n"); continue; }
    $stats['scraped']++;

    if (!preg_match('#<div class="short-description">.*?<div class="std"[^>]*>(.*?)</div>\s*</div>#siu', $html, $sd)) continue;
    $sdInner = $sd[1];

    $sectionHits = [];
    foreach ($sectionPatterns as $key => $pat) {
        if (preg_match($pat, $sdInner, $m)) {
            $sectionHits[$key] = $m[0];
        }
    }

    if (!$sectionHits) continue;

    $out[] = "-- {$sku} (entity_id={$eid}): " . implode(', ', array_keys($sectionHits));
    foreach ($sectionHits as $key => $bytes) {
        $hex = bin2hex($bytes);
        $out[] = "UPDATE catalog_product_entity_text SET value = REPLACE(value, UNHEX('{$hex}'), '')"
               . " WHERE entity_id = {$eid} AND attribute_id = {$attrShort};";
        $stats['stripped']++;
    }
    $out[] = "";
}

fwrite(STDERR, "Stats: " . json_encode($stats) . "\n");
echo implode("\n", $out);
