-- Add admin user siraj@tertiarycourses.com.gh (Ghana) with all 6 roles +
-- Administrators ACL group. Password: Welcome2026! (sha256("NW"+password):NW,
-- same hashing convention as migration 017). Idempotent.

INSERT IGNORE INTO admin_user
    (firstname, lastname, email, username, password, created, is_active)
VALUES
    ('Siraj', 'Ghana', 'siraj@tertiarycourses.com.gh',
     'siraj@tertiarycourses.com.gh',
     '0df0c8c38051fd31b37ec459d68e502998b321f43d2fa8b956c0fffa36566717:NW',
     NOW(), 1);

-- Assign Administrators ACL group (role_id=1).
DELETE ar FROM admin_role ar
INNER JOIN admin_user u ON u.user_id = ar.user_id
WHERE u.email = 'siraj@tertiarycourses.com.gh'
  AND ar.role_type = 'U';

INSERT INTO admin_role (parent_id, tree_level, sort_order, role_type, user_id, role_name)
SELECT 1, 2, 0, 'U', u.user_id, u.email
FROM admin_user u
WHERE u.email = 'siraj@tertiarycourses.com.gh';

-- Seed all 6 roles; admin = primary.
INSERT IGNORE INTO mmd_user_role_map (user_id, role_code, is_primary, created_at)
SELECT u.user_id, r.code, IF(r.code='admin', 1, 0), NOW()
FROM admin_user u
CROSS JOIN (
    SELECT 'learner' AS code UNION ALL
    SELECT 'trainer' UNION ALL
    SELECT 'developer' UNION ALL
    SELECT 'marketing' UNION ALL
    SELECT 'admin' UNION ALL
    SELECT 'training_provider'
) r
WHERE u.email = 'siraj@tertiarycourses.com.gh';

-- Enforce admin = primary.
UPDATE mmd_user_role_map m
INNER JOIN admin_user u ON u.user_id = m.user_id
SET m.is_primary = IF(m.role_code='admin', 1, 0)
WHERE u.email = 'siraj@tertiarycourses.com.gh';
