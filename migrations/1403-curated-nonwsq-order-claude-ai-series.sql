-- 1403: Pin the requested non-WSQ (C-) order in the Claude AI Series (281).
--
-- Requested order (positions 7..15, directly after the six TGS- rows pinned
-- 1..6 by migration 1402):
--    7  C1382  Claude Cowork Masterclass
--    8  C201   Claude Design Masterclass
--    9  C197   Claude Microsoft 365 Masterclass
--   10  C1417  Claude Code Masterclass
--   11  C141   Claude Code for Digital Marketing
--   12  C744   Claude Certified Associate - Foundations Certification
--   13  C437   Claude Certified Architect - Foundations Certification
--   14  C364   Claude Certified Architect - Professional Certification
--   15  C439   Claude Certified Developer - Foundations Certification
--
-- Net change vs the order left by 1402: the three Masterclasses lead
-- (Cowork, Design, Microsoft 365), then Claude Code Masterclass drops from 7
-- to 10 and Claude Code for Digital Marketing stays at 11. The four
-- Certification rows (12..15) keep their existing order. The TGS- block
-- (1..6) is deliberately untouched.
--
-- This is a CURATED non-alphabetical order. It only survives because
-- 'claude-ai-series' is present in mmd/category_ordering/curated_url_keys --
-- the nightly MMD_RoleManager_Model_Cron_CategoryOrdering sweep skips curated
-- categories, so it will not re-alphabetise these rows. If that url_key is
-- ever removed from the curated list, this pin dies within 24h.
-- Positive positions only (negative pins are flattened -- see 1195).
--
-- Writes BOTH catalog_category_product (admin source of truth) and
-- catalog_category_product_index (what the storefront listing reads), for
-- every store present for the category. Absolute position writes, so it is
-- idempotent and self-correcting on a re-run. Business-key lookups by sku;
-- these C- SKUs also exist on partner sites, but the @cat lookup resolves
-- per-instance and the writes are scoped to that category, so partner rows
-- are only touched if the same category exists there.

SET @cat := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'claude-ai-series' LIMIT 1
);

SET @c1 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C1382' LIMIT 1);
SET @c2 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C201'  LIMIT 1);
SET @c3 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C197'  LIMIT 1);
SET @c4 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C1417' LIMIT 1);
SET @c5 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C141'  LIMIT 1);
SET @c6 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C744'  LIMIT 1);
SET @c7 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C437'  LIMIT 1);
SET @c8 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C364'  LIMIT 1);
SET @c9 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C439'  LIMIT 1);

-- ===== base table (admin view) =====

UPDATE catalog_category_product SET position = 7
WHERE @cat IS NOT NULL AND @c1 IS NOT NULL AND category_id = @cat AND product_id = @c1;
UPDATE catalog_category_product SET position = 8
WHERE @cat IS NOT NULL AND @c2 IS NOT NULL AND category_id = @cat AND product_id = @c2;
UPDATE catalog_category_product SET position = 9
WHERE @cat IS NOT NULL AND @c3 IS NOT NULL AND category_id = @cat AND product_id = @c3;
UPDATE catalog_category_product SET position = 10
WHERE @cat IS NOT NULL AND @c4 IS NOT NULL AND category_id = @cat AND product_id = @c4;
UPDATE catalog_category_product SET position = 11
WHERE @cat IS NOT NULL AND @c5 IS NOT NULL AND category_id = @cat AND product_id = @c5;
UPDATE catalog_category_product SET position = 12
WHERE @cat IS NOT NULL AND @c6 IS NOT NULL AND category_id = @cat AND product_id = @c6;
UPDATE catalog_category_product SET position = 13
WHERE @cat IS NOT NULL AND @c7 IS NOT NULL AND category_id = @cat AND product_id = @c7;
UPDATE catalog_category_product SET position = 14
WHERE @cat IS NOT NULL AND @c8 IS NOT NULL AND category_id = @cat AND product_id = @c8;
UPDATE catalog_category_product SET position = 15
WHERE @cat IS NOT NULL AND @c9 IS NOT NULL AND category_id = @cat AND product_id = @c9;

-- ===== index table (what the storefront listing reads) =====

UPDATE catalog_category_product_index SET position = 7
WHERE @cat IS NOT NULL AND @c1 IS NOT NULL AND category_id = @cat AND product_id = @c1;
UPDATE catalog_category_product_index SET position = 8
WHERE @cat IS NOT NULL AND @c2 IS NOT NULL AND category_id = @cat AND product_id = @c2;
UPDATE catalog_category_product_index SET position = 9
WHERE @cat IS NOT NULL AND @c3 IS NOT NULL AND category_id = @cat AND product_id = @c3;
UPDATE catalog_category_product_index SET position = 10
WHERE @cat IS NOT NULL AND @c4 IS NOT NULL AND category_id = @cat AND product_id = @c4;
UPDATE catalog_category_product_index SET position = 11
WHERE @cat IS NOT NULL AND @c5 IS NOT NULL AND category_id = @cat AND product_id = @c5;
UPDATE catalog_category_product_index SET position = 12
WHERE @cat IS NOT NULL AND @c6 IS NOT NULL AND category_id = @cat AND product_id = @c6;
UPDATE catalog_category_product_index SET position = 13
WHERE @cat IS NOT NULL AND @c7 IS NOT NULL AND category_id = @cat AND product_id = @c7;
UPDATE catalog_category_product_index SET position = 14
WHERE @cat IS NOT NULL AND @c8 IS NOT NULL AND category_id = @cat AND product_id = @c8;
UPDATE catalog_category_product_index SET position = 15
WHERE @cat IS NOT NULL AND @c9 IS NOT NULL AND category_id = @cat AND product_id = @c9;
