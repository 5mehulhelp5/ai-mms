-- 090-gmail-oauth-sender-name-override.sql
--
-- Seed the new Gmail OAuth/SMTP "Override Sender Name" setting introduced
-- in MagePal_GmailSmtpApp/etc/system.xml with "Tertiary Infotech Academy"
-- at the default scope. Per-template identity names (trans_email/ident_*/
-- name) become irrelevant for outbound mail — every email sent through
-- the Gmail SMTP transport, regardless of website, now carries this
-- single display name on the From: header.
--
-- Admin: System -> Configuration -> Advanced -> System ->
--        "Gmail/Google Apps SMPT Pro" -> Override Sender Name

INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('default', 0, 'system/magepal_gmailsmtpapp/sender_name', 'Tertiary Infotech Academy')
ON DUPLICATE KEY UPDATE value = VALUES(value);
