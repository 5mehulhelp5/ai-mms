-- CompTIA Certification Exam Prep (url_key comptia-certification-prep-courses):
-- set the explicit owner-specified order of the 11 funded (TGS-) courses.
-- The canonical category-ordering rule (545/1201) keeps TGS- rows ABOVE the C- block and
-- PRESERVES their existing relative order, so this renumber survives the nightly sweep.
-- The non-WSQ (C-) block is left alone: it is already alphabetical, as the rule requires.
--
-- Positions 1..11 for TGS-, matching the current C-block start (12); both the base table
-- and catalog_category_product_index are written (the storefront reads the index; the
-- index is renumbered DIRECTLY so anchor-inherited rows are covered).
-- Resolved by url_key + SKU, so this is a clean no-op on partner sites (MY/GH carry no TGS-).

SET @cat := (SELECT uk.entity_id FROM catalog_category_entity_varchar uk
  JOIN eav_attribute ea ON ea.attribute_id = uk.attribute_id
   AND ea.entity_type_id = 3 AND ea.attribute_code = 'url_key'
  WHERE uk.store_id = 0 AND uk.value = 'comptia-certification-prep-courses' LIMIT 1);

DROP TEMPORARY TABLE IF EXISTS tmp_comptia_order;
CREATE TEMPORARY TABLE tmp_comptia_order (sku VARCHAR(64) PRIMARY KEY, pos INT NOT NULL);
INSERT INTO tmp_comptia_order (sku, pos) VALUES
  ('TGS-2024048317',  1),  -- WSQ - CompTIA Certified A+ Training (Core 1 and Core 2)
  ('TGS-2023039181',  2),  -- WSQ - CompTIA Certified Security+ Training
  ('TGS-2025054472',  3),  -- WSQ - CompTIA Certified Network+ Training
  ('TGS-2023040479',  4),  -- WSQ - CompTIA Certified Network+ Training (Synchronous e-Learning)
  ('TGS-2024048316',  5),  -- WSQ - CompTIA Certified Linux+ Training
  ('TGS-2024048318',  6),  -- WSQ - CompTIA Certified Server+ Training
  ('TGS-2024049214',  7),  -- WSQ - CompTIA Certified Cloud+ Training
  ('TGS-2024049212',  8),  -- WSQ - CompTIA Certified Data+ Training
  ('TGS-2024049211',  9),  -- WSQ - CompTIA Cybersecurity Analyst (CySA+) Training
  ('TGS-2026064471', 10),  -- CASL - CompTIA PenTest+ Training
  ('TGS-2025053927', 11);  -- WSQ - CompTIA Certified SecurityX Training

-- What the storefront actually sorts by (every store_id present on this instance).
UPDATE catalog_category_product_index idx
  JOIN catalog_product_entity e ON e.entity_id = idx.product_id
  JOIN tmp_comptia_order t ON t.sku = e.sku
   SET idx.position = t.pos
 WHERE idx.category_id = @cat AND @cat IS NOT NULL;

-- Source of truth for the admin view.
UPDATE catalog_category_product cp
  JOIN catalog_product_entity e ON e.entity_id = cp.product_id
  JOIN tmp_comptia_order t ON t.sku = e.sku
   SET cp.position = t.pos
 WHERE cp.category_id = @cat AND @cat IS NOT NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_comptia_order;
