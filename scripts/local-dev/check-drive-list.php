<?php
// List everything the SA can see — both the parent folder's children
// and the SA's accessible files top-level. Tells us if the parent ID
// is right + whether the country subfolders are findable.
require_once __DIR__ . '/../../vendor/autoload.php';

$keyFile = __DIR__ . '/../../app/etc/google-drive-key.json';
$parentId = '16S5PAreCxFQ7Kcbu7eE6djMfhNq7wz2B';

$client = new \Google\Client();
$client->setAuthConfig($keyFile);
$client->setScopes(array(\Google\Service\Drive::DRIVE));
$drive = new \Google\Service\Drive($client);

echo "=== ABOUT (who am I?) ===\n";
$about = $drive->about->get(array('fields' => 'user,storageQuota'));
echo "SA email: " . $about->getUser()->getEmailAddress() . "\n";

echo "\n=== TOP-LEVEL FILES THE SA HAS ACCESS TO ===\n";
$top = $drive->files->listFiles(array(
    'fields' => 'files(id, name, mimeType, parents, shared)',
    'pageSize' => 25,
    'supportsAllDrives' => true,
    'includeItemsFromAllDrives' => true,
    'corpora' => 'allDrives',
));
foreach ($top->getFiles() as $f) {
    echo sprintf("  %s | %-40s | %s\n",
        $f->getId(),
        substr($f->getName(), 0, 40),
        substr($f->getMimeType(), 0, 35)
    );
}
if (count($top->getFiles()) === 0) echo "  (none)\n";

echo "\n=== CHILDREN OF PARENT '$parentId' ===\n";
try {
    $resp = $drive->files->listFiles(array(
        'q' => "'$parentId' in parents and trashed = false",
        'fields' => 'files(id, name, mimeType)',
        'pageSize' => 25,
        'supportsAllDrives' => true,
        'includeItemsFromAllDrives' => true,
    ));
    foreach ($resp->getFiles() as $f) {
        echo sprintf("  %s | %s | %s\n", $f->getId(), $f->getName(), $f->getMimeType());
    }
    if (count($resp->getFiles()) === 0) echo "  (none)\n";
} catch (Throwable $e) {
    echo "ERROR querying parent: " . $e->getMessage() . "\n";
}

echo "\n=== CAN WE GET PARENT METADATA? ===\n";
try {
    $parent = $drive->files->get($parentId, array('fields' => 'id,name,mimeType,driveId', 'supportsAllDrives' => true));
    echo "Parent name: " . $parent->getName() . "\n";
    echo "Mime type:   " . $parent->getMimeType() . "\n";
    echo "Drive ID:    " . ($parent->getDriveId() ?: '(My Drive)') . "\n";
} catch (Throwable $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
