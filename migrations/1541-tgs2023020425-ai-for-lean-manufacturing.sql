-- 1541: TGS-2023020425 -> "AI for Lean Manufacturing"
--
-- Retitles "WSQ - Reducing Waste and Improving Workplace Efficiency with Lean
-- Six Sigma" (product 1348) onto an AI-assisted framing, and rewrites the
-- outline from 3 topics to the supplied 4.
--
-- CLASSIFIED AS A RETITLE, NOT A REPURPOSE. The SKU is unchanged and the
-- subject has NOT moved: this still teaches lean manufacturing against the
-- same SSG-registered competency. The tell, confirmed by probing prod before
-- writing this file:
--   * the supplied LO1-LO9 are BYTE-IDENTICAL to the live
--     course_TGS-2023020425_learning_outcomes cms_block. They are the
--     SSG-registered outcomes; the four new topics are the same nine outcomes
--     re-framed as AI-assisted. So the LO block is deliberately NOT touched.
--   * course_TGS-2023020425_skills_framework already reads "Lean Manufacturing
--     PRE-OPR-4064-1.1 TSC under Precision Engineering" -- still accurate,
--     left alone.
-- Per feedback_retitle_vs_repurpose_keep_most_surfaces this migration therefore
-- edits ONLY the naming + AI-facing copy surfaces and leaves taxonomy/content
-- surfaces alone. Explicitly verified correct and NOT touched, so a later
-- session does not "fix" them:
--   * the 5 cms_blocks (brochure / learning_outcomes / certification /
--     skills_framework / funding_and_grant) -- keyed to the unchanged SKU.
--   * all 8 category placements (3, 15, 119, 288, 292, 293, 301, 330). The
--     course keeps its quality-assurance / six-sigma / wsq-funded listings;
--     cat 301 (wsq-it-security-courses) is pre-existing and out of scope here.
--   * the 7 funding tags (WSQ|SkillsFuture Credit|PSEA|UTAP|SFEC|
--     Absentee Payroll|MCES), price ($800), duration (16), sessions (2),
--     level, software, trainers, trainerprofile, prerequisite, additional_note.
--
-- WHAT IS STALE and is fixed here:
--   * name, url_key, url_path (both store 0 and store 1 rows)
--   * meta_title -- note it must NOT start with "WSQ": MMD_Seotitle prepends
--     "WSQ funded" at render time for TGS- SKUs on SG, and the stored
--     "WSQ Reducing Waste & ... | Tertiary Courses Singapore" was already
--     producing a duplicated funding token on the live <title>. Fixed to the
--     PLAIN title as part of this rename.
--   * meta_description (<= 255 chars, varchar column), meta_keyword
--   * short_description -- the About copy, rewritten to the supplied text.
--   * description -- the outline, rewritten from 3 topics to the supplied 4.
--     This product stores the outline as <h3 class="course-topic-h3"> + <ul>
--     (NOT the LSN_DATA JSON marker some other courses use) -- that existing
--     format is preserved exactly.
--   * whoshouldattend -- refreshed onto AI-assisted manufacturing roles.
--   * image_label / small_image_label / thumbnail_label + the media-gallery
--     label (the real alt text). The image/small_image/thumbnail PATHS are
--     left alone on purpose -- they are filesystem paths and renaming them
--     would 404 the gallery.
--   * course_image_url -> the regenerated R2 cover. The title is baked into
--     the PNG, so the rename alone would keep serving the old title.
--     Rendered via MMD_CourseImage_Model_Cover with the product's existing
--     7-badge set, verified HTTP 200:
--       course-covers/TGS-2023020425-20260922-171733.png  (153479 bytes)
--
-- SG production only; keyed by SKU so a partner site without this SKU no-ops.
-- Idempotent: plain UPDATEs + INSERT IGNORE / ON DUPLICATE KEY UPDATE.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2023020425' LIMIT 1);
SET @et  := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');

-- ---------------------------------------------------------------- name
SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='name' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'AI for Lean Manufacturing'
 WHERE attribute_id = @a_name AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- url_key
SET @a_url := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_key' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-ai-for-lean-manufacturing'
 WHERE attribute_id = @a_url AND entity_id = @pid AND @pid IS NOT NULL;

-- url_path (global + the store 1 row this product carries)
SET @a_upath := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_path' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-ai-for-lean-manufacturing.html'
 WHERE attribute_id = @a_upath AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- meta_title
-- No leading "WSQ": MMD_Seotitle adds the "WSQ funded" prefix at render time.
SET @a_mt := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_title' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'AI for Lean Manufacturing Course | Tertiary Courses Singapore'
 WHERE attribute_id = @a_mt AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- meta_description
-- varchar(255): the string below is 209 chars.
SET @a_md := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_description' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'Learn AI for Lean Manufacturing in Singapore. Use AI to reduce waste, optimise inventory and kanban, improve material flow and support predictive maintenance. Hands-on WSQ funded course with up to 70% subsidy.'
 WHERE attribute_id = @a_md AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- meta_keyword
SET @a_mk := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_keyword' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = 'AI for Lean Manufacturing, AI lean manufacturing course, lean manufacturing singapore, AI waste reduction, AI inventory optimisation, kanban training, TAKT time, predictive maintenance, value stream mapping, WSQ lean manufacturing course'
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
-- Keeps this product's established format: <h3 class="course-topic-h3"> + <ul>.
-- Rewritten from 3 topics to the supplied 4; the bullets carry the same
-- LO1-LO9 subject matter, re-framed as AI-assisted.
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
-- Kept the manufacturing roles (the subject is unchanged) and refreshed the
-- list onto AI-adjacent operations roles. Also drops the stray trailing "."
-- on the last item in the old list.
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
       'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023020425-20260922-171733.png'
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
   AND request_path LIKE '%wsq-reducing-waste-and-improving-workplace-efficiency-with-lean-six-sigma.html';

-- Clear any is_system=0 squatter sitting on the NEW paths.
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND request_path LIKE '%wsq-ai-for-lean-manufacturing.html';

-- 301 old -> new: bare path plus each of the 8 category-prefixed paths.
INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT @sid,
       CONCAT('tgs2023020425-ai-lean-mfg-', t.slot, '-', @pid),
       CONCAT(t.prefix, 'wsq-reducing-waste-and-improving-workplace-efficiency-with-lean-six-sigma.html'),
       CONCAT(t.prefix, 'wsq-ai-for-lean-manufacturing.html'),
       0, 'RP', '1541: TGS-2023020425 renamed to AI for Lean Manufacturing'
  FROM (
        SELECT 'bare'   AS slot, ''                                    AS prefix
  UNION SELECT 'cat3',           'adult-training-courses/'
  UNION SELECT 'cat15',          'latest-courses/'
  UNION SELECT 'cat119',         'quality-and-assurance-training-courses/'
  UNION SELECT 'cat288',         'wsq-quality-assurance-courses/'
  UNION SELECT 'cat292',         'wsq-funded-courses/'
  UNION SELECT 'cat293',         'wsq-finance-mfg-green-courses/'
  UNION SELECT 'cat301',         'wsq-it-security-courses/'
  UNION SELECT 'cat330',         'six-sigma-courses/'
  ) t
 WHERE @pid IS NOT NULL AND @sid IS NOT NULL;

-- Flatten the PRE-EXISTING 301s that still target the OLD slug, so the many
-- historical URLs (wsq-lean-manufacturing-at-workplace,
-- wsq-fundamentals-of-lean-manufacturing-at-workplace, the deep
-- adult-training-courses/electronics-semiconductor/... paths, and the stale
-- wsq-advanced-nlp-...-1348 aliases from this entity's earlier life) redirect
-- ONCE to the new slug instead of chaining 301 -> 301. Anchored on target_path
-- so the category-prefixed variants are flattened too.
UPDATE core_url_rewrite
   SET target_path = REPLACE(target_path,
                             'wsq-reducing-waste-and-improving-workplace-efficiency-with-lean-six-sigma.html',
                             'wsq-ai-for-lean-manufacturing.html')
 WHERE is_system = 0
   AND target_path LIKE '%wsq-reducing-waste-and-improving-workplace-efficiency-with-lean-six-sigma.html'
   AND id_path NOT LIKE 'tgs2023020425-ai-lean-mfg-%';

-- ---------------------------------------------------------------- search redirects
-- 9 stored search terms point at the old slug and would 301-chain after this
-- rename. Repoint them straight at the live URL. Scoped to rows whose redirect
-- IS the old slug -- the many other lean/six-sigma terms point at the separate
-- CLSS belt courses and must NOT be touched.
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/wsq-ai-for-lean-manufacturing.html'
 WHERE redirect = 'https://www.tertiarycourses.com.sg/wsq-reducing-waste-and-improving-workplace-efficiency-with-lean-six-sigma.html';
