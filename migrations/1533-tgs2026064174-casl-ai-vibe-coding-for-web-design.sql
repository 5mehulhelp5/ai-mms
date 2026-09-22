-- 1533: TGS-2026064174 -> "CASL - AI Vibe Coding for Web Design"
--
-- Retitles + rewrites the course from the hand-coded HTML5/CSS3 life
-- ("Vibe Coding for Basic Web Design") onto AI-assisted web design. The SKU is
-- UNCHANGED, so this is a retitle + content rewrite, NOT a WSQ->CASL
-- conversion: the CASL prefix, the CASL tag and the other five funding tags
-- (PSEA / UTAP / SFEC / Absentee Payroll / MCES) were already in place before
-- this migration and are deliberately left alone.
--
-- PROBED on prod before writing. Already correct, NOT touched:
--   * name prefix "CASL - " (present), url_key already casl-* (re-prefixed by
--     an earlier session), the CASL tag, and all 6 funding tags.
--   * categories (12), trainers, price ($750), duration (16), sessions (2).
--     This stays a 2-day WSQ-funded TGS- course -- the non-WSQ "AI Vibe Coding
--     Series" standard (15h / $700 / red series badge) does NOT apply here.
--   * no cms_block exists for this SKU, so there is no per-course funding or
--     certification block to edit.
--   * `prerequisite` is shared WSQ funding/entry-requirement boilerplate and
--     carries no course-topic copy -- left as is.
--
-- WHAT WAS STALE and is fixed here -- every surface still described hand-coding
-- HTML5/CSS3 rather than AI-assisted vibe coding:
--   * name, url_key, url_path
--   * meta_title -- note it must NOT start with "WSQ": MMD_Seotitle prepends
--     "WSQ funded" at render time for TGS- SKUs on the SG site, and the stored
--     "WSQ Vibe Coding for Basic Web Design | ..." is what produced the live
--     "WSQ funded WSQ Vibe Coding for Basic Web Design" duplication.
--   * meta_description (<= 255 chars, varchar column), meta_keyword
--   * short_description -- the About copy, rewritten to the supplied text.
--   * description -- the 4-topic outline, rewritten to the supplied topics.
--     The LSN_DATA JSON marker is regenerated in lockstep with the visible
--     HTML: the admin Lesson editor parses that marker, so leaving it on the
--     old topics would make the admin and the storefront disagree.
--   * whoshouldattend -- job roles, refreshed onto AI-assisted web roles.
--   * image_label / small_image_label / thumbnail_label + the media-gallery
--     label (the real alt text). The image/small_image/thumbnail PATHS are
--     left alone on purpose -- they are filesystem paths and renaming them
--     would 404 the gallery.
--   * course_image_url -> the regenerated R2 cover (the title is baked into
--     the PNG, so the rename alone would keep serving the old title).
--     Rendered via MMD_CourseImage_Model_Cover with the product's existing
--     badge set (CASL|PSEA|UTAP|SFEC|Absentee Payroll|MCES), verified HTTP 200:
--       course-covers/TGS-2026064174-20260922-153043.png  (163899 bytes)
--
-- The supplied LO1-LO4 are the learning outcomes behind the same four topics;
-- this product renders the outline only (no separate LO block and no cms_block
-- for this SKU), so there is nothing to write for them.
--
-- SG production only; keyed by SKU so a partner site without this SKU no-ops.
-- Idempotent: plain UPDATEs + INSERT IGNORE / ON DUPLICATE KEY UPDATE, and the
-- name UPDATE is guarded on the OLD value so a re-run cannot double-prefix.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026064174' LIMIT 1);
SET @et  := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');

-- ---------------------------------------------------------------- name
SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='name' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'CASL - AI Vibe Coding for Web Design'
 WHERE attribute_id = @a_name AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- url_key
SET @a_url := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_key' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'casl-ai-vibe-coding-for-web-design'
 WHERE attribute_id = @a_url AND entity_id = @pid AND @pid IS NOT NULL;

-- url_path (global + any store rows)
SET @a_upath := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_path' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'casl-ai-vibe-coding-for-web-design.html'
 WHERE attribute_id = @a_upath AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- meta_title
-- No leading "WSQ": MMD_Seotitle adds the "WSQ funded" prefix at render time.
SET @a_mt := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_title' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'AI Vibe Coding for Web Design Course | Tertiary Courses Singapore'
 WHERE attribute_id = @a_mt AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- meta_description
-- varchar(255): the string below is 236 chars.
SET @a_md := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_description' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'Learn AI Vibe Coding for Web Design in Singapore. Use AI coding assistants to build web content, improve usability, generate leads and enhance user experience. Hands-on WSQ funded course at Tertiary Courses Singapore.'
 WHERE attribute_id = @a_md AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- meta_keyword
SET @a_mk := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_keyword' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = 'AI Vibe Coding for Web Design, AI Vibe Coding, Vibe Coding, AI Web Design, AI Coding Assistant, Web Usability, Lead Generation, Online Visibility, User Experience, CASL'
 WHERE attribute_id = @a_mk AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- short_description (About This Course)
SET @a_sd := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<p>AI Vibe Coding for Web Design is a practical, hands-on course that equips participants with the skills to use AI-assisted coding techniques to create effective, user-friendly, and business-focused websites. Through natural-language instructions and AI coding assistants, learners will generate, modify, test, and refine web content and interfaces while developing practical skills in web usability, online visibility, lead generation, and user experience.</p>',
     '<p>Participants will begin with AI Vibe Coding for Web Content, learning how to create and structure engaging web pages that communicate information clearly and support business objectives. They will use AI-assisted workflows to develop and refine content, page structures, calls-to-action, and other website elements for different audiences and purposes.</p>',
     '<p>The course progresses to AI Vibe Coding for Web Usability, where learners will apply principles of navigation, accessibility, responsive design, readability, and interface consistency to make websites easier to use across different devices. Participants will then explore AI Vibe Coding for Lead Generation and Online Visibility, applying techniques to improve website discoverability, develop effective landing pages, optimise calls-to-action, and create web experiences that encourage visitor engagement and conversion.</p>',
     '<p>Finally, participants will apply AI Vibe Coding for User Experience to evaluate and enhance website interactions, layouts, content flows, and overall usability. Through hands-on activities and practical web projects, learners will use AI to prototype improvements, troubleshoot issues, and refine their designs. By the end of the course, participants will be able to use AI Vibe Coding to create and optimise websites that deliver relevant content, improve usability, strengthen online visibility, generate leads, and provide positive user experiences.</p>')
 WHERE attribute_id = @a_sd AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- description (Course Outline)
-- Keeps this product's established format: the LSN_DATA JSON marker (read by
-- the admin Lesson editor) followed by the <p><strong>/<p><em> HTML the
-- storefront renders. Both are regenerated from the same four topics.
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='description' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<!-- LSN_DATA: [',
       '{"title":"Topic 1 AI Vibe Coding for Web Content","subsecs":[',
         '{"title":"Plan and generate web page content with AI coding assistants","links":[]},',
         '{"title":"Structure pages, headings and calls-to-action for clarity","links":[]},',
         '{"title":"Refine content for different audiences and business objectives","links":[]}]},',
       '{"title":"Topic 2 AI Vibe Coding for Web Usability","subsecs":[',
         '{"title":"Build navigation and forms that are easy to use","links":[]},',
         '{"title":"Apply accessibility, readability and interface consistency","links":[]},',
         '{"title":"Make layouts responsive across devices with AI assistance","links":[]}]},',
       '{"title":"Topic 3 AI Vibe Coding for Lead Generation and Online Visibility","subsecs":[',
         '{"title":"Improve website discoverability and on-page visibility","links":[]},',
         '{"title":"Develop effective landing pages with AI Vibe Coding","links":[]},',
         '{"title":"Optimise calls-to-action to encourage engagement and conversion","links":[]}]},',
       '{"title":"Topic 4 AI Vibe Coding for User Experience","subsecs":[',
         '{"title":"Evaluate website interactions, layouts and content flows","links":[]},',
         '{"title":"Prototype and troubleshoot design improvements with AI","links":[]},',
         '{"title":"Manage multimedia content for audience needs and site functionality","links":[]}]}] -->\n',
     '<p><strong>Topic 1 AI Vibe Coding for Web Content</strong></p>\n',
     '<p><em>Plan and generate web page content with AI coding assistants</em></p>\n',
     '<p><em>Structure pages, headings and calls-to-action for clarity</em></p>\n',
     '<p><em>Refine content for different audiences and business objectives</em></p>\n',
     '<p><strong>Topic 2 AI Vibe Coding for Web Usability</strong></p>\n',
     '<p><em>Build navigation and forms that are easy to use</em></p>\n',
     '<p><em>Apply accessibility, readability and interface consistency</em></p>\n',
     '<p><em>Make layouts responsive across devices with AI assistance</em></p>\n',
     '<p><strong>Topic 3 AI Vibe Coding for Lead Generation and Online Visibility</strong></p>\n',
     '<p><em>Improve website discoverability and on-page visibility</em></p>\n',
     '<p><em>Develop effective landing pages with AI Vibe Coding</em></p>\n',
     '<p><em>Optimise calls-to-action to encourage engagement and conversion</em></p>\n',
     '<p><strong>Topic 4 AI Vibe Coding for User Experience</strong></p>\n',
     '<p><em>Evaluate website interactions, layouts and content flows</em></p>\n',
     '<p><em>Prototype and troubleshoot design improvements with AI</em></p>\n',
     '<p><em>Manage multimedia content for audience needs and site functionality</em></p>\n')
 WHERE attribute_id = @a_desc AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- who should attend
-- The old list was hand-coding roles (HTML/CSS Coder, Web Design Intern...).
SET @a_wsa := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='whoshouldattend' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<ul>',
     '<li>Web Designer</li>',
     '<li>Web Developer</li>',
     '<li>Front-End Developer</li>',
     '<li>UI Designer</li>',
     '<li>UX Designer</li>',
     '<li>Product Designer</li>',
     '<li>Digital Marketing Executive</li>',
     '<li>Content Marketing Executive</li>',
     '<li>SEO Executive</li>',
     '<li>Web Content Editor</li>',
     '<li>Content Management Executive</li>',
     '<li>Digital Media Executive</li>',
     '<li>Multimedia Designer</li>',
     '<li>Creative Technologist</li>',
     '<li>Business Owner</li>',
     '<li>Entrepreneur</li>',
     '<li>Marketing Manager</li>',
     '<li>E-commerce Executive</li>',
     '<li>Freelance Web Designer</li>',
     '<li>Web Administrator</li>',
     '</ul>')
 WHERE attribute_id = @a_wsa AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- image alt labels
-- Labels only; the image PATHS stay as-is (filesystem paths).
UPDATE catalog_product_entity_varchar v
   JOIN eav_attribute a ON a.attribute_id = v.attribute_id
    SET v.value = 'CASL - AI Vibe Coding for Web Design'
  WHERE v.entity_id = @pid AND @pid IS NOT NULL
    AND a.entity_type_id = @et
    AND a.attribute_code IN ('image_label','small_image_label','thumbnail_label');

UPDATE catalog_product_entity_media_gallery_value g
   JOIN catalog_product_entity_media_gallery m ON m.value_id = g.value_id
    SET g.label = 'CASL - AI Vibe Coding for Web Design'
  WHERE m.entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- cover image
SET @a_ciu := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='course_image_url' AND entity_type_id=@et);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @et, @a_ciu, 0, @pid,
       'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026064174-20260922-153043.png'
 WHERE @pid IS NOT NULL AND @a_ciu IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @pid AND attribute_id = @a_ciu AND store_id <> 0
   AND @pid IS NOT NULL AND @a_ciu IS NOT NULL;

-- ---------------------------------------------------------------- URL rewrites
SET @sid := (SELECT store_id FROM core_store WHERE store_id > 0 ORDER BY store_id LIMIT 1);

-- Free the OLD slug: the is_system=1 rows use id_path 'product/<id>...' -- the
-- same id_path the 301 would need -- so INSERT IGNORE would silently no-op and
-- refreshProductRewrite() would mint a '-1' suffix for the NEW slug.
DELETE FROM core_url_rewrite
 WHERE product_id = @pid AND is_system = 1 AND @pid IS NOT NULL
   AND request_path LIKE '%casl-vibe-coding-for-basic-web-design.html';

-- Clear any is_system=0 squatter sitting on the NEW paths.
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND request_path LIKE '%casl-ai-vibe-coding-for-web-design.html';

-- 301 old -> new: bare path plus each of the 12 category-prefixed paths.
INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT @sid,
       CONCAT('tgs2026064174-ai-vibe-web-', t.slot, '-', @pid),
       CONCAT(t.prefix, 'casl-vibe-coding-for-basic-web-design.html'),
       CONCAT(t.prefix, 'casl-ai-vibe-coding-for-web-design.html'),
       0, 'RP', '1533: TGS-2026064174 renamed to CASL - AI Vibe Coding for Web Design'
  FROM (
        SELECT 'bare'   AS slot, ''                                AS prefix
  UNION SELECT 'cat3',           'adult-training-courses/'
  UNION SELECT 'cat4',           'web-design-courses/'
  UNION SELECT 'cat15',          'latest-courses/'
  UNION SELECT 'cat33',          'html-css-training-courses/'
  UNION SELECT 'cat55',          'computer-programming-and-infocomm-courses/'
  UNION SELECT 'cat252',         'artificial-intelligence-courses/'
  UNION SELECT 'cat292',         'wsq-funded-courses/'
  UNION SELECT 'cat301',         'wsq-it-security-courses/'
  UNION SELECT 'cat325',         'wsq-ai-courses/'
  UNION SELECT 'cat333',         'wsq-web-design-cms-courses/'
  UNION SELECT 'cat414',         'ai-vibe-coding-series/'
  UNION SELECT 'cat425',         'wsq-ai-vibe-coding-courses/'
  ) t
 WHERE @pid IS NOT NULL AND @sid IS NOT NULL;

-- Flatten the PRE-EXISTING 301s that still target the OLD slug, so the many
-- historical URLs (wsq-vibe-coding-for-basic-web-design,
-- wsq-web-design-html-css-course, wsq-seo-sme-1083, ...) redirect ONCE to the
-- new slug instead of chaining 301 -> 301. Anchored on target_path so the
-- category-prefixed variants are flattened too.
UPDATE core_url_rewrite
   SET target_path = REPLACE(target_path,
                             'casl-vibe-coding-for-basic-web-design.html',
                             'casl-ai-vibe-coding-for-web-design.html')
 WHERE is_system = 0
   AND target_path LIKE '%casl-vibe-coding-for-basic-web-design.html'
   AND id_path NOT LIKE 'tgs2026064174-ai-vibe-web-%';

-- ---------------------------------------------------------------- search redirects
-- 37 stored search terms still point at the pre-CASL slug, which already
-- 301-chains today and would become a 2-hop chain after this rename.
-- Repoint every one of them straight at the live URL.
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/casl-ai-vibe-coding-for-web-design.html'
 WHERE redirect IN (
        'https://www.tertiarycourses.com.sg/wsq-vibe-coding-for-basic-web-design.html',
        'https://www.tertiarycourses.com.sg/casl-vibe-coding-for-basic-web-design.html',
        'https://www.tertiarycourses.com.sg/wsq-web-design-html-css-course.html');
