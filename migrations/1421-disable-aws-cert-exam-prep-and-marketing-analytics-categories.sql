-- Disable four retired catalog category pages and 301 their URLs to a live parent.
--
-- Requested 2026-09-18. Four landing pages are being taken down:
--
--   227  "AWS Certification Exam Prep"  aws-certification-exams.html
--   404  "AWS Certification Exam Prep"  aws-certification-preparation-exam-courses.html
--          (child of 227, same display name, hidden from the menu)
--   126  "Marketing Analytics"          marketing-analytics-courses.html
--    98  "ERP & CRM"                    erp-crm-training-courses.html
--
-- Each was a real indexed landing page, so the old URL 301s to its live parent
-- rather than dead-ending:
--   227, 404  ->  certification-exam-prep-courses.html      (parent 182)
--   126       ->  digital-marketing-courses-in.html         (parent 8)
--    98       ->  logistics-and-manufacturing-courses.html  (parent 132)
--
-- VERIFIED ON PROD BEFORE WRITING: no ENABLED product is orphaned by any of the
-- four (every one sits in at least one other live category), so nothing drops
-- off the storefront. Product rewrites nested under these slugs resolve to
-- catalog/product/view/... and keep working independently -- left alone.
--
-- CHAIN FLATTENING. Two slugs already 301 INTO pages we are now retiring, which
-- would leave a 301 -> 301 -> 200 hop. Both are re-pointed at the final target:
--   business-analytics-training-courses.html                     -> 126, now -> parent 8
--   adult-training-courses/.../erp-crm-training-courses.html     ->  98, now -> parent 132
-- Four search terms redirect to business-analytics-training-courses.html; they
-- keep working because that slug itself now lands on a live page in one hop.
--
-- The 7 search-term redirects aimed at aws-certification-preparation-exam-courses.html
-- are CLEARED to '' so those terms fall back to normal search results instead of
-- redirecting into a redirect (feedback_search_redirects_rot_when_course_disabled).
--
-- Categories resolved BY url_key + name so this is a clean no-op on partner
-- sites (MY/GH), whose trees differ. Idempotent.
--
-- WHY id_path IS SET EXPLICITLY: core_url_rewrite has UNIQUE(id_path,is_system,
-- store_id). Category 126 already owns 'category/126' at is_system=0 via the
-- business-analytics redirect row, so inserting another is_system=0 row without
-- an id_path collided (1062) on the first dry-run and aborted the whole chain.
-- Every INSERT below therefore writes a distinct, deterministic id_path.
--
-- ORDER OF OPERATIONS (learned the hard way on prod 2026-07-18, migration 588):
-- a `catalog_url` reindex REGENERATES the rewrite row for a disabled category as
-- `catalog/category/view/id/<id>`, which then 301s into a 404. So this migration
-- must be (re-)applied AFTER any catalog_url reindex, not before. The UPDATEs
-- below match the regenerated id-path target as well as an already-correct row,
-- so re-running always restores the right target.
--
-- AFTER APPLYING ON PROD, reindex -- a cache flush alone will NOT clear the page,
-- because the storefront reads catalog_category_flat_store_1
-- (see feedback_category_repurpose_needs_flat_reindex_not_just_cache_flush):
--   catalog_category_flat, catalog_url, catalog_category_product
-- then flush the cache, THEN re-run this file so the 301s survive the reindex.

SET @a_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='name');
SET @a_uk     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='url_key');
SET @a_active := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='is_active');
SET @a_menu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=3 AND attribute_code='include_in_menu');

-- ---------------------------------------------------------------- resolve ids
-- Matched on url_key AND name so a same-slug category elsewhere can't be hit.

SET @aws_parent := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_uk AND v.store_id=0
  WHERE v.value='aws-certification-exams' LIMIT 1) r);

SET @aws_child := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_uk AND v.store_id=0
  WHERE v.value='aws-certification-preparation-exam-courses' AND e.parent_id=@aws_parent LIMIT 1) r);

SET @certprep := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_uk AND v.store_id=0
  JOIN catalog_category_entity_varchar n ON n.entity_id=e.entity_id AND n.attribute_id=@a_name AND n.store_id=0
  WHERE v.value='certification-exam-prep-courses' AND TRIM(n.value)='Certification Exam Prep' LIMIT 1) r);

SET @mktg := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_uk AND v.store_id=0
  JOIN catalog_category_entity_varchar n ON n.entity_id=e.entity_id AND n.attribute_id=@a_name AND n.store_id=0
  WHERE v.value='marketing-analytics-courses' AND TRIM(n.value)='Marketing Analytics' LIMIT 1) r);

SET @dmkt := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_uk AND v.store_id=0
  JOIN catalog_category_entity_varchar n ON n.entity_id=e.entity_id AND n.attribute_id=@a_name AND n.store_id=0
  WHERE v.value='digital-marketing-courses-in' AND TRIM(n.value)='Digital Marketing' LIMIT 1) r);

SET @erp := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_uk AND v.store_id=0
  JOIN catalog_category_entity_varchar n ON n.entity_id=e.entity_id AND n.attribute_id=@a_name AND n.store_id=0
  WHERE v.value='erp-crm-training-courses' AND TRIM(n.value)='ERP & CRM' LIMIT 1) r);

SET @logi := (SELECT entity_id FROM (SELECT e.entity_id FROM catalog_category_entity e
  JOIN catalog_category_entity_varchar v ON v.entity_id=e.entity_id AND v.attribute_id=@a_uk AND v.store_id=0
  JOIN catalog_category_entity_varchar n ON n.entity_id=e.entity_id AND n.attribute_id=@a_name AND n.store_id=0
  WHERE v.value='logistics-and-manufacturing-courses' AND TRIM(n.value)='Logistics & Supply Chain' LIMIT 1) r);

-- Redirect source/target paths, read from the live url_keys.
SET @src_awsp := (SELECT CONCAT(value,'.html') FROM catalog_category_entity_varchar
  WHERE entity_id=@aws_parent AND attribute_id=@a_uk AND store_id=0 LIMIT 1);
SET @src_awsc := (SELECT CONCAT(value,'.html') FROM catalog_category_entity_varchar
  WHERE entity_id=@aws_child  AND attribute_id=@a_uk AND store_id=0 LIMIT 1);
SET @dst_aws  := (SELECT CONCAT(value,'.html') FROM catalog_category_entity_varchar
  WHERE entity_id=@certprep   AND attribute_id=@a_uk AND store_id=0 LIMIT 1);
SET @src_mktg := (SELECT CONCAT(value,'.html') FROM catalog_category_entity_varchar
  WHERE entity_id=@mktg       AND attribute_id=@a_uk AND store_id=0 LIMIT 1);
SET @dst_mktg := (SELECT CONCAT(value,'.html') FROM catalog_category_entity_varchar
  WHERE entity_id=@dmkt       AND attribute_id=@a_uk AND store_id=0 LIMIT 1);
SET @src_erp  := (SELECT CONCAT(value,'.html') FROM catalog_category_entity_varchar
  WHERE entity_id=@erp        AND attribute_id=@a_uk AND store_id=0 LIMIT 1);
SET @dst_erp  := (SELECT CONCAT(value,'.html') FROM catalog_category_entity_varchar
  WHERE entity_id=@logi       AND attribute_id=@a_uk AND store_id=0 LIMIT 1);

-- Per-branch guards: each branch applies independently, so a partner site
-- missing one still gets the others (and a site missing all is a total no-op).
-- A NULL target would silently blank a redirect -- excluded.
SET @ok_aws  := (@aws_parent IS NOT NULL AND @certprep IS NOT NULL
                 AND @src_awsp IS NOT NULL AND @dst_aws IS NOT NULL AND @src_awsp <> @dst_aws);
SET @ok_awsc := (@ok_aws AND @aws_child IS NOT NULL AND @src_awsc IS NOT NULL AND @src_awsc <> @dst_aws);
SET @ok_mktg := (@mktg IS NOT NULL AND @dmkt IS NOT NULL
                 AND @src_mktg IS NOT NULL AND @dst_mktg IS NOT NULL AND @src_mktg <> @dst_mktg);
SET @ok_erp  := (@erp IS NOT NULL AND @logi IS NOT NULL
                 AND @src_erp IS NOT NULL AND @dst_erp IS NOT NULL AND @src_erp <> @dst_erp);

-- ------------------------------------------------------- disable + de-menu
-- store_id=0 (default scope) plus any store-scope override rows, so a
-- store-level is_active=1 can't keep the page alive.

UPDATE catalog_category_entity_int SET value = 0
 WHERE attribute_id = @a_active
   AND ((@ok_aws  AND entity_id = @aws_parent)
     OR (@ok_awsc AND entity_id = @aws_child)
     OR (@ok_mktg AND entity_id = @mktg)
     OR (@ok_erp  AND entity_id = @erp));

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_active, 0, e.entity_id, 0 FROM catalog_category_entity e
 WHERE ((@ok_aws  AND e.entity_id = @aws_parent)
     OR (@ok_awsc AND e.entity_id = @aws_child)
     OR (@ok_mktg AND e.entity_id = @mktg)
     OR (@ok_erp  AND e.entity_id = @erp))
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM catalog_category_entity_int) x
                   WHERE x.entity_id = e.entity_id AND x.attribute_id = @a_active AND x.store_id = 0);

UPDATE catalog_category_entity_int SET value = 0
 WHERE attribute_id = @a_menu
   AND ((@ok_aws  AND entity_id = @aws_parent)
     OR (@ok_awsc AND entity_id = @aws_child)
     OR (@ok_mktg AND entity_id = @mktg)
     OR (@ok_erp  AND entity_id = @erp));

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_menu, 0, e.entity_id, 0 FROM catalog_category_entity e
 WHERE ((@ok_aws  AND e.entity_id = @aws_parent)
     OR (@ok_awsc AND e.entity_id = @aws_child)
     OR (@ok_mktg AND e.entity_id = @mktg)
     OR (@ok_erp  AND e.entity_id = @erp))
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM catalog_category_entity_int) x
                   WHERE x.entity_id = e.entity_id AND x.attribute_id = @a_menu AND x.store_id = 0);

-- --------------------------------------------------------------- 301 the URLs
-- Each UPDATE matches BOTH the id-path target a catalog_url reindex regenerates
-- and an already-corrected row, so this is safe to re-run after any reindex.

UPDATE core_url_rewrite
   SET target_path = @dst_aws, options = 'RP', is_system = 0, category_id = NULL,
       id_path = CONCAT('mmd_retire/', @aws_parent)
 WHERE @ok_aws AND request_path = @src_awsp
   AND (target_path = CONCAT('catalog/category/view/id/', @aws_parent) OR target_path = @dst_aws);

UPDATE core_url_rewrite
   SET target_path = @dst_aws, options = 'RP', is_system = 0, category_id = NULL,
       id_path = CONCAT('mmd_retire/', @aws_child)
 WHERE @ok_awsc AND request_path = @src_awsc
   AND (target_path = CONCAT('catalog/category/view/id/', @aws_child) OR target_path = @dst_aws);

UPDATE core_url_rewrite
   SET target_path = @dst_mktg, options = 'RP', is_system = 0, category_id = NULL,
       id_path = CONCAT('mmd_retire/', @mktg)
 WHERE @ok_mktg AND request_path = @src_mktg
   AND (target_path = CONCAT('catalog/category/view/id/', @mktg) OR target_path = @dst_mktg);

UPDATE core_url_rewrite
   SET target_path = @dst_erp, options = 'RP', is_system = 0, category_id = NULL,
       id_path = CONCAT('mmd_retire/', @erp)
 WHERE @ok_erp AND request_path = @src_erp
   AND (target_path = CONCAT('catalog/category/view/id/', @erp) OR target_path = @dst_erp);

-- If no rewrite row exists for an old slug on a live store, create one.
-- id_path is explicit and distinct (see header) to avoid the UNIQUE
-- (id_path,is_system,store_id) collision with pre-existing redirect rows.
INSERT INTO core_url_rewrite (store_id, category_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, NULL, CONCAT('mmd_retire/', @aws_parent), @src_awsp, @dst_aws, 0, 'RP' FROM core_store s
 WHERE @ok_aws AND s.store_id > 0
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
                   WHERE x.request_path = @src_awsp AND x.store_id = s.store_id);

INSERT INTO core_url_rewrite (store_id, category_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, NULL, CONCAT('mmd_retire/', @aws_child), @src_awsc, @dst_aws, 0, 'RP' FROM core_store s
 WHERE @ok_awsc AND s.store_id > 0
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
                   WHERE x.request_path = @src_awsc AND x.store_id = s.store_id);

INSERT INTO core_url_rewrite (store_id, category_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, NULL, CONCAT('mmd_retire/', @mktg), @src_mktg, @dst_mktg, 0, 'RP' FROM core_store s
 WHERE @ok_mktg AND s.store_id > 0
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
                   WHERE x.request_path = @src_mktg AND x.store_id = s.store_id);

INSERT INTO core_url_rewrite (store_id, category_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, NULL, CONCAT('mmd_retire/', @erp), @src_erp, @dst_erp, 0, 'RP' FROM core_store s
 WHERE @ok_erp AND s.store_id > 0
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
                   WHERE x.request_path = @src_erp AND x.store_id = s.store_id);

-- ------------------------------------------------------- flatten 301 chains
-- Any rewrite that pointed AT a now-retired slug is re-pointed at the final
-- destination, so no visitor takes two hops. Scoped to redirect rows
-- (is_system=0) and skips the retired slug's own row.

UPDATE core_url_rewrite SET target_path = @dst_mktg
 WHERE @ok_mktg AND is_system = 0 AND target_path = @src_mktg AND request_path <> @src_mktg;

UPDATE core_url_rewrite SET target_path = @dst_erp
 WHERE @ok_erp AND is_system = 0 AND target_path = @src_erp AND request_path <> @src_erp;

UPDATE core_url_rewrite SET target_path = @dst_aws
 WHERE @ok_aws AND is_system = 0 AND target_path = @src_awsp AND request_path <> @src_awsp;

UPDATE core_url_rewrite SET target_path = @dst_aws
 WHERE @ok_awsc AND is_system = 0 AND target_path = @src_awsc AND request_path <> @src_awsc;

-- ------------------------------------------------- clear dead search redirects
-- 7 terms point at the AWS child slug. It now 301s rather than 404s, but a
-- search redirect into a redirect is a needless hop -- blank it so Magento
-- shows real search results, which for these terms surface live AWS courses.
UPDATE catalogsearch_query SET redirect = ''
 WHERE @ok_awsc AND redirect LIKE CONCAT('%', @src_awsc)
   AND redirect IS NOT NULL AND redirect <> '';

UPDATE catalogsearch_query SET redirect = ''
 WHERE @ok_aws AND redirect LIKE CONCAT('%', @src_awsp)
   AND redirect IS NOT NULL AND redirect <> '';

UPDATE catalogsearch_query SET redirect = ''
 WHERE @ok_mktg AND redirect LIKE CONCAT('%', @src_mktg)
   AND redirect IS NOT NULL AND redirect <> '';

UPDATE catalogsearch_query SET redirect = ''
 WHERE @ok_erp AND redirect LIKE CONCAT('%', @src_erp)
   AND redirect IS NOT NULL AND redirect <> '';
