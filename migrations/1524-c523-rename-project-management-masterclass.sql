-- 1524: C523 -> "Project Management Masterclass"
--
-- Renames the non-WSQ PMP twin, re-slugs it with a permanent 301 from the old
-- URL, re-prices it to $1400, restates the course as 4 days / 30 instructional
-- hours (9:30am-5:30pm, the non-WSQ house figure), and copies the overview +
-- topics from its WSQ parent TGS-2024045797 so both catalogue entries describe
-- the same course. The stale copy cited PMBOK 6th Edition; the parent is built
-- against the PMI ECO July 2026.
--
-- SG production only; keyed by SKU so a partner site with no C523 no-ops.
-- Idempotent: re-running changes nothing.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C523' LIMIT 1);

-- name
SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='name'
   AND entity_type_id=(SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product'));
UPDATE catalog_product_entity_varchar
   SET value = 'Project Management Masterclass'
 WHERE attribute_id = @a_name AND entity_id = @pid AND @pid IS NOT NULL;

-- url_key
SET @a_url := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_key'
   AND entity_type_id=(SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product'));
UPDATE catalog_product_entity_varchar
   SET value = 'project-management-masterclass'
 WHERE attribute_id = @a_url AND entity_id = @pid AND @pid IS NOT NULL;

-- meta_title
SET @a_mt := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_title'
   AND entity_type_id=(SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product'));
UPDATE catalog_product_entity_varchar
   SET value = 'Project Management Masterclass'
 WHERE attribute_id = @a_mt AND entity_id = @pid AND @pid IS NOT NULL;

-- meta_description: no day count, <=255 chars
SET @a_md := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_description'
   AND entity_type_id=(SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product'));
UPDATE catalog_product_entity_varchar
   SET value = 'Project Management Masterclass in Singapore. Master the full project lifecycle and prepare for the PMI PMP exam - governance, planning, risk, delivery and closure, with 24 hands-on labs at Tertiary Courses Singapore.'
 WHERE attribute_id = @a_md AND entity_id = @pid AND @pid IS NOT NULL;

-- duration: 4 x 7.5 = 30 instructional hours (was 35)
SET @a_dur := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='duration'
   AND entity_type_id=(SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product'));
UPDATE catalog_product_entity_varchar
   SET value = '30'
 WHERE attribute_id = @a_dur AND entity_id = @pid AND @pid IS NOT NULL;

-- sessions stays 4 (4-day course) - asserted, not changed

-- price 1200 -> 1400 (every scope row)
SET @a_price := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='price'
   AND entity_type_id=(SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product'));
UPDATE catalog_product_entity_decimal
   SET value = 1400.0000
 WHERE attribute_id = @a_price AND entity_id = @pid AND @pid IS NOT NULL;

-- overview + topics copied from the WSQ parent TGS-2024045797
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description'
   AND entity_type_id=(SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product'));
UPDATE catalog_product_entity_text
   SET value = '<p>This course, Project Management Professional Training, is designed for aspiring project managers to gain critical skills needed for PMP certification. The course covers the full project lifecycle, starting from aligning projects with business objectives and identifying stakeholders to developing comprehensive project plans. Learners will explore project governance, compliance, and the strategic value of projects within an organization.</p>\n<p>In the second half, participants will focus on executing and monitoring projects, honing leadership skills, managing team performance, and resolving conflicts. The course also covers risk management, project change control, and successful project closure, with an emphasis on knowledge transfer and benefits realization. This training prepares participants for the PMP certification and ensures they are equipped to manage medium-scale projects effectively.</p>'
 WHERE attribute_id = @a_short AND entity_id = @pid AND @pid IS NOT NULL;

SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='description'
   AND entity_type_id=(SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product'));
UPDATE catalog_product_entity_text
   SET value = '<!-- LSN_DATA: [{"title":"Topic 1: Business Environment","subsecs":[{"title":"Foundation","links":[]},{"title":"Strategic Alignment","links":[]},{"title":"Project Benefits and Value","links":[]},{"title":"Organization Culture and Change Management","links":[]},{"title":"Project Governance","links":[]},{"title":"Project Compliance","links":[]}]},{"title":"Topic 2: Start the Project","subsecs":[{"title":"Identify and Engage Stakeholders","links":[]},{"title":"Form the Team","links":[]},{"title":"Build Shared Understanding","links":[]},{"title":"Determine Project Approach","links":[]}]},{"title":"Topic 3: Plan the Project","subsecs":[{"title":"Planning the Project","links":[]},{"title":"Scope","links":[]},{"title":"Schedule & Resources","links":[]},{"title":"Budget & Risks","links":[]},{"title":"Quality","links":[]},{"title":"Integrated Plans","links":[]}]},{"title":"Topic 4: Execute the Project","subsecs":[{"title":"Craft Your Leadership Skills","links":[]},{"title":"Create a Collaborative Project Team Environment","links":[]},{"title":"Empower the Team","links":[]},{"title":"Support Team Member Performance","links":[]},{"title":"Communicate and Collaborate with Stakeholders","links":[]},{"title":"Training, Coaching and Mentoring","links":[]},{"title":"Manage Conflict","links":[]}]},{"title":"Topic 5: Monitor and Control the Project","subsecs":[{"title":"Implement Ongoing Improvements","links":[]},{"title":"Support Performance","links":[]},{"title":"Evaluate Project Progress","links":[]},{"title":"Manage Issues and Impediments","links":[]},{"title":"Manage Changes","links":[]}]},{"title":"Topic 6: Close the Project","subsecs":[{"title":"Project/Phase Closure","links":[]},{"title":"Benefits Realization","links":[]},{"title":"Knowledge Transfer","links":[]}]}] -->\n<p><strong>Topic 1: Business Environment</strong></p>\n<p><em>Foundation</em></p>\n<p><em>Strategic Alignment</em></p>\n<p><em>Project Benefits and Value</em></p>\n<p><em>Organization Culture and Change Management</em></p>\n<p><em>Project Governance</em></p>\n<p><em>Project Compliance</em></p>\n<p><strong>Topic 2: Start the Project</strong></p>\n<p><em>Identify and Engage Stakeholders</em></p>\n<p><em>Form the Team</em></p>\n<p><em>Build Shared Understanding</em></p>\n<p><em>Determine Project Approach</em></p>\n<p><strong>Topic 3: Plan the Project</strong></p>\n<p><em>Planning the Project</em></p>\n<p><em>Scope</em></p>\n<p><em>Schedule &amp; Resources</em></p>\n<p><em>Budget &amp; Risks</em></p>\n<p><em>Quality</em></p>\n<p><em>Integrated Plans</em></p>\n<p><strong>Topic 4: Execute the Project</strong></p>\n<p><em>Craft Your Leadership Skills</em></p>\n<p><em>Create a Collaborative Project Team Environment</em></p>\n<p><em>Empower the Team</em></p>\n<p><em>Support Team Member Performance</em></p>\n<p><em>Communicate and Collaborate with Stakeholders</em></p>\n<p><em>Training, Coaching and Mentoring</em></p>\n<p><em>Manage Conflict</em></p>\n<p><strong>Topic 5: Monitor and Control the Project</strong></p>\n<p><em>Implement Ongoing Improvements</em></p>\n<p><em>Support Performance</em></p>\n<p><em>Evaluate Project Progress</em></p>\n<p><em>Manage Issues and Impediments</em></p>\n<p><em>Manage Changes</em></p>\n<p><strong>Topic 6: Close the Project</strong></p>\n<p><em>Project/Phase Closure</em></p>\n<p><em>Benefits Realization</em></p>\n<p><em>Knowledge Transfer</em></p>\n\n'
 WHERE attribute_id = @a_desc AND entity_id = @pid AND @pid IS NOT NULL;

-- permanent 301: old slug -> new slug (SG store only)
SET @sid := (SELECT store_id FROM core_store WHERE store_id > 0 ORDER BY store_id LIMIT 1);

INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT @sid,
       CONCAT('c523-rename-masterclass-', @pid),
       'project-management-professional-pmp-exam-prep.html',
       'project-management-masterclass.html',
       0, 'RP', '1524: C523 renamed to Project Management Masterclass'
WHERE @pid IS NOT NULL AND @sid IS NOT NULL;
