-- Switch every store from MMD_Email's custom "Registration Confirmed"
-- template back to Magento's standard sales/order new-order email so
-- the per-store transactional email templates (Calendar Invite /
-- HRD Corp / Company Invoice / Cancellation / Direction sections,
-- configured in System > Transactional Emails for each country) fire
-- on order placement instead.
--
-- Migration 058 disabled sales_email/order/enabled at the default
-- scope so MMD_Email could own the confirmation flow globally. We
-- now unwind that decision for every country (SG/MY/NG/GH/BT/IN):
--
--   1. Re-enable sales_email/order at the default scope so OnePage
--      and admin order-create trigger the standard order confirmation
--      email for every website.
--   2. Disable mmd_email/course_registration at the same scope so the
--      sales_order_place_after observer no longer fires and the
--      customer doesn't receive both emails.
--   3. Strip any website / store overrides on either path so the new
--      default applies uniformly.

-- 1. Re-enable Magento's default order confirmation email everywhere.
INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('default', 0, 'sales_email/order/enabled', '1')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- 2. Turn off MMD_Email's custom course-registration confirmation.
INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('default', 0, 'mmd_email/course_registration/enabled', '0')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- 3. Remove any website / store-level overrides so all scopes inherit
--    the unified default values set above.
DELETE FROM core_config_data
WHERE path IN ('sales_email/order/enabled', 'mmd_email/course_registration/enabled')
  AND scope IN ('websites', 'stores');
