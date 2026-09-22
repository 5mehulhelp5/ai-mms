-- 1538: TGS-2024048317 -> "WSQ - CompTIA A+ (Core 1 and 2)"
--
-- Shortens the CompTIA A+ course title. The url_key is deliberately NOT
-- changed (the slug stays 'wsq-comptia-certified-a-training-core-1-and-core-2'),
-- so every existing rewrite, backlink and stored search redirect keeps
-- resolving and no 301 work is needed.
--
-- The WSQ prefix is kept on the product NAME (consistent with the rest of the
-- WSQ catalog and the category listings) but is deliberately absent from the
-- COVER IMAGE, which reads "CompTIA A+ (Core 1 and 2)".
--
-- Content is NOT touched: description, short_description and the five
-- course_TGS-2024048317_* cms blocks were checked and carry no occurrence of
-- the old title, so there is nothing to rewrite there. Price, duration,
-- sessions, categories and the badge tags (WSQ, SkillsFuture Credit, PSEA,
-- SFEC, Absentee Payroll, MCES) are all unchanged.
--
-- The cover is a PRE-RENDERED PNG on R2 with the title baked in, so the rename
-- alone would keep serving a cover reading "CompTIA Certified A+ Training
-- (Core 1 and Core 2)". The new object was rendered by
-- MMD_CourseImage_Model_Cover (same code path as the admin cover dialog) with
-- the course's OWN badges, and uploaded to shared R2 storage:
--   course-covers/TGS-2024048317-20260922-171619.png   (155850 bytes, HTTP 200)
-- The superseded object is left on R2 so reverting is just repointing the URL.
--
-- The three image label attributes render as the cover's alt="" / title="" on
-- the product page, so they are retitled as well; only rows whose value is
-- exactly the OLD title are rewritten, leaving any admin customisation alone.
--
-- SG production only; keyed by SKU so a partner site with no TGS-2024048317
-- no-ops. Idempotent: re-running converges.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024048317' LIMIT 1);
SET @etid := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product');

-- name
SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='name' AND entity_type_id=@etid);
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - CompTIA A+ (Core 1 and 2)'
 WHERE attribute_id = @a_name AND entity_id = @pid AND @pid IS NOT NULL;

-- image / small_image / thumbnail labels (alt + title text on the cover)
UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a
    ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = @etid
   AND a.attribute_code IN ('image_label','small_image_label','thumbnail_label')
   SET v.value = 'WSQ - CompTIA A+ (Core 1 and 2)'
 WHERE v.entity_id = @pid AND @pid IS NOT NULL
   AND v.value = 'WSQ - CompTIA Certified A+ Training (Core 1 and Core 2)';

-- media gallery label (shown under the gallery thumb)
UPDATE catalog_product_entity_media_gallery_value
   SET label = 'WSQ - CompTIA A+ (Core 1 and 2)'
 WHERE @pid IS NOT NULL
   AND TRIM(label) = 'WSQ CompTIA A+ Training'
   AND value_id IN (SELECT value_id FROM catalog_product_entity_media_gallery WHERE entity_id = @pid);

-- cover image: repoint at the regenerated PNG (global scope; clear any
-- store-scoped row that would shadow it)
SET @a_ciu := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='course_image_url' AND entity_type_id=@etid);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_ciu, 0, @pid,
       'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024048317-20260922-171619.png'
 WHERE @pid IS NOT NULL AND @a_ciu IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @pid AND attribute_id = @a_ciu AND store_id <> 0
   AND @pid IS NOT NULL AND @a_ciu IS NOT NULL;
