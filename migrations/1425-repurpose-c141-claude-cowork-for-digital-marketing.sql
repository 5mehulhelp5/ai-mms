-- 1425: Repurpose C141 "Claude Code for Digital Marketing"
--       -> "Claude Cowork for Digital Marketing"
--
-- Content + topics are cloned from the WSQ counterpart TGS-2023018659
-- (https://www.tertiarycourses.com.sg/wsq-claude-cowork-for-digital-marketing.html).
-- Topics mirror the WSQ course exactly: 3 titles, no sub-bullets.
-- Funding block repointed at that WSQ course (was still pointing at the stale
-- iOS/C++ course left over from this entity's previous life).
-- Schedule template is moved to the non-WSQ B05 counterpart of the WSQ parent's
-- "(SG) WSQ-B05" template (code match, per the non-wsq-schedule rule).
--
-- url_key is deliberately UNCHANGED (claude-code-for-digital-marketing) so the
-- existing URL and its SEO/backlinks keep working; no 301 needed.
-- Price ($700) and duration (15h) stay at the non-WSQ 2-day standard.
--
-- SG-only: guarded on the C141 SKU, which exists only on the SG site.
-- Idempotent: every write is INSERT ... ON DUPLICATE KEY UPDATE or a guarded UPDATE.

SET @eid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C141' LIMIT 1);

-- ---------------------------------------------------------------------------
-- 1. Name / meta (varchar, store 0)
-- ---------------------------------------------------------------------------
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_mtitle:= (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_cover := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @eid, 'Claude Cowork for Digital Marketing'
WHERE @eid IS NOT NULL AND @a_name IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @eid, 'Claude Cowork for Digital Marketing | Tertiary Courses Singapore'
WHERE @eid IS NOT NULL AND @a_mtitle IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @eid, 'Use Claude Cowork as an AI workspace for digital marketing - connect MCP tools, build reusable Claude Skills, and analyse campaign performance in this hands-on 2-day course.'
WHERE @eid IS NOT NULL AND @a_mdesc IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @eid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C141-20260917-180300.png'
WHERE @eid IS NOT NULL AND @a_cover IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------------------
-- 2. Overview + topics + keywords (text, store 0) — cloned from TGS-2023018659
-- ---------------------------------------------------------------------------
SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_mkw   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sdesc, 0, @eid,
'<p>This hands-on course equips digital marketers with the skills to use Claude Cowork as an intelligent workspace for content production, system integration, workflow automation, and marketing performance analysis. Participants will learn how to connect Claude Cowork with various Model Context Protocol (MCP) tools, enabling it to access business applications, marketing platforms, documents, data sources, and other digital systems within a unified workflow.</p><p>Learners will create reusable Claude Skills based on real-world marketing tasks, transforming proven work processes into repeatable AI-assisted workflows. These skills can support activities such as market research, campaign planning, audience profiling, SEO content creation, social media posts, email campaigns, advertising copy, content calendars, and marketing reports. Participants will also learn how to provide clear instructions, reference materials, brand guidelines, and quality criteria to produce consistent, brand-aligned content.</p><p>The course further explores how Claude Cowork can consolidate campaign data, analyse key marketing metrics, identify performance trends, and generate actionable recommendations. Through practical exercises, participants will build integrated digital marketing workflows that reduce repetitive work, improve content quality, and support faster, data-driven decisions. By the end of the course, learners will be able to use Claude Cowork, MCP tools, and custom Skills to create a scalable and efficient AI-powered digital marketing system.</p>'
WHERE @eid IS NOT NULL AND @a_sdesc IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Topics: mirror the WSQ course exactly - 3 titles, no sub-bullets.
-- Non-WSQ courses use the h3.course-topic-h3 format (not the LSN_DATA comment form).
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @eid,
'<h3 class="course-topic-h3">Topic 1: Integrating Claude Cowork with Digital Marketing Systems Using MCP Tools</h3>
<h3 class="course-topic-h3">Topic 2: Creating Reusable Claude Skills for Digital Marketing Content and Workflows</h3>
<h3 class="course-topic-h3">Topic 3: Analysing Marketing Performance and Generating Data-Driven Insights</h3>'
WHERE @eid IS NOT NULL AND @a_desc IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkw, 0, @eid,
'Claude Cowork, Digital Marketing, MCP Tools, Claude Skills, Marketing Automation, AI Content Creation, Marketing Analytics, Singapore'
WHERE @eid IS NOT NULL AND @a_mkw IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------------------
-- 3. Funding block -> the WSQ Claude Cowork course
--    Content-only UPDATE (never ->save() a cms/block: it wipes cms_block_store).
-- ---------------------------------------------------------------------------
UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>
<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-claude-cowork-for-digital-marketing.html" title="WSQ - Claude Cowork for Digital Marketing">WSQ - Claude Cowork for Digital Marketing</a></span></p>'
 WHERE identifier = 'course_C141_funding_and_grant';

-- ---------------------------------------------------------------------------
-- 4. Schedule template -> non-WSQ B05 (counterpart of the WSQ parent's
--    "(SG) WSQ-B05 Fri-Mon/Sat-Sun 1st/2nd wk", matched on template CODE).
--
--    NOT DONE IN SQL. custom_options_relation is keyed per OPTION
--    (group_id, option_id, product_id) - it does not merely link a product to a
--    template, so inserting a product/group row is impossible without first
--    materialising the template's options onto the product. Switching is done
--    through the supported path, which clones the template's options, snapshots
--    admin-confirmed dates and restores them:
--
--      Admin -> Course Schedule -> Schedule Template -> B05 -> Switch Template
--      (adminhtml/coursesave/switchScheduleTemplate), i.e.
--      Mage::getModel('mmd_agentapi/template')->applyGroupToProduct($group, $pid)
--
--    Applied on SG prod on 2026-09-17: C141 moved from B01 (gid 188) to
--    B05 (gid 271); the six orphaned B01 options were deleted afterwards.
--    Recorded here so a rebuilt DB is known to need the same switch.
