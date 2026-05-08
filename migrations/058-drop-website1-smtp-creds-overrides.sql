-- Follow-up to migration 057-fix-website1-smtp-config.sql.
--
-- The earlier migration only dropped the website-1 overrides for
-- port / ssl / auth, on the assumption that username and password
-- still matched at default scope. They don't — website 1 still has
-- its own copy of smtp_username (no-reply@tertiarycourses.com.sg)
-- and smtp_password, so anything saved at default scope via the
-- admin form gets shadowed.
--
-- Drop those website-1 overrides too. After this, whatever the admin
-- enters at "default config" scope under System > Configuration >
-- SMTPPro / SMTP becomes the effective credential set for the SG
-- storefront (website 1), which is what we want now that we're
-- switching the SMTP login from no-reply@... to sales@...
--
-- Other websites (2..6) keep their own usernames/passwords because
-- each one points at a different mail host (.my, .gh, .ng, .bt, .in)
-- with its own credentials.

DELETE FROM core_config_data
WHERE scope = 'websites'
  AND scope_id = 1
  AND path IN (
      'smtppro/general/smtp_username',
      'smtppro/general/smtp_password'
  );
