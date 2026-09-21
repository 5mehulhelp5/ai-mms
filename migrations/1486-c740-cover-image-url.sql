-- 1486: C740 — point course_image_url at the re-rendered cover.
--
-- Follow-up to 1485, which renamed C740 to "Google Professional Machine
-- Learning Engineer Training". Course covers are pre-rendered PNGs on R2 with
-- the TITLE painted into the image, so the rename left the product serving a
-- cover that still read "Google Cloud Certified Professional Cloud Architect
-- Training". The renderer is not a live code path — the image had to be
-- regenerated and re-uploaded, which was done out-of-band:
--
--   C740-20260717-162916.png  (old title)
--   C740-20260921-051055.png  (new title, 1600x900, 156834 bytes, verified 200)
--
-- Rendered with the product's OWN badges (C740 is a non-fundable C-prefix SKU,
-- so badges = [] and the cover carries no funding chips) and WITHOUT
-- syncProductTags(), so only the image changed and no badge data was touched.
--
-- The old R2 object is deliberately left in place, so reverting is just
-- repointing this attribute back at the 20260717 file.
--
-- Guarded on the OLD value so this is idempotent and cannot clobber a cover
-- rendered later by someone else.
--
-- Partner-safe: C740 exists only on SG => @e IS NULL on MY/GH => no-op.
--
-- AFTER DEPLOY: course_image_url is read from the FLAT table on the storefront,
-- so reindex catalog_product_flat (or the stale cover keeps serving).

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C740' LIMIT 1);
SET @a_cover := (SELECT attribute_id FROM eav_attribute
                  WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');

UPDATE catalog_product_entity_varchar
   SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C740-20260921-051055.png'
 WHERE entity_id = @e
   AND attribute_id = @a_cover
   AND value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C740-20260717-162916.png'
   AND @e IS NOT NULL;
