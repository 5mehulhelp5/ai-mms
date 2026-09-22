-- 1532: TGS-2026064175 -> "CASL - AI for Shopify eCommerce Store"
--
-- Retitles the CASL course from "Build Your Own eCommerce Store with AI Vibe
-- Coding" to "AI for Shopify eCommerce Store", re-slugs it with a permanent
-- 301 from the old URL, refreshes the title-derived metas + media alt labels,
-- restates the overview to the Shopify framing, and points course_image_url at
-- a newly rendered cover carrying the new title.
--
-- PROBED FIRST (2026-09-22): these surfaces were ALREADY correct on prod and are
-- deliberately NOT touched -
--   * description   - already exactly the 5 requested topics (LSN_DATA + <p>)
--   * learning outcomes cms_block - already LO1..LO6 as requested
--   * whoshouldattend - already the Shopify job-role list
--   * skills_framework - already the Retail SF "Content Management System
--     Utilisation RET-CIE-4002-1.1 TSC", which matches the Shopify/CMS framing
--   * certification block - already clean CASL, no SOA bullet
--   * CASL tag + CASL - name prefix - already present, PRESERVED here
-- Rewriting them would be churn and risks clobbering correct copy.
-- See feedback_rename_probe_first_shrinks_scope.
--
-- SG production only; keyed by SKU so a partner site with no such SKU no-ops.
-- Idempotent: re-running changes nothing (every UPDATE is value-absolute and
-- the rewrite INSERT is guarded).

SET @et := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product');
SET @e  := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026064175' LIMIT 1);

-- ---------------------------------------------------------------------------
-- 1. Title-derived attributes
-- ---------------------------------------------------------------------------

-- name: keep the "CASL - " prefix (explicitly requested)
SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='name' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'CASL - AI for Shopify eCommerce Store'
 WHERE attribute_id = @a_name AND entity_id = @e AND @e IS NOT NULL;

-- meta_title: stored BARE (no "WSQ"/"CASL" prefix, no brand suffix). MMD_Seotitle
-- prepends the funding prefix and appends the brand at render time; storing a
-- prefixed value yields a duplicated "WSQ funded WSQ ..." <title>.
SET @a_mt := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_title' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'AI for Shopify eCommerce Store Training'
 WHERE attribute_id = @a_mt AND entity_id = @e AND @e IS NOT NULL;

-- meta_description: varchar(255) - keep under the cap
SET @a_md := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_description' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'AI for Shopify eCommerce Store training in Singapore. Use AI to set up a Shopify store, curate product and web content, customise themes, and manage orders, payments, shipping and store marketing.'
 WHERE attribute_id = @a_md AND entity_id = @e AND @e IS NOT NULL;

SET @a_mk := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_keyword' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = 'AI for Shopify eCommerce Store, Shopify course Singapore, Shopify training, AI Shopify store setup, Shopify CMS course, Shopify theme customisation, Shopify order management, Shopify payment and shipping, CASL Shopify course, eCommerce store training Singapore'
 WHERE attribute_id = @a_mk AND entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 2. Overview (short_description) - restated for the Shopify framing.
--    NB the live value carries a mojibake byte (U+FFFD where an em dash was);
--    this rewrite replaces the whole value with clean ASCII.
-- ---------------------------------------------------------------------------
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = '<p>This course equips participants with practical skills to build, manage, and enhance a Shopify eCommerce store using Artificial Intelligence (AI). Learners will explore how AI tools can support key stages of eCommerce development, from setting up the storefront and creating product content to improving customer experience and streamlining day-to-day store operations.</p><p>Participants will learn to configure Shopify themes, product catalogues, collections, inventory, orders, customers, discounts, and essential store settings. They will use AI to generate and refine product titles, descriptions, images, promotional content, SEO keywords, and marketing materials. The course also explores how AI can support personalised customer experiences, customer enquiries, product recommendations, and eCommerce marketing activities.</p><p>Learners will gain hands-on experience using Shopify''s built-in features and AI capabilities to optimise store content, improve search visibility, analyse sales and customer data, and identify opportunities for business improvement. Key considerations such as payment setup, shipping, store security, testing, and publishing will also be covered.</p><p>By the end of the course, participants will be able to create and manage a professional Shopify eCommerce store and apply AI effectively to improve content creation, marketing, customer engagement, operational efficiency, and data-driven decision-making to support eCommerce business growth.</p>'
 WHERE attribute_id = @a_short AND entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 3. Cover image. course_image_url is the R2-hosted rendered cover (title is
--    BAKED INTO the PNG, so a rename needs a re-render - this URL is the new
--    render). image/small_image/thumbnail stay as-is: they are filesystem
--    paths and renaming them 404s the media.
--    Alt labels DO carry the title and are updated.
-- ---------------------------------------------------------------------------
SET @a_ciu := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='course_image_url' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026064175-20260922-152759.png'
 WHERE attribute_id = @a_ciu AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar v
   JOIN eav_attribute a ON a.attribute_id = v.attribute_id
    SET v.value = 'AI for Shopify eCommerce Store'
  WHERE v.entity_id = @e AND @e IS NOT NULL
    AND a.entity_type_id = @et
    AND a.attribute_code IN ('image_label','small_image_label','thumbnail_label');

-- media gallery label is the real alt text on the product page gallery
UPDATE catalog_product_entity_media_gallery_value gv
   JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
    SET gv.label = 'AI for Shopify eCommerce Store'
  WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 4. Slug move + permanent 301
-- ---------------------------------------------------------------------------
SET @a_url  := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_key'  AND entity_type_id=@et);
SET @a_path := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_path' AND entity_type_id=@et);

UPDATE catalog_product_entity_varchar
   SET value = 'casl-ai-for-shopify-ecommerce-store'
 WHERE attribute_id = @a_url AND entity_id = @e AND @e IS NOT NULL;

-- drop url_path at every scope; Magento regenerates it on rewrite refresh
DELETE FROM catalog_product_entity_varchar
 WHERE attribute_id = @a_path AND entity_id = @e AND @e IS NOT NULL;

-- 4a. Free the NEW path of any squatting non-system row.
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND request_path IN ('casl-ai-for-shopify-ecommerce-store.html')
   AND @e IS NOT NULL;

-- 4b. DELETE the is_system=1 rows holding the OLD slug (bare + category-scoped).
--     Without this the canonical rewrite for the new slug gets a "-<id>" suffix
--     and the new URL 404s. See feedback_repurpose_301_needs_system_row_delete.
DELETE FROM core_url_rewrite
 WHERE product_id = @e AND is_system = 1 AND @e IS NOT NULL
   AND (request_path = 'casl-build-your-own-ecommerce-store-with-ai-vibe-coding.html'
        OR request_path LIKE '%/casl-build-your-own-ecommerce-store-with-ai-vibe-coding.html');

-- 4c. Permanent 301 old -> new.
--     id_path is DELIBERATELY NOT 'product/<id>': that id_path belongs to the
--     canonical is_system=1 rewrite, and squatting it stops Magento ever
--     regenerating the new slug's rewrite (new URL 404s forever).
--     See feedback_rename_301_row_squats_id_path_blocks_system_rewrite.
SET @sid := (SELECT store_id FROM core_store WHERE store_id > 0 ORDER BY store_id LIMIT 1);

INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT @sid,
       CONCAT('tgs2026064175-shopify-rename-', @e),
       'casl-build-your-own-ecommerce-store-with-ai-vibe-coding.html',
       'casl-ai-for-shopify-ecommerce-store.html',
       0, 'RP', '1532: TGS-2026064175 renamed to AI for Shopify eCommerce Store'
WHERE @e IS NOT NULL AND @sid IS NOT NULL;

-- 4d. Re-point every EXISTING 301 that targeted the old slug straight at the new
--     one, so legacy aliases stay 1 hop instead of chaining old -> older -> new.
--     Anchored on target_path; covers the bare and category-prefixed forms.
UPDATE core_url_rewrite
   SET target_path = 'casl-ai-for-shopify-ecommerce-store.html'
 WHERE is_system = 0
   AND request_path <> 'casl-build-your-own-ecommerce-store-with-ai-vibe-coding.html'
   AND (target_path = 'casl-build-your-own-ecommerce-store-with-ai-vibe-coding.html'
        OR target_path LIKE '%/casl-build-your-own-ecommerce-store-with-ai-vibe-coding.html');

-- 4e. Flatten any CATEGORY-PREFIXED 301 target to the bare slug. Category URLs
--     are always flat here (MMD_FlatCategoryUrl), so a prefixed target 301s
--     into a 404. Idempotent: already-flat rows contain no '/'.
UPDATE core_url_rewrite
   SET target_path = SUBSTRING_INDEX(target_path, '/', -1)
 WHERE is_system = 0
   AND target_path LIKE '%/casl-ai-for-shopify-ecommerce-store.html';
