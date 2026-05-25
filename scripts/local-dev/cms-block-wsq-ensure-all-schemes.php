<?php
/**
 * Standardize the WSQ Funding cms/block on every TGS-* (WSQ) course so all
 * 4 sub-cards always render on the storefront:
 *   - SkillsFuture Enterprise Credit (SFEC)
 *   - SkillsFuture Credit (SFC)
 *   - UTAP
 *   - PSEA
 *
 * Sourced from TGS-2023021752's canonical text. URLs are SKU-templated so
 * each course links to its own SkillsFuture course-directory entry. The
 * preamble (WSQ funding boilerplate, fee table, "Upon registration..."
 * paragraphs) is intentionally omitted from the block because view.phtml's
 * WSQ card auto-renders fee tiles from the live product price and the
 * post-processor would strip those paragraphs from the block anyway.
 *
 * Strategy:
 *   - For every TGS-* product, detect which of the 4 sub-card <h3> headings
 *     are present in the WSQ Funding cms/block.
 *   - If ALL 4 are present, leave the block alone (course-specific edits
 *     are preserved).
 *   - If any are missing, rewrite the block content to the canonical 4
 *     sub-cards in order (SFEC → SFC → UTAP → PSEA), SKU-templated. This
 *     guarantees completeness on every WSQ course.
 *
 * Run:
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/cms-block-wsq-ensure-all-schemes.php --dry-run
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/cms-block-wsq-ensure-all-schemes.php --apply
 *
 *   --force      rewrite ALL blocks unconditionally (clobbers customisations)
 *   --sku=SKU    restrict to one course
 */

declare(strict_types=1);

$flags = [];
foreach ($argv as $a) {
    if (in_array($a, ['--apply','--dry-run','--force'], true)) {
        $flags[ltrim($a,'-')] = true;
    } elseif (preg_match('/^--(\w+)=(.*)$/', $a, $m)) {
        $flags[$m[1]] = $m[2];
    }
}
$apply   = !empty($flags['apply']);
$force   = !empty($flags['force']);
$onlySku = $flags['sku'] ?? null;
$mode    = $apply ? ($force ? 'apply-force' : 'apply') : 'dry-run';

require_once dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app('admin');
Mage::register('isSecureArea', true);

// --------------------------------------------------------------------------
// Canonical sub-card templates (SFEC/SFC/UTAP/PSEA) — extracted verbatim
// from TGS-2023021752's WSQ Funding cms/block. {SKU} placeholder is
// replaced per course so each card's submission URL targets the correct
// SkillsFuture course-directory entry.
// --------------------------------------------------------------------------
$canonical = function (string $sku): string {
    $tpl = '<h3>SkillsFuture Enterprise Credit (SFEC)</h3>'
         . '<p>Eligible Singapore-registered companies can tap on $10000 SFEC to cover out-of-pocket expenses.'
         . '<a href="https://skillsfuture.gobusiness.gov.sg/course-directory/courses/{SKU}" target="_blank">'
         . '<span style="color: #ff0000; text-decoration-line: underline;">Click here to submit SkillsFuture Enterprise Credit</span></a></p>'
         . '<h3>SkillsFuture Credit (SFC)</h3>'
         . '<p>Eligible Singapore Citizens can use their SFC to offset course fee payable after funding but the $4,000 Additional SFC (Mid-Career Support) cannot be used. '
         . '<a href="https://www.myskillsfuture.gov.sg/content/portal/en/training-exchange/course-directory/course-detail.html?courseReferenceNumber={SKU}" title="SkillsFuture Credit" target="_blank">'
         . '<span style="color: #ff0000; text-decoration-line: underline;">Click here for SkillsFuture Credit submission</span></a></p>'
         . '<h3>UTAP</h3>'
         . '<p>Eligible NTUC members can apply for 50% of the unfunded fee from UTAP, capped up to $250/year and for members aged 40 and above, capped up to $500/year. '
         . '<a href="https://www.ntuc.org.sg/wps/portal/up2/home/eserviceslanding?id=6bc1ca2c-ce81-4acb-a28f-c0be586e185f" target="_blank">'
         . '<span style="color: #ff0000; text-decoration-line: underline;">Click here to submit UTAP</span></a></p>'
         . '<h3>PSEA</h3>'
         . '<p>Eligible Singapore Citizens can use their PSEA funds to offset course fee payable after funding.</p>'
         . '<p>To check for Post-Secondary Education Account (PSEA) eligibility for this course, '
         . '<a href="https://www.myskillsfuture.gov.sg/content/portal/en/training-exchange/course-directory/course-detail.html?courseReferenceNumber={SKU}" title="SkillsFuture Credit" target="_blank">'
         . '<span style="color: #ff0000; text-decoration-line: underline;">Visit SkillsFuture (course code: {SKU})</span></a></p>'
         . '<ul>'
         . '<li>Scroll down to &ldquo;Keyword Tags&rdquo; to verify for PSEA eligibility.</li>'
         . '<li>If there is &ldquo;PSEA&rdquo; under keyword tags, the course is eligible for PSEA.</li>'
         . '</ul>'
         . '<p>Once you are eligible for PSEA, please download and fill up the '
         . '<a href="https://www.moe.gov.sg/-/media/files/financial-matters/psea-ad-hoc-withdrawal-form.pdf" title="PSEA Withdrawal Form" target="_blank">'
         . '<span style="text-decoration: underline; color: #ff0000;">PSEA Withdrawal Form</span></a> and email to us.</p>';
    return str_replace('{SKU}', $sku, $tpl);
};

// Detect which sub-cards are present in a block's content. Uses the same
// acronym-in-parentheses / acronym-at-start slug logic as view.phtml so
// detection matches what the post-processor wraps as .wsq-sub--xxx.
$hasScheme = function (string $content, string $scheme): bool {
    if ($content === '') return false;
    // Acronym in parens: (SFEC), (SFC)
    if (preg_match_all('#<h[1-6][^>]*>(.*?)</h[1-6]>#siu', $content, $m)) {
        foreach ($m[1] as $title) {
            $title = trim(strip_tags($title));
            if (preg_match('#\(([A-Z]{2,6})\)#u', $title, $am) && strtoupper($am[1]) === $scheme) return true;
            if (preg_match('#^([A-Z]{2,6})\b#u', $title, $am) && strtoupper($am[1]) === $scheme) return true;
        }
    }
    return false;
};

// --------------------------------------------------------------------------
// Iterate TGS-* products
// --------------------------------------------------------------------------
$collection = Mage::getModel('catalog/product')->getCollection()
    ->addAttributeToSelect('sku');
$collection->addAttributeToFilter('sku', ['like' => 'TGS-%']);
if ($onlySku) $collection->addAttributeToFilter('sku', $onlySku);

echo "mode: $mode | TGS-* products: " . $collection->getSize() . "\n";

$tot = ['complete'=>0, 'rewrote'=>0, 'created'=>0, 'skipped'=>0];
$schemes = ['SFEC','SFC','UTAP','PSEA'];

foreach ($collection as $p) {
    $sku = (string)$p->getSku();
    if ($sku === '' || stripos($sku, 'TGS-') !== 0) continue;

    $blockId = 'course_' . $sku . '_wsq_funding';
    $b = Mage::getModel('cms/block')->load($blockId, 'identifier');
    $content = (string) $b->getContent();

    $present = [];
    foreach ($schemes as $s) { if ($hasScheme($content, $s)) $present[] = $s; }
    $missing = array_diff($schemes, $present);

    if (!$force && empty($missing) && $b->getId()) {
        $tot['complete']++;
        continue;
    }

    if (!$apply) {
        echo "[dry] $sku : " . ($b->getId() ? 'rewrite' : 'create')
           . ' (have=[' . implode(',', $present) . '] missing=[' . implode(',', $missing) . '])' . "\n";
        $tot[$b->getId() ? 'rewrote' : 'created']++;
        continue;
    }

    $newContent = $canonical($sku);
    if ($b->getId()) {
        $b->setContent($newContent)->setIsActive(1)->save();
        $tot['rewrote']++;
    } else {
        Mage::getModel('cms/block')
            ->setIdentifier($blockId)
            ->setTitle('Course ' . $sku . ' — WSQ Funding')
            ->setContent($newContent)
            ->setIsActive(1)
            ->setStores([0])
            ->save();
        $tot['created']++;
    }
    $p->clearInstance();
}

echo "totals:\n";
foreach ($tot as $k=>$v) printf("  %-10s %d\n", $k, $v);
echo "done\n";
