-- Remove orphan ACL rule references to admin/system/config/grecaptcha.
-- The reCAPTCHA admin config node no longer exists in this install, so any
-- admin_rule rows still pointing at it surface a yellow banner on the role
-- edit page: "The following role resources are no longer available in the
-- system: admin/system/config/grecaptcha. You can delete them by clicking here."
DELETE FROM admin_rule WHERE resource_id = 'admin/system/config/grecaptcha';
