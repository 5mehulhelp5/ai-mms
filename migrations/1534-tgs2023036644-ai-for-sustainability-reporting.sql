-- 1534: TGS-2023036644 -> "AI for Sustainability Reporting"
--
-- Repurposes the WSQ sustainability-reporting course from a pure
-- GRI-standards course onto an AI-assisted reporting workflow. The course
-- stays a WSQ-funded TGS- SKU: the WSQ tag and the other six funding tags
-- (SkillsFuture Credit, PSEA, UTAP, SFEC, Absentee Payroll, MCES) are
-- untouched, as are categories (8), trainers, price, duration and sessions.
--
-- What was ALREADY correct on prod and is deliberately NOT touched:
--   * the Learning Outcomes cms_block (course_TGS-2023036644_learning_outcomes,
--     block_id 1943) — its stored LO1-LO3 are byte-identical to the supplied
--     outcomes, so there is nothing to write. (The "reportig" typo in LO2 is
--     pre-existing and is preserved rather than silently "fixed" here.)
--   * the other four per-course cms_blocks (brochure, certification,
--     skills_framework, funding_and_grant).
--
-- What IS rewritten here:
--   * name, url_key, url_path
--   * description — the course outline, reduced from the old 3 GRI topics to
--     the 3 supplied AI topics.
--   * short_description — the "About This Course" copy.
--   * meta_title — note it must NOT start with "WSQ": MMD_Seotitle prepends
--     "WSQ funded" at render time for TGS- SKUs on the SG site, and the
--     stored title currently starts with "WSQ", producing a duplicated
--     "WSQ funded WSQ Sustainability Reporting Course..." on the live page.
--   * meta_description (<= 255 chars, varchar column), meta_keyword
--   * image_label / small_image_label / thumbnail_label (the real alt text).
--     The image/small_image/thumbnail PATHS are left alone on purpose —
--     they are filesystem paths and renaming them would 404 the gallery.
--   * course_image_url -> the regenerated R2 cover (the title is baked into
--     the PNG, so the rename alone would keep serving the old title).
--     Rendered via MMD_CourseImage_Model_Cover with the product's existing
--     badge set (WSQ|SkillsFuture Credit|PSEA|UTAP|SFEC|Absentee Payroll|
--     MCES), verified HTTP 200:
--       course-covers/TGS-2023036644-20260922-153550.png  (162807 bytes)
--   * URL rewrites: 301 the old slug (bare + each of the 8 category
--     prefixes) to the new one, and flatten the 26 pre-existing 301s that
--     still target the old slug so they redirect ONCE instead of chaining.
--   * the 13 stored search-term redirects pointing at the old slug.
--
-- SG production only; keyed by SKU so a partner site without this SKU no-ops.
-- Idempotent: plain UPDATEs + INSERT IGNORE / ON DUPLICATE KEY UPDATE.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2023036644' LIMIT 1);
SET @et  := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');

-- ---------------------------------------------------------------- name
SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='name' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'AI for Sustainability Reporting'
 WHERE attribute_id = @a_name AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- url_key
SET @a_url := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_key' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'ai-for-sustainability-reporting'
 WHERE attribute_id = @a_url AND entity_id = @pid AND @pid IS NOT NULL;

-- url_path (global + any store rows)
SET @a_upath := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_path' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'ai-for-sustainability-reporting.html'
 WHERE attribute_id = @a_upath AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- meta_title
-- No leading "WSQ": MMD_Seotitle adds the "WSQ funded" prefix at render time.
SET @a_mt := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_title' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'AI for Sustainability Reporting Course | Tertiary Courses Singapore'
 WHERE attribute_id = @a_mt AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- meta_description
SET @a_md := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_description' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'Learn to apply AI and Generative AI to sustainability reporting in Singapore. Use AI for data analysis, gap analysis, GRI framework mapping, narrative drafting and compliance checks to produce audit-ready reports. Up to 70% WSQ funding subsidy.'
 WHERE attribute_id = @a_md AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- meta_keyword
SET @a_mk := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_keyword' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = 'AI for Sustainability Reporting, Sustainability Reporting, GRI Standards, Generative AI, ESG Reporting, AI Data Analysis, Prompt Engineering, Compliance, Responsible AI, WSQ'
 WHERE attribute_id = @a_mk AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- description (Course Outline)
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='description' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<h3 class="course-topic-h3">Topic 1: Introduction to AI for Sustainability Reporting</h3>',
     '<ul>',
     '<li>Overview of sustainability reporting and ESG disclosure requirements</li>',
     '<li>Objectives of sustainability reports and organisational reporting procedures</li>',
     '<li>How AI and Generative AI support the sustainability reporting process</li>',
     '<li>AI tools and capabilities across the reporting workflow</li>',
     '<li>Prompt engineering for accurate, source-based reporting content</li>',
     '<li>Managing hallucinations, unsupported claims and responsible AI use</li>',
     '</ul>',
     '<h3 class="course-topic-h3">Topic 2: AI-Assisted Sustainability Data Analysis and Report Development</h3>',
     '<ul>',
     '<li>Preparing and structuring sustainability data for AI analysis</li>',
     '<li>Using AI to analyse sustainability data and surface insights</li>',
     '<li>Mapping disclosures to GRI standards and reporting frameworks</li>',
     '<li>AI-assisted gap analysis to identify missing or incomplete disclosures</li>',
     '<li>Drafting sustainability report narratives with Generative AI</li>',
     '<li>Collaborating with stakeholders on AI-assisted report development</li>',
     '</ul>',
     '<h3 class="course-topic-h3">Topic 3: AI-Assisted Report Review, Compliance and Presentation</h3>',
     '<ul>',
     '<li>Using AI to proofread and refine sustainability reports</li>',
     '<li>AI-assisted compliance checking against reporting requirements</li>',
     '<li>Evidence management, traceability and audit readiness</li>',
     '<li>Displaying sustainability data effectively with AI support</li>',
     '<li>Human oversight, verification and data accuracy safeguards</li>',
     '<li>Submitting and presenting reports to relevant stakeholders</li>',
     '</ul>')
 WHERE attribute_id = @a_desc AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- short_description (About This Course)
SET @a_sd := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<p>Enhance your expertise in Sustainability Reporting with Artificial Intelligence (AI) through this practical course designed to help professionals streamline and strengthen the sustainability reporting process. Learn how AI and Generative AI tools can support the collection and analysis of sustainability data, identify reporting gaps, and transform verified information into clear and structured sustainability disclosures.</p>',
     '<p>Participants will gain hands-on experience using AI to support key reporting activities, including data preparation, framework mapping, gap analysis, narrative drafting, compliance checking, and evidence management. The course also explores effective prompt engineering techniques to generate accurate, relevant, and source-based reporting content while reducing the risks of hallucinations and unsupported claims.</p>',
     '<p>Through practical exercises and real-world reporting scenarios, participants will learn how to integrate AI into sustainability reporting workflows while maintaining human oversight, data accuracy, traceability, and responsible AI practices. By the end of the course, participants will be equipped to use AI effectively to produce more efficient, consistent, and audit-ready sustainability reports aligned with recognised sustainability reporting requirements.</p>')
 WHERE attribute_id = @a_sd AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- image alt labels
-- Labels only; the image PATHS stay as-is (filesystem paths).
UPDATE catalog_product_entity_varchar v
   JOIN eav_attribute a ON a.attribute_id = v.attribute_id
    SET v.value = 'AI for Sustainability Reporting'
  WHERE v.entity_id = @pid AND @pid IS NOT NULL
    AND a.entity_type_id = @et
    AND a.attribute_code IN ('image_label','small_image_label','thumbnail_label');

UPDATE catalog_product_entity_media_gallery_value g
   JOIN catalog_product_entity_media_gallery m ON m.value_id = g.value_id
    SET g.label = 'AI for Sustainability Reporting'
  WHERE m.entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- cover image
SET @a_ciu := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='course_image_url' AND entity_type_id=@et);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @et, @a_ciu, 0, @pid,
       'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2023036644-20260922-153550.png'
 WHERE @pid IS NOT NULL AND @a_ciu IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @pid AND attribute_id = @a_ciu AND store_id <> 0
   AND @pid IS NOT NULL AND @a_ciu IS NOT NULL;

-- ---------------------------------------------------------------- URL rewrites
SET @sid := (SELECT store_id FROM core_store WHERE store_id > 0 ORDER BY store_id LIMIT 1);

-- Free the OLD slug: the is_system=1 rows use id_path 'product/<id>...' — the
-- same id_path the 301 would need — so INSERT IGNORE would silently no-op and
-- refreshProductRewrite() would mint a '-1' suffix for the NEW slug.
DELETE FROM core_url_rewrite
 WHERE product_id = @pid AND is_system = 1 AND @pid IS NOT NULL
   AND request_path LIKE '%wsq-sustainability-reporting-and-gri-standards.html';

-- Clear any is_system=0 squatter sitting on the NEW paths.
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND request_path LIKE '%ai-for-sustainability-reporting.html';

-- 301 old -> new: bare path plus each of the 8 category-prefixed paths.
INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT @sid,
       CONCAT('tgs2023036644-ai-sustain-rep-', t.slot, '-', @pid),
       CONCAT(t.prefix, 'wsq-sustainability-reporting-and-gri-standards.html'),
       CONCAT(t.prefix, 'ai-for-sustainability-reporting.html'),
       0, 'RP', '1534: TGS-2023036644 renamed to AI for Sustainability Reporting'
  FROM (
        SELECT 'bare'   AS slot, ''                                AS prefix
  UNION SELECT 'cat3',           'adult-training-courses/'
  UNION SELECT 'cat15',          'latest-courses/'
  UNION SELECT 'cat292',         'wsq-funded-courses/'
  UNION SELECT 'cat293',         'wsq-finance-mfg-green-courses/'
  UNION SELECT 'cat301',         'wsq-it-security-courses/'
  UNION SELECT 'cat332',         'esg-and-sustainability-courses/'
  UNION SELECT 'cat401',         'sustainability-and-environment-courses/'
  UNION SELECT 'cat412',         'wsq-sustainability-esg-courses/'
  ) t
 WHERE @pid IS NOT NULL AND @sid IS NOT NULL;

-- Flatten the PRE-EXISTING 301s that still target the OLD slug, so the many
-- historical URLs (wsq-carbon-footprint-management-for-sustainability-*,
-- sustainability-reporting-courses/*, wsq-courses/*, ntuc-utap-courses/*, ...)
-- redirect ONCE to the new slug instead of chaining 301 -> 301.
UPDATE core_url_rewrite
   SET target_path = REPLACE(target_path,
                             'wsq-sustainability-reporting-and-gri-standards.html',
                             'ai-for-sustainability-reporting.html')
 WHERE is_system = 0
   AND target_path LIKE '%wsq-sustainability-reporting-and-gri-standards.html'
   AND id_path NOT LIKE 'tgs2023036644-ai-sustain-rep-%';

-- ---------------------------------------------------------------- search redirects
-- 13 stored search terms point at the old slug, which now 301-chains.
-- Repoint them straight at the live URL.
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/ai-for-sustainability-reporting.html'
 WHERE redirect = 'https://www.tertiarycourses.com.sg/wsq-sustainability-reporting-and-gri-standards.html';
