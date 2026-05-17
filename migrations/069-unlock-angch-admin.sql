-- Re-reset angch@tertiaryinfotech.com password to "admin12345" and ensure
-- the account is active. This build has no admin lockout columns
-- (failures_num / lock_expires / first_failure don't exist on admin_user),
-- so the "temporarily disabled" message in the login UI is just OpenMage's
-- generic catch-all wording for any auth failure — there's no lockout
-- state to clear.
UPDATE admin_user
SET password  = 'f795ce7f18f76861c0e5f5cc4471578febd940e4cef014a016f2c0c8e67d274c:NW',
    is_active = 1
WHERE email = 'angch@tertiaryinfotech.com';
