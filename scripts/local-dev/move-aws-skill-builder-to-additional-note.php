<?php
/**
 * Move the "AWS Skill Builder" section out of short_description and append
 * it to the additional_note EAV attribute for every AWS course that
 * currently has it embedded in short_description.
 *
 * Why: short_description is the marketing narrative + structured course
 * sections (handled by per-course cms/blocks). The AWS Skill Builder note
 * is a small call-to-action that belongs in the "Additional Note" card —
 * same place as the canonical "bring your own laptop" line — not in the
 * main description.
 *
 * Behavior per product:
 *   - Find <h?>AWS Skill Builder</h?> + body in short_description (default
 *     scope, store_id=0).
 *   - Append the extracted body (just the paragraphs, no heading) to the
 *     end of additional_note, separated by a blank line. Idempotent: skips
 *     if the AWS link already appears in additional_note.
 *   - Strip the heading + body from short_description.
 *   - Write both at store_id=0 (per memory [[eav-save-attribute-scope]]).
 *   - Backup original short_description and additional_note for rollback.
 *
 * Run:
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/move-aws-skill-builder-to-additional-note.php --dry-run
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/move-aws-skill-builder-to-additional-note.php --apply
 */

declare(strict_types=1);

$flags = [];
foreach ($argv as $a) {
    if (in_array($a, ['--apply','--dry-run'], true)) { $flags[ltrim($a,'-')] = true; }
}
$apply = !empty($flags['apply']);
$mode  = $apply ? 'apply' : 'dry-run';

require_once dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app('admin');
Mage::register('isSecureArea', true);

$pdoR = Mage::getSingleton('core/resource')->getConnection('core_read');
$pdoW = Mage::getSingleton('core/resource')->getConnection('core_write');

$aidSd = (int)$pdoR->fetchOne("SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description' AND entity_type_id=4");
$aidAn = (int)$pdoR->fetchOne("SELECT attribute_id FROM eav_attribute WHERE attribute_code='additional_note' AND entity_type_id=4");
if (!$aidSd || !$aidAn) { fwrite(STDERR, "could not resolve attribute_ids\n"); exit(1); }

$WS = '(?:\s|&nbsp;|\x{00A0}|\x{2007}|\x{202F})';
$pattern = '#<h[1-6][^>]*>' . $WS . '*AWS' . $WS . '+Skill' . $WS . '*Builder' . $WS . '*</h[1-6]>(.*?)(?=(?:<[a-z][a-z0-9]*\b[^>]*>' . $WS . '*)*<h[1-6]|\z)#siu';

// All matches at default scope.
$rows = $pdoR->fetchAll("SELECT cpe.entity_id, cpe.sku, t.value AS sd FROM catalog_product_entity cpe JOIN catalog_product_entity_text t ON t.entity_id=cpe.entity_id AND t.attribute_id=$aidSd AND t.store_id=0 WHERE t.value REGEXP '<h[1-6][^>]*>[^<]*AWS[[:space:]]+Skill[[:space:]]*Builder'");

echo "mode: $mode | candidates: " . count($rows) . "\n";

$report = [
    'generated_at' => gmdate('c'),
    'mode'         => $mode,
    'totals'       => ['seen'=>0, 'moved'=>0, 'skipped_no_match'=>0, 'skipped_already_in_note'=>0],
    'rows'         => [],
];

foreach ($rows as $r) {
    $eid = (int)$r['entity_id']; $sku = (string)$r['sku']; $sd = (string)$r['sd'];
    $report['totals']['seen']++;

    if (!preg_match($pattern, $sd, $m)) {
        $report['totals']['skipped_no_match']++;
        $report['rows'][] = ['sku'=>$sku, 'action'=>'skip-no-match'];
        continue;
    }
    $fullMatch = $m[0];   // heading + body (for stripping from sd)
    $body      = trim($m[1]);  // body only (for appending to additional_note)
    if ($body === '') {
        $report['totals']['skipped_no_match']++;
        continue;
    }

    $note = (string)$pdoR->fetchOne("SELECT value FROM catalog_product_entity_text WHERE attribute_id=$aidAn AND entity_id=? AND store_id=0", [$eid]);

    // Idempotency guard: if additional_note already mentions the AWS Skill
    // Builder link, skip the move (already migrated).
    if (stripos($note, 'aws-skill-builder') !== false || stripos($note, 'AWS Skill Builder') !== false) {
        $report['totals']['skipped_already_in_note']++;
        $report['rows'][] = ['sku'=>$sku, 'action'=>'skip-already-in-note'];
        continue;
    }

    $sep     = ($note !== '' && substr($note, -1) !== "\n") ? "\n\n" : "\n";
    $newNote = ($note === '') ? ('<p><strong>AWS Skill Builder</strong></p>' . "\n" . $body)
                              : ($note . $sep . '<p><strong>AWS Skill Builder</strong></p>' . "\n" . $body);
    $newSd   = preg_replace($pattern, '', $sd, 1) ?? $sd;

    $report['rows'][] = [
        'sku'              => $sku,
        'sd_before_len'    => strlen($sd),
        'sd_after_len'     => strlen($newSd),
        'note_before_len'  => strlen($note),
        'note_after_len'   => strlen($newNote),
        'backup_sd'        => $sd,
        'backup_note'      => $note,
        'action'           => $apply ? 'moved' : 'dry-would-move',
    ];

    if ($apply) {
        $pdoW->update('catalog_product_entity_text', ['value'=>$newSd],   ['attribute_id=?'=>$aidSd, 'entity_id=?'=>$eid, 'store_id=?'=>0]);
        $pdoW->update('catalog_product_entity_text', ['value'=>$newNote], ['attribute_id=?'=>$aidAn, 'entity_id=?'=>$eid, 'store_id=?'=>0]);
    }
    $report['totals']['moved']++;
}

$reportDir = dirname(__DIR__, 2) . '/media/migrations-reports';
if (!is_dir($reportDir)) @mkdir($reportDir, 0775, true);
$reportPath = $reportDir . '/move-aws-skill-builder-' . $mode . '-' . gmdate('Ymd-His') . '.json';
file_put_contents($reportPath, json_encode($report, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");

echo "report: $reportPath\n";
foreach ($report['totals'] as $k=>$v) printf("  %-26s %d\n", $k, $v);
echo "done\n";
