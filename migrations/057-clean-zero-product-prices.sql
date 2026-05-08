-- Heal courses that show $0 on the storefront with the regular price
-- struck through. Magento renders the strike-through pair when the
-- price index has final_price < price, which happens when a product
-- has special_price=0, group_price=0, tier_price=0, or a stale index
-- row left over from old data.
--
-- Fix in three steps:
--   1. Wipe any special_price <= 0 from catalog_product_entity_decimal.
--      A zero special price is never a real discount — it's bad data.
--   2. Wipe any group_price / tier_price <= 0.
--   3. Re-heal the catalog_product_index_price rows whose final_price
--      collapsed to 0 — set final_price/min_price/max_price back to the
--      regular price. A subsequent full reindex will overwrite this if
--      it's still wrong, but in steady state this matches what the
--      reindex would compute.
--
-- All three steps are idempotent: re-running on already-clean data is
-- a no-op.

-- Step 1: clear special_price <= 0
DELETE cped
FROM catalog_product_entity_decimal cped
JOIN eav_attribute ea
  ON ea.attribute_id = cped.attribute_id
 AND ea.entity_type_id = 4
 AND ea.attribute_code = 'special_price'
WHERE cped.value IS NULL OR cped.value <= 0;

-- Step 2a: clear group_price <= 0 (legacy single-table form)
DELETE FROM catalog_product_entity_group_price
WHERE value IS NULL OR value <= 0;

-- Step 2b: clear tier_price <= 0
DELETE FROM catalog_product_entity_tier_price
WHERE value IS NULL OR value <= 0;

-- Step 3: heal catalog_product_index_price rows where final_price has
-- collapsed to <= 0 but the regular price is still > 0. Restores the
-- "no discount" state so the storefront stops drawing the strike-through.
UPDATE catalog_product_index_price
   SET final_price = price,
       min_price   = price,
       max_price   = price
 WHERE price > 0
   AND (final_price IS NULL OR final_price <= 0);
