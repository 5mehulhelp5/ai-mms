-- 1400: Add "Claude Cowork Masterclass" (C1382) to the Codex AI Series (283),
--       placed before "Codex for Digital Marketing" (C818).
--
-- The requested order coincides with the canonical alphabetical rule
-- ('Claude ...' < 'Codex ...'), and 'codex-ai-series' is NOT in
-- mmd/category_ordering/curated_url_keys, so the nightly ordering sweep will
-- keep reproducing this order rather than flattening it. No curated pin and no
-- exemption entry are needed.
--
-- Category before this change (store 1):
--   1  TGS-2023041081  WSQ - Agentic AI Applications with Codex
--   2  C818            Codex for Digital Marketing
--   3  C427            Codex for Work Automation
--   4  C989            Codex Masterclass
-- After: C1382 takes position 2, the C-block shifts down, TGS- stays at 1.
--
-- C1382 keeps its existing memberships (Claude AI Series 281 etc.) -- this is
-- an additional assignment, not a move.
--
-- Writes BOTH catalog_category_product (admin source of truth) and
-- catalog_category_product_index (what the listing actually reads), for every
-- store_id already present for this category on the instance -- so it lands
-- without a reindex and stays correct on partner sites. Business-key lookups
-- (url_key / sku); C-prefix SKUs exist on partner sites too, so this is
-- intentionally not SG-gated. Idempotent.

SET @cat := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'codex-ai-series' LIMIT 1
);
SET @prod := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C1382' LIMIT 1);

-- ===== base table: make room at position 2, then insert =====

UPDATE catalog_category_product
SET position = position + 1
WHERE @cat IS NOT NULL AND @prod IS NOT NULL
  AND category_id = @cat
  AND position >= 2
  AND product_id <> @prod;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @prod, 2 FROM dual
WHERE @cat IS NOT NULL AND @prod IS NOT NULL;

UPDATE catalog_category_product
SET position = 2
WHERE @cat IS NOT NULL AND @prod IS NOT NULL
  AND category_id = @cat AND product_id = @prod;

-- ===== index table: same shift, per store present for this category =====

UPDATE catalog_category_product_index
SET position = position + 1
WHERE @cat IS NOT NULL AND @prod IS NOT NULL
  AND category_id = @cat
  AND position >= 2
  AND product_id <> @prod;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @prod, 2, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND @prod IS NOT NULL
  AND i.category_id = @cat
GROUP BY i.store_id;

UPDATE catalog_category_product_index
SET position = 2
WHERE @cat IS NOT NULL AND @prod IS NOT NULL
  AND category_id = @cat AND product_id = @prod;
