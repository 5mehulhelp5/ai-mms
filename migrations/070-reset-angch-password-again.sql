-- Re-reset angch@tertiaryinfotech.com password to "admin12345" because the
-- account was changed via the admin UI between deploys. Migration 069 is
-- already marked applied in schema_migrations, so we need a new file to
-- force the SQL to run again on production.
UPDATE admin_user
SET password  = 'f795ce7f18f76861c0e5f5cc4471578febd940e4cef014a016f2c0c8e67d274c:NW',
    is_active = 1
WHERE email = 'angch@tertiaryinfotech.com';
