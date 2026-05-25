-- Place `assessment_duration` directly after `duration` in the Course Details
-- group (i.e. between Duration and Level / Course Type).
--
-- Current sort_orders in Course Details:
--   sessions=4, duration=5, level=6, software=7, assessment_duration=7,
--   additional_note=8, prerequisite=9, whoshouldattend=10, assessment_methods=80
--
-- We bump every row in [6..79] by +1, then set assessment_duration to 6.
-- The @needs guard makes the bump idempotent on re-run.

SET @aid := (SELECT attribute_id FROM eav_attribute
             WHERE entity_type_id=4 AND attribute_code='assessment_duration' LIMIT 1);

SET @needs := (SELECT 1 FROM eav_entity_attribute eea
               JOIN eav_attribute_group eag ON eag.attribute_group_id=eea.attribute_group_id
               WHERE eea.attribute_id=@aid
                 AND eag.attribute_group_name='Course Details'
                 AND eea.sort_order <> 6
               LIMIT 1);

UPDATE eav_entity_attribute eea
JOIN eav_attribute_group eag ON eag.attribute_group_id=eea.attribute_group_id
SET eea.sort_order = eea.sort_order + 1
WHERE eag.attribute_group_name = 'Course Details'
  AND eea.entity_type_id = 4
  AND eea.sort_order BETWEEN 6 AND 79
  AND eea.attribute_id <> @aid
  AND @needs = 1;

UPDATE eav_entity_attribute SET sort_order = 6 WHERE attribute_id = @aid;
