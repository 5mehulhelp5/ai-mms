-- FIX for 1490, which hit the same apply.php splitter trap as 1491.
--
-- 1490's TGS- VALUES list ended with a ';' followed by a trailing comment, so its
-- "UPDATE catalog_category_product_index ..." was glued onto the INSERT and silently
-- discarded by PDO::exec(). Only the base-table UPDATE ran. The storefront LOOKED
-- correct anyway because the nightly CategoryOrdering sweep preserves the funded
-- block's existing relative INDEX order -- which happened to already match. That is
-- coincidence, not correctness: the index was never actually pinned, so any future
-- reindex or drift would resurface the old order.
--
-- This re-applies the intended funded order to the INDEX explicitly.
-- See feedback_migration_semicolon_trailing_comment_swallows_next_statement.
-- Every ';' below is the last character on its line. Idempotent.
-- Resolved by url_key + SKU: a clean no-op on partner sites (MY/GH carry no TGS-).

DROP TEMPORARY TABLE IF EXISTS tmp_comptia_wsq;

CREATE TEMPORARY TABLE tmp_comptia_wsq (sku VARCHAR(64) PRIMARY KEY, pos INT NOT NULL);

-- A+, Security+, Network+, Network+ (Sync e-Learning), Linux+, Server+, Cloud+,
-- Data+, CySA+, PenTest+ (CASL), SecurityX.
INSERT INTO tmp_comptia_wsq (sku, pos) VALUES
  ('TGS-2024048317',  1),
  ('TGS-2023039181',  2),
  ('TGS-2025054472',  3),
  ('TGS-2023040479',  4),
  ('TGS-2024048316',  5),
  ('TGS-2024048318',  6),
  ('TGS-2024049214',  7),
  ('TGS-2024049212',  8),
  ('TGS-2024049211',  9),
  ('TGS-2026064471', 10),
  ('TGS-2025053927', 11);

UPDATE catalog_category_product_index idx
  JOIN catalog_product_entity e ON e.entity_id = idx.product_id
  JOIN tmp_comptia_wsq t ON t.sku = e.sku
  JOIN catalog_category_entity_varchar uk ON uk.entity_id = idx.category_id
   AND uk.store_id = 0 AND uk.value = 'comptia-certification-prep-courses'
  JOIN eav_attribute ea ON ea.attribute_id = uk.attribute_id
   AND ea.entity_type_id = 3 AND ea.attribute_code = 'url_key'
   SET idx.position = t.pos;

UPDATE catalog_category_product cp
  JOIN catalog_product_entity e ON e.entity_id = cp.product_id
  JOIN tmp_comptia_wsq t ON t.sku = e.sku
  JOIN catalog_category_entity_varchar uk ON uk.entity_id = cp.category_id
   AND uk.store_id = 0 AND uk.value = 'comptia-certification-prep-courses'
  JOIN eav_attribute ea ON ea.attribute_id = uk.attribute_id
   AND ea.entity_type_id = 3 AND ea.attribute_code = 'url_key'
   SET cp.position = t.pos;

DROP TEMPORARY TABLE IF EXISTS tmp_comptia_wsq;
