-- 1442: Repurpose C744 "Claude Certified Associate - Foundations Certification"
-- -> "Claude Design for UX/UI".
--
-- Content mirrors the WSQ twin CASL - UI Design with AI
-- (TGS-2026064709, /casl-ui-design-with-ai.html): same four topics, same
-- overview arc, rewritten for the Claude non-WSQ course. WSQ/CASL/funding
-- language is stripped per the non-WSQ rule (no scheme names in course copy).
--
-- Also: 2 days/15h -> 1 day/7.5h, $700 -> $350, new url_key + 301 off the old
-- slug, joins the UX/UI Design category (359 on SG), and repoints the Funding
-- block at this course's OWN WSQ twin (was pointing at an unrelated agentic-AI
-- course -- bulk-seeded cross-link, see project_nonwsq_courseware_no_funding_at_all).
--
-- The cover PNG bakes the title, so it is re-rendered out-of-band on prod and
-- course_image_url is NOT written here (a stale URL would be worse than none).
--
-- Business-key lookups throughout, so this is a clean no-op on partner sites
-- that lack the SKU/category. Idempotent. Store scope 0.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C744');

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_dur   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='duration');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_price := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='price');

-- ---------------------------------------------------------------- name
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'Claude Design for UX/UI' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------- overview
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Unlock your potential in user interface (UI) design with Claude Design for UX/UI. Discover how artificial intelligence is transforming the design process and learn to combine human creativity with AI-powered tools for faster, smarter and more impactful results. From wireframing and prototyping to user testing, you will gain a comprehensive understanding of how to integrate Claude into every stage of the UI design workflow.</p>
<p>Structured with hands-on activities and real-world projects, this 1-day course emphasises the practical skills today&rsquo;s designers need. You will learn how to analyse user needs, generate design concepts with AI assistance, build interactive prototypes and validate them with AI-driven testing methods. By the end of the course, you will have a strong foundation in AI-enhanced UI design and a portfolio-ready project, positioning you for a future-ready career in UX/UI design.</p>'
FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------- topics
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Requirements for AI-Enhanced UI Design</h3>
<ul>
<li>Apply the Design Thinking Approach with AI Support</li>
<li>Use Claude to Understand User Expectations and Identify User Needs</li>
<li>Map and Analyse Information Flow with AI-Powered Insights</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Components and States</h3>
<ul>
<li>Explore Essential UI Design Tools and AI Features</li>
<li>Develop and Manage Intelligent Components</li>
<li>Add and Configure Adaptive States for Components</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Design and Evaluate AI-Driven Graphic User Interface (GUI)</h3>
<ul>
<li>Create Interactive and AI-Assisted GUI Prototypes</li>
<li>Share and Validate GUI Prototypes Using AI-Enhanced User Testing</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Documentation and Collaboration</h3>
<ul>
<li>Document Using AI-Integrated Design Systems</li>
<li>Collaborate and Update Projects via Cloud and AI Platforms</li>
<li>Export and Prepare Optimised Design Assets with AI</li>
</ul>'
FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------- metas
-- meta_title stored BARE (MMD_Seotitle appends the brand at render time).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Claude Design for UX/UI' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_description is varchar(255) -- keep under the cap.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Learn AI-enhanced UI design with Claude. Analyse user needs, build intelligent components and adaptive states, prototype and validate GUIs, and document design systems in this hands-on 1-day course in Singapore.'
FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Claude Design, UX Design, UI Design, AI UI Design, Design Thinking, Prototyping, Wireframing, Design Systems, GUI Design, Claude, Generative AI'
FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------- 1 day / 7.5h
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_dur, 0, @e, '7.5' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------- $350
INSERT INTO catalog_product_entity_decimal (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_price, 0, @e, 350.0000 FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------- url_key
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'claude-design-for-ux-ui' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Clear per-store overrides so store 1 cannot shadow the store-0 values above.
DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND @e IS NOT NULL
  AND attribute_id IN (@a_name, @a_mt, @a_md, @a_dur, @a_url);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND @e IS NOT NULL
  AND attribute_id IN (@a_short, @a_desc, @a_mk);
DELETE FROM catalog_product_entity_decimal
WHERE entity_id=@e AND store_id<>0 AND @e IS NOT NULL AND attribute_id=@a_price;

-- ---------------------------------------------------------------- 301s
-- DELETE the is_system=1 row squatting on the OLD slug FIRST: it shares the
-- id_path the 301 needs, so INSERT IGNORE would silently no-op and the new
-- slug would get a -744 suffix (feedback_repurpose_301_needs_system_row_delete).
DELETE FROM core_url_rewrite
WHERE product_id=@e AND is_system=1 AND @e IS NOT NULL
  AND request_path IN ('claude-certified-associate-foundations-certification.html',
                       'adult-training-courses/claude-certified-associate-foundations-certification.html');

-- Drop any non-system squatter already holding the NEW path.
DELETE FROM core_url_rewrite
WHERE request_path='claude-design-for-ux-ui.html' AND is_system=0;

INSERT IGNORE INTO core_url_rewrite
  (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options)
SELECT 1, NULL, @e, CONCAT('product/', @e), 'claude-certified-associate-foundations-certification.html',
       'claude-design-for-ux-ui.html', 0, 'RP'
FROM dual WHERE @e IS NOT NULL;

-- Flatten the existing chains (old Unreal-era aliases pointed at the old slug)
-- so nothing 301-hops twice.
UPDATE core_url_rewrite
SET target_path='claude-design-for-ux-ui.html'
WHERE is_system=0 AND options='RP'
  AND target_path IN ('claude-certified-associate-foundations-certification.html',
                      'adult-training-courses/claude-certified-associate-foundations-certification.html')
  AND request_path <> 'claude-design-for-ux-ui.html';

-- ---------------------------------------------------------------- UX/UI category
-- Resolved by url_key so the id can differ per site (359 on SG).
SET @uxui := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='ux-ui-design-courses' LIMIT 1);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @uxui, @e, 5 FROM dual WHERE @uxui IS NOT NULL AND @e IS NOT NULL;

-- Non-WSQ rows in this category are alphabetical after the TGS- block.
-- "Claude Design for UX/UI" sorts before "Prototyping..." -> slot 5, push the
-- two later titles down. Mirror into the index (that is what the storefront
-- actually sorts by).
UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id=cp.product_id
SET cp.position = CASE p.sku WHEN 'C744' THEN 5 WHEN 'C1268' THEN 6 WHEN 'C775' THEN 7 END
WHERE cp.category_id=@uxui AND @uxui IS NOT NULL
  AND p.sku IN ('C744','C1268','C775');

UPDATE catalog_category_product_index ci
JOIN catalog_product_entity p ON p.entity_id=ci.product_id
SET ci.position = CASE p.sku WHEN 'C744' THEN 5 WHEN 'C1268' THEN 6 WHEN 'C775' THEN 7 END
WHERE ci.category_id=@uxui AND @uxui IS NOT NULL
  AND p.sku IN ('C744','C1268','C775');

-- ---------------------------------------------------------------- funding block
-- Content-only UPDATE. NEVER ->save() a cms/block model: it wipes
-- cms_block_store and 404s the page (feedback_cms_model_save_wipes_store_mapping).
-- Repointed at this course's OWN WSQ twin; it previously cross-linked to an
-- unrelated agentic-AI course from the bulk seed.
UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>
<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/casl-ui-design-with-ai.html" title="CASL - UI Design with AI">CASL - UI Design with AI</a></span></p>'
WHERE identifier = 'course_C744_funding_and_grant';
