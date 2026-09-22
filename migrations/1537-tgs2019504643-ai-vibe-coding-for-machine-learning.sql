-- 1537: TGS-2019504643 -> "WSQ - AI Vibe Coding for Machine Learning"
--
-- Retitles the course from "AI Vibe Coding for Data Analytics" to
-- "AI Vibe Coding for Machine Learning", aligning every content surface with
-- the Scikit-Learn machine-learning syllabus the LOs and Topics 2-5 already
-- describe, re-slugs with permanent 301s, and repoints the cover image.
--
-- BACKGROUND: migration 962 (2026-08-13) shipped, on explicit admin
-- instruction, a deliberate content mismatch -- the LOs and Topics 2-5 were
-- Scikit-Learn ML while Topic 1 and the whole About narrative still described
-- data analytics. Migration 998 then repurposed the identity to "AI Vibe
-- Coding for Data Analytics", which matched the narrative but NOT the LOs.
-- This migration resolves that split in favour of MACHINE LEARNING, which is
-- what the five LOs (classification / regression / clustering / PCA) and the
-- accredited outline actually teach. The 962 header note warning a future
-- reader not to "fix" the mismatch is therefore superseded BY ADMIN REQUEST
-- (2026-09-22) -- this is the intended realignment, not an accidental undo.
--
-- SLUG: the obvious slug `wsq-ai-vibe-coding-for-machine-learning` is ALREADY
-- OWNED by a different live, enabled course -- TGS-2020504357 (entity 1103),
-- also named "WSQ - AI Vibe Coding for Machine Learning" (an R / deep-learning
-- 6-topic syllabus). Taking it would collide on core_url_rewrite's unique key
-- and break that course. Admin chose the distinguishing slug
-- `wsq-ai-vibe-coding-for-machine-learning-scikit-learn` (2026-09-22). Entity
-- 1103 is deliberately NOT touched by this migration.
--
-- Learning outcomes are NOT changed: cms_block
-- course_TGS-2019504643_learning_outcomes already carries the five supplied
-- LOs byte-for-byte, so there is nothing to write.
--
-- The cover is a PRE-RENDERED PNG on R2 with the title baked in, so a rename
-- alone would keep serving a cover reading "AI Vibe Coding for Data
-- Analytics". Re-rendered via MMD_CourseImage_Model_Cover with the product's
-- OWN badge set (WSQ, SkillsFuture Credit, PSEA, UTAP, SFEC, Absentee Payroll,
-- MCES -- all 7 chips preserved) and uploaded to shared R2:
--   course-covers/TGS-2019504643-20260922-154215.png  (167961 bytes, HTTP 200)
-- The superseded object is left on R2 so reverting is just repointing the URL.
--
-- SKU is UNCHANGED, so every SkillsFuture / SFEC / SFC / PSEA / UTAP deep link,
-- the funding table, brochure, certification and skills-framework blocks stay
-- valid and are not touched.
--
-- SG production only; keyed by SKU so a partner site with no TGS-2019504643
-- no-ops. Idempotent: plain UPDATEs + INSERT IGNORE + guarded upsert.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2019504643' LIMIT 1);
SET @et := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product');

-- ---------------------------------------------------------------------------
-- 1. Identity: name, url_key, url_path
-- ---------------------------------------------------------------------------

-- name: keeps the `WSQ - ` prefix (the storefront H1 wants it)
SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='name' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - AI Vibe Coding for Machine Learning'
 WHERE attribute_id = @a_name AND entity_id = @e AND @e IS NOT NULL;

-- url_key: distinguishing slug (see SLUG note above)
SET @a_url := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_key' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-ai-vibe-coding-for-machine-learning-scikit-learn'
 WHERE attribute_id = @a_url AND entity_id = @e AND @e IS NOT NULL;

-- url_path: DELETE at every scope so the URL Rewrites indexer regenerates it
SET @a_upath := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_path' AND entity_type_id=@et);
DELETE FROM catalog_product_entity_varchar
 WHERE attribute_id = @a_upath AND entity_id = @e AND @e IS NOT NULL AND @a_upath IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 2. Meta
-- ---------------------------------------------------------------------------

-- meta_title: NO leading "WSQ" -- MMD_Seotitle prepends "WSQ funded" at render
-- time for any SG TGS- SKU, so a stored "WSQ ..." double-prints.
SET @a_mt := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_title' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'AI Vibe Coding for Machine Learning'
 WHERE attribute_id = @a_mt AND entity_id = @e AND @e IS NOT NULL;

-- meta_description: varchar(255) -- this value is 232 chars
SET @a_md := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_description' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'Use AI vibe coding with Python and scikit-learn to build machine learning models. Apply classification, regression, clustering and PCA to real data. Up to 70% WSQ funding subsidy.'
 WHERE attribute_id = @a_md AND entity_id = @e AND @e IS NOT NULL;

-- meta_keyword
SET @a_mk := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_keyword' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = 'AI Vibe Coding, Machine Learning, Scikit-Learn, Python, WSQ Funding, AI Coding Assistant, Classification, Regression, Clustering, PCA'
 WHERE attribute_id = @a_mk AND entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 3. Content: About narrative + Course Outline
-- ---------------------------------------------------------------------------

-- short_description ("What's This Course About"): the supplied six-paragraph
-- machine-learning narrative, replacing the data-analytics one. This course's
-- sections were extracted to cms_block rows, so short_description holds ONLY
-- the intro copy -- a full replace is correct here (no <h2>Course Brochure</h2>
-- tail to splice around).
SET @a_sd := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
'<p>This course equips participants with practical skills to use AI vibe coding and Python to build machine learning solutions using scikit-learn. Learners will use natural-language instructions and AI coding assistants to generate, explain, test, debug, and refine Python code, making machine learning development faster and more accessible.</p>',
'\n<p>Participants will learn how to prepare data for machine learning by importing, cleaning, transforming, encoding, and organising datasets. They will use scikit-learn to develop machine learning workflows covering data preprocessing, feature selection, model training, prediction, and evaluation.</p>',
'\n<p>The course covers key supervised and unsupervised learning techniques, including regression, classification, clustering, and dimensionality reduction. Learners will explore commonly used algorithms such as Linear Regression, Logistic Regression, Decision Trees, Random Forests, K-Nearest Neighbours, K-Means Clustering, and Principal Component Analysis (PCA).</p>',
'\n<p>Using AI-assisted workflows, learners will generate and refine scikit-learn code, select suitable algorithms, troubleshoot errors, and compare model performance. They will apply train-test splitting, cross-validation, feature scaling, hyperparameter tuning, and scikit-learn Pipelines to improve model reliability.</p>',
'\n<p>Through hands-on projects, participants will build end-to-end machine learning solutions, from preparing data and training models to evaluating, improving, and interpreting results. Emphasis is placed on validating AI-generated code, preventing overfitting and data leakage, and selecting appropriate evaluation metrics.</p>',
'\n<p>By the end of the course, learners will be able to use AI vibe coding, Python, and scikit-learn to develop and evaluate practical machine learning solutions.</p>')
 WHERE attribute_id = @a_sd AND entity_id = @e AND @e IS NOT NULL;

-- description (Course Outline): five topic titles. Only Topic 1 changes --
-- it still carried the "for Data Analytics" qualifier while Topics 2-5 were
-- already the ML outline. Topic bodies stay absent (titles only), matching the
-- shape 962 established and the supplied outline.
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='description' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
'<h3 class="course-topic-h3">Topic 1: AI Vibe Coding and Machine Learning Fundamentals</h3>',
'\n<h3 class="course-topic-h3">Topic 2: Data Classification and Performance Evaluation</h3>',
'\n<h3 class="course-topic-h3">Topic 3: Regression Analysis and Predictive Modelling</h3>',
'\n<h3 class="course-topic-h3">Topic 4: Clustering and Customer or Data Segmentation</h3>',
'\n<h3 class="course-topic-h3">Topic 5: Principal Component Analysis and Dimensionality Reduction</h3>')
 WHERE attribute_id = @a_desc AND entity_id = @e AND @e IS NOT NULL;

-- whoshouldattend: the job-role list named the OLD subject (pure analyst
-- roles). Re-pointed at machine-learning equivalents. Broad business roles
-- that remain accurate are kept.
SET @a_wsa := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='whoshouldattend' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
'<ul>',
'\n<li>Machine Learning Engineer</li>',
'\n<li>Data Scientist</li>',
'\n<li>Data Analyst</li>',
'\n<li>AI Engineer</li>',
'\n<li>Business Analyst</li>',
'\n<li>Data Engineer</li>',
'\n<li>Software Developer moving into machine learning</li>',
'\n<li>Research Analyst</li>',
'\n<li>Predictive Modelling Specialist</li>',
'\n<li>Analytics Consultant</li>',
'\n<li>Product Manager (focused on data or AI products)</li>',
'\n<li>Innovation Specialist</li>',
'\n<li>Business Owner or Manager working with data</li>',
'\n</ul>')
 WHERE attribute_id = @a_wsa AND entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 4. Cover image + alt text
-- ---------------------------------------------------------------------------

-- image alt-text labels: plain title, no `WSQ - ` prefix (the cover itself
-- strips it via Cover.php::cleanTitle)
UPDATE catalog_product_entity_varchar v
   JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @et
    SET v.value = 'AI Vibe Coding for Machine Learning'
  WHERE v.entity_id = @e AND @e IS NOT NULL
    AND a.attribute_code IN ('image_label','small_image_label','thumbnail_label');

-- media gallery label -- the real alt text on the product image
UPDATE catalog_product_entity_media_gallery_value gv
   JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
    SET gv.label = 'AI Vibe Coding for Machine Learning'
  WHERE g.entity_id = @e AND @e IS NOT NULL;

-- cover image: repoint at the regenerated PNG (global scope; clear any
-- store-scoped row that would shadow it)
SET @a_ciu := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='course_image_url' AND entity_type_id=@et);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @et, @a_ciu, 0, @e,
       'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2019504643-20260922-154215.png'
 WHERE @e IS NOT NULL AND @a_ciu IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id <> 0
   AND @e IS NOT NULL AND @a_ciu IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 5. URL rewrites: 301 the old slug, flatten the chain history
-- ---------------------------------------------------------------------------

SET @sid := (SELECT store_id FROM core_store WHERE store_id > 0 ORDER BY store_id LIMIT 1);

-- The old bare slug is held by the canonical is_system=1 row on
-- id_path='product/<e>'. INSERT IGNORE would silently no-op against it, so
-- DELETE it first; the indexer re-mints the canonical row at the NEW slug when
-- refreshProductRewrite runs post-deploy.
DELETE FROM core_url_rewrite
 WHERE product_id = @e AND is_system = 1
   AND request_path = 'wsq-ai-vibe-coding-for-data-analytics.html'
   AND @e IS NOT NULL;

-- Clear any is_system=0 squatter sitting on the NEW path
DELETE FROM core_url_rewrite
 WHERE request_path = 'wsq-ai-vibe-coding-for-machine-learning-scikit-learn.html'
   AND is_system = 0;

-- Permanent 301: old bare slug -> new bare slug. The indexer auto-301s the
-- ~13 category-prefixed paths once the rewrites are refreshed.
INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT @sid, CONCAT('tgs2019504643-ml-scikit-bare-', @e),
       'wsq-ai-vibe-coding-for-data-analytics.html',
       'wsq-ai-vibe-coding-for-machine-learning-scikit-learn.html',
       0, 'RP', '1537: TGS-2019504643 retitled to AI Vibe Coding for Machine Learning'
WHERE @e IS NOT NULL AND @sid IS NOT NULL;

-- Flatten the PRE-EXISTING 301s that point at the OLD slug so the historical
-- URLs (wsq-python-intermediate-level-course, wsq-machine-learning-python-course,
-- wsq-basic-machine-learning-with-scikitlearn-course, ...) redirect in ONE hop
-- instead of chaining 301 -> 301.
--
-- Anchored on request_path LIKE '%wsq-%': target_path says where a row POINTS,
-- not who it BELONGS to, and a bare target_path sweep can repoint foreign
-- courses' aliases at this page. Verified before writing: 56 rows match, 0 of
-- them foreign (every match carries the wsq- stem and belongs to this course).
UPDATE core_url_rewrite
   SET target_path = REPLACE(target_path,
                             'wsq-ai-vibe-coding-for-data-analytics.html',
                             'wsq-ai-vibe-coding-for-machine-learning-scikit-learn.html')
 WHERE is_system = 0
   AND target_path LIKE '%wsq-ai-vibe-coding-for-data-analytics.html'
   AND request_path LIKE '%wsq-%'
   AND id_path NOT LIKE 'tgs2019504643-ml-scikit-%';

-- Search-term redirects pointing at the old slug follow the course (the SKU and
-- the ML subject are unchanged, so the intent still matches). Anchored on the
-- '/wsq-' prefix + full old filename so a non-WSQ twin's rows are excluded.
UPDATE catalogsearch_query
   SET redirect = REPLACE(redirect,
                          'wsq-ai-vibe-coding-for-data-analytics.html',
                          'wsq-ai-vibe-coding-for-machine-learning-scikit-learn.html')
 WHERE redirect LIKE '%wsq-ai-vibe-coding-for-data-analytics.html';
