-- Reset password for saeid@tertiarycourses.com.my to "Welcome2026!"
-- (sha256("NW"+password):NW, same hashing convention as migration 017).
-- Also ensures the account is active.
UPDATE admin_user
SET password = '0df0c8c38051fd31b37ec459d68e502998b321f43d2fa8b956c0fffa36566717:NW',
    is_active = 1
WHERE email = 'saeid@tertiarycourses.com.my';
