---
name: eav-multiselect-source-model
description: "When creating a multiselect EAV product attribute in a migration, set source_model='eav/entity_attribute_source_table' or admin edit + getSource()->getAllOptions() will fail with \"Source model \"\"\" not found\""
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 13b64289-4508-4a4c-a367-fef41378c572
---

When adding a `frontend_input='multiselect'` EAV attribute on `catalog_product`, you **must** set `source_model='eav/entity_attribute_source_table'` on the `eav_attribute` row. Without it, `$attribute->getSource()` throws `Mage_Eav_Exception: Source model "" not found`, and the admin product-edit dropdown also fails to populate.

The `backend_model='eav/entity_attribute_backend_array'` setting handles array<->CSV serialization but does **not** provide a source — those are two separate concerns in Magento 1's EAV.

**Why:** Discovered while building migration 157 (`assessment_methods`). The existing `trainers` attribute in this repo also has `source_model=NULL` but doesn't break, because all its consumers read raw CSV from `catalog_product_entity_text` directly and never call `getSource()`. The new attribute is read in `description.phtml` via the source lookup (option_id -> label), so the missing source_model was a fatal regression until added.

**How to apply:** Any new multiselect (or `select` w/ admin-managed options) EAV migration in this repo must include in the `INSERT INTO eav_attribute`:

```sql
backend_model='eav/entity_attribute_backend_array',
source_model='eav/entity_attribute_source_table',
```

See [[funding-badges-via-tags]] for the alternative (tag-based) path that avoids EAV entirely when the values are also storefront-filterable.

Demonstrated at [migrations/157-assessment-methods-attribute.sql:26](migrations/157-assessment-methods-attribute.sql#L26).
