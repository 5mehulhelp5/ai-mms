<?php
/**
 * Dry-run audit of unused media files.
 *
 * Builds a "keep-list" from every database column that can reference a
 * media file, walks media/wysiwyg/, media/catalog/product/, and
 * media/catalog/category/ on disk, and writes a CSV of every file that
 * is NOT referenced anywhere.
 *
 * NEVER deletes. Output goes to var/log/audit-unused-media-<ts>.csv.
 *
 * Usage (inside container):
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/maintenance/audit-unused-media.php
 *
 * Reads:
 *   - cms_block.content  (active blocks only)
 *   - cms_page.content   (active pages only)
 *   - catalog_product_entity_media_gallery.value
 *   - catalog_category_entity_varchar (image / thumbnail attrs)
 *   - core_config_data    (image-pathy values)
 *   - courses_trainers.profile_image
 *   - courses_providers.profile_image
 *
 * Also keeps an explicit banner allowlist for files referenced by the
 * Infortis Ultimo carousel widget that don't otherwise show up in
 * cms_block content (defensive — should be covered by the block scan).
 */

require_once dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app('admin');

$resource = Mage::getSingleton('core/resource');
/** @var Varien_Db_Adapter_Pdo_Mysql $read */
$read = $resource->getConnection('core_read');

$webroot = realpath(dirname(__DIR__, 2));

// ---------- 1) Build keep-list ----------
$keep = []; // normalized relative paths under webroot, e.g. "media/wysiwyg/alfred-ang.png"

function add_ref(array &$keep, string $raw, string $defaultDir = '')
{
    $raw = trim($raw);
    if ($raw === '') return;
    // Normalise: strip leading slash, "media/" prefix variations, query strings.
    $raw = preg_replace('/[?#].*$/', '', $raw);
    $raw = ltrim($raw, '/');
    // If it looks like a bare filename inside one of our known dirs, prepend.
    if ($defaultDir !== '' && strpos($raw, '/') === false) {
        $raw = rtrim($defaultDir, '/') . '/' . $raw;
    }
    // Common forms:
    //   wysiwyg/foo.jpg          -> media/wysiwyg/foo.jpg
    //   media/wysiwyg/foo.jpg    -> media/wysiwyg/foo.jpg
    //   /w/o/wordpress.jpg       -> media/catalog/product/w/o/wordpress.jpg
    //   foo.jpg (under category) -> media/catalog/category/foo.jpg
    if (strpos($raw, 'media/') !== 0
        && strpos($raw, 'wysiwyg/') === 0) {
        $raw = 'media/' . $raw;
    }
    $keep[$raw] = true;
}

// 1a) cms_block + cms_page content — grep wysiwyg refs.
foreach (['cms_block', 'cms_page'] as $tbl) {
    $rows = $read->fetchCol("SELECT content FROM {$tbl} WHERE is_active = 1");
    foreach ($rows as $content) {
        if (!$content) continue;
        if (preg_match_all(
            '#(?:media/)?wysiwyg/[A-Za-z0-9._/\-]+\.(?:jpg|jpeg|png|gif|webp|svg|pdf|JPG|JPEG|PNG|GIF)#',
            $content,
            $m
        )) {
            foreach ($m[0] as $hit) add_ref($keep, $hit);
        }
    }
}

// 1b) catalog_product_entity_media_gallery — product images live under media/catalog/product/<value>
$prodImgs = $read->fetchCol("SELECT DISTINCT value FROM catalog_product_entity_media_gallery WHERE value IS NOT NULL AND value != ''");
foreach ($prodImgs as $v) {
    $v = ltrim($v, '/');
    add_ref($keep, 'media/catalog/product/' . $v);
}

// 1c) catalog_category_entity_varchar — image / thumbnail attrs, under media/catalog/category/<value>
$catImgs = $read->fetchCol("
    SELECT DISTINCT v.value
    FROM catalog_category_entity_varchar v
    JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3
    WHERE a.attribute_code IN ('image','thumbnail')
      AND v.value IS NOT NULL AND v.value != ''
");
foreach ($catImgs as $v) {
    $v = ltrim($v, '/');
    add_ref($keep, 'media/catalog/category/' . $v);
}

// 1d) core_config_data — values that look like image paths.
$configRows = $read->fetchAll("
    SELECT path, value FROM core_config_data
    WHERE value REGEXP '\\\\.(jpg|jpeg|png|gif|webp|svg)\$' AND value NOT LIKE 'http%'
");
foreach ($configRows as $row) {
    $path  = $row['path'];
    $value = ltrim($row['value'], '/');
    // Most config values are relative to media/<something>/ depending on the field.
    // Conservatively allow them under the common roots.
    foreach (['media/' . $value, 'media/wysiwyg/' . $value, 'media/' . ltrim(str_replace('default/', '', $value), '/')] as $cand) {
        add_ref($keep, $cand);
    }
    // Logo paths live under media/<store>/images/ — also keep them.
    if (strpos($value, 'images/') === 0) {
        add_ref($keep, 'media/' . $value);
    }
}

// 1e) courses_trainers.profile_image + courses_providers.profile_image
foreach (
    [
        'courses_trainers'  => 'media/trainers',
        'courses_providers' => 'media/providers',
    ] as $tbl => $defaultDir
) {
    try {
        $rows = $read->fetchCol("SELECT DISTINCT profile_image FROM {$tbl} WHERE profile_image IS NOT NULL AND profile_image != ''");
        foreach ($rows as $v) {
            $v = ltrim($v, '/');
            add_ref($keep, $v, $defaultDir);
            add_ref($keep, 'media/' . $v);
            add_ref($keep, 'media/wysiwyg/' . $v);
        }
    } catch (Exception $e) { /* table missing — skip */ }
}

// 1f) Belt-and-suspenders banner allowlist (explicit filenames the homepage
//     carousel cycles through, in case any are referenced only via widget
//     config blobs that the scan above missed).
$bannerAllowlist = [
    'media/wysiwyg/banner.png',
    'media/wysiwyg/tertiarycouresebanner2.jpg',
    'media/wysiwyg/tertiarycouresebanner3.jpg',
    'media/tertiarycouresebanner2.jpg',
    'media/tertiarycouresebanner3.jpg',
];
foreach ($bannerAllowlist as $p) $keep[$p] = true;

// 1g) Theme asset directories — Infortis Ultimo references these pattern
//     backgrounds + demo assets via theme config, not via cms_block content.
//     Verified locally that deleting them produced a 500 on the storefront
//     (media/wysiwyg/infortis/ultimo/_patterns/default/1.png). Treat the
//     whole infortis/* + demo/* subtrees as "keep" regardless of DB refs.
$themePrefixes = [
    'media/wysiwyg/infortis/',
    'media/wysiwyg/demo/',
];

// ---------- 2) Walk filesystem ----------
$targets = [
    'media/wysiwyg'         => 'wysiwyg',
    'media/catalog/product' => 'catalog-product',
    'media/catalog/category'=> 'catalog-category',
    'media/trainers'        => 'trainers',
    'media/providers'       => 'providers',
];

$tsTag    = date('Ymd-His');
$csvPath  = $webroot . '/var/log/audit-unused-media-' . $tsTag . '.csv';
@mkdir(dirname($csvPath), 0775, true);
$fh = fopen($csvPath, 'w');
fputcsv($fh, ['relative_path', 'size_bytes', 'size_human', 'last_modified', 'category', 'reason']);

$skipDirs   = ['.thumbs', 'cache', 'watermark', 'placeholder', 'swatches', 'tmp'];
$exts       = ['jpg','jpeg','png','gif','webp','svg','JPG','JPEG','PNG','GIF','pdf'];
$candCount  = 0;
$candBytes  = 0;
$totalCount = 0;
$totalBytes = 0;

function human_size(int $b): string
{
    foreach (['B','KB','MB','GB'] as $u) {
        if ($b < 1024) return $b . $u;
        $b = intdiv($b, 1024);
    }
    return $b . 'TB';
}

foreach ($targets as $relRoot => $category) {
    $absRoot = $webroot . '/' . $relRoot;
    if (!is_dir($absRoot)) continue;

    $rii = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($absRoot, FilesystemIterator::SKIP_DOTS),
        RecursiveIteratorIterator::LEAVES_ONLY
    );
    foreach ($rii as $file) {
        if (!$file->isFile()) continue;

        $abs = $file->getPathname();
        $rel = substr($abs, strlen($webroot) + 1);

        // Skip Magento's resize/cache subtrees — those rebuild themselves.
        foreach ($skipDirs as $sk) {
            if (strpos($rel, '/' . $sk . '/') !== false) continue 2;
        }
        $ext = strtolower(pathinfo($rel, PATHINFO_EXTENSION));
        if (!in_array($ext, array_map('strtolower', $exts), true)) continue;

        $size = $file->getSize();
        $totalCount++;
        $totalBytes += $size;

        // Build the candidate-keys to test against the keep-list.
        $relKeys = [$rel];
        // catalog/product paths: also try without the /a/b/ prefix shard.
        if (strpos($rel, 'media/catalog/product/') === 0) {
            // The DB stores "/w/o/wordpress.jpg" — already covered by add_ref.
        }

        $isKept = false;
        foreach ($relKeys as $k) {
            if (isset($keep[$k])) { $isKept = true; break; }
        }
        // Theme-prefix allowlist — keep the whole subtree.
        if (!$isKept) {
            foreach ($themePrefixes as $pref) {
                if (strpos($rel, $pref) === 0) { $isKept = true; break; }
            }
        }
        if ($isKept) continue;

        // Heuristic reason
        $reason = 'no DB reference';
        if ($category === 'wysiwyg') {
            $base = basename($rel);
            // Single-personal-name PNG (one token, no hyphen) → "likely trainer headshot"
            if (preg_match('/\.png$/i', $base) && preg_match('/^[A-Za-z][A-Za-z0-9_]+\.png$/i', $base)) {
                $reason = 'likely trainer headshot (no DB reference)';
            }
        } elseif ($category === 'catalog-product') {
            $reason = 'old product image (no media_gallery row)';
        } elseif ($category === 'catalog-category') {
            $reason = 'old category image (no EAV reference)';
        } elseif ($category === 'trainers' || $category === 'providers') {
            $reason = 'orphaned trainer/provider photo';
        }

        fputcsv($fh, [
            $rel,
            $size,
            human_size($size),
            date('Y-m-d H:i:s', $file->getMTime()),
            $category,
            $reason,
        ]);
        $candCount++;
        $candBytes += $size;
    }
}
fclose($fh);

echo "CSV written: {$csvPath}\n";
echo "Keep-list entries: " . count($keep) . "\n";
echo "Scanned files: {$totalCount} (" . human_size($totalBytes) . ")\n";
echo "Deletion candidates: {$candCount} (" . human_size($candBytes) . ")\n";
echo "  -> wysiwyg:         " . shell_exec("awk -F, '\$5==\"wysiwyg\"{c++;b+=\$2}END{print c\" files / \"int(b/1024/1024)\"MB\"}' " . escapeshellarg($csvPath));
echo "  -> catalog-product: " . shell_exec("awk -F, '\$5==\"catalog-product\"{c++;b+=\$2}END{print c\" files / \"int(b/1024/1024)\"MB\"}' " . escapeshellarg($csvPath));
echo "  -> catalog-category:" . shell_exec("awk -F, '\$5==\"catalog-category\"{c++;b+=\$2}END{print c\" files / \"int(b/1024/1024)\"MB\"}' " . escapeshellarg($csvPath));
echo "  -> trainers:        " . shell_exec("awk -F, '\$5==\"trainers\"{c++;b+=\$2}END{print c\" files / \"int(b/1024/1024)\"MB\"}' " . escapeshellarg($csvPath));
echo "  -> providers:       " . shell_exec("awk -F, '\$5==\"providers\"{c++;b+=\$2}END{print c\" files / \"int(b/1024/1024)\"MB\"}' " . escapeshellarg($csvPath));
echo "\nReview the CSV. Nothing has been deleted.\n";
