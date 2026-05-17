-- Set default password "password123" for the Malaysia (Saeid) and Ghana
-- (Siraj) country admins so they can sign in to their newly-wired-up
-- country store views. Same sha256(salt+password):salt convention as
-- migration 064 (salt = "NW"). Re-activate the accounts too.
--
-- The original also set failures_num = 0 / lock_expires = NULL, but
-- those Magento admin-lockout columns don't exist on this DB (the
-- prod backup never received that patch), which fataled the migration
-- runner and abort-looped the container. The runner (apply.php) also
-- can't execute a PREPARE/EXECUTE column-existence guard (its PDO
-- connection is unbuffered). Since the core intent is just "let these
-- admins log in", drop the optional lockout-clear entirely:
-- is_active = 1 already restores a deactivated account, and these
-- accounts are not brute-force-locked. Works on every DB regardless
-- of whether the lockout columns are present.

UPDATE admin_user
SET password  = '991d4e0e795da6258419572b4e92981671544d4c293771f6b1f464dbf689c198:NW',
    is_active = 1
WHERE email IN (
    'saeid@tertiarycourses.com.my',
    'siraj@tertiarycourses.com.gh'
);
