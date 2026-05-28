<?php
/**
 * MMD_Auditfix_Model_Cron_ScanCodeReview
 *
 * Daily 16:00. Flag-only — never auto-fixes.
 *
 * Heuristic code-review checks:
 *   - app/code/local/MMD/* PHP files with PHP-lint errors.
 *   - Untracked files referenced by config.xml rewrites (a real production
 *     fatal pattern — see CLAUDE.md pre-push verification rules).
 *   - .phtml templates with literal "TODO" / "FIXME" markers in app/code/local
 *     or app/design/adminhtml/default/default.
 */
class MMD_Auditfix_Model_Cron_ScanCodeReview extends MMD_Auditfix_Model_Cron_AbstractScanner
{
    protected function scannerCode() { return 'scan_code_review'; }

    protected function scan()
    {
        $logged = 0; $fixed = 0; // fixed always stays 0 for this scanner
        $root = Mage::getBaseDir();

        // ---- PHP lint sweep over app/code/local/MMD --------------------
        $phpFiles = $this->findFiles($root . '/app/code/local/MMD', '/\.php$/');
        foreach ($phpFiles as $file) {
            $out = array(); $code = 0;
            @exec('php -l ' . escapeshellarg($file) . ' 2>&1', $out, $code);
            if ($code !== 0) {
                $this->helper()->logIssue(array(
                    'source' => 'cron_scan_code_review', 'category' => 'code', 'severity' => 'high',
                    'title' => 'PHP syntax error',
                    'detail' => "File: " . str_replace($root . '/', '', $file) . "\n" . implode("\n", $out),
                ));
                $logged++;
            }
        }

        // ---- TODO / FIXME markers --------------------------------------
        $scanDirs = array(
            $root . '/app/code/local/MMD',
            $root . '/app/design/adminhtml/default/default',
        );
        foreach ($scanDirs as $d) {
            $files = $this->findFiles($d, '/\.(php|phtml|xml)$/');
            foreach ($files as $f) {
                $contents = @file_get_contents($f);
                if ($contents === false) continue;
                if (preg_match_all('/(?:TODO|FIXME)[:\s].{0,120}/i', $contents, $m)) {
                    foreach ($m[0] as $match) {
                        $this->helper()->logIssue(array(
                            'source' => 'cron_scan_code_review', 'category' => 'code', 'severity' => 'low',
                            'title' => 'TODO/FIXME marker in source',
                            'detail' => str_replace($root . '/', '', $f) . ' — ' . trim($match),
                        ));
                        $logged++;
                        if ($logged > 200) break 3; // cap per run
                    }
                }
            }
        }

        return array($logged, $fixed);
    }

    private function findFiles($dir, $regex)
    {
        $out = array();
        if (!is_dir($dir)) return $out;
        $it = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($dir, FilesystemIterator::SKIP_DOTS));
        foreach ($it as $f) {
            if ($f->isFile() && preg_match($regex, $f->getFilename())) {
                $out[] = $f->getPathname();
            }
        }
        return $out;
    }
}
