-- Seed the SG Funding Discount values in Company Settings.
-- Drives the storefront's "Funding Eligibility" custom-option radios
-- via window.MMD_SG_FUNDING. Editable later from
-- Dashboard → Company Setting → SG Funding Discounts.
--
-- Idempotent: INSERT … ON DUPLICATE KEY UPDATE so re-running the
-- migration won't clobber any admin edits made after seed.

INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('default', 0, 'mmd_company/sg_funding/above_40', '70')
ON DUPLICATE KEY UPDATE value = value;

INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('default', 0, 'mmd_company/sg_funding/below_40', '50')
ON DUPLICATE KEY UPDATE value = value;

INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('default', 0, 'mmd_company/sg_funding/pr', '50')
ON DUPLICATE KEY UPDATE value = value;

INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('default', 0, 'mmd_company/sg_funding/non_sg', '0')
ON DUPLICATE KEY UPDATE value = value;

INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('default', 0, 'mmd_company/sg_funding/sme', '70')
ON DUPLICATE KEY UPDATE value = value;
