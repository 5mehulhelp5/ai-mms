-- Follow-up to migration 076: also clear special_price=0 rows at the
-- default scope (store_id=0). Migration 076 only cleaned store_id=1
-- (SG store-scope) to be conservative, but on prod the broken
-- products had their special_price=0 row saved at the default scope,
-- which propagates down to every store that doesn't override.
--
-- Verified locally: same SG store_code='singapore' setup, but local DB
-- has no special_price=0 rows at any scope, and SG product pages
-- render productPrice correctly (= getPrice). On prod, the broken
-- product page reports "productPrice":0, "productOldPrice":800 — the
-- only way Magento computes that is special_price=0 in EAV.
--
-- A literal special_price=0 is never meaningful for a paid training
-- course in any of our stores (SG/MY/GH/NG/BT/IN). Cleared globally;
-- idempotent (deleting absent rows is a no-op).

DELETE FROM catalog_product_entity_decimal
WHERE attribute_id = 76
  AND value = 0;

-- Repair the price index across ALL websites so any collapsed
-- final_price snaps back to catalog price on first paint, without
-- waiting for the price reindex cron.
UPDATE catalog_product_index_price
SET final_price = price,
    min_price   = price,
    max_price   = price
WHERE price > 0
  AND (final_price IS NULL OR final_price = 0 OR final_price < price);
