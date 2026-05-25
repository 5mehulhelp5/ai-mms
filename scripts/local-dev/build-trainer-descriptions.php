#!/usr/bin/env php
<?php
/**
 * Harvest trainer bios from the legacy `trainerprofile` product attribute
 * (eav id 153) on catalog_product_entity_text — each blob is an HTML
 * series of <p><strong>Trainer Name:</strong> long bio…</p> blocks —
 * normalize them to one bio per distinct trainer name (longest wins),
 * match them to courses_trainers.title, and emit a SQL migration with
 * UPDATE statements that fill description WHERE it's currently NULL.
 *
 * Run from the project root (local dev container):
 *     docker exec project-web-1 php scripts/local-dev/build-trainer-descriptions.php
 * The generated migration is written to migrations/161-trainer-descriptions-backfill.sql.
 *
 * Idempotent: re-running produces the same output. The generated SQL
 * itself is also idempotent — the UPDATE guards on description IS NULL.
 */

require_once dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app();

$out = dirname(__DIR__, 2) . '/migrations/161-trainer-descriptions-backfill.sql';

$resource = Mage::getSingleton('core/resource');
$read     = $resource->getConnection('core_read');
$productTextTbl = $resource->getTableName('catalog_product_entity_text');
$trainersTbl    = $resource->getTableName('courses_trainers');

$TRAINER_PROFILE_ATTR_ID = 153; // see eav_attribute, code = trainerprofile

// 1. Pull every non-empty trainerprofile blob (store_id = 0, the default
//    scope where these bios live — verified during exploration).
$blobs = $read->fetchCol(
    "SELECT value
       FROM {$productTextTbl}
      WHERE attribute_id = ?
        AND value IS NOT NULL
        AND value <> ''",
    [$TRAINER_PROFILE_ATTR_ID]
);
fwrite(STDERR, sprintf("[1/4] fetched %d trainerprofile blobs\n", count($blobs)));

// 2. Parse each blob into name => description pairs. Each blob is a
//    sequence of <strong>Name:</strong> body text … (next <strong> ends body).
//    The body can include <p>, <br>, <em>, and trailing paragraphs that
//    belong to the same trainer until the NEXT <strong> appears.
$bios = []; // name (normalized lower) => ['display' => Name, 'desc' => longest seen]

$NORM = function (string $s): string {
    $s = html_entity_decode($s, ENT_QUOTES | ENT_HTML5, 'UTF-8');
    $s = preg_replace('/\s+/u', ' ', $s);
    $s = trim($s);
    return $s;
};

foreach ($blobs as $blob) {
    // Find every <strong>…</strong> position. Trainer name is whatever
    // is inside the <strong>, stripped of any inner tags and trailing
    // ":" punctuation. Body is everything between the END of this
    // <strong>'s containing paragraph block and the start of the next
    // <strong> (or end of blob). To keep this robust against varied
    // markup, we split on <strong> boundaries.
    if (!preg_match_all('#<strong>(.*?)</strong>(.*?)(?=<strong>|\z)#siu', $blob, $matches, PREG_SET_ORDER)) {
        continue;
    }
    foreach ($matches as $m) {
        $rawName = $NORM(strip_tags($m[1]));
        $rawDesc = $m[2];

        // Strip the leading ":" or "—" that always follows the name.
        $rawName = rtrim($rawName, ":\xC2\xA0-\xE2\x80\x93\xE2\x80\x94 ");
        if ($rawName === '') { continue; }
        // Names that are clearly section headings, not people, are skipped.
        $lowerName = mb_strtolower($rawName, 'UTF-8');
        if (preg_match('/^(certificat|about|trainer profile|profile|note|disclaimer|introduction)/iu', $lowerName)) {
            continue;
        }
        // Cap reasonable name length — anything wildly long is probably
        // mis-parsed (e.g. someone bolded a whole sentence).
        if (mb_strlen($rawName, 'UTF-8') > 120) { continue; }

        // Clean the body: drop <p> wrappers, keep paragraph breaks as
        // double-newline, strip remaining tags, trim a leading colon
        // (in case the <strong> closed before the colon).
        $desc = $rawDesc;
        $desc = preg_replace('#<br\s*/?>#i', "\n", $desc);
        $desc = preg_replace('#</p>\s*<p[^>]*>#i', "\n\n", $desc);
        $desc = preg_replace('#</?p[^>]*>#i', '', $desc);
        $desc = strip_tags($desc);
        $desc = html_entity_decode($desc, ENT_QUOTES | ENT_HTML5, 'UTF-8');
        $desc = preg_replace('/[ \t]+/u', ' ', $desc);
        $desc = preg_replace("/\r\n|\r/", "\n", $desc);
        $desc = preg_replace("/\n{3,}/", "\n\n", $desc);
        $desc = trim($desc);
        // Drop a leading ":" if the name didn't include it
        $desc = preg_replace('/^[:\s\xC2\xA0]+/u', '', $desc);

        if ($desc === '' || mb_strlen($desc, 'UTF-8') < 40) { continue; }

        $key = $lowerName;
        if (!isset($bios[$key]) || mb_strlen($desc, 'UTF-8') > mb_strlen($bios[$key]['desc'], 'UTF-8')) {
            $bios[$key] = ['display' => $rawName, 'desc' => $desc];
        }
    }
}
fwrite(STDERR, sprintf("[2/4] parsed %d distinct trainer bios\n", count($bios)));

// 3. Match against courses_trainers.title with multi-pass fuzzy matching.
// Strip honorifics ("Dr.", "Mr.", "Mrs.", "Prof.", "ACTA", "ACLP") and
// normalize whitespace. Same applies to the bio-side name.
$STRIP_PREFIXES = ['dr', 'mr', 'mrs', 'ms', 'miss', 'prof', 'professor', 'acta', 'aclp', 'wsq', 'ir'];
$cleanName = function (string $s) use ($STRIP_PREFIXES, $NORM): string {
    $s = $NORM($s);
    // Strip leading title tokens like "Dr.", "Mr.", "Prof.", "ACTA"
    $tokens = preg_split('/\s+/', $s);
    while (!empty($tokens)) {
        $head = preg_replace('/[^a-z]/i', '', $tokens[0]);
        if (in_array(strtolower($head), $STRIP_PREFIXES, true)) {
            array_shift($tokens);
        } else {
            break;
        }
    }
    return mb_strtolower(implode(' ', $tokens), 'UTF-8');
};

$trainers = $read->fetchAll("SELECT trainers_id, title FROM {$trainersTbl}");
$trainerIdx = []; // [['id' => x, 'clean' => 'patrick foo kuek sun', 'tokens' => [...]]]
foreach ($trainers as $t) {
    $clean = $cleanName((string) $t['title']);
    if ($clean === '') { continue; }
    $trainerIdx[] = [
        'id'     => (int) $t['trainers_id'],
        'clean'  => $clean,
        'tokens' => preg_split('/\s+/', $clean),
    ];
}

// Build exact-clean lookup for O(1) pass 1 + 2
$exactLookup = [];
foreach ($trainerIdx as $ti) {
    $exactLookup[$ti['clean']][] = $ti['id'];
}

$updates = [];   // [trainers_id => ['title' => original_title, 'desc' => description]]
$matched = 0;
$ambiguous = 0;
$unmatched = []; // names with bios but no trainer record
// Reverse lookup id => original title so we can emit title-based SQL
$titleById = [];
foreach ($trainers as $t) { $titleById[(int)$t['trainers_id']] = (string)$t['title']; }

$matchBio = function (string $bioNameClean) use ($exactLookup, $trainerIdx) {
    // Run every pass and union their hits — many trainer tables have
    // duplicate rows for the same person (e.g. "Patrick Foo Kuek Sun"
    // AND "ACTA Patrick Foo" are the same human). All should get the bio.
    $all = [];
    // Pass 1: exact match on cleaned name
    if (isset($exactLookup[$bioNameClean])) {
        foreach ($exactLookup[$bioNameClean] as $id) { $all[$id] = true; }
    }
    $bioTokens = preg_split('/\s+/', $bioNameClean);
    if (count($bioTokens) < 2) {
        return array_keys($all);
    }
    // Pass 2: bio name is a token-aligned prefix of trainer title.
    $bioFirst2 = implode(' ', array_slice($bioTokens, 0, 2));
    foreach ($trainerIdx as $ti) {
        if (count($ti['tokens']) < 2) { continue; }
        $trainerFirst2 = implode(' ', array_slice($ti['tokens'], 0, 2));
        if ($trainerFirst2 === $bioFirst2) { $all[$ti['id']] = true; }
    }
    // Pass 3: first-token + last-token match
    $bioFirst = $bioTokens[0];
    $bioLast  = $bioTokens[count($bioTokens) - 1];
    foreach ($trainerIdx as $ti) {
        if (count($ti['tokens']) < 2) { continue; }
        $tFirst = $ti['tokens'][0];
        $tLast  = $ti['tokens'][count($ti['tokens']) - 1];
        if ($tFirst === $bioFirst && $tLast === $bioLast) { $all[$ti['id']] = true; }
    }
    // Pass 4: token set (one is subset/superset of other) with >=2 overlap
    $bioSet = array_unique($bioTokens);
    sort($bioSet);
    foreach ($trainerIdx as $ti) {
        $tSet = array_unique($ti['tokens']);
        sort($tSet);
        $overlap = count(array_intersect($bioSet, $tSet));
        $allBioInTrainer = count(array_diff($bioSet, $tSet)) === 0;
        $allTrainerInBio = count(array_diff($tSet, $bioSet)) === 0;
        if ($overlap >= 2 && ($allBioInTrainer || $allTrainerInBio)) {
            $all[$ti['id']] = true;
        }
    }
    return array_keys($all);
};

foreach ($bios as $key => $info) {
    $bioClean = $cleanName($info['display']);
    $ids = $matchBio($bioClean);
    if (!empty($ids)) {
        if (count($ids) > 1) { $ambiguous++; }
        foreach ($ids as $id) {
            $updates[$id] = ['title' => $titleById[$id] ?? '', 'desc' => $info['desc']];
        }
        $matched++;
    } else {
        $unmatched[] = $info['display'];
    }
}
fwrite(STDERR, sprintf("[3/4] matched %d bios → %d trainer rows (%d titles ambiguous, %d unmatched bios)\n",
    $matched, count($updates), $ambiguous, count($unmatched)));

if (!empty($unmatched)) {
    fwrite(STDERR, "      Sample unmatched bio names (first 10): " . implode(' | ', array_slice($unmatched, 0, 10)) . "\n");
}

// 4. Emit the SQL migration — keyed by LOWER(TRIM(title)) so the same
//    file works on whatever trainers_id values prod is using (in case of
//    drift between the local backup and current production).
$fh = fopen($out, 'w');
fwrite($fh, "-- Auto-generated by scripts/local-dev/build-trainer-descriptions.php\n");
fwrite($fh, "-- Source: catalog_product_entity_text where attribute_id = 153 (trainerprofile)\n");
fwrite($fh, "-- Strategy: longest-bio-wins per distinct trainer name, only fills rows\n");
fwrite($fh, "-- where description IS NULL OR is empty. Matched by normalised title\n");
fwrite($fh, "-- (LOWER(TRIM(...))) so trainers_id drift between local + prod is OK.\n");
fwrite($fh, "-- Idempotent: re-run safe. Manual edits survive the IS NULL guard.\n\n");
// Dedupe by title — multiple ids with same title would emit the same SQL,
// which is harmless but noisy.
$byTitle = [];
foreach ($updates as $id => $row) {
    $title = trim($row['title']);
    if ($title === '') { continue; }
    $titleKey = mb_strtolower($title, 'UTF-8');
    if (!isset($byTitle[$titleKey])) {
        $byTitle[$titleKey] = ['title' => $title, 'desc' => $row['desc']];
    }
}
ksort($byTitle);
foreach ($byTitle as $row) {
    $escapedDesc  = $read->quote($row['desc']);
    $escapedTitle = $read->quote(mb_strtolower(trim($row['title']), 'UTF-8'));
    fwrite($fh, sprintf(
        "UPDATE courses_trainers SET description = %s WHERE LOWER(TRIM(title)) = %s AND (description IS NULL OR description = '');\n",
        $escapedDesc, $escapedTitle
    ));
}
fclose($fh);

fwrite(STDERR, sprintf("[4/4] wrote %d UPDATE statements to %s\n", count($byTitle), $out));
echo "done\n";
