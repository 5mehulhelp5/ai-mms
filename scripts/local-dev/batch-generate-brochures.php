<?php
// Batch-generate brochures for every product on a given website.
// Mirrors the admin "Generate Brochure" controller action but loops.
//
// Usage:
//   docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/batch-generate-brochures.php --wid=2
//   docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/batch-generate-brochures.php --wid=2 --limit=5
//   docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/batch-generate-brochures.php --wid=2 --no-drive
//   docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/batch-generate-brochures.php --wid=2 --regenerate
//
// Per course it (a) renders the PDF to media/courses/brochures/<SKU>-<CC>.pdf,
// (b) uploads to Drive, (c) writes the cms_block course_<SKU>_brochure with the
// download link. Idempotent — skips courses whose PDF + cms_block are both already
// in place unless --regenerate is passed.
// Output buffering must start before Mage.php boots so the adminhtml session
// can call session_start() / session_save_path() without "headers already sent"
// warnings. Magento's stock admin path always runs under PHP-FPM where output
// is buffered by Apache; in CLI we have to do it manually.
@ob_start();
@session_save_path(sys_get_temp_dir());

require_once __DIR__ . '/../../app/Mage.php';
Mage::app('admin', 'store');

// Pre-warm the adminhtml session singletons so that subsequent product->load()
// (which triggers MMD_CustomOptions_Model_Mysql4_Product_Option_Collection
// ::addTitleToResult → Mage::getSingleton('adminhtml/session/quote')) finds
// them ready and doesn't try to re-init the session mid-loop.
try { Mage::getSingleton('core/session', array('name' => 'adminhtml')); } catch (Throwable $e) {}
try { Mage::getSingleton('adminhtml/session'); } catch (Throwable $e) {}
try { Mage::getSingleton('adminhtml/session_quote'); } catch (Throwable $e) {}

// Discard the warm-up buffer now that session_start() etc. have run. Subsequent
// echoes flush immediately so `tail -f /tmp/my-batch.log` shows progress live.
while (ob_get_level() > 0) { @ob_end_clean(); }
@ob_implicit_flush(true);

// Magento converts PHP warnings to exceptions. Drop warnings/notices from the
// promoter so a benign session-headers warning doesn't kill the loop.
$origLevel = error_reporting();
error_reporting($origLevel & ~E_WARNING & ~E_NOTICE & ~E_STRICT & ~E_DEPRECATED);

$opts = array(
    'wid'        => 0,
    'limit'      => 0,
    'sku_like'   => '',
    'no_drive'   => false,
    'regenerate' => false,
);
foreach ($argv as $arg) {
    if (preg_match('/^--wid=(\d+)$/',     $arg, $m)) $opts['wid']        = (int) $m[1];
    if (preg_match('/^--limit=(\d+)$/',   $arg, $m)) $opts['limit']      = (int) $m[1];
    if (preg_match('/^--sku-like=(.+)$/', $arg, $m)) $opts['sku_like']   = $m[1];
    if ($arg === '--no-drive')                       $opts['no_drive']   = true;
    if ($arg === '--regenerate')                     $opts['regenerate'] = true;
}
if ($opts['wid'] <= 0) {
    fwrite(STDERR, "Usage: --wid=2  (1=SG 2=MY 3=GH 4=NG 5=BT 6=IN)\n");
    exit(1);
}

$ccMap   = array(1 => 'SG', 2 => 'MY', 3 => 'GH', 4 => 'NG', 5 => 'BT', 6 => 'IN');
$skuLike = $opts['sku_like'] !== '' ? $opts['sku_like'] : ($opts['wid'] === 1 ? '' : 'M%');
$cc      = $ccMap[$opts['wid']] ?? 'SG';

// Force Branchscope to resolve active_wid to the requested website.
Mage::app()->getRequest()->setParam('store', $opts['wid']);

require_once __DIR__ . '/../../app/code/local/MMD/RoleManager/controllers/Adminhtml/CoursesaveController.php';

// Sub-class the controller so we can call its protected methods.
$controller = new class extends MMD_RoleManager_Adminhtml_CoursesaveController {
    public function __construct() {}
    public function buildContext($p)    { return $this->_collectBrochureContext($p); }
    public function renderPdf($p, $c)   { return $this->_renderBrochurePdf($p, $c); }
    public function driveUpload($f, $n, $cc) { return $this->_uploadBrochureToDrive($f, $n, $cc); }
};

$db = Mage::getSingleton('core/resource')->getConnection('core_write');

// Discover candidate products.
$query = "
  SELECT DISTINCT p.entity_id, p.sku
  FROM catalog_product_entity p
  JOIN catalog_product_website pw ON pw.product_id=p.entity_id AND pw.website_id=:wid
  WHERE 1
";
$params = array('wid' => $opts['wid']);
if ($skuLike !== '') {
    $query .= " AND p.sku LIKE :sku ";
    $params['sku'] = $skuLike;
}
$query .= " ORDER BY p.sku ASC";
if ($opts['limit'] > 0) $query .= " LIMIT " . ((int) $opts['limit']);

$rows = $db->fetchAll($query, $params);
$total = count($rows);
echo "Batch: $total product(s) on website {$opts['wid']} ($cc), regen=" . ($opts['regenerate']?'yes':'no')
    . ", drive=" . ($opts['no_drive']?'OFF':'on') . PHP_EOL;
echo str_repeat('-', 60) . PHP_EOL;

$brochureDir = Mage::getBaseDir('media') . '/courses/brochures';
if (!is_dir($brochureDir)) { @mkdir($brochureDir, 0777, true); @chmod($brochureDir, 0777); }

$stats = array('rendered'=>0,'skipped'=>0,'drive_ok'=>0,'drive_skip'=>0,'drive_fail'=>0,'cms_set'=>0,'fail'=>0);
$tBatch = microtime(true);
$i = 0;

foreach ($rows as $row) {
    $i++;
    $sku    = (string) $row['sku'];
    $safe   = preg_replace('/[^A-Za-z0-9._-]/', '_', $sku);
    $pdfPath = $brochureDir . '/' . $safe . '-' . $cc . '.pdf';
    $blockId = 'course_' . $sku . '_brochure';

    echo "[$i/$total] $sku ... ";

    try {
        $product = Mage::getModel('catalog/product')
            ->setStoreId(Mage_Core_Model_App::ADMIN_STORE_ID)
            ->load((int) $row['entity_id']);
        if (!$product->getId()) { echo "MISSING\n"; $stats['fail']++; continue; }

        $havePdf = is_file($pdfPath);
        $blockExists = (int) $db->fetchOne(
            "SELECT block_id FROM cms_block WHERE identifier=?", array($blockId)
        );

        if ($havePdf && $blockExists && !$opts['regenerate']) {
            echo "skip (pdf+block already)\n";
            $stats['skipped']++;
            continue;
        }

        if (!$havePdf || $opts['regenerate']) {
            $ctx = $controller->buildContext($product);
            $controller->renderPdf($product, $ctx);
            if (!is_file($pdfPath)) {
                throw new RuntimeException("PDF not written to $pdfPath");
            }
            $stats['rendered']++;
        }

        if (!$opts['no_drive']) {
            $res = $controller->driveUpload($pdfPath, basename($pdfPath), $cc);
            if (!empty($res['uploaded'])) {
                $stats['drive_ok']++;
            } elseif (!empty($res['skipped'])) {
                $stats['drive_skip']++;
            } else {
                $stats['drive_fail']++;
                echo "[drive:fail] ";
            }
        }

        // cms_block: identifier + content + store=All.
        $mtime   = filemtime($pdfPath);
        $href    = rtrim(Mage::getBaseUrl('media'), '/') . '/courses/brochures/'
                 . rawurlencode($safe . '-' . $cc) . '.pdf?v=' . $mtime;
        $content = '<a href="' . htmlspecialchars($href, ENT_QUOTES) . '" target="_blank">Download Course Brochure</a>';

        $block = Mage::getModel('cms/block')->load($blockId);
        if (!$block->getId()) {
            $block->setIdentifier($blockId)
                  ->setTitle('Course Brochure - ' . $sku)
                  ->setIsActive(1);
        }
        $block->setContent($content)->setStores(array(0))->save();
        $stats['cms_set']++;

        echo "ok (" . number_format(filesize($pdfPath)/1024,1) . "KB, mtime=" . date('H:i:s', $mtime) . ")\n";

    } catch (Throwable $e) {
        echo "FAIL: " . $e->getMessage() . "\n";
        $stats['fail']++;
    }

    // Periodic progress + ETA
    if ($i % 20 === 0 || $i === $total) {
        $elapsed = microtime(true) - $tBatch;
        $rate = $i / max($elapsed, 0.001);
        $eta = ($total - $i) / max($rate, 0.001);
        printf("--- progress %d/%d (%.1f%%), elapsed %ds, ~%ds remain ---\n",
            $i, $total, ($i/$total)*100, (int) $elapsed, (int) $eta);
    }
}

echo str_repeat('=', 60) . PHP_EOL;
echo "Done in " . number_format(microtime(true) - $tBatch, 1) . "s\n";
print_r($stats);
