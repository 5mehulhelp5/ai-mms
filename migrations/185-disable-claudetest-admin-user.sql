-- Disable the claudetest@local.test admin user.
--
-- This row was created on 2026-05-28 17:36 (~24h before the May 29 webshell
-- drop), has no admin_role assignment, no mmd_user_role_map entry, lognum=0,
-- logdate=NULL. The "claudetest" name pattern strongly suggests it was created
-- by a Claude Code dev session and never cleaned up. It's harmless today
-- (zero ACL, never used) but it's an inactive credentials row that doesn't
-- belong on a production admin user list.
--
-- We set is_active=0 instead of DELETE so the row stays for audit purposes
-- (records when it was created, and if it ever logged in afterwards). Safe
-- to re-run: targets the row by email only.

UPDATE admin_user
SET is_active = 0
WHERE email = 'claudetest@local.test'
  AND lognum = 0
  AND logdate IS NULL;
