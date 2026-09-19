-- 1434: Generative AI Series — curated non-WSQ order + disable 3 retired courses.
--
-- A) Disable 3 non-WSQ courses catalog-wide (status = 2, store_id = 0):
--      C037  Generative AI for Concept Art
--      C802  Generative AI for LinkedIn Lead Generation
--      C505  Generative AI for Curriculum Development
--    Disabling is catalog-wide, not a category unassign — the courses are
--    retired, so they must drop off every listing and their own product
--    pages, not just this series. Their category rows are left in place so
--    a future re-enable restores them without re-assignment.
--
-- B) Pin the requested 17-course non-WSQ order in the Generative AI Series
--    at positions 101..117 — after the TGS- block (17 rows), which the
--    nightly sweep always sorts first regardless of absolute position.
--
-- 'generative-ai-series' is ALREADY in mmd/category_ordering/curated_url_keys,
-- so MMD_RoleManager_Model_Cron_CategoryOrdering preserves this non-WSQ order
-- instead of re-alphabetising it (the curated exemption is live in the cron —
-- see _curatedOrderExpr()). No config change is needed here.
--
-- Matched by entity_id, resolved from sku with TRIM() on BOTH sides: SKU
-- 'C16 ' carries a trailing space on SG prod, so a bare `sku = 'C16'` or
-- `sku IN (...)` match silently drops that row and leaves Adobe Photoshop
-- stranded at its old position.
--
-- Positive positions only (negative pins die — see 1195). Business-key
-- lookups; these SKUs are SG-only, so this is a clean partner no-op.
-- Idempotent: re-running rewrites the same positions and statuses.

SET @a_status := (SELECT attribute_id FROM eav_attribute
  WHERE entity_type_id = 4 AND attribute_code = 'status' LIMIT 1);

SET @gen := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'generative-ai-series' LIMIT 1
);

-- ===== A: disable the 3 retired non-WSQ courses =====

UPDATE catalog_product_entity_int s
JOIN catalog_product_entity p ON p.entity_id = s.entity_id
SET s.value = 2
WHERE s.attribute_id = @a_status
  AND s.store_id = 0
  AND TRIM(p.sku) IN ('C037', 'C802', 'C505');

-- Clear any store-scoped status override that would re-enable the course on
-- the storefront despite the store-0 disable above.
UPDATE catalog_product_entity_int s
JOIN catalog_product_entity p ON p.entity_id = s.entity_id
SET s.value = 2
WHERE s.attribute_id = @a_status
  AND s.store_id <> 0
  AND TRIM(p.sku) IN ('C037', 'C802', 'C505');

-- Drop them from the storefront-facing index so the listing stops showing
-- them before the next reindex runs.
DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE TRIM(p.sku) IN ('C037', 'C802', 'C505');

-- ===== B: pin the curated non-WSQ order (101..117), after the TGS block =====

DROP TEMPORARY TABLE IF EXISTS tmp_gen_order;
CREATE TEMPORARY TABLE tmp_gen_order (
  product_id INT NOT NULL PRIMARY KEY,
  pos        INT NOT NULL
);

INSERT INTO tmp_gen_order (product_id, pos)
SELECT p.entity_id, o.pos
FROM (
            SELECT 'C013'  AS sku, 101 AS pos
  UNION ALL SELECT 'C324',  102
  UNION ALL SELECT 'C1234', 103
  UNION ALL SELECT 'C1276', 104
  UNION ALL SELECT 'C688',  105
  UNION ALL SELECT 'C924',  106
  UNION ALL SELECT 'C329',  107
  UNION ALL SELECT 'C439',  108
  UNION ALL SELECT 'C1176', 109
  UNION ALL SELECT 'C364',  110
  UNION ALL SELECT 'C1468', 111
  UNION ALL SELECT 'C11',   112
  UNION ALL SELECT 'C1373', 113
  UNION ALL SELECT 'C1311', 114
  UNION ALL SELECT 'C162',  115
  UNION ALL SELECT 'C152',  116
  UNION ALL SELECT 'C16',   117
) o
JOIN catalog_product_entity p ON TRIM(p.sku) = o.sku;

UPDATE catalog_category_product cp
JOIN tmp_gen_order t ON t.product_id = cp.product_id
SET cp.position = t.pos
WHERE cp.category_id = @gen AND @gen IS NOT NULL;

UPDATE catalog_category_product_index i
JOIN tmp_gen_order t ON t.product_id = i.product_id
SET i.position = t.pos
WHERE i.category_id = @gen AND @gen IS NOT NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_gen_order;
