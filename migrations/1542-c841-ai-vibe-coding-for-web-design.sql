-- 1542: C841 -> "AI Vibe Coding for Web Design" (AI Vibe Coding Series)
--
-- Repurposes C841 off its Unity Game Development life onto Web Design, and
-- brings it onto the AI Vibe Coding Series standard: 2 days / 15 hrs / $700 /
-- exactly 4 topics. C841 is the SG non-WSQ (C-prefix) twin of the WSQ course
-- TGS-2026064174 "CASL - AI Vibe Coding for Web Design" (migration 1533).
--
-- PROBED on prod before writing. Already correct, NOT touched:
--   * course_series_badge = 'AI Vibe Coding Series' (already set)
--   * category 414 'AI Vibe Coding Series' membership (already a member;
--     the requested "add to the AI Vibe Coding Series catalog page" is
--     therefore already satisfied -- only the listing POSITION is restated
--     below so the renamed course sorts alphabetically among its siblings).
--   * trainers, venue, googlemap, additional_note.
--
-- WHAT CHANGES:
--   * name, url_key, url_path -> ai-vibe-coding-for-web-design
--   * price 1050 -> 700 (every store-scoped decimal row), duration 22.5 -> 15,
--     sessions 4 -> 2  (2 days @ $350/day = the series standard)
--   * meta_title / meta_description / meta_keyword
--   * short_description (2-paragraph overview) + description (exactly 4 topics
--     in the series' h3.course-topic-h3 + <ul> format -- NOT the LSN_DATA
--     format; series courses use the h3 format)
--   * whoshouldattend -- Unity/game roles -> web design roles
--   * image/small_image/thumbnail LABELS + media-gallery label (the real alt
--     text). The image PATHS are left alone on purpose -- they are filesystem
--     paths (/u/n/unity-...jpg) and renaming them would 404 the gallery; the
--     storefront card renders course_image_url (the R2 cover) instead.
--   * course_image_url -> regenerated R2 cover rendered from the NEW title with
--     NO badges (non-WSQ courses get a clean title card), verified HTTP 200:
--       course-covers/C841-20260922-173153.png  (136873 bytes)
--   * Unity / game / certification-exam-prep category memberships are REMOVED
--     (100 Gaming & Animation, 182 Certification Exam Prep, 206 Unity,
--     368 Game Development Cert Prep, 369 Unity Cert Prep) -- the course no
--     longer teaches Unity and must not sit in an exam-prep listing. Web
--     Development (4) and HTML & CSS (33) are added so it lists with its peers.
--     Removals are mirrored into catalog_category_product_index.
--   * the funding block is repointed at the course's OWN WSQ parent
--     (TGS-2026064174), replacing the unrelated Multi-Agents System link.
--     Content-only UPDATE -- never ->save() a cms/block model (wipes
--     cms_block_store and 404s the page).
--   * 301s old slug -> new slug, pre-existing 301s flattened, and the
--     is_system row on the old slug deleted so refreshProductRewrite cannot
--     mint a '-1' suffix.
--
-- NOT done here: the schedule template switch D01 -> B19. That is a CODE path
-- (per-option_id custom_options_relation rows); doing it in SQL corrupts
-- in_group_id / dependent_ids. It is driven separately through the real
-- CoursesaveController::switchScheduleTemplateAction (B19 = group_id 108).
-- C841 has 0 admin_managed dates, so nothing needs preserving across it.
--
-- SG production only; keyed by SKU so a partner site without this SKU no-ops.
-- Idempotent: plain UPDATEs + INSERT IGNORE / ON DUPLICATE KEY UPDATE.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C841' LIMIT 1);
SET @et  := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');

-- ---------------------------------------------------------------- name
SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='name' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'AI Vibe Coding for Web Design'
 WHERE attribute_id = @a_name AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- url_key / url_path
SET @a_url := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_key' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'ai-vibe-coding-for-web-design'
 WHERE attribute_id = @a_url AND entity_id = @pid AND @pid IS NOT NULL;

SET @a_upath := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_path' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'ai-vibe-coding-for-web-design.html'
 WHERE attribute_id = @a_upath AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- metas
SET @a_mt := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_title' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'AI Vibe Coding for Web Design'
 WHERE attribute_id = @a_mt AND entity_id = @pid AND @pid IS NOT NULL;

-- varchar(255): the string below is 232 chars.
SET @a_md := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_description' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'Design and build websites with AI vibe coding. Generate web content, improve usability, boost online visibility and refine user experience using AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 2-day course.'
 WHERE attribute_id = @a_md AND entity_id = @pid AND @pid IS NOT NULL;

SET @a_mk := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_keyword' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = 'AI Vibe Coding for Web Design, AI Vibe Coding, Vibe Coding, AI Web Design, Web Design Course Singapore, AI Coding Assistant, Cursor, GitHub Copilot, Claude, Web Usability, User Experience'
 WHERE attribute_id = @a_mk AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- duration / sessions (2 days, 15 hrs)
SET @a_dur := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='duration' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = '15'
 WHERE attribute_id = @a_dur AND entity_id = @pid AND @pid IS NOT NULL;

SET @a_ses := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='sessions' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = '2'
 WHERE attribute_id = @a_ses AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- price $700
-- Every store-scoped row, so a stale per-store override is cleaned up too.
SET @a_price := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='price' AND entity_type_id=@et);
UPDATE catalog_product_entity_decimal
   SET value = 700.0000
 WHERE attribute_id = @a_price AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- short_description (About)
SET @a_sd := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<p>AI Vibe Coding for Web Design is a practical, hands-on course that equips participants with the skills to use AI-assisted coding techniques to create effective, user-friendly, and business-focused websites. Through natural-language instructions and AI coding assistants such as Cursor, GitHub Copilot and Claude, learners will generate, modify, test, and refine web content and interfaces while developing practical skills in web usability, online visibility, lead generation, and user experience.</p>',
     '<p>Participants will build web content and page structures with AI, then apply navigation, accessibility, responsive design and interface consistency to make sites easy to use across devices. They will improve discoverability, develop landing pages and optimise calls-to-action, and finally evaluate and enhance website interactions, layouts and content flows. By the end of the course, participants will be able to use AI Vibe Coding to create and optimise websites that deliver relevant content, improve usability, strengthen online visibility, generate leads, and provide positive user experiences.</p>')
 WHERE attribute_id = @a_sd AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- description (exactly 4 topics, 2 per day)
-- Series format: h3.course-topic-h3 + <ul><li>. NOT the LSN_DATA/<p><em> format.
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='description' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<h3 class="course-topic-h3">Topic 1 AI Vibe Coding for Web Content</h3>\n<ul>\n',
     '<li>Setting Up AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>\n',
     '<li>Generating Web Pages and Content from a Prompt</li>\n',
     '<li>Structuring Pages, Headings and Calls-to-Action</li>\n',
     '<li>Refining Content for Different Audiences and Business Goals</li>\n</ul>\n',
     '<h3 class="course-topic-h3">Topic 2 AI Vibe Coding for Web Usability</h3>\n<ul>\n',
     '<li>Building Navigation and Forms that are Easy to Use</li>\n',
     '<li>Applying Accessibility, Readability and Interface Consistency</li>\n',
     '<li>Making Layouts Responsive Across Devices with AI</li>\n',
     '<li>Testing and Troubleshooting AI-Generated Interfaces</li>\n</ul>\n',
     '<h3 class="course-topic-h3">Topic 3 AI Vibe Coding for Lead Generation and Online Visibility</h3>\n<ul>\n',
     '<li>Improving Website Discoverability and On-Page Visibility</li>\n',
     '<li>Developing Effective Landing Pages with AI Vibe Coding</li>\n',
     '<li>Optimising Calls-to-Action for Engagement and Conversion</li>\n',
     '<li>Capturing and Managing Leads from the Website</li>\n</ul>\n',
     '<h3 class="course-topic-h3">Topic 4 AI Vibe Coding for User Experience</h3>\n<ul>\n',
     '<li>Evaluating Website Interactions, Layouts and Content Flows</li>\n',
     '<li>Prototyping Design Improvements with AI</li>\n',
     '<li>Managing Multimedia Content for Audience Needs</li>\n',
     '<li>Refining and Deploying the Final Website</li>\n</ul>')
 WHERE attribute_id = @a_desc AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- who should attend
SET @a_wsa := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='whoshouldattend' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<ul>',
     '<li>Web Designer</li>',
     '<li>Web Developer</li>',
     '<li>Front-End Developer</li>',
     '<li>UI Designer</li>',
     '<li>UX Designer</li>',
     '<li>Digital Marketing Executive</li>',
     '<li>Content Marketing Executive</li>',
     '<li>SEO Executive</li>',
     '<li>Web Content Editor</li>',
     '<li>Digital Media Executive</li>',
     '<li>Business Owner</li>',
     '<li>Entrepreneur</li>',
     '<li>Marketing Manager</li>',
     '<li>E-commerce Executive</li>',
     '<li>Freelance Web Designer</li>',
     '</ul>')
 WHERE attribute_id = @a_wsa AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- image alt labels
UPDATE catalog_product_entity_varchar v
   JOIN eav_attribute a ON a.attribute_id = v.attribute_id
    SET v.value = 'AI Vibe Coding for Web Design'
  WHERE v.entity_id = @pid AND @pid IS NOT NULL
    AND a.entity_type_id = @et
    AND a.attribute_code IN ('image_label','small_image_label','thumbnail_label');

UPDATE catalog_product_entity_media_gallery_value g
   JOIN catalog_product_entity_media_gallery m ON m.value_id = g.value_id
    SET g.label = 'AI Vibe Coding for Web Design'
  WHERE m.entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- cover image
SET @a_ciu := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='course_image_url' AND entity_type_id=@et);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @et, @a_ciu, 0, @pid,
       'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C841-20260922-173153.png'
 WHERE @pid IS NOT NULL AND @a_ciu IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @pid AND attribute_id = @a_ciu AND store_id <> 0
   AND @pid IS NOT NULL AND @a_ciu IS NOT NULL;

-- ---------------------------------------------------------------- series badge (idempotent restate)
SET @a_badge := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='course_series_badge' AND entity_type_id=@et);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @et, @a_badge, 0, @pid, 'AI Vibe Coding Series'
 WHERE @pid IS NOT NULL AND @a_badge IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------- categories
-- Drop the Unity / game / certification-exam-prep memberships.
DELETE FROM catalog_category_product
 WHERE product_id = @pid AND @pid IS NOT NULL
   AND category_id IN (100, 182, 206, 368, 369);

DELETE FROM catalog_category_product_index
 WHERE product_id = @pid AND @pid IS NOT NULL
   AND category_id IN (100, 182, 206, 368, 369);

-- Add the web-design homes so it lists with its peers.
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT c.cid, @pid, 0 FROM (SELECT 4 AS cid UNION SELECT 33) c
 WHERE @pid IS NOT NULL;

-- Keep it in 414 'AI Vibe Coding Series' (already a member; restated so the
-- migration is self-contained if the row is ever missing).
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT 414, @pid, 39 WHERE @pid IS NOT NULL;

-- ---------------------------------------------------------------- funding block
-- Repoint at this course's OWN WSQ parent. Content-only UPDATE by design.
UPDATE cms_block
   SET content = CONCAT(
         '<h2>Funding and Grant Applications</h2>\n',
         '<p>No funding is available for this course</p>\n',
         '<p>For WSQ funding, please checkout the details at&nbsp;',
         '<span style="text-decoration: underline;">',
         '<a href="https://www.tertiarycourses.com.sg/casl-ai-vibe-coding-for-web-design.html" ',
         'title="CASL - AI Vibe Coding for Web Design">CASL - AI Vibe Coding for Web Design</a>',
         '</span></p>')
 WHERE identifier = 'course_C841_funding_and_grant';

-- ---------------------------------------------------------------- URL rewrites
SET @sid := (SELECT store_id FROM core_store WHERE store_id > 0 ORDER BY store_id LIMIT 1);

-- Free the OLD slug so refreshProductRewrite cannot mint a '-1' suffix.
DELETE FROM core_url_rewrite
 WHERE product_id = @pid AND is_system = 1 AND @pid IS NOT NULL
   AND request_path LIKE '%ai-vibe-coding-for-unity-game-development.html';

-- Clear any is_system=0 squatter sitting on the NEW paths.
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND request_path LIKE '%ai-vibe-coding-for-web-design.html';

-- 301 old -> new: bare path plus the surviving category-prefixed paths.
-- The retired Unity/exam-prep prefixes are included so their historical URLs
-- still land on the renamed course rather than 404ing.
INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT @sid,
       CONCAT('c841-ai-vibe-web-', t.slot, '-', @pid),
       CONCAT(t.prefix, 'ai-vibe-coding-for-unity-game-development.html'),
       CONCAT(IF(t.keep = 1, t.prefix, ''), 'ai-vibe-coding-for-web-design.html'),
       0, 'RP', '1542: C841 repurposed to AI Vibe Coding for Web Design'
  FROM (
        SELECT 'bare'   AS slot, ''                                             AS prefix, 1 AS keep
  UNION SELECT 'cat3',           'adult-training-courses/',                         1
  UNION SELECT 'cat69',          'digital-media-courses/',                          1
  UNION SELECT 'cat252',         'artificial-intelligence-courses/',                1
  UNION SELECT 'cat414',         'ai-vibe-coding-series/',                          1
  -- retired category prefixes: 301 to the BARE new path (keep = 0)
  UNION SELECT 'cat100',         'gaming-animation-and-video-courses-in/',          0
  UNION SELECT 'cat182',         'certification-exam-prep-courses/',                0
  UNION SELECT 'cat206',         'unity-training-courses/',                         0
  UNION SELECT 'cat368',         'game-development-certification-prep-courses/',    0
  UNION SELECT 'cat369',         'unity-certification-exam-prep-courses/',          0
  ) t
 WHERE @pid IS NOT NULL AND @sid IS NOT NULL;

-- Flatten pre-existing 301s that still target the OLD slug so nothing chains.
UPDATE core_url_rewrite
   SET target_path = REPLACE(target_path,
                             'ai-vibe-coding-for-unity-game-development.html',
                             'ai-vibe-coding-for-web-design.html')
 WHERE is_system = 0
   AND target_path LIKE '%ai-vibe-coding-for-unity-game-development.html'
   AND id_path NOT LIKE 'c841-ai-vibe-web-%';

-- ---------------------------------------------------------------- search redirects
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/ai-vibe-coding-for-web-design.html'
 WHERE redirect LIKE '%ai-vibe-coding-for-unity-game-development.html';
