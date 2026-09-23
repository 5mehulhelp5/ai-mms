-- C1262: media-gallery alt text follow-up to 1535 (the repurpose to
-- "Business Negotiation Masterclass"). 1535 renamed the product, but NOT the
-- media-gallery row's own `label`, which is what the product page renders as
-- the cover's alt/title -- so the page still carried
-- alt="Effective Negotiation Training in Singapore" over the new cover image.
-- Also refreshes the image_label / small_image_label / thumbnail_label EAV
-- attributes, which feed listing tiles.
-- Idempotent: guarded on the OLD text, so a re-run is a no-op.
-- Partner-safe: C1262 exists only on SG => @e IS NULL on MY/GH => no-op.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1262' LIMIT 1);

UPDATE catalog_product_entity_media_gallery_value v
  JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
   SET v.label = 'Business Negotiation Masterclass in Singapore'
 WHERE g.entity_id = @e
   AND @e IS NOT NULL
   AND v.label LIKE '%Effective Negotiation Training%';

UPDATE catalog_product_entity_varchar ev
  JOIN eav_attribute a ON a.attribute_id = ev.attribute_id
  JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
   AND t.entity_type_code = 'catalog_product'
   SET ev.value = 'Business Negotiation Masterclass in Singapore'
 WHERE ev.entity_id = @e
   AND @e IS NOT NULL
   AND a.attribute_code IN ('image_label','small_image_label','thumbnail_label')
   AND ev.value LIKE '%Effective Negotiation Training%';
