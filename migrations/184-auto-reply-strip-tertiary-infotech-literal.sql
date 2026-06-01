-- Follow-up to migration 169. The previous migration only swapped the
-- `{{var store.frontend_name}}` placeholder for `{{var store_brand}}`,
-- but on prod (and on any env where the lead auto-reply rows were ever
-- hand-edited via Admin -> Transactional Emails) the header / signature
-- / subject also carry the LITERAL string "Tertiary Infotech Academy".
-- That literal renders verbatim regardless of the receiving store, so a
-- Ghana lead sees "TERTIARY INFOTECH ACADEMY" in the email header instead
-- of "Tertiary Courses Ghana".
--
-- Replace the literal with the same {{var store_brand}} placeholder so
-- MMD_Leads_Helper_Data::getStoreBrandName($storeId) resolves the brand
-- from the store CODE (immune to core_config_data drift -- see
-- feedback_auto_reply_store_brand_var memory).
--
-- Idempotent: REPLACE() is a no-op once the substring is gone.

UPDATE core_email_template
   SET template_text    = REPLACE(template_text,    'Tertiary Infotech Academy', '{{var store_brand}}'),
       template_subject = REPLACE(template_subject, 'Tertiary Infotech Academy', '{{var store_brand}}'),
       modified_at      = NOW()
 WHERE orig_template_code IN ('mmd_leads_auto_reply', 'mmd_leads_auto_reply_sg', 'mmd_leads_course_reply');
