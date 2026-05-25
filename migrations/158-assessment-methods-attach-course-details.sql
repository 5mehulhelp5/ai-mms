-- Attach `assessment_methods` to the "Course Details" attribute group.
--
-- Migration 157 tried to attach this multiselect to the "Course Sections"
-- group, but migration 150 had previously dropped that group as part of the
-- cms/block cutover. The INSERT IGNORE silently no-op'd, so the admin
-- product-edit page never showed the field — admins saw nothing under
-- "Course Details" where they expected to manage assessment methods.
--
-- This migration attaches the attribute to the long-standing "Course Details"
-- group on every product attribute set that has one. Idempotent on
-- (attribute_set_id, attribute_id) — re-runs are no-ops.

SET @aid_assess := (SELECT attribute_id FROM eav_attribute
                     WHERE entity_type_id=4 AND attribute_code='assessment_methods' LIMIT 1);

INSERT IGNORE INTO eav_entity_attribute (entity_type_id, attribute_set_id, attribute_group_id, attribute_id, sort_order)
SELECT 4, eag.attribute_set_id, eag.attribute_group_id, @aid_assess, 80
FROM eav_attribute_group eag
JOIN eav_attribute_set eas ON eas.attribute_set_id = eag.attribute_set_id
WHERE eag.attribute_group_name = 'Course Details' AND eas.entity_type_id = 4
  AND @aid_assess IS NOT NULL;
