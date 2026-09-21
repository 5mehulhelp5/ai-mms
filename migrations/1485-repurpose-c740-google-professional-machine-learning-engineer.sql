-- 1485: Repurpose C740
--   OLD: "Google Cloud Certified Professional Cloud Architect Training"
--   NEW: "Google Professional Machine Learning Engineer Training"
-- SKU unchanged (C740). Non-WSQ C-prefix twin of the WSQ parent TGS-2023040476
-- (wsq-google-professional-machine-learning-engineer-training.html): same 8
-- topics, same About prose, same job roles.
--
-- Shape: 4 days / 30 hrs / $1400.
--   duration (30) and sessions (4) are ALREADY correct on C740 and are left
--   alone -- 7.5 hrs x 4 days is the non-WSQ house rule, and the parent's own
--   hours (which include its assessment block) are deliberately NOT copied.
--   price moves 1200 -> 1400.
--
-- SCHEDULE: deliberately NOT changed. C740 already sits on template D02
--   "Mon-Thurs/Sat-Sun 2nd wk" (gid 227), which is the exact counterpart of the
--   parent's "(SG) WSQ-D02" (gid 280) -- both 4-day, same calendar week. A
--   template switch is a code path (the admin Switch Template button), never
--   SQL: custom_options_relation is keyed per OPTION, so a DELETE+INSERT here
--   fails on option_id AFTER the DELETE lands and leaves the course with an
--   empty Course Date dropdown (incident 2026-09-17, C141).
--
-- SLUG: google-professional-machine-learning-engineer-training is FREE --
--   verified against core_url_rewrite and every product url_key on prod
--   2026-09-21. The neighbouring
--   google-professional-machine-learning-engineer-training-practice-exams.html
--   belongs to product 1677 and is a prefix neighbour, not a collision.
--   Two OLD is_system=0 rows already 301 legacy ML-engineer paths elsewhere:
--     * ...-certification-exam-prep.html -> C997 (Business Transformation with
--       AI Agents), via the custom/c997-301 chain
--     * ...-certification-prep.html      -> the WSQ parent 1209
--   Both are left INTACT: they point at pages that still exist, and neither
--   squats the bare slug this migration claims.
--
-- Surfaces touched:
--   1  name / meta_title
--   2  meta_description / meta_keyword
--   3  url_key + url_path (dropped at every scope so the indexer regenerates)
--      + a 301 from the old bare slug + chain-flattening of the ~20 legacy
--      rewrites that 301 INTO it, so they stay one hop
--   4  description       -> the parent's 8 topics
--   5  short_description -> the parent's About prose
--   6  whoshouldattend   -> the parent's ML job roles
--   7  price             -> 1400
--   8  *_label (3) + media_gallery_value.label (the real rendered alt text)
--   9  categories        -> add the parent's ML/AI homes; drop Cloud Architect-
--                           only ones that no longer describe the course
--  10  catalogsearch_query -> retarget c740 / c0740 + the cloud-architect terms
--
-- Deliberately NOT touched:
--   - image / small_image / thumbnail: filesystem PATHS; renaming them 404s the
--     JPG. The rendered cover is course_image_url (R2) -- see the note below.
--   - prerequisite: C740's own block is correct for a non-WSQ course (Google
--     review promo, no WSQ entry criteria). The parent's is WSQ-laden (PWM,
--     SkillsFuture, UTAP, funding tables) and must NOT ride along onto an
--     unfunded course. Only the "Software: TBD" line is filled in, spliced by
--     offset because the blob has newlines BETWEEN tags (a single-line
--     REPLACE across them silently no-ops).
--   - course_C740_funding_and_grant: already reads "No funding is available for
--     this course", which stays true.
--   - course_C740_certification_exam: the Google Cloud certification registration
--     link is still correct for the ML Engineer exam.
--   - trainerprofile / trainers.
--
-- Partner-safe: C740 exists only on SG => @e IS NULL on MY/GH => all no-ops.
-- All replacement text is clean ASCII (apply.php connects charset=utf8).
--
-- AFTER DEPLOY (both required, neither is DDL):
--   a) reindex catalog_url_rewrite + catalog_product_flat, then flush cache, or
--      the new slug 404s and the page keeps serving the old copy.
--   b) RE-RENDER THE COVER: course_image_url is a baked PNG on R2 that has the
--      OLD title painted into it. Re-render with the product's own badges
--      (C740 is non-fundable => badges = []) -- never the Bulk AI Covers screen,
--      which posts one shared badge set across the batch.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C740' LIMIT 1);

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpth  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_sdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_who     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');
SET @a_prereq  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');
SET @a_price   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'price');
SET @a_ilabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_slabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_tlabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');

-- --------------------------------------------------------------- 1. name
UPDATE catalog_product_entity_varchar
   SET value = 'Google Professional Machine Learning Engineer Training'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- meta_title: PLAIN title only -- MMD_Seotitle appends the brand postfix at
-- render time, so baking "| Tertiary Courses Singapore" in here duplicates it.
-- (The OLD value had it baked in; this drops it.)
UPDATE catalog_product_entity_varchar
   SET value = 'Google Professional Machine Learning Engineer Training'
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND @e IS NOT NULL;

-- ------------------------------------------------------- 2. meta description
-- meta_description is varchar(255) -- keep under the cap or the write truncates.
-- No funding wording: this is the UNFUNDED twin.
UPDATE catalog_product_entity_varchar
   SET value = 'Prepare for the Google Professional Machine Learning Engineer certification. Build and deploy scalable ML models with Vertex AI, TensorFlow and BigQuery ML, and apply MLOps best practices in this hands-on 4-day course in Singapore.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = 'Google Professional Machine Learning Engineer, Machine Learning Certification, Vertex AI, TensorFlow, BigQuery ML, MLOps, Feature Engineering, Google Cloud, Exam Prep, Course, Singapore'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------------------------------ 3. slug
-- An is_system row on the OLD bare slug would block the 301 INSERT below on the
-- unique key, so drop it first; the indexer regenerates one for the NEW slug.
DELETE FROM core_url_rewrite
 WHERE product_id = @e AND is_system = 1
   AND request_path = 'google-professional-cloud-architecture-certification-exam-prep.html'
   AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'google-professional-machine-learning-engineer-training'
 WHERE entity_id = @e AND attribute_id = @a_urlkey AND @e IS NOT NULL;

-- Drop url_path at EVERY scope so the URL-rewrite indexer regenerates it.
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlpth AND @e IS NOT NULL;

-- Explicit 301 for the old BARE slug.
INSERT IGNORE INTO core_url_rewrite
    (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT s.store_id, NULL, @e,
       CONCAT('product/', @e),
       'google-professional-cloud-architecture-certification-exam-prep.html',
       'google-professional-machine-learning-engineer-training.html',
       0, 'RP', '1485 repurpose 301'
  FROM core_store s
 WHERE s.store_id > 0 AND @e IS NOT NULL;

-- Flatten the ~20 legacy chains (macos-training-740, windows-1x-essential-*,
-- google-associate-cloud-engineer-*, the category-prefixed variants) that 301
-- INTO the old bare slug, so they stay ONE hop instead of becoming two.
UPDATE core_url_rewrite
   SET target_path = 'google-professional-machine-learning-engineer-training.html'
 WHERE is_system = 0
   AND target_path = 'google-professional-cloud-architecture-certification-exam-prep.html'
   AND request_path <> 'google-professional-machine-learning-engineer-training.html'
   AND @e IS NOT NULL;

-- The category-scoped legacy chains point at
-- '<category>/google-professional-cloud-architecture-...html', which the
-- indexer will no longer generate. Flatten those to the new BARE slug too --
-- a category-prefixed target that stops existing is a 301 -> 404.
UPDATE core_url_rewrite
   SET target_path = 'google-professional-machine-learning-engineer-training.html'
 WHERE is_system = 0
   AND target_path LIKE '%/google-professional-cloud-architecture-certification-exam-prep.html'
   AND @e IS NOT NULL;

-- ------------------------------------------------------- 4. Topics Covered
-- The WSQ parent's 8 topics, verbatim (clean ASCII, newlines as \r\n escapes).
UPDATE catalog_product_entity_text
   SET value = '<h3 class="course-topic-h3">Topic 1 Google Cloud Big Data and Machine Learning Fundamentals</h3>\n<ul>\n<li>Data-to-AI lifecycle on Google Cloud and the major products of big data and machine learning.</li>\n<li>Design streaming pipelines with Dataflow and Pub/Sub and design streaming pipelines with Dataflow and Pub/Sub.</li>\n<li>Options to build machine learning solutions on Google Cloud.</li>\n<li>Machine learning workflow and the key steps with Vertex AI and build a machine learning pipeline using AutoML.</li>\n</ul>\n<h3 class="course-topic-h3">Topic 2 How Google does Machine Learning</h3>\n<ul>\n<li>Vertex AI Platform and how it\'s used to quickly build, train, and deploy AutoML machine learning models without writing any code</li>\n<li>Best practices for implementing machine learning on Google Cloud</li>\n<li>Leverage Google Cloud tools and environment to do ML</li>\n<li>Responsible AI best practices</li>\n</ul>\n<h3 class="course-topic-h3">Topic 3 Launching into Machine Learning</h3>\n<ul>\n<li>Improve data quality and perform exploratory data analysis</li>\n<li>Build and train AutoML Models using Vertex AI and BigQuery ML</li>\n<li>Optimize and evaluate models using loss functions and performance metrics</li>\n<li>Create repeatable and scalable training, evaluation, and test datasets</li>\n</ul>\n<h3 class="course-topic-h3">Topic 4 TensorFlow on Google Cloud</h3>\n<ul>\n<li>Create TensorFlow and Keras machine learning models and describe their key components.</li>\n<li>Use the tf.data library to manipulate data and large datasets.</li>\n<li>Use the Keras Sequential and Functional APIs for simple and advanced model creation.</li>\n<li>Train, deploy, and productionalize ML models at scale with Vertex AI.</li>\n</ul>\n<h3 class="course-topic-h3">Topic 5 Feature Engineering</h3>\n<ul>\n<li>Describe Vertex AI Feature Store and compare the key required aspects of a good feature.</li>\n<li>Perform feature engineering using BigQuery ML, Keras, and TensorFlow.</li>\n<li>Discuss how to preprocess and explore features with Dataflow and Dataprep.</li>\n<li>Use tf.Transform.</li>\n</ul>\n<h3 class="course-topic-h3">Topic 6 Machine Learning in the Enterprise</h3>\n<ul>\n<li>Describe data management, governance, and preprocessing options</li>\n<li>Identify when to use Vertex AutoML, BigQuery ML, and custom training</li>\n<li>Implement Vertex Vizier Hyperparameter Tuning</li>\n<li>Explain how to create batch and online predictions, setup model monitoring, and create pipelines using Vertex AI</li>\n</ul>\n<h3 class="course-topic-h3">Topic 7 Production Machine Learning Systems</h3>\n<ul>\n<li>Compare static versus dynamic training and inference</li>\n<li>Manage model dependencies</li>\n<li>Set up distributed training for fault tolerance, replication, and more</li>\n<li>Export models for portability</li>\n</ul>\n<h3 class="course-topic-h3">Topic 8 Machine Learning Operations (MLOps)</h3>\n<ul>\n<li>Core technologies required to support effective MLOps.</li>\n<li>Adopt the best CI/CD practices in the context of ML systems.</li>\n<li>Configure and provision Google Cloud architectures for reliable and effective MLOps environments.</li>\n<li>Implement reliable and repeatable training and inference workflows.</li>\n<li>ML Pipelines on Google Cloud</li>\n</ul>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

-- --------------------------------------------------- 5. About This Course
-- The parent's overview prose. It states no day/hour count and carries no
-- funding wording, so nothing here can contradict C740's own tiles
-- (Sessions 4 / Duration 30) or reintroduce WSQ framing onto an unfunded course.
UPDATE catalog_product_entity_text
   SET value = '<p>Embark on a transformative journey towards becoming a Google Professional Machine Learning Engineer. Our comprehensive preparation course is meticulously designed to cover all the critical facets of machine learning, ensuring you gain the expertise needed to pass the certification exam confidently. By engaging with this course, you will dive deep into the development of scalable machine learning models, understanding complex data pipelines, and deploying robust ML projects using Google Cloud technologies. This certification signifies to employers that you possess the acumen to leverage machine learning in a way that drives powerful, innovative solutions.</p> <p>This advanced training program goes beyond the fundamentals, providing insights into machine learning algorithms, model optimization, and problem-solving techniques crucial for real-world applications. You will learn how to approach machine learning engineering with an ethical and socially responsible lens while mastering the skills to build, test, and deploy AI systems that are scalable and reliable. Our curriculum is crafted to ensure that upon completion, you will not only be prepared for the Google Professional Machine Learning Engineer exam but also equipped to propel your career forward in the thriving field of AI and machine learning.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0 AND @e IS NOT NULL;

-- --------------------------------------------------------- 6. Job roles
UPDATE catalog_product_entity_text
   SET value = '<ul>\n<li>Data Scientist</li>\n<li>Machine Learning Engineer</li>\n<li>AI Engineer</li>\n<li>Data Analyst</li>\n<li>Software Engineer</li>\n<li>Cloud Solutions Architect</li>\n<li>Research Scientist</li>\n<li>Application Developer</li>\n<li>Big Data Engineer</li>\n<li>Business Intelligence Developer</li>\n<li>Robotics Engineer</li>\n<li>Quantitative Analyst</li>\n<li>Systems Analyst</li>\n<li>Product Manager</li>\n<li>Technical Program Manager</li>\n</ul>'
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------------------- 7. Software block
-- Fill the 'Software: TBD' placeholder with Google Cloud. Spliced by offset on
-- the unique '<p>TBD</p>' line: the blob has newlines BETWEEN the tags, so a
-- single-line REPLACE() across them silently no-ops. @tbd > 0 makes this
-- converge on a re-run and no-op on partner sites.
SET @prereq := (SELECT value FROM catalog_product_entity_text
                 WHERE entity_id = @e AND attribute_id = @a_prereq AND store_id = 0 LIMIT 1);
SET @tbd := (SELECT LOCATE('<p>TBD</p>', @prereq));

UPDATE catalog_product_entity_text
   SET value = CONCAT(
       SUBSTRING(@prereq, 1, @tbd - 1),
       '<p>You can sign up for the following:</p>\r\n<ul>\r\n<li><a href="https://cloud.google.com/" target="_blank"><span style="text-decoration: underline;">Google Cloud</span></a></li>\r\n</ul>',
       SUBSTRING(@prereq, @tbd + CHAR_LENGTH('<p>TBD</p>'))
   )
 WHERE entity_id = @e AND attribute_id = @a_prereq AND store_id = 0
   AND @e IS NOT NULL AND @tbd > 0;

-- ------------------------------------------------------------- 8. price
-- 4-day non-WSQ: $1400 (was 1200).
UPDATE catalog_product_entity_decimal
   SET value = 1400.0000
 WHERE entity_id = @e AND attribute_id = @a_price AND @e IS NOT NULL;

-- ----------------------------------------------------------- 9. alt text
UPDATE catalog_product_entity_varchar
   SET value = 'Google Professional Machine Learning Engineer Training'
 WHERE entity_id = @e AND attribute_id IN (@a_ilabel, @a_slabel, @a_tlabel) AND @e IS NOT NULL;

-- The media gallery label is the alt= the storefront actually renders.
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'Google Professional Machine Learning Engineer Training'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- -------------------------------------------------------- 10. categories
-- Add the ML/AI homes the parent sits in; the course is no longer about cloud
-- architecture. 419/420 (Google cert prep) and 184 (Google Cloud) stay -- this
-- is still a Google Cloud certification. 87 (Cloud Computing) stays for the
-- same reason and because the parent is in it too.
-- Added: 186 Computer Vision, 245 AI for Machine Learning, 252 AI Courses.
-- Deliberately NOT added: 250 (AI Infrastructure Series) and every WSQ-only
-- category (15, 292, 293, 301, 325, 345, 383) -- an unfunded C-prefix course
-- must never appear in a WSQ listing.
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT c.entity_id, @e, 0
  FROM catalog_category_entity c
 WHERE c.entity_id IN (186, 245, 252) AND @e IS NOT NULL;

-- ------------------------------------------------ 11. search-term redirects
-- Retarget every stored redirect that still points at the old course page.
-- Only rows whose redirect is ALREADY the old URL are touched, so no
-- intentional redirect elsewhere is overwritten.
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/google-professional-machine-learning-engineer-training.html'
 WHERE redirect = 'https://www.tertiarycourses.com.sg/google-professional-cloud-architecture-certification-exam-prep.html'
   AND query_text IN ('c740', 'c0740')
   AND @e IS NOT NULL;

-- The cloud-architect SEARCH TERMS ('Cloud architect', 'Professional Cloud
-- Architect', 'cloud architect certification', 'Cloud architecture', 'Google
-- Cloud Certified Professional Cloud Architect Exam Prep') no longer describe
-- this course. Leaving them pointed here would send cloud-architecture seekers
-- to an ML course. Clear them instead and let Magento search answer -- better an
-- honest result page than a confidently wrong redirect.
UPDATE catalogsearch_query
   SET redirect = NULL
 WHERE redirect = 'https://www.tertiarycourses.com.sg/google-professional-cloud-architecture-certification-exam-prep.html'
   AND query_text NOT IN ('c740', 'c0740')
   AND @e IS NOT NULL;
