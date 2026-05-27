-- Replace the hardcoded brand label in the two lead auto-reply transactional
-- email rows with a new {{var store_brand}} placeholder that the helper
-- (MMD_Leads_Helper_Data::sendAutoReply) injects per-store. This avoids the
-- recurring "TERTIARY INFOTECH ACADEMY" header bug: the previous template
-- read {{var store.frontend_name}}, which silently falls back to the default
-- scope when general/store_information/name is not overridden at the store
-- scope (see feedback_auto_reply_per_store memory). The new variable is
-- computed in PHP from the store CODE so the brand is always correct for
-- the receiving country (Singapore / Malaysia / Ghana / Nigeria / Bhutan /
-- India), regardless of core_config_data state on the target environment.
--
-- Idempotent: REPLACE() is a no-op once the substring is gone, so re-runs
-- against an already-migrated DB do nothing.

UPDATE core_email_template SET template_text = REPLACE(template_text, '{{var store.frontend_name}}', '{{var store_brand}}'), template_subject = REPLACE(template_subject, '{{var store.frontend_name}}', '{{var store_brand}}'), modified_at = NOW() WHERE orig_template_code = 'mmd_leads_auto_reply';

UPDATE core_email_template SET template_text = REPLACE(template_text, 'Tertiary Courses Singapore', '{{var store_brand}}'), template_subject = REPLACE(template_subject, 'Tertiary Courses Singapore', '{{var store_brand}}'), modified_at = NOW() WHERE orig_template_code = 'mmd_leads_auto_reply_sg';
