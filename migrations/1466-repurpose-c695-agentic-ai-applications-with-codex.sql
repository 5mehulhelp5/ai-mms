-- 1466: Repurpose C695
--   OLD: "Agentic AI for Market Research"   (set by 1464, same day)
--   NEW: "Agentic AI Applications with Codex"
-- SKU unchanged (C695).
--
-- Content follows the WSQ parent TGS-2023041081
-- (wsq-agentic-ai-applications-with-codex.html): same 4 topics, same About
-- prose, same job roles, same software (OpenAI Codex).
--
-- SHAPE CHANGE (explicit user instruction, diverges from the WSQ parent):
--   1 day / 7.5 hrs / S$350.  The WSQ parent is 2 days / 16 hrs / S$800.
--   7.5 + 1 session is the house non-WSQ 1-day convention (207 C-courses use
--   exactly '7.5'/'1'), and 7.5 = one 9:30am-5:30pm day
--   (feedback_nonwsq_duration_is_7p5_hours_per_day).
--
-- NOTE: C695 has NO duration/sessions rows at all (verified on prod
-- 2026-09-20) -- they are INSERTed here, not UPDATEd, or the shape silently
-- stays blank. Both are backend_type=varchar (attribute_id 145 / 151),
-- NOT decimal: writing them into catalog_product_entity_decimal would store a
-- value the storefront never reads.
--
-- Surfaces touched:
--   1  name / meta_title
--   2  meta_description / meta_keyword
--   3  url_key + url_path (dropped at every scope so the rewrite indexer
--      regenerates) + explicit 301 from the old bare slug + chain flatten
--   4  description      -> the WSQ parent's 4 topics, non-WSQ house shape
--   5  short_description-> the WSQ parent's About prose
--   6  whoshouldattend  -> the WSQ parent's job roles
--   7  prerequisite     -> Software block repointed at Codex (was Claude+MCP)
--   8  *_label (3) + media_gallery_value.label -> the real rendered alt text
--   9  categories       -> drop Digital Marketing (8) + Marketing Analytics
--                          (126); the course is no longer a marketing course
--  10  price 700 -> 350; duration/sessions INSERTed as 7.5 / 1
--  10b course_image_url -> fresh R2 cover rendered from the NEW title
--  11  funding block    -> repoint at the course's OWN WSQ parent
--  12  catalogsearch_query c695 / c0695 -> new slug
--
-- Deliberately NOT touched:
--   - Course Date / Course Time custom options. C695 currently sits on a
--     2-DAY schedule template ('19/20 Sep 2026 (Sat/Sun)' etc), which is wrong
--     for a 1-day course -- but a schedule TEMPLATE SWITCH IS NEVER DONE IN
--     SQL (feedback_schedule_template_switch_never_in_sql). It is a follow-up
--     admin action via the non-wsq-schedule skill: move B-series -> the
--     matching A-series (1-day) template.
--   - image / small_image / thumbnail: filesystem PATHS; renaming 404s the JPG.
--     The storefront renders the R2 cover (course_image_url), re-rendered
--     out-of-band after deploy (the PNG bakes the title).
--   - level (11 = Beginner), software (198 = Non-funded), status: correct.
--   - search terms 'agentic ai for market research' / 'agentic ai market
--     research' (query_id 78501 / 78559): these intentionally point at the WSQ
--     course wsq-agentic-ai-for-market-research.html, NOT at C695. They stay.
--   - brochure block: regenerated out-of-band from the new title.
--
-- Partner-safe: C695 exists only on SG => @e IS NULL on MY/GH => every
-- statement no-ops. All replacement text is clean ASCII (apply.php uses utf8) --
-- note the OLD prerequisite blob contains invalid UTF-8 bytes around
-- "GCE 'O' Levels", which is why that attribute is rewritten WHOLESALE rather
-- than spliced with REPLACE() (feedback_migration_applyphp_utf8_outage).

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C695' LIMIT 1);

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
SET @a_ilabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_slabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_tlabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');
SET @a_price   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'price');
SET @a_dur     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'duration');
SET @a_sess    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'sessions');

-- --------------------------------------------------------------- 1. name
UPDATE catalog_product_entity_varchar
   SET value = 'Agentic AI Applications with Codex'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- meta_title: store the PLAIN title. MMD_Seotitle appends the brand postfix at
-- render time, so baking "| Tertiary Courses Singapore" here duplicates it.
UPDATE catalog_product_entity_varchar
   SET value = 'Agentic AI Applications with Codex'
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND @e IS NOT NULL;

-- ------------------------------------------------------- 2. meta description
-- meta_description is varchar(255) -- keep under the cap or the write truncates.
-- (feedback_meta_description_255_char_cap)
UPDATE catalog_product_entity_varchar
   SET value = 'Build agentic AI applications with OpenAI Codex - plan, code, refactor and test with Codex Skills, MCP tools, RAG and multi-agent workflows in this hands-on 1-day course in Singapore.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = 'Codex course Singapore, agentic AI applications, AI coding agent training, Codex Skills, MCP tools course, RAG application development, multi-agent AI course, AI agent development course, Course, Singapore'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------- 3. url_key / url_path / 301
-- Clear any is_system = 0 squatter on the NEW path first: INSERT IGNORE would
-- silently no-op against a stale row. (Verified 0 rows on prod, but the DELETE
-- keeps this idempotent across re-runs and partner DBs.)
DELETE FROM core_url_rewrite
 WHERE request_path = 'agentic-ai-applications-with-codex.html'
   AND is_system = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'agentic-ai-applications-with-codex'
 WHERE entity_id = @e AND attribute_id = @a_urlkey AND @e IS NOT NULL;

-- Drop url_path at EVERY scope so the URL-rewrite indexer regenerates it.
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlpth AND @e IS NOT NULL;

-- Explicit 301 for the old BARE slug.
--
-- An is_system = 1 rewrite SQUATS the old bare slug (id_path 'product/695',
-- url_rewrite_id 15536177), so a bare INSERT IGNORE hits the unique key and
-- silently no-ops, leaving the old URL resolving to the product with no
-- redirect (feedback_repurpose_301_needs_system_row_delete). Delete the system
-- row first; the indexer regenerates a system row for the NEW slug.
DELETE FROM core_url_rewrite
 WHERE product_id = @e AND is_system = 1
   AND request_path = 'agentic-ai-for-market-research.html'
   AND @e IS NOT NULL;

-- The indexer auto-301s the category paths.
--
-- id_path must NOT be CONCAT('product/', @e) here. core_url_rewrite carries a
-- SECOND unique key -- UNQ_CORE_URL_REWRITE_ID_PATH_IS_SYSTEM_STORE_ID on
-- (id_path, is_system, store_id) -- and the ('product/695', 0, 1) slot is
-- ALREADY held by migration 1464's own 301 row (the one redirecting the
-- instagram slug, which the chain-flatten below repoints at the codex slug).
-- Reusing that id_path makes this INSERT IGNORE hit the unique key and
-- SILENTLY NO-OP, leaving agentic-ai-for-market-research.html with no rewrite
-- at all => a hard 404 on the URL that was live this morning. Verified locally:
-- the row was missing after the first apply.php run.
--
-- Use a unique, non-colliding id_path instead -- the same shape Magento itself
-- generates for custom (is_system = 0) rewrites.
INSERT IGNORE INTO core_url_rewrite
    (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT s.store_id, NULL, @e,
       CONCAT('1466_c695_codex_', s.store_id),
       'agentic-ai-for-market-research.html',
       'agentic-ai-applications-with-codex.html',
       0, 'RP', '1466 repurpose 301'
  FROM core_store s
 WHERE s.store_id > 0 AND @e IS NOT NULL;

-- Flatten the inherited chains. C695 carries a lot of history (instagram-*,
-- qoo10-*, social-media-marketing-*) whose rows already 301 into the OLD bare
-- slug and would otherwise become 2-hop redirects. Anchor on target_path so
-- every foreign alias is repointed
-- (feedback_rename_chain_flatten_must_anchor_request_path).
UPDATE core_url_rewrite
   SET target_path = 'agentic-ai-applications-with-codex.html'
 WHERE is_system = 0
   AND target_path = 'agentic-ai-for-market-research.html'
   AND request_path <> 'agentic-ai-for-market-research.html'
   AND @e IS NOT NULL;

-- Category-scoped chains (e.g. 'adult-training-courses/agentic-ai-for-market-research.html').
UPDATE core_url_rewrite
   SET target_path = REPLACE(target_path, 'agentic-ai-for-market-research.html', 'agentic-ai-applications-with-codex.html')
 WHERE is_system = 0
   AND target_path LIKE '%/agentic-ai-for-market-research.html'
   AND @e IS NOT NULL;

-- --------------------------------------------------------- 4. description
-- The WSQ parent's 4 topics. The parent stores them as bare <p><strong> lines
-- with no sub-bullets; the non-WSQ house shape is <h3 class="course-topic-h3">
-- plus a <ul> of subtopics, so the subtopics are expanded from the parent's
-- own About prose (workflows/tools/memory/RAG/multi-agent/testing/security).
-- Content is squeezed into ONE day: 4 topics, ~5 subtopics each.
UPDATE catalog_product_entity_text
   SET value = '<h3 class="course-topic-h3">Topic 1 Agentic AI Application Planning and Development with Codex</h3>\n<ul>\n<li>What is an Agentic AI Application?</li>\n<li>Setting Up Codex as an AI Coding Agent</li>\n<li>Translating Requirements into Working Software</li>\n<li>Understanding, Generating and Refactoring Code</li>\n<li>Diagnosing Issues and Validating Solutions</li>\n</ul>\n<h3 class="course-topic-h3">Topic 2 Building Reusable AI Workflows with Codex Skills and MCP Tools</h3>\n<ul>\n<li>Structured Workflows, Tool Use and Action Loops</li>\n<li>Memory and Context Management</li>\n<li>Connecting to External Systems with Model Context Protocol (MCP)</li>\n<li>Developing Reusable Codex Skills</li>\n<li>Human Approvals and Permission Control</li>\n</ul>\n<h3 class="course-topic-h3">Topic 3 Developing RAG and Multi-Agent Applications with Codex</h3>\n<ul>\n<li>Retrieval-Augmented Generation (RAG) Fundamentals</li>\n<li>Integrating APIs and Managing Application Data</li>\n<li>Implementing Application Interfaces</li>\n<li>Multi-Agent Coordination Patterns</li>\n<li>Deploying a Functional Agentic Application</li>\n</ul>\n<h3 class="course-topic-h3">Topic 4 Testing, Evaluating and Optimising Agentic AI Applications</h3>\n<ul>\n<li>Creating Tests and Evaluating Outputs with Codex</li>\n<li>Troubleshooting Failures and Improving Reliability</li>\n<li>Secure Coding and Data Privacy</li>\n<li>Responsible AI Practices and Human Oversight</li>\n<li>Documenting and Optimising Your Solution</li>\n</ul>\n'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

-- --------------------------------------------------- 5. short_description
-- The WSQ parent's About prose, verbatim except the WSQ-only framing.
UPDATE catalog_product_entity_text
   SET value = '<p>This course equips learners with practical skills to design, build, test, and optimise agentic AI applications using Codex. Participants will use Codex as an AI coding agent to translate application requirements into working software, understand existing codebases, generate and refactor code, diagnose issues, and validate solutions through testing and review.</p><p>Learners will explore the core components of agentic applications, including structured workflows, tool use, memory, context management, retrieval-augmented generation (RAG), action loops, human approvals, and multi-agent coordination. They will connect applications to external systems and data sources using Model Context Protocol (MCP) tools and develop reusable Skills for consistent, task-specific workflows.</p><p>The course covers the end-to-end development process, from defining use cases and planning system architecture to implementing interfaces, integrating APIs, managing data, and deploying functional applications. Participants will also use Codex to create tests, evaluate outputs, troubleshoot failures, improve reliability, and document their solutions.</p><p>Emphasis is placed on secure coding, permission control, data privacy, responsible AI practices, and human oversight. By the end of the course, learners will be able to use Codex to develop production-oriented agentic AI applications that can retrieve information, use tools, complete multi-step tasks, and support real-world business processes.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0 AND @e IS NOT NULL;

-- ----------------------------------------------------- 6. whoshouldattend
-- The WSQ parent's job roles verbatim.
UPDATE catalog_product_entity_text
   SET value = '<ul><li>AI Developer</li><li>Machine Learning Engineer</li><li>AI Solutions Architect</li><li>Data Scientist</li><li>AI Agent Engineer</li><li>Software Developer</li><li>AI Product Manager</li><li>Data Engineer</li><li>Prompt Engineer</li><li>AI Automation Consultant</li><li>Application Developer</li><li>R&amp;D Engineer (AI)</li><li>Technical Consultant (AI)</li><li>Business Intelligence Analyst</li><li>Innovation Manager</li><li>Systems Analyst</li><li>Tech Project Manager</li><li>Automation Engineer</li><li>AI Research Assistant</li><li>Solution Developer</li></ul>'
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0 AND @e IS NOT NULL;

-- -------------------------------------------------------- 7. prerequisite
-- Rewritten WHOLESALE, not spliced: the existing blob carries invalid UTF-8
-- bytes around "GCE 'O' Levels" that would abort apply.php on an INSERT..SELECT
-- and make any REPLACE() match unreliable. This is the non-WSQ entry
-- apparatus (Promotion Code + Minimum Entry Requirement + Software/Hardware) --
-- the WSQ parent's funding/PWM apparatus is deliberately NOT copied.
-- Software repointed from Claude + MCP to OpenAI Codex, matching the parent
-- ("You need an OpenAI Codex account (a paid ChatGPT plan is required)").
UPDATE catalog_product_entity_text
   SET value = '<h2>Promotion Code</h2><p>Your will get 10% discount voucher for 2nd course onwards if you write us a <u><a href="https://g.page/r/CeH-OtN8J4r9EB0/review" rel="noopener noreferrer" target="_blank">Google review</a>.</u></p><h2>Minimum Entry Requirement</h2><p>Knowledge and Skills</p><ul><li>Able to operate using computer functions</li><li>Minimum 3 GCE O Levels Passes including English or WPL Level 5 (Average of Reading, Listening, Speaking &amp; Writing Scores)</li></ul><p>Attitude</p><ul><li>Positive Learning Attitude</li><li>Enthusiastic Learner</li></ul><p>Experience</p><ul><li>Minimum of 1 year of working experience.</li></ul><p>Target Age Group: 18-65 years old</p><h2>Minimum Software/Hardware Requirement</h2><p><strong>Software:</strong></p><p>You can sign up for the following:</p>\n<ul>\n<li><a href="https://openai.com/codex/" target="_blank"><span style="text-decoration: underline;">OpenAI Codex</span></a> (a paid ChatGPT plan is required)</li>\n<li><a href="https://modelcontextprotocol.io/" target="_blank"><span style="text-decoration: underline;">Model Context Protocol (MCP)</span></a></li>\n</ul><p><strong>Hardware:</strong> Window or Mac Laptops</p>'
 WHERE entity_id = @e AND attribute_id = @a_prereq AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------------------------- 8. alt text
UPDATE catalog_product_entity_varchar
   SET value = 'Agentic AI Applications with Codex'
 WHERE entity_id = @e
   AND attribute_id IN (@a_ilabel, @a_slabel, @a_tlabel)
   AND @e IS NOT NULL;

-- The media-gallery per-image label is the REAL rendered alt/title on the
-- product-page zoom gallery (feedback_media_gallery_label_is_the_real_alt_text).
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'Agentic AI Applications with Codex'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ----------------------------------------------------------- 9. categories
-- Drop the marketing taxonomy: the course is now an AI development course.
-- Keeps 3 (All Courses), 189 (Agentic AI Series), 252 (AI Courses).
-- Resolve BY NAME so the statement is partner-safe and id-drift-proof
-- (feedback_course_repurpose_cross_site_rollout step 5).
DELETE cp FROM catalog_category_product cp
  JOIN catalog_category_entity_varchar cv
    ON cv.entity_id = cp.category_id AND cv.store_id = 0
   AND cv.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name')
 WHERE cp.product_id = @e
   AND cv.value IN ('Digital Marketing', 'Marketing Analytics')
   AND @e IS NOT NULL;

-- Mirror the removal into the category index, else the course keeps rendering
-- in those listings until a full reindex (feedback_category_swap_needs_index_mirror).
DELETE ci FROM catalog_category_product_index ci
  JOIN catalog_category_entity_varchar cv
    ON cv.entity_id = ci.category_id AND cv.store_id = 0
   AND cv.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name')
 WHERE ci.product_id = @e
   AND cv.value IN ('Digital Marketing', 'Marketing Analytics')
   AND @e IS NOT NULL;

-- Drop the now-dead category rewrites for those two (8 = Digital Marketing,
-- 126 = Marketing Analytics).
DELETE FROM core_url_rewrite
 WHERE product_id = @e
   AND id_path IN ('product/695/8', 'product/695/126')
   AND @e IS NOT NULL;

-- ------------------------------------------- 10. price / duration / sessions
-- 1 day, 7.5 hrs, S$350 (explicit user instruction).
UPDATE catalog_product_entity_decimal
   SET value = 350.0000
 WHERE entity_id = @e AND attribute_id = @a_price AND @e IS NOT NULL;

-- duration + sessions have NO rows for C695 -- INSERT, do not UPDATE.
-- ON DUPLICATE KEY UPDATE keeps this idempotent on re-run and correct on any
-- partner DB that does happen to carry a row.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_dur, 0, @e, '7.5'
 WHERE @e IS NOT NULL AND @a_dur IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sess, 0, @e, '1'
 WHERE @e IS NOT NULL AND @a_sess IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Any store-scoped override would shadow the store-0 values written above.
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id IN (@a_dur, @a_sess) AND store_id <> 0
   AND @e IS NOT NULL;

-- ------------------------------------------------------ 10b. R2 cover
-- The cover PNG bakes the course title, so the 1464 cover still reads
-- "Agentic AI for Market Research". A fresh PNG was rendered from the NEW
-- title with the SAME renderer (no badges -- C695 is a non-funded C-prefix
-- course) and uploaded to R2 BEFORE this migration ships, so the URL below is
-- already live (verified HTTP 200, image/png, 140547 bytes).
UPDATE catalog_product_entity_varchar
   SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C695-20260920-061726.png'
 WHERE entity_id = @e
   AND attribute_id = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url')
   AND store_id = 0
   AND @e IS NOT NULL;

-- Drop any store-scoped override so the store-0 value above wins.
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e
   AND attribute_id = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url')
   AND store_id <> 0
   AND @e IS NOT NULL;

-- ----------------------------------------------------- 11. funding block
-- Point at the course's OWN WSQ parent (TGS-2023041081).
UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-agentic-ai-applications-with-codex.html" title="WSQ - Agentic AI Applications with Codex">WSQ - Agentic AI Applications with Codex</a></span></p>'
 WHERE identifier = 'course_C695_funding_and_grant';

-- ------------------------------------------------- 12. search redirects
-- Only the course-code terms follow the entity. The term-based rows
-- ('agentic ai for market research' / 'agentic ai market research',
-- query_id 78501 / 78559) intentionally point at the WSQ market-research
-- course and are NOT touched here.
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/agentic-ai-applications-with-codex.html'
 WHERE query_text IN ('c695', 'c0695')
   AND redirect LIKE '%agentic-ai-for-market-research.html';
