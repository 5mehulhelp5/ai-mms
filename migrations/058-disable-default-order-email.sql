-- The MMD_Email module now sends a course-registration confirmation
-- on every sales_order_place_after. Without this migration, Magento's
-- standard order-confirmation email also fires from the OnePage /
-- admin order-create flow, so the customer would receive two emails
-- per registration (the generic one + ours).
--
-- Disable the standard sales/order new-order email at the default
-- scope. Re-enable from System > Configuration > Sales > Sales Emails
-- > Order > "Enabled = Yes" if you ever want it back.
--
-- Idempotent: ON DUPLICATE KEY UPDATE keeps re-runs safe.

INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('default', 0, 'sales_email/order/enabled', '0')
ON DUPLICATE KEY UPDATE value = '0';

-- Order-update emails (status changes) and invoice emails are left
-- alone — those still fire from Magento's default sales emails block.
