-- Seed a default API key for the WSQ Schedule public API at default scope.
-- Replace via System → Configuration → MMD → Provider Manager → WSQ Schedule API Key
-- after first deploy. Idempotent: INSERT IGNORE skips on re-run.
INSERT IGNORE INTO core_config_data (scope, scope_id, path, value)
VALUES ('default', 0, 'courses/general/wsq_schedule_api_key', '3bbb09785284f80cca81877fc634ea97dd4459cada452ec1');
