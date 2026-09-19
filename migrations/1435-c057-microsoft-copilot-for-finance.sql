-- 1435: Repurpose C057
--   "Agentic AI for Finance"  ->  "Microsoft Copilot for Finance"
--
-- SKU UNCHANGED (C057). Fee and duration UNCHANGED and deliberately NOT written:
-- live already holds price = 700.0000 and duration = 15 (2 days), which is exactly
-- what was asked for -- writing them again would be pure churn.
--
-- ===========================================================================
-- SCOPE: content + topics adopted from TGS-2026065050
-- ===========================================================================
-- The admin asked for the description and topics of the WSQ/CASL twin
-- TGS-2026065050 "CASL - Generative AI for Finance and Fintech" (entity 1084),
-- keeping C057 at 2 days / $700, with funding pointing at that same twin.
--
-- Topics: all FIVE source topics are copied VERBATIM (admin decision -- the
-- source's 5 x <h3> + bullets are reproduced exactly, only re-tagged with the
-- house `class="course-topic-h3"` already used by the source).
--
-- DELIBERATELY NOT TOUCHED:
--   * price (700) / duration (15) / sessions / participants -- already correct.
--   * prerequisite -- C057's NON-WSQ variant (Google-review promo code, no PWM,
--     no SSG funding apparatus). The source's prerequisite is the full WSQ/PWM
--     funding block and must NEVER be copied onto a C-prefix course
--     (memory project_nonwsq_courseware_no_funding_at_all).
--   * `image` / `small_image` / `thumbnail` FILESYSTEM paths -- renaming them
--     404s the files (memory feedback_rename_probe_first_shrinks_scope). Only
--     the display LABELS are updated below.
--   * tags -- C057 carries none (probed: zero tag_relation rows), and a non-WSQ
--     course gets no funding badges.
--
-- COVER PNG: the R2 object bakes the title, so SQL cannot re-render it
-- (memory feedback_cover_rerender_save_needs_store0_then_clear_overrides).
-- course_image_url is left pointing at the existing object here; the PNG is
-- re-rendered on prod after deploy and the new URL written by that script.
--
-- CATEGORY MOVE (admin decision): OUT of 189 "Agentic AI Series", INTO 357
-- "Microsoft Copilot Series" (which already holds the TGS-2026065050 twin plus
-- C34/C027/C734/C590/C803/C814). Mirrored into catalog_category_product_index in
-- this same file -- the storefront listing reads the INDEX, not
-- catalog_category_product (memory feedback_category_swap_needs_index_mirror).
-- Position is seeded at MAX+1 and the nightly WSQ-first/C-alphabetical sweep
-- settles the final order; no hand-pin (memory
-- feedback_curated_category_orders_dead_nightly_sweep).
--
-- NEW-TITLE COLLISION CHECK (memory
-- feedback_repurpose_target_name_may_already_exist_as_live_twin): probed BOTH
-- catalog_product_entity_varchar.url_key and core_url_rewrite for
-- 'microsoft-copilot-for-finance%' -- ZERO rows. Slug is free.
--
-- URL REWRITES: live holds ONE is_system = 1 bare row (46853) plus 8 is_system = 1
-- category rows, all on the old slug; there are no pre-existing is_system = 0
-- chain rows for this entity, so 3c is a no-op safeguard rather than a fix.
-- The is_system = 1 bare-slug DELETE is mandatory or the 301 INSERT IGNORE
-- no-ops on the shared id_path (memory feedback_repurpose_301_needs_system_row_delete),
-- and refreshProductRewrite MUST be run on prod afterwards or the new slug 404s
-- (memory feedback_rename_301_row_squats_id_path_blocks_system_rewrite).
--
-- SEARCH REDIRECTS: 2 rows ('c0057', 'c57') point at the old absolute URL and
-- would rot into 404s; both are re-pointed
-- (memory feedback_search_redirect_rot_into_live_200_repurposed_slug).
--
-- meta_title: stored PLAIN -- MMD_Seotitle appends the brand suffix at render
-- time (memory project_seo_title_render_time_composer); the OLD value baked in
-- "| Tertiary Courses Singapore", so this migration also cleans that up.
-- meta_description is varchar(255) (memory feedback_meta_description_255_char_cap):
-- the value below is 216 chars.
--
-- SG-only: guarded on @mms_instance (env-derived, set by migrations/apply.php).
-- ASCII-only payload -- no invalid UTF-8 can reach apply.php's utf8 connection
-- (memory feedback_migration_applyphp_utf8_outage).

SET @is_sg := IF(@mms_instance = 'SG', 1, 0);

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C057');

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_ilabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_slabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_tlabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_sdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_who     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='whoshouldattend');

SET @old_slug := 'agentic-ai-for-finance';
SET @new_slug := 'microsoft-copilot-for-finance';
SET @old_path := CONCAT(@old_slug, '.html');
SET @new_path := CONCAT(@new_slug, '.html');

-- ---------------------------------------------------------------------------
-- 1. name
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'Microsoft Copilot for Finance'
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_name;

-- ---------------------------------------------------------------------------
-- 2. url_key + url_path
--    url_path is deleted at EVERY scope (live has store 0 AND store 1 rows) so
--    the URL Rewrites indexer regenerates them.
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
--     silently no-op against a stale row).
DELETE FROM core_url_rewrite
WHERE @is_sg = 1 AND request_path = @new_path AND is_system = 0;

-- 3b. Drop the is_system = 1 row holding the OLD bare slug. Its id_path is
--     product/<entity_id> -- the SAME id_path the 301 needs -- so without this
--     DELETE the INSERT IGNORE below creates nothing and the old URL 404s.
DELETE FROM core_url_rewrite
WHERE @is_sg = 1 AND @e IS NOT NULL
  AND product_id = @e AND request_path = @old_path AND is_system = 1;

-- 3c. Flatten any existing chain so nothing becomes 2-hop (anchored on
--     target_path; no such rows exist today, this is a safeguard).
UPDATE core_url_rewrite
SET target_path = @new_path
WHERE @is_sg = 1 AND is_system = 0 AND target_path = @old_path;

-- 3d. Explicit 301 for the old BARE slug. The indexer auto-301s the 8 category
--     paths from its rewrite history; only the bare slug needs seeding.
INSERT IGNORE INTO core_url_rewrite
    (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT 1, NULL, @e,
       CONCAT('product/', @e),
       @old_path,
       @new_path,
       0, 'RP', 'Repurpose 1435: Agentic AI for Finance -> Microsoft Copilot for Finance'
FROM dual
WHERE @is_sg = 1 AND @e IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
    WHERE x.request_path = @old_path AND x.store_id = 1 AND x.is_system = 0
);

-- ---------------------------------------------------------------------------
-- 4. meta_title / meta_description / meta_keyword
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'Microsoft Copilot for Finance'
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_mtitle;

UPDATE catalog_product_entity_varchar
SET value = 'Apply Microsoft Copilot and Generative AI across finance: Excel Copilot for FP&A, financial process automation with AI agents, risk management and fraud detection. Hands-on 2-day course at Tertiary Courses Singapore.'
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_mdesc;

UPDATE catalog_product_entity_text
SET value = 'Microsoft Copilot for Finance, Excel Copilot, Generative AI for Finance, Agentic AI, FP&A, Financial Process Automation, Fraud Detection, Risk Management, Fintech'
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_mkey;

-- ---------------------------------------------------------------------------
-- 5. Alt-text labels + media-gallery label
--    (FILE PATHS intentionally untouched; only the display LABEL changes.)
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'Microsoft Copilot for Finance'
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e
  AND attribute_id IN (@a_ilabel, @a_slabel, @a_tlabel);

UPDATE catalog_product_entity_media_gallery_value v
JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
SET v.label = 'Microsoft Copilot for Finance'
WHERE @is_sg = 1 AND @e IS NOT NULL AND g.entity_id = @e;

-- ---------------------------------------------------------------------------
-- 6. short_description -- adopted from TGS-2026065050, re-framed for the
--    2-day non-WSQ course (no CASL/WSQ branding, no funding claims).
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = '<p><strong>Microsoft Copilot for Finance</strong> steps you into the future of finance with comprehensive coverage of Microsoft Copilot, Generative AI (GenAI) and Agentic AI tailored specifically for financial professionals. The course begins by establishing a strong foundation in AI, Machine Learning and Generative AI, emphasizing their transformative role in the finance and fintech sectors. Participants will learn how to design and deploy both single and multi-agent systems to automate and enhance financial operations, planning and decision-making.</p><p>In the next module, learners will explore the practical power of Excel Copilot for Finance, mastering how to summarize, process and analyze financial data through AI-driven tools that streamline Financial Planning and Analysis (FP&amp;A) tasks. Through hands-on exercises, participants will experience how AI can boost productivity and insight generation in financial modeling.</p><p>The course then transitions to the application of Agentic AI for financial process automation, examining real-world case studies and guiding participants to build and deploy autonomous agents that handle complex financial workflows and reporting. Learners will gain firsthand experience in implementing multi-agent automation systems for finance operations.</p><p>A dedicated section on AI Risk Management and Fraud Detection enables participants to understand how AI models can predict, detect and mitigate financial risks. Learners will also build a fraud detection system using Generative AI, applying advanced AI tools to real-world data.</p><p>Finally, the course concludes by exploring future trends and innovations in Generative AI for Finance, helping participants anticipate emerging technologies and adopt AI-driven innovations within their organizations. By the end of the program, learners will be equipped with both strategic and technical expertise to lead the AI transformation in financial services.</p>'
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_sdesc;

-- ---------------------------------------------------------------------------
-- 7. description (course outline) -- all FIVE source topics, verbatim.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = '<h3 class="course-topic-h3">Topic 1: Introduction to Generative AI and Its Foundations in Finance</h3>
<ul>
<li>Basics of AI and Machine Learning</li>
<li>Introduction to Generative AI and Agentic AI</li>
<li>Use Cases of Gen AI and Agentic AI in Finance</li>
<li>Build Single and Multi-Agent for Financial Services</li>
</ul>
<h3 class="course-topic-h3">Topic 2: Excel Copilot For Finance Planning and Analysis</h3>
<ul>
<li>Excel Copilot for Finance</li>
<li>Summarize Financial Data</li>
<li>Process Financial Data</li>
<li>Financial Planning &amp; Analysis (FP&amp;A)</li>
</ul>
<h3 class="course-topic-h3">Topic 3: Practical Applications of Agentic AI to Automate Financial Processes</h3>
<ul>
<li>Case Studies of Agentic AI for Financial Processes</li>
<li>Agentic AI Automation for Financial Processes</li>
<li>Multi Agent Automation for Financial Processes</li>
</ul>
<h3 class="course-topic-h3">Topic 4: AI Risk Management and Fraud Detection</h3>
<ul>
<li>AI for Risk Management</li>
<li>Build a Fraud Detection System using GenAI</li>
</ul>
<h3 class="course-topic-h3">Topic 5: Future Trends and Innovations in Generative AI for Finance</h3>
<ul>
<li>Future Trends in Generative AI for Finances</li>
<li>Adoption of Generative AI Innovations in Organizations</li>
</ul>'
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_desc;

-- ---------------------------------------------------------------------------
-- 8. whoshouldattend -- adopted from the source twin (the finance/fintech AI
--    role list matches the new subject).
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = '<ul><li>AI Financial Analyst</li><li>Generative AI Fintech Developer</li><li>AI-Driven Risk Management Specialist</li><li>GAI-Enhanced Fraud Detection Analyst</li><li>Financial Data Scientist using AI</li><li>AI-Integrated Wealth Management Advisor</li><li>AI-Powered Regulatory Compliance Officer</li><li>Fintech Innovation Strategist with AI</li><li>AI-Driven Investment Portfolio Manager</li><li>GAI Solutions Architect for Finance</li><li>AI-Enhanced Credit Analyst</li><li>Financial Technology Product Manager with AI</li><li>AI-Driven Financial Planning Consultant</li><li>GAI-Based Financial Market Researcher</li><li>AI-Enhanced Banking Operations Manager</li><li>Fintech Customer Experience Designer with AI</li><li>AI-Driven Financial Reporting Specialist</li><li>GAI Implementation Consultant in Finance</li><li>AI-Enhanced Insurance Underwriter</li><li>GAI-Powered Blockchain Specialist</li></ul>'
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_who;

-- ---------------------------------------------------------------------------
-- 9. Funding block -- point at TGS-2026065050 (the requested funding reference).
--    C-prefix courses carry no funding of their own; the block redirects to the
--    funded twin (memory project_nonwsq_courseware_no_funding_at_all).
--    Matched on identifier; block_id keys drift between local and prod
--    (memory feedback_block_id_keyed_migrations_drift_between_local_and_prod).
-- ---------------------------------------------------------------------------
UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>
<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/casl-generative-ai-for-finance-and-fintech.html" title="CASL - Generative AI for Finance and Fintech">CASL - Generative AI for Finance and Fintech</a></span></p>'
WHERE @is_sg = 1 AND identifier = 'course_C057_funding_and_grant';

-- ---------------------------------------------------------------------------
-- 10. Category move: OUT of 189 (Agentic AI Series), INTO 357 (Microsoft
--     Copilot Series). Both catalog_category_product AND the index it feeds.
-- ---------------------------------------------------------------------------
DELETE FROM catalog_category_product
WHERE @is_sg = 1 AND @e IS NOT NULL AND product_id = @e AND category_id = 189;

SET @pos357 := (SELECT COALESCE(MAX(position), 0) + 1
                FROM (SELECT position FROM catalog_category_product WHERE category_id = 357) t);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT 357, @e, @pos357
FROM dual
WHERE @is_sg = 1 AND @e IS NOT NULL;

-- 10a. Mirror the DROP into the index -- guarded so a category the product
--      legitimately still belongs to is never removed.
DELETE i FROM catalog_category_product_index i
WHERE @is_sg = 1 AND @e IS NOT NULL
  AND i.product_id = @e AND i.category_id = 189
  AND NOT EXISTS (
    SELECT 1 FROM (SELECT * FROM catalog_category_product) cp
    WHERE cp.product_id = @e AND cp.category_id = 189
);

-- 10b. Mirror the ADD into the index, copying visibility from an existing index
--      row for the same product+store.
INSERT IGNORE INTO catalog_category_product_index
    (category_id, product_id, position, is_parent, store_id, visibility)
SELECT 357, @e, @pos357, 1, s.store_id,
       COALESCE((SELECT x.visibility FROM (SELECT * FROM catalog_category_product_index) x
                 WHERE x.product_id = @e AND x.store_id = s.store_id LIMIT 1), 4)
FROM core_store s
WHERE @is_sg = 1 AND @e IS NOT NULL AND s.store_id > 0;

-- ---------------------------------------------------------------------------
-- 11. Search-term redirects -- re-point the 2 rows ('c0057', 'c57') that target
--     the old slug so neither rots into a 404.
-- ---------------------------------------------------------------------------
UPDATE catalogsearch_query
SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_path)
WHERE @is_sg = 1
  AND redirect = CONCAT('https://www.tertiarycourses.com.sg/', @old_path);
