-- 1531: Repurpose TGS-2026064720
--   "CASL - AI Vibe Coding with PyTorch"
--     -> "CASL - AI Vibe Coding for Advanced Data Modeling"
--
-- Admin-supplied 2026-09-22 (new LOs, 5 topics, About narrative). SKU unchanged
-- (every SkillsFuture / SFEC / SFC / PSEA / UTAP deep link is keyed on it).
-- The "CASL - " H1 prefix is RETAINED (admin-confirmed 2026-09-22).
--
-- This is a CASL/WSQ (TGS-) course, NOT a member of the SG non-WSQ "AI Vibe
-- Coding Series". The series standard (4 topics / 15 hrs / $700 / red series
-- badge) deliberately does NOT apply here: the admin spec carries 6 learning
-- outcomes and 5 topics, which is the WSQ/CASL shape. price (750), duration
-- (16), sessions (2) and the badge tags are accredited params and stay as-is.
--
-- Surfaces touched, from a pre-write sweep of the LIVE SG product page (the
-- local DB has no row for this SKU, so the rendered page + its LSN_DATA/JSON-LD
-- were the source of truth -- do not trust an enumerated list, the sweep is
-- what found these):
--   name, url_key (+ url_path DELETE at every scope), meta_title,
--   meta_description, meta_keyword, short_description (About narrative),
--   description (5 topics, LSN_DATA comment format), learning_outcomes cms_block,
--   image_label/small_image_label/thumbnail_label, media-gallery label,
--   whoshouldattend (job roles named the OLD tech), prerequisite (the ONE
--   software-requirement line naming PyTorch), trainerprofile (teaching
--   sentences only), course_image_url (new R2 cover), and a 301 for the old
--   bare slug.
--
-- TOPIC FORMAT: this course uses the LSN_DATA HTML-comment format (NOT the
-- h3.course-topic-h3 format used by the C-prefix series). The comment is the
-- machine-readable source; the visible <strong> lines must mirror it exactly or
-- the card and the parsed outline disagree.
--
-- meta_title: PLAIN title -- NO leading "WSQ"/"CASL", NO "| Tertiary Courses
-- Singapore" suffix. MMD_Seotitle composes <title> at render time (prepends
-- "WSQ funded" for SG TGS- SKUs and appends the brand postfix). The OLD value
-- baked in both, which is the 853 bug; this migration cleans that up too.
--
-- TRAINER BIOS -- surgical, not wholesale. The bios mention PyTorch in two ways:
--   * CAREER CREDENTIALS (facts): "taught ... deep learning with TensorFlow and
--     PyTorch, and computer vision with OpenCV", "IBM certifications in Python,
--     machine learning, and deep learning using TensorFlow and PyTorch". These
--     are TRUE and are LEFT ALONE -- rewriting them would falsify a real
--     person's bio.
--   * COURSE-TEACHING CLAIMS: "he emphasizes the use of PyTorch for building
--     deep learning models...", "His courses cover ... implementing them in
--     PyTorch...". These describe what is taught on THIS course and are
--     retargeted to neural-network-based advanced data modeling.
-- Each is an exact-string REPLACE() on a SINGLE line -- multi-line REPLACE()
-- silently no-ops on these CRLF WYSIWYG blobs.
--
-- prerequisite: holds the ENTIRE funding apparatus (PWM, Funding Eligibility
-- table, SkillsFuture/PSEA/SFEC/UTAP/NTUC/MOM deep links, Appeal Process).
-- NEVER rewritten wholesale -- only the one software-requirement line naming
-- PyTorch is swapped.
--
-- Deliberately UNCHANGED (verified against the live page before writing):
--   * sku, price (750.00), duration (16), sessions (2) -- accredited params.
--   * course_TGS-2026064720_funding_and_grant / _certification / _brochure /
--     _skills_framework -- keyed on the unchanged SKU; WSQ accreditation, the
--     fee table and OpenCerts wording are unaffected by a title change.
--   * badge tags (WSQ, SkillsFuture Credit, PSEA) -- funding eligibility is
--     unchanged; the new cover render resolved the same three from the SKU.
--   * image/small_image/thumbnail PATHS -- filesystem paths, not display text;
--     renaming them 404s the file. The storefront renders course_image_url
--     (updated below). Only the LABELS (alt text) change.
--   * catalogsearch_query -- search redirects are DATA and are applied live,
--     never via a migration.
--
-- NEW SLUG COLLISION CHECK (2026-09-22): the new slug returns 404 on
-- www.tertiarycourses.com.sg and no url_key row matches '%advanced-data-
-- modeling%', so the slug is free.
--
-- PARTNER SAFETY: TGS- SKUs are Singapore WSQ/CASL courses; MY/GH partner DBs
-- have no such SKU, so @e is NULL there and every statement matches zero rows
-- (clean no-op). Same holds on any DB lacking this row.
--
-- IDEMPOTENCY: every statement either sets a full target value or REPLACE()s an
-- exact old string that no longer exists after the first run. Re-running
-- converges.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026064720');

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_cover   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_ilabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_slabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_tlabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');
SET @a_sdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_who     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='whoshouldattend');
SET @a_prereq  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='prerequisite');
SET @a_trainer := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='trainerprofile');

-- ---------------------------------------------------------------------------
-- 1. name  (keep the "CASL - " prefix -- the storefront H1 wants it)
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'CASL - AI Vibe Coding for Advanced Data Modeling'
WHERE entity_id = @e AND attribute_id = @a_name;

-- ---------------------------------------------------------------------------
-- 2. url_key + url_path
--    Delete url_path at EVERY scope so the URL Rewrites indexer regenerates.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'casl-ai-vibe-coding-for-advanced-data-modeling'
WHERE entity_id = @e AND attribute_id = @a_urlkey;

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND attribute_id = @a_urlpath;

-- Drop any is_system = 0 squatter on the NEW path first: INSERT IGNORE silently
-- no-ops against a stale row (the 647 trap).
DELETE FROM core_url_rewrite
WHERE request_path = 'casl-ai-vibe-coding-for-advanced-data-modeling.html' AND is_system = 0;

-- Explicit 301 for the old BARE slug. The indexer auto-301s the category paths
-- from its rewrite history; only the bare slug needs seeding.
INSERT IGNORE INTO core_url_rewrite
    (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT 1, NULL, @e,
       CONCAT('product/', @e),
       'casl-ai-vibe-coding-with-pytorch.html',
       'casl-ai-vibe-coding-for-advanced-data-modeling.html',
       0, 'RP', 'Repurpose 1531: old PyTorch slug -> AI Vibe Coding for Advanced Data Modeling'
FROM dual
WHERE @e IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
    WHERE x.request_path = 'casl-ai-vibe-coding-with-pytorch.html'
      AND x.store_id = 1 AND x.is_system = 0
);

-- ---------------------------------------------------------------------------
-- 3. meta_title / meta_description / meta_keyword
--    meta_title is the PLAIN title: MMD_Seotitle adds the "WSQ funded" prefix
--    and the brand suffix at render time. The old value baked in both.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'AI Vibe Coding for Advanced Data Modeling'
WHERE entity_id = @e AND attribute_id = @a_mtitle;

UPDATE catalog_product_entity_varchar
SET value = 'Build advanced predictive models with deep learning and AI coding assistants: neural networks for regression and classification, CNNs, and transformers. Enjoy up to 70% WSQ funding subsidy.'
WHERE entity_id = @e AND attribute_id = @a_mdesc;

UPDATE catalog_product_entity_text
SET value = 'AI Vibe Coding, Advanced Data Modeling, Deep Learning, Neural Networks, WSQ Funding, AI Coding Assistant, Convolutional Neural Network, Transformer Self-Attention, Predictive Modeling, Data Visualisation'
WHERE entity_id = @e AND attribute_id = @a_mkey;

-- ---------------------------------------------------------------------------
-- 4. Cover image (rendered + uploaded to R2 2026-09-22) + alt-text labels.
--    The labels carry the PLAIN title (the cover itself strips "CASL - ").
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026064720-20260922-152500.png'
WHERE entity_id = @e AND attribute_id = @a_cover;

UPDATE catalog_product_entity_varchar
SET value = 'AI Vibe Coding for Advanced Data Modeling'
WHERE entity_id = @e AND attribute_id IN (@a_ilabel, @a_slabel, @a_tlabel);

UPDATE catalog_product_entity_media_gallery_value v
JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
SET v.label = 'AI Vibe Coding for Advanced Data Modeling'
WHERE g.entity_id = @e;

-- ---------------------------------------------------------------------------
-- 5. short_description -- the "What's This Course About" narrative.
--    Admin-supplied 2026-09-22, verbatim (4 paragraphs).
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = '<p>AI Vibe Coding for Advanced Data Modeling equips participants with practical skills to build advanced predictive models using deep learning and AI-assisted coding techniques. Through natural-language instructions and AI coding assistants, learners will generate, explain, test, debug, and refine code for neural network models, making advanced data modelling more accessible and efficient.</p>
<p>Participants will begin with an overview of deep learning, exploring fundamental concepts such as tensors, neural network architectures, activation functions, loss functions, optimisers, gradient computation, and model training. They will then develop neural networks for regression to predict continuous outcomes and neural networks for classification to categorise data and support data-driven decision-making.</p>
<p>The course progresses to Convolutional Neural Networks (CNNs), where participants will learn to build models for image and pattern recognition tasks. Learners will also explore Transformers and self-attention, understanding how attention mechanisms enable models to identify relationships and contextual patterns within complex and sequential data.</p>
<p>Throughout the course, participants will use AI Vibe Coding to accelerate model development, troubleshoot errors, optimise model performance, and interpret results. By the end of the course, learners will be able to apply deep learning techniques to develop, evaluate, and refine advanced data models for prediction, classification, pattern recognition, and other real-world applications.</p>'
WHERE entity_id = @e AND attribute_id = @a_sdesc;

-- ---------------------------------------------------------------------------
-- 6. description -- the 5-topic course outline.
--    LSN_DATA comment (machine-readable) + the visible <strong> lines must
--    mirror each other exactly.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = '<!-- LSN_DATA: [{"title":"Topic 1 Overview of Deep Learning","subsecs":[]},{"title":"Topic 2 Neural Network for Regression","subsecs":[]},{"title":"Topic 3 Neural Network for Classification","subsecs":[]},{"title":"Topic 4 Convolutional Neural Network","subsecs":[]},{"title":"Topic 5 Transformer and Self-Attention","subsecs":[]}] -->
<p><strong>Topic 1 Overview of Deep Learning</strong></p>
<p><strong>Topic 2 Neural Network for Regression</strong></p>
<p><strong>Topic 3 Neural Network for Classification</strong></p>
<p><strong>Topic 4 Convolutional Neural Network</strong></p>
<p><strong>Topic 5 Transformer and Self-Attention</strong></p>'
WHERE entity_id = @e AND attribute_id = @a_desc;

-- ---------------------------------------------------------------------------
-- 7. learning_outcomes cms_block -- admin-supplied 2026-09-22 (6 outcomes).
--    Content-only UPDATE: never ->save() a cms/block model (wipes
--    cms_block_store -> 404s the page).
-- ---------------------------------------------------------------------------
UPDATE cms_block
SET content = '<p>At the end of this course, participants will be able to:</p>
<ul>
<li>apply machine learning principles to gain business insights.</li>
<li>aggregate data to help test problem.</li>
<li>apply predictive data modeling techniques to identify underlying trend and patterns in data using neural networks.</li>
<li>develop prototype classification model using machine learning techniques to gain new insight from data.</li>
<li>identify patterns using convolutional neural network model to derive insights and make decision.</li>
<li>use data visualisation tool to create interactive visualizations of data.</li>
</ul>'
WHERE identifier = 'course_TGS-2026064720_learning_outcomes';

-- ---------------------------------------------------------------------------
-- 8. whoshouldattend -- the job-role list named the OLD technology.
--    Re-pointed at data-modeling roles; generic data/AI roles are kept.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = '<ul>
<li>Machine Learning Engineer</li>
<li>Data Scientist</li>
<li>AI Research Scientist</li>
<li>Deep Learning Specialist</li>
<li>Predictive Modeling Specialist</li>
<li>Computer Vision Engineer</li>
<li>NLP Engineer</li>
<li>Data Analyst (expanding into deep learning)</li>
<li>Artificial Intelligence Consultant</li>
<li>Business Intelligence Specialist</li>
<li>Financial Forecasting Analyst</li>
<li>Data Engineer</li>
<li>Research Analyst</li>
<li>Analytics Consultant</li>
<li>Business Owner or Manager working with data</li>
</ul>'
WHERE entity_id = @e AND attribute_id = @a_who;

-- ---------------------------------------------------------------------------
-- 9. prerequisite -- swap ONLY the software-requirement line naming PyTorch.
--    Everything else (funding tables, PWM, all gov deep links) is untouched.
--    Two spellings are attempted because the blob's exact markup around the
--    tool name varies; each REPLACE() is a no-op if its needle is absent.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = REPLACE(value, 'Software: You can download and install the following software: PyTorch',
                           'Software: You can download and install the following software: Python with a deep learning framework')
WHERE entity_id = @e AND attribute_id = @a_prereq;

UPDATE catalog_product_entity_text
SET value = REPLACE(value, '<li>PyTorch</li>', '<li>Python with a deep learning framework</li>')
WHERE entity_id = @e AND attribute_id = @a_prereq;

-- ---------------------------------------------------------------------------
-- 10. trainerprofile -- retarget COURSE-TEACHING sentences only.
--     Career-history / credential sentences are deliberately left factual.
--     One exact single-line REPLACE() per bio (CRLF-safe).
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      'In predictive analytics, he emphasizes the use of PyTorch for building deep learning models that can forecast trends, detect anomalies, and classify outcomes.',
      'In predictive analytics, he emphasizes the use of neural networks for building deep learning models that can forecast trends, detect anomalies, and classify outcomes.'
    )
WHERE entity_id = @e AND attribute_id = @a_trainer;

UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      'His courses cover regression models, ensemble methods, and neural networks, with a focus on implementing them in PyTorch for real-world use cases.',
      'His courses cover regression models, ensemble methods, and neural networks, with a focus on implementing them with AI coding assistants for real-world use cases.'
    )
WHERE entity_id = @e AND attribute_id = @a_trainer;
