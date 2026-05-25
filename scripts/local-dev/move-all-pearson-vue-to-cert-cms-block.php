<?php
/**
 * Move the "Certification Exam at Pearson Vue" section out of
 * short_description and append it to the per-course Certification cms/block
 * for EVERY product that carries it — not just AWS.
 *
 * Generalised version of move-aws-pearson-vue-to-cert-cms-block.php:
 *   - No brand filter (processes Microsoft / Cisco / Autodesk / etc.)
 *   - Auto-creates the per-course cert cms/block when missing (seeds it
 *     with the standard MY cert baseline + Pearson Vue suffix so the
 *     non-SG fallback chain doesn't lose Certificate of Completion).
 *
 * Same marker format as before (`<p><strong>Certification Exam at Pearson
 * Vue</strong></p>`) — view.phtml's SG cert branch already looks for it
 * and appends it after the hardcoded Cert-of-Completion template.
 *
 * Idempotent: skips products whose per-course cert cms/block already
 * contains "Pearson Vue". JSON report includes per-product backups for
 * rollback.
 *
 * Run:
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/move-all-pearson-vue-to-cert-cms-block.php --dry-run
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/move-all-pearson-vue-to-cert-cms-block.php --apply
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

$WS = '(?:\s|&nbsp;|\x{00A0}|\x{2007}|\x{202F})';
$pattern = '#<h[1-6][^>]*>' . $WS . '*Certification' . $WS . '+Exam' . $WS . '+at' . $WS . '+Pearson' . $WS . '+Vue' . $WS . '*</h[1-6]>(.*?)(?=(?:<[a-z][a-z0-9]*\b[^>]*>' . $WS . '*)*<h[1-6]|\z)#siu';

$rows = $pdoR->fetchAll("SELECT cpe.entity_id, cpe.sku, t.value AS sd
  FROM catalog_product_entity cpe
  JOIN catalog_product_entity_text t ON t.entity_id=cpe.entity_id AND t.attribute_id=$aidSd AND t.store_id=0
  WHERE t.value REGEXP '<h[1-6][^>]*>[^<]*Certification[[:space:]]+Exam[[:space:]]+at[[:space:]]+Pearson'");

echo "mode: $mode | candidates: " . count($rows) . "\n";

$baselineCert = '<ul><li><strong>Certificate of Completion from Tertiary Courses</strong> - Upon meeting at least 75% attendance and passing the assessment(s), participants will receive a Certificate of Completion from Tertiary Courses.</li></ul>';

$report = ['generated_at'=>gmdate('c'), 'mode'=>$mode, 'totals'=>['seen'=>0,'moved'=>0,'created_block'=>0,'skipped_already'=>0,'skipped_no_match'=>0], 'rows'=>[]];

foreach ($rows as $r) {
    $eid = (int)$r['entity_id']; $sku = (string)$r['sku']; $sd = (string)$r['sd'];
    $report['totals']['seen']++;

    if (!preg_match($pattern, $sd, $m)) {
        $report['totals']['skipped_no_match']++;
        $report['rows'][] = ['sku'=>$sku, 'action'=>'skip-no-match'];
        continue;
    }
    $body = trim($m[1]);
    if ($body === '') { $report['totals']['skipped_no_match']++; continue; }

    $blockId = 'course_' . $sku . '_certification';
    $block   = Mage::getModel('cms/block')->load($blockId, 'identifier');
    $cur     = $block->getId() ? (string)$block->getContent() : '';

    if ($cur !== '' && (stripos($cur, 'Pearson Vue') !== false || stripos($cur, 'Certification Exam at Pearson') !== false)) {
        $report['totals']['skipped_already']++;
        $report['rows'][] = ['sku'=>$sku, 'action'=>'skip-already-in-block'];
        continue;
    }

    $pvMarker = "\n<p><strong>Certification Exam at Pearson Vue</strong></p>\n" . $body;

    if (!$block->getId()) {
        // Create block with baseline + Pearson Vue so MY fallback chain keeps Cert of Completion.
        $newCont = $baselineCert . $pvMarker;
        $createBlock = true;
    } else {
        $newCont = rtrim($cur) . $pvMarker;
        $createBlock = false;
    }
    // Strip ALL occurrences (some legacy products have the section pasted twice).
    $newSd = preg_replace($pattern, '', $sd) ?? $sd;

    $report['rows'][] = [
        'sku'            => $sku,
        'create_block'   => $createBlock,
        'sd_before_len'  => strlen($sd),  'sd_after_len'   => strlen($newSd),
        'blk_before_len' => strlen($cur), 'blk_after_len'  => strlen($newCont),
        'backup_sd'      => $sd,          'backup_block'   => $cur,
        'action'         => $apply ? 'moved' : 'dry-would-move',
    ];

    if ($apply) {
        if (!$block->getId()) {
            Mage::getModel('cms/block')
                ->setIdentifier($blockId)
                ->setTitle('Course ' . $sku . ' — Certification')
                ->setContent($newCont)
                ->setIsActive(1)
                ->setStores([0])
                ->save();
            $report['totals']['created_block']++;
        } else {
            $block->setContent($newCont)->setIsActive(1)->save();
        }
        $pdoW->update('catalog_product_entity_text', ['value'=>$newSd], ['attribute_id=?'=>$aidSd, 'entity_id=?'=>$eid, 'store_id=?'=>0]);
    }
    $report['totals']['moved']++;
}

$reportDir = dirname(__DIR__, 2) . '/media/migrations-reports';
if (!is_dir($reportDir)) @mkdir($reportDir, 0775, true);
$reportPath = $reportDir . '/move-all-pearson-vue-' . $mode . '-' . gmdate('Ymd-His') . '.json';
file_put_contents($reportPath, json_encode($report, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");

echo "report: $reportPath\n";
foreach ($report['totals'] as $k=>$v) printf("  %-22s %d\n", $k, $v);
echo "done\n";
