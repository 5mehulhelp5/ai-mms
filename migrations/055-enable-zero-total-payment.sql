-- Enable Magento's built-in "Free" payment method so that orders
-- with grand_total = 0 (e.g. fully funded SkillsFuture / Vendors@Gov
-- enrolments, 100%-discount promo codes) have a selectable payment
-- option at checkout. Without this, /checkout/onepage/ shows
-- "No Payment Methods" and the order cannot be placed.
--
-- The method's display title is already configured as
-- "Vendors@Gov e-Invoice" in core_config_data, so flipping `active`
-- to 1 at default scope is sufficient.

INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('default', 0, 'payment/free/active', '1')
ON DUPLICATE KEY UPDATE value = '1';
