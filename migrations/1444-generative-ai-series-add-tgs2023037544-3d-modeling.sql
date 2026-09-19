-- 1444: Generative AI Series — add WSQ "Generative AI for 3D Modeling"
-- (TGS-2023037544, /wsq-generative-ai-for-3d-modeling.html).
--
-- The course was in 16 other categories but not in the Generative AI Series
-- (433). Its non-WSQ twin C162 "Generative AI for 3D Modeling" was already a
-- member at position 116 — this adds the funded parent alongside it.
--
-- Pinned at 16, directly after TGS-2023039180 "WSQ - Generative AI Design for
-- Civil 3D" (15), so the two 3D/CAD courses sit together in the funded block.
-- The two courses below shift down one slot:
--
--   ...
--   14 TGS-2019503343  WSQ - Enhancing Online Presence with AI Powered SEO
--   15 TGS-2023039180  WSQ - Generative AI Design for Civil 3D
--   16 TGS-2023037544  WSQ - Generative AI for 3D Modeling        <-- NEW
--   17 TGS-2021009337  WSQ - Generative AI for Paid Search Marketing
--
-- Positions 18..24 hold DISABLED courses (status=2) that were at 17..23; they
-- are shifted too so the funded block stays contiguous. They render nowhere,
-- but leaving a collision at 17 would make the next curated edit ambiguous.
--
-- The non-WSQ block (101..118) is untouched — no renumbering needed, since the
-- insert is inside the TGS block and the sweep sorts funded first regardless of
-- absolute position.
--
-- 'generative-ai-series' is ALREADY in mmd/category_ordering/curated_url_keys,
-- so MMD_RoleManager_Model_Cron_CategoryOrdering preserves this order rather
-- than re-alphabetising. No config change needed.
--
-- Matched by entity_id resolved from TRIM(sku) on BOTH sides — SG prod carries
-- trailing spaces on some SKUs (see 1434/1437). Positive positions only
-- (negative pins die — see 1195). Business-key lookups; these SKUs are SG-only,
-- so this is a clean partner no-op. Idempotent: re-running rewrites the same
-- membership and the same positions.

SET @gen := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'generative-ai-series' LIMIT 1
);

SET @p_3d := (SELECT entity_id FROM catalog_product_entity
              WHERE TRIM(sku) = 'TGS-2023037544' LIMIT 1);

-- ===== A: assign the course to the series =====
-- A direct catalog_category_product row is required: an anchor-inherited
-- member has no position of its own, and the reindex would discard the pin.

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @gen, @p_3d, 16
WHERE @gen IS NOT NULL AND @p_3d IS NOT NULL;

-- ===== B: pin the funded block 1..17 (+ the parked disabled rows 18..24) =====

UPDATE catalog_category_product ccp
JOIN catalog_product_entity p ON p.entity_id = ccp.product_id
SET ccp.position = CASE TRIM(p.sku)
  WHEN 'TGS-2023037589' THEN 1
  WHEN 'TGS-2025056983' THEN 2
  WHEN 'TGS-2026061325' THEN 3
  WHEN 'TGS-2020503501' THEN 4
  WHEN 'TGS-2023036653' THEN 5
  WHEN 'TGS-2024049183' THEN 6
  WHEN 'TGS-2024049781' THEN 7
  WHEN 'TGS-2026065050' THEN 8
  WHEN 'TGS-2024051421' THEN 9
  WHEN 'TGS-2024045220' THEN 10
  WHEN 'TGS-2024043855' THEN 11
  WHEN 'TGS-2020505925' THEN 12
  WHEN 'TGS-2026064709' THEN 13
  WHEN 'TGS-2019503343' THEN 14
  WHEN 'TGS-2023039180' THEN 15
  WHEN 'TGS-2023037544' THEN 16
  WHEN 'TGS-2021009337' THEN 17
  WHEN 'C167'           THEN 18
  WHEN 'C154'           THEN 19
  WHEN 'C037'           THEN 20
  WHEN 'C505'           THEN 21
  WHEN 'C802'           THEN 22
  WHEN 'C597'           THEN 23
  WHEN 'C1177'          THEN 24
  ELSE ccp.position
END
WHERE ccp.category_id = @gen
  AND TRIM(p.sku) IN ('TGS-2023037589','TGS-2025056983','TGS-2026061325',
                      'TGS-2020503501','TGS-2023036653','TGS-2024049183',
                      'TGS-2024049781','TGS-2026065050','TGS-2024051421',
                      'TGS-2024045220','TGS-2024043855','TGS-2020505925',
                      'TGS-2026064709','TGS-2019503343','TGS-2023039180',
                      'TGS-2023037544','TGS-2021009337',
                      'C167','C154','C037','C505','C802','C597','C1177');

-- ===== C: mirror into the storefront index =====
-- catalog_category_product_index is what the category page actually reads;
-- without this the pin is invisible until the next full reindex.

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @gen, @p_3d, 16, 1, s.store_id, 4
FROM core_store s
WHERE s.store_id > 0 AND @gen IS NOT NULL AND @p_3d IS NOT NULL
  AND EXISTS (
    SELECT 1 FROM catalog_product_entity_int st
    WHERE st.entity_id = @p_3d AND st.store_id = 0
      AND st.attribute_id = (SELECT attribute_id FROM eav_attribute
        WHERE entity_type_id = 4 AND attribute_code = 'status' LIMIT 1)
      AND st.value = 1
  );

UPDATE catalog_category_product_index cpi
JOIN catalog_product_entity p ON p.entity_id = cpi.product_id
SET cpi.position = CASE TRIM(p.sku)
  WHEN 'TGS-2023037589' THEN 1
  WHEN 'TGS-2025056983' THEN 2
  WHEN 'TGS-2026061325' THEN 3
  WHEN 'TGS-2020503501' THEN 4
  WHEN 'TGS-2023036653' THEN 5
  WHEN 'TGS-2024049183' THEN 6
  WHEN 'TGS-2024049781' THEN 7
  WHEN 'TGS-2026065050' THEN 8
  WHEN 'TGS-2024051421' THEN 9
  WHEN 'TGS-2024045220' THEN 10
  WHEN 'TGS-2024043855' THEN 11
  WHEN 'TGS-2020505925' THEN 12
  WHEN 'TGS-2026064709' THEN 13
  WHEN 'TGS-2019503343' THEN 14
  WHEN 'TGS-2023039180' THEN 15
  WHEN 'TGS-2023037544' THEN 16
  WHEN 'TGS-2021009337' THEN 17
  ELSE cpi.position
END
WHERE cpi.category_id = @gen
  AND TRIM(p.sku) IN ('TGS-2023037589','TGS-2025056983','TGS-2026061325',
                      'TGS-2020503501','TGS-2023036653','TGS-2024049183',
                      'TGS-2024049781','TGS-2026065050','TGS-2024051421',
                      'TGS-2024045220','TGS-2024043855','TGS-2020505925',
                      'TGS-2026064709','TGS-2019503343','TGS-2023039180',
                      'TGS-2023037544','TGS-2021009337');
