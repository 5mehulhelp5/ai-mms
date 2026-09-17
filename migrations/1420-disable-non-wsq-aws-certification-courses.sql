-- Disable all non-WSQ (C-prefix) AWS certification courses on the AWS
-- Certification Exams category page (aws-certification-exams.html).
--
-- The WSQ (TGS-) AWS courses in the same category stay enabled -- this only
-- touches the C-prefix exam-prep courses.
--
-- SG-only: guarded on store_id 1 / code 'singapore', so MY/GH are a no-op
-- (partner catalogs are separate DBs anyway, but the guard keeps this
-- migration file safe to ship everywhere).

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @status_attr := (
    SELECT attribute_id FROM eav_attribute
    WHERE attribute_code = 'status'
      AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product')
);

INSERT INTO catalog_product_entity_int (entity_type_id, entity_id, attribute_id, store_id, value)
SELECT e.entity_type_id, e.entity_id, @status_attr, 0, 2
FROM catalog_product_entity e
WHERE @sg = 1
  AND @status_attr IS NOT NULL
  AND TRIM(e.sku) IN (
      'C14', 'C19', 'C279', 'C371', 'C503', 'C635',
      'C1041', 'C1330', 'C1391', 'C1392', 'C1393', 'C1407'
  )
ON DUPLICATE KEY UPDATE value = 2;
