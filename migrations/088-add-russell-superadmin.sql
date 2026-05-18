-- Provision Russell (greentan31@gmail.com) as an admin user and grant
-- all six roles. training_provider is the primary role (the "Super
-- Admin" ACL group), so a fresh login lands directly in the full-access
-- workspace; the other five appear in the role-switcher menu.
--
-- Password is set to an unusable sentinel so the user must reset via
-- "Forgot Password" before first login. We keep is_active=1 so the
-- reset flow works.
--
-- Idempotent: INSERT IGNORE on admin_user (UNIQUE on username);
-- INSERT IGNORE on mmd_user_role_map (UNQ_USER_ROLE on user_id+role_code).

INSERT IGNORE INTO admin_user
    (firstname, lastname, email, username, password, is_active, created)
VALUES
    ('Russell', '', 'greentan31@gmail.com', 'greentan31@gmail.com',
     'invalid:reset_required', 1, NOW());

-- Assign all six roles. training_provider = Super Admin, marked primary.
INSERT IGNORE INTO mmd_user_role_map (user_id, role_code, is_primary, created_at)
SELECT u.user_id, 'learner', 0, NOW()
FROM admin_user u WHERE u.email = 'greentan31@gmail.com';

INSERT IGNORE INTO mmd_user_role_map (user_id, role_code, is_primary, created_at)
SELECT u.user_id, 'trainer', 0, NOW()
FROM admin_user u WHERE u.email = 'greentan31@gmail.com';

INSERT IGNORE INTO mmd_user_role_map (user_id, role_code, is_primary, created_at)
SELECT u.user_id, 'developer', 0, NOW()
FROM admin_user u WHERE u.email = 'greentan31@gmail.com';

INSERT IGNORE INTO mmd_user_role_map (user_id, role_code, is_primary, created_at)
SELECT u.user_id, 'marketing', 0, NOW()
FROM admin_user u WHERE u.email = 'greentan31@gmail.com';

INSERT IGNORE INTO mmd_user_role_map (user_id, role_code, is_primary, created_at)
SELECT u.user_id, 'admin', 0, NOW()
FROM admin_user u WHERE u.email = 'greentan31@gmail.com';

INSERT IGNORE INTO mmd_user_role_map (user_id, role_code, is_primary, created_at)
SELECT u.user_id, 'training_provider', 1, NOW()
FROM admin_user u WHERE u.email = 'greentan31@gmail.com';
