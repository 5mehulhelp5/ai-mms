-- Stop relying on Aschroder_SMTPPro for transactional email transport.
--
-- MMD_Email now installs its own Gmail OAuth2 transport as Zend_Mail's
-- default at `controller_front_init_before`. Every Magento email path
-- (orders, invoices, shipments, password resets, newsletter, contact
-- form, …) ends in $mail->send() with no transport argument, which
-- picks up that default. SMTPPro's role — opening a TCP socket to a
-- legacy SMTP relay that isn't reachable from the Coolify container
-- for non-SG stores — disappears.
--
-- Aschroder_SMTPPro_Helper_Data::isEnabled() returns false when
-- `smtppro/general/option` equals 'disabled'. Both rewritten classes
-- (Email and Email_Template) early-return parent::send() in that case,
-- so they become transparent pass-throughs to Magento core and never
-- dispatch their `aschroder_smtppro_*_before_send` events.
--
-- Idempotent. Reversible with one UPDATE if we ever need to re-enable.

-- 1. Disable at default scope.
INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('default', 0, 'smtppro/general/option', 'disabled')
ON DUPLICATE KEY UPDATE value = 'disabled';

-- 2. Strip any website / store overrides so no scope can re-enable it.
DELETE FROM core_config_data
WHERE path = 'smtppro/general/option'
  AND scope IN ('websites', 'stores');
