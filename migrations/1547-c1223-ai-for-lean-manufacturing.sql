-- 1547: C1223 "Applying 5S Techniques" -> "AI for Lean Manufacturing"
--
-- Activates and repurposes the non-WSQ C1223 (product 1223) into the non-WSQ
-- twin of WSQ TGS-2023020425 "AI for Lean Manufacturing" (migration 1541).
--
-- This IS a repurpose (unlike 1541, which was a retitle): the subject moves
-- from 5S workplace organisation to AI-assisted lean manufacturing, so the
-- content surfaces are rewritten wholesale.
--
-- PROBED on prod before writing:
--   * status was 2 (DISABLED) -- this migration activates it (status 1).
--     visibility is already 4 (Catalog, Search); left as is.
--   * price 350 -> 700, duration 7.5 -> 15, sessions 1 -> 2 (2 days).
--   * C1223 is a RECYCLED entity: it carries 301s from an earlier
--     "fmea-training-1223" life. Those are flattened onto the new slug below
--     so they do not 301 -> 301.
--   * 11 historical order items exist, last one 2026-02-15, and ZERO
--     future-dated course_run_enrolments -- so changing the schedule strands
--     no learner.
--   * no tags (correct: C-prefix unfunded courses carry no funding badges,
--     and MMD_CourseImage::isFundableSku('C1223') returns false, so the
--     regenerated cover has no badge row).
--   * 3 cms_blocks exist (brochure / certification / funding_and_grant),
--     keyed to the unchanged SKU. NOT touched here -- the funding block is a
--     separate concern and the non-WSQ twin's funding card points at the WSQ
--     parent via its own follow-up if needed.
--
-- Content follows the WSQ parent TGS-2023020425 as instructed, adapted for the
-- non-WSQ twin: the 4 topics and the About copy are the parent's, but all WSQ /
-- SSG / funding framing is dropped (no "WSQ funded", no subsidy claim in the
-- meta_description) because this SKU is unfunded.
--
-- NOT done in SQL -- these are CODE paths, run separately:
--   * the schedule template switch A02 (gid 70) -> B07 (gid 190). Per the
--     non-wsq-schedule skill this must go through
--     CoursesaveController::switchScheduleTemplateAction, never
--     custom_options_relation DDL (that table is keyed per OPTION and a
--     DELETE+INSERT leaves the course with NO schedule options at all).
--     B07 is the correct counterpart: the parent sits on (SG) WSQ-B07 and the
--     twin is 2 days, so letter B + digits 07 carry over unchanged.
--   * refreshProductRewrite() to mint the is_system rewrites for the new slug.
--   * the cover PNG, already rendered + uploaded to R2 (title is baked in):
--       course-covers/C1223-20260923-005435.png  (121553 bytes, HTTP 200)
--
-- SG production only; keyed by SKU so a partner site without C1223 no-ops.
-- Idempotent: plain UPDATEs + INSERT IGNORE / ON DUPLICATE KEY UPDATE.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1223' LIMIT 1);
SET @et  := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');

-- ---------------------------------------------------------------- activate
SET @a_status := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='status' AND entity_type_id=@et);
UPDATE catalog_product_entity_int
   SET value = 1
 WHERE attribute_id = @a_status AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- name
SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='name' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'AI for Lean Manufacturing'
 WHERE attribute_id = @a_name AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- url_key / url_path
-- The WSQ parent holds 'wsq-ai-for-lean-manufacturing'; the non-WSQ twin takes
-- the bare slug so the two never collide.
SET @a_url := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_key' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'ai-for-lean-manufacturing'
 WHERE attribute_id = @a_url AND entity_id = @pid AND @pid IS NOT NULL;

SET @a_upath := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_path' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'ai-for-lean-manufacturing.html'
 WHERE attribute_id = @a_upath AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- price / duration / sessions
SET @a_price := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='price' AND entity_type_id=@et);
UPDATE catalog_product_entity_decimal
   SET value = 700.0000
 WHERE attribute_id = @a_price AND entity_id = @pid AND @pid IS NOT NULL;

-- 2 days x 7.5 hrs = 15 hrs. Both duration AND sessions must move together or
-- the product-page tiles disagree.
SET @a_dur := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='duration' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = '15'
 WHERE attribute_id = @a_dur AND entity_id = @pid AND @pid IS NOT NULL;

SET @a_sess := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='sessions' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = '2'
 WHERE attribute_id = @a_sess AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- meta_title
-- No "WSQ": this SKU is unfunded and MMD_Seotitle only prefixes TGS- SKUs.
SET @a_mt := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_title' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'AI for Lean Manufacturing Course | Tertiary Courses Singapore'
 WHERE attribute_id = @a_mt AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- meta_description
-- varchar(255): the string below is 191 chars. No subsidy claim -- unfunded SKU.
SET @a_md := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_description' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'Learn AI for Lean Manufacturing in Singapore. Use AI to reduce waste, optimise inventory and kanban, improve material flow and support predictive maintenance. Hands-on 2-day course, 15 hours.'
 WHERE attribute_id = @a_md AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- meta_keyword
SET @a_mk := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_keyword' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = 'AI for Lean Manufacturing, AI lean manufacturing course, lean manufacturing singapore, AI waste reduction, AI inventory optimisation, kanban training, TAKT time, predictive maintenance, value stream mapping'
 WHERE attribute_id = @a_mk AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- short_description (About This Course)
SET @a_sd := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<p>This AI for Lean Manufacturing course equips learners with practical knowledge and hands-on skills to apply Artificial Intelligence (AI) to improve manufacturing processes, reduce waste, enhance productivity, and support continuous improvement. The course integrates established Lean Manufacturing principles with modern AI capabilities, enabling participants to identify inefficiencies, analyse operational data, and make more informed improvement decisions.</p>',
     '<p>Learners will explore how AI can support key Lean practices such as value stream analysis, waste identification, process optimisation, quality improvement, predictive maintenance, production planning, and root cause analysis. Through practical manufacturing scenarios, participants will use AI to analyse process information, identify bottlenecks and non-value-added activities, generate improvement recommendations, and evaluate alternative solutions.</p>',
     '<p>The course also examines how AI can enhance traditional Lean approaches such as 5S, Kaizen, Value Stream Mapping (VSM), Standard Work, Overall Equipment Effectiveness (OEE), and continuous improvement. Participants will learn how AI-assisted analysis can help uncover patterns in production data, monitor operational performance, anticipate potential issues, and support faster problem-solving.</p>',
     '<p>With a strong emphasis on hands-on and real-life manufacturing applications, learners will work through practical exercises and improvement scenarios that demonstrate how AI can complement human expertise on the production floor. By the end of the course, participants will be able to apply Lean and AI techniques together to identify improvement opportunities, streamline manufacturing workflows, reduce operational waste, and contribute to smarter, more efficient manufacturing operations.</p>')
 WHERE attribute_id = @a_sd AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- description (Course Outline)
-- Same 4 topics as the WSQ parent. C1223's existing format is a bare <h3> +
-- <ul> (no LSN_DATA marker), and the parent uses class="course-topic-h3" --
-- adopting the parent's class so both pages render identically.
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='description' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<h3 class="course-topic-h3">Topic 1: AI-Assisted Lean Manufacturing Fundamentals and Waste Reduction</h3>\n',
     '<ul>\n',
     '<li>Identify the eight types of production waste with AI-assisted analysis</li>\n',
     '<li>Benefits of lean manufacturing and steps to achieve lean performance results</li>\n',
     '<li>Apply lean principles to compute production capacity and TAKT time</li>\n',
     '<li>Use AI for value stream analysis and to surface non-value-added activities</li>\n',
     '</ul>\n',
     '<h3 class="course-topic-h3">Topic 2: AI for Inventory Classification and Kanban Optimisation</h3>\n',
     '<ul>\n',
     '<li>Perform ABC analysis for inventory classification using selective inventory control</li>\n',
     '<li>Calculate economic batch quantity and the number of kanbans required</li>\n',
     '<li>Apply AI to optimise batch sizing and kanban levels</li>\n',
     '<li>Basic lean and QC tools</li>\n',
     '</ul>\n',
     '<h3 class="course-topic-h3">Topic 3: AI-Enabled Production, Inventory and Material Flow Control</h3>\n',
     '<ul>\n',
     '<li>Objectives of production and inventory control</li>\n',
     '<li>Types of inventories by function and condition</li>\n',
     '<li>Implement lean manufacturing tools for improved inventory and material flow</li>\n',
     '<li>Use AI to identify bottlenecks and support production planning</li>\n',
     '</ul>\n',
     '<h3 class="course-topic-h3">Topic 4: AI for Lean Implementation, Performance and Preventive Maintenance</h3>\n',
     '<ul>\n',
     '<li>Implement lean manufacturing at various organisational levels and areas for improvement</li>\n',
     '<li>Determine the necessity for preventive maintenance within the organisation</li>\n',
     '<li>Apply AI to predictive maintenance and Overall Equipment Effectiveness (OEE)</li>\n',
     '<li>Identify performance measurement areas and steps for successful lean implementation</li>\n',
     '</ul>\n')
 WHERE attribute_id = @a_desc AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- who should attend
SET @a_wsa := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='whoshouldattend' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<ul>',
     '<li>Production Manager</li>',
     '<li>Operations Manager</li>',
     '<li>Manufacturing Engineer</li>',
     '<li>Process Engineer</li>',
     '<li>Quality Assurance Manager</li>',
     '<li>Plant Manager</li>',
     '<li>Continuous Improvement Coordinator</li>',
     '<li>Supply Chain Manager</li>',
     '<li>Production Supervisor</li>',
     '<li>Inventory Control Specialist</li>',
     '<li>Logistics Coordinator</li>',
     '<li>Six Sigma Specialist</li>',
     '<li>Industrial Engineer</li>',
     '<li>Operational Excellence Manager</li>',
     '<li>Factory Floor Supervisor</li>',
     '<li>Maintenance Engineer</li>',
     '<li>Manufacturing Data Analyst</li>',
     '<li>Smart Manufacturing Executive</li>',
     '<li>Production Planner</li>',
     '<li>Business Owner</li>',
     '</ul>')
 WHERE attribute_id = @a_wsa AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- image alt labels
-- Labels only; the image PATHS stay as-is (filesystem paths).
UPDATE catalog_product_entity_varchar v
   JOIN eav_attribute a ON a.attribute_id = v.attribute_id
    SET v.value = 'AI for Lean Manufacturing'
  WHERE v.entity_id = @pid AND @pid IS NOT NULL
    AND a.entity_type_id = @et
    AND a.attribute_code IN ('image_label','small_image_label','thumbnail_label');

UPDATE catalog_product_entity_media_gallery_value g
   JOIN catalog_product_entity_media_gallery m ON m.value_id = g.value_id
    SET g.label = 'AI for Lean Manufacturing'
  WHERE m.entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- cover image
SET @a_ciu := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='course_image_url' AND entity_type_id=@et);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @et, @a_ciu, 0, @pid,
       'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1223-20260923-005435.png'
 WHERE @pid IS NOT NULL AND @a_ciu IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @pid AND attribute_id = @a_ciu AND store_id <> 0
   AND @pid IS NOT NULL AND @a_ciu IS NOT NULL;

-- ---------------------------------------------------------------- URL rewrites
SET @sid := (SELECT store_id FROM core_store WHERE store_id > 0 ORDER BY store_id LIMIT 1);

-- Free the OLD slug: the is_system=1 rows use id_path 'product/<id>...' -- the
-- same id_path the 301 would need -- so INSERT IGNORE would silently no-op and
-- refreshProductRewrite() would mint a '-1' suffix for the NEW slug.
DELETE FROM core_url_rewrite
 WHERE product_id = @pid AND is_system = 1 AND @pid IS NOT NULL
   AND request_path LIKE '%applying-5s-techniques.html';

-- Clear any is_system=0 squatter sitting on the NEW paths.
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND request_path LIKE '%ai-for-lean-manufacturing.html'
   AND request_path NOT LIKE '%wsq-ai-for-lean-manufacturing.html';

-- 301 old -> new: bare path plus each of the 3 category-prefixed paths.
INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT @sid,
       CONCAT('c1223-ai-lean-mfg-', t.slot, '-', @pid),
       CONCAT(t.prefix, 'applying-5s-techniques.html'),
       CONCAT(t.prefix, 'ai-for-lean-manufacturing.html'),
       0, 'RP', '1547: C1223 repurposed to AI for Lean Manufacturing'
  FROM (
        SELECT 'bare'   AS slot, ''                                AS prefix
  UNION SELECT 'cat3',           'adult-training-courses/'
  UNION SELECT 'cat68',          'business-soft-skills-courses/'
  UNION SELECT 'cat119',         'quality-and-assurance-training-courses/'
  ) t
 WHERE @pid IS NOT NULL AND @sid IS NOT NULL;

-- Flatten the PRE-EXISTING 301s that still target the OLD slug -- including the
-- recycled entity's older 'fmea-training-1223' aliases -- so they redirect ONCE
-- to the new slug instead of chaining 301 -> 301.
UPDATE core_url_rewrite
   SET target_path = REPLACE(target_path,
                             'applying-5s-techniques.html',
                             'ai-for-lean-manufacturing.html')
 WHERE is_system = 0
   AND target_path LIKE '%applying-5s-techniques.html'
   AND id_path NOT LIKE 'c1223-ai-lean-mfg-%';

-- ---------------------------------------------------------------- search redirects
-- Any stored search term pointing at the old 5S slug would 301-chain after this
-- repurpose. Repoint to the live URL. Scoped to the exact old target only.
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/ai-for-lean-manufacturing.html'
 WHERE redirect = 'https://www.tertiarycourses.com.sg/applying-5s-techniques.html';
