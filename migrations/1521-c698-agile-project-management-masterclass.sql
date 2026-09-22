-- C698: re-activate and repurpose
--   "Apply Scrum Methodology in Agile Environment"
--   -> "Agile Project Management Masterclass"
--
-- Content (short_description, topics/description, whoshouldattend, meta) is
-- copied from the WSQ parent TGS-2023018967 "Agile Project Management for
-- Business", with the WSQ-only layer stripped (no funding tables, no PWM, no
-- SSG/SkillsFuture wording, no assessment) per the non-WSQ convention.
--
-- Unchanged on purpose: price ($700) and duration (15 hrs / 2 days) already
-- match the requested values.
--
-- NOT in this file: the schedule template switch B03 -> B07 (gid 190, the
-- non-WSQ counterpart of the parent's "(SG) WSQ-B07"). custom_options_relation
-- is keyed per OPTION, so a SQL switch leaves the course with no schedule
-- options at all. That switch is a CODE path -- run it via the admin
-- "Switch Template" button / CoursesaveController::switchScheduleTemplateAction.
--
-- SG-only course (C-prefix). Guarded on the SG store so this is a no-op on the
-- MY/GH partner servers, which run the same migration chain.
-- Idempotent: safe to re-run.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C698');

-- ============================================================ activate ====
SET @a_status := (SELECT attribute_id FROM eav_attribute a
                  JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                  WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'status');

UPDATE catalog_product_entity_int
SET value = 1
WHERE @sg = 1 AND @pid IS NOT NULL
  AND entity_id = @pid AND attribute_id = @a_status;

-- ================================================================ name ====
SET @a_name := (SELECT attribute_id FROM eav_attribute a
                JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'name');

UPDATE catalog_product_entity_varchar
SET value = 'Agile Project Management Masterclass'
WHERE @sg = 1 AND @pid IS NOT NULL
  AND entity_id = @pid AND attribute_id = @a_name;

-- ============================================================= url_key ====
SET @a_urlkey := (SELECT attribute_id FROM eav_attribute a
                  JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                  WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'url_key');

UPDATE catalog_product_entity_varchar
SET value = 'agile-project-management-masterclass'
WHERE @sg = 1 AND @pid IS NOT NULL
  AND entity_id = @pid AND attribute_id = @a_urlkey;

SET @a_urlpath := (SELECT attribute_id FROM eav_attribute a
                   JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                   WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'url_path');

UPDATE catalog_product_entity_varchar
SET value = 'agile-project-management-masterclass.html'
WHERE @sg = 1 AND @pid IS NOT NULL
  AND entity_id = @pid AND attribute_id = @a_urlpath;

-- ======================================================== image labels ====
SET @a_imglbl  := (SELECT attribute_id FROM eav_attribute a
                   JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                   WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'image_label');
SET @a_simglbl := (SELECT attribute_id FROM eav_attribute a
                   JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                   WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'small_image_label');
SET @a_thmblbl := (SELECT attribute_id FROM eav_attribute a
                   JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                   WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'thumbnail_label');

UPDATE catalog_product_entity_varchar
SET value = 'Agile Project Management Masterclass'
WHERE @sg = 1 AND @pid IS NOT NULL
  AND entity_id = @pid
  AND attribute_id IN (@a_imglbl, @a_simglbl, @a_thmblbl);

-- ============================================================ meta data ===
-- meta_title / meta_description are varchar(255); both fit.
SET @a_mtitle := (SELECT attribute_id FROM eav_attribute a
                  JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                  WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'meta_title');
SET @a_mdesc  := (SELECT attribute_id FROM eav_attribute a
                  JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                  WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'meta_description');

UPDATE catalog_product_entity_varchar
SET value = 'Agile Project Management Masterclass | Tertiary Courses Singapore'
WHERE @sg = 1 AND @pid IS NOT NULL
  AND entity_id = @pid AND attribute_id = @a_mtitle;

UPDATE catalog_product_entity_varchar
SET value = 'Master Agile project management for business. Learn Agile values, the Scrum framework, Lean methodology, sprint execution and project tracking in this 2-day masterclass in Singapore.'
WHERE @sg = 1 AND @pid IS NOT NULL
  AND entity_id = @pid AND attribute_id = @a_mdesc;

SET @a_mkey := (SELECT attribute_id FROM eav_attribute a
                JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'meta_keyword');

UPDATE catalog_product_entity_text
SET value = 'Agile Project Management, Business Agility, Project Lifecycle, Scrum, Kanban, Lean, Risk Management, Team Collaboration'
WHERE @sg = 1 AND @pid IS NOT NULL
  AND entity_id = @pid AND attribute_id = @a_mkey;

-- ===================================================== short_description ==
-- Copied from the parent, with the WSQ framing dropped.
SET @a_sdesc := (SELECT attribute_id FROM eav_attribute a
                 JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                 WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'short_description');

UPDATE catalog_product_entity_text
SET value = CONCAT(
  '<p>Elevate your project management skills to new heights with our Agile Project Management Masterclass. ',
  'This course is structured to equip you with the fundamentals and advanced techniques of Agile methodologies like Scrum and Kanban. ',
  'Learn how to plan, execute, and close projects effectively while embracing changes and managing risks. ',
  'The curriculum covers key aspects of Agile such as backlog grooming, sprint planning, and iterative development, ',
  'setting you up for success in fast-paced business environments.</p>',
  '<p>Unlock the full potential of your projects and teams by mastering Agile Project Management principles. ',
  'This course dives into topics like stakeholder engagement, risk management, and team dynamics, ',
  'ensuring that you are well-prepared to manage projects from inception to completion. ',
  'Whether you are a business leader, manager, or aspiring project manager, this training provides you with the toolkit ',
  'to improve project outcomes, enhance team collaboration, and contribute to business agility.</p>'
)
WHERE @sg = 1 AND @pid IS NOT NULL
  AND entity_id = @pid AND attribute_id = @a_sdesc;

-- ================================================ description (topics) ====
-- The three topics of the parent TGS-2023018967, verbatim, in the non-WSQ
-- course-topic markup. The leading LSN_DATA comment is the structured mirror
-- the course-outline UI reads; it must stay in sync with the HTML below it.
-- En dashes are written as the HTML entity so the file stays pure ASCII and
-- apply.php (charset=utf8) cannot trip on a stray byte.
SET @a_desc := (SELECT attribute_id FROM eav_attribute a
                JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'description');

UPDATE catalog_product_entity_text
SET value = CONCAT(
  '<!-- LSN_DATA: [',
    '{"title":"Topic 1: Introduction to Agile Project Management","subsecs":[',
      '{"title":"A reality check on current and future business operating landscapes","links":[]},',
      '{"title":"Overview of waterfall model - analyze current and future customer needs","links":[]},',
      '{"title":"Agile overview - understanding Agile development, policies and processes","links":[]},',
      '{"title":"Agile paradigm shift - experiment with Agile project delivery","links":[]}]},',
    '{"title":"Topic 2: Agile Essentials","subsecs":[',
      '{"title":"Values and principles of Agile methodologies","links":[]},',
      '{"title":"Finding Agile support and preparing for resistance","links":[]},',
      '{"title":"SCRUM framework and Lean Methodology","links":[]},',
      '{"title":"Implement Agile practices","links":[]}]},',
    '{"title":"Topic 3: Agile Project Execution and Tracking","subsecs":[',
      '{"title":"Project requirement - build an Agile team and setting vision","links":[]},',
      '{"title":"Project execution - assess work performance and continuous improvement","links":[]},',
      '{"title":"Project tracking - measure progress against targets","links":[]}]}',
  '] -->\n',
  '<h3 class="course-topic-h3">Topic 1: Introduction to Agile Project Management</h3>\n<ul>\n',
  '<li>A reality check on current and future business operating landscapes</li>\n',
  '<li>Overview of waterfall model &ndash; analyze current and future customer needs</li>\n',
  '<li>Agile overview &ndash; understanding Agile development, policies and processes</li>\n',
  '<li>Agile paradigm shift &ndash; experiment with Agile project delivery</li>\n</ul>\n',
  '<h3 class="course-topic-h3">Topic 2: Agile Essentials</h3>\n<ul>\n',
  '<li>Values and principles of Agile methodologies</li>\n',
  '<li>Finding Agile support and preparing for resistance</li>\n',
  '<li>SCRUM framework and Lean Methodology</li>\n',
  '<li>Implement Agile practices</li>\n</ul>\n',
  '<h3 class="course-topic-h3">Topic 3: Agile Project Execution and Tracking</h3>\n<ul>\n',
  '<li>Project requirement &ndash; build an Agile team and setting vision</li>\n',
  '<li>Project execution &ndash; assess work performance and continuous improvement</li>\n',
  '<li>Project tracking &ndash; measure progress against targets</li>\n</ul>\n'
)
WHERE @sg = 1 AND @pid IS NOT NULL
  AND entity_id = @pid AND attribute_id = @a_desc;

-- ===================================================== whoshouldattend ====
SET @a_who := (SELECT attribute_id FROM eav_attribute a
               JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
               WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'whoshouldattend');

UPDATE catalog_product_entity_text
SET value = CONCAT(
  '<ul>\n<li>Project Manager</li>\n<li>Scrum Master</li>\n<li>Product Owner</li>\n',
  '<li>Business Analyst</li>\n<li>Product Manager</li>\n<li>Team Leader</li>\n',
  '<li>IT Project Manager</li>\n<li>Change Manager</li>\n<li>Operations Manager</li>\n',
  '<li>Business Process Manager</li>\n<li>Development Team Lead</li>\n<li>QA Manager</li>\n',
  '<li>HR Project Coordinator</li>\n<li>Program Manager</li>\n',
  '<li>Organizational Development Specialist</li>\n</ul>'
)
WHERE @sg = 1 AND @pid IS NOT NULL
  AND entity_id = @pid AND attribute_id = @a_who;

-- ======================================================== 301 rewrites ====
-- Every stored path that resolved to the old slug must 301 to the new bare
-- slug. options='RP' IS the 301; an empty options column is a 302.
--
-- 1) Repoint existing RP rows whose TARGET was an old-slug path.
UPDATE core_url_rewrite
SET target_path = 'agile-project-management-masterclass.html', options = 'RP', is_system = 0
WHERE @sg = 1
  AND options = 'RP'
  AND target_path LIKE '%apply-scrum-methodology-in-agile-environment.html';

-- 2) Turn the old SYSTEM rows into permanent redirects to the new bare slug.
--    The indexer recreates the system rows for the new slug.
UPDATE core_url_rewrite
SET target_path = 'agile-project-management-masterclass.html', options = 'RP', is_system = 0
WHERE @sg = 1 AND @pid IS NOT NULL
  AND product_id = @pid
  AND request_path LIKE '%apply-scrum-methodology-in-agile-environment.html'
  AND target_path LIKE 'catalog/product/view/id/%';

-- 3) Belt and braces: a bare old-slug -> new-slug row in the default (0) and
--    SG (1) scopes even if the rows above were missing.
INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('manual-301-', MD5('apply-scrum-methodology-in-agile-environment.html'), '-', s.store_id),
       'apply-scrum-methodology-in-agile-environment.html',
       'agile-project-management-masterclass.html', 0, 'RP'
FROM (SELECT 0 AS store_id UNION ALL SELECT 1 AS store_id) s
WHERE @sg = 1
  AND NOT EXISTS (
    SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
    WHERE x.request_path = 'apply-scrum-methodology-in-agile-environment.html'
      AND x.store_id = s.store_id
  );

-- ==================================================== search redirects ====
UPDATE catalogsearch_query
SET redirect = REPLACE(redirect,
                       'apply-scrum-methodology-in-agile-environment.html',
                       'agile-project-management-masterclass.html')
WHERE @sg = 1
  AND redirect LIKE '%apply-scrum-methodology-in-agile-environment.html';

-- ====================================================== funding block =====
-- The non-WSQ Funding card pointed at "WSQ - Professional Scrum Master
-- Training", which is no longer this course's parent -- and that URL now 301s
-- to a DIFFERENT course (wsq-scrum-master-fundamentals-for-high-performing-
-- teams.html). Point it at the real parent, TGS-2023018967, using the target
-- that resolves 200 with no redirect hop.
UPDATE cms_block
SET content = CONCAT(
  '<p><span>For WSQ funding, please checkout the details at&nbsp;',
  '<a href="https://www.tertiarycourses.com.sg/wsq-agile-project-management-for-business.html" ',
  'title="WSQ - Agile Project Management for Business">',
  '<span style="text-decoration: underline;">WSQ - Agile Project Management for Business</span>',
  '</a></span></p>'
)
WHERE @sg = 1
  AND identifier = 'course_C698_funding_and_grant';
