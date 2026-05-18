-- Russell logged in but showed no roles — migration 088's role-map
-- INSERTs may have no-op'd if prod's admin_user.email differed in case
-- or whitespace from 'greentan31@gmail.com'. Re-assert all six roles
-- joining on username (set to the email by the role-manager flow and
-- by migration 088 itself). INSERT IGNORE → idempotent.

INSERT IGNORE INTO mmd_user_role_map (user_id, role_code, is_primary, created_at)
SELECT u.user_id, 'learner', 0, NOW()
FROM admin_user u WHERE u.username = 'greentan31@gmail.com';

INSERT IGNORE INTO mmd_user_role_map (user_id, role_code, is_primary, created_at)
SELECT u.user_id, 'trainer', 0, NOW()
FROM admin_user u WHERE u.username = 'greentan31@gmail.com';

INSERT IGNORE INTO mmd_user_role_map (user_id, role_code, is_primary, created_at)
SELECT u.user_id, 'developer', 0, NOW()
FROM admin_user u WHERE u.username = 'greentan31@gmail.com';

INSERT IGNORE INTO mmd_user_role_map (user_id, role_code, is_primary, created_at)
SELECT u.user_id, 'marketing', 0, NOW()
FROM admin_user u WHERE u.username = 'greentan31@gmail.com';

INSERT IGNORE INTO mmd_user_role_map (user_id, role_code, is_primary, created_at)
SELECT u.user_id, 'admin', 0, NOW()
FROM admin_user u WHERE u.username = 'greentan31@gmail.com';

INSERT IGNORE INTO mmd_user_role_map (user_id, role_code, is_primary, created_at)
SELECT u.user_id, 'training_provider', 1, NOW()
FROM admin_user u WHERE u.username = 'greentan31@gmail.com';
