<?php
/**
 * Move the "Certification Exam at Pearson Vue" section out of
 * short_description and append it to the per-course Certification cms/block
 * for every AWS course (course name contains "AWS").
 *
 * Identifier:  course_<sku>_certification
 * Scope:       single block, all-stores (rendered on SG + non-SG)
 *
 * On SG store, view.phtml's cert branch is being updated separately to
 * render the hardcoded Cert-of-Completion template PLUS the per-course
 * cms/block content (with the duplicate Cert-of-Completion <li> stripped
 * to avoid double-rendering). On non-SG stores the per-course block
 * already renders directly.
 *
 * Idempotent: skips products whose Certification cms/block already
 * contains the Pearson Vue marker. JSON report includes per-product
 * backups for rollback.
 *
 * Run:
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/move-aws-pearson-vue-to-cert-cms-block.php --dry-run
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/move-aws-pearson-vue-to-cert-cms-block.php --apply
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

$aidSd   = (int)$pdoR->fetchOne("SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description' AND entity_type_id=4");
$aidName = (int)$pdoR->fetchOne("SELECT attribute_id FROM eav_attribute WHERE attribute_code='name' AND entity_type_id=4");

$WS = '(?:\s|&nbsp;|\x{00A0}|\x{2007}|\x{202F})';
$pattern = '#<h[1-6][^>]*>' . $WS . '*Certification' . $WS . '+Exam' . $WS . '+at' . $WS . '+Pearson' . $WS . '+Vue' . $WS . '*</h[1-6]>(.*?)(?=(?:<[a-z][a-z0-9]*\b[^>]*>' . $WS . '*)*<h[1-6]|\z)#siu';

// Find AWS courses (name contains "AWS") with the section
$rows = $pdoR->fetchAll("SELECT cpe.entity_id, cpe.sku, n.value AS name, t.value AS sd
  FROM catalog_product_entity cpe
  JOIN catalog_product_entity_text t ON t.entity_id=cpe.entity_id AND t.attribute_id=$aidSd AND t.store_id=0
  JOIN catalog_product_entity_varchar n ON n.entity_id=cpe.entity_id AND n.attribute_id=$aidName AND n.store_id=0
  WHERE t.value REGEXP '<h[1-6][^>]*>[^<]*Certification[[:space:]]+Exam[[:space:]]+at[[:space:]]+Pearson'
    AND n.value LIKE '%AWS%'");

echo "mode: $mode | AWS candidates: " . count($rows) . "\n";

$report = ['generated_at'=>gmdate('c'), 'mode'=>$mode, 'totals'=>['seen'=>0,'moved'=>0,'skipped_already'=>0,'skipped_no_match'=>0,'skipped_no_block'=>0], 'rows'=>[]];

foreach ($rows as $r) {
    $eid = (int)$r['entity_id']; $sku = (string)$r['sku']; $sd = (string)$r['sd'];
    $report['totals']['seen']++;

    if (!preg_match($pattern, $sd, $m)) {
        $report['totals']['skipped_no_match']++;
        $report['rows'][] = ['sku'=>$sku, 'action'=>'skip-no-match'];
        continue;
    }
    $fullMatch = $m[0];
    $body      = trim($m[1]);
    if ($body === '') { $report['totals']['skipped_no_match']++; continue; }

    $blockId = 'course_' . $sku . '_certification';
    $block   = Mage::getModel('cms/block')->load($blockId, 'identifier');
    if (!$block->getId()) {
        $report['totals']['skipped_no_block']++;
        $report['rows'][] = ['sku'=>$sku, 'action'=>'skip-no-block'];
        continue;
    }
    $cur = (string)$block->getContent();

    // Idempotency guard
    if (stripos($cur, 'Pearson Vue') !== false || stripos($cur, 'Certification Exam at Pearson') !== false) {
        $report['totals']['skipped_already']++;
        $report['rows'][] = ['sku'=>$sku, 'action'=>'skip-already-in-block'];
        continue;
    }

    // Use the exact marker format view.phtml's SG cert branch looks for
    // when it appends the Pearson Vue suffix to the hardcoded template:
    //   <p><strong>Certification Exam at Pearson Vue</strong></p>...
    // (see view.phtml ~282 — the same convention CompTIA uses).
    $append   = "\n<p><strong>Certification Exam at Pearson Vue</strong></p>\n" . $body;
    $newCont  = rtrim($cur) . $append;
    $newSd    = preg_replace($pattern, '', $sd, 1) ?? $sd;

    $report['rows'][] = [
        'sku'            => $sku, 'name' => $r['name'],
        'sd_before_len'  => strlen($sd),   'sd_after_len'   => strlen($newSd),
        'blk_before_len' => strlen($cur),  'blk_after_len'  => strlen($newCont),
        'backup_sd'      => $sd,           'backup_block'   => $cur,
        'action'         => $apply ? 'moved' : 'dry-would-move',
    ];

    if ($apply) {
        $block->setContent($newCont)->setIsActive(1)->save();
        $pdoW->update('catalog_product_entity_text', ['value'=>$newSd], ['attribute_id=?'=>$aidSd, 'entity_id=?'=>$eid, 'store_id=?'=>0]);
    }
    $report['totals']['moved']++;
}

$reportDir = dirname(__DIR__, 2) . '/media/migrations-reports';
if (!is_dir($reportDir)) @mkdir($reportDir, 0775, true);
$reportPath = $reportDir . '/move-aws-pearson-vue-' . $mode . '-' . gmdate('Ymd-His') . '.json';
file_put_contents($reportPath, json_encode($report, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");

echo "report: $reportPath\n";
foreach ($report['totals'] as $k=>$v) printf("  %-22s %d\n", $k, $v);
echo "done\n";
