-- C1098 (Google Cloud Certified Associate Cloud Engineer Training) — set the
-- course fee to $1400.
--
-- Why: C1098 is the non-WSQ twin of TGS-2023041024, converted 2026-09-21. It
-- runs 4 days / 30 instructional hours (9:30am - 5:30pm). The fee was $1200 and
-- is set to $1400 as instructed. Note this is the 4-day course; the catalogue's
-- $1800 band (migration 1480) applies only to 5-day C-prefix courses and is not
-- touched here.
--
-- The funded parent TGS-2023041024 keeps its own price ($1600) — the funded twin
-- is priced on its own basis and is never the reference.
--
-- EVERY scope row is updated, not just store_id = 0: a lingering store-scope
-- override would otherwise keep serving the old price.
--
-- Scoped `sku LIKE 'C%' AND sku NOT LIKE 'CASL%'` per house rule so no TGS-
-- (WSQ/CASL/IBF) or M- (partner) course can ever be touched by this file.
--
-- Idempotent: re-running writes the same value.
--
-- AFTER DEPLOY: reindex + flush, or the flat catalog serves the old fee
--   -> /reindex/api/run?flush=1&token=<mmd_reindex/api/token>
-- Verify the storefront then shows $1,400.00 and $1,526.00 incl. GST.

SET @a_price := (SELECT attribute_id FROM eav_attribute
                  WHERE attribute_code = 'price' AND entity_type_id = 4 LIMIT 1);

SET @dst := (SELECT entity_id FROM catalog_product_entity
              WHERE sku = 'C1098'
                AND sku LIKE 'C%' AND sku NOT LIKE 'CASL%' LIMIT 1);

UPDATE catalog_product_entity_decimal
   SET value = 1400.0000
 WHERE entity_id = @dst
   AND attribute_id = @a_price
   AND @dst IS NOT NULL;

-- Partner servers (MY/GH) hold no C1098 row, so @dst is NULL there and the
-- statement above is a no-op.
