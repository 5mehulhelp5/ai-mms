-- Flip course_image_url EAV attribute from Global (is_global=1) to Store View
-- (is_global=0) scope. Required so the bulk cover generator can save a
-- different cover URL per country store — until now every store read the
-- same scope-0 value, causing Malaysia's HRDF cover to bleed into Ghana,
-- Nigeria, Bhutan, and India.
--
-- After this migration the bulkRunAction passes the selected store_id to
-- saveAttribute. EAV then stores the URL on a per-store row, with the
-- scope-0 value remaining as the fallback default for stores that haven't
-- been bulk-regenerated yet.
--
-- The is_global flag lives on catalog_eav_attribute (the product-specific
-- EAV extension), not the base eav_attribute table.
--
-- Idempotent: re-running is a no-op (UPDATE matches zero rows once flipped).
-- Existing scope-0 values are preserved untouched.

UPDATE catalog_eav_attribute cea
  JOIN eav_attribute ea ON ea.attribute_id = cea.attribute_id
   SET cea.is_global = 0
 WHERE ea.attribute_code = 'course_image_url'
   AND ea.entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product')
   AND cea.is_global <> 0;
