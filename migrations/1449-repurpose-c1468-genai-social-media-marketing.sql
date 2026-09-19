-- Repurpose course C1468 from "Generative AI for Digital Marketing" to
-- "Generative AI for Social Media Marketing".
--
-- Content (overview + 4 topics) follows the WSQ parent TGS-2021003023
-- (WSQ - Generative AI for Social Media Marketing), with the WSQ funding
-- sentence STRIPPED: C1468 is a non-WSQ C-prefix course and carries zero
-- funding, so a "70% WSQ funding subsidy" claim must never appear on it.
--
-- NOT touched (deliberate):
--   * schedule -- duration stays 15h / 9:30am-5:30pm on its own B03
--     (Wed-Thurs/Sat-Sun) template. Non-WSQ runs 9:30am-5:30pm by house
--     convention (no WSQ assessment hour) and keeping a distinct weekday
--     pair stops the twin colliding with its WSQ parent's dates.
--   * price -- stays $700.
--   * categories -- the existing 11 memberships already include
--     social-media-marketing-training-courses (118).
--
-- url_key: generative-ai-for-digital-marketing -> generative-ai-for-social-media-marketing
-- The live SG path carries a -1468 suffix (rewrite collision handling), so
-- both the bare and suffixed old paths are 301'd.
--
-- Idempotent. Store scope 0. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1468');

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');

-- ---------------------------------------------------------------- name
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'Generative AI for Social Media Marketing' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------- overview
-- Mirrors the WSQ parent's overview. Final clause of the WSQ copy
-- ("with up to 70% WSQ funding subsidy available ...") removed: non-WSQ.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Are you ready to supercharge your brand&rsquo;s online presence with the power of AI? Dive into Generative AI for Social Media Marketing, where you will discover how tools like ChatGPT and AI image and video generators can transform the way you plan, create and run social media campaigns. In this comprehensive course, we will equip you with the knowledge and skills to develop a data-driven social media marketing plan, evaluate the right platforms for your business, and produce engaging AI-generated posts, visuals and ad copy in a fraction of the time.</p>
<p>By the end of this course, you will be able to build a complete AI-powered social media campaign, from audience analysis and content creation to performance tracking and optimization, and evaluate its impact on your organization. Join us today and take your brand&rsquo;s social media presence to the next level!</p>'
FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------- topics
-- 4 topics, 1:1 with the WSQ parent (non-WSQ topics always follow the WSQ
-- parent -- rescale, never cut).
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1: Plan a Social Media Marketing Campaign with Generative AI</h3>
<ul>
<li>Overview of generative AI tools for social media marketing</li>
<li>Examples of AI-generated social media advertisements</li>
<li>Map out customer journey using AI-assisted customer persona tools</li>
<li>Competitive and audience analysis using AI-powered audience insights</li>
<li>Develop a social media marketing plan with generative AI</li>
</ul>
<h3 class="course-topic-h3">Topic 2: Evaluate Social Media Marketing Opportunities and Platforms</h3>
<ul>
<li>Social media competitive and audience evaluation using AI-powered audience insights</li>
<li>Feasibility and comparison of using various social media platforms</li>
<li>Advantages of applying generative AI across social media platforms</li>
</ul>
<h3 class="course-topic-h3">Topic 3: Create a Social Media Marketing Campaign with Generative AI</h3>
<ul>
<li>Market penetration potential of AI-driven social media marketing in the local context</li>
<li>Create social media photo and video posts with generative AI</li>
<li>AI-assisted captions, hashtags and location tagging</li>
<li>Anatomy of an AI-optimized social media ads campaign structure</li>
<li>Privacy, copyright and responsible AI considerations</li>
</ul>
<h3 class="course-topic-h3">Topic 4: Evaluate Social Media Marketing Performance with Generative AI</h3>
<ul>
<li>Create and install tracking pixels to collect performance data</li>
<li>Understand key social media performance and advertising ROI metrics</li>
<li>Set up custom and automated reporting with generative AI</li>
<li>Manage consumer reviews and user-generated content with AI</li>
<li>Audience, budget, scheduling and placement optimization using AI</li>
<li>AI tools for social media scheduling</li>
<li>Retargeting strategies</li>
</ul>'
FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------- metas
-- meta_title stored BARE (MMD_Seotitle appends the brand at render time).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Generative AI for Social Media Marketing' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_description is varchar(255) -- keep under the cap.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Plan, create and optimize social media campaigns with generative AI. Build AI-powered posts, visuals, captions and ad copy, then track performance in this hands-on 2-day course in Singapore.'
FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Generative AI, Social Media Marketing, ChatGPT, Content Creation, Social Media Campaign, Audience Analysis, Hashtags, Social Media Ads, Retargeting, AI Marketing'
FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------- url_key
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'generative-ai-for-social-media-marketing' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------- cover
-- Freshly rendered for the NEW title and uploaded to R2 (non-WSQ: no funding
-- chips). The renderer bakes the title into the PNG, so the old cover would
-- keep showing "Generative AI for Digital Marketing" until repointed.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1468-20260919-070125.png'
FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Clear per-store overrides so store 1 cannot shadow the store-0 values above.
DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND @e IS NOT NULL
  AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url, @a_img);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND @e IS NOT NULL
  AND attribute_id IN (@a_short, @a_desc, @a_mk);

-- ---------------------------------------------------------------- 301s
-- DELETE the is_system=1 rows squatting on the OLD slug FIRST: they share the
-- id_path the 301 needs, so INSERT IGNORE would silently no-op and the new
-- slug would get a -1468 suffix.
DELETE FROM core_url_rewrite
WHERE product_id=@e AND is_system=1 AND @e IS NOT NULL
  AND request_path IN ('generative-ai-for-digital-marketing.html',
                       'generative-ai-for-digital-marketing-1468.html',
                       'adult-training-courses/generative-ai-for-digital-marketing-1468.html');

-- Drop any non-system squatter already holding the NEW path.
DELETE FROM core_url_rewrite
WHERE request_path='generative-ai-for-social-media-marketing.html' AND is_system=0;

-- 301 the live (suffixed) path and the bare path at the new slug.
INSERT IGNORE INTO core_url_rewrite
  (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options)
SELECT 1, NULL, @e, CONCAT('product/', @e), 'generative-ai-for-digital-marketing-1468.html',
       'generative-ai-for-social-media-marketing.html', 0, 'RP'
FROM dual WHERE @e IS NOT NULL;

-- NOTE: the BARE 'generative-ai-for-digital-marketing.html' is deliberately NOT
-- 301'd here -- that request_path belongs to the disabled product C429
-- (id_path product/429), which has 404'd since migration 374 freed the slug.
-- C1468's live path has always been the -1468 suffixed one. Taking the bare
-- path would mean hijacking another product's rewrite row.

-- Flatten existing chains (the old WSQ-era aliases pointed at the old slug)
-- so nothing 301-hops twice.
UPDATE core_url_rewrite
SET target_path='generative-ai-for-social-media-marketing.html'
WHERE is_system=0 AND options='RP'
  AND target_path IN ('generative-ai-for-digital-marketing.html',
                      'generative-ai-for-digital-marketing-1468.html',
                      'adult-training-courses/generative-ai-for-digital-marketing-1468.html')
  AND request_path <> 'generative-ai-for-social-media-marketing.html';
