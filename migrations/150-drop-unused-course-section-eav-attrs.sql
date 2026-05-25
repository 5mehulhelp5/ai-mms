-- Cleanup of the four EAV attributes created in migration 149.
--
-- Migration 149 created course_lo_html, course_brochure_html,
-- course_skills_framework_html, course_wsq_funding_raw_html intended as
-- per-section storage. The architecture has since moved to per-course
-- cms/block rows (identifier convention course_<sku>_<section>) — see
-- scripts/local-dev/cms-block-phase01.php for the bootstrap and
-- app/design/frontend/ultimo/default/template/catalog/product/view.phtml
-- for the storefront reads.
--
-- view.phtml does NOT read these attributes anywhere. The admin Course
-- Details panels do NOT write them anywhere. The "Course Sections"
-- attribute group on every product attribute set is also unused after
-- the cms/block cutover.
--
-- This migration drops the four attributes and the empty attribute group.
-- The EAV value rows (catalog_product_entity_text) cascade automatically
-- on attribute_id FK delete; in practice no value rows exist since Phase 2
-- was never run against these attributes.
--
-- Idempotent: guarded DELETE statements, safe to re-run.

DELETE FROM eav_attribute
 WHERE entity_type_id = 4
   AND attribute_code IN (
       'course_lo_html',
       'course_brochure_html',
       'course_skills_framework_html',
       'course_wsq_funding_raw_html'
   );

DELETE eag FROM eav_attribute_group eag
JOIN eav_attribute_set eas ON eas.attribute_set_id = eag.attribute_set_id
WHERE eas.entity_type_id = 4
  AND eag.attribute_group_name = 'Course Sections';
