-- 1548: TGS-2023036657 -> "WSQ - Agentic AI and AI Agents for Video Inbound Marketing"
--
-- Repurposes the TikTok course to a platform-neutral video inbound marketing
-- course. The SKU is UNCHANGED, so every SkillsFuture / SFEC / SFC / PSEA deep
-- link keyed on the course code stays valid and the funding registration is
-- untouched.
--
-- Surfaces rewritten (from the pre-write EAV sweep of entity 1381 -- every
-- varchar/text row grepped for "tiktok"):
--   name, meta_title, meta_description, meta_keyword, url_key, url_path,
--   image_label / small_image_label / thumbnail_label, short_description,
--   description (outline), whoshouldattend, prerequisite (the tool <li> ONLY),
--   trainerprofile (the course-teaching paragraph of each of the 4 bios ONLY),
--   and the learning_outcomes cms_block.
--
-- Deliberately NOT touched:
--   * image / small_image / thumbnail -- filesystem paths to the uploaded JPG,
--     not display text; renaming them would 404 the file.
--   * review_detail -- genuine learner testimonials about the course as it was
--     taught; one mentions TikTok. Facts, not leaks. Flagged, not rewritten.
--   * trainer CREDENTIALS (para 1 of each bio) -- real career history.
--
-- SG production only; keyed by SKU so a partner site with no TGS-2023036657
-- no-ops. Idempotent: re-running changes nothing.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023036657' LIMIT 1);
SET @et  := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product');

-- ---------- name ----------
SET @a := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='name' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - Agentic AI and AI Agents for Video Inbound Marketing'
 WHERE attribute_id=@a AND entity_id=@pid AND @pid IS NOT NULL;

-- ---------- meta_title ----------
-- Plain title: NO leading "WSQ", NO brand suffix. MMD_Seotitle prepends
-- "WSQ funded" for SG TGS- SKUs and appends the brand at render time; baking
-- either in yields "WSQ funded WSQ ... | Tertiary Courses Singapore".
SET @a := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_title' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'Agentic AI and AI Agents for Video Inbound Marketing'
 WHERE attribute_id=@a AND entity_id=@pid AND @pid IS NOT NULL;

-- ---------- meta_description (varchar, <=255) ----------
SET @a := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_description' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'Plan, create, and automate video inbound marketing with AI agents: content creation, campaign automation, and performance analytics. Enjoy up to 70% WSQ funding subsidy.'
 WHERE attribute_id=@a AND entity_id=@pid AND @pid IS NOT NULL;

-- ---------- meta_keyword ----------
SET @a := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_keyword' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = 'WSQ video inbound marketing course, agentic AI marketing, AI agents marketing, AI video content creation, video campaign automation, AI marketing Singapore, inbound marketing funnel, short-form video marketing, AI lead generation'
 WHERE attribute_id=@a AND entity_id=@pid AND @pid IS NOT NULL;

-- ---------- url_key ----------
SET @a := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_key' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-agentic-ai-for-video-inbound-marketing'
 WHERE attribute_id=@a AND entity_id=@pid AND @pid IS NOT NULL;

-- ---------- url_path: DELETE at every scope so the rewrite indexer regenerates ----------
SET @a := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_path' AND entity_type_id=@et);
DELETE FROM catalog_product_entity_varchar
 WHERE attribute_id=@a AND entity_id=@pid AND @pid IS NOT NULL;

-- ---------- alt-text labels (plain title, no "WSQ - " prefix: the cover strips it) ----------
SET @a := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='image_label' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar SET value='Agentic AI and AI Agents for Video Inbound Marketing'
 WHERE attribute_id=@a AND entity_id=@pid AND @pid IS NOT NULL;
SET @a := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='small_image_label' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar SET value='Agentic AI and AI Agents for Video Inbound Marketing'
 WHERE attribute_id=@a AND entity_id=@pid AND @pid IS NOT NULL;
SET @a := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='thumbnail_label' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar SET value='Agentic AI and AI Agents for Video Inbound Marketing'
 WHERE attribute_id=@a AND entity_id=@pid AND @pid IS NOT NULL;

-- media gallery label
UPDATE catalog_product_entity_media_gallery_value v
  JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
   SET v.label = 'Agentic AI and AI Agents for Video Inbound Marketing'
 WHERE g.entity_id = @pid AND @pid IS NOT NULL;

-- ---------- short_description (overview) ----------
-- This course's sdesc is intro prose only (no <h2> Brochure/Certification tail
-- -- those live in cms_block rows), so a full replace is correct here.
SET @a := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = '<p>This <strong>WSQ Agentic AI and AI Agents for Video Inbound Marketing</strong> course equips learners with practical skills to use Agentic AI and Generative AI to plan, create, automate, and optimise video-driven inbound marketing strategies. Participants will learn how AI agents can streamline marketing workflows from audience research and content planning to video creation, lead generation, engagement, and performance analysis.</p><p>The course introduces key concepts in video inbound marketing, including audience personas, customer journeys, content funnels, search intent, and strategies for attracting and converting prospects. Learners will use AI agents to support market and competitor research, topic and keyword discovery, content ideation, video script generation, call-to-action development, and campaign planning.</p><p>Through hands-on activities, participants will create video content for different stages of the marketing funnel and use AI-powered workflows to repurpose content, automate repetitive marketing tasks, support lead nurturing, and analyse campaign performance. Learners will also explore multi-agent workflows where specialised AI agents collaborate across research, content creation, marketing automation, and analytics.</p><p>The course covers responsible AI usage, brand consistency, content accuracy, governance, and human oversight. By the end of the course, learners will be able to implement Agentic AI-powered video inbound marketing workflows that improve productivity, attract qualified prospects, increase engagement, generate leads, and support business growth.</p>'
 WHERE attribute_id=@a AND entity_id=@pid AND @pid IS NOT NULL;

-- ---------- description (Course Outline: LSN_DATA + rendered topics) ----------
SET @a := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='description' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<!-- LSN_DATA: [{"title":"Topic 1: Foundations of Agentic AI for Video Inbound Marketing","subsecs":[]},{"title":"Topic 2: AI-Powered Video Content Creation and Campaign Automation","subsecs":[]},{"title":"Topic 3: Optimising, Analysing, and Scaling Video Marketing with AI Agents","subsecs":[]}] -->', '\n',
     '<p><strong>Topic 1: Foundations of Agentic AI for Video Inbound Marketing</strong></p>', '\n',
     '<p><strong>Topic 2: AI-Powered Video Content Creation and Campaign Automation</strong></p>', '\n',
     '<p><strong>Topic 3: Optimising, Analysing, and Scaling Video Marketing with AI Agents</strong></p>', '\n')
 WHERE attribute_id=@a AND entity_id=@pid AND @pid IS NOT NULL;

-- ---------- whoshouldattend: repoint the two platform-named roles ----------
SET @a := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='whoshouldattend' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = REPLACE(REPLACE(value,
         '<li>TikTok Channel Manager</li>', '<li>Video Channel Manager</li>'),
         '<li>Social Media Ad Campaign Manager</li>', '<li>Video Ad Campaign Manager</li>')
 WHERE attribute_id=@a AND entity_id=@pid AND @pid IS NOT NULL;

-- ---------- prerequisite: swap ONLY the software <li>. ----------
-- This attribute also holds the whole funding apparatus (PWM, Funding
-- Eligibility, SkillsFuture/PSEA/SFEC/UTAP deep links, Appeal Process) --
-- never rewrite it wholesale. Deep-link counts asserted post-apply:
-- myskillsfuture=4, ntuc=3, mom=1.
SET @a := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='prerequisite' AND entity_type_id=@et);
-- Two markup shapes exist in the wild for this <li>: prod stores
-- `<u><a ...>` while other instances store `<a ...><span style=...>`.
-- Match BOTH or the REPLACE silently no-ops on whichever instance differs.
UPDATE catalog_product_entity_text
   SET value = REPLACE(REPLACE(value,
         '<li><u><a href="https://www.tiktok.com/" rel="noopener noreferrer" target="_blank">TikTok</a></u></li>',
         '<li><u><a href="https://www.youtube.com/" rel="noopener noreferrer" target="_blank">YouTube</a></u></li><li><u><a href="https://www.canva.com/" rel="noopener noreferrer" target="_blank">Canva</a></u></li>'),
         '<li><a href="https://www.tiktok.com/" target="_blank"><span style="text-decoration: underline;">TikTok</span></a></li>',
         '<li><a href="https://www.youtube.com/" target="_blank"><span style="text-decoration: underline;">YouTube</span></a></li><li><a href="https://www.canva.com/" target="_blank"><span style="text-decoration: underline;">Canva</span></a></li>')
 WHERE attribute_id=@a AND entity_id=@pid AND @pid IS NOT NULL;

-- ---------- trainerprofile: retarget ONLY the course-teaching paragraph ----------
-- Para 1 of each bio is career-history credentials (real TikTok/social work) and
-- stays untouched; para 2 is the "in his/her <topic> training" claim.
SET @a := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='trainerprofile' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = REPLACE(REPLACE(REPLACE(REPLACE(value,
     -- Allen Wong
     '<p>In his TikTok marketing training, Allen emphasizes creative content creation, data analytics, and campaign optimization. He guides learners on how to leverage TikTok&rsquo;s algorithm, trends, and advertising tools to turn engagement into measurable leads. By integrating case studies and hands-on exercises, he equips participants to design effective TikTok strategies that convert followers into customers.</p>',
     '<p>In his video inbound marketing training, Allen emphasizes creative content creation, data analytics, and campaign optimization. He guides learners on how to leverage AI agents, platform algorithms, and advertising tools to turn engagement into measurable leads. By integrating case studies and hands-on exercises, he equips participants to design effective video marketing strategies that convert viewers into customers.</p>'),
     -- Patrick Foo
     '<p>In his TikTok training, Patrick focuses on content strategy and community building. He teaches learners how to design engaging short-form videos, apply storytelling techniques, and use TikTok Ads to target niche audiences. His practical approach ensures participants can confidently apply TikTok as a tool for brand visibility and lead generation.</p>',
     '<p>In his video inbound marketing training, Patrick focuses on content strategy and community building. He teaches learners how to design engaging short-form videos, apply storytelling techniques, and use video ad platforms to target niche audiences. His practical approach ensures participants can confidently apply video marketing as a tool for brand visibility and lead generation.</p>'),
     -- Ray Teoh Tham Kim
     '<p>In his TikTok marketing training, Ray emphasizes strategic campaign planning and analytics. He guides learners through audience targeting, influencer collaborations, and content optimization for maximum reach and conversion. Drawing on his regional leadership experience, he provides insights on using TikTok for cross-border marketing and business growth.</p>',
     '<p>In his video inbound marketing training, Ray emphasizes strategic campaign planning and analytics. He guides learners through audience targeting, influencer collaborations, and content optimization for maximum reach and conversion. Drawing on his regional leadership experience, he provides insights on using video marketing for cross-border marketing and business growth.</p>'),
     -- Janice Ong
     '<p>In her TikTok courses, Janice emphasizes building authentic personal and business branding on the platform. She guides learners through creating engaging content, leveraging TikTok trends, and applying analytics to track performance. By combining strategic insights with hands-on practice, she helps participants convert TikTok engagement into tangible leads and sales opportunities.</p>',
     '<p>In her video inbound marketing courses, Janice emphasizes building authentic personal and business branding across video platforms. She guides learners through creating engaging content, leveraging video content trends, and applying analytics to track performance. By combining strategic insights with hands-on practice, she helps participants convert video engagement into tangible leads and sales opportunities.</p>')
 WHERE attribute_id=@a AND entity_id=@pid AND @pid IS NOT NULL;

-- ---------- learning outcomes cms_block ----------
UPDATE cms_block
   SET content = CONCAT(
         '<p>By end of the course, learners should be able to:</p>', '\n',
         '<ul>', '\n',
         '<li>LO1: Formulate inbound video marketing strategies to attract leads</li>', '\n',
         '<li>LO2: Create viral content on video platforms.</li>', '\n',
         '<li>LO3: Evaluate the performance of video marketing campaign</li>', '\n',
         '</ul>', '\n')
 WHERE identifier = 'course_TGS-2023036657_learning_outcomes';

-- ---------- permanent 301: old bare slug -> new bare slug ----------
-- The category-path variants are auto-301'd by the URL Rewrites indexer.
SET @sid := (SELECT store_id FROM core_store WHERE store_id > 0 ORDER BY store_id LIMIT 1);

-- Clear any is_system=0 squatter first: INSERT IGNORE silently no-ops against a
-- stale row holding the old request_path (see migration 647).
-- The squatter on the old bare path is the SYSTEM rewrite the indexer built
-- for the old url_key (is_system=1, target catalog/product/view/id/N), not just
-- an is_system=0 row -- so do NOT filter on is_system here or the INSERT IGNORE
-- below silently no-ops and the old URL keeps resolving instead of 301ing.
DELETE FROM core_url_rewrite
 WHERE store_id = @sid
   AND request_path = 'wsq-agentic-ai-for-tiktok-marketing.html'
   AND @pid IS NOT NULL AND @sid IS NOT NULL;

INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT @sid,
       CONCAT('tgs2023036657-video-inbound-', @pid),
       'wsq-agentic-ai-for-tiktok-marketing.html',
       'wsq-agentic-ai-for-video-inbound-marketing.html',
       0, 'RP', '1548: TGS-2023036657 repurposed to Video Inbound Marketing'
WHERE @pid IS NOT NULL AND @sid IS NOT NULL;

-- ---------- flatten the PREVIOUS lives' 301s so nothing 2-hops ----------
-- This slug already absorbed two earlier titles. Their rows point at the slug
-- we are retiring; repoint them at the new one directly.
UPDATE core_url_rewrite
   SET target_path = REPLACE(target_path,
         'wsq-agentic-ai-for-tiktok-marketing.html',
         'wsq-agentic-ai-for-video-inbound-marketing.html')
 WHERE store_id = @sid
   AND is_system = 0
   AND target_path LIKE '%wsq-agentic-ai-for-tiktok-marketing.html'
   AND request_path <> 'wsq-agentic-ai-for-tiktok-marketing.html'
   AND @sid IS NOT NULL;

-- ---------- search redirect: bare course code follows the course ----------
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/wsq-agentic-ai-for-video-inbound-marketing.html'
 WHERE query_text = 'TGS-2023036657';
