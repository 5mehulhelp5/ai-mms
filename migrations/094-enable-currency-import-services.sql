-- Currency import-service dropdown on /system_currency/ (Manage Currency
-- Rates → "Import Service") rendered empty because all three registered
-- services (currencyconverterapi, fixerio, webservicex) had
-- currency/<code>/active = 0 in core_config_data. The source model
-- Mage_Adminhtml_Model_System_Config_Source_Currency_Service skips any
-- service whose active === '0', so the <select> shipped with zero
-- <option> children.
--
-- Flip all three to active = 1 so admins can pick a rate source.
-- Idempotent: INSERT ... ON DUPLICATE KEY UPDATE.

INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES
    ('default', 0, 'currency/currencyconverterapi/active', '1'),
    ('default', 0, 'currency/fixerio/active',              '1'),
    ('default', 0, 'currency/webservicex/active',          '1')
ON DUPLICATE KEY UPDATE value = '1';
