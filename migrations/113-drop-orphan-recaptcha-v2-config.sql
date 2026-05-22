-- Drop the orphaned Google reCAPTCHA v2 site/secret keys left behind after
-- the captcha module was swapped to Cloudflare Turnstile. The new module
-- reads from TURNSTILE_SITE_KEY / TURNSTILE_SECRET_KEY env vars instead,
-- so these config rows have no readers anymore.
--
-- Idempotent: deletes by exact path; running on a DB that's already clean
-- (e.g. fresh local) is a no-op.

DELETE FROM core_config_data
WHERE  path IN (
    'magentocaptcha/general/site_key',
    'magentocaptcha/general/secret_key',
    'magentocaptcha/general/enabled'
);
