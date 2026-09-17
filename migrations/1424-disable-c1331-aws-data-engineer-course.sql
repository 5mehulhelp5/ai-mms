-- Disable the non-WSQ AWS Certified Data Engineer Associate course (C1331).
--
-- Requested 2026-09-18. Follow-up to migration 1420, which disabled the
-- C-prefix AWS certification courses (C14, C19, C279, C371, C503, C635, C1041,
-- C1330, C1391, C1392, C1393, C1407) but MISSED C1331 -- it sits in the "AWS"
-- category (183) under Cloud Computing rather than on the AWS Certification
-- Exams page that 1420 worked from, so it stayed enabled:
--
--   C1331  "AWS Certified Data Engineer Associate Training"
--          aws-certified-data-engineer-associate-exam-prep.html
--
-- With this, every C-prefix AWS certification course is disabled; the WSQ (TGS-)
-- AWS courses stay enabled, exactly as in 1420.
--
-- NOTE: there is a WSQ counterpart with the same course name --
-- TGS-2025053209 "WSQ - AWS Certified Data Engineer Associate Training" -- which
-- remains ENABLED. Matching is by SKU, never by name, so the funded course is
-- untouched.
--
-- Same mechanics as 1420: set status = 2 (Disabled) at store_id 0 (default
-- scope), via INSERT ... ON DUPLICATE KEY UPDATE so it is idempotent whether or
-- not the row already exists. Magento's product URL keeps resolving to a 404
-- for a disabled product; no rewrite work is needed or wanted here (unlike a
-- retired CATEGORY, a disabled course is expected to 404 -- adding a 301 to an
-- unrelated listing would be misleading to a visitor who wanted this course).
--
-- SG-only: guarded on store_id 1 / code 'singapore', so MY/GH are a no-op.

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
  AND TRIM(e.sku) = 'C1331'
ON DUPLICATE KEY UPDATE value = 2;

-- Clear any store-scope override that would keep it enabled on the storefront.
UPDATE catalog_product_entity_int i
  JOIN catalog_product_entity e ON e.entity_id = i.entity_id
   SET i.value = 2
 WHERE @sg = 1 AND @status_attr IS NOT NULL
   AND i.attribute_id = @status_attr AND i.store_id <> 0
   AND TRIM(e.sku) = 'C1331';

-- Drop any search-term redirect aimed at the retired course page so those terms
-- fall back to normal search results instead of 404-ing
-- (feedback_search_redirects_rot_when_course_disabled).
UPDATE catalogsearch_query SET redirect = ''
 WHERE @sg = 1
   AND redirect LIKE '%/aws-certified-data-engineer-associate-exam-prep.html'
   AND redirect IS NOT NULL AND redirect <> '';
