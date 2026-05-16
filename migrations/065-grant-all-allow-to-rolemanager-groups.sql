-- Grant wildcard ACL to the RoleManager-introduced admin_role groups.
--
-- Problem: applyRoleAcl() in MMD/RoleManager/Helper/Data.php points the
-- admin user's admin_role.parent_id at one of six groups (Learner/Trainer/
-- Developer/Marketing/Admin/Super Admin). Super Admin was seeded with
-- 'all=allow' and Developer was seeded with 'admin/system=allow'
-- (migration 031), but Learner / Trainer / Marketing / Admin were created
-- with no admin_rule rows at all. Result: switching into any of those
-- four roles silently denies every controller, including Cache Management
-- (symptom reported repeatedly as "I click Cache Management and get
-- logged out" — actually the standard Magento "Access denied" page,
-- which the dark theme renders without the sidebar so it looks like a
-- logout).
--
-- CLAUDE.md states the current intent is "all roles temporarily inherit
-- the 'Administrators' ACL group (full access). Per-role ACL restrictions
-- are TODO." The functional restriction today comes from RoleManager's
-- _roleControllerMap() (predispatch allow-list), NOT from admin_rule —
-- so granting all=allow on these groups is consistent with how access
-- is actually enforced.
--
-- admin_rule has no natural unique key on (role_id, resource_id), so
-- idempotency is via DELETE-then-INSERT scoped to ('all', target groups).

DELETE ar FROM admin_rule ar
JOIN admin_role r ON r.role_id = ar.role_id
WHERE r.role_type = 'G'
  AND r.role_name IN ('Learner', 'Trainer', 'Developer', 'Marketing', 'Admin')
  AND ar.resource_id = 'all';

-- role_type must be 'G' here. Mage_Admin_Model_Resource_Acl::loadRules()
-- builds the Zend_Acl role identifier as $rule['role_type'].$rule['role_id'],
-- so a NULL role_type produces a phantom role '258' (instead of 'G258') that
-- no user inherits from, and the rule is silently ignored.
INSERT INTO admin_rule (role_id, resource_id, privileges, assert_id, role_type, permission)
SELECT r.role_id, 'all', NULL, 0, 'G', 'allow'
FROM admin_role r
WHERE r.role_type = 'G'
  AND r.role_name IN ('Learner', 'Trainer', 'Developer', 'Marketing', 'Admin');
