-- Add a third recipient to the Singapore storefront Contact Us form.
-- The Contact Us recipient list is a comma-separated value (see 111);
-- core sends to every address in the list.
--
-- Singapore (websites scope, website_id=1, store "singapore"):
--   was: sales@tertiarycourses.com.sg, enquiry@tertiaryinfotech.com
--   now: sales@tertiarycourses.com.sg, enquiry@tertiaryinfotech.com, angch@tertiaryinfotech.com
--
-- Idempotent: only rewrites the known prior value, and the WHERE clause
-- excludes a row that already contains angch@tertiaryinfotech.com, so
-- re-running is a no-op.

UPDATE core_config_data
SET    value = 'sales@tertiarycourses.com.sg,enquiry@tertiaryinfotech.com,angch@tertiaryinfotech.com'
WHERE  scope = 'websites' AND scope_id = 1
   AND path  = 'contacts/email/recipient_email'
   AND value NOT LIKE '%angch@tertiaryinfotech.com%';
