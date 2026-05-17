<?php
/**
 * Backfill the 403 reviews from the 2026-05-17 production snapshot
 * (review_id 22460..22862) to the new Hostinger DB via the Kael Review
 * API. Reads from the LOCAL DB and POSTs to the configured prod URL,
 * preserving original `created_at`.
 *
 * Usage:
 *   KAEL_REVIEW_API_KEY=... \
 *   KAEL_REVIEW_API_URL=https://www.tertiarycourses.com.sg/kael_review_api.php \
 *   docker exec -i ai-mms-web-1 php /var/www/html/scripts/local-dev/sync-reviews-to-prod.php
 *
 *   # Or, to test a single review:
 *   ... php scripts/local-dev/sync-reviews-to-prod.php --limit=1
 *
 *   # Dry run (no POST, just print what would be sent):
 *   ... php scripts/local-dev/sync-reviews-to-prod.php --dry-run
 *
 * Idempotency: progress is recorded in
 * `scripts/local-dev/.review-sync-progress.json` keyed by source
 * `review_id`. Re-running the script skips already-synced reviews.
 */

ini_set('display_errors', '1');
error_reporting(E_ALL);

// ── Args / env ─────────────────────────────────────────────────────────
$apiUrl = getenv('KAEL_REVIEW_API_URL') ?: '';
$apiKey = getenv('KAEL_REVIEW_API_KEY') ?: '';
$limit  = 0;
$dryRun = false;
foreach (array_slice($argv, 1) as $a) {
    if (strpos($a, '--limit=') === 0)   { $limit = (int) substr($a, 8); }
    elseif ($a === '--dry-run')         { $dryRun = true; }
}

if ($apiUrl === '' || $apiKey === '') {
    fwrite(STDERR, "ERROR: KAEL_REVIEW_API_URL and KAEL_REVIEW_API_KEY env vars are required.\n");
    exit(2);
}

// ── DB connection (read from app/etc/local.xml) ────────────────────────
$xml = simplexml_load_file(__DIR__ . '/../../app/etc/local.xml');
if (!$xml) { fwrite(STDERR, "ERROR: cannot read app/etc/local.xml\n"); exit(2); }
$dbHost = (string) $xml->global->resources->default_setup->connection->host;
$dbUser = (string) $xml->global->resources->default_setup->connection->username;
$dbPass = (string) $xml->global->resources->default_setup->connection->password;
$dbName = (string) $xml->global->resources->default_setup->connection->dbname;

$pdo = new PDO("mysql:host=$dbHost;dbname=$dbName;charset=utf8", $dbUser, $dbPass, array(
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
));

// ── Progress ledger ────────────────────────────────────────────────────
$progressFile = __DIR__ . '/.review-sync-progress.json';
$progress = file_exists($progressFile)
    ? json_decode(file_get_contents($progressFile), true)
    : array();
if (!is_array($progress)) $progress = array();

// ── Query the 403 reviews + their ratings ──────────────────────────────
$sql = "
SELECT r.review_id, r.created_at, r.entity_pk_value AS product_id,
       rd.nickname, rd.title, rd.detail, rd.customer_id, rd.store_id
FROM review r
JOIN review_detail rd ON rd.review_id = r.review_id
WHERE r.review_id BETWEEN 22460 AND 22862
ORDER BY r.review_id
";
$reviews = $pdo->query($sql)->fetchAll(PDO::FETCH_ASSOC);

$votesStmt = $pdo->prepare("SELECT rating_id, value FROM rating_option_vote WHERE review_id = ?");

echo sprintf("Found %d source reviews. API: %s\n", count($reviews), $apiUrl);

$sent = $skipped = $failed = 0;

foreach ($reviews as $row) {
    $srcId = (int) $row['review_id'];

    if (isset($progress[$srcId])) {
        $skipped++;
        continue;
    }

    $votesStmt->execute(array($srcId));
    $ratings = array();
    foreach ($votesStmt->fetchAll(PDO::FETCH_ASSOC) as $v) {
        $ratings[(string) $v['rating_id']] = (int) $v['value'];
    }

    $payload = array(
        'product_id' => (int) $row['product_id'],
        'nickname'   => (string) $row['nickname'],
        'title'      => (string) $row['title'],
        'detail'     => (string) $row['detail'],
        'ratings'    => $ratings,
        'created_at' => (string) $row['created_at'],
        'store_id'   => (int) $row['store_id'],
    );
    if ($row['customer_id'] !== null && $row['customer_id'] !== '') {
        $payload['customer_id'] = (int) $row['customer_id'];
    }

    if ($dryRun) {
        echo "DRY  src=$srcId product={$payload['product_id']} created_at={$payload['created_at']}\n";
        continue;
    }

    $ch = curl_init($apiUrl);
    curl_setopt_array($ch, array(
        CURLOPT_POST            => true,
        CURLOPT_POSTFIELDS      => json_encode($payload),
        CURLOPT_HTTPHEADER      => array(
            'Content-Type: application/json',
            'X-Api-Key: ' . $apiKey,
        ),
        CURLOPT_RETURNTRANSFER  => true,
        CURLOPT_TIMEOUT         => 30,
        CURLOPT_USERAGENT       => 'kael-review-sync/1.0',
    ));
    $body  = curl_exec($ch);
    $http  = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $cerr  = curl_error($ch);
    curl_close($ch);

    if ($http !== 200) {
        $failed++;
        echo "FAIL src=$srcId http=$http err=" . ($cerr ?: substr((string) $body, 0, 200)) . "\n";
        // Stop on first failure so we don't blast 403 bad requests.
        break;
    }

    $resp = json_decode((string) $body, true);
    $newId = is_array($resp) && isset($resp['review_id']) ? (int) $resp['review_id'] : 0;
    $progress[$srcId] = $newId;
    file_put_contents($progressFile, json_encode($progress, JSON_PRETTY_PRINT));
    $sent++;

    echo sprintf("OK   src=%d -> prod=%d (%s)\n", $srcId, $newId, $payload['created_at']);

    if ($limit > 0 && $sent >= $limit) {
        echo "Reached --limit=$limit. Stopping.\n";
        break;
    }

    // Gentle pacing — 5/sec is plenty for a 403-row backfill.
    usleep(200000);
}

echo "\nDone. sent=$sent skipped=$skipped failed=$failed\n";
echo "Progress ledger: $progressFile\n";
