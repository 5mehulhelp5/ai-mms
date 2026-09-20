-- 1477: C1162 "CompTIA Linux+ Training" -- align the non-WSQ course with its
-- WSQ parent TGS-2024048316 "WSQ - CompTIA Certified Linux+ Training".
--
-- The twin was running SHORTER than its parent: 3 days / 22.5 hrs / $900 on
-- schedule template C03, against the parent's 5-day E02 intake. It is now a
-- 5-day course at $1,800.
--
--   duration  22,5 -> 37.5     (3 days -> 5 days)
--   price      900 -> 1800
--
-- DURATION IS 37.5, NOT THE PARENT'S 40. The non-WSQ house day is 9:30am-5:30pm
-- = 7.5 hrs, so 5 days = 37.5. The WSQ parent's 40 includes its assessment block
-- (WA + PP), which the non-WSQ twin does not run -- copying 40 across would ship
-- a Duration tile that contradicts the course's own lesson plan (incident
-- 2026-09-20 on C526, fixed by 1459; see memory
-- feedback_nonwsq_duration_is_7p5_hours_per_day). 37.5 is also the established
-- catalogue value for a 5-day non-WSQ course (42 courses carry it).
--
-- The old value was written '22,5' with a COMMA -- an anomaly against the house
-- format, which uses a dot ('7.5', '22.5', '37.5'). The new value uses the dot.
--
-- NOT IN THIS FILE: the schedule template switch C03 -> E02 (gid 290 -> 262).
-- custom_options_relation is keyed (group_id, option_id, product_id), so a
-- template has one row PER OPTION and there is no product/group row to insert --
-- a DELETE+INSERT migration fails on 'option_id has no default value' AFTER the
-- delete, leaving the course with NO schedule options and uncheckoutable
-- (incident 2026-09-17 on C141). The switch is a CODE path: it was applied via
-- the admin's switchScheduleTemplateAction, which clones the template's options
-- onto the product and carries over admin-confirmed dates. Recorded here as a
-- note only, per the non-wsq-schedule skill.
--
-- store_id = 0 (default scope) -- this course is SG-only; C-prefix SKUs exist on
-- partner sites, so both statements are keyed on SKU and are a clean no-op where
-- the row is absent. Idempotent.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C1162');
SET @a_dur := (SELECT attribute_id FROM eav_attribute
               WHERE entity_type_id = 4 AND attribute_code = 'duration');
SET @a_price := (SELECT attribute_id FROM eav_attribute
                 WHERE entity_type_id = 4 AND attribute_code = 'price');

UPDATE catalog_product_entity_varchar
SET value = '37.5'
WHERE entity_id = @e AND attribute_id = @a_dur AND store_id = 0
  AND @e IS NOT NULL AND @a_dur IS NOT NULL;

UPDATE catalog_product_entity_decimal
SET value = 1800.0000
WHERE entity_id = @e AND attribute_id = @a_price AND store_id = 0
  AND @e IS NOT NULL AND @a_price IS NOT NULL;
