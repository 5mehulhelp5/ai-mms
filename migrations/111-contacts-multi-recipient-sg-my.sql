-- Send the storefront Contact Us form to TWO recipients per country instead
-- of one. The Mage_Contacts controller is rewritten in MMD_Email to split
-- the comma-separated list at runtime; here we just widen the config values.
--
-- Singapore  (websites scope, website_id=1, store "singapore"):
--   was: enquiry@tertiaryinfotech.com
--   now: sales@tertiarycourses.com.sg, enquiry@tertiaryinfotech.com
--
-- Malaysia  (stores scope, store_id=2 — overrides website-level value):
--   was: saeid@tertiarycourses.com.my
--   now: sales@tertiarycourses.com.my, saeid@tertiarycourses.com.my
--
-- Idempotent: UPDATE matches on scope/scope_id/path; running twice is a no-op.

UPDATE core_config_data
SET    value = 'sales@tertiarycourses.com.sg,enquiry@tertiaryinfotech.com'
WHERE  scope = 'websites' AND scope_id = 1
   AND path  = 'contacts/email/recipient_email';

UPDATE core_config_data
SET    value = 'sales@tertiarycourses.com.my,saeid@tertiarycourses.com.my'
WHERE  scope = 'stores' AND scope_id = 2
   AND path  = 'contacts/email/recipient_email';
