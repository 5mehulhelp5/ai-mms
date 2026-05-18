-- 088-rebrand-sg-email-sender-name.sql
--
-- Singapore order emails currently display the sender as "Tertiary Courses
-- SG" / "Singapore, Tertiary Courses" because every trans_email/ident_*/name
-- value at the default scope (SG = website 1, store 1) is set to that.
-- Rebrand the sender name to "Tertiary Infotech Academy" to match the
-- corporate identity used elsewhere in the admin panel and the email
-- header logo. The from-address (sales@tertiarycourses.com.sg) stays put.
--
-- Other countries (MY/GH/NG/BT/IN) are not touched — their names are
-- scoped to their own websites and read correctly today.

UPDATE core_config_data
SET value = 'Tertiary Infotech Academy'
WHERE scope = 'default'
  AND scope_id = 0
  AND path IN (
    'trans_email/ident_general/name',
    'trans_email/ident_sales/name',
    'trans_email/ident_support/name',
    'trans_email/ident_custom1/name',
    'trans_email/ident_custom2/name'
  )
  AND value = 'Tertiary Courses SG';
