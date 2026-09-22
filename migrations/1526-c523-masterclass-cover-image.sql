-- 1526: point C523 at its re-rendered "Project Management Masterclass" cover
--
-- The cover PNG bakes the course TITLE into the image, so the 1524 rename made
-- the old cover wrong (it still read the previous course name). Re-rendered via
-- MMD_CourseImage_Model_Cover and uploaded to R2; this sets the URL.
--
-- course_image_url is Store View scoped (migration 126); scope 0 is the
-- fallback every store reads unless it has its own row.
-- Idempotent: re-running writes the same value.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C523' LIMIT 1);
SET @a_cov := (SELECT attribute_id FROM eav_attribute
                WHERE attribute_code = 'course_image_url'
                  AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type
                                         WHERE entity_type_code = 'catalog_product'));

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product'),
       @a_cov, 0, @pid,
       'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C523-20260922-151341.png'
WHERE @pid IS NOT NULL AND @a_cov IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
