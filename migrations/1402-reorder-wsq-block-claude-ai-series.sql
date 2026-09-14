-- 1402: Pin the requested WSQ (TGS-) order in the Claude AI Series (281).
--
-- Requested order (positions 1..6):
--   1  TGS-2025052468  WSQ - Agentic AI Applications with Claude Code
--   2  TGS-2023018659  WSQ - Claude Cowork for Digital Marketing
--   3  TGS-2020503109  WSQ - Claude Cowork for Email Marketing
--   4  TGS-2022017520  WSQ - Agentic AI for Market Research
--   5  TGS-2025060552  WSQ - Agentic AI for Affiliate Marketing
--   6  TGS-2026061312  WSQ - Claude Certified Architect Foundation
--
-- Net effect vs the order left by 1401: TGS-2026061312 moves 4 -> 6, and
-- TGS-2022017520 / TGS-2025060552 shift up to 4 / 5. The C-prefix block
-- (positions 7..15) is deliberately untouched -- this is a WSQ-block reorder
-- only, and the non-WSQ courses keep their curated positions.
--
-- 'claude-ai-series' IS in mmd/category_ordering/curated_url_keys and the
-- nightly ordering sweep preserves TGS- relative order by position, so these
-- pins survive. Funded-first still holds (all six TGS- rows stay above 7).
--
-- Writes BOTH catalog_category_product (admin source of truth) and
-- catalog_category_product_index (what the listing reads), all stores present
-- for the category. Absolute position writes, so it is idempotent and
-- self-correcting on a re-run. Business-key lookups; TGS- SKUs are SG-only, so
-- the @p* lookups are NULL on partner sites and every statement no-ops there.

SET @cat := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'claude-ai-series' LIMIT 1
);

SET @p1 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025052468' LIMIT 1);
SET @p2 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023018659' LIMIT 1);
SET @p3 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2020503109' LIMIT 1);
SET @p4 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2022017520' LIMIT 1);
SET @p5 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025060552' LIMIT 1);
SET @p6 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2026061312' LIMIT 1);

-- ===== base table (admin view) =====

UPDATE catalog_category_product SET position = 1
WHERE @cat IS NOT NULL AND @p1 IS NOT NULL AND category_id = @cat AND product_id = @p1;
UPDATE catalog_category_product SET position = 2
WHERE @cat IS NOT NULL AND @p2 IS NOT NULL AND category_id = @cat AND product_id = @p2;
UPDATE catalog_category_product SET position = 3
WHERE @cat IS NOT NULL AND @p3 IS NOT NULL AND category_id = @cat AND product_id = @p3;
UPDATE catalog_category_product SET position = 4
WHERE @cat IS NOT NULL AND @p4 IS NOT NULL AND category_id = @cat AND product_id = @p4;
UPDATE catalog_category_product SET position = 5
WHERE @cat IS NOT NULL AND @p5 IS NOT NULL AND category_id = @cat AND product_id = @p5;
UPDATE catalog_category_product SET position = 6
WHERE @cat IS NOT NULL AND @p6 IS NOT NULL AND category_id = @cat AND product_id = @p6;

-- ===== index table (what the storefront listing reads) =====

UPDATE catalog_category_product_index SET position = 1
WHERE @cat IS NOT NULL AND @p1 IS NOT NULL AND category_id = @cat AND product_id = @p1;
UPDATE catalog_category_product_index SET position = 2
WHERE @cat IS NOT NULL AND @p2 IS NOT NULL AND category_id = @cat AND product_id = @p2;
UPDATE catalog_category_product_index SET position = 3
WHERE @cat IS NOT NULL AND @p3 IS NOT NULL AND category_id = @cat AND product_id = @p3;
UPDATE catalog_category_product_index SET position = 4
WHERE @cat IS NOT NULL AND @p4 IS NOT NULL AND category_id = @cat AND product_id = @p4;
UPDATE catalog_category_product_index SET position = 5
WHERE @cat IS NOT NULL AND @p5 IS NOT NULL AND category_id = @cat AND product_id = @p5;
UPDATE catalog_category_product_index SET position = 6
WHERE @cat IS NOT NULL AND @p6 IS NOT NULL AND category_id = @cat AND product_id = @p6;
