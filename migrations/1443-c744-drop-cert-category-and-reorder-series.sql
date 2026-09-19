-- 1443: Follow-up to 1442. C744 is no longer a certification course
-- ("Claude Certified Associate - Foundations" -> "Claude Design for UX/UI"),
-- so it must leave the cert surfaces 1442 left untouched:
--
--   A) Drop it from the "Claude Certification Exam Prep" category -- it is not
--      exam prep any more. Removes the membership row, the index mirror and the
--      category-scoped is_system rewrite that 1442's refreshProductRewrite minted.
--   B) Move its Claude AI Series pin out of the certification block (prod pos 13,
--      ahead of C437) into the non-cert block, after the masterclasses (pos 12).
--      The cert rows shift down one so no position collides.
--
-- Prod order before:  ...C1417(11) C141(12) C744(13) C437(14)
--              after: ...C1417(11) C141(12) C744(13->stays) C437(14)
-- C744 already sits directly after the masterclass/course block, so only the
-- semantic grouping changes -- the pin is re-asserted explicitly so a later
-- curated sweep cannot re-sort it back into the cert group.
--
-- claude-ai-series is in mmd/category_ordering/curated_url_keys, so the nightly
-- sweep leaves these pins alone (it still forces WSQ first, which holds here).
-- Writes BOTH catalog_category_product and catalog_category_product_index.
-- Business-key lookups -- clean no-op on partner sites. Idempotent.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C744');

-- ---------------------------------------------------------- A) leave cert cat
SET @certcat := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='claude-certification-exam-prep-courses' LIMIT 1);

DELETE FROM catalog_category_product
WHERE category_id=@certcat AND product_id=@e AND @certcat IS NOT NULL AND @e IS NOT NULL;

DELETE FROM catalog_category_product_index
WHERE category_id=@certcat AND product_id=@e AND @certcat IS NOT NULL AND @e IS NOT NULL;

-- The category-scoped rewrite would otherwise keep serving the course under the
-- cert category path.
DELETE FROM core_url_rewrite
WHERE product_id=@e AND category_id=@certcat AND is_system=1
  AND @certcat IS NOT NULL AND @e IS NOT NULL;

-- ---------------------------------------------------------- B) series pin
SET @series := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='claude-ai-series' LIMIT 1);

-- Re-assert the non-cert block (masterclasses + courses, then C744), with the
-- certification rows after it. Positive positions only -- negative pins die on
-- reindex (see 1195).
UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id=cp.product_id
SET cp.position = CASE p.sku
      WHEN 'C1382' THEN 8   -- Claude Cowork Masterclass
      WHEN 'C201'  THEN 9   -- Claude Design Masterclass
      WHEN 'C197'  THEN 10  -- Claude Microsoft 365 Masterclass
      WHEN 'C1417' THEN 11  -- Claude Code Masterclass
      WHEN 'C141'  THEN 12  -- Claude Cowork for Digital Marketing
      WHEN 'C744'  THEN 13  -- Claude Design for UX/UI  (was a cert, now a course)
      WHEN 'C437'  THEN 14  -- Claude Certified Architect - Foundations
      WHEN 'C364'  THEN 15  -- Claude Certified Architect - Professional
      WHEN 'C439'  THEN 16  -- Claude Certified Developer - Foundations
    END
WHERE cp.category_id=@series AND @series IS NOT NULL
  AND p.sku IN ('C1382','C201','C197','C1417','C141','C744','C437','C364','C439');

UPDATE catalog_category_product_index ci
JOIN catalog_product_entity p ON p.entity_id=ci.product_id
SET ci.position = CASE p.sku
      WHEN 'C1382' THEN 8
      WHEN 'C201'  THEN 9
      WHEN 'C197'  THEN 10
      WHEN 'C1417' THEN 11
      WHEN 'C141'  THEN 12
      WHEN 'C744'  THEN 13
      WHEN 'C437'  THEN 14
      WHEN 'C364'  THEN 15
      WHEN 'C439'  THEN 16
    END
WHERE ci.category_id=@series AND @series IS NOT NULL
  AND p.sku IN ('C1382','C201','C197','C1417','C141','C744','C437','C364','C439');
