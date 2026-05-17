-- Add `enable_sg_funding` product attribute and auto-enable it for
-- every TGS-* SKU so MMD_SingaporePrice can provision the standard
-- Funding Eligibility custom option on save (replacing the
-- option-templates flow for SG funding).
--
-- Idempotent: every INSERT uses ON DUPLICATE KEY UPDATE, so re-runs
-- against a DB that already has the attribute are a no-op.
--
-- Behaviour after this migration:
--   1. New attribute `enable_sg_funding` (yes/no) appears in admin
--      Product Edit → General group.
--   2. Existing TGS-* simple products get the attribute set to Yes,
--      but the funding custom-option is NOT created here (would
--      require row-by-row inserts across catalog_product_option,
--      catalog_product_option_title, catalog_product_option_type_value
--      and catalog_product_option_type_title). Instead the observer
--      MMD_SingaporePrice_Model_Observer::onProductSaveAfter creates
--      the option the next time each product is saved in admin.
--      Admins can bulk-trigger this via the mass-update action
--      "Save selected products" — no manual editing needed.
--   3. Products without enable_sg_funding=1 are untouched.

-- 1. Create the attribute row in eav_attribute.
INSERT INTO eav_attribute
    (entity_type_id, attribute_code, attribute_model, backend_model, backend_type,
     backend_table, frontend_model, frontend_input, frontend_label, frontend_class,
     source_model, is_required, is_user_defined, default_value, is_unique, note)
SELECT
    4, 'enable_sg_funding', NULL, '', 'int',
    NULL, NULL, 'boolean', 'Enable SG Funding Discounts', NULL,
    'eav/entity_attribute_source_boolean', 0, 1, '0', 0,
    'Auto-create the Funding Eligibility radios on the storefront for this product. SG / Infotech stores only.'
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='enable_sg_funding'
);

-- 2. Add it to the catalog_eav_attribute table (extends eav_attribute).
INSERT INTO catalog_eav_attribute
    (attribute_id, frontend_input_renderer, is_global, is_visible, is_searchable,
     is_filterable, is_comparable, is_visible_on_front, is_html_allowed_on_front,
     is_used_for_price_rules, is_filterable_in_search, used_in_product_listing,
     used_for_sort_by, is_configurable, apply_to, is_visible_in_advanced_search,
     position, is_wysiwyg_enabled, is_used_for_promo_rules)
SELECT
    a.attribute_id, NULL, 0, 1, 0,
    0, 0, 0, 0,
    0, 0, 0,
    0, 0, 'simple,virtual,downloadable', 0,
    0, 0, 0
FROM eav_attribute a
WHERE a.entity_type_id=4 AND a.attribute_code='enable_sg_funding'
  AND NOT EXISTS (SELECT 1 FROM catalog_eav_attribute WHERE attribute_id=a.attribute_id);

-- 3. Attach it to every attribute set under the General group (group_id
--    in the "General" group of each attribute_set). We pick the first
--    group of each set as a safe default; admins can rearrange later.
INSERT INTO eav_entity_attribute (attribute_set_id, attribute_group_id, attribute_id, sort_order)
SELECT s.attribute_set_id, g.attribute_group_id, a.attribute_id, 200
FROM eav_attribute_set s
JOIN eav_attribute_group g
  ON g.attribute_set_id = s.attribute_set_id
 AND g.attribute_group_name = 'General'
JOIN eav_attribute a
  ON a.entity_type_id = s.entity_type_id
 AND a.attribute_code = 'enable_sg_funding'
WHERE s.entity_type_id = 4
  AND NOT EXISTS (
      SELECT 1 FROM eav_entity_attribute ea
      WHERE ea.attribute_set_id = s.attribute_set_id
        AND ea.attribute_id = a.attribute_id
  );

-- 4. Auto-enable for every TGS-* SKU. Sets the attribute value to 1 at
--    the default scope (store_id=0) so it inherits everywhere.
INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, a.attribute_id, 0, p.entity_id, 1
FROM catalog_product_entity p
CROSS JOIN eav_attribute a
WHERE a.entity_type_id = 4
  AND a.attribute_code = 'enable_sg_funding'
  AND p.sku LIKE 'TGS-%'
ON DUPLICATE KEY UPDATE value = 1;
