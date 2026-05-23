-- Remove orphaned Magecomp_Recaptcha (Google reCAPTCHA) config rows.
-- The Magecomp_Recaptcha module + its templates were deleted; Cloudflare
-- Turnstile (MMD_MagentoCaptcha) is now the sole spam-protection layer.
-- These rows are harmless without the module but pollute System Config.

DELETE FROM core_config_data WHERE path LIKE 'grecaptcha/%';
