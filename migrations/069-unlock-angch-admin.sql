-- Re-reset angch@tertiaryinfotech.com password to "admin12345" AND clear
-- the lockout state. After repeated failed sign-ins OpenMage sets
-- failures_num/first_failure/lock_expires on admin_user, which keeps the
-- "did not sign in correctly or your account is temporarily disabled"
-- message even when the password is now correct.
UPDATE admin_user
SET password       = 'f795ce7f18f76861c0e5f5cc4471578febd940e4cef014a016f2c0c8e67d274c:NW',
    is_active      = 1,
    failures_num   = 0,
    first_failure  = NULL,
    lock_expires   = NULL
WHERE email = 'angch@tertiaryinfotech.com';
