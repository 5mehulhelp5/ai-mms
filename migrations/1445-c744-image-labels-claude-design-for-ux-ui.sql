-- 1444: Follow-up to 1442. Fix the FOUR image-label surfaces C744's repurpose
-- left stale. These are four surfaces, not one
-- (feedback_media_gallery_label_is_the_real_alt_text):
--
--   image_label / small_image_label / thumbnail_label  (varchar attrs)
--   catalog_product_entity_media_gallery_value.label   (the REAL rendered alt)
--
-- The rendered page served alt="Claude Certified Associate - Foundations
-- Certification" from the gallery row; the three *_label attrs alone do NOT
-- change it. The gallery label was two renames behind -- still on the
-- pre-Claude "Unreal Engine Blueprint Visual Programming Course in Singapore".
--
-- Plain title, no prefix, matching CourseImage Cover::cleanTitle. Idempotent.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C744');

SET @a_il  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'Claude Design for UX/UI' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'Claude Design for UX/UI' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'Claude Design for UX/UI' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND @e IS NOT NULL
  AND attribute_id IN (@a_il, @a_sil, @a_til);

-- The one the storefront actually renders as alt=/title=.
UPDATE catalog_product_entity_media_gallery_value v
  JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
   SET v.label = 'Claude Design for UX/UI'
 WHERE g.entity_id = @e AND @e IS NOT NULL;
