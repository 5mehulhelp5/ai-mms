-- 1426: Repurpose C439 "Claude Certified Developer - Foundations Certification"
--       -> "Generative AI for Content Creation"
--
-- Content + topics are cloned from the WSQ counterpart TGS-2023037589
-- (https://www.tertiarycourses.com.sg/wsq-generative-ai-for-content-creation.html).
-- Topics mirror the WSQ course exactly: 3 topics with their sub-bullets.
-- Funding block repointed at that WSQ course (was pointing at the unrelated
-- "WSQ - Agentic AI Applications with Claude Code" from this entity's Claude life).
--
-- url_key CHANGES (claude-certified-developer-foundations-certification ->
-- generative-ai-for-content-creation): the old slug names a Claude certification
-- that no longer exists on this entity, so it must not keep resolving. A 301 is
-- added below so the old URL never 404s (see the course-url-change playbook).
--
-- Product image: the Magento image/small_image/thumbnail were STILL the stale
-- "/m/a/master-unity-and-c_-game-development..." jpg from an even earlier life of
-- this entity. Repointed to the new branded R2 cover and the stale gallery row
-- removed, so the storefront and the cover agree.
--
-- Category moves: OUT of Claude AI Series (281) + Claude Certification Exam Prep
-- (370), INTO Generative AI Series (433).
--
-- Price ($700) and duration (15h) stay at the non-WSQ 2-day standard.
-- Schedule template deliberately UNCHANGED (B15) - not part of this request.
--
-- SG-only: guarded on the C439 SKU, which exists only on the SG site.
-- Idempotent: every write is INSERT ... ON DUPLICATE KEY UPDATE or a guarded
-- UPDATE/DELETE, and every category write is INSERT IGNORE / guarded DELETE.

SET @eid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C439' LIMIT 1);

-- ---------------------------------------------------------------------------
-- 1. Name / url_key / meta / cover (varchar, store 0)
-- ---------------------------------------------------------------------------
SET @a_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_mtitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_cover  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @eid, 'Generative AI for Content Creation'
WHERE @eid IS NOT NULL AND @a_name IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_urlkey, 0, @eid, 'generative-ai-for-content-creation'
WHERE @eid IS NOT NULL AND @a_urlkey IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Clear any store-scoped url_key override so store 1 cannot resurrect the old slug.
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @eid AND attribute_id = @a_urlkey AND store_id <> 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @eid, 'Generative AI for Content Creation | Tertiary Courses Singapore'
WHERE @eid IS NOT NULL AND @a_mtitle IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @eid, 'Build a Generative AI content strategy - define objectives, apply prompt engineering, evaluate AI-generated content and manage ethical and legal concerns in this hands-on 2-day course at Tertiary Courses Singapore.'
WHERE @eid IS NOT NULL AND @a_mdesc IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @eid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C439-20260918-154518.png'
WHERE @eid IS NOT NULL AND @a_cover IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------------------
-- 2. Overview + topics + keywords (text, store 0) - cloned from TGS-2023037589
-- ---------------------------------------------------------------------------
SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_mkw   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sdesc, 0, @eid,
'<p>This course introduces participants to the dynamic field of Generative AI (GenAI) for content creation, focusing on developing a comprehensive content strategy that leverages AI tools to meet organizational goals. Participants will learn how to define their AI-generated content strategy objectives, identify their target audience, and understand the role of tools like ChatGPT in crafting engaging content. The course emphasizes the importance of aligning AI-generated content with business strategies, ensuring content not only captivates but also converts.</p><p>Beyond the basics, the course delves into the ethical and legal dimensions of using AI in content creation. It covers prompt engineering best practices, evaluating content ideas through market research, and the selection of suitable content management systems for AI-generated content. Participants will come away with a solid plan for managing their marketing content, equipped to navigate the emerging trends and ethical considerations in AI content delivery, ensuring their content strategy remains both innovative and responsible.</p>'
WHERE @eid IS NOT NULL AND @a_sdesc IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Topics: mirror the WSQ course - 3 topics with sub-bullets.
-- Non-WSQ courses use the h3.course-topic-h3 format (not the LSN_DATA comment form).
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @eid,
'<h3 class="course-topic-h3">Topic 1: Introduction to Content Strategy and AI Generative Tools</h3>
<ul>
<li>Overview of AI-generated content</li>
<li>Organizational priorities and strategy in using AI-generated content</li>
<li>Defining AI-generated content strategy objectives</li>
<li>Establish roles of ChatGPT and generative AI in content strategy</li>
<li>Establishing a target audience for AI-generated content</li>
</ul>
<h3 class="course-topic-h3">Topic 2: Evaluate AI-Generated Content</h3>
<ul>
<li>Best prompt engineering practices for AI-generated content</li>
<li>Evaluate AI-generated content ideas for market research and digital marketing</li>
<li>Align AI-generated marketing content to business strategies</li>
</ul>
<h3 class="course-topic-h3">Topic 3: Ethical and Legal Concerns of Managing AI-Generated Content</h3>
<ul>
<li>Emerging trends in AI ethical and legal concerns in AI-generated content delivery</li>
<li>Develop a plan for managing AI-generated content</li>
<li>Determine a suitable management system for AI-generated content</li>
</ul>'
WHERE @eid IS NOT NULL AND @a_desc IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkw, 0, @eid,
'Generative AI, Content Strategy, AI Marketing, AI Content Management, Digital Marketing, Content Evaluation, AI Ethical Concerns, AI Legal Concerns, Prompt Engineering, Business Strategy Alignment, GAI'
WHERE @eid IS NOT NULL AND @a_mkw IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------------------
-- 3. Product image -> the new branded R2 cover; drop the stale Unity gallery row
-- ---------------------------------------------------------------------------
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image');
SET @a_simg  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image');
SET @a_thumb := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail');

-- The storefront renders course_image_url (the R2 cover) when present; setting the
-- three media attributes to 'no_selection' stops the stale Unity jpg from leaking
-- into the gallery, Open Graph tags and the admin grid thumbnail.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_img, 0, @eid, 'no_selection'
WHERE @eid IS NOT NULL AND @a_img IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_simg, 0, @eid, 'no_selection'
WHERE @eid IS NOT NULL AND @a_simg IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_thumb, 0, @eid, 'no_selection'
WHERE @eid IS NOT NULL AND @a_thumb IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Remove the leftover gallery entry (label "Master Unity and C# Game Development...").
DELETE gv FROM catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
 WHERE g.entity_id = @eid;
DELETE FROM catalog_product_entity_media_gallery WHERE entity_id = @eid;

-- ---------------------------------------------------------------------------
-- 4. Funding block -> the WSQ Generative AI for Content Creation course
--    Content-only UPDATE (never ->save() a cms/block: it wipes cms_block_store).
-- ---------------------------------------------------------------------------
UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>
<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-generative-ai-for-content-creation.html" title="WSQ - Generative AI for Content Creation">WSQ - Generative AI for Content Creation</a></span></p>'
 WHERE identifier = 'course_C439_funding_and_grant';

-- ---------------------------------------------------------------------------
-- 5. Category membership
--    OUT: Claude AI Series (281), Claude Certification Exam Prep (370)
--    IN : Generative AI Series (433)
--    catalog_category_product_index is mirrored so the storefront listing
--    reflects the change before the next reindex.
-- ---------------------------------------------------------------------------
DELETE FROM catalog_category_product       WHERE product_id = @eid AND category_id IN (281, 370);
DELETE FROM catalog_category_product_index WHERE product_id = @eid AND category_id IN (281, 370);

-- Slot in alphabetically among the C-prefix block of cat 433. The funded (TGS-)
-- courses hold positions 1-16; the C- block runs 17+ alphabetically.
-- "Generative AI for Content Creation" sorts after "Generative AI for Concept Art"
-- (pos 36) and before "Generative AI for Creativity", so the C- tail is renumbered.
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT 433, @eid, 0 WHERE @eid IS NOT NULL;

-- Renumber the whole category deterministically: funded (TGS-) first by existing
-- position, then C-prefix alphabetically by name, then anything else.
--
-- Two steps on purpose. A single `SELECT (@rn := @rn + 1) ... ORDER BY` does NOT
-- number rows in ORDER BY sequence on MySQL 5.7 - the variable is evaluated during
-- scanning, before the sort - which silently interleaves TGS- and C- courses.
-- So: materialise the sorted rows first, THEN number them by scanning that table.
CREATE TEMPORARY TABLE tmp_cat433_sorted (
  seq        INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  product_id INT UNSIGNED NOT NULL
) ENGINE=InnoDB;

INSERT INTO tmp_cat433_sorted (product_id)
SELECT cp.product_id
  FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  LEFT JOIN catalog_product_entity_varchar nv ON nv.entity_id = p.entity_id
       AND nv.store_id = 0 AND nv.attribute_id = @a_name
 WHERE cp.category_id = 433
 ORDER BY CASE WHEN p.sku LIKE 'TGS-%' THEN 0
               WHEN p.sku LIKE 'C%'    THEN 1
               ELSE 2 END,
          CASE WHEN p.sku LIKE 'TGS-%' THEN LPAD(cp.position, 6, '0') ELSE nv.value END,
          nv.value;

UPDATE catalog_category_product cp
  JOIN tmp_cat433_sorted t ON t.product_id = cp.product_id
   SET cp.position = t.seq
 WHERE cp.category_id = 433;

INSERT INTO catalog_category_product_index
       (category_id, product_id, position, is_parent, store_id, visibility)
SELECT 433, cp.product_id, cp.position, 1, s.store_id, 4
  FROM catalog_category_product cp
  CROSS JOIN core_store s
 WHERE cp.category_id = 433 AND s.store_id > 0
ON DUPLICATE KEY UPDATE position = VALUES(position);

DROP TEMPORARY TABLE tmp_cat433_sorted;

-- ---------------------------------------------------------------------------
-- 6. 301 the old slug -> the new one, so the retired Claude-certification URL
--    never 404s. Explicit id_path (not the default product/<id>) because the
--    system rewrite already owns product/439 - a collision on the UNIQUE
--    (id_path, is_system, store_id) aborts apply.php and leaves the chain
--    half-applied. See memory feedback_category_301_needs_explicit_id_path_unique_key.
-- ---------------------------------------------------------------------------
DELETE FROM core_url_rewrite
 WHERE request_path = 'claude-certified-developer-foundations-certification.html'
   AND is_system = 1;

INSERT INTO core_url_rewrite
       (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT s.store_id, NULL, NULL,
       CONCAT('c439-genai-content-301-', s.store_id),
       'claude-certified-developer-foundations-certification.html',
       'generative-ai-for-content-creation.html',
       0, 'RP', 'C439 repurposed: Claude Certified Developer -> Generative AI for Content Creation'
  FROM core_store s
 WHERE s.store_id > 0
ON DUPLICATE KEY UPDATE target_path = VALUES(target_path), options = VALUES(options);
