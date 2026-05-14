-- Ensure saeid@tertiarycourses.com.my has Administrators ACL group + all 6
-- role_codes in mmd_user_role_map (admin = primary). Migration 016 already
-- backfills role_codes for all users, but this migration also enforces the
-- ACL group assignment and primary role, and is safe to re-run.
-- No-op if the user doesn't exist on the target DB.

-- Administrators ACL group (role_id=1). Drop any existing user-role row first
-- so re-runs converge to exactly one Administrators assignment.
DELETE ar FROM admin_role ar
INNER JOIN admin_user u ON u.user_id = ar.user_id
WHERE u.email = 'saeid@tertiarycourses.com.my'
  AND ar.role_type = 'U';

INSERT INTO admin_role (parent_id, tree_level, sort_order, role_type, user_id, role_name)
SELECT 1, 2, 0, 'U', u.user_id, u.email
FROM admin_user u
WHERE u.email = 'saeid@tertiarycourses.com.my';

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
WHERE u.email = 'saeid@tertiarycourses.com.my';

-- Enforce admin as primary (in case row pre-existed with is_primary=0).
UPDATE mmd_user_role_map m
INNER JOIN admin_user u ON u.user_id = m.user_id
SET m.is_primary = IF(m.role_code='admin', 1, 0)
WHERE u.email = 'saeid@tertiarycourses.com.my';

-- Make sure account is active.
UPDATE admin_user
SET is_active = 1
WHERE email = 'saeid@tertiarycourses.com.my';
