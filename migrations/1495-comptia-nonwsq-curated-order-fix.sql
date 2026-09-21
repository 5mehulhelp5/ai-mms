-- FIX for 1491-comptia-category-nonwsq-curated-order.sql, which apply.php recorded as applied but which SILENTLY NO-OPPED on prod.
--
-- Root cause: apply.php splits files with preg_split('/;\s*$/m', $sql) — it only breaks on a
-- semicolon that ends a LINE. In 1491 the final VALUES row was written
--     ('C476',  25);  -- CompTIA DataAI Training
-- so the ';' had a trailing comment after it and did NOT match. The splitter therefore ran
-- past it to the next line-ending ';', gluing the whole
-- "UPDATE catalog_category_product_index ..." onto the INSERT as ONE string. PDO::exec()
-- accepts that multi-statement string, executes the INSERT, and DISCARDS the trailing UPDATE
-- without error — so the run printed OK, the ledger recorded 1491, and the storefront index
-- was never written. Only the base-table UPDATE landed, which the storefront does not read.
--
-- Rules this file follows (apply to every future migration):
--   * NEVER put a comment after a statement-terminating ';' — put it on its own line above.
--   * Keep each statement's ';' as the last character on its line.
--   * Don't rely on a @var set in one statement being visible to another; inline the lookup.
--
-- Net effect: same curated order 1491 intended. Idempotent; re-running is a no-op.
-- Resolved by url_key + SKU, so this is a clean no-op on partner sites (MY/GH).

-- 1. Register the category as curated, so the nightly CategoryOrdering sweep preserves
-- the hand-picked non-WSQ order instead of re-alphabetising it.
UPDATE core_config_data
   SET value = CONCAT(value, ',comptia-certification-prep-courses')
 WHERE path = 'mmd/category_ordering/curated_url_keys'
   AND FIND_IN_SET('comptia-certification-prep-courses', value) = 0;

-- 2. Curated positions for the 14 non-WSQ (C-) courses, continuing after the 11 TGS- rows.
DROP TEMPORARY TABLE IF EXISTS tmp_comptia_nonwsq;

CREATE TEMPORARY TABLE tmp_comptia_nonwsq (sku VARCHAR(64) PRIMARY KEY, pos INT NOT NULL);

-- Order: A+, Tech+, Network+, Security+, Cloud+, Linux+, Server+, CySA+, PenTest+,
-- SecurityX, SecAI+, Data+, Project+, DataAI.
INSERT INTO tmp_comptia_nonwsq (sku, pos) VALUES
  ('C471',  12),
  ('C402',  13),
  ('C938',  14),
  ('C628',  15),
  ('C855',  16),
  ('C1162', 17),
  ('C1048', 18),
  ('C916',  19),
  ('C1136', 20),
  ('C718',  21),
  ('C1750', 22),
  ('C923',  23),
  ('C790',  24),
  ('C476',  25);

-- What the storefront listing actually sorts by. Written for every store_id on this
-- instance, and renumbered DIRECTLY so anchor-inherited rows (no base row) are covered.
UPDATE catalog_category_product_index idx
  JOIN catalog_product_entity e ON e.entity_id = idx.product_id
  JOIN tmp_comptia_nonwsq t ON t.sku = e.sku
  JOIN catalog_category_entity_varchar uk ON uk.entity_id = idx.category_id
   AND uk.store_id = 0 AND uk.value = 'comptia-certification-prep-courses'
  JOIN eav_attribute ea ON ea.attribute_id = uk.attribute_id
   AND ea.entity_type_id = 3 AND ea.attribute_code = 'url_key'
   SET idx.position = t.pos;

-- Admin-facing source of truth.
UPDATE catalog_category_product cp
  JOIN catalog_product_entity e ON e.entity_id = cp.product_id
  JOIN tmp_comptia_nonwsq t ON t.sku = e.sku
  JOIN catalog_category_entity_varchar uk ON uk.entity_id = cp.category_id
   AND uk.store_id = 0 AND uk.value = 'comptia-certification-prep-courses'
  JOIN eav_attribute ea ON ea.attribute_id = uk.attribute_id
   AND ea.entity_type_id = 3 AND ea.attribute_code = 'url_key'
   SET cp.position = t.pos;

DROP TEMPORARY TABLE IF EXISTS tmp_comptia_nonwsq;
