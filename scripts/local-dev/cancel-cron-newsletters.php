<?php
// EMERGENCY: nuke every cron-pattern campaign on MailerLite, in any
// state (draft OR ready). DELETE means gone, not paused — recoverable
// only from MailerLite's deleted-items if they keep one. The user
// wants ALL creation and sending stopped until they say so; this is
// the comprehensive sweep.
//
// Cron-pattern names: "Course Spotlight: ..." or "Auto: ..." — those
// are the exact prefixes the AutoNewsletter cron used. Manually-
// authored campaigns with other names are NOT touched.
//
// Run repeatedly. Each call:
//   1. lists every ready + every draft campaign matching the pattern
//   2. DELETEs each via /api/campaigns/{id}
// Idempotent: re-running on an empty MailerLite is a no-op.

require_once dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app();

$cfg = Mage::helper('mmd_rolemanager')->getMarketingApiConfig();
$key = trim((string) ($cfg['mailerlite_key'] ?? ''));
if ($key === '') { fwrite(STDERR, "no MailerLite key configured\n"); exit(1); }

function ml($key, $method, $path, $body = null) {
    $ch = curl_init('https://connect.mailerlite.com/api' . $path);
    $opts = array(
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 20,
        CURLOPT_HTTPHEADER => array(
            'Authorization: Bearer ' . $key,
            'Content-Type: application/json',
            'Accept: application/json',
        ),
    );
    if ($method === 'POST') {
        $opts[CURLOPT_POST] = true;
        $opts[CURLOPT_POSTFIELDS] = $body !== null ? json_encode($body) : '';
    } elseif ($method !== 'GET') {
        $opts[CURLOPT_CUSTOMREQUEST] = $method;
        if ($body !== null) $opts[CURLOPT_POSTFIELDS] = json_encode($body);
    }
    curl_setopt_array($ch, $opts);
    $raw = curl_exec($ch);
    $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    return array($code, $raw);
}

function isCronPattern($name) {
    return stripos($name, 'Course Spotlight:') === 0
        || stripos($name, 'Auto:') === 0;
}

$totalCancelled = 0;
$totalDeleted   = 0;
$totalFailed    = 0;

// ---- Pass 1: cancel every ready campaign (moves to draft) ----
list($code, $raw) = ml($key, 'GET', '/campaigns?filter[status]=ready&limit=100');
$rsp = json_decode($raw, true);
$ready = $rsp['data'] ?? array();
echo "[ready]  total=" . count($ready) . "\n";
foreach ($ready as $c) {
    $name = (string) ($c['name'] ?? '');
    if (!isCronPattern($name)) continue;
    list($cc, $cr) = ml($key, 'POST', '/campaigns/' . $c['id'] . '/cancel');
    if ($cc >= 200 && $cc < 300) {
        echo "  cancelled  " . $c['id'] . "  " . substr($name, 0, 60) . "\n";
        $totalCancelled++;
    } else {
        echo "  FAILED cancel " . $c['id'] . " http=$cc\n";
        $totalFailed++;
    }
}

// ---- Pass 2: delete every draft campaign matching cron pattern ----
// (includes anything just cancelled above + anything the cron is
//  still creating between sweeps)
list($code, $raw) = ml($key, 'GET', '/campaigns?filter[status]=draft&limit=100');
$rsp = json_decode($raw, true);
$drafts = $rsp['data'] ?? array();
echo "[draft]  total=" . count($drafts) . "\n";
foreach ($drafts as $c) {
    $name = (string) ($c['name'] ?? '');
    if (!isCronPattern($name)) continue;
    list($cc, $cr) = ml($key, 'DELETE', '/campaigns/' . $c['id']);
    if ($cc >= 200 && $cc < 300) {
        echo "  DELETED    " . $c['id'] . "  " . substr($name, 0, 60) . "\n";
        $totalDeleted++;
    } else {
        echo "  FAILED delete " . $c['id'] . " http=$cc body=" . substr($cr, 0, 100) . "\n";
        $totalFailed++;
    }
}

echo "\nresult: cancelled=$totalCancelled deleted=$totalDeleted failed=$totalFailed\n";
