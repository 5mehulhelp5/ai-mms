<?php
/**
 * Apply the deletions identified by audit-unused-media.php.
 *
 * Reads the most recent var/log/audit-unused-media-*.csv, tars every file
 * into a backup at /tmp/media-delete-backup-<ts>.tar, then deletes them.
 *
 * SAFE BY DEFAULT — runs in dry-run mode (lists what it would do, doesn't
 * touch the filesystem). Pass --execute to actually delete.
 *
 * Usage (inside container):
 *   # 1. Refresh the audit CSV
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/maintenance/audit-unused-media.php
 *   # 2. Dry-run delete (no-op, prints what would happen)
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/maintenance/delete-unused-media.php
 *   # 3. Actually delete (creates a tar backup first)
 *   docker exec ai-mms-web-1 php /var/www/html/scripts/maintenance/delete-unused-media.php --execute
 *
 * Restore from backup if anything broke:
 *   docker exec ai-mms-web-1 sh -lc 'cd / && tar -xf /tmp/media-delete-backup-<ts>.tar'
 *
 * Behavior:
 *   - Skips any file not on disk (idempotent).
 *   - Skips any path outside media/ (defensive — the audit only ever writes
 *     media/* paths, but we double-check here so a bad CSV can't nuke /etc).
 *   - Removes empty leaf directories after the delete pass.
 *   - After --execute completes, recommends flushing var/cache + FPC and
 *     hitting the storefront homepage to confirm no broken images.
 */

$webroot = realpath(dirname(__DIR__, 2));
$execute = in_array('--execute', $argv ?? [], true);

// Find the most recent audit CSV.
$logDir  = $webroot . '/var/log';
$csvs    = glob($logDir . '/audit-unused-media-*.csv') ?: [];
if (!$csvs) {
    fwrite(STDERR, "No audit CSV found in {$logDir}. Run audit-unused-media.php first.\n");
    exit(1);
}
usort($csvs, function ($a, $b) { return filemtime($b) - filemtime($a); });
$csv = $csvs[0];
echo ($execute ? "[EXECUTE]" : "[DRY-RUN]") . " Reading " . basename($csv) . "\n";

// Parse CSV (header + columns: relative_path,size_bytes,size_human,last_modified,category,reason)
$fh = fopen($csv, 'r');
fgetcsv($fh); // skip header
$candidates = [];
while (($row = fgetcsv($fh)) !== false) {
    if (!isset($row[0])) continue;
    $rel = $row[0];
    // Defensive: only allow media/* paths.
    if (strpos($rel, 'media/') !== 0) continue;
    // Forbid any path traversal.
    if (strpos($rel, '..') !== false) continue;
    $abs = $webroot . '/' . $rel;
    if (!is_file($abs)) continue;
    $candidates[] = ['rel' => $rel, 'abs' => $abs, 'size' => (int)($row[1] ?? 0)];
}
fclose($fh);

$count = count($candidates);
$bytes = array_sum(array_column($candidates, 'size'));
echo "Candidates on disk: {$count} (" . round($bytes / 1024 / 1024, 1) . " MB)\n";

if ($count === 0) {
    echo "Nothing to do.\n";
    exit(0);
}

if (!$execute) {
    echo "Dry-run only. Pass --execute to delete.\n";
    echo "Sample paths (first 10):\n";
    foreach (array_slice($candidates, 0, 10) as $c) {
        echo "  - {$c['rel']}\n";
    }
    exit(0);
}

// --execute path: tar backup, then rm.
$tsTag  = date('Ymd-His');
$backup = "/tmp/media-delete-backup-{$tsTag}.tar";
$listF  = "/tmp/media-delete-list-{$tsTag}.txt";
file_put_contents($listF, implode("\n", array_column($candidates, 'rel')) . "\n");

echo "Creating tar backup at {$backup}...\n";
$tarCmd = sprintf(
    "cd %s && tar -cf %s -T %s 2>&1",
    escapeshellarg($webroot),
    escapeshellarg($backup),
    escapeshellarg($listF)
);
exec($tarCmd, $tarOut, $tarRc);
if ($tarRc !== 0) {
    fwrite(STDERR, "Tar backup failed (rc={$tarRc}). Aborting WITHOUT deleting.\n");
    fwrite(STDERR, implode("\n", array_slice($tarOut, 0, 20)) . "\n");
    exit(1);
}
echo "Backup: " . round(filesize($backup) / 1024 / 1024, 1) . " MB\n";

echo "Deleting files...\n";
$deleted = 0; $failed = 0;
foreach ($candidates as $c) {
    if (@unlink($c['abs'])) $deleted++; else $failed++;
}
echo "Deleted: {$deleted}  Failed: {$failed}\n";

// Remove empty leaf directories.
echo "Removing empty directories under media/...\n";
$rmDirs = 0;
$rii = new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator($webroot . '/media', FilesystemIterator::SKIP_DOTS),
    RecursiveIteratorIterator::CHILD_FIRST
);
foreach ($rii as $f) {
    if ($f->isDir()) {
        if (@rmdir($f->getPathname())) $rmDirs++;
    }
}
echo "Empty dirs removed: {$rmDirs}\n";

echo "\nDone.\n";
echo "Backup: {$backup}\n";
echo "Restore: cd / && tar -xf {$backup}\n";
echo "\nRecommended next steps:\n";
echo "  1. Flush Magento cache: rm -rf {$webroot}/var/cache {$webroot}/var/full_page_cache\n";
echo "  2. curl http://localhost/ and confirm HTTP 200 + no broken images\n";
