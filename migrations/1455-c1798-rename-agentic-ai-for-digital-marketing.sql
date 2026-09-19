-- 1455: C1798 "Agentic AI for Digital Marketing and Advertising"
--         -> "Agentic AI for Digital Marketing"
--
-- Admin-supplied 2026-09-19. The course is realigned onto its WSQ parent
-- TGS-2025056988 "WSQ - Agentic AI for Digital Marketing"
-- (https://www.tertiarycourses.com.sg/wsq-agentic-ai-for-digital-marketing.html),
-- whose description + course outline are the authoritative source for this change.
--
-- SKU unchanged (C1798). url_key DELIBERATELY unchanged
-- ('agentic-ai-for-digital-marketing-and-advertising') -- admin-confirmed: keep the
-- existing slug and its SEO history rather than rename + 301. The bare parent slug
-- 'agentic-ai-for-digital-marketing' also belongs to the WSQ course's own rewrite
-- space, so renaming here would risk a collision; nothing in this migration touches
-- core_url_rewrite.
--
-- CONTENT REALIGNMENT (admin-confirmed both calls):
--   * description  -- the OLD 6-topic n8n/Facebook-Ads outline is replaced by the
--     PARENT's 3 topics, verbatim and WITHOUT sub-bullets. The parent genuinely
--     carries only 3 bare headings; inventing sub-bullets here would make the
--     unfunded page advertise content the funded one does not.
--     Includes the LSN_DATA JSON comment the course-outline renderer parses --
--     it must stay in sync with the <p> headings below it or the rendered outline
--     and the admin editor disagree.
--   * short_description -- copied verbatim from the parent (5 paragraphs, Claude
--     Cowork / Claude Skills framing). The old text described a different syllabus
--     (n8n pipelines, Nano Banana images, Facebook/Google Ads APIs).
--
-- Surfaces touched, from the mandatory pre-write EAV sweep of BOTH value tables
-- (memory feedback_tgs_course_rename_checklist -- the sweep is what found these,
-- an enumerated list is not trustworthy):
--   name, meta_title, meta_description, meta_keyword,
--   image_label / small_image_label / thumbnail_label, the media-gallery label,
--   description, short_description.
--
-- meta_title: stored BARE -- no "| Tertiary Courses Singapore" suffix. The OLD
-- value baked the brand postfix in AND used a raw 0x96 en-dash byte, which is the
-- 853 bug; MMD_Seotitle composes the <title> at render time and appends the brand
-- itself. Rewriting it here also removes the invalid byte.
-- (memory feedback_meta_description_255_char_cap: meta_title/meta_description are
-- varchar(255) -- both new values are well under.)
--
-- Deliberately UNCHANGED (verified against live data before writing):
--   * sku, price, duration (15), sessions (2) -- course params are not part of a
--     rename. NOTE duration stays 15h vs the parent's 16h: the WSQ version carries
--     assessment time the non-WSQ one drops. Both are still 2 DAYS, which is what
--     the schedule template letter keys on (see the note below).
--   * url_key / url_path -- see above.
--   * whoshouldattend -- 20 generic marketing job roles (Digital Marketing Manager,
--     SEO and SEM Specialist, ...). They remain accurate for the realigned
--     syllabus; only "Advertising Operations Manager" leans old, and the parent
--     lists "Online Advertising Specialist" itself. Not worth churning.
--   * image / small_image / thumbnail PATHS -- filesystem paths, not display text;
--     renaming them 404s the file. Only the LABELS (alt text) change below.
--   * course_image_url -- admin-confirmed: the existing R2 cover is kept. It is
--     rendered from the OLD title, so re-rendering is a separate, deliberate step
--     (memory feedback_cover_renderer_change_needs_rerender_of_r2_pngs).
--   * course_C1798_funding_and_grant -- reads "No funding is available for this
--     course." Correct and unchanged: C1798 is the UNFUNDED twin.
--   * course_C1798_certification / _brochure -- keyed on the unchanged SKU.
--   * catalogsearch_query -- anchored sweep on the full old filename and on the
--     bare course code returned ZERO rows; there is no redirect to retarget.
--
-- NOT IN THIS FILE -- SCHEDULE TEMPLATE. C1798 sits on B15 (gid 258) while its
-- parent is on (SG) WSQ-B11 (gid 244); the counterpart is B11 (gid 132) -- same
-- letter because both courses run 2 days, digits carried over from the parent
-- (memory feedback_schedule_template_letter_is_duration_digits_are_slot).
-- The switch is a CODE path and is performed via the real
-- CoursesaveController::switchScheduleTemplateAction, NEVER in SQL:
-- custom_options_relation is keyed (group_id, option_id, product_id), so a
-- DELETE+INSERT dies on option_id AFTER the DELETE has committed and leaves the
-- course with zero schedule options -- an uncheckoutable page
-- (memory feedback_schedule_template_switch_never_in_sql).
-- C1798 has 0 admin_managed option values, so the snapshot/restore is a no-op.
--
-- Idempotent: every statement is keyed on the NEW value or a scoped UPDATE, so
-- re-running is a no-op.

SET @eid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C1798');

-- ---------------------------------------------------------------- name + labels
SET @a_name := (SELECT attribute_id FROM eav_attribute
                 WHERE attribute_code = 'name' AND entity_type_id = 4);

UPDATE catalog_product_entity_varchar
   SET value = 'Agentic AI for Digital Marketing'
 WHERE entity_id = @eid AND attribute_id = @a_name;

-- Image alt-text at every scope. Paths are untouched (see header).
UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 4
   SET v.value = 'Agentic AI for Digital Marketing'
 WHERE v.entity_id = @eid
   AND a.attribute_code IN ('image_label', 'small_image_label', 'thumbnail_label');

UPDATE catalog_product_entity_media_gallery g
  JOIN catalog_product_entity_media_gallery_value mv ON mv.value_id = g.value_id
   SET mv.label = 'Agentic AI for Digital Marketing'
 WHERE g.entity_id = @eid;

-- ------------------------------------------------------------------------- SEO
-- Stored BARE: MMD_Seotitle appends the brand postfix at render time.
SET @a_mt := (SELECT attribute_id FROM eav_attribute
               WHERE attribute_code = 'meta_title' AND entity_type_id = 4);

UPDATE catalog_product_entity_varchar
   SET value = 'Agentic AI for Digital Marketing'
 WHERE entity_id = @eid AND attribute_id = @a_mt;

SET @a_md := (SELECT attribute_id FROM eav_attribute
               WHERE attribute_code = 'meta_description' AND entity_type_id = 4);

UPDATE catalog_product_entity_varchar
   SET value = 'Learn agentic AI and generative AI for digital marketing. Plan campaigns, create multi-channel content, integrate tools and analyse marketing performance with human oversight.'
 WHERE entity_id = @eid AND attribute_id = @a_md;

-- Old keywords named Facebook Ads / Google Ads / n8n-era pipeline terms that are
-- no longer on the syllabus.
SET @a_mk := (SELECT attribute_id FROM eav_attribute
               WHERE attribute_code = 'meta_keyword' AND entity_type_id = 4);

UPDATE catalog_product_entity_text
   SET value = 'agentic AI digital marketing, generative AI marketing, AI campaign planning, multi-channel marketing content, marketing research automation, AI marketing workflow, campaign ROI analysis, digital marketing AI course Singapore'
 WHERE entity_id = @eid AND attribute_id = @a_mk;

-- --------------------------------------------------- course outline (3 topics)
-- Mirrors TGS-2025056988 verbatim. LSN_DATA must match the <p> headings.
SET @a_desc := (SELECT attribute_id FROM eav_attribute
                 WHERE attribute_code = 'description' AND entity_type_id = 4);

UPDATE catalog_product_entity_text
   SET value = CONCAT(
       '<!-- LSN_DATA: [{"title":"Topic 1: Digital Marketing Research and Campaign Planning with Agentic AI","subsecs":[]},{"title":"Topic 2: Creating Multi-Channel Marketing Content with Generative AI","subsecs":[]},{"title":"Topic 3: Integrating Tools and Analysing Digital Marketing Performance","subsecs":[]}] -->', CHAR(10),
       '<p><strong>Topic 1: Digital Marketing Research and Campaign Planning with Agentic AI</strong></p>', CHAR(10),
       '<p><strong>Topic 2: Creating Multi-Channel Marketing Content with Generative AI</strong></p>', CHAR(10),
       '<p><strong>Topic 3: Integrating Tools and Analysing Digital Marketing Performance</strong></p>')
 WHERE entity_id = @eid AND attribute_id = @a_desc AND store_id = 0;

-- ------------------------------------------------------ About / short_description
-- Copied verbatim from the parent.
SET @a_sdesc := (SELECT attribute_id FROM eav_attribute
                  WHERE attribute_code = 'short_description' AND entity_type_id = 4);

UPDATE catalog_product_entity_text
   SET value = CONCAT(
       '<p>This course equips learners with practical skills to use generative ai and agentic AI to plan, create, manage, and optimise digital marketing activities across multiple channels. Participants will learn how to use agentic ai and generative ai as an intelligent marketing workspace for conducting market research, understanding target audiences, developing campaign strategies, coordinating tasks, and producing consistent, brand-aligned marketing content.</p>', CHAR(10),
       '<p>Learners will explore how tools can connect Claude Cowork with relevant business applications, documents, data sources, content repositories, and marketing platforms. These integrations enable Claude Cowork to retrieve information, work across systems, and support end-to-end digital marketing workflows with appropriate human oversight.</p>', CHAR(10),
       '<p>The course also guides participants in creating custom Claude Skills from real-world marketing processes. Learners will transform repeatable tasks, brand guidelines, templates, and quality standards into reusable skills for campaign planning, content creation, review, reporting, and optimisation. They will apply these skills to produce channel-specific content for websites, blogs, search engines, email campaigns, social media, online advertisements, and other digital touchpoints.</p>', CHAR(10),
       '<p>Participants will also use Claude Cowork to analyse campaign results, compare performance against marketing objectives and KPIs, identify trends, evaluate return on investment, and generate actionable recommendations. By the end of the course, learners will be able to build integrated, AI-assisted digital marketing workflows that improve productivity, content consistency, audience engagement, and data-driven decision-making.</p>', CHAR(10),
       '<p>This course is suitable for beginner and intermediate learners who have a basic understanding of digital marketing and want to apply agentic ai and generative ai skills in practical marketing environments.</p>')
 WHERE entity_id = @eid AND attribute_id = @a_sdesc AND store_id = 0;
