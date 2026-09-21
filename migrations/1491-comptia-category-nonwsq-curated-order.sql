-- CompTIA Certification Exam Prep (url_key comptia-certification-prep-courses, SG cat 30):
-- owner-specified CURATED order for the 14 non-WSQ (C-) courses — exam-progression order
-- (A+ -> Tech+ -> Network+ -> Security+ -> ... -> specialisations), NOT alphabetical.
--
-- Two halves, both required:
--   1. Register the category in mmd/category_ordering/curated_url_keys. Without this the
--      nightly MMD_RoleManager_Model_Cron_CategoryOrdering sweep (01:00 UTC) re-alphabetises
--      the C-block and the curated order is gone within a day. The cron honours this list
--      (_curatedCategoryIds / _curatedOrderExpr) by ordering curated non-TGS rows by their
--      EXISTING position instead of by name; WSQ-first is still enforced either way.
--   2. Write the positions themselves, continuing after the 11 TGS- rows pinned by 1490.
--
-- Positions 12..25 so the funded block (1..11) is untouched. Both the storefront-facing
-- index and the admin-facing base table are written; the index is renumbered DIRECTLY so
-- anchor-inherited rows (no base row) are covered.
-- Resolved by url_key + SKU: a clean no-op on partner sites lacking this category/these SKUs.

-- 1. curated allow-list — append idempotently, preserving whatever is already there.
UPDATE core_config_data
   SET value = CONCAT(value, ',comptia-certification-prep-courses')
 WHERE path = 'mmd/category_ordering/curated_url_keys'
   AND FIND_IN_SET('comptia-certification-prep-courses', value) = 0;

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'default', 0, 'mmd/category_ordering/curated_url_keys', 'comptia-certification-prep-courses'
  FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM (SELECT 1 FROM core_config_data
        WHERE path = 'mmd/category_ordering/curated_url_keys' LIMIT 1) x);

-- 2. the curated positions.
SET @cat := (SELECT uk.entity_id FROM catalog_category_entity_varchar uk
  JOIN eav_attribute ea ON ea.attribute_id = uk.attribute_id
   AND ea.entity_type_id = 3 AND ea.attribute_code = 'url_key'
  WHERE uk.store_id = 0 AND uk.value = 'comptia-certification-prep-courses' LIMIT 1);

DROP TEMPORARY TABLE IF EXISTS tmp_comptia_nonwsq;
CREATE TEMPORARY TABLE tmp_comptia_nonwsq (sku VARCHAR(64) PRIMARY KEY, pos INT NOT NULL);
INSERT INTO tmp_comptia_nonwsq (sku, pos) VALUES
  ('C471',  12),  -- CompTIA A+ Cert Prep Training (Core 1 and Core 2)
  ('C402',  13),  -- CompTIA Tech+ Training
  ('C938',  14),  -- CompTIA Network+ Training
  ('C628',  15),  -- CompTIA Security+ Exam Prep
  ('C855',  16),  -- CompTIA Cloud+ Training
  ('C1162', 17),  -- CompTIA Linux+ Training
  ('C1048', 18),  -- CompTIA Server+ Training
  ('C916',  19),  -- CompTIA Cybersecurity Analyst (CySA+) Training
  ('C1136', 20),  -- CompTIA PenTest+ Training
  ('C718',  21),  -- CompTIA Certified SecurityX Training
  ('C1750', 22),  -- CompTIA SecAI+ Training
  ('C923',  23),  -- CompTIA Data+ Training
  ('C790',  24),  -- CompTIA Project+ Training
  ('C476',  25);  -- CompTIA DataAI Training

UPDATE catalog_category_product_index idx
  JOIN catalog_product_entity e ON e.entity_id = idx.product_id
  JOIN tmp_comptia_nonwsq t ON t.sku = e.sku
   SET idx.position = t.pos
 WHERE idx.category_id = @cat AND @cat IS NOT NULL;

UPDATE catalog_category_product cp
  JOIN catalog_product_entity e ON e.entity_id = cp.product_id
  JOIN tmp_comptia_nonwsq t ON t.sku = e.sku
   SET cp.position = t.pos
 WHERE cp.category_id = @cat AND @cat IS NOT NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_comptia_nonwsq;
