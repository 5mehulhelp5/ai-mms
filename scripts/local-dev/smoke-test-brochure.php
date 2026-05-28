<?php
// Smoke-test the brochure generator end-to-end without going through the
// admin auth. Loads a real course by SKU, renders the PDF to media/, and
// reports timing + output path. Local-dev only.
//
//   docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/smoke-test-brochure.php TGS-2025060473
//   docker exec ai-mms-web-1 php /var/www/html/scripts/local-dev/smoke-test-brochure.php M1001 --wid=2
//
require_once __DIR__ . '/../../app/Mage.php';
Mage::app('admin', 'store');

// --wid=N → forces the brochure controller to render as if the admin's
// active website were N. Works by setting ?store=N on the current request
// so MMD_Branchscope_Helper_Data::hasExplicitChoice() returns true and
// MMD_RoleManager_Helper_Data::getActiveWebsiteId() resolves to N. Store
// IDs in this build are 1=SG, 2=MY, 3=GH, 4=NG, 5=BT, 6=IN.
$widOverride = 0;
foreach ($argv as $arg) {
    if (preg_match('/^--wid=(\d+)$/', (string) $arg, $m)) {
        $widOverride = (int) $m[1];
    }
}
if ($widOverride > 0) {
    Mage::app()->getRequest()->setParam('store', $widOverride);
}

require_once __DIR__ . '/../../app/code/local/MMD/RoleManager/controllers/Adminhtml/CoursesaveController.php';

$sku = $argv[1] ?? null;
if (!$sku) {
    // Pick any course with a TGS- prefix so we exercise a populated row.
    $sku = Mage::getModel('catalog/product')->getCollection()
        ->addAttributeToFilter('sku', array('like' => 'TGS-%'))
        ->setOrder('entity_id', 'ASC')
        ->setPageSize(1)
        ->getFirstItem()
        ->getSku();
    if (!$sku) {
        fwrite(STDERR, "No TGS-* course found and no SKU argument supplied.\n");
        exit(1);
    }
}

$product = Mage::getModel('catalog/product')->loadByAttribute('sku', $sku);
if (!$product || !$product->getId()) {
    fwrite(STDERR, "Course not found: $sku\n");
    exit(1);
}

// Re-load with admin scope (matches the controller).
$product = Mage::getModel('catalog/product')
    ->setStoreId(Mage_Core_Model_App::ADMIN_STORE_ID)
    ->load($product->getId());

// Sub-class the controller so we can poke at the protected methods.
$controller = new class extends MMD_RoleManager_Adminhtml_CoursesaveController {
    public function __construct() { /* skip Mage_Adminhtml_Controller_Action ctor — we don't need a request */ }
    public function run($product) {
        $t0 = microtime(true);
        $ctx = $this->_collectBrochureContext($product);
        $tCtx = microtime(true) - $t0;

        echo "context:\n";
        foreach (['title','sku','price','price_gst','price_incl_gst','gst_rate_pct',
                  'duration','duration_fmt','sessions','sessions_fmt','level',
                  'assessment_dur','skills_title','skills_code',
                  'store_name','store_phone','store_email',
                  'whatsapp','registration_url','generated_at'] as $k) {
            echo "  " . str_pad($k, 18) . ' = ' . substr((string) ($ctx[$k] ?? ''), 0, 120) . PHP_EOL;
        }
        echo "  " . str_pad('badges', 18) . ' = ' . implode(', ', $ctx['badges']) . PHP_EOL;
        echo "  " . str_pad('assessment_methods', 18) . ' = ' . implode(', ', $ctx['assessment_methods'] ?? []) . PHP_EOL;
        echo "  " . str_pad('venue_html len', 18) . ' = ' . strlen($ctx['venue_html'] ?? '') . PHP_EOL;
        echo "  funded_tiers = " . count($ctx['funded_tiers'] ?? []) . " tier(s)" . PHP_EOL;
        foreach (($ctx['funded_tiers'] ?? []) as $t) {
            echo "    " . $t['label'] . ' = ' . $t['value'] . '  (' . $t['hint'] . ')' . PHP_EOL;
        }
        echo "  description (" . strlen($ctx['description']) . " chars): " . substr($ctx['description'], 0, 200) . "...\n";
        echo "  outcomes (" . count($ctx['outcomes']) . " items)\n";
        echo "  outline_html: " . strlen($ctx['outline_html']) . " chars\n";
        echo "  trainer_html: " . strlen($ctx['trainer_html']) . " chars\n";

        // Skip the AI polish for the smoke test — too slow + needs network.
        // We just verify the PDF rendering pipeline works against raw data.
        $t1 = microtime(true);
        $url = $this->_renderBrochurePdf($product, $ctx);
        $tPdf = microtime(true) - $t1;

        echo "\ntimings: collect=" . number_format($tCtx, 2) . "s, render=" . number_format($tPdf, 2) . "s\n";
        echo "url: $url\n";

        // Brochure path is <SKU>-<CC>.pdf — derive CC from active_wid.
        $ccMap = array(1 => 'SG', 2 => 'MY', 3 => 'GH', 4 => 'NG', 5 => 'BT', 6 => 'IN');
        $cc       = $ccMap[(int) ($ctx['active_wid'] ?? 1)] ?? 'SG';
        $safeSku  = preg_replace('/[^A-Za-z0-9._-]/', '_', $product->getSku());
        $path     = Mage::getBaseDir('media') . '/courses/brochures/' . $safeSku . '-' . $cc . '.pdf';
        if (is_file($path)) {
            echo "file: $path (" . filesize($path) . " bytes)\n";
        } else {
            echo "WARN: expected file not found at $path\n";
        }
    }
};

try {
    $controller->run($product);
} catch (Throwable $e) {
    fwrite(STDERR, "FAILED: " . $e->getMessage() . "\n");
    fwrite(STDERR, $e->getTraceAsString() . "\n");
    exit(2);
}
