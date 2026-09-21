-- Disable course C730 "Practical Costing Essentials for Non-Finance Professionals".
-- Keyed on SKU, so this is a no-op on partner sites (MY/GH) that have no C730 row.
-- Idempotent: re-running simply re-asserts status = 2 (Disabled).

SET @c730 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C730' LIMIT 1);
SET @status_attr := (SELECT attribute_id FROM eav_attribute
                     WHERE attribute_code = 'status' AND entity_type_id = 4 LIMIT 1);

-- Flip every existing status row (default scope + any store-level override) to Disabled.
UPDATE catalog_product_entity_int
SET value = 2
WHERE @c730 IS NOT NULL
  AND entity_id = @c730
  AND attribute_id = @status_attr;

-- Guarantee a default-scope row exists even if the product never had one.
INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @status_attr, 0, @c730, 2
FROM dual
WHERE @c730 IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM (SELECT * FROM catalog_product_entity_int) x
    WHERE x.entity_id = @c730 AND x.attribute_id = @status_attr AND x.store_id = 0
  );

-- Drop it from the category listing index so it disappears without waiting for a reindex.
DELETE FROM catalog_category_product_index WHERE @c730 IS NOT NULL AND product_id = @c730;
