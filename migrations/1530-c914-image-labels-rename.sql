-- 1530: C914 image labels -> "Robot Operating System (ROS) Fundamentals"
--
-- Follow-up to 1528. The rename updated `name` but the three image LABEL
-- attributes (image_label / small_image_label / thumbnail_label) still stored
-- the pre-rename title, and the product page renders them as the cover's
-- alt="" and title="" text -- so the page still said "Robotics with ROS"
-- twice even though the image itself was the regenerated cover.
--
-- Only rows whose value is exactly the OLD title are rewritten, so a label an
-- admin has since customised is left alone.
--
-- SG production only; keyed by SKU so a partner site with no C914 no-ops.
-- Idempotent: re-running matches nothing once applied.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C914' LIMIT 1);

UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a
    ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product')
   AND a.attribute_code IN ('image_label','small_image_label','thumbnail_label')
   SET v.value = 'Robot Operating System (ROS) Fundamentals'
 WHERE v.entity_id = @pid AND @pid IS NOT NULL
   AND v.value = 'Robotics with ROS';
