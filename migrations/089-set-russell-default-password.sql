-- Set Russell's password to "password123" (temporary default).
-- Russell MUST change this on first login: System → My Account → Password.
--
-- Hash format is sha256(salt . plaintext):salt, the same shape Magento
-- writes when the admin saves a password via the UI. Computed locally
-- via Mage::helper('core')->getHash('password123', 2). Different salts
-- across environments are fine — Magento only checks that the recomputed
-- hash with the stored salt matches.

UPDATE admin_user
SET password = 'ed22e8f12cf4c459bc3c449b3a492a149e98483ac875c82a6260a09cdfe05f23:j2'
WHERE email = 'greentan31@gmail.com';
