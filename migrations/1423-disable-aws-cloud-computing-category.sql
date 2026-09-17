-- Disable the retired "AWS" category page and 301 it to Certification Exam Prep.
--
-- Requested 2026-09-18, follow-up to migration 1421 (which retired 227/404/126/98).
-- This one sits in a DIFFERENT branch -- Infocomm Technology (55) -> Cloud
-- Computing (87) -> AWS (183) -- which is why it was not in that batch:
--
--   183  "AWS"  aws-cloud-computing-courses.html  ->  certification-exam-prep-courses.html
--
-- The 301 target is NOT this category's own parent (Cloud Computing). The owner
-- explicitly chose Certification Exam Prep (182), because the listing's content
-- is AWS certification training. Resolved by url_key+name, not by parent walk.
--
-- VERIFIED ON PROD BEFORE WRITING: 183 holds 11 ENABLED courses, 10 of them
-- WSQ/CASL funded (TGS- SKUs). NONE is orphaned by this change -- every one sits
-- in at least one other live category, so all 11 stay reachable on the
-- storefront and only this browsing path goes away. Confirmed with the owner
-- before applying, since unlike 1421's four this is a live funded listing.
--
-- CHAIN FLATTENING. The flattened deep path
--   adult-training-courses/.../cloud-computing-courses/aws-cloud-computing-courses.html
-- already 301s INTO this slug and would become a two-hop; it is re-pointed at
-- the final destination.
--
-- SEARCH REDIRECTS. 10 terms point here, including high-traffic "AWS" and
-- "amazon web services". They are REPOINTED at certification-exam-prep-courses.html
-- rather than cleared: unlike 1421's AWS-child terms (whose courses are indexed
-- and surface fine via normal search), these are broad brand terms whose best
-- landing page is the curated cert-prep listing. Repointing also stops them
-- redirecting into a redirect.
--
-- WHY id_path IS SET EXPLICITLY (learned in 1421, 2026-09-18): core_url_rewrite
-- has UNIQUE(id_path,is_system,store_id). Flipping the category's own system row
-- to is_system=0 collides with any existing redirect row already holding
-- 'category/<id>' at is_system=0, and a 1062 there ABORTS the whole apply.php
-- chain -> every host 502s. Both the UPDATE and the INSERT therefore write a
-- distinct deterministic id_path. See
-- feedback_category_301_needs_explicit_id_path_unique_key.
--
-- ORDER OF OPERATIONS: a `catalog_url` reindex REGENERATES the rewrite row for a
-- disabled category as `catalog/category/view/id/<id>`, which then 301s into a
-- 404. The UPDATE below matches that regenerated id-path target as well as an
-- already-correct row, so re-running always restores the right target.
--
-- AFTER APPLYING ON PROD, reindex -- a cache flush alone will NOT clear the page,
-- because the storefront reads catalog_category_flat_store_1:
--   catalog_category_flat, catalog_url, catalog_category_product
-- then flush the cache, and re-check the 301 survived.
--
-- Resolved BY url_key + name so this is a clean no-op on partner sites. Idempotent.

SET @a_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='name');
SET @a_uk     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='url_key');
SET @a_active := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='is_active');
SET @a_menu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='include_in_menu');

-- The retired category: url_key + name 'AWS' + parent named 'Cloud Computing',
-- so a same-slug category in another tree cannot be hit.
SET @aws := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_uk AND v.store_id=0
  JOIN catalog_category_entity_varchar n ON n.entity_id=e.entity_id AND n.attribute_id=@a_name AND n.store_id=0
  JOIN catalog_category_entity_varchar pn ON pn.entity_id=e.parent_id AND pn.attribute_id=@a_name AND pn.store_id=0
  WHERE v.value='aws-cloud-computing-courses' AND TRIM(n.value)='AWS'
    AND TRIM(pn.value)='Cloud Computing' LIMIT 1) r);

-- Redirect target: Certification Exam Prep (owner's explicit choice).
SET @certprep := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_uk AND v.store_id=0
  JOIN catalog_category_entity_varchar n ON n.entity_id=e.entity_id AND n.attribute_id=@a_name AND n.store_id=0
  WHERE v.value='certification-exam-prep-courses' AND TRIM(n.value)='Certification Exam Prep' LIMIT 1) r);

SET @src := (SELECT CONCAT(value,'.html') FROM catalog_category_entity_varchar
  WHERE entity_id=@aws      AND attribute_id=@a_uk AND store_id=0 LIMIT 1);
SET @dst := (SELECT CONCAT(value,'.html') FROM catalog_category_entity_varchar
  WHERE entity_id=@certprep AND attribute_id=@a_uk AND store_id=0 LIMIT 1);

-- A NULL target would silently blank a redirect; a self-redirect would loop.
SET @ok := (@aws IS NOT NULL AND @certprep IS NOT NULL
            AND @src IS NOT NULL AND @dst IS NOT NULL AND @src <> @dst);

-- Extra safety: refuse to run if the destination is not itself enabled.
SET @ok := (@ok AND (SELECT COALESCE(MIN(i.value),0) FROM catalog_category_entity_int i
                      WHERE i.entity_id=@certprep AND i.attribute_id=@a_active) = 1);

-- ------------------------------------------------------- disable + de-menu
-- store_id=0 (default scope) plus any store-scope override rows, so a
-- store-level is_active=1 cannot keep the page alive.

UPDATE catalog_category_entity_int SET value = 0
 WHERE @ok AND entity_id = @aws AND attribute_id IN (@a_active, @a_menu);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_active, 0, @aws, 0 FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM catalog_category_entity_int) x
                           WHERE x.entity_id = @aws AND x.attribute_id = @a_active AND x.store_id = 0);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_menu, 0, @aws, 0 FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM catalog_category_entity_int) x
                           WHERE x.entity_id = @aws AND x.attribute_id = @a_menu AND x.store_id = 0);

-- --------------------------------------------------------------- 301 the URL
-- Matches BOTH the id-path target a catalog_url reindex regenerates and an
-- already-corrected row, so this is safe to re-run after any reindex.
UPDATE core_url_rewrite
   SET target_path = @dst, options = 'RP', is_system = 0, category_id = NULL,
       id_path = CONCAT('mmd_retire/', @aws)
 WHERE @ok AND request_path = @src
   AND (target_path = CONCAT('catalog/category/view/id/', @aws) OR target_path = @dst);

-- If no rewrite row exists for the old slug on a live store, create one.
INSERT INTO core_url_rewrite (store_id, category_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, NULL, CONCAT('mmd_retire/', @aws), @src, @dst, 0, 'RP' FROM core_store s
 WHERE @ok AND s.store_id > 0
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
                   WHERE x.request_path = @src AND x.store_id = s.store_id);

-- ------------------------------------------------------- flatten 301 chain
-- The flattened deep path pointed at this slug; send it straight to the target.
UPDATE core_url_rewrite SET target_path = @dst
 WHERE @ok AND is_system = 0 AND target_path = @src AND request_path <> @src;

-- ------------------------------------------------ repoint search redirects
-- 10 broad AWS brand terms; the curated cert-prep listing is the better landing
-- page than raw search results, and this keeps them to a single hop.
UPDATE catalogsearch_query
   SET redirect = CONCAT(SUBSTRING_INDEX(redirect, '/', 3), '/', @dst)
 WHERE @ok AND redirect LIKE CONCAT('%/', @src)
   AND redirect IS NOT NULL AND redirect <> '';
