-- 1394: Rename TGS-2021009337
--   "WSQ - Pay Per Click (PPC) Campaign Optimization:  Driving ROI with Google Ads"
--     -> "WSQ - Generative AI for Paid Search Marketing"
--
-- SKU UNCHANGED (every SkillsFuture / SFEC / SFC / PSEA / UTAP deep link and the
-- TPG course reference are keyed on it). Funding validity 20-10-2021 -> 19-10-2027
-- was verified ALREADY CORRECT on live (news_from_date = 2021-10-20,
-- news_to_date = 2027-10-19) -- this migration deliberately does NOT rewrite the
-- dates, there is nothing to change.
--
-- ===========================================================================
-- SCOPE: THIS IS A TITLE/BRANDING RENAME, *NOT* A SUBJECT REPURPOSE.
-- ===========================================================================
-- Established by reading skills_framework FIRST (memory
-- feedback_repurpose_realigns_to_own_accredited_tsc) against the live SG DB:
--
--   cms_block course_TGS-2021009337_skills_framework (block_id 2667) reads
--   "Paid Search Engine Marketing RET-OTO-4004-1.1 TSC under Retail Skills
--   Framework"
--
-- The registered competency IS "Paid Search Marketing" -- which is precisely the
-- new title. The accredited subject does not move at all; only the course's
-- branding moves onto the Generative-AI framing used by its 11 WSQ siblings.
--
-- Corroborated by the admin-supplied content being BYTE-EQUIVALENT to live
-- (memory feedback_repurpose_tool_swap_keeps_everything -- diff the supplied LOs
-- against the live block before deciding scope):
--   * supplied LO1-LO5      == cms_block 1873 learning_outcomes, verbatim
--   * supplied "About This Course" (2 paras) == live short_description, verbatim
--   * supplied Topics 1-5 + all bullets      == live description, verbatim
--
-- CONSEQUENCE -- these surfaces are DELIBERATELY NOT TOUCHED:
--   * short_description / description  -- supplied copy is identical to live;
--     rewriting would be pure churn (and a full sdesc replace risks the legacy
--     funding-card fallback, memory feedback_conversion_drops_legacy_funding_fallback).
--   * cms_block learning_outcomes (1873) / skills_framework (2667) /
--     certification (2398) / funding_and_grant (2958) / brochure (970) -- all
--     five confirmed present and all describe the UNCHANGED accredited
--     competency. Editing SSG-accredited LO text is never churn-free.
--   * All 11 categories (3, 8, 15, 36 PPC Marketing, 67 Google, 72, 238 Google
--     Ads, 292, 293, 301, 308) -- the course still teaches paid search with
--     Google Ads, so PPC/Google Ads membership remains correct. No vendor or
--     exam-prep category exists to drop.
--   * whoshouldattend -- swept and CLEAN: all 15 roles (PPC Specialist, SEM
--     Specialist, Digital Marketing Manager...) are the roles for paid search
--     marketing and remain accurate.
--   * prerequisite (12042 bytes) -- the whole funding apparatus (PWM, Funding
--     Eligibility, SkillsFuture/PSEA/SFEC/UTAP deep links, Appeal Process).
--     Swept for the old title: NO hits, so not one byte is touched.
--   * trainerprofile -- career credentials in paid search / Google Ads; true and
--     still in scope.
--   * The 7 badge tags (WSQ, SkillsFuture Credit, PSEA, SFEC, UTAP, Absentee
--     Payroll, MCES) -- funding status unchanged.
--
-- NEW-TITLE COLLISION CHECK (memory
-- feedback_repurpose_target_name_may_already_exist_as_live_twin -- probe name AND
-- url_key): 'generative-ai-for-paid-search%' returned ZERO rows in
-- catalog_product_entity_varchar.url_key and ZERO in core_url_rewrite. The
-- "WSQ - Generative AI for <topic>" / "wsq-generative-ai-for-<topic>" shape
-- matches all 11 live WSQ siblings (TGS-2021003023 Social Media Marketing,
-- TGS-2020503501 SEO, TGS-2023037589 Content Creation, ...), so the house
-- convention is preserved. The mandatory "WSQ - " name prefix is kept: it drives
-- the WSQ-first category ordering and the funded-course UI.
--
-- meta_title: PLAIN title -- NO leading "WSQ", NO "| Tertiary Courses Singapore"
-- suffix. MMD_Seotitle composes <title> at render time (memory
-- project_seo_title_render_time_composer). The OLD value baked in BOTH ("WSQ
-- Master PPC Marketing with Google Ads - ... | Tertiary Courses Singapore") --
-- the 853 bug -- so this migration also cleans that up.
-- meta_description is varchar(255) (memory feedback_meta_description_255_char_cap):
-- the value below is 238 chars.
--
-- URL REWRITES -- chain flatten (memory
-- feedback_rename_chain_flatten_must_anchor_request_path). This entity has been
-- renamed before: ~20 rows for the FOREIGN old slug
-- 'wsq-per-pay-click-ppc-marketing-google-ads' already 301 into the CURRENT
-- slug. Left alone those become 2-hop chains (old -> current -> new), so every
-- is_system = 0 row whose TARGET is the current path is re-pointed at the new
-- path, anchored on request_path. Plus the is_system = 1 DELETE on the old bare
-- slug (memory feedback_repurpose_301_needs_system_row_delete) -- without it the
-- INSERT IGNORE no-ops on the shared id_path AND refreshProductRewrite mints a
-- '-1239' suffix for the new slug.
--
-- SEARCH REDIRECTS -- 18 catalogsearch_query rows (PPC, pay per click, wsq
-- google ads, ...) point at the current slug and would ROT INTO 404s the moment
-- url_key changes (memory feedback_search_redirect_rot_into_live_200_repurposed_slug).
-- They are re-pointed to the new absolute URL. All are legitimate paid-search
-- intent, so every one is kept.
--
-- COVER PNG: the R2 cover bakes the title, so the image cannot be re-rendered in
-- SQL (memory feedback_cover_rerender_save_needs_store0_then_clear_overrides).
-- course_image_url is left pointing at the existing object here and the PNG is
-- re-rendered from the admin Course Cover dialog after deploy; the alt-text
-- labels + media-gallery label below carry the new plain title. The `image` /
-- `small_image` / `thumbnail` FILESYSTEM paths are NOT renamed (renaming 404s
-- them -- memory feedback_rename_probe_first_shrinks_scope).
--
-- SG-only: guarded on @mms_instance (memory
-- feedback_prefer_mms_instance_guard_over_base_url_count) -- env-derived, so it
-- really runs on localhost and can be proven to skip on MY/GH, which run this
-- same chain against their own DBs and have no TGS- SKUs.
-- ASCII-only payload -- no invalid UTF-8 can reach apply.php's utf8 connection
-- (memory feedback_migration_applyphp_utf8_outage).

SET @is_sg := IF(@mms_instance = 'SG', 1, 0);

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2021009337');

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_ilabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_slabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_tlabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');

SET @old_slug := 'wsq-pay-per-click-ppc-campaign-optimization-driving-roi-with-google-ads';
SET @new_slug := 'wsq-generative-ai-for-paid-search-marketing';
SET @old_path := CONCAT(@old_slug, '.html');
SET @new_path := CONCAT(@new_slug, '.html');

-- ---------------------------------------------------------------------------
-- 1. name  (keeps the "WSQ - " prefix; also drops the stray double space that
--    the live value carried after the colon)
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'WSQ - Generative AI for Paid Search Marketing'
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_name;

-- ---------------------------------------------------------------------------
-- 2. url_key + url_path
--    Delete url_path at EVERY scope (live has store 0 AND store 1 rows) so the
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

-- 3c. Flatten the EXISTING chain: rows (from the earlier rename) that 301 into
--     the CURRENT path are re-pointed at the NEW path so nothing becomes 2-hop.
UPDATE core_url_rewrite
SET target_path = @new_path
WHERE @is_sg = 1 AND is_system = 0 AND target_path = @old_path;

-- 3d. Explicit 301 for the old BARE slug. The indexer auto-301s the ~11
--     category paths from its rewrite history; only the bare slug needs seeding.
INSERT IGNORE INTO core_url_rewrite
    (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT 1, NULL, @e,
       CONCAT('product/', @e),
       @old_path,
       @new_path,
       0, 'RP', 'Rename 1394: old PPC slug -> Generative AI for Paid Search Marketing'
FROM dual
WHERE @is_sg = 1 AND @e IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
    WHERE x.request_path = @old_path AND x.store_id = 1 AND x.is_system = 0
);

-- ---------------------------------------------------------------------------
-- 4. meta_title / meta_description / meta_keyword
--    meta_title is the PLAIN title -- MMD_Seotitle prepends "WSQ funded" and
--    appends the brand suffix at render time.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'Generative AI for Paid Search Marketing'
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_mtitle;

UPDATE catalog_product_entity_varchar
SET value = 'Use generative AI to plan, build and optimise paid search campaigns on Google Ads. Hands-on keyword research, ad copywriting, conversion tracking, bid management and ROI reporting. Up to 70% WSQ funding subsidy.'
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_mdesc;

UPDATE catalog_product_entity_text
SET value = 'Generative AI, Paid Search Marketing, Google Ads, PPC Marketing, WSQ Funding, Keyword Research, Ad Copywriting, Conversion Tracking, Bid Management, ROI Optimization'
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_mkey;

-- ---------------------------------------------------------------------------
-- 5. Alt-text labels + media-gallery label -- the PLAIN title (the cover
--    renderer itself strips the "WSQ - " prefix). The media-gallery FILE PATH is
--    intentionally left alone; only the display LABEL is corrected.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'Generative AI for Paid Search Marketing'
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e
  AND attribute_id IN (@a_ilabel, @a_slabel, @a_tlabel);

UPDATE catalog_product_entity_media_gallery_value v
JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
SET v.label = 'Generative AI for Paid Search Marketing'
WHERE @is_sg = 1 AND @e IS NOT NULL AND g.entity_id = @e;

-- ---------------------------------------------------------------------------
-- 6. Search-term redirects -- re-point every row that targets the old slug so
--    none of the 18 paid-search queries rots into a 404.
-- ---------------------------------------------------------------------------
UPDATE catalogsearch_query
SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_path)
WHERE @is_sg = 1
  AND redirect = CONCAT('https://www.tertiarycourses.com.sg/', @old_path);
