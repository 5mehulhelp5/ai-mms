-- 089-rebrand-all-email-sender-names.sql
--
-- Rebrand the email sender display name across every website (SG, MY, GH,
-- NG, BT, IN, Infotech) to "Tertiary Infotech Academy". Previously each
-- non-SG website carried its own scoped override ("Tertiary Courses
-- Malaysia", "Tertiary Courses Ghana", etc); the SG default was already
-- rebranded in migration 088.
--
-- Every trans_email/ident_*/name row at every scope (default / websites /
-- stores) is normalised here. From-addresses are untouched so each site
-- continues to send from its country mailbox.

UPDATE core_config_data
SET value = 'Tertiary Infotech Academy'
WHERE path IN (
    'trans_email/ident_general/name',
    'trans_email/ident_sales/name',
    'trans_email/ident_support/name',
    'trans_email/ident_custom1/name',
    'trans_email/ident_custom2/name'
);
