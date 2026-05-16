-- Reset password for angch@tertiaryinfotech.com to "admin12345"
-- (sha256("NW"+password):NW, same hashing convention as migration 022).
-- Also ensures the account is active.
UPDATE admin_user
SET password = 'f795ce7f18f76861c0e5f5cc4471578febd940e4cef014a016f2c0c8e67d274c:NW',
    is_active = 1
WHERE email = 'angch@tertiaryinfotech.com';
