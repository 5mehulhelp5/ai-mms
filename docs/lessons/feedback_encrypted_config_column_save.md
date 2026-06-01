---
name: encrypted-config-column-save
description: "Writing plaintext to a core_config_data row whose backend_model is adminhtml/system_config_backend_encrypted corrupts the value — getStoreConfig auto-decrypts the plaintext as ciphertext and returns garbage. Always call Mage::helper('core')->encrypt() before saveConfig."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: a60b9863-7c47-4b65-9b0b-349f105a7176
---

When a config path is declared in `system.xml` with
`<backend_model>adminhtml/system_config_backend_encrypted</backend_model>`
(e.g. `smtppro/general/smtp_password`, `mmd_marketing/api/*_key`), the
reader (`Mage::getStoreConfig()`) auto-decrypts the stored ciphertext on
the way out. Writing raw plaintext via `Mage::getConfig()->saveConfig()`
bypasses the backend model — the plaintext goes to the DB literally,
then the next read attempts to decrypt it as ciphertext and returns
garbage (often 6–14 chars of high-bytes). Downstream code that uses the
value (SMTP auth, API client init) then fails with credential errors.

**Why:** SG fallback SMTP broke with `5.7.8 BadCredentials` on both
localhost and prod. The Gmail App Password was correct (raw socket
`AUTH LOGIN` returned `235 Accepted` outside Magento), but the value
read by `Mage::getStoreConfig('smtppro/general/smtp_password', $sid)`
came back as 12–14 garbled bytes — the previous save had written
plaintext into the encrypted column. Same symptom would apply to any
encrypted-backed config path written by custom code that forgets to
encrypt first.

**How to apply:** Any time you write to a config path with the
encrypted backend model from a controller, observer, CLI script, or
migration helper:

```php
$enc = Mage::helper('core')->encrypt($plaintext);
Mage::getModel('core/config')->saveConfig($path, $enc, $scope, $scopeId);
Mage::app()->getCacheInstance()->cleanType('config');
```

The admin **System Configuration** UI handles this for you via the
backend model — only direct `saveConfig` calls bypass it. The
`savecredsAction` in
`app/code/local/MMD/Email/controllers/Adminhtml/MaildiagnoseController.php`
(line ~161) is the canonical correct pattern in this repo. The
recovery one-liner for a corrupted row is the same shape — see
`scripts/maintenance/ensure-smtp-fallback-passwords.php` which reads
the App Password from env `SMTPPRO_SG_FALLBACK_PASSWORD` and re-writes
it encrypted on container start (idempotent — no-op if the decrypted
value already matches).

Diagnostic: if `getStoreConfig` returns a string of unexpected length
or non-printable characters for a known-encrypted path, that row is
corrupted, not the consumer code. Verify by comparing `strlen()` of
the read value against the known plaintext length.

Related: [[funding-badges-via-tags]] for another case where Magento's
"helpful" auto-loading hides the real storage path. [[apply-php-sql-splitter]]
for migration-safety pitfalls when the same value lands in SQL.
