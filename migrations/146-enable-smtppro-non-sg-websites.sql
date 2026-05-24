-- Enable Aschroder SMTPPro at every non-SG country website scope.
--
-- Background: the Credentials panel in the admin lets ops fill SMTP
-- host/port/user/password per country (MY/GH/NG/BT/IN), but the
-- "Email Connection" toggle (`smtppro/general/option`) was easy to
-- miss. Without a website-scope row, those store views inherit from
-- the default scope (= "disabled"), so SMTPPro is off for MY/GH/NG/
-- BT/IN regardless of the host/user/password already being saved.
--
-- This migration writes `option = 'smtp'` at each country's website
-- scope so the per-website credentials actually take effect. Idempotent
-- via ON DUPLICATE KEY UPDATE so re-applying is a no-op.
--
-- Singapore (website_id = 1, code 'base') is intentionally untouched —
-- SG sends transactional mail via Gmail OAuth2, not SMTPPro.

INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES
    ('websites', 2, 'smtppro/general/option', 'smtp'),  -- Malaysia
    ('websites', 3, 'smtppro/general/option', 'smtp'),  -- Ghana
    ('websites', 4, 'smtppro/general/option', 'smtp'),  -- Nigeria
    ('websites', 5, 'smtppro/general/option', 'smtp'),  -- Bhutan
    ('websites', 6, 'smtppro/general/option', 'smtp')   -- India
ON DUPLICATE KEY UPDATE value = VALUES(value);
