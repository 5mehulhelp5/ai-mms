<?php
/**
 * Normalize the "Topics Covered" markup in product descriptions so every
 * course renders the same structure on the storefront.
 *
 * Two legacy patterns are converted to the canonical form:
 *
 *   <p><strong>Topic N: ...</strong></p>          ->  <h3 class="course-topic-h3">Topic N: ...</h3>
 *   <p><em>bullet text</em></p>  (consecutive)    ->  <ul><li>bullet text</li>...</ul>
 *
 * Canonical form (what the hydroponics-style courses already use):
 *   <h3 class="course-topic-h3">Topic N: ...</h3>
 *   <ul>
 *     <li>bullet 1</li>
 *     <li>bullet 2</li>
 *   </ul>
 *
 * Scope: admin scope (store_id=0) only — per-course descriptions are
 * authored at default scope and no per-store overrides exist for this
 * attribute (verified by SELECT store_id from catalog_product_entity_text).
 *
 * USAGE
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/maintenance/normalize-course-topics.php
 *     -> dry run; prints per-product diff summary, writes nothing.
 *
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/maintenance/normalize-course-topics.php --confirm
 *     -> writes the cleaned description back, then reindexes
 *        catalog_product_flat and flushes block_html/FPC caches.
 *
 * Re-runnable: transforms are idempotent — rows already in canonical form
 * are detected as unchanged and skipped.
 */

@ini_set('memory_limit', '1024M');
set_time_limit(0);

require __DIR__ . '/../../app/Mage.php';
Mage::app('admin');

$confirm = in_array('--confirm', $argv ?? [], true);

$resource = Mage::getSingleton('core/resource');
$read     = $resource->getConnection('core_read');
$write    = $resource->getConnection('core_write');

$descAttr = Mage::getModel('eav/entity_attribute')
    ->loadByCode('catalog_product', 'description');
$descAttrId = (int) $descAttr->getId();

// Pull every product whose description has a legacy Topic marker. The two
// markers together cover both the "<p><strong>Topic N:" header style and
// the "<p><em>...</em></p>" pseudo-bullet style.
$rows = $read->fetchAll(
    "SELECT cpe.entity_id, cpe.sku, cpet.value AS description
       FROM catalog_product_entity cpe
       JOIN catalog_product_entity_text cpet
         ON cpet.entity_id = cpe.entity_id
        AND cpet.attribute_id = ?
        AND cpet.store_id = 0
      WHERE cpet.value LIKE '%<p><strong>Topic%'
         OR cpet.value LIKE '%<p><em>%'
      ORDER BY cpe.entity_id",
    [$descAttrId]
);

printf("scope: %d products with legacy topic/bullet markup\n", count($rows));
printf("mode:  %s\n\n", $confirm ? 'WRITE' : 'DRY RUN');

$stats = ['header_fixed'=>0, 'bullets_wrapped'=>0, 'updated'=>0, 'unchanged'=>0];

foreach ($rows as $r) {
    $orig = (string) $r['description'];
    $sku  = $r['sku'];
    $eid  = (int) $r['entity_id'];

    $next = normalizeTopicMarkup($orig, $headerHits, $bulletHits);

    if ($next === $orig) {
        $stats['unchanged']++;
        continue;
    }

    $stats['updated']++;
    $stats['header_fixed']  += $headerHits;
    $stats['bullets_wrapped'] += $bulletHits;

    printf("%-22s eid=%-5d  headers=%-2d  bullet-blocks=%-2d\n",
        $sku, $eid, $headerHits, $bulletHits);

    if ($confirm) {
        $write->update(
            'catalog_product_entity_text',
            ['value' => $next],
            ['entity_id = ?' => $eid, 'attribute_id = ?' => $descAttrId, 'store_id = ?' => 0]
        );
    }
}

printf("\nsummary: updated=%d unchanged=%d header_fixes=%d bullet_blocks=%d\n",
    $stats['updated'], $stats['unchanged'], $stats['header_fixed'], $stats['bullets_wrapped']);

if ($confirm && $stats['updated'] > 0) {
    // Per feedback_flat_catalog_reindex: saveAttribute / direct EAV writes
    // leave the flat catalog and block_html cache stale. Reindex + flush so
    // the storefront actually picks up the new markup.
    echo "\nreindexing catalog_product_flat ...\n";
    Mage::getModel('index/process')
        ->load('catalog_product_flat', 'indexer_code')
        ->reindexEverything();

    echo "flushing block_html / FPC / collections caches ...\n";
    Mage::app()->getCacheInstance()->cleanType('block_html');
    Mage::app()->getCacheInstance()->cleanType('full_page');
    Mage::app()->getCacheInstance()->cleanType('collections');

    echo "done.\n";
} elseif (!$confirm) {
    echo "\n(dry run — pass --confirm to write)\n";
}

/**
 * Convert legacy topic/bullet markup to the canonical h3 + ul/li structure.
 *
 * Returns the rewritten HTML. $headerHits / $bulletHits are populated with
 * the number of header conversions and contiguous bullet blocks wrapped.
 */
function normalizeTopicMarkup(string $html, ?int &$headerHits = 0, ?int &$bulletHits = 0): string
{
    $headerHits = 0;
    $bulletHits = 0;

    // Pre-pass: split chained "<p><strong>Topic 1 ...</strong><br /><strong>Topic 2 ...</strong></p>"
    // patterns into one <p>...</p> per topic so the main header regex can pick them up.
    $html = preg_replace_callback(
        '#<p>\s*(?:<br\s*/?>\s*)?<strong>\s*(Topic[\s\xC2\xA0&nbsp;]+\d+[^<]*?)</strong>(\s*<br\s*/?>\s*<strong>\s*Topic[\s\xC2\xA0&nbsp;]+\d+[^<]*?</strong>)+\s*</p>#i',
        function ($m) {
            $body = $m[0];
            // Strip outer <p> ... </p>
            $body = preg_replace('#^<p>\s*#i', '', $body);
            $body = preg_replace('#\s*</p>$#i', '', $body);
            $body = preg_replace('#^<br\s*/?>\s*#i', '', $body);
            // Split into individual <strong>...</strong> chunks (drop empty/<br/>).
            $parts = preg_split('#\s*<br\s*/?>\s*#i', $body);
            $out = '';
            foreach ($parts as $p) {
                $p = trim($p);
                if ($p === '') continue;
                $out .= '<p>' . $p . '</p>';
            }
            return $out;
        },
        $html
    );

    // 1) Header: <p>[<br/>]<strong>Topic N: ...</strong>(<strong></strong>)?</p>
    //    -> <h3 class="course-topic-h3">Topic N: ...</h3>
    //    Tolerate &nbsp; / NBSP between "Topic" and the number, a leading <br/>
    //    inside the <p>, and the trailing empty <strong></strong> the legacy
    //    WYSIWYG often left behind.
    $html = preg_replace_callback(
        '#<p>\s*(?:<br\s*/?>\s*)?<strong>\s*(Topic(?:&nbsp;|\xC2\xA0|\s)+\d+[^<]*?)\s*(?:&nbsp;)?\s*</strong>\s*(?:<strong>\s*</strong>)?\s*</p>#i',
        function ($m) use (&$headerHits) {
            $headerHits++;
            $title = trim(html_entity_decode($m[1], ENT_QUOTES, 'UTF-8'));
            // Normalize internal NBSP to a regular space so the heading text
            // reads cleanly in DOM inspectors and screen readers.
            $title = preg_replace('/[\xC2\xA0\s]+/u', ' ', $title);
            $title = htmlspecialchars($title, ENT_QUOTES | ENT_HTML5, 'UTF-8');
            return '<h3 class="course-topic-h3">' . $title . '</h3>';
        },
        $html
    );

    // 1b) Permissive header sweep: any <p>...</p> whose content (after
    //     stripping <strong>, <span>, <br>, &nbsp;) starts with "Topic <num>".
    //     Catches the long tail: split-strong, nested-strong, trailing-&nbsp;,
    //     empty <span lang=...>, decimal topic numbers (e.g. "Topic 4.4:").
    $html = preg_replace_callback(
        '#<p>(\s*(?:<strong>|<span[^>]*>|<br\s*/?>|&nbsp;|\xC2\xA0|\s)*<strong>.*?</p>)#is',
        function ($m) use (&$headerHits) {
            $inner = $m[1];
            // Pull the visible text by stripping every inline tag.
            $text = preg_replace('#<[^>]+>#', '', $inner);
            $text = html_entity_decode($text, ENT_QUOTES, 'UTF-8');
            $text = preg_replace('/[\xC2\xA0\s]+/u', ' ', $text);
            $text = trim($text);
            if (!preg_match('/^Topic\s+[0-9.]+/i', $text)) {
                return $m[0]; // not a topic header, leave it alone
            }
            $headerHits++;
            $text = htmlspecialchars($text, ENT_QUOTES | ENT_HTML5, 'UTF-8');
            return '<h3 class="course-topic-h3">' . $text . '</h3>';
        },
        $html
    );

    // 2) Pseudo-bullets: contiguous runs of <p><em>line</em></p>
    //    (separated only by whitespace) -> <ul><li>line</li>...</ul>.
    //    Anchored on at least two consecutive <p><em> blocks so we don't wrap
    //    a single italicized standalone paragraph that wasn't a bullet.
    $html = preg_replace_callback(
        '#(?:<p>\s*<em>\s*(?:.(?!</em>))*?.\s*</em>\s*</p>\s*){2,}#is',
        function ($m) use (&$bulletHits) {
            $bulletHits++;
            $block = $m[0];
            preg_match_all('#<p>\s*<em>\s*(.*?)\s*</em>\s*</p>#is', $block, $items);
            $lis = '';
            foreach ($items[1] as $line) {
                $line = trim($line);
                // Drop trailing non-breaking spaces the WYSIWYG leaves behind.
                $line = preg_replace('/(?:&nbsp;|\xC2\xA0|\s)+$/u', '', $line);
                $lis .= '<li>' . $line . '</li>';
            }
            return '<ul>' . $lis . '</ul>';
        },
        $html
    );

    return $html;
}
