-- Attach the four hydroponics tour photos to product 1064 (WSQ Basic
-- Urban Farming with Hydroponics) as additional Media Gallery entries.
-- These previously rendered inline in the description under a "Guided
-- Farm Tour" heading (removed by 147); the right-column Photo Gallery
-- block in view.phtml reads catalog_product_entity_media_gallery, so we
-- populate it here.
--
-- Files are seeded onto the volume-mounted media/ disk by entrypoint.sh
-- (see CPG_SEED_DIR -> /var/www/html/media/catalog/product/). The hash
-- subdir convention is first-letter/second-letter of the filename, so all
-- four images live under /h/y/.
--
-- Idempotent via NOT EXISTS guards. media_gallery has no unique key on
-- (entity_id, value), so INSERT IGNORE wouldn't help.
-- attribute_id 88 = media_gallery for catalog_product on this DB.

INSERT INTO catalog_product_entity_media_gallery (attribute_id, entity_id, value)
SELECT 88, 1064, '/h/y/hydroponics-guided-tour-1.jpg' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM catalog_product_entity_media_gallery g WHERE g.entity_id = 1064 AND g.value = '/h/y/hydroponics-guided-tour-1.jpg');

INSERT INTO catalog_product_entity_media_gallery (attribute_id, entity_id, value)
SELECT 88, 1064, '/h/y/hydroponics-guided-tour-3.jpg' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM catalog_product_entity_media_gallery g WHERE g.entity_id = 1064 AND g.value = '/h/y/hydroponics-guided-tour-3.jpg');

INSERT INTO catalog_product_entity_media_gallery (attribute_id, entity_id, value)
SELECT 88, 1064, '/h/y/hydroponics-guided-tour-7.jpg' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM catalog_product_entity_media_gallery g WHERE g.entity_id = 1064 AND g.value = '/h/y/hydroponics-guided-tour-7.jpg');

INSERT INTO catalog_product_entity_media_gallery (attribute_id, entity_id, value)
SELECT 88, 1064, '/h/y/hydroponics-farm-tour-5.jpg' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM catalog_product_entity_media_gallery g WHERE g.entity_id = 1064 AND g.value = '/h/y/hydroponics-farm-tour-5.jpg');

INSERT INTO catalog_product_entity_media_gallery_value (value_id, store_id, label, position, disabled)
SELECT g.value_id, 0, 'Hydroponics Farm Tour', 1, 0 FROM catalog_product_entity_media_gallery g
WHERE g.entity_id = 1064 AND g.value = '/h/y/hydroponics-guided-tour-1.jpg'
  AND NOT EXISTS (SELECT 1 FROM catalog_product_entity_media_gallery_value v WHERE v.value_id = g.value_id AND v.store_id = 0);

INSERT INTO catalog_product_entity_media_gallery_value (value_id, store_id, label, position, disabled)
SELECT g.value_id, 0, 'Hydroponics Urban Farming', 2, 0 FROM catalog_product_entity_media_gallery g
WHERE g.entity_id = 1064 AND g.value = '/h/y/hydroponics-guided-tour-3.jpg'
  AND NOT EXISTS (SELECT 1 FROM catalog_product_entity_media_gallery_value v WHERE v.value_id = g.value_id AND v.store_id = 0);

INSERT INTO catalog_product_entity_media_gallery_value (value_id, store_id, label, position, disabled)
SELECT g.value_id, 0, 'Hydroponics Course', 3, 0 FROM catalog_product_entity_media_gallery g
WHERE g.entity_id = 1064 AND g.value = '/h/y/hydroponics-guided-tour-7.jpg'
  AND NOT EXISTS (SELECT 1 FROM catalog_product_entity_media_gallery_value v WHERE v.value_id = g.value_id AND v.store_id = 0);

INSERT INTO catalog_product_entity_media_gallery_value (value_id, store_id, label, position, disabled)
SELECT g.value_id, 0, 'Urban Farming with Hydroponics', 4, 0 FROM catalog_product_entity_media_gallery g
WHERE g.entity_id = 1064 AND g.value = '/h/y/hydroponics-farm-tour-5.jpg'
  AND NOT EXISTS (SELECT 1 FROM catalog_product_entity_media_gallery_value v WHERE v.value_id = g.value_id AND v.store_id = 0);
