-- 1464: Repurpose C695
--   OLD: "Agentic AI for Instagram Marketing"
--   NEW: "Agentic AI for Market Research"
-- SKU unchanged (C695). Non-WSQ C-prefix course: 2 days / 15 hrs / $700.
-- Content follows the WSQ parent TGS-2022017520
-- (wsq-agentic-ai-for-market-research.html): same 4 topics, same About prose,
-- same job roles, same software (Claude + MCP).
--
-- This is a REPURPOSE, not a retitle -- the subject moves from Instagram/social
-- media to market research -- so content AND taxonomy surfaces both change.
--
-- Surfaces touched:
--   1  name / meta_title
--   2  meta_description / meta_keyword
--   3  url_key + url_path (deleted at every scope so the rewrite indexer
--      regenerates) + explicit 301 from the old bare slug
--   4  description      -> the WSQ parent's 4 topics
--   5  short_description-> the WSQ parent's "What's This Course About" prose
--   6  whoshouldattend  -> market-research job roles (from the WSQ parent)
--   7  prerequisite     -> the Software <li> only (Claude + MCP); the rest of
--                          that attribute is the entry-requirement apparatus
--   8  *_label (3) + media_gallery_value.label -> the real rendered alt text
--   9  categories       -> drop Instagram (232) + Social Media Marketing (118),
--                          add Marketing Analytics (126), matching the WSQ parent
--  10  funding block    -> repoint at the course's OWN WSQ parent
--  11  catalogsearch_query c695 / c0695 -> new slug
--
-- Deliberately NOT touched:
--   - image / small_image / thumbnail: filesystem PATHS; renaming 404s the JPG.
--     The storefront renders the R2 cover (course_image_url), which is
--     re-rendered out-of-band after deploy (the PNG bakes the title).
--   - price (700), duration (15), sessions (2): unchanged, and they already
--     match the WSQ parent's 2-day shape.
--   - trainerprofile: bios here carry no Instagram-specific teaching claim.
--   - brochure block: regenerated out-of-band from the new title.
-- Partner-safe: C695 exists only on SG => @e IS NULL on MY/GH => every
-- statement no-ops. All replacement text is clean ASCII (apply.php uses utf8).

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

-- --------------------------------------------------------------- 1. name
UPDATE catalog_product_entity_varchar
   SET value = 'Agentic AI for Market Research'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- meta_title: store the PLAIN title. MMD_Seotitle appends the brand postfix at
-- render time, so baking "| Tertiary Courses Singapore" here duplicates it.
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

-- ------------------------------------------- 3. url_key / url_path / 301
-- Clear any is_system = 0 squatter on the NEW path first: INSERT IGNORE would
-- silently no-op against a stale row.
DELETE FROM core_url_rewrite
 WHERE request_path = 'agentic-ai-for-market-research.html'
   AND is_system = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'agentic-ai-for-market-research'
 WHERE entity_id = @e AND attribute_id = @a_urlkey AND @e IS NOT NULL;

-- Drop url_path at EVERY scope so the URL-rewrite indexer regenerates it.
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlpth AND @e IS NOT NULL;

-- Explicit 301 for the old BARE slug.
--
-- An is_system = 1 rewrite already SQUATS the old bare slug (id_path
-- 'product/695'), so a bare INSERT IGNORE hits the unique key and silently
-- no-ops, leaving the old URL resolving to the product with no redirect
-- (feedback_repurpose_301_needs_system_row_delete -- caught by the local
-- apply.php dry-run on this very migration). Delete the system row first; the
-- rewrite indexer will regenerate a system row for the NEW slug.
DELETE FROM core_url_rewrite
 WHERE product_id = @e AND is_system = 1
   AND request_path = 'agentic-ai-for-instagram-marketing.html'
   AND @e IS NOT NULL;

-- The indexer auto-301s the category paths.
INSERT IGNORE INTO core_url_rewrite
    (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT s.store_id, NULL, @e,
       CONCAT('product/', @e),
       'agentic-ai-for-instagram-marketing.html',
       'agentic-ai-for-market-research.html',
       0, 'RP', '1464 repurpose 301'
  FROM core_store s
 WHERE s.store_id > 0 AND @e IS NOT NULL;

-- Flatten the inherited chains: rows that already 301 into the OLD bare slug
-- would become a 2-hop redirect. Repoint them straight at the new path.
UPDATE core_url_rewrite
   SET target_path = 'agentic-ai-for-market-research.html'
 WHERE is_system = 0
   AND target_path = 'agentic-ai-for-instagram-marketing.html'
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
-- Replace the "TBD" placeholder under Software only; the entry-requirement
-- apparatus around it must survive byte-identical.
--
-- The blob is a WYSIWYG value with newlines BETWEEN the tags, so a single-line
-- REPLACE() of '<p><strong>Software:</strong></p><p>TBD</p>' silently no-ops
-- (feedback_multiline_replace_fails_on_crlf_blobs -- caught by the local
-- apply.php dry-run on this very migration). Anchor on the '<p>TBD</p>' line
-- alone, which is unique in this attribute, and splice by offset instead so the
-- surrounding newlines survive whatever they are.
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
-- Drop the now-wrong topic categories; add Marketing Analytics (126), which is
-- where the WSQ parent sits. Category 232 (Instagram) and 118 (Social Media
-- Marketing) no longer describe this course.
DELETE FROM catalog_category_product
 WHERE product_id = @e AND category_id IN (118, 232) AND @e IS NOT NULL;
DELETE FROM catalog_category_product_index
 WHERE product_id = @e AND category_id IN (118, 232) AND @e IS NOT NULL;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT 126, @e, 0 FROM dual WHERE @e IS NOT NULL
  AND EXISTS (SELECT 1 FROM catalog_category_entity WHERE entity_id = 126);

-- Drop the stale is_system rewrites for the removed categories so the old
-- Instagram-scoped paths stop resolving to this product.
DELETE FROM core_url_rewrite
 WHERE product_id = @e AND is_system = 1 AND category_id IN (118, 232)
   AND @e IS NOT NULL;

-- -------------------------------------------------------- 10. funding block
-- Point at this course's OWN WSQ parent, not the unrelated BPA course.
UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-agentic-ai-for-market-research.html" title="WSQ - Agentic AI for Market Research">WSQ - Agentic AI for Market Research</a></span></p>'
 WHERE identifier = 'course_C695_funding_and_grant';

-- --------------------------------------------------- 11. search redirects
-- The two code lookups pointed at the old slug; retarget them. The remaining
-- Instagram-term rows are deliberately left pointing at the Instagram CATEGORY
-- page -- those searchers still want Instagram courses, not market research.
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/agentic-ai-for-market-research.html'
 WHERE redirect = 'https://www.tertiarycourses.com.sg/agentic-ai-for-instagram-marketing.html';
