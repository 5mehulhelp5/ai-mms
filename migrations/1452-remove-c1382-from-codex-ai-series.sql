-- 1452: Remove "Claude Cowork Masterclass" (C1382) from the Codex AI Series (283).
--
-- Reverses migration 1400, which had added C1382 to this category at position 2.
-- The course is a Claude course, not a Codex one; it keeps its other
-- memberships (Claude AI Series 281 etc.) -- this drops ONE assignment, it does
-- not disable or delete the product.
--
-- Category before this change (store 1):
--   1  TGS-2023041081  WSQ - Agentic AI Applications with Codex
--   2  C1382           Claude Cowork Masterclass   <-- removed
--   3  C818            Codex for Digital Marketing
--   4  C427            Codex for Work Automation
--   5  C989            Codex Masterclass
-- After: the C-block shifts up, leaving 1..4 contiguous. That is exactly the
-- canonical order (funded TGS- first, then C- alphabetical), and
-- 'codex-ai-series' is NOT in mmd/category_ordering/curated_url_keys, so the
-- nightly ordering sweep keeps reproducing it. No curated pin needed.
--
-- Deletes from BOTH catalog_category_product (admin source of truth) and
-- catalog_category_product_index (what the listing actually reads), for every
-- store present -- so it lands without a reindex. Business-key lookups
-- (url_key / sku). Idempotent: re-running is a no-op once the row is gone,
-- and the position shift is guarded on the row still existing.

SET @cat  := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'codex-ai-series' LIMIT 1
);
SET @prod := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C1382' LIMIT 1);

-- Position the row currently occupies, captured BEFORE the delete so the
-- shift-up only touches products that sat after it. NULL if already removed.
SET @pos := (
  SELECT position FROM catalog_category_product
  WHERE category_id = @cat AND product_id = @prod LIMIT 1
);

-- ===== base table =====

DELETE FROM catalog_category_product
WHERE @cat IS NOT NULL AND @prod IS NOT NULL
  AND category_id = @cat AND product_id = @prod;

UPDATE catalog_category_product
SET position = position - 1
WHERE @cat IS NOT NULL AND @prod IS NOT NULL AND @pos IS NOT NULL
  AND category_id = @cat
  AND position > @pos;

-- ===== index table: same removal + shift, across every store =====

DELETE FROM catalog_category_product_index
WHERE @cat IS NOT NULL AND @prod IS NOT NULL
  AND category_id = @cat AND product_id = @prod;

UPDATE catalog_category_product_index
SET position = position - 1
WHERE @cat IS NOT NULL AND @prod IS NOT NULL AND @pos IS NOT NULL
  AND category_id = @cat
  AND position > @pos;
