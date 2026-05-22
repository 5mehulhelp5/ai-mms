<?php
/**
 * One-time generator: cleans the "Course Details" / Course Topics HTML stored
 * in catalog_product_entity_text (attribute_id 72 = description) and emits a
 * guarded SQL migration (migrations/120-clean-course-topics-html.sql).
 *
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/clean-course-topics.php
 *
 * It does NOT write to the database — it only produces the .sql file. Apply it
 * the normal way (migrations/apply.php), which also makes it deploy to prod.
 *
 * Scope: "standard-pattern" rows only — every <strong> sits inside a
 * <p><strong>...</strong></p> topic header (so unwrapping cannot damage inline
 * emphasis) and there is at least one such header. Irregular rows (<strong>
 * used inside <li> or mid-paragraph) are skipped and reported for manual review.
 *
 * Output HTML uses only <h3>, <ul>, <li>, <i>:
 *   - <p><strong>Topic N: ...</strong></p>  ->  <h3 class="course-topic-h3">...</h3>
 *     (class kept so the existing custom.css topic-heading styling applies)
 *   - <h1>-<h6>                              ->  <h3 class="course-topic-h3">
 *   - <ul>/<ol> list items                   ->  <li> (flattened, nested lists too)
 *   - loose <p> content under a header       ->  <li> bullets (split on <br>)
 *   - <em>/<i>                               ->  <i>
 *   - <span>,<div>,<a>,<code>,<b>,<strong>   ->  unwrapped (text kept)
 *   - <script>,<style>,<img>,<hr>            ->  removed
 */

require_once '/var/www/html/app/Mage.php';
Mage::app();

const ATTR_ID  = 72;
const OUT_FILE = '/var/www/html/migrations/121-clean-course-topics-html.sql';
const SAMPLES  = '/tmp/topics-samples.txt';

/* ── helpers ─────────────────────────────────────────────────────────── */

function collapseWs(string $s): string
{
    return trim(preg_replace('/\s+/u', ' ', $s));
}

function stripBullet(string $s): string
{
    // Leading bullet glyphs / dashes left over from "&bull; ..." paragraphs.
    return trim(preg_replace('/^(?:\x{2022}|\x{2023}|\x{25E6}|\x{00B7}|\x{2043}|-|\*)\s*/u', '', $s));
}

/** Serialize one node to clean inline HTML — keeps only <i>, unwraps the rest. */
function serializeOne(DOMNode $c): string
{
    if ($c->nodeType === XML_TEXT_NODE) {
        return htmlspecialchars($c->nodeValue, ENT_NOQUOTES, 'UTF-8');
    }
    if ($c->nodeType !== XML_ELEMENT_NODE) {
        return '';
    }
    $tag = strtolower($c->nodeName);
    if ($tag === 'br') {
        return ' ';
    }
    if (in_array($tag, ['img', 'script', 'style', 'hr'], true)) {
        return '';
    }
    if ($tag === 'i' || $tag === 'em') {
        $inner = serializeInline($c);
        return trim($inner) === '' ? '' : '<i>' . $inner . '</i>';
    }
    // strong, span, a, code, b, u, p, div, ul, li, ... -> unwrap
    return serializeInline($c);
}

/** Serialize a node's children to clean inline HTML. */
function serializeInline(DOMNode $node): string
{
    $out = '';
    foreach ($node->childNodes as $c) {
        $out .= serializeOne($c);
    }
    return $out;
}

/** Split a <p>'s children on <br> into segments of clean inline HTML. */
function splitOnBr(DOMNode $node): array
{
    $segs = [];
    $cur  = '';
    foreach ($node->childNodes as $c) {
        if ($c->nodeType === XML_ELEMENT_NODE && strtolower($c->nodeName) === 'br') {
            $segs[] = $cur;
            $cur = '';
        } else {
            $cur .= serializeOne($c);
        }
    }
    $segs[] = $cur;
    return $segs;
}

/** Flatten a <ul>/<ol> into list items, recursing nested lists. */
function listItems(DOMNode $list, array &$items): void
{
    foreach ($list->childNodes as $li) {
        if (!($li->nodeType === XML_ELEMENT_NODE && strtolower($li->nodeName) === 'li')) {
            continue;
        }
        $inline = '';
        $nested = [];
        foreach ($li->childNodes as $c) {
            if ($c->nodeType === XML_ELEMENT_NODE
                && in_array(strtolower($c->nodeName), ['ul', 'ol'], true)) {
                $nested[] = $c;
            } else {
                $inline .= serializeOne($c);
            }
        }
        $inline = stripBullet(collapseWs($inline));
        if ($inline !== '') {
            $items[] = $inline;
        }
        foreach ($nested as $nl) {
            listItems($nl, $items);
        }
    }
}

/** Is this <p> a topic header? (a <p> carrying a <strong>/<b>). */
function isHeaderP(DOMElement $p): bool
{
    return $p->getElementsByTagName('strong')->length > 0
        || $p->getElementsByTagName('b')->length > 0;
}

/**
 * Transform one description value.
 * @return array{0:?string,1:string}  [newHtml|null, note]
 */
function transform(string $html): array
{
    $dom = new DOMDocument('1.0', 'UTF-8');
    libxml_use_internal_errors(true);
    $ok = $dom->loadHTML(
        '<?xml encoding="UTF-8"?><html><body>' . $html . '</body></html>',
        LIBXML_NONET
    );
    libxml_clear_errors();
    if (!$ok) {
        return [null, 'parse-failed'];
    }
    $body = $dom->getElementsByTagName('body')->item(0);
    if (!$body) {
        return [null, 'no-body'];
    }

    $out   = [];
    $items = [];

    $flush = function () use (&$out, &$items): void {
        if ($items) {
            $out[] = '<ul>';
            foreach ($items as $it) {
                $out[] = '<li>' . $it . '</li>';
            }
            $out[] = '</ul>';
            $items = [];
        }
    };

    $walk = function (array $nodes) use (&$walk, &$out, &$items, $flush): void {
        foreach ($nodes as $n) {
            if ($n->nodeType === XML_TEXT_NODE) {
                $t = stripBullet(collapseWs(htmlspecialchars($n->nodeValue, ENT_NOQUOTES, 'UTF-8')));
                if ($t !== '') {
                    $items[] = $t;
                }
                continue;
            }
            if ($n->nodeType !== XML_ELEMENT_NODE) {
                continue;
            }
            $tag = strtolower($n->nodeName);

            if (in_array($tag, ['script', 'style', 'hr', 'img', 'br'], true)) {
                continue;
            }
            if (in_array($tag, ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'], true)) {
                $flush();
                $txt = collapseWs(serializeInline($n));
                if ($txt !== '') {
                    $out[] = '<h3 class="course-topic-h3">' . $txt . '</h3>';
                }
                continue;
            }
            if ($tag === 'p') {
                if (isHeaderP($n)) {
                    $flush();
                    $txt = collapseWs(serializeInline($n));
                    if ($txt !== '') {
                        $out[] = '<h3 class="course-topic-h3">' . $txt . '</h3>';
                    }
                } else {
                    foreach (splitOnBr($n) as $seg) {
                        $seg = stripBullet(collapseWs($seg));
                        if ($seg !== '') {
                            $items[] = $seg;
                        }
                    }
                }
                continue;
            }
            if ($tag === 'ul' || $tag === 'ol') {
                listItems($n, $items);
                continue;
            }
            if ($tag === 'div') {
                $walk(iterator_to_array($n->childNodes));
                continue;
            }
            // any other element -> treat content as a bullet
            $seg = stripBullet(collapseWs(serializeInline($n)));
            if ($seg !== '') {
                $items[] = $seg;
            }
        }
    };

    $walk(iterator_to_array($body->childNodes));
    $flush();

    if (!$out) {
        return [null, 'empty-result'];
    }
    return [implode("\n", $out), 'ok'];
}

function sqlEscape(string $v): string
{
    return str_replace(['\\', "'"], ['\\\\', "\\'"], $v);
}

/* ── main ────────────────────────────────────────────────────────────── */

$db = Mage::getSingleton('core/resource')->getConnection('core_read');
$rows = $db->fetchAll(
    "SELECT value_id, entity_id, store_id, value
       FROM catalog_product_entity_text
      WHERE attribute_id = " . ATTR_ID . "
        AND value IS NOT NULL AND value <> ''
      ORDER BY entity_id, store_id"
);

$total      = count($rows);
$skipIrreg  = 0;
$skipNoHdr  = 0;
$unchanged  = 0;
$failed     = [];
$changes    = [];          // [value_id => [entity_id, store_id, oldHash, new]]
$flagTags   = [];          // entity_id => list of notable tags found
$samples    = [];

foreach ($rows as $r) {
    $v = $r['value'];

    $nStrong = preg_match_all('/<strong\b[^>]*>/i', $v);
    $nHeader = preg_match_all('/<p\b[^>]*>\s*<strong\b[^>]*>.*?<\/strong>\s*<\/p>/is', $v);

    if ($nStrong !== $nHeader) {        // irregular <strong> usage -> skip
        $skipIrreg++;
        continue;
    }
    if ($nHeader < 1) {                  // not a topic-header description -> skip
        $skipNoHdr++;
        continue;
    }

    [$new, $note] = transform($v);
    if ($new === null) {
        $failed[] = $r['entity_id'] . ' (' . $note . ')';
        continue;
    }
    if ($new === $v) {
        $unchanged++;
        continue;
    }

    foreach (['a', 'script', 'img', 'iframe', 'code', 'table', 'object', 'embed'] as $t) {
        if (preg_match('/<' . $t . '\b/i', $v)) {
            $flagTags[$r['entity_id']][] = $t;
        }
    }

    $changes[$r['value_id']] = [
        'entity_id' => (int)$r['entity_id'],
        'store_id'  => (int)$r['store_id'],
        'oldHash'   => md5($v),
        'new'       => $new,
    ];
    if (count($samples) < 10) {
        $samples[] = "===== entity_id {$r['entity_id']} store {$r['store_id']} =====\n"
            . "--- BEFORE ---\n" . $v . "\n--- AFTER ---\n" . $new . "\n";
    }
}

/* ── write migration ─────────────────────────────────────────────────── */

$sql  = "-- Clean Course Topics HTML (catalog_product_entity_text, attribute_id "
      . ATTR_ID . " = description).\n";
$sql .= "--\n";
$sql .= "-- One-time normalisation of the \"Course Details\" tab markup for the\n";
$sql .= "-- " . count($changes) . " standard-pattern course descriptions. Each topic header\n";
$sql .= "-- (a paragraph whose whole content is a strong run) becomes an h3 with class\n";
$sql .= "-- course-topic-h3; all sub-topic content becomes ul/li bullets; every non-allowed\n";
$sql .= "-- tag (span, div, a, code, script, img, ...) is stripped. The cleaned values use\n";
$sql .= "-- only the h3, ul, li and i tags.\n";
$sql .= "--\n";
$sql .= "-- Generated by scripts/local-dev/clean-course-topics.php — do not hand-edit.\n";
$sql .= "-- Each UPDATE is guarded by MD5(value): a row is only rewritten while its\n";
$sql .= "-- content still matches what was cleaned, so this is idempotent and will not\n";
$sql .= "-- clobber a course description edited after this migration was generated.\n";
$sql .= "--\n";
$sql .= "-- Irregular rows (a strong run used outside the topic-header pattern) were\n";
$sql .= "-- intentionally left untouched for manual review.\n\n";

foreach ($changes as $valueId => $c) {
    $sql .= "UPDATE catalog_product_entity_text\n";
    $sql .= "SET value = '" . sqlEscape($c['new']) . "'\n";
    $sql .= "WHERE value_id = " . (int)$valueId
          . " AND MD5(value) = '" . $c['oldHash'] . "';\n\n";
}

file_put_contents(OUT_FILE, $sql);
file_put_contents(SAMPLES, implode("\n", $samples));

/* ── report ──────────────────────────────────────────────────────────── */

echo "=== clean-course-topics ===\n";
echo "total non-empty description rows : $total\n";
echo "skipped — irregular <strong>     : $skipIrreg\n";
echo "skipped — no topic header        : $skipNoHdr\n";
echo "already clean (no change)        : $unchanged\n";
echo "transformed (UPDATE emitted)     : " . count($changes) . "\n";
echo "transform failures               : " . count($failed) . "\n";
if ($failed) {
    echo "  " . implode(', ', $failed) . "\n";
}
echo "\nmigration written : " . OUT_FILE . " (" . number_format(strlen($sql)) . " bytes)\n";
echo "samples written   : " . SAMPLES . "\n";

if ($flagTags) {
    echo "\nNOTE — " . count($flagTags) . " transformed course(s) contained tags that were\n";
    echo "unwrapped/removed (review if any carried meaningful links/media):\n";
    $shown = 0;
    foreach ($flagTags as $eid => $tags) {
        echo "  entity_id $eid: " . implode(', ', array_unique($tags)) . "\n";
        if (++$shown >= 40) {
            echo "  ... (" . (count($flagTags) - 40) . " more)\n";
            break;
        }
    }
}
