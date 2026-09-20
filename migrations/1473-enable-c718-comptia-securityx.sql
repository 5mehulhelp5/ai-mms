-- C718 CompTIA Certified SecurityX Training — enable on the storefront.
--
-- The course sits at status = 2 (Disabled) in the default scope (store_id = 0) with no
-- store-level override row, so flipping the default row to 1 (Enabled) is sufficient.
-- Website assignment (catalog_product_website) is already present — nothing to add.
--
-- Keyed by SKU, not entity_id: the same migration runs on every partner server (SG/MY/GH)
-- whose entity_ids have diverged. Partner sites carry no C-prefix SG catalog row for this
-- SKU, so the UPDATE matches zero rows and is a clean no-op there.
--
-- Idempotent: re-running sets status to the value it already holds.

UPDATE catalog_product_entity_int s
  JOIN catalog_product_entity e
    ON e.entity_id = s.entity_id
   SET s.value = 1
 WHERE e.sku = 'C718'
   AND s.store_id = 0
   AND s.attribute_id = (
       SELECT attribute_id FROM eav_attribute
        WHERE attribute_code = 'status'
          AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product')
   );
