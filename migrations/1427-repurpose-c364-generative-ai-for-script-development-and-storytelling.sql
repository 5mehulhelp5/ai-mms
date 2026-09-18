-- 1427: Repurpose C364
--   "Claude Certified Architect - Professional Certification"
--     -> "Generative AI for Script Development and Storytelling"
--
-- SKU UNCHANGED (C364). This is a full SUBJECT REPURPOSE: the entity stops being
-- a Claude certification-exam-prep course and becomes the non-WSQ counterpart of
-- the WSQ course TGS-2025056983
-- (https://www.tertiarycourses.com.sg/wsq-generative-ai-for-script-development-and-storytelling.html).
--
-- Overview, the 3 topics and the meta keywords are CLONED from that WSQ parent so
-- the funded and unfunded editions describe the same course. The WSQ parent stores
-- its topics in the LSN_DATA-comment form; this non-WSQ course uses the
-- h3.course-topic-h3 form that the other C-prefix courses use (memory
-- ai-vibe-coding-series topic format), same three titles, no sub-bullets.
--
-- URL SLUG CHANGES (the old one names a retired Claude certification):
--   claude-certified-architect-professional-certification
--     -> generative-ai-for-script-development-and-storytelling
-- Verified free on live: ZERO rows in catalog_product_entity_varchar.url_key and
-- ZERO in core_url_rewrite for 'generative-ai-for-script-development%'.
--
-- !! A url_key change is only HALF the job in SQL. After this deploys,
--    refreshProductRewrite(364) + a cache flush MUST run on prod or the NEW slug
--    404s -- section 3d's 301 row squats id_path 'product/364', so the indexer
--    concludes the canonical rewrite already exists and never mints the
--    is_system = 1 row (memory
--    feedback_rename_301_row_squats_id_path_blocks_system_rewrite). Proof of a
--    good deploy is a 200 on the BARE new slug, not a 301 on the old one.
--
-- CATEGORIES: removed from Claude AI Series (281) and Claude Certification Exam
-- Prep (370) -- the course is no longer Claude-specific; added to Generative AI
-- Series (433). Stays in All Courses (3) and AI Courses (252). Every
-- catalog_category_product write is mirrored into catalog_category_product_index
-- (is_parent = 1, matching what the real indexer writes) or the storefront
-- listings do not move at all (memory feedback_category_swap_needs_index_mirror).
--
-- ORDERING in 433: the category is already funded-first (TGS- 1..16) then
-- C-prefix (17..) sorted alphabetically by course name, which is the order the
-- listing renders in. "Generative AI for Script Development and Storytelling"
-- sorts after C013 "Generative AI for Project Management" and before C11
-- "Generative AI for SEO", so C364 takes position 34 and everything from the old
-- 34 onward shifts down by one. Only this category is renumbered.
--
-- NB: compute this slot against CURRENT names. The pre-existing positions were
-- assigned from names that several repurposes have since changed, so reading the
-- order off a stale catalog_product_flat puts the course in the wrong slot
-- (memory feedback_flat_catalog_reindex).
--
-- COVER: re-rendered from the new title and uploaded to R2 before writing this
-- file (the PNG bakes the title, so it cannot be regenerated in SQL) --
-- course-covers/C364-20260918-154848.png, verified HTTP 200.
-- The Magento `image`/`small_image`/`thumbnail` still pointed at
-- /u/n/unreal-essential-training.jpg from this entity's pre-Claude life, and the
-- single gallery row was still labelled "Unreal Essential Training"; both the
-- labels and the gallery label are corrected to the new title. The FILESYSTEM
-- paths are left alone -- renaming them 404s the image (memory
-- feedback_rename_probe_first_shrinks_scope).
--
-- FUNDING BLOCK: repointed from "WSQ - Agentic AI Applications with Claude Code"
-- (left over from the Claude course) to the WSQ parent above, per the request.
-- Content-only UPDATE -- never ->save() a cms/block, it wipes cms_block_store and
-- 404s the block (memory feedback_cms_model_save_wipes_store_mapping).
--
-- SEARCH REDIRECTS: the two rows that resolve 'c364' / 'c0364' to the old slug are
-- re-pointed, or they rot into 404s the moment url_key changes.
--
-- price ($ unchanged) and duration (15h) are deliberately NOT touched.
--
-- SG-only: guarded on @mms_instance (env-derived, set by apply.php) so the same
-- chain is a no-op on MY/GH, which run it against their own DBs.
-- Idempotent: every write is a guarded UPDATE / DELETE+INSERT / INSERT IGNORE.
-- ASCII-only payload -- no invalid UTF-8 can reach apply.php's utf8 connection
-- (memory feedback_migration_applyphp_utf8_outage).

SET @is_sg := IF(@mms_instance = 'SG', 1, 0);

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C364');

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_sdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_cover   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_ilabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_slabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_tlabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');
SET @a_vis     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='visibility');

SET @old_slug := 'claude-certified-architect-professional-certification';
SET @new_slug := 'generative-ai-for-script-development-and-storytelling';
SET @old_path := CONCAT(@old_slug, '.html');
SET @new_path := CONCAT(@new_slug, '.html');
SET @title    := 'Generative AI for Script Development and Storytelling';

-- ---------------------------------------------------------------------------
-- 1. name (no "WSQ - " prefix: this is the non-WSQ C-prefix edition)
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = @title
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_name;

-- ---------------------------------------------------------------------------
-- 2. url_key + url_path
--    url_path is deleted at EVERY scope so the URL Rewrites indexer regenerates.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = @new_slug
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_urlkey;

DELETE FROM catalog_product_entity_varchar
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_urlpath;

-- ---------------------------------------------------------------------------
-- 3. URL rewrites
-- ---------------------------------------------------------------------------
-- 3a. Drop any is_system = 0 squatter on the NEW path (INSERT IGNORE would
--     otherwise silently no-op against a stale row).
DELETE FROM core_url_rewrite
WHERE @is_sg = 1 AND request_path = @new_path AND is_system = 0;

-- 3b. Drop the is_system = 1 row holding the OLD bare slug. Its id_path is
--     product/364 -- the SAME id_path the 301 needs -- so without this DELETE the
--     INSERT IGNORE below creates nothing and the old URL 404s.
DELETE FROM core_url_rewrite
WHERE @is_sg = 1 AND @e IS NOT NULL
  AND product_id = @e AND request_path = @old_path AND is_system = 1;

-- 3c. Flatten the EXISTING chain. This entity has been renamed twice before
--     (Maya -> Unreal -> Claude Architect): 6 is_system = 0 rows already 301 into
--     the current paths. Left alone they become 2-hop chains.
UPDATE core_url_rewrite
SET target_path = @new_path
WHERE @is_sg = 1 AND is_system = 0 AND target_path = @old_path;

UPDATE core_url_rewrite
SET target_path = CONCAT('adult-training-courses/', @new_path)
WHERE @is_sg = 1 AND is_system = 0
  AND target_path = CONCAT('adult-training-courses/', @old_path);

-- 3d. Explicit 301 for the old BARE slug. The indexer auto-301s the category
--     paths from its rewrite history; only the bare slug needs seeding.
INSERT IGNORE INTO core_url_rewrite
    (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT 1, NULL, @e,
       CONCAT('product/', @e),
       @old_path,
       @new_path,
       0, 'RP', 'Repurpose 1427: Claude Certified Architect -> Generative AI for Script Development and Storytelling'
FROM dual
WHERE @is_sg = 1 AND @e IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
    WHERE x.request_path = @old_path AND x.store_id = 1 AND x.is_system = 0
);

-- ---------------------------------------------------------------------------
-- 4. meta_title / meta_description / meta_keyword
--    meta_title is stored BARE -- MMD_Seotitle appends the brand suffix at render
--    time (memory project_seo_title_render_time_composer,
--    feedback_meta_description_255_char_cap: meta_description is varchar(255);
--    the value below is 232 chars).
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = @title
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_mtitle;

UPDATE catalog_product_entity_varchar
SET value = 'Use Generative AI for script development and storytelling. Hands-on training in narrative structure, character and dialogue, AI-assisted storyboarding, video creation, script refinement and responsible AI use in Singapore.'
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_mdesc;

UPDATE catalog_product_entity_text
SET value = 'generative AI script development, AI storytelling course, AI scriptwriting training, AI storyboarding, video script refinement with AI, AI ethics and copyright, AI content creation, narrative structure with AI, Singapore'
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_mkey;

-- ---------------------------------------------------------------------------
-- 5. Overview + topics -- cloned from the WSQ parent TGS-2025056983.
--    Topics use the h3.course-topic-h3 form (the non-WSQ house format), same 3
--    titles as the WSQ edition, no sub-bullets.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = '<p>This course equips participants with practical skills to use Generative AI for script development, storytelling, storyboarding, and multimedia content creation. Learners will explore how AI can support the creative process from initial concept development to the production of complete, engaging narratives for media, advertising, education, entertainment, and digital platforms.</p><p>Participants will apply storytelling principles to develop themes, plots, narrative structures, characters, dialogue, settings, and fictional worlds. They will use Generative AI to explore creative directions, overcome idea blocks, develop alternative storylines, and adapt scripts for different audiences, formats, tones, and communication objectives.</p><p>The course also covers script evaluation and refinement. Learners will review AI-generated content for clarity, originality, pacing, emotional impact, character consistency, and narrative coherence. They will translate scripts into visual storyboards by planning scenes, camera angles, shot sequences, transitions, dialogue, voiceovers, and supporting visual elements.</p><p>Through practical projects, participants will integrate scripts, images, audio, voiceovers, and AI-generated video elements into cohesive storytelling presentations. Emphasis is placed on maintaining human creative direction and addressing responsible content creation issues such as factual accuracy, bias, cultural sensitivity, plagiarism, copyright, and appropriate disclosure of AI-generated materials.</p><p>By the end of the course, learners will be able to use Generative AI to develop, refine, visualise, and present compelling stories while improving creative productivity and maintaining professional and ethical standards. This course is suitable for beginner and intermediate learners with an interest in writing, content creation, or digital media.</p>'
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_sdesc;

UPDATE catalog_product_entity_text
SET value = '<h3 class="course-topic-h3">Topic 1: Script Development and Creative Storytelling with Generative AI</h3>
<h3 class="course-topic-h3">Topic 2: AI-Assisted Storyboarding, Visual Design and Video Creation</h3>
<h3 class="course-topic-h3">Topic 3: Script Refinement, Responsible AI and Copyright Risk Management</h3>'
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_desc;

-- ---------------------------------------------------------------------------
-- 6. Cover (R2) + alt-text labels + media-gallery label.
--    The gallery row was still labelled "Unreal Essential Training" from this
--    entity's pre-Claude life. File paths are NOT renamed (that 404s them).
-- ---------------------------------------------------------------------------
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @e,
       'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C364-20260918-154848.png'
FROM dual
WHERE @is_sg = 1 AND @e IS NOT NULL AND @a_cover IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_product_entity_varchar
SET value = @title
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e
  AND attribute_id IN (@a_ilabel, @a_slabel, @a_tlabel);

UPDATE catalog_product_entity_media_gallery_value v
JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
SET v.label = @title
WHERE @is_sg = 1 AND @e IS NOT NULL AND g.entity_id = @e;

-- ---------------------------------------------------------------------------
-- 7. Funding block -> the WSQ parent.
--    Content-only UPDATE (never ->save() a cms/block: it wipes cms_block_store).
-- ---------------------------------------------------------------------------
UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>
<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-generative-ai-for-script-development-and-storytelling.html" title="WSQ - Generative AI for Script Development and Storytelling">WSQ - Generative AI for Script Development and Storytelling</a></span></p>'
WHERE @is_sg = 1 AND identifier = 'course_C364_funding_and_grant';

-- ---------------------------------------------------------------------------
-- 8. Categories: -281 (Claude AI Series), -370 (Claude Certification Exam Prep),
--    +433 (Generative AI Series). Each write is mirrored into
--    catalog_category_product_index or the storefront listings never change.
-- ---------------------------------------------------------------------------
DELETE FROM catalog_category_product
WHERE @is_sg = 1 AND @e IS NOT NULL AND product_id = @e AND category_id IN (281, 370);

DELETE FROM catalog_category_product_index
WHERE @is_sg = 1 AND @e IS NOT NULL AND product_id = @e AND category_id IN (281, 370);

-- Shift the alphabetical C-prefix tail down by one so C364 can take 34, between
-- "Generative AI for Project Management" and "Generative AI for SEO".
-- Guarded on C364 not already being placed, so a re-run is a no-op.
SET @needs_slot := (
  SELECT IF(EXISTS(SELECT 1 FROM (SELECT * FROM catalog_category_product) c
                   WHERE c.category_id = 433 AND c.product_id = @e), 0, 1)
);

UPDATE catalog_category_product
SET position = position + 1
WHERE @is_sg = 1 AND @needs_slot = 1 AND category_id = 433 AND position >= 34;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT 433, @e, 34 FROM dual
WHERE @is_sg = 1 AND @e IS NOT NULL;

-- Mirror the ADD into the index. is_parent = 1 and visibility read from
-- catalog_product_entity_int at store 0 is exactly what the real indexer writes,
-- so the next full reindex does not rewrite these rows.
INSERT IGNORE INTO catalog_category_product_index
    (category_id, product_id, position, is_parent, store_id, visibility)
SELECT cp.category_id, cp.product_id, cp.position, 1, s.store_id,
       COALESCE((SELECT i.value FROM catalog_product_entity_int i
                  WHERE i.entity_id = @e AND i.attribute_id = @a_vis AND i.store_id = 0
                  LIMIT 1), 4)
FROM catalog_category_product cp
CROSS JOIN core_store s
WHERE @is_sg = 1 AND @e IS NOT NULL
  AND cp.product_id = @e AND cp.category_id = 433 AND s.store_id > 0;

-- Keep the index positions in step with the shift above.
UPDATE catalog_category_product_index i
JOIN catalog_category_product cp
  ON cp.category_id = i.category_id AND cp.product_id = i.product_id
SET i.position = cp.position
WHERE @is_sg = 1 AND i.category_id = 433;

-- ---------------------------------------------------------------------------
-- 9. Search-term redirects -- 'c364' / 'c0364' resolve to the old slug and would
--    rot into 404s.
-- ---------------------------------------------------------------------------
UPDATE catalogsearch_query
SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_path)
WHERE @is_sg = 1
  AND redirect = CONCAT('https://www.tertiarycourses.com.sg/', @old_path);
