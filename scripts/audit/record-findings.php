<?php
/**
 * scripts/audit/record-findings.php
 *
 * Writes an audit-findings record to var/audit-notifications/findings.json
 * so the admin header banner can surface critical issues sitewide.
 *
 * Usage:
 *   php scripts/audit/record-findings.php \
 *       --scope="SG storefront homepage + course pages" \
 *       --high=3 --medium=5 --quick=8 --low=2 --big=1 \
 *       --summary="3 high-risk indexability issues; missing hreflang on MY" \
 *       --report=/tmp/seo-audit-2026-05-29.md
 *
 * Or pipe a JSON blob on stdin:
 *   cat findings.json | php scripts/audit/record-findings.php --stdin
 *
 * To clear the banner:
 *   php scripts/audit/record-findings.php --clear
 */

$opts = getopt('', [
    'scope::', 'summary::', 'report::',
    'high::', 'medium::', 'quick::', 'low::', 'big::',
    'source::', 'stdin', 'clear',
]);

$outDir  = __DIR__ . '/../../var/audit-notifications';
$outFile = $outDir . '/findings.json';

if (!is_dir($outDir)) {
    mkdir($outDir, 0775, true);
}

if (isset($opts['clear'])) {
    if (is_file($outFile)) {
        unlink($outFile);
    }
    fwrite(STDOUT, "Audit notification cleared.\n");
    exit(0);
}

if (isset($opts['stdin'])) {
    $raw  = stream_get_contents(STDIN);
    $data = json_decode($raw, true);
    if (!is_array($data)) {
        fwrite(STDERR, "Invalid JSON on stdin.\n");
        exit(1);
    }
} else {
    $data = [
        'scope'   => $opts['scope']   ?? 'Unknown scope',
        'summary' => $opts['summary'] ?? '',
        'report'  => $opts['report']  ?? '',
        'source'  => $opts['source']  ?? 'seo-auditor',
        'counts'  => [
            'high'      => (int)($opts['high']   ?? 0),
            'medium'    => (int)($opts['medium'] ?? 0),
            'low'       => (int)($opts['low']    ?? 0),
            'quick_win' => (int)($opts['quick']  ?? 0),
            'big_bet'   => (int)($opts['big']    ?? 0),
        ],
    ];
}

$data['timestamp'] = date('c');

file_put_contents($outFile, json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
chmod($outFile, 0664);

fwrite(STDOUT, "Wrote {$outFile}\n");
