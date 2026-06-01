-- Course Section product attributes.
--
-- Per-course data that currently lives inline inside short_description and is
-- regex-extracted at render time in view.phtml. Storing it as proper EAV
-- attributes lets admins edit each section independently, lets labels stay
-- template-controlled, and removes the parse-on-every-pageview tax.
--
-- Phase 1: this migration only creates the attributes. No product rows are
-- written and view.phtml is NOT changed, so the storefront renders the same
-- HTML as before (it still reads short_description). A separate backfill +
-- view.phtml cutover happens in later phases once we've reviewed the dry-run
-- extraction report.
--
-- Attribute set assignment: added to ALL product attribute sets under a new
-- "Course Sections" group so they show up in admin product edit. Idempotent.
--
-- Re-runnable: every INSERT is guarded; running twice is a no-op.

-- ---------------------------------------------------------------------------
-- Helper: create one course-section attribute idempotently.
-- (Inlined per attribute since apply.php does not support routines.)
-- ---------------------------------------------------------------------------

-- 1) course_lo_html — Learning Outcomes section body (HTML).
SET @existing := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_lo_html' LIMIT 1);
INSERT INTO eav_attribute (entity_type_id, attribute_code, backend_type, frontend_input, frontend_label, is_required, is_user_defined, is_unique, note)
SELECT 4, 'course_lo_html', 'text', 'textarea', 'Learning Outcomes (HTML)', 0, 1, 0,
       'HTML body for the Learning Outcomes card. Leave empty to fall back to short_description regex extraction.'
FROM DUAL WHERE @existing IS NULL;
SET @aid_lo := IFNULL(@existing, LAST_INSERT_ID());
INSERT IGNORE INTO catalog_eav_attribute (attribute_id, is_global, is_visible, used_in_product_listing) VALUES (@aid_lo, 1, 1, 0);

-- 2) course_brochure_html — Brochure section body (HTML).
SET @existing := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_brochure_html' LIMIT 1);
INSERT INTO eav_attribute (entity_type_id, attribute_code, backend_type, frontend_input, frontend_label, is_required, is_user_defined, is_unique, note)
SELECT 4, 'course_brochure_html', 'text', 'textarea', 'Course Brochure (HTML)', 0, 1, 0,
       'HTML body for the Course Brochure card. Should contain a single <a href> to the PDF.'
FROM DUAL WHERE @existing IS NULL;
SET @aid_br := IFNULL(@existing, LAST_INSERT_ID());
INSERT IGNORE INTO catalog_eav_attribute (attribute_id, is_global, is_visible, used_in_product_listing) VALUES (@aid_br, 1, 1, 0);

-- 3) course_skills_framework_html — Skills Framework section body (HTML).
SET @existing := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_skills_framework_html' LIMIT 1);
INSERT INTO eav_attribute (entity_type_id, attribute_code, backend_type, frontend_input, frontend_label, is_required, is_user_defined, is_unique, note)
SELECT 4, 'course_skills_framework_html', 'text', 'textarea', 'Skills Framework (HTML)', 0, 1, 0,
       'HTML body for the Skills Framework card. view.phtml derives TSC Title and TSC Code from this prose.'
FROM DUAL WHERE @existing IS NULL;
SET @aid_sf := IFNULL(@existing, LAST_INSERT_ID());
INSERT IGNORE INTO catalog_eav_attribute (attribute_id, is_global, is_visible, used_in_product_listing) VALUES (@aid_sf, 1, 1, 0);

-- 4) course_wsq_funding_raw_html — WSQ Funding section RAW inner HTML.
-- This is the inside of the <div style="...border-radius:25px"> wrapper
-- BEFORE view.phtml strips the legacy fee table / boilerplate paragraphs.
-- Storing raw keeps view.phtml's existing processing pipeline byte-identical
-- in Phase 3 (it runs the same regex strips on this attribute).
SET @existing := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_wsq_funding_raw_html' LIMIT 1);
INSERT INTO eav_attribute (entity_type_id, attribute_code, backend_type, frontend_input, frontend_label, is_required, is_user_defined, is_unique, note)
SELECT 4, 'course_wsq_funding_raw_html', 'text', 'textarea', 'WSQ Funding Raw (HTML)', 0, 1, 0,
       'RAW inner HTML of the WSQ Funding wrapper (SFEC/SFC/UTAP/PSEA paragraphs and their TGS- links). Leave empty for non-WSQ courses.'
FROM DUAL WHERE @existing IS NULL;
SET @aid_wsq := IFNULL(@existing, LAST_INSERT_ID());
INSERT IGNORE INTO catalog_eav_attribute (attribute_id, is_global, is_visible, used_in_product_listing) VALUES (@aid_wsq, 1, 1, 0);

-- ---------------------------------------------------------------------------
-- Attach all four attributes to a new "Course Sections" group on every
-- product attribute set, so they appear in admin product edit.
-- ---------------------------------------------------------------------------

-- Create the "Course Sections" attribute group on every product attribute set
-- (idempotent — UNIQUE on (attribute_set_id, attribute_group_name)).
INSERT IGNORE INTO eav_attribute_group (attribute_set_id, attribute_group_name, sort_order, default_id)
SELECT eas.attribute_set_id, 'Course Sections', 50, 0
FROM eav_attribute_set eas WHERE eas.entity_type_id = 4;

-- Attach each attribute to that group on every set.
INSERT IGNORE INTO eav_entity_attribute (entity_type_id, attribute_set_id, attribute_group_id, attribute_id, sort_order)
SELECT 4, eag.attribute_set_id, eag.attribute_group_id, @aid_lo, 10
FROM eav_attribute_group eag
JOIN eav_attribute_set eas ON eas.attribute_set_id = eag.attribute_set_id
WHERE eag.attribute_group_name = 'Course Sections' AND eas.entity_type_id = 4;

INSERT IGNORE INTO eav_entity_attribute (entity_type_id, attribute_set_id, attribute_group_id, attribute_id, sort_order)
SELECT 4, eag.attribute_set_id, eag.attribute_group_id, @aid_br, 20
FROM eav_attribute_group eag
JOIN eav_attribute_set eas ON eas.attribute_set_id = eag.attribute_set_id
WHERE eag.attribute_group_name = 'Course Sections' AND eas.entity_type_id = 4;

INSERT IGNORE INTO eav_entity_attribute (entity_type_id, attribute_set_id, attribute_group_id, attribute_id, sort_order)
SELECT 4, eag.attribute_set_id, eag.attribute_group_id, @aid_sf, 30
FROM eav_attribute_group eag
JOIN eav_attribute_set eas ON eas.attribute_set_id = eag.attribute_set_id
WHERE eag.attribute_group_name = 'Course Sections' AND eas.entity_type_id = 4;

INSERT IGNORE INTO eav_entity_attribute (entity_type_id, attribute_set_id, attribute_group_id, attribute_id, sort_order)
SELECT 4, eag.attribute_set_id, eag.attribute_group_id, @aid_wsq, 40
FROM eav_attribute_group eag
JOIN eav_attribute_set eas ON eas.attribute_set_id = eag.attribute_set_id
WHERE eag.attribute_group_name = 'Course Sections' AND eas.entity_type_id = 4;
