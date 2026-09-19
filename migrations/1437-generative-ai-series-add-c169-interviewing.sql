-- 1437: Generative AI Series — add C169 "Generative AI for Interviewing".
--
-- Assigns C169 to the Generative AI Series (433) and pins it at position 107,
-- inside the curated non-WSQ block from 1434, grouped with the business /
-- professional-skills courses (problem solving, creativity, design thinking)
-- and ahead of the presentation / content block. The 11 courses that were at
-- 107..117 shift down one slot to 108..118.
--
-- Resulting non-WSQ order (positions 101..118):
--   101 C013   Generative AI for Project Management
--   102 C324   Generative AI for Agile Project Management
--   103 C1234  Generative AI for Problem Solving
--   104 C1276  Generative AI for Creativity
--   105 C688   Generative AI for Design Thinking
--   106 C924   Generative AI for Agile Design Thinking
--   107 C169   Generative AI for Interviewing          <-- NEW
--   108 C329   Generative AI for Business Presentation
--   109 C439   Generative AI for Content Creation
--   110 C1176  Generative AI for Instructional Design
--   111 C364   Generative AI for Script Development and Storytelling
--   112 C1468  Generative AI for Digital Marketing
--   113 C11    Generative AI for SEO
--   114 C1373  Generative AI for Video Creation
--   115 C1311  Generative AI for Sustainability Reporting
--   116 C162   Generative AI for 3D Modeling
--   117 C152   Generative AI for Adobe Illustrator
--   118 C16    Generative AI for Adobe Photoshop
--
-- 'generative-ai-series' is ALREADY in mmd/category_ordering/curated_url_keys,
-- so MMD_RoleManager_Model_Cron_CategoryOrdering preserves this non-WSQ order
-- instead of re-alphabetising it. No config change is needed here.
--
-- The TGS- block (positions 1..17) is untouched — the sweep always sorts
-- funded courses first regardless of absolute position.
--
-- Matched by entity_id resolved from sku with TRIM() on BOTH sides: SKU 'C16 '
-- carries a trailing space on SG prod, so a bare `sku = 'C16'` match silently
-- drops that row and strands Adobe Photoshop at its old position (see 1434).
--
-- Positive positions only (negative pins die — see 1195). Business-key
-- lookups; these SKUs are SG-only, so this is a clean partner no-op.
-- Idempotent: re-running rewrites the same membership and the same positions.

SET @gen := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'generative-ai-series' LIMIT 1
);

SET @p_c169 := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C169' LIMIT 1);

-- ===== A: assign C169 to the series =====
-- A direct catalog_category_product row is required: an anchor-inherited
-- member has no position of its own, and the reindex would discard the pin.

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @gen, @p_c169, 107
WHERE @gen IS NOT NULL AND @p_c169 IS NOT NULL;

-- ===== B: pin the curated non-WSQ order 101..118 =====

UPDATE catalog_category_product ccp
JOIN catalog_product_entity p ON p.entity_id = ccp.product_id
SET ccp.position = CASE TRIM(p.sku)
  WHEN 'C013'  THEN 101
  WHEN 'C324'  THEN 102
  WHEN 'C1234' THEN 103
  WHEN 'C1276' THEN 104
  WHEN 'C688'  THEN 105
  WHEN 'C924'  THEN 106
  WHEN 'C169'  THEN 107
  WHEN 'C329'  THEN 108
  WHEN 'C439'  THEN 109
  WHEN 'C1176' THEN 110
  WHEN 'C364'  THEN 111
  WHEN 'C1468' THEN 112
  WHEN 'C11'   THEN 113
  WHEN 'C1373' THEN 114
  WHEN 'C1311' THEN 115
  WHEN 'C162'  THEN 116
  WHEN 'C152'  THEN 117
  WHEN 'C16'   THEN 118
  ELSE ccp.position
END
WHERE ccp.category_id = @gen
  AND TRIM(p.sku) IN ('C013','C324','C1234','C1276','C688','C924','C169',
                      'C329','C439','C1176','C364','C1468','C11','C1373',
                      'C1311','C162','C152','C16');

-- ===== C: mirror into the storefront index =====
-- catalog_category_product_index is what the category page actually reads;
-- without this the pin is invisible until the next full reindex.

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @gen, @p_c169, 107, 1, s.store_id, 4
FROM core_store s
WHERE s.store_id > 0 AND @gen IS NOT NULL AND @p_c169 IS NOT NULL
  AND EXISTS (
    SELECT 1 FROM catalog_product_entity_int st
    WHERE st.entity_id = @p_c169 AND st.store_id = 0
      AND st.attribute_id = (SELECT attribute_id FROM eav_attribute
        WHERE entity_type_id = 4 AND attribute_code = 'status' LIMIT 1)
      AND st.value = 1
  );

UPDATE catalog_category_product_index cpi
JOIN catalog_product_entity p ON p.entity_id = cpi.product_id
SET cpi.position = CASE TRIM(p.sku)
  WHEN 'C013'  THEN 101
  WHEN 'C324'  THEN 102
  WHEN 'C1234' THEN 103
  WHEN 'C1276' THEN 104
  WHEN 'C688'  THEN 105
  WHEN 'C924'  THEN 106
  WHEN 'C169'  THEN 107
  WHEN 'C329'  THEN 108
  WHEN 'C439'  THEN 109
  WHEN 'C1176' THEN 110
  WHEN 'C364'  THEN 111
  WHEN 'C1468' THEN 112
  WHEN 'C11'   THEN 113
  WHEN 'C1373' THEN 114
  WHEN 'C1311' THEN 115
  WHEN 'C162'  THEN 116
  WHEN 'C152'  THEN 117
  WHEN 'C16'   THEN 118
  ELSE cpi.position
END
WHERE cpi.category_id = @gen
  AND TRIM(p.sku) IN ('C013','C324','C1234','C1276','C688','C924','C169',
                      'C329','C439','C1176','C364','C1468','C11','C1373',
                      'C1311','C162','C152','C16');
