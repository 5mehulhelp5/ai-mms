<?php
// EMERGENCY: cancel every "ready" Course Spotlight campaign on
// MailerLite so it cannot send. Moves each one back to draft via the
// /cancel endpoint. The cron-side stop is handled by removing the
// crontab registration (same commit); this script handles the already-
// queued sends that wouldn't be affected by code changes.

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

list($code, $raw) = ml($key, 'GET', '/campaigns?filter[status]=ready&limit=100');
$rsp = json_decode($raw, true);
$ready = $rsp['data'] ?? array();
echo "ready campaigns on MailerLite: " . count($ready) . "\n";

$targets = array();
foreach ($ready as $c) {
    $name = (string) ($c['name'] ?? '');
    if (stripos($name, 'Course Spotlight:') === 0 || stripos($name, 'Auto:') === 0) {
        $targets[] = $c;
    }
}
echo "matching cron-pattern (Course Spotlight: / Auto:): " . count($targets) . "\n\n";

$ok = 0; $fail = 0;
foreach ($targets as $c) {
    $id = $c['id'];
    $name = substr((string) ($c['name'] ?? ''), 0, 70);
    $sched = (string) ($c['scheduled_for'] ?? '');
    echo "  $id  sched=$sched  $name\n";
    list($ccode, $craw) = ml($key, 'POST', '/campaigns/' . $id . '/cancel');
    if ($ccode >= 200 && $ccode < 300) {
        echo "    CANCELLED (http $ccode)\n";
        $ok++;
    } else {
        echo "    FAILED http=$ccode body=" . substr($craw, 0, 150) . "\n";
        $fail++;
    }
}
echo "\nresult: cancelled=$ok failed=$fail\n";
