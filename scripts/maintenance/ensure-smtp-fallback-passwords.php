<?php
/**
 * Idempotently sync SMTPPro fallback passwords from environment variables
 * into core_config_data, encrypted via Mage::helper('core')->encrypt() so
 * SMTPPro's runtime auto-decrypt round-trip works.
 *
 * Why this exists: the admin "Credentials" form (MaildiagnoseController
 * savecredsAction) correctly encrypts on save, but historically the SG
 * fallback row was written either via legacy code or a partial form
 * submit (password field left as masked dots) — leaving a corrupted
 * ciphertext in the DB. Result on send: Gmail rejects with 5.7.8
 * BadCredentials even though the App Password is right.
 *
 * The fix-the-DB-on-localhost path is `Mage::helper('core')->encrypt()
 * + saveConfig`. To mirror that to production without committing the
 * App Password to git, we read it from env at container start.
 *
 * Env vars consulted (all optional; missing ones are skipped):
 *   SMTPPRO_SG_FALLBACK_PASSWORD  → smtppro/general/smtp_password @ website=1
 *
 * Add more sites by extending $sites below if MY/GH/etc. ever need the
 * same automation. For now only SG needs it (other countries are configured
 * via the admin UI without this corruption history).
 *
 * Idempotency: we decrypt the current value and only re-write if it differs.
 * Safe to run on every container start.
 */
require_once dirname(__DIR__, 2) . '/app/Mage.php';
Mage::app('admin');

$sites = [
    [
        'label'    => 'SG fallback',
        'website'  => 1,
        'env'      => 'SMTPPRO_SG_FALLBACK_PASSWORD',
        'path'     => 'smtppro/general/smtp_password',
    ],
];

foreach ($sites as $s) {
    $want = (string) getenv($s['env']);
    if ($want === '') {
        echo "[smtp-fallback] {$s['env']} not set, skipping {$s['label']}\n";
        continue;
    }
    // Gmail App Passwords are commonly displayed in groups of 4 with spaces;
    // Google accepts either form. Normalize to no-spaces so a future env edit
    // with or without spaces doesn't cause a needless re-write loop.
    $want = preg_replace('/\s+/', '', $want);

    try {
        $store = Mage::app()->getWebsite((int) $s['website'])->getDefaultStore();
        $sid   = (int) $store->getId();
        $current = (string) Mage::getStoreConfig($s['path'], $sid);

        if ($current === $want) {
            echo "[smtp-fallback] {$s['label']}: already in sync\n";
            continue;
        }

        $enc = Mage::helper('core')->encrypt($want);
        Mage::getModel('core/config')->saveConfig(
            $s['path'],
            $enc,
            'websites',
            (int) $s['website']
        );
        echo "[smtp-fallback] {$s['label']}: updated (len " . strlen($want) . ")\n";
    } catch (Exception $e) {
        // Never fatal — we don't want a misconfigured env var to take down the
        // container. SMTP failure is recoverable via admin UI; container down isn't.
        echo "[smtp-fallback] {$s['label']}: WARN " . $e->getMessage() . "\n";
    }
}

Mage::app()->getCacheInstance()->cleanType('config');
