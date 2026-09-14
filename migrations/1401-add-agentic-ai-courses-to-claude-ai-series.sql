-- 1401: Add two WSQ courses to the Claude AI Series (281).
--
--   TGS-2022017520  WSQ - Agentic AI for Market Research
--   TGS-2025060552  WSQ - Agentic AI for Affiliate Marketing
--
-- Two other courses named in the same request were already members and are
-- deliberately untouched: TGS-2023018659 (Claude Cowork for Digital Marketing,
-- pos 2) and TGS-2020503109 (Claude Cowork for Email Marketing, pos 3).
--
-- Both new rows go at the END of the TGS- block (after TGS-2026061312 at pos 4)
-- and the C-prefix block shifts down by 2, so funded-first is preserved.
-- 'claude-ai-series' IS in mmd/category_ordering/curated_url_keys, and the
-- nightly sweep preserves TGS- relative order, so these positions are stable.
--
-- Category before:              After:
--   1..4  TGS- block              1..4  TGS- block (unchanged)
--   5..14 C- block                5     TGS-2022017520   <- new
--                                 6     TGS-2025060552   <- new
--                                 7..16 C- block (shifted +2)
--
-- Writes BOTH catalog_category_product (admin source of truth) and
-- catalog_category_product_index (what the listing reads), for every store_id
-- already present for this category. Business-key lookups by url_key / sku.
-- TGS- SKUs are SG-only, so this is a clean no-op on partner sites (the
-- @prod lookups return NULL there). Idempotent: the shift is gated on the
-- product not already being a member.

SET @cat := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'claude-ai-series' LIMIT 1
);
SET @p1 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2022017520' LIMIT 1);
SET @p2 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025060552' LIMIT 1);

-- How many of the two are genuinely new (drives the shift amount, so a re-run
-- shifts nothing).
SET @new := (
  SELECT (CASE WHEN @p1 IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM (SELECT * FROM catalog_category_product) t
            WHERE t.category_id = @cat AND t.product_id = @p1) THEN 1 ELSE 0 END)
       + (CASE WHEN @p2 IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM (SELECT * FROM catalog_category_product) t
            WHERE t.category_id = @cat AND t.product_id = @p2) THEN 1 ELSE 0 END)
);

-- ===== make room: push everything below the TGS- block down =====

UPDATE catalog_category_product
SET position = position + @new
WHERE @cat IS NOT NULL AND @new > 0
  AND category_id = @cat
  AND position >= 5;

UPDATE catalog_category_product_index
SET position = position + @new
WHERE @cat IS NOT NULL AND @new > 0
  AND category_id = @cat
  AND position >= 5;

-- ===== insert the new rows =====

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @p1, 5 FROM dual WHERE @cat IS NOT NULL AND @p1 IS NOT NULL;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @p2, 6 FROM dual WHERE @cat IS NOT NULL AND @p2 IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @p1, 5, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND @p1 IS NOT NULL AND i.category_id = @cat
GROUP BY i.store_id;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @p2, 6, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND @p2 IS NOT NULL AND i.category_id = @cat
GROUP BY i.store_id;

-- ===== pin the positions (also corrects a re-run) =====

UPDATE catalog_category_product SET position = 5
WHERE @cat IS NOT NULL AND @p1 IS NOT NULL AND category_id = @cat AND product_id = @p1;
UPDATE catalog_category_product SET position = 6
WHERE @cat IS NOT NULL AND @p2 IS NOT NULL AND category_id = @cat AND product_id = @p2;

UPDATE catalog_category_product_index SET position = 5
WHERE @cat IS NOT NULL AND @p1 IS NOT NULL AND category_id = @cat AND product_id = @p1;
UPDATE catalog_category_product_index SET position = 6
WHERE @cat IS NOT NULL AND @p2 IS NOT NULL AND category_id = @cat AND product_id = @p2;
