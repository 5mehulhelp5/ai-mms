-- C1433 is a NON-WSQ course: strip the inlined WSQ sections from `prerequisite`.
--
-- The recycled product entity carried four WSQ blocks baked into the field:
--   <h2>WSQ Funding Validity Period</h2>  (expired: 15 Aug 2020 - 14 Aug 2024)
--   <h2>WSQ Course Fee Funding</h2>       (SkillsFuture / PSEA / Absentee Payroll)
--   <h2>WSQ Assessment</h2>               (a non-WSQ course has no assessment)
-- plus a "Promo cannot be applied to WSQ courses" line and a stale "basic Python
-- knowledge" requirement inherited from a previous life (this is a Power BI course).
--
-- The genuine Prerequisite and Mode of Training copy is PRESERVED and rewritten
-- for Power BI. Funding for this course lives only in the Funding block, which
-- redirects to the WSQ twin (see 1509).
--
-- Idempotent: guarded on the WSQ marker, so a re-run matches nothing.

SET @pid  := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C1433');
SET @a_pre := (SELECT attribute_id FROM eav_attribute
                WHERE attribute_code = 'prerequisite' AND entity_type_id = 4);

UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<h2>Prerequisite</h2>',
     '<p>The learner must meet the minimum requirement below :</p>',
     '<ul>',
     '<li>At least O levels and above education</li>',
     '<li>Read, write, speak and understand English</li>',
     '<li>Basic familiarity with spreadsheets and working with data</li>',
     '</ul>',
     '<h2>Mode of Training</h2>',
     '<p>Instructor Classroom Training</p>')
 WHERE entity_id = @pid
   AND attribute_id = @a_pre
   AND value LIKE '%WSQ Funding Validity Period%';
