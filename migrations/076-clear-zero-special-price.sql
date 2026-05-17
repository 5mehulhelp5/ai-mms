-- SG-only: clear special_price=0 rows at the Singapore store scope and
-- repair the price index for the Singapore website so Fee renders
-- immediately on first page load.
--
-- Other stores (MY/GH/NG/BT/IN) follow standard Magento behaviour and
-- are NOT touched by this migration.
--
-- Symptom this fixes: on www.tertiarycourses.com.sg, products render
-- Fee = $0.00 with the catalog price ($800 etc) struck through, because
-- a row in catalog_product_entity_decimal with attribute_id=76
-- (special_price) and value=0 at the SG store scope makes Magento use
-- $0 as final_price, collapsing the GST line too.
--
-- A literal special_price of zero is never meaningful for a paid course
-- in SG. Deleting the bad SG-scope rows + repairing the SG website's
-- price index fixes the display without waiting for cron reindex.

-- 1. Drop the bad EAV rows at the SG store scope only (store_id=1).
--    Default scope (store_id=0) is left alone so we don't accidentally
--    change behaviour for other stores that inherit from it.
DELETE FROM catalog_product_entity_decimal
WHERE attribute_id = 76
  AND value = 0
  AND store_id = 1;

-- 2. Repair the price index for the SG website only (website_id=1).
--    Lift collapsed final_price back to the catalog price so the
--    storefront renders the full Fee on first paint.
UPDATE catalog_product_index_price
SET final_price = price,
    min_price   = price,
    max_price   = price
WHERE website_id = 1
  AND price > 0
  AND (final_price IS NULL OR final_price = 0 OR final_price < price);
