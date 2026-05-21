-- Close the unbalanced `<div style="background-color: #dddddd; ...">` wrapper
-- around the WSQ Funding section in course short_description values.
-- Course TGS-2024043854 (entity_id 1296) renders distorted on
-- tertiarycourses.com.sg because this div opens but never closes, so the
-- "You May Be Interested In These Courses" section gets nested inside the
-- funding box and the related-course grid collapses to single-character
-- columns.
--
-- The migration counts `<div` opens vs `</div>` closes inside any
-- short_description (attribute_id=73) that contains the `background-color:
-- #dddddd` funding-wrapper pattern, and appends ONE `</div>` if the count
-- is imbalanced. Idempotent: once balanced, the WHERE clause filters it
-- out on re-run.
--
-- Locally this is a no-op (the synced product uses Quill 2.x `<table>` markup
-- without this wrapper div). On production it should restore proper
-- layout on the affected course page(s).

UPDATE catalog_product_entity_text
SET value = CONCAT(value, '</div>')
WHERE attribute_id = 73
  AND value LIKE '%<div style="background-color: #dddddd%'
  AND ((LENGTH(value) - LENGTH(REPLACE(value, '<div', ''))) / 4)
    > ((LENGTH(value) - LENGTH(REPLACE(value, '</div>', ''))) / 6);
