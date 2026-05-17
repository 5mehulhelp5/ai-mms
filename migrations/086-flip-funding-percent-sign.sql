-- Migration 085 wrote positive percent values for funding discounts,
-- but Magento's standard option-price math interprets positive percent
-- as ADD to base. Legacy site's working funding options use NEGATIVE
-- percent (verified by local DB inspection — 8 legacy products have
-- -70 / -50 prices for the same labels). Flip signs to match.
--
-- Net effect of price=-70, price_type=percent:
--   added option price = getProductPriceByQty() * (-70/100) = -0.7 * base
--   final = base + (-0.7 * base) = 0.3 * base   ← 70% discount ✓
--
-- Idempotent: only flips positive funding-discount rows; re-runs leave
-- already-negative rows untouched.

UPDATE catalog_product_option_type_price tp
JOIN catalog_product_option_type_value tv ON tv.option_type_id = tp.option_type_id
JOIN catalog_product_option_type_title tt
  ON tt.option_type_id = tv.option_type_id AND tt.store_id = 0
JOIN catalog_product_option o ON o.option_id = tv.option_id
JOIN catalog_product_option_title ot
  ON ot.option_id = o.option_id AND ot.store_id = 0
 AND ot.title = 'Funding Eligibility (Subject to Verification)'
SET tp.price = -ABS(tp.price)
WHERE tp.price > 0
  AND tp.price_type = 'percent'
  AND tt.title IN (
      'Singaporean above 40 yrs old',
      'Singaporean below 40 yrs old',
      'Singapore PR',
      'SME (Singaporean/PR Direct Hire)'
  );
