-- 1539: TGS-2024048318 -> "WSQ - CompTIA Server+ Training"
--
-- Drops the word "Certified" from the course title. The vendor certification
-- is "CompTIA Server+" -- there is no "CompTIA Certified Server+" product --
-- so the old name misnamed the cert it prepares learners for.
--
-- The "WSQ - " prefix STAYS: this is a funded TGS- course and 271 of the 299
-- TGS- SKUs carry that prefix, which is what flags a funded course in the
-- category listing and in search results.
--
-- url_key is deliberately UNCHANGED (wsq-comptia-certified-server-training),
-- so every existing link keeps resolving and NO 301 rewrite is needed. The
-- slug still reads "certified", which is cosmetic only and not worth the
-- redirect churn -- re-slugging would require 301s for the bare URL plus each
-- category-prefixed path.
--
-- Cover: covers are PRE-RENDERED PNGs on R2 with the title baked in, so the
-- rename alone would keep serving a cover reading "CompTIA Certified
-- Server+ Training". The new object was rendered by
-- MMD_CourseImage_Model_Cover (same code path as the admin cover dialog)
-- with the product's OWN badges (WSQ, SkillsFuture Credit, PSEA, UTAP, SFEC,
-- Absentee Payroll, MCES) and uploaded to shared R2, reachable from prod:
--   course-covers/TGS-2024048318-20260922-154750.png  (152362 bytes, HTTP 200)
-- The superseded object is left on R2 so reverting is just repointing the URL.
--
-- Tags are NOT touched -- this changes naming + image only, never badge data.
--
-- SG production only; keyed by SKU so a partner site with no TGS-2024048318
-- no-ops. Idempotent: re-running converges (plain UPDATEs + ON DUPLICATE KEY).

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024048318' LIMIT 1);
SET @etype := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');

-- name
SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='name' AND entity_type_id=@etype);
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - CompTIA Server+ Training'
 WHERE attribute_id = @a_name AND entity_id = @pid AND @pid IS NOT NULL;

-- meta_title: keep the existing "<title> | Tertiary Courses Singapore" shape,
-- stored BARE of the store suffix per the site's render-time composer.
SET @a_mt := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_title' AND entity_type_id=@etype);
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ CompTIA Server+ Training | Tertiary Courses Singapore'
 WHERE attribute_id = @a_mt AND entity_id = @pid AND @pid IS NOT NULL;

-- meta_description: drop "Certified" only; stays well under the 255-char cap.
SET @a_md := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_description' AND entity_type_id=@etype);
UPDATE catalog_product_entity_varchar
   SET value = 'Advance your server management skills with our WSQ CompTIA Server+ Training. Learn server administration, virtualization, and data security. Enjoy up to 70% WSQ funding subsidy.'
 WHERE attribute_id = @a_md AND entity_id = @pid AND @pid IS NOT NULL;

-- image LABELS: the product page renders these as the cover's alt="" and
-- title="" text. Only rows still holding the exact OLD title are rewritten,
-- so a label an admin has since customised is left alone.
UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a
    ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = @etype
   AND a.attribute_code IN ('image_label','small_image_label','thumbnail_label')
   SET v.value = 'WSQ - CompTIA Server+ Training'
 WHERE v.entity_id = @pid AND @pid IS NOT NULL
   AND v.value = 'WSQ - CompTIA Certified Server+ Training';

-- cover image: repoint at the regenerated PNG (global scope; clear any
-- store-scoped row that would shadow it)
SET @a_ciu := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='course_image_url' AND entity_type_id=@etype);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @a_ciu, 0, @pid,
       'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024048318-20260922-154750.png'
 WHERE @pid IS NOT NULL AND @a_ciu IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @pid AND attribute_id = @a_ciu AND store_id <> 0
   AND @pid IS NOT NULL AND @a_ciu IS NOT NULL;
