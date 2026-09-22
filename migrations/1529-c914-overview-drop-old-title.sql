-- 1529: C914 overview -- drop the old course title from the opening sentence.
--
-- Follow-up to 1528 (which was already in the schema_migrations ledger by the
-- time this was spotted, so editing it in place would never re-run).
--
-- The overview opened "Build and program robots with Robotics with ROS.",
-- naming the pre-rename title. Restated with the new name.
--
-- SG production only; keyed by SKU so a partner site with no C914 no-ops.
-- Idempotent: the REPLACE is a no-op once applied.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C914' LIMIT 1);

SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description'
   AND entity_type_id=(SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product'));
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
        'Build and program robots with Robotics with ROS.',
        'Build and program robots with the Robot Operating System (ROS).')
 WHERE attribute_id = @a_short AND entity_id = @pid AND @pid IS NOT NULL;
