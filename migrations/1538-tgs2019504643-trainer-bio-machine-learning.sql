-- 1538: TGS-2019504643 trainer bios -- retarget the course-teaching sentences
--
-- Follow-up to 1537 (retitle to "WSQ - AI Vibe Coding for Machine Learning").
-- 1537 is already in the ledger, so the fix ships as its own file.
--
-- The post-apply RENDERED-page grep caught two `trainerprofile` leaks that the
-- pre-write EAV sweep surfaced but 1537 did not edit: two bios still claim the
-- trainer teaches "AI vibe coding for data analytics" / "Python and data
-- analytics" on THIS course. Those are course-teaching claims, so they
-- retarget with the course.
--
-- Deliberately NOT touched: every other mention of analytics/data science in
-- this attribute is CAREER HISTORY or a genuine credential (Head of Data
-- Science, SAP/IMDA delivery history, "data science bootcamps and corporate
-- workshops"). Rewriting those would falsify a bio -- per the rename
-- checklist, only course-teaching claims move.
--
-- Targeted REPLACE() on the exact inner sentences so the surrounding
-- &ndash;/&nbsp; entities and the WYSIWYG markup survive byte-for-byte. Two
-- separate REPLACEs (not a wholesale rewrite) for the same reason.
--
-- Idempotent: REPLACE() of an already-replaced string is a no-op, and the
-- guard skips the row once neither needle is present.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2019504643' LIMIT 1);
SET @a_tp := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='trainerprofile'
   AND entity_type_id=(SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product'));

UPDATE catalog_product_entity_text
   SET value = REPLACE(
         REPLACE(value,
           'His teaching in Python and data analytics introduces learners to AI coding assistants through practical exercises in data preparation, reporting, and application to business contexts.',
           'His teaching in Python and machine learning introduces learners to AI coding assistants through practical exercises in data preparation, model building, and application to business contexts.'),
         'He has trained professionals in applying AI vibe coding for data analytics, ensuring they understand not only the tools but also data preparation, quality checks, and visual reporting.',
         'He has trained professionals in applying AI vibe coding for machine learning, ensuring they understand not only the tools but also data preparation, model evaluation, and result interpretation.')
 WHERE entity_id = @e AND attribute_id = @a_tp
   AND @e IS NOT NULL AND @a_tp IS NOT NULL;
