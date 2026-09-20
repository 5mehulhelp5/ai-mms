-- 1468: Repurpose C386
--   OLD: "Agentic AI for Linkedin Marketing"
--   NEW: "Agentic AI for Market Research"
-- SKU unchanged (C386). Non-WSQ C-prefix course: 2 days / 15 hrs / $700.
-- Content follows the WSQ parent TGS-2022017520
-- (wsq-agentic-ai-for-market-research.html): same 4 topics, same About prose,
-- same job roles, same software (Claude + MCP).
--
-- HISTORY THAT MATTERS: migration 1464 made C695 the Market Research course,
-- then 1466 repurposed C695 again to "Agentic AI Applications with Codex".
-- 1466 therefore left FOUR is_system = 0 rows (id_path '1466_c695_codex_1' plus
-- three category paths) that 301 the market-research paths -> the Codex course.
-- Those rows SQUAT the slug this migration needs: without deleting them, C386's
-- new URL 301s away to Codex and the repurpose silently fails on the storefront.
-- Deleting them is correct, not destructive -- they only ever existed to cover a
-- slug that C695 held for two days and no longer wants.
--
-- Surfaces touched:
--   1  name / meta_title
--   2  meta_description / meta_keyword
--   3  url_key + url_path (dropped at every scope so the indexer regenerates)
--      + the squatter cleanup above + a 301 from the old linkedin slug
--   4  description      -> the WSQ parent's 4 topics
--   5  short_description-> the WSQ parent's "What's This Course About" prose
--   6  whoshouldattend  -> market-research job roles (from the WSQ parent)
--   7  prerequisite     -> the Software <li> only (Claude + MCP), spliced by
--                          offset: the blob has newlines BETWEEN the tags, so a
--                          single-line REPLACE() silently no-ops
--   8  *_label (3) + media_gallery_value.label (the real rendered alt text)
--   9  categories       -> drop Linkedin (231) + Social Media Marketing (118)
--                          + Infocomm Technology (55); add Marketing Analytics
--                          (126) to match the WSQ parent
--  10  funding block    -> repoint at this course's OWN WSQ parent (it currently
--                          points at an unrelated BPA course)
--  11  catalogsearch_query c386 / c0386 -> new slug
--
-- Deliberately NOT touched:
--   - image / small_image / thumbnail: filesystem PATHS; renaming 404s the JPG.
--   - price (700), duration (15), sessions (2): already the 2-day shape.
--   - trainerprofile: no LinkedIn-specific course-teaching claim in the bios.
--   - The LinkedIn CATEGORY (231) itself and its own course listings.
--   - The ~35 legacy 301s into the old linkedin slug are chain-flattened below
--     rather than deleted, so historical inbound links keep resolving.
-- Partner-safe: C386 exists only on SG => @e IS NULL on MY/GH => all no-ops.
-- All replacement text is clean ASCII (apply.php connects charset=utf8).

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C386' LIMIT 1);

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

-- --------------------------------------------------------------- 1. name
UPDATE catalog_product_entity_varchar
   SET value = 'Agentic AI for Market Research'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- meta_title: PLAIN title only -- MMD_Seotitle appends the brand postfix at
-- render time, so baking it in here duplicates it.
UPDATE catalog_product_entity_varchar
   SET value = 'Agentic AI for Market Research'
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND @e IS NOT NULL;

-- ------------------------------------------------------- 2. meta description
-- meta_description is varchar(255) -- keep under the cap or the write truncates.
UPDATE catalog_product_entity_varchar
   SET value = 'Use Claude Cowork, MCP tools and custom Claude Skills to run agentic market research. Analyse competitors, market trends, customer behaviour and marketing effectiveness in this hands-on 2-day course in Singapore.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = 'Agentic AI, Market Research, Claude Cowork, Claude Skills, MCP, Competitor Analysis, Customer Personas, Market Trends, Forecasting, Marketing Analytics, Consumer Insights, Course, Singapore'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------ 3. slug: clear the C695/Codex squatters FIRST
-- Migration 1466 pointed these at the Codex course when C695 moved off this
-- slug. Left in place they win over the product's own URL and 301 visitors away.
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND request_path IN (
        'agentic-ai-for-market-research.html',
        'adult-training-courses/agentic-ai-for-market-research.html',
        'agentic-ai-series/agentic-ai-for-market-research.html',
        'artificial-intelligence-courses/agentic-ai-for-market-research.html')
   AND @e IS NOT NULL;

-- Belt and braces: any OTHER non-system row still squatting a market-research
-- path (a later re-run of a Codex-era migration, say) that is not ours.
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND request_path LIKE '%agentic-ai-for-market-research.html'
   AND request_path NOT LIKE 'wsq-%'
   AND request_path NOT LIKE '%/wsq-%'
   AND target_path LIKE '%agentic-ai-applications-with-codex%'
   AND @e IS NOT NULL;

-- An is_system row on the OLD slug would block the 301 INSERT below on the
-- unique key, so drop it first; the indexer regenerates one for the NEW slug.
DELETE FROM core_url_rewrite
 WHERE product_id = @e AND is_system = 1
   AND request_path = 'agentic-ai-for-linkedin-marketing.html'
   AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'agentic-ai-for-market-research'
 WHERE entity_id = @e AND attribute_id = @a_urlkey AND @e IS NOT NULL;

-- Drop url_path at EVERY scope so the URL-rewrite indexer regenerates it.
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlpth AND @e IS NOT NULL;

-- Explicit 301 for the old BARE slug.
INSERT IGNORE INTO core_url_rewrite
    (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT s.store_id, NULL, @e,
       CONCAT('product/', @e),
       'agentic-ai-for-linkedin-marketing.html',
       'agentic-ai-for-market-research.html',
       0, 'RP', '1468 repurpose 301'
  FROM core_store s
 WHERE s.store_id > 0 AND @e IS NOT NULL;

-- Flatten the ~35 legacy chains (facebook-advertising-training-386,
-- linkedin-for-business-*, etc.) that 301 INTO the old bare slug, so they stay
-- one hop instead of becoming two.
UPDATE core_url_rewrite
   SET target_path = 'agentic-ai-for-market-research.html'
 WHERE is_system = 0
   AND target_path = 'agentic-ai-for-linkedin-marketing.html'
   AND request_path <> 'agentic-ai-for-market-research.html'
   AND @e IS NOT NULL;

-- ------------------------------------------------------- 4. Topics Covered
-- The WSQ parent's 4 topics, verbatim.
UPDATE catalog_product_entity_text
   SET value = '<h3>Topic 1 Identifying Market Research Data and Sources with Claude Cowork</h3><ul><li>Defining Research Objectives and Research Questions</li><li>Determining Data Types for Market Research</li><li>Identifying Reliable Information and Data Sources</li><li>Connecting Claude Cowork to Documents and Datasets with MCP</li><li>Organising and Verifying Research Inputs</li></ul><h3>Topic 2 Analysing Market Trends and Industry Developments</h3><ul><li>Gathering Industry Reports and Market Data</li><li>Determining Variables That Drive Market Movement</li><li>Competitor Analysis and Benchmarking with Agentic AI</li><li>Synthesising Findings Across Multiple Sources</li><li>Building a Reusable Trend Analysis Claude Skill</li></ul><h3>Topic 3 Customer Behaviour Analysis, Market Dynamics and Forecasting</h3><ul><li>Developing Customer Personas with Claude Cowork</li><li>Analysing Survey Responses and Customer Feedback</li><li>Exploring Market Dynamics and Segment Opportunities</li><li>Forecasting Techniques for Demand and Growth</li><li>Turning Exploration into Structured Research Reports</li></ul><h3>Topic 4 Evaluating Marketing Effectiveness with Agentic AI Models and Indicators</h3><ul><li>Defining Indicators, Events and Conversions</li><li>Modelling Techniques for Marketing Effectiveness</li><li>Evaluating Campaign Performance with AI Assistance</li><li>Visual Summaries and Actionable Recommendations</li><li>Building an End-to-End Agentic Market Research Workflow</li></ul>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

-- --------------------------------------------------- 5. About This Course
-- The WSQ parent's "What's This Course About" prose, with the WSQ framing
-- dropped (this is the unfunded C-prefix twin).
UPDATE catalog_product_entity_text
   SET value = '<p>This course equips participants with practical skills to use Claude Cowork and agentic AI to conduct efficient, structured, and insight-driven market research. Learners will use Claude Cowork to define research objectives, formulate research questions, identify reliable information sources, analyse competitors, explore industry trends, and understand customer needs and behaviours.</p><p>Participants will learn how to connect Claude Cowork with relevant documents, datasets, business applications, and research sources through Model Context Protocol (MCP) tools. These integrations enable AI-assisted workflows for gathering, organising, comparing, and synthesising information from multiple sources while maintaining human oversight and verifying the reliability of findings.</p><p>The course also guides learners in creating custom Claude Skills from real-world market research processes. These reusable skills can support activities such as developing customer personas, analysing survey responses, conducting competitor comparisons, evaluating market opportunities, identifying emerging trends, and producing structured research reports. Participants will learn to incorporate research frameworks, templates, evaluation criteria, and reporting standards into repeatable workflows.</p><p>Through hands-on activities and practical business scenarios, learners will use Claude Cowork to transform complex information into clear findings, visual summaries, and actionable recommendations. By the end of the course, participants will be able to build an agentic market research workflow that improves research efficiency, strengthens evidence-based decision-making, and supports the development of effective marketing and business strategies.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0 AND @e IS NOT NULL;

-- --------------------------------------------------------- 6. Job roles
UPDATE catalog_product_entity_text
   SET value = '<ul><li>Market Research Analyst</li><li>Market Intelligence Specialist</li><li>Consumer Insights Analyst</li><li>Competitive Intelligence Analyst</li><li>Digital Marketing Specialist</li><li>Content Marketing Manager</li><li>E-commerce Manager</li><li>User Experience (UX) Researcher</li><li>Business Analyst</li><li>Strategy and Planning Executive</li><li>Product Manager</li><li>Brand Strategist</li><li>Customer Acquisition Specialist</li><li>Media Planner</li><li>Business Owner or Entrepreneur conducting market research</li></ul>'
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------------------- 7. Software block
-- Splice by offset on the unique '<p>TBD</p>' line: the blob has newlines
-- BETWEEN the tags, so a single-line REPLACE() across them silently no-ops
-- (feedback_multiline_replace_fails_on_crlf_blobs). @tbd > 0 makes it converge
-- on a re-run and no-op on partner sites.
SET @prereq := (SELECT value FROM catalog_product_entity_text
                 WHERE entity_id = @e AND attribute_id = @a_prereq AND store_id = 0 LIMIT 1);
SET @tbd := (SELECT LOCATE('<p>TBD</p>', @prereq));

UPDATE catalog_product_entity_text
   SET value = CONCAT(
       SUBSTRING(@prereq, 1, @tbd - 1),
       '<p>You can sign up for the following:</p>\n<ul>\n<li><a href="https://claude.ai/" target="_blank"><span style="text-decoration: underline;">Claude</span></a></li>\n<li><a href="https://modelcontextprotocol.io/" target="_blank"><span style="text-decoration: underline;">Model Context Protocol (MCP)</span></a></li>\n</ul>',
       SUBSTRING(@prereq, @tbd + CHAR_LENGTH('<p>TBD</p>'))
   )
 WHERE entity_id = @e AND attribute_id = @a_prereq AND store_id = 0
   AND @e IS NOT NULL AND @tbd > 0;

-- ----------------------------------------------------------- 8. alt text
UPDATE catalog_product_entity_varchar
   SET value = 'Agentic AI for Market Research'
 WHERE entity_id = @e AND attribute_id IN (@a_ilabel, @a_slabel, @a_tlabel) AND @e IS NOT NULL;

-- The media gallery label is the alt= the storefront actually renders.
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'Agentic AI for Market Research'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- --------------------------------------------------------- 9. categories
-- Drop the now-wrong topic categories; add Marketing Analytics (126), where the
-- WSQ parent sits. 231 (Linkedin), 118 (Social Media Marketing) and 55
-- (Infocomm Technology) no longer describe this course.
DELETE FROM catalog_category_product
 WHERE product_id = @e AND category_id IN (55, 118, 231) AND @e IS NOT NULL;
DELETE FROM catalog_category_product_index
 WHERE product_id = @e AND category_id IN (55, 118, 231) AND @e IS NOT NULL;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT 126, @e, 0 FROM dual WHERE @e IS NOT NULL
  AND EXISTS (SELECT 1 FROM catalog_category_entity WHERE entity_id = 126);

-- Drop the stale is_system rewrites for the removed categories.
DELETE FROM core_url_rewrite
 WHERE product_id = @e AND is_system = 1 AND category_id IN (55, 118, 231)
   AND @e IS NOT NULL;

-- -------------------------------------------------------- 10. funding block
-- Point at this course's OWN WSQ parent, not the unrelated BPA course.
UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-agentic-ai-for-market-research.html" title="WSQ - Agentic AI for Market Research">WSQ - Agentic AI for Market Research</a></span></p>'
 WHERE identifier = 'course_C386_funding_and_grant';

-- --------------------------------------------------- 11. search redirects
-- The two code lookups pointed at the old slug. LinkedIn-term searches are left
-- pointing at the LinkedIn category page -- those searchers still want LinkedIn.
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/agentic-ai-for-market-research.html'
 WHERE redirect = 'https://www.tertiarycourses.com.sg/agentic-ai-for-linkedin-marketing.html';
