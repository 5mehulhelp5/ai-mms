-- 1459: C526 "No Code and Low Code Agentic AI Applications" -- correct the
--       Duration tile from 32 hrs to 30 hrs.
--
-- Migration 1451 set duration = 32 by copying the WSQ parent TGS-2026062147.
-- That figure is the WSQ course's, and it includes its assessment block. A
-- non-WSQ course has no assessment and runs the house day of 9:30am - 5:30pm
-- = 7.5 instructional hours, so a 4-day non-WSQ course is 30 hrs, not 32.
--
-- This is the established convention across the catalogue, not a judgement
-- call: every other 4-day C-prefix course reads 30 (C14, C767, C921, C1754,
-- C1404, C389 ...), and every 3-day one reads 22.5 (= 3 x 7.5).
--
-- The published courseware now states 30 hrs throughout -- the Lesson Plan's
-- course-facts table ("4 Days (30 instructional hours)", "9:30 AM - 5:30 PM
-- (7.5 instructional hours/day)") and the deck's schedule slide -- so leaving
-- the storefront at 32 would contradict the learner's own materials.
--
-- sessions stays 4 (four class days) and price stays $1400 -- both correct.
--
-- Idempotent. Store scope 0. ID resolved by SKU.

SET @e     = (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C526');
SET @a_dur = (SELECT attribute_id FROM eav_attribute
               WHERE entity_type_id = 4 AND attribute_code = 'duration');

UPDATE catalog_product_entity_varchar
   SET value = '30'
 WHERE entity_id = @e AND attribute_id = @a_dur AND store_id = 0
   AND @e IS NOT NULL AND @a_dur IS NOT NULL;

-- Clear any per-store override so store 1 cannot shadow the store-0 value.
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_dur AND store_id <> 0
   AND @e IS NOT NULL AND @a_dur IS NOT NULL;
