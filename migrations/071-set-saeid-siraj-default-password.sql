-- Set default password "password123" for the Malaysia (Saeid) and Ghana
-- (Siraj) country admins so they can sign in to their newly-wired-up
-- country store views. Same sha256(salt+password):salt convention as
-- migration 064 (salt = "NW"). Both accounts are explicitly re-activated
-- in case they were locked.
UPDATE admin_user
SET password   = '991d4e0e795da6258419572b4e92981671544d4c293771f6b1f464dbf689c198:NW',
    is_active  = 1,
    failures_num = 0,
    lock_expires = NULL
WHERE email IN (
    'saeid@tertiarycourses.com.my',
    'siraj@tertiarycourses.com.gh'
);
