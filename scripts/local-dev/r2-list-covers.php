<?php

/**
 * One-shot R2 bucket inspector.
 *
 * Lists every `course-covers/*.png` object in the R2 bucket and prints the
 * mapping (sku → most recent public URL) along with raw counts. Used to
 * recover the cover URLs after an interrupted bulk run, so a SQL migration
 * can be generated without re-uploading the same PNGs.
 *
 * Run from the host: docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/r2-list-covers.php
 */

require_once '/var/www/html/app/Mage.php';
Mage::app();

/** @var MMD_CourseImage_Helper_Data $cfg */
$cfg = Mage::helper('mmd_courseimage');

$accessKey = $cfg->env('R2_ACCESS_KEY_ID');
$secretKey = $cfg->env('R2_SECRET_ACCESS_KEY');
$endpoint  = rtrim((string) $cfg->env('R2_ENDPOINT', ''), '/');
$bucket    = $cfg->env('R2_BUCKET');
$publicUrl = rtrim((string) $cfg->env('R2_PUBLIC_URL', ''), '/');

if (!$accessKey || !$secretKey || !$endpoint || !$bucket || !$publicUrl) {
    fwrite(STDERR, "R2 not configured (env vars missing)\n");
    exit(1);
}

$host = parse_url($endpoint, PHP_URL_HOST);
$region = 'auto';
$service = 's3';

/**
 * Sign + execute a GET ListObjectsV2 call. Returns parsed XML.
 */
function r2_list_page(string $endpoint, string $host, string $bucket, string $accessKey, string $secretKey, string $region, string $service, array $query): SimpleXMLElement
{
    ksort($query);
    $queryStr = '';
    foreach ($query as $k => $v) {
        $queryStr .= ($queryStr === '' ? '' : '&') . rawurlencode((string) $k) . '=' . rawurlencode((string) $v);
    }

    $now  = gmdate('Ymd\THis\Z');
    $date = substr($now, 0, 8);
    $hash = hash('sha256', '');

    $headers = [
        'host'                 => $host,
        'x-amz-content-sha256' => $hash,
        'x-amz-date'           => $now,
    ];
    ksort($headers);

    $canonicalHeaders = '';
    $signedHeaders    = [];
    foreach ($headers as $k => $v) {
        $canonicalHeaders .= $k . ':' . trim($v) . "\n";
        $signedHeaders[]   = $k;
    }
    $signedHeadersStr = implode(';', $signedHeaders);

    $canonicalUri = '/' . rawurlencode($bucket);
    $canonicalReq = "GET\n{$canonicalUri}\n{$queryStr}\n{$canonicalHeaders}\n{$signedHeadersStr}\n{$hash}";

    $scope        = "{$date}/{$region}/{$service}/aws4_request";
    $stringToSign = "AWS4-HMAC-SHA256\n{$now}\n{$scope}\n" . hash('sha256', $canonicalReq);

    $kDate    = hash_hmac('sha256', $date, 'AWS4' . $secretKey, true);
    $kRegion  = hash_hmac('sha256', $region, $kDate, true);
    $kService = hash_hmac('sha256', $service, $kRegion, true);
    $kSigning = hash_hmac('sha256', 'aws4_request', $kService, true);
    $sig      = hash_hmac('sha256', $stringToSign, $kSigning);

    $authHeader = sprintf(
        'AWS4-HMAC-SHA256 Credential=%s/%s, SignedHeaders=%s, Signature=%s',
        $accessKey,
        $scope,
        $signedHeadersStr,
        $sig
    );

    $url = "{$endpoint}/{$bucket}?{$queryStr}";
    $ch  = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_HTTPHEADER     => [
            'Authorization: ' . $authHeader,
            'x-amz-content-sha256: ' . $hash,
            'x-amz-date: ' . $now,
        ],
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT        => 30,
    ]);
    $resp = curl_exec($ch);
    $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($code !== 200) {
        throw new RuntimeException("ListObjectsV2 HTTP {$code}: " . substr((string) $resp, 0, 400));
    }
    return simplexml_load_string((string) $resp);
}

// Page through the bucket, collecting every course-covers/*.png key.
$all = [];
$continuationToken = null;
$pages = 0;
do {
    $q = ['list-type' => '2', 'prefix' => 'course-covers/', 'max-keys' => '1000'];
    if ($continuationToken !== null) {
        $q['continuation-token'] = $continuationToken;
    }
    $xml = r2_list_page($endpoint, $host, $bucket, $accessKey, $secretKey, $region, $service, $q);
    $pages++;

    foreach ($xml->Contents ?? [] as $obj) {
        $key  = (string) $obj->Key;
        $size = (int) $obj->Size;
        $lm   = (string) $obj->LastModified;
        if (substr($key, -4) !== '.png') {
            continue;
        }
        $all[] = ['key' => $key, 'size' => $size, 'lm' => $lm];
    }

    $isTruncated = (string) ($xml->IsTruncated ?? 'false') === 'true';
    $continuationToken = $isTruncated ? (string) $xml->NextContinuationToken : null;
} while ($continuationToken !== null);

// Parse: keys look like `course-covers/{safeSku}-{YYYYMMDD}-{HHmmss}.png`.
// The trailing "-YYYYMMDD-HHmmss.png" is always 20 chars. Strip it to recover
// safeSku, which is the SKU after replacing non-[a-zA-Z0-9-] with "-".
$bySafeSku = [];
foreach ($all as $row) {
    $base = substr($row['key'], strlen('course-covers/'));
    if (!preg_match('/^(.+)-(\d{8})-(\d{6})\.png$/', $base, $m)) {
        continue;
    }
    $safeSku = $m[1];
    $stampTs = mktime(
        (int) substr($m[3], 0, 2),
        (int) substr($m[3], 2, 2),
        (int) substr($m[3], 4, 2),
        (int) substr($m[2], 4, 2),
        (int) substr($m[2], 6, 2),
        (int) substr($m[2], 0, 4)
    );
    if (!isset($bySafeSku[$safeSku]) || $bySafeSku[$safeSku]['ts'] < $stampTs) {
        $bySafeSku[$safeSku] = ['ts' => $stampTs, 'key' => $row['key']];
    }
}

echo "R2 listing summary:\n";
echo "  total PNG keys: " . count($all) . " (pages: {$pages})\n";
echo "  unique safe-SKUs: " . count($bySafeSku) . "\n\n";

// Cross-reference against catalog SKUs so we can output (sku → url) pairs
// rather than (safeSku → url), and identify any keys that don't match a
// known product (likely orphaned uploads we can ignore).
$skuMap = [];
$collection = Mage::getResourceModel('catalog/product_collection')
    ->addAttributeToSelect(['sku']);
foreach ($collection as $p) {
    $sku = (string) $p->getSku();
    if ($sku === '') {
        continue;
    }
    $safe = preg_replace('/[^a-z0-9\-]+/i', '-', $sku);
    if ($safe !== null && $safe !== '') {
        $skuMap[$safe] = $sku;
    }
}

$matched = [];
$orphans = [];
foreach ($bySafeSku as $safeSku => $info) {
    if (isset($skuMap[$safeSku])) {
        $matched[$skuMap[$safeSku]] = "{$publicUrl}/{$info['key']}";
    } else {
        $orphans[] = $safeSku;
    }
}

echo "Matched to a current SKU: " . count($matched) . "\n";
echo "Orphan keys (no matching SKU in catalog): " . count($orphans) . "\n";
if ($orphans) {
    echo "  Sample orphans: " . implode(', ', array_slice($orphans, 0, 5)) . "\n";
}
echo "\n";

// Write out a JSON dump that the migration generator can consume.
$out = '/tmp/r2-covers.json';
file_put_contents($out, json_encode($matched, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
echo "Wrote {$out}\n";
