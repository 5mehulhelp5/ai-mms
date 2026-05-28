<?php
// One-shot: re-run _uploadBrochureToDrive() against an existing local
// brochure PDF and dump the result. Local-dev verification only —
// confirms the service-account key + folder share are working.
require_once __DIR__ . '/../../app/Mage.php';
Mage::app('admin', 'store');
require_once __DIR__ . '/../../app/code/local/MMD/RoleManager/controllers/Adminhtml/CoursesaveController.php';

$sku = $argv[1] ?? 'M1872';
$cc  = $argv[2] ?? 'MY';
$file = Mage::getBaseDir('media') . '/courses/brochures/' . $sku . '-' . $cc . '.pdf';
if (!is_file($file)) {
    fwrite(STDERR, "Brochure file not found: $file\n");
    fwrite(STDERR, "Generate it first via smoke-test-brochure.php\n");
    exit(1);
}

$controller = new class extends MMD_RoleManager_Adminhtml_CoursesaveController {
    public function __construct() {}
    public function ping($file, $sku, $cc) {
        $filename = basename($file);
        return $this->_uploadBrochureToDrive($file, $filename, $cc);
    }
};

$result = $controller->ping($file, $sku, $cc);
echo "Drive upload result for $sku ($cc):\n";
echo "  uploaded:  " . ($result['uploaded'] ? 'YES' : 'no') . "\n";
echo "  skipped:   " . ($result['skipped']  ? 'yes' : 'NO') . "\n";
echo "  message:   " . ($result['message'] ?? '(none)') . "\n";
if (!empty($result['drive_url'])) echo "  drive_url: " . $result['drive_url'] . "\n";
if (!empty($result['folder']))    echo "  folder:    " . $result['folder'] . "\n";
