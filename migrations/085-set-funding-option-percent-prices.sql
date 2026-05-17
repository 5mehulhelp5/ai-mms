-- Bulletproof fallback: write the discount percentages directly into
-- catalog_product_option_type_price so MMD_CustomOptions's *existing*
-- storefront JS (catalog-product-view-options.phtml lines 245-298)
-- applies the discount on radio click — independent of whether the
-- new MMD_SingaporePrice JS module loads correctly.
--
-- Before this migration the option values had price=0 / price_type=fixed.
-- After:
--   "Singaporean above 40 yrs old"          → price=70, price_type=percent
--   "Singaporean below 40 yrs old"          → price=50, price_type=percent
--   "Singapore PR"                           → price=50, price_type=percent
--   "non Singaporean"                        → price=0  (no row; default)
--   "SME (Singaporean/PR Direct Hire)"      → price=70, price_type=percent
--
-- Resolved by joining option_type_title to option_type_value so the
-- right rows get matched by label, not by hardcoded option_type_ids
-- (which differ per product). Idempotent — ON DUPLICATE KEY UPDATE.
--
-- The radio is also tagged with data-type="percent" via a UNION into
-- the same row's price_type column (catalog_product_option_type_price
-- IS the source of truth Magento reads to emit data-type).

-- 1. Singaporean above 40 yrs old → 70%
INSERT INTO catalog_product_option_type_price (option_type_id, store_id, price, price_type)
SELECT tv.option_type_id, 0, 70, 'percent'
FROM catalog_product_option_type_value tv
JOIN catalog_product_option_type_title tt
  ON tt.option_type_id = tv.option_type_id AND tt.store_id = 0
JOIN catalog_product_option o ON o.option_id = tv.option_id
JOIN catalog_product_option_title ot
  ON ot.option_id = o.option_id AND ot.store_id = 0
 AND ot.title = 'Funding Eligibility (Subject to Verification)'
WHERE tt.title = 'Singaporean above 40 yrs old'
ON DUPLICATE KEY UPDATE price = VALUES(price), price_type = VALUES(price_type);

-- 2. Singaporean below 40 yrs old → 50%
INSERT INTO catalog_product_option_type_price (option_type_id, store_id, price, price_type)
SELECT tv.option_type_id, 0, 50, 'percent'
FROM catalog_product_option_type_value tv
JOIN catalog_product_option_type_title tt
  ON tt.option_type_id = tv.option_type_id AND tt.store_id = 0
JOIN catalog_product_option o ON o.option_id = tv.option_id
JOIN catalog_product_option_title ot
  ON ot.option_id = o.option_id AND ot.store_id = 0
 AND ot.title = 'Funding Eligibility (Subject to Verification)'
WHERE tt.title = 'Singaporean below 40 yrs old'
ON DUPLICATE KEY UPDATE price = VALUES(price), price_type = VALUES(price_type);

-- 3. Singapore PR → 50%
INSERT INTO catalog_product_option_type_price (option_type_id, store_id, price, price_type)
SELECT tv.option_type_id, 0, 50, 'percent'
FROM catalog_product_option_type_value tv
JOIN catalog_product_option_type_title tt
  ON tt.option_type_id = tv.option_type_id AND tt.store_id = 0
JOIN catalog_product_option o ON o.option_id = tv.option_id
JOIN catalog_product_option_title ot
  ON ot.option_id = o.option_id AND ot.store_id = 0
 AND ot.title = 'Funding Eligibility (Subject to Verification)'
WHERE tt.title = 'Singapore PR'
ON DUPLICATE KEY UPDATE price = VALUES(price), price_type = VALUES(price_type);

-- 4. SME (Singaporean/PR Direct Hire) → 70%
INSERT INTO catalog_product_option_type_price (option_type_id, store_id, price, price_type)
SELECT tv.option_type_id, 0, 70, 'percent'
FROM catalog_product_option_type_value tv
JOIN catalog_product_option_type_title tt
  ON tt.option_type_id = tv.option_type_id AND tt.store_id = 0
JOIN catalog_product_option o ON o.option_id = tv.option_id
JOIN catalog_product_option_title ot
  ON ot.option_id = o.option_id AND ot.store_id = 0
 AND ot.title = 'Funding Eligibility (Subject to Verification)'
WHERE tt.title = 'SME (Singaporean/PR Direct Hire)'
ON DUPLICATE KEY UPDATE price = VALUES(price), price_type = VALUES(price_type);

-- 5. non Singaporean stays at 0. (Optional explicit row for clarity.)
INSERT INTO catalog_product_option_type_price (option_type_id, store_id, price, price_type)
SELECT tv.option_type_id, 0, 0, 'percent'
FROM catalog_product_option_type_value tv
JOIN catalog_product_option_type_title tt
  ON tt.option_type_id = tv.option_type_id AND tt.store_id = 0
JOIN catalog_product_option o ON o.option_id = tv.option_id
JOIN catalog_product_option_title ot
  ON ot.option_id = o.option_id AND ot.store_id = 0
 AND ot.title = 'Funding Eligibility (Subject to Verification)'
WHERE tt.title = 'non Singaporean'
ON DUPLICATE KEY UPDATE price = VALUES(price), price_type = VALUES(price_type);
