-- Standardise the catalog_product additional_note attribute across every
-- product and every store view. Historical values varied from "Nil" / "."
-- through course-specific notes ("Raspberry Pi", etc.); the course ops team
-- wants one canonical message everywhere so the storefront sidebar is
-- consistent.

SET @attr_id := (
    SELECT attribute_id
    FROM eav_attribute
    WHERE attribute_code = 'additional_note'
      AND entity_type_id = (
          SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product'
      )
);

SET @canonical := 'Please bring your own laptop for hands-on training. If you don''t have laptop, we can provide spare laptop for training use.';

-- Drop every store-scope override; everyone inherits the default scope.
DELETE FROM catalog_product_entity_text
WHERE attribute_id = @attr_id
  AND store_id <> 0;

-- Rewrite every default-scope row to the canonical text.
UPDATE catalog_product_entity_text
SET value = @canonical
WHERE attribute_id = @attr_id
  AND store_id = 0;

-- Backfill: any product without a default-scope row gets one.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT
    (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product'),
    @attr_id,
    0,
    e.entity_id,
    @canonical
FROM catalog_product_entity e
LEFT JOIN catalog_product_entity_text t
    ON t.entity_id = e.entity_id
   AND t.attribute_id = @attr_id
   AND t.store_id = 0
WHERE t.value_id IS NULL;
