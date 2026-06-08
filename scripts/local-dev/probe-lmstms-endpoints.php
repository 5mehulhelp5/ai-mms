<?php
/**
 * Probe what's available on the LMS-TMS external API.
 *
 * We already know one endpoint works: GET /api/external/trainers-export
 * (used by MMD_RoleManager_Model_TrainerImportService). What we need next
 * is an endpoint that returns "scheduled classes with assigned trainers
 * for a given date" so the WhatsApp trainer-reminders bot can use LMS-TMS
 * as a fallback when MMS shows no trainer.
 *
 * This script reads the LMS URL + API key from core_config_data
 * (mmd/trainer_import/lms_url + mmd/trainer_import/api_key) and tries a
 * grid of candidate paths. For each it reports the HTTP code and a short
 * body preview so we can see which paths exist, which 404, and what shape
 * the live ones return.
 *
 * Usage on prod (Coolify container):
 *   docker exec <web-container> php /var/www/html/scripts/local-dev/probe-lmstms-endpoints.php
 *
 * Read-only (GET only). Safe to run in production. No data is written.
 *
 * To probe a specific date, pass DATE=2026-06-09 as the env var:
 *   docker exec -e DATE=2026-06-09 <web-container> php /var/www/html/scripts/local-dev/probe-lmstms-endpoints.php
 */

require_once dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app();

$lmsUrl = rtrim(trim((string) Mage::getStoreConfig('mmd/trainer_import/lms_url')), '/');
$apiKey = trim((string) Mage::getStoreConfig('mmd/trainer_import/api_key'));
$date   = getenv('DATE') ?: date('Y-m-d', strtotime('+1 day'));

if ($lmsUrl === '' || $apiKey === '') {
    fwrite(STDERR, "LMS URL or API key not configured in core_config_data.\n");
    fwrite(STDERR, "  mmd/trainer_import/lms_url = '" . $lmsUrl . "'\n");
    fwrite(STDERR, "  mmd/trainer_import/api_key = " . ($apiKey ? '(set)' : '(empty)') . "\n");
    exit(1);
}

echo "LMS-TMS endpoint probe\n";
echo "======================\n";
echo "Base URL: $lmsUrl\n";
echo "Probe date: $date\n";
echo "Auth: x-api-key header (length " . strlen($apiKey) . ")\n\n";

// Candidate paths covering common REST naming for "class / schedule /
// assignment per date" lookups. Each is tried with and without ?date=,
// plus a few discovery paths (OpenAPI, listing).
$candidates = array(
    // baseline — known to work (smoke test that auth still passes)
    '/api/external/trainers-export',
    // discovery
    '/api/external',
    '/api/external/openapi.json',
    '/api/external/docs',
    '/api/docs',
    // schedule / classes / runs / sessions, with and without date
    '/api/external/classes',
    '/api/external/classes?date=' . $date,
    '/api/external/schedule',
    '/api/external/schedule?date=' . $date,
    '/api/external/runs',
    '/api/external/runs?date=' . $date,
    '/api/external/course-runs',
    '/api/external/course-runs?date=' . $date,
    '/api/external/sessions',
    '/api/external/sessions?date=' . $date,
    '/api/external/upcoming-classes',
    '/api/external/upcoming-classes?date=' . $date,
    // assignments
    '/api/external/assignments',
    '/api/external/assignments?date=' . $date,
    '/api/external/trainer-assignments',
    '/api/external/trainer-assignments?date=' . $date,
    // reminders / what-the-bot-needs (worth a try in case it already exists)
    '/api/external/reminders',
    '/api/external/reminders?date=' . $date,
    '/api/external/trainer-reminders',
    '/api/external/trainer-reminders?date=' . $date,
);

printf("%-50s  %-5s  %-25s  %s\n", 'PATH', 'HTTP', 'CONTENT-TYPE', 'TOP-LEVEL KEYS / SNIPPET');
echo str_repeat('-', 120) . "\n";

foreach ($candidates as $path) {
    $url = $lmsUrl . $path;
    $ch  = curl_init($url);
    curl_setopt_array($ch, array(
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT        => 10,
        CURLOPT_CONNECTTIMEOUT => 5,
        CURLOPT_HTTPHEADER     => array('x-api-key: ' . $apiKey, 'Accept: application/json'),
        CURLOPT_HEADER         => false,
    ));
    $raw  = curl_exec($ch);
    $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $ctype = (string) curl_getinfo($ch, CURLINFO_CONTENT_TYPE);
    $err  = curl_error($ch);
    curl_close($ch);

    $summary = '';
    if ($raw === false || $raw === '') {
        $summary = '(no body) ' . $err;
    } else {
        $decoded = json_decode($raw, true);
        if (is_array($decoded)) {
            $keys = array_keys($decoded);
            $summary = '{' . implode(', ', array_slice($keys, 0, 8)) . '}';
            if (isset($decoded['data']) && is_array($decoded['data'])) {
                $n = count($decoded['data']);
                $summary .= " data:array[$n]";
                if ($n > 0 && is_array($decoded['data'][0])) {
                    $sample = array_keys($decoded['data'][0]);
                    $summary .= ' first:{' . implode(',', array_slice($sample, 0, 8)) . '}';
                }
            } elseif (isset($decoded['error'])) {
                $summary .= ' error="' . substr((string) $decoded['error'], 0, 60) . '"';
            }
        } else {
            // not JSON — show first 80 bytes of body
            $summary = '(' . substr(trim((string) $raw), 0, 80) . ')';
        }
    }
    printf("%-50s  %-5d  %-25s  %s\n", substr($path, 0, 50), $code, substr($ctype, 0, 25), $summary);
}

echo "\nDone. Paths that returned 200 with a `data` array are candidate fallbacks.\n";
echo "Look especially for ones that include trainer_name / trainer_email + course_code + date.\n";
