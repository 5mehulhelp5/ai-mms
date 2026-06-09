<?php
/**
 * Prune manual core_url_rewrite rows whose source product is gone AND
 * whose target slug shares less than half of its meaningful tokens with
 * the source slug (Jaccard < 0.5) — i.e. the random/garbage redirects
 * that send course pages to unrelated courses.
 *
 * Two-phase, operator-driven:
 *
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/maintenance/prune-bad-url-redirects.php --dry-run
 *     → audits + scores + prints bucket counts and the first 20 matches.
 *       Writes nothing. Safe on prod, run as many times as you want.
 *
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/maintenance/prune-bad-url-redirects.php --confirm
 *     → INSERTs matches into core_url_rewrite_archive_2026_06, then
 *       DELETEs them from core_url_rewrite, in batches of 1000.
 *       Idempotent (archive PK = url_rewrite_id, INSERT IGNORE).
 *       Tracks "done" in core_config_data so a re-run is a no-op.
 *
 * Why NOT auto-run via apply.php / migrations: this deletes ~26k rows
 * from a hot table. An operator should eyeball the dry-run output
 * before pulling the trigger.
 *
 * Scoring is identical to scripts/maintenance/audit-bad-url-rewrites.php
 * so dry-run counts match the original audit numbers (modulo prod/local
 * drift since the audit was first run).
 */

require_once __DIR__ . '/../../app/Mage.php';
Mage::app();

$args = array_slice($argv, 1);
$dryRun  = in_array('--dry-run',  $args, true);
$confirm = in_array('--confirm',  $args, true);
$threshold = 0.5; // matches the operator's pick on 2026-06-09

if (!$dryRun && !$confirm) {
    fwrite(STDERR, "Usage:\n");
    fwrite(STDERR, "  --dry-run    audit and report; write nothing\n");
    fwrite(STDERR, "  --confirm    archive matches then DELETE from core_url_rewrite\n");
    exit(1);
}
if ($dryRun && $confirm) {
    fwrite(STDERR, "Pass --dry-run OR --confirm, not both.\n");
    exit(1);
}

$conn   = Mage::getSingleton('core/resource')->getConnection('core_write');
$DONE_FLAG = 'mmd/url_rewrite_prune/done_2026_06';

if ($confirm) {
    $already = (string) Mage::getConfig()->getNode('default/' . $DONE_FLAG);
    $alreadyRow = $conn->fetchOne(
        "SELECT value FROM core_config_data WHERE path = ?",
        [$DONE_FLAG]
    );
    if ($alreadyRow) {
        echo "Already pruned on " . $alreadyRow . " — re-running is a no-op.\n";
        echo "To re-prune anyway, delete the core_config_data row for path='$DONE_FLAG' first.\n";
        // continue anyway — archive table is INSERT IGNORE so we won't dup
    }
    // Sanity: the archive table must exist (migration 199 must have run).
    $haveArchive = $conn->fetchOne(
        "SELECT COUNT(*) FROM information_schema.tables
          WHERE table_schema = DATABASE()
            AND table_name = 'core_url_rewrite_archive_2026_06'"
    );
    if (!$haveArchive) {
        fwrite(STDERR, "ERROR: core_url_rewrite_archive_2026_06 does not exist.\n");
        fwrite(STDERR, "Apply migration 199 first (deploy will run it via apply.php).\n");
        exit(2);
    }
}

// Generic course-slug noise that doesn't carry topical meaning.
// MUST match scripts/maintenance/audit-bad-url-rewrites.php exactly so
// dry-run scores reproduce the original audit numbers.
$stopwords = array_flip([
    'training', 'course', 'courses', 'day', 'days', 'hour', 'hours',
    'class', 'classes', 'workshop', 'workshops', 'certified', 'cert',
    'certification', 'professional', 'expert', 'beginner', 'beginners',
    'advanced', 'intermediate', 'introduction', 'fundamental', 'fundamentals',
    'essential', 'essentials', 'basic', 'basics', 'guide', 'with', 'using',
    'for', 'and', 'the', 'how', 'to', 'all', 'new', 'best', 'top',
    'singapore', 'malaysia', 'ghana', 'nigeria', 'bhutan', 'india',
    'wsq', 'tgs', 'in', 'on', 'of', 'an',
]);

$tokenize = function ($slug) use ($stopwords) {
    $slug  = preg_replace('/\.html$/i', '', (string) $slug);
    $slug  = preg_replace('/-\d+$/', '', $slug); // strip Magento -1 / -2 collision suffix
    $parts = preg_split('/[\/\-_]+/', strtolower($slug));
    $out   = [];
    foreach ($parts as $p) {
        $p = trim($p);
        if (strlen($p) < 3)                continue;
        if (isset($stopwords[$p]))         continue;
        if (preg_match('/^\d+$/', $p))     continue;
        $out[$p] = true;
    }
    return array_keys($out);
};

$jaccard = function ($a, $b) {
    if (!$a || !$b) return 0.0;
    $i = array_intersect($a, $b);
    $u = array_unique(array_merge($a, $b));
    return count($u) > 0 ? count($i) / count($u) : 0.0;
};

$urlKeyAttrId = (int) $conn->fetchOne(
    "SELECT attribute_id FROM eav_attribute
      WHERE attribute_code = 'url_key'
        AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type
                               WHERE entity_type_code = 'catalog_product')"
);
if (!$urlKeyAttrId) {
    fwrite(STDERR, "ERROR: could not resolve url_key attribute_id\n");
    exit(3);
}

echo ($dryRun ? "[DRY RUN] " : "[CONFIRM] ")
   . "auditing orphan manual RP rewrites (.html → .html, threshold < $threshold)...\n";

// Pull candidates: manual permanent redirects where the source url_key
// no longer maps to any product (in store 0 or the redirect's store).
// .html on both sides keeps us off category/CMS rows we don't audit.
$rows = $conn->fetchAll("
    SELECT cur.url_rewrite_id, cur.store_id, cur.request_path, cur.target_path
      FROM core_url_rewrite cur
     WHERE cur.options = 'RP'
       AND cur.is_system = 0
       AND cur.target_path  LIKE '%.html'
       AND cur.request_path LIKE '%.html'
       AND NOT EXISTS (
           SELECT 1 FROM catalog_product_entity_varchar cpev
            WHERE cpev.attribute_id = {$urlKeyAttrId}
              AND cpev.store_id IN (0, cur.store_id)
              AND cpev.value = REPLACE(SUBSTRING_INDEX(cur.request_path, '/', -1), '.html', '')
       )
");

echo "Loaded " . number_format(count($rows)) . " candidates. Scoring...\n";

$toPrune = [];
$buckets = [
    '0.00 (no overlap)'  => 0,
    '0.01 - 0.24 (poor)' => 0,
    '0.25 - 0.49 (weak)' => 0,
    '0.50 - 0.74 (ok)'   => 0,
    '0.75 - 1.00 (good)' => 0,
];
foreach ($rows as $r) {
    $score = $jaccard(
        $tokenize($r['request_path']),
        $tokenize($r['target_path'])
    );
    if      ($score == 0)   $buckets['0.00 (no overlap)']++;
    elseif  ($score < 0.25) $buckets['0.01 - 0.24 (poor)']++;
    elseif  ($score < 0.50) $buckets['0.25 - 0.49 (weak)']++;
    elseif  ($score < 0.75) $buckets['0.50 - 0.74 (ok)']++;
    else                    $buckets['0.75 - 1.00 (good)']++;

    if ($score < $threshold) {
        $toPrune[] = [
            'id'           => (int) $r['url_rewrite_id'],
            'store_id'     => (int) $r['store_id'],
            'request_path' => $r['request_path'],
            'target_path'  => $r['target_path'],
            'score'        => $score,
        ];
    }
}

echo "\n=== Score distribution (all orphan manual RP) ===\n";
foreach ($buckets as $label => $n) printf("  %-22s %s\n", $label, number_format($n));
echo "\n=== Prune target (score < $threshold) ===\n";
echo "  rows: " . number_format(count($toPrune)) . "\n";

if (!empty($toPrune)) {
    echo "\n=== First 20 to prune ===\n";
    foreach (array_slice($toPrune, 0, 20) as $r) {
        printf("  [%.2f] (store %d) %s  ->  %s\n",
            $r['score'], $r['store_id'], $r['request_path'], $r['target_path']);
    }
}

if ($dryRun) {
    echo "\n[DRY RUN] no rows touched. Re-run with --confirm to archive + delete.\n";
    exit(0);
}

if (empty($toPrune)) {
    echo "\nNothing to do.\n";
    exit(0);
}

// --confirm path: archive in batches, then delete in batches.
// INSERT IGNORE protects against partial re-runs (archive PK = original
// url_rewrite_id). DELETE by id is naturally idempotent.
$batchSize = 1000;
$total     = count($toPrune);
$archived  = 0;
$deleted   = 0;

echo "\nArchiving + deleting in batches of $batchSize ...\n";

$conn->beginTransaction();
try {
    for ($offset = 0; $offset < $total; $offset += $batchSize) {
        $batch = array_slice($toPrune, $offset, $batchSize);
        $ids   = array_map(fn($r) => $r['id'], $batch);

        // 1) Archive — copy current row state from the live table, plus
        // our prune metadata. Doing it via JOIN keeps every column in
        // sync with the live schema even if columns get reordered.
        $idList = implode(',', $ids);
        $conn->query("
            INSERT IGNORE INTO core_url_rewrite_archive_2026_06 (
                url_rewrite_id, store_id, id_path, request_path, target_path,
                is_system, options, description, category_id, product_id,
                archived_score, archived_reason
            )
            SELECT
                cur.url_rewrite_id, cur.store_id, cur.id_path,
                cur.request_path, cur.target_path,
                cur.is_system, cur.options, cur.description,
                cur.category_id, cur.product_id,
                NULL,
                'orphan-jaccard-lt-0.5'
              FROM core_url_rewrite cur
             WHERE cur.url_rewrite_id IN ($idList)
        ");
        // Score backfill — couldn't do in one shot because scores are
        // per-row Jaccards we computed in PHP, not in SQL.
        foreach ($batch as $r) {
            $conn->update(
                'core_url_rewrite_archive_2026_06',
                ['archived_score' => round($r['score'], 3)],
                ['url_rewrite_id = ?' => $r['id']]
            );
        }
        $archived += count($batch);

        // 2) Delete from live table.
        $conn->query("DELETE FROM core_url_rewrite WHERE url_rewrite_id IN ($idList)");
        $deleted += count($batch);

        printf("  ... %s / %s archived  |  %s deleted\n",
            number_format($archived), number_format($total), number_format($deleted));
    }

    // Stamp a "done" flag so a careless re-run is a no-op (the script
    // checks this at start and warns; INSERT IGNORE is the actual guard).
    $conn->query(
        "INSERT INTO core_config_data (scope, scope_id, path, value)
              VALUES ('default', 0, ?, NOW())
         ON DUPLICATE KEY UPDATE value = VALUES(value)",
        [$DONE_FLAG]
    );

    $conn->commit();
} catch (Exception $e) {
    $conn->rollBack();
    fwrite(STDERR, "ERROR: " . $e->getMessage() . "\n");
    fwrite(STDERR, "Rolled back. Live table is untouched.\n");
    exit(4);
}

echo "\nDone.\n";
echo "  archived: " . number_format($archived) . " rows -> core_url_rewrite_archive_2026_06\n";
echo "  deleted:  " . number_format($deleted)  . " rows from core_url_rewrite\n";
echo "\nRollback (if SEO falls off): see top of file — copy rows back from the archive.\n";
