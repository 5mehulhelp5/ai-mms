-- 1395: Correct the TITLE of TGS-2026064715 (entity_id 1272)
--   "CASL - Python Text Mining and Analytics: Transforming Text"
--     -> "CASL - Python Text Mining and Analytics: Transforming Text into Insights"
--
-- This is a TITLE CORRECTION (the live name was truncated -- it lost the trailing
-- "into Insights"), NOT a repurpose. The subject, the accredited competency, the
-- categories, the LOs and the whole funding apparatus are unchanged, so this
-- migration deliberately touches ONLY: name, url_key/url_path, the three meta
-- fields, the alt-text/gallery labels, the url rewrites and the search redirects.
--
-- SKU UNCHANGED -- every SkillsFuture / SFEC / PSEA / CASL deep link and the TPG
-- course reference are keyed on it.
--
-- ===========================================================================
-- "CASL - " PREFIX IS KEPT (confirmed with the admin)
-- ===========================================================================
-- The product carries the CASL tag (alongside SkillsFuture Credit, SFEC, PSEA,
-- Absentee Payroll, MCES) and every one of its 20 live CASL siblings uses the
-- "CASL - <plain title>" / "casl-<slugified-plain-title>" shape:
--     CASL - AI Vibe Coding with PyTorch  / casl-ai-vibe-coding-with-pytorch
--     CASL - Data Analytics with Excel    / casl-data-analytics-with-excel
-- The prefix also drives the funded-first category ordering and the funded-course
-- UI, so dropping it would silently demote the course in every listing.
--
-- ===========================================================================
-- SLUG: THE NEW ONE IS FREE, AND THE OLD CHAIN MUST BE FLATTENED
-- ===========================================================================
-- New-slug collision probe (memory
-- feedback_repurpose_target_name_may_already_exist_as_live_twin -- probe name AND
-- url_key): 'casl-python-text-mining%' returns ZERO rows in
-- catalog_product_entity_varchar.url_key and ZERO in core_url_rewrite; the live
-- URL 404s today. The only '%text-mining%' url_keys belong to OTHER entities
-- (577 text-mining-with-r, 808 text-mining-with-orange) -- untouched here.
--
-- Entity 1272 has been renamed THREE times already, so a long 301 chain exists:
--     wsq-text-analytics-with-python            -> casl-ai-vibe-coding-for-data-mining
--     wsq-python-text-mining-...-into-insights   -> casl-ai-vibe-coding-for-data-mining
--     wsq-ai-vibe-coding-for-data-mining         -> casl-ai-vibe-coding-for-data-mining
-- plus ~30 category-path variants of the same three. Left alone every one becomes
-- a 2-hop chain the moment url_key moves (memory
-- feedback_rename_chain_flatten_must_anchor_request_path), so section 3c
-- re-points EVERY is_system = 0 row whose TARGET is a current path at the new
-- path -- both the bare slug and the '<category>/<slug>' forms.
--
-- The is_system = 1 DELETE (3b) is mandatory: that row's id_path is
-- product/1272, the SAME id_path the 301 needs, so without it the INSERT IGNORE
-- silently no-ops AND refreshProductRewrite mints a '-1' suffixed slug (memory
-- feedback_repurpose_301_needs_system_row_delete).
--
-- ===========================================================================
-- PRODUCT IMAGE
-- ===========================================================================
-- The R2 cover PNG bakes the title into the image, so it CANNOT be re-rendered in
-- SQL (memory feedback_cover_rerender_save_needs_store0_then_clear_overrides).
-- course_image_url is left pointing at the existing object and the PNG is
-- re-rendered from the admin Course Cover dialog after deploy -- the renderer
-- writes the new course_image_url itself.
--
-- What this migration DOES fix is the text that surrounds the image and is wrong
-- today: the three alt-text labels still say "WSQ - ..." (stale prefix -- the
-- course is CASL now) and the media-gallery label still says the long-dead "WSQ
-- Text Analytics with Python". All four are set to the PLAIN new title (the cover
-- renderer itself strips the funding prefix, so labels carry no "CASL - ").
-- The `image` / `small_image` / `thumbnail` FILESYSTEM paths (/p/y/pytextmine.png)
-- are NOT renamed -- renaming 404s them (memory
-- feedback_rename_probe_first_shrinks_scope).
--
-- ===========================================================================
-- META
-- ===========================================================================
-- meta_title: PLAIN title -- NO leading "WSQ"/"CASL", NO "| Tertiary Courses
-- Singapore" suffix. MMD_Seotitle composes <title> at render time (memory
-- project_seo_title_render_time_composer). The OLD live value baked in BOTH (the
-- 853 bug) AND described the retired "Text Analytics with Python" course, plus it
-- carried a trailing space -- all cleaned up here.
-- meta_description is varchar(255) (memory feedback_meta_description_255_char_cap);
-- the value below is 243 chars. It also drops the stale "WSQ-endorsed"/"WSQ
-- funding" wording, which is wrong for a CASL course.
-- meta_keyword lives in catalog_product_entity_TEXT -- a varchar write is silently
-- ignored (same memory).
--
-- ===========================================================================
-- SEARCH REDIRECTS
-- ===========================================================================
-- 15 catalogsearch_query rows already point at
-- wsq-python-text-mining-and-analytics-transforming-text-into-insights.html --
-- i.e. at a 301 that currently lands on the vibe-coding slug. They are re-pointed
-- at the new absolute URL so none rots into a 404 or a 2-hop chain (memory
-- feedback_search_redirect_rot_into_live_200_repurposed_slug). Rows targeting
-- the OTHER entities' slugs (wsq-text-analytics-with-r.html, entity 577) are NOT
-- touched -- different course.
--
-- SG-only: guarded on @mms_instance (memory
-- feedback_prefer_mms_instance_guard_over_base_url_count) -- env-derived, so it
-- really runs on localhost and provably skips on MY/GH, which run this same chain
-- against their own DBs and have no TGS- SKUs.
-- ASCII-only payload -- no invalid UTF-8 can reach apply.php's utf8 connection
-- (memory feedback_migration_applyphp_utf8_outage).

SET @is_sg := IF(@mms_instance = 'SG', 1, 0);

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2026064715');

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_ilabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_slabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_tlabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');

SET @old_slug := 'casl-ai-vibe-coding-for-data-mining';
SET @new_slug := 'casl-python-text-mining-and-analytics-transforming-text-into-insights';
SET @old_path := CONCAT(@old_slug, '.html');
SET @new_path := CONCAT(@new_slug, '.html');

-- ---------------------------------------------------------------------------
-- 1. name -- restores the truncated "into Insights", keeps the "CASL - " prefix
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'CASL - Python Text Mining and Analytics: Transforming Text into Insights'
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_name;

-- ---------------------------------------------------------------------------
-- 2. url_key + url_path
--    Delete url_path at EVERY scope (live has a store 0 AND a store 1 row) so the
--    URL Rewrites indexer regenerates them.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = @new_slug
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_urlkey;

DELETE FROM catalog_product_entity_varchar
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_urlpath;

-- ---------------------------------------------------------------------------
-- 3. URL rewrites
-- ---------------------------------------------------------------------------
-- 3a. Drop any is_system = 0 squatter on the NEW path (the 647 trap: INSERT
--     IGNORE silently no-ops against a stale row).
DELETE FROM core_url_rewrite
WHERE @is_sg = 1 AND request_path = @new_path AND is_system = 0;

-- 3b. Drop the is_system = 1 row holding the OLD bare slug. Its id_path is
--     product/<entity_id> -- the SAME id_path the 301 needs -- so without this
--     DELETE the INSERT IGNORE below creates nothing and the old URL 404s.
DELETE FROM core_url_rewrite
WHERE @is_sg = 1 AND @e IS NOT NULL
  AND product_id = @e AND request_path = @old_path AND is_system = 1;

-- 3c. Flatten the EXISTING chain from the three earlier renames. Anchored on
--     target_path so both the bare slug and every '<category>/<slug>' variant
--     that 301s into a CURRENT path is re-pointed at the NEW bare path.
UPDATE core_url_rewrite
SET target_path = @new_path
WHERE @is_sg = 1 AND @e IS NOT NULL AND product_id = @e AND is_system = 0
  AND (target_path = @old_path OR target_path LIKE CONCAT('%/', @old_path));

-- 3d. Explicit 301 for the old BARE slug. The indexer auto-301s the ~13 category
--     paths from its rewrite history; only the bare slug needs seeding.
INSERT IGNORE INTO core_url_rewrite
    (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT 1, NULL, @e,
       CONCAT('product/', @e),
       @old_path,
       @new_path,
       0, 'RP', 'Rename 1395: vibe-coding-for-data-mining slug -> Python Text Mining and Analytics'
FROM dual
WHERE @is_sg = 1 AND @e IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
    WHERE x.request_path = @old_path AND x.store_id = 1 AND x.is_system = 0
);

-- ---------------------------------------------------------------------------
-- 4. meta_title / meta_description / meta_keyword
--    meta_title is the PLAIN title -- MMD_Seotitle prepends the funding prefix
--    and appends the brand suffix at render time.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'Python Text Mining and Analytics: Transforming Text into Insights'
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_mtitle;

UPDATE catalog_product_entity_varchar
SET value = 'Turn raw text into business insights with Python. Hands-on text mining, tokenization, sentiment analysis, topic modelling and text classification using NLTK, spaCy and scikit-learn. CASL funded with SkillsFuture Credit, PSEA and SFEC support.'
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_mdesc;

UPDATE catalog_product_entity_text
SET value = 'Python Text Mining, Text Analytics, Natural Language Processing, Sentiment Analysis, Topic Modelling, Text Classification, NLTK, spaCy, CASL Funding, Data Insights'
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_mkey;

-- ---------------------------------------------------------------------------
-- 5. PRODUCT IMAGE -- alt-text labels + media-gallery label.
--    PLAIN title (the cover renderer strips the funding prefix). Clears the
--    stale "WSQ - " alt text and the dead "WSQ Text Analytics with Python"
--    gallery label. File paths and course_image_url are intentionally untouched;
--    the cover PNG is re-rendered from the admin dialog after deploy.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'Python Text Mining and Analytics: Transforming Text into Insights'
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e
  AND attribute_id IN (@a_ilabel, @a_slabel, @a_tlabel);

UPDATE catalog_product_entity_media_gallery_value v
JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
SET v.label = 'Python Text Mining and Analytics: Transforming Text into Insights'
WHERE @is_sg = 1 AND @e IS NOT NULL AND g.entity_id = @e;

-- ---------------------------------------------------------------------------
-- 6. Search-term redirects -- re-point the 15 rows that target this entity's
--    previous slugs so none rots into a 404 or a 2-hop chain. Rows pointing at
--    wsq-text-analytics-with-r.html belong to entity 577 and are NOT touched.
-- ---------------------------------------------------------------------------
UPDATE catalogsearch_query
SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_path)
WHERE @is_sg = 1
  AND redirect IN (
    CONCAT('https://www.tertiarycourses.com.sg/', @old_path),
    'https://www.tertiarycourses.com.sg/wsq-python-text-mining-and-analytics-transforming-text-into-insights.html',
    'https://www.tertiarycourses.com.sg/wsq-text-analytics-with-python.html',
    'https://www.tertiarycourses.com.sg/wsq-ai-vibe-coding-for-data-mining.html'
);
