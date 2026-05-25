-- Re-order `assessment_duration` to render right after Level / Course Type
-- inside its attribute group, rather than buried below assessment_methods.
--
-- Migration 159 attached the attribute with sort_order=85 (after assessment_
-- methods at 80), which puts it at the bottom of the group. Admin operators
-- expect to see Assessment Duration alongside the other "course info"
-- numerics (Duration, Sessions, Level), so we lower the sort.
--
-- Idempotent.

SET @aid := (SELECT attribute_id FROM eav_attribute
             WHERE entity_type_id=4 AND attribute_code='assessment_duration' LIMIT 1);

UPDATE eav_entity_attribute
SET sort_order = 7
WHERE attribute_id = @aid;
