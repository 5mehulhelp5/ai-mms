-- Assessment Methods product attribute.
--
-- Phase 1 of the Assessment-card initiative on the product page Course Details
-- tab. WSQ courses (SKU prefix TGS-) currently bury their assessment methods
-- inline at the bottom of `description`, after a `<h3>Final Assessment</h3>`
-- heading. This migration adds the structured EAV attribute that will replace
-- that inline list so admins can manage assessment methods as a multi-select.
--
-- This migration only creates schema. The one-time backfill — parse the
-- inline list out of `description`, populate the new attribute, then strip
-- the inline list from `description` — lives in
-- scripts/maintenance/backfill-assessment-methods.php and must be run once
-- on each environment after this migration applies.
--
-- Re-runnable: every INSERT is guarded; running twice is a no-op.

-- ---------------------------------------------------------------------------
-- 1) Create the multiselect attribute itself.
-- ---------------------------------------------------------------------------
-- Mirror the existing `trainers` multiselect on this entity type:
--   backend_type=text, frontend_input=multiselect,
--   backend_model=eav/entity_attribute_backend_array.
-- The backend_array model handles array<->CSV serialization on save.
SET @existing_assess := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='assessment_methods' LIMIT 1);
INSERT INTO eav_attribute (entity_type_id, attribute_code, backend_type, backend_model, source_model, frontend_input, frontend_label, is_required, is_user_defined, is_unique, note)
SELECT 4, 'assessment_methods', 'text', 'eav/entity_attribute_backend_array', 'eav/entity_attribute_source_table', 'multiselect', 'Assessment Methods', 0, 1, 0,
       'Multi-select of WSQ assessment methods displayed on the product page Assessment card. WSQ courses (TGS- SKU) default to Written Exam + Practical Exam if left empty.'
FROM DUAL WHERE @existing_assess IS NULL;
SET @aid_assess := IFNULL(@existing_assess, LAST_INSERT_ID());

-- Ensure source_model is populated for existing rows (re-runs / earlier draft).
UPDATE eav_attribute SET source_model='eav/entity_attribute_source_table'
WHERE attribute_id=@aid_assess AND (source_model IS NULL OR source_model='');

INSERT IGNORE INTO catalog_eav_attribute (attribute_id, is_global, is_visible, used_in_product_listing)
VALUES (@aid_assess, 1, 1, 0);

-- ---------------------------------------------------------------------------
-- 2) Seed the 8 canonical option values.
-- ---------------------------------------------------------------------------
-- Each option row is guarded on (attribute_id, value) so re-running is safe.

-- Option: Written Exam
SET @opt := (SELECT eao.option_id FROM eav_attribute_option eao JOIN eav_attribute_option_value eaov ON eaov.option_id=eao.option_id WHERE eao.attribute_id=@aid_assess AND eaov.store_id=0 AND eaov.value='Written Exam' LIMIT 1);
INSERT INTO eav_attribute_option (attribute_id, sort_order) SELECT @aid_assess, 10 FROM DUAL WHERE @opt IS NULL;
SET @opt := IFNULL(@opt, LAST_INSERT_ID());
INSERT IGNORE INTO eav_attribute_option_value (option_id, store_id, value) VALUES (@opt, 0, 'Written Exam');

-- Option: Practical Exam
SET @opt := (SELECT eao.option_id FROM eav_attribute_option eao JOIN eav_attribute_option_value eaov ON eaov.option_id=eao.option_id WHERE eao.attribute_id=@aid_assess AND eaov.store_id=0 AND eaov.value='Practical Exam' LIMIT 1);
INSERT INTO eav_attribute_option (attribute_id, sort_order) SELECT @aid_assess, 20 FROM DUAL WHERE @opt IS NULL;
SET @opt := IFNULL(@opt, LAST_INSERT_ID());
INSERT IGNORE INTO eav_attribute_option_value (option_id, store_id, value) VALUES (@opt, 0, 'Practical Exam');

-- Option: Case Study
SET @opt := (SELECT eao.option_id FROM eav_attribute_option eao JOIN eav_attribute_option_value eaov ON eaov.option_id=eao.option_id WHERE eao.attribute_id=@aid_assess AND eaov.store_id=0 AND eaov.value='Case Study' LIMIT 1);
INSERT INTO eav_attribute_option (attribute_id, sort_order) SELECT @aid_assess, 30 FROM DUAL WHERE @opt IS NULL;
SET @opt := IFNULL(@opt, LAST_INSERT_ID());
INSERT IGNORE INTO eav_attribute_option_value (option_id, store_id, value) VALUES (@opt, 0, 'Case Study');

-- Option: Role Play
SET @opt := (SELECT eao.option_id FROM eav_attribute_option eao JOIN eav_attribute_option_value eaov ON eaov.option_id=eao.option_id WHERE eao.attribute_id=@aid_assess AND eaov.store_id=0 AND eaov.value='Role Play' LIMIT 1);
INSERT INTO eav_attribute_option (attribute_id, sort_order) SELECT @aid_assess, 40 FROM DUAL WHERE @opt IS NULL;
SET @opt := IFNULL(@opt, LAST_INSERT_ID());
INSERT IGNORE INTO eav_attribute_option_value (option_id, store_id, value) VALUES (@opt, 0, 'Role Play');

-- Option: Oral Questioning
SET @opt := (SELECT eao.option_id FROM eav_attribute_option eao JOIN eav_attribute_option_value eaov ON eaov.option_id=eao.option_id WHERE eao.attribute_id=@aid_assess AND eaov.store_id=0 AND eaov.value='Oral Questioning' LIMIT 1);
INSERT INTO eav_attribute_option (attribute_id, sort_order) SELECT @aid_assess, 50 FROM DUAL WHERE @opt IS NULL;
SET @opt := IFNULL(@opt, LAST_INSERT_ID());
INSERT IGNORE INTO eav_attribute_option_value (option_id, store_id, value) VALUES (@opt, 0, 'Oral Questioning');

-- Option: Assignment
SET @opt := (SELECT eao.option_id FROM eav_attribute_option eao JOIN eav_attribute_option_value eaov ON eaov.option_id=eao.option_id WHERE eao.attribute_id=@aid_assess AND eaov.store_id=0 AND eaov.value='Assignment' LIMIT 1);
INSERT INTO eav_attribute_option (attribute_id, sort_order) SELECT @aid_assess, 60 FROM DUAL WHERE @opt IS NULL;
SET @opt := IFNULL(@opt, LAST_INSERT_ID());
INSERT IGNORE INTO eav_attribute_option_value (option_id, store_id, value) VALUES (@opt, 0, 'Assignment');

-- Option: Demonstration
SET @opt := (SELECT eao.option_id FROM eav_attribute_option eao JOIN eav_attribute_option_value eaov ON eaov.option_id=eao.option_id WHERE eao.attribute_id=@aid_assess AND eaov.store_id=0 AND eaov.value='Demonstration' LIMIT 1);
INSERT INTO eav_attribute_option (attribute_id, sort_order) SELECT @aid_assess, 70 FROM DUAL WHERE @opt IS NULL;
SET @opt := IFNULL(@opt, LAST_INSERT_ID());
INSERT IGNORE INTO eav_attribute_option_value (option_id, store_id, value) VALUES (@opt, 0, 'Demonstration');

-- Option: Project
SET @opt := (SELECT eao.option_id FROM eav_attribute_option eao JOIN eav_attribute_option_value eaov ON eaov.option_id=eao.option_id WHERE eao.attribute_id=@aid_assess AND eaov.store_id=0 AND eaov.value='Project' LIMIT 1);
INSERT INTO eav_attribute_option (attribute_id, sort_order) SELECT @aid_assess, 80 FROM DUAL WHERE @opt IS NULL;
SET @opt := IFNULL(@opt, LAST_INSERT_ID());
INSERT IGNORE INTO eav_attribute_option_value (option_id, store_id, value) VALUES (@opt, 0, 'Project');

-- ---------------------------------------------------------------------------
-- 3) Attach the attribute to every product attribute set, under the existing
--    "Course Sections" group (created by migration 149).
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO eav_entity_attribute (entity_type_id, attribute_set_id, attribute_group_id, attribute_id, sort_order)
SELECT 4, eag.attribute_set_id, eag.attribute_group_id, @aid_assess, 50
FROM eav_attribute_group eag
JOIN eav_attribute_set eas ON eas.attribute_set_id = eag.attribute_set_id
WHERE eag.attribute_group_name = 'Course Sections' AND eas.entity_type_id = 4;
