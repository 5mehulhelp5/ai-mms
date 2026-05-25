<?php
/**
 * Backfill the `assessment_methods` multiselect attribute from the Final
 * Assessment block embedded in each WSQ course description, then strip the
 * inline Final Assessment block out of `description` so the storefront only
 * renders it once (via the new Assessment card on the product page).
 *
 * Scope: products whose SKU starts with "TGS-" (WSQ courses). Non-WSQ
 * products are skipped entirely — the Assessment card never renders for them
 * and they should not have the attribute populated.
 *
 * Mapping rules (substring detection inside the extracted Final Assessment
 * block — the same block is stripped after parsing):
 *   "Written Assess" / "MCQ" / "Written Exam"          -> Written Exam
 *   "Practical" / "Pracitcal" / "Practicum"            -> Practical Exam
 *   "Case Stud" / "Caes Study"                         -> Case Study
 *   "Oral Question"                                    -> Oral Questioning
 *   "Role Play"                                        -> Role Play
 *   "Assignment"                                       -> Assignment
 *   "Demonstration"                                    -> Demonstration
 *   "Project"                                          -> Project
 * Defaults: WSQ course with no Final Assessment block, OR with a block that
 * matches none of the above, gets Written Exam + Practical Exam.
 *
 * USAGE
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/maintenance/backfill-assessment-methods.php
 *     -> dry run; prints what each WSQ product WOULD be set to + what would
 *        be stripped from its description. Writes nothing.
 *
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/maintenance/backfill-assessment-methods.php --confirm
 *     -> writes the attribute values + strips the Final Assessment block
 *        from each product's description (store_id=0, admin scope).
 *
 * Re-runnable: detection is idempotent. On second run, products whose
 * descriptions have already been stripped won't match the Final Assessment
 * regex and will be left as-is (their attribute value already set).
 */

@ini_set('memory_limit', '1024M');
set_time_limit(0);

require __DIR__ . '/../../app/Mage.php';
Mage::app('admin');

$confirm = in_array('--confirm', $argv ?? [], true);

$resource = Mage::getSingleton('core/resource');
$read     = $resource->getConnection('core_read');
$write    = $resource->getConnection('core_write');

// Resolve attribute id + per-label option ids for the new multiselect.
$asmtAttr = Mage::getModel('eav/entity_attribute')
    ->loadByCode('catalog_product', 'assessment_methods');
if (!$asmtAttr->getId()) {
    fwrite(STDERR, "assessment_methods attribute not found — run migration 157 first.\n");
    exit(1);
}

$optByLabel = [];
foreach ($asmtAttr->getSource()->getAllOptions(false) as $opt) {
    if (!empty($opt['label']) && !empty($opt['value'])) {
        $optByLabel[$opt['label']] = (int) $opt['value'];
    }
}
foreach (['Written Exam','Practical Exam','Case Study','Role Play','Oral Questioning','Assignment','Demonstration','Project'] as $required) {
    if (empty($optByLabel[$required])) {
        fwrite(STDERR, "Missing option: $required — re-run migration 157.\n");
        exit(1);
    }
}

$descAttr = Mage::getModel('eav/entity_attribute')
    ->loadByCode('catalog_product', 'description');

// Pull every WSQ product's admin-scope description.
$rows = $read->fetchAll(
    "SELECT cpe.entity_id, cpe.sku, cpet.value AS description
       FROM catalog_product_entity cpe
       JOIN catalog_product_entity_text cpet
         ON cpet.entity_id = cpe.entity_id
        AND cpet.attribute_id = ?
        AND cpet.store_id = 0
      WHERE cpe.sku LIKE 'TGS-%'
      ORDER BY cpe.entity_id",
    [(int) $descAttr->getId()]
);

printf("scope: %d WSQ products (TGS-)\n", count($rows));
printf("mode:  %s\n\n", $confirm ? 'WRITE' : 'DRY RUN');

$stats = ['parsed'=>0, 'defaulted'=>0, 'stripped'=>0, 'updated_desc'=>0, 'updated_attr'=>0, 'unchanged'=>0];

foreach ($rows as $r) {
    $desc = (string) $r['description'];
    $sku  = $r['sku'];
    $eid  = (int) $r['entity_id'];

    // Locate the assessment block. Tolerate every heading variant seen in
    // the wild — the literal heading text varies between WSQ courses:
    //   <h3 class="course-topic-h3">Final Assessment</h3>
    //   <h3>Mode of Assessment</h3>
    //   <h4>Assessment Methods</h4>
    //   <p><strong>Final Assessment</strong></p>
    // Plus a leading <p>By end of...</p>-style intro is sometimes present.
    // The block ends at the next </ul>.
    $block = null;
    $blockStart = null;
    $blockEnd = null;
    $headingAlt = 'Final Assessment|Mode of Assessment|Assessment Method[s]?|Assessment[s]?\s*[:\-]';
    // Allow trailing &nbsp; / whitespace inside the heading text — admins
    // paste-in from Word often introduces a non-breaking space.
    $headingTail = '(?:&nbsp;|\s)*';
    if (preg_match('#(<h[1-6][^>]*>\s*(?:' . $headingAlt . ')' . $headingTail . '</h[1-6]>\s*<ul[^>]*>.*?</ul>)#is', $desc, $m, PREG_OFFSET_CAPTURE)) {
        $block = $m[1][0];
        $blockStart = $m[1][1];
        $blockEnd = $blockStart + strlen($block);
    } elseif (preg_match('#(<p>\s*<strong>\s*(?:' . $headingAlt . ')' . $headingTail . '</strong>\s*</p>\s*<ul[^>]*>.*?</ul>)#is', $desc, $m, PREG_OFFSET_CAPTURE)) {
        $block = $m[1][0];
        $blockStart = $m[1][1];
        $blockEnd = $blockStart + strlen($block);
    } elseif (preg_match('#(<h[1-6][^>]*>\s*(?:' . $headingAlt . ')' . $headingTail . '</h[1-6]>)#is', $desc, $m, PREG_OFFSET_CAPTURE)) {
        // Orphan heading with no <ul> after — earlier passes / manual edits
        // stripped the body but left the title behind. Remove the title too.
        $block = $m[1][0];
        $blockStart = $m[1][1];
        $blockEnd = $blockStart + strlen($block);
    }

    // Map block content -> canonical option set.
    $picked = [];
    if ($block !== null) {
        $b = $block;
        if (preg_match('/Written Assess|Written Exam|\bMCQ\b/i', $b)) $picked['Written Exam'] = true;
        if (preg_match('/Practical|Pracitcal|Practicum/i', $b))       $picked['Practical Exam'] = true;
        if (preg_match('/Case Stud|Caes Study/i', $b))                $picked['Case Study'] = true;
        if (preg_match('/Oral Question/i', $b))                       $picked['Oral Questioning'] = true;
        if (preg_match('/Role Play/i', $b))                           $picked['Role Play'] = true;
        if (preg_match('/Assignment/i', $b))                          $picked['Assignment'] = true;
        if (preg_match('/Demonstration/i', $b))                       $picked['Demonstration'] = true;
        if (preg_match('/\bProject\b/i', $b))                         $picked['Project'] = true;
        $stats['parsed']++;
    }
    if (empty($picked)) {
        $picked = ['Written Exam' => true, 'Practical Exam' => true];
        $stats['defaulted']++;
    }

    $optionIds = [];
    foreach (array_keys($picked) as $label) {
        $optionIds[] = $optByLabel[$label];
    }
    sort($optionIds, SORT_NUMERIC);
    $newAttrValue = implode(',', $optionIds);

    // Read current attribute value (if any) to skip no-op writes.
    $currentAttrValue = $read->fetchOne(
        "SELECT value FROM catalog_product_entity_text
          WHERE entity_id=? AND attribute_id=? AND store_id=0",
        [$eid, (int) $asmtAttr->getId()]
    );

    // New description with the block stripped, only if we found one.
    $newDesc = $desc;
    if ($block !== null) {
        $newDesc = substr($desc, 0, $blockStart) . substr($desc, $blockEnd);
        $newDesc = preg_replace("/\n{3,}/", "\n\n", $newDesc);
        $stats['stripped']++;
    }

    $attrChanged = ((string) $currentAttrValue !== $newAttrValue);
    $descChanged = ($newDesc !== $desc);

    if (!$attrChanged && !$descChanged) {
        $stats['unchanged']++;
        continue;
    }

    printf("%-18s eid=%-5d  attr: %s  desc-strip: %s\n",
        $sku,
        $eid,
        $attrChanged ? implode('+', array_keys($picked)) : '(unchanged)',
        $descChanged ? 'YES' : 'no'
    );

    if (!$confirm) {
        continue;
    }

    if ($attrChanged) {
        // Upsert on (entity_id, attribute_id, store_id) — uniq key in this table.
        $write->insertOnDuplicate(
            $resource->getTableName('catalog_product_entity_text'),
            [
                'entity_type_id' => 4,
                'attribute_id'   => (int) $asmtAttr->getId(),
                'store_id'       => 0,
                'entity_id'      => $eid,
                'value'          => $newAttrValue,
            ],
            ['value']
        );
        $stats['updated_attr']++;
    }
    if ($descChanged) {
        $write->update(
            $resource->getTableName('catalog_product_entity_text'),
            ['value' => $newDesc],
            [
                'entity_id = ?'    => $eid,
                'attribute_id = ?' => (int) $descAttr->getId(),
                'store_id = ?'     => 0,
            ]
        );
        $stats['updated_desc']++;
    }
}

print "\n";
print "summary:\n";
foreach ($stats as $k => $v) printf("  %-13s %d\n", $k, $v);
if (!$confirm) {
    print "\n(dry run — re-run with --confirm to write)\n";
}
