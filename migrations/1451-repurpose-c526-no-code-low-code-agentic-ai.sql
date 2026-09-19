-- 1451: Repurpose course C526 from "Agentic AI for Facebook Marketing" to
--       "No Code and Low Code Agentic AI Applications".
--
-- C526 becomes the non-WSQ twin of TGS-2026062147
-- ("WSQ - No Code and Low Code Agentic AI Applications", entity 1869).
-- Content (overview + topics) and the class calendar follow that WSQ parent.
--
-- Six coupled changes, all on C526 only:
--
--   1. name / overview / topics / metas  -> mirror the WSQ parent
--   2. Course Fee        $700.00         -> $1400.00
--   3. Class info        2 sess / 15 hrs -> 4 sess / 32 hrs
--   4. Schedule template B07 Tues-Wed/Sat/Sun 2nd wk -> D01 Mon-Thurs/Sat-Sun 1st wk
--   5. Course Date rows  the 19 B07 two-day pairs    -> the WSQ parent's 20 D01 four-day dates
--   6. url_key + cover   -> new slug + freshly rendered PNG, old paths 301'd
--
-- WHY THE OVERVIEW IS COPIED BUT NOT THE FUNDING SENTENCE
-- The WSQ parent's own overview carries no funding claim (its funding copy
-- lives in the separate WSQ Funding card), so the four paragraphs transfer
-- verbatim. The parent's meta_description DOES end in "Enjoy up to 70% WSQ
-- funding subsidy" -- that clause is STRIPPED here. C526 is a non-WSQ
-- C-prefix course carrying zero funding, so a subsidy claim must never
-- appear on it.
--
-- WHY THE TOPICS ARE THREE BARE HEADINGS
-- The WSQ parent's `description` is exactly three <h3 class="course-topic-h3">
-- headings with no sub-bullets. Topics follow the parent 1:1, so C526 gets the
-- same three headings -- deliberately not embellished with invented bullets.
--
-- WHY THE TEMPLATE CODE, NOT THE WEEKDAY NAMES
-- The WSQ catalogue prefixes templates "(SG) WSQ-"; the non-WSQ catalogue uses
-- the bare code. The counterpart is the one sharing the CODE:
--
--     (SG) WSQ-D01 Mon-Thurs/Sat-Sun 1st wk  ->  D01 Mon-Thurs/Sat-Sun 1st wk
--
-- Both run 4-day blocks, so the same letter+digits applies. C526 sat on B07
-- (a 2-day template) -- correct for the Facebook course it used to be, wrong
-- for a 4-day course.
--
-- WHY THE DATE ROWS ARE COPIED EXPLICITLY
-- custom_options_relation.group_id is only a LABEL saying which calendar
-- pattern a course follows; each course owns its own
-- catalog_product_option_type_value rows. Repointing group_id alone would
-- relabel C526 as D01 while leaving the 2-day B07 dates in place. The admin's
-- "Switch Template" button rewrites both; this migration does the same in SQL.
-- reg_course is the column that actually drives the schedule (the title is
-- display text), so it is copied too.
--
-- Dates are copied VERBATIM from the WSQ parent (explicitly requested), so
-- C526 runs on the same calendar slots as TGS-2026062147.
--
-- CLASS TIME stays 9:30am - 5:30pm and is therefore NOT touched. The WSQ
-- parent runs 9:30am - 6:30pm because of its assessment hour; non-WSQ has no
-- assessment, so the house 9:30-5:30 convention holds. Duration is recorded
-- as 32 hrs to match the parent's contact hours.
--
-- Orders are unaffected: Magento snapshots chosen options as serialized text
-- on sales_flat_order_item, so rewriting option values never rewrites order
-- history.
--
-- Idempotent. Store scope 0. IDs resolved by SKU, never hardcoded. No content
-- line ends in a semicolon.

-- ---------------------------------------------------------------------------
-- Resolve ids by SKU (never hardcode entity_ids -- they differ per instance).
-- ---------------------------------------------------------------------------
SET @e     = (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C526');
SET @wsq_id = (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2026062147');

SET @a_name  = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_img   = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_price = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='price');
SET @a_sess  = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='sessions');
SET @a_dur   = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='duration');

-- ---------------------------------------------------------------- name
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'No Code and Low Code Agentic AI Applications' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------- overview
-- Verbatim from the WSQ parent (its overview carries no funding claim).
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>This course equips learners with practical skills to develop agentic AI applications using n8n through no-code and low-code development approaches. Participants will learn to design AI agents, connect business applications and data sources, automate multi-step processes, and create workflows that can analyse information, make decisions and perform actions with minimal coding.</p>
<p>Through hands-on, real-life applications, learners will use n8n to build solutions for customer enquiries, lead management, email processing, document handling, internal approvals, reporting and knowledge retrieval. They will explore workflow triggers, webhooks, conditional logic, human-in-the-loop approvals, error handling and data transformation to develop reliable automations for everyday business operations.</p>
<p>The course also covers the development of agentic RAG applications that retrieve relevant information from organisational knowledge sources and generate context-aware responses. Participants will learn to test, troubleshoot and improve their workflows while considering data security, accuracy, governance and appropriate human oversight.</p>
<p>Designed for beginner to intermediate learners, this course enables professionals from technical and non-technical backgrounds to rapidly prototype and deploy useful agentic AI solutions. By the end of the course, participants will be able to build an end-to-end n8n application that addresses a real business need and improves operational productivity.</p>'
FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------- topics
-- 1:1 with the WSQ parent: three headings, no sub-bullets.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1: Develop No Code Agentic AI Workflows</h3>
<h3 class="course-topic-h3">Topic 2: Develop Low-Code Agentic AI Workflows</h3>
<h3 class="course-topic-h3">Topic 3: Real Life Applications of Agentic AI Workflows</h3>'
FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------- metas
-- meta_title stored BARE (MMD_Seotitle appends the brand at render time).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'No Code and Low Code Agentic AI Applications with n8n' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_description is varchar(255) -- keep under the cap. The WSQ parent's
-- trailing "Enjoy up to 70% WSQ funding subsidy." is STRIPPED: non-WSQ.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Build no-code and low-code Agentic AI applications and agentic RAG workflows with n8n to automate real business processes in this hands-on 4-day course in Singapore.'
FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'no code agentic AI course Singapore, low code AI agent course, n8n course Singapore, n8n AI agent workflow, agentic RAG n8n, business process automation AI, AI workflow automation training'
FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------- url_key
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'no-code-and-low-code-agentic-ai-applications' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------- cover
-- Freshly rendered for the NEW title and uploaded to R2 (non-WSQ: no funding
-- chips). The renderer bakes the title into the PNG, so the old cover would
-- keep showing "Agentic AI for Facebook Marketing" until repointed.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C526-20260919-133752.png'
FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Clear per-store overrides so store 1 cannot shadow the store-0 values above.
DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND @e IS NOT NULL
  AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url, @a_img);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND @e IS NOT NULL
  AND attribute_id IN (@a_short, @a_desc, @a_mk);

-- ---------------------------------------------------------------- fee
-- $1400.00 GST-exclusive; the theme derives the incl. figure.
UPDATE catalog_product_entity_decimal SET value = 1400.0000
WHERE entity_id = @e AND attribute_id = @a_price AND store_id = 0 AND @e IS NOT NULL;

-- ---------------------------------------------------------------- class info
-- 4 sessions / 32 hrs (matches the WSQ parent's contact hours).
-- Stored as bare numbers; the product template appends " days" / " hrs".
UPDATE catalog_product_entity_varchar SET value = '4'
WHERE entity_id = @e AND attribute_id = @a_sess AND store_id = 0
  AND @e IS NOT NULL AND @a_sess IS NOT NULL;

UPDATE catalog_product_entity_varchar SET value = '32'
WHERE entity_id = @e AND attribute_id = @a_dur AND store_id = 0
  AND @e IS NOT NULL AND @a_dur IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Schedule: B07 (2-day) -> D01 (4-day), and copy the WSQ parent's date rows.
-- ---------------------------------------------------------------------------
SET @grp_d01 = (SELECT group_id FROM custom_options_group
                 WHERE title NOT LIKE '(SG)%' AND title LIKE 'D01 %' LIMIT 1);

SET @opt_nonwsq = (SELECT o.option_id FROM catalog_product_option o
                     JOIN catalog_product_option_title t
                       ON t.option_id = o.option_id AND t.store_id = 0
                    WHERE o.product_id = @e AND t.title LIKE '%Course Date%' LIMIT 1);
SET @opt_wsq    = (SELECT o.option_id FROM catalog_product_option o
                     JOIN catalog_product_option_title t
                       ON t.option_id = o.option_id AND t.store_id = 0
                    WHERE o.product_id = @wsq_id AND t.title LIKE '%Course Date%' LIMIT 1);

-- Guard: if any lookup missed (course absent on this instance, or no D01
-- template), @ok is 0 and every write below becomes a no-op rather than
-- writing NULLs or nuking an unrelated product's options.
SET @ok = IF(@e IS NOT NULL AND @wsq_id IS NOT NULL AND @grp_d01 IS NOT NULL
             AND @opt_nonwsq IS NOT NULL AND @opt_wsq IS NOT NULL, 1, 0);

-- 1. Schedule template -> D01. Repoints every option row this course has.
SET @sql = IF(@ok,
  'UPDATE custom_options_relation SET group_id = @grp_d01 WHERE product_id = @e',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 2. Course Date rows -> the WSQ parent's D01 dates.
--    Drop the old child rows (price + title) before the values they hang off.
SET @sql = IF(@ok,
  'DELETE p FROM catalog_product_option_type_price p
     JOIN catalog_product_option_type_value v ON v.option_type_id = p.option_type_id
    WHERE v.option_id = @opt_nonwsq', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@ok,
  'DELETE t FROM catalog_product_option_type_title t
     JOIN catalog_product_option_type_value v ON v.option_type_id = t.option_type_id
    WHERE v.option_id = @opt_nonwsq', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@ok,
  'DELETE FROM catalog_product_option_type_value WHERE option_id = @opt_nonwsq', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Copy the WSQ parent's rows. sort_order is carried across so it can key the
-- title/price joins below (option_type_id is auto-assigned on insert).
SET @sql = IF(@ok,
  'INSERT INTO catalog_product_option_type_value
     (option_id, sku, sort_order, reg_course, customoptions_qty, `default`,
      in_group_id, dependent_ids, weight, admin_managed)
   SELECT @opt_nonwsq, v.sku, v.sort_order, v.reg_course, v.customoptions_qty,
          v.`default`, v.in_group_id, v.dependent_ids, v.weight, v.admin_managed
     FROM catalog_product_option_type_value v
    WHERE v.option_id = @opt_wsq
    ORDER BY v.sort_order', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@ok,
  'INSERT INTO catalog_product_option_type_title (option_type_id, store_id, title)
   SELECT nv.option_type_id, 0, ot.title
     FROM catalog_product_option_type_value nv
     JOIN catalog_product_option_type_value sv
       ON sv.option_id = @opt_wsq AND sv.sort_order = nv.sort_order
     JOIN catalog_product_option_type_title ot
       ON ot.option_type_id = sv.option_type_id AND ot.store_id = 0
    WHERE nv.option_id = @opt_nonwsq', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Date rows carry no surcharge; the course fee is the product price.
SET @sql = IF(@ok,
  'INSERT INTO catalog_product_option_type_price (option_type_id, store_id, price, price_type)
   SELECT nv.option_type_id, 0, 0.0000, ''fixed''
     FROM catalog_product_option_type_value nv
    WHERE nv.option_id = @opt_nonwsq', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ---------------------------------------------------------------------------
-- 301s. DELETE the is_system=1 rows squatting on the OLD slug FIRST: they share
-- the id_path the 301 needs, so INSERT IGNORE would silently no-op and the new
-- slug would get a -526 suffix.
-- ---------------------------------------------------------------------------
DELETE FROM core_url_rewrite
WHERE product_id=@e AND is_system=1 AND @e IS NOT NULL
  AND request_path LIKE '%agentic-ai-for-facebook-marketing.html';

-- Drop any non-system squatter already holding the NEW path.
DELETE FROM core_url_rewrite
WHERE request_path='no-code-and-low-code-agentic-ai-applications.html' AND is_system=0;

-- 301 the bare old path at the new slug.
INSERT IGNORE INTO core_url_rewrite
  (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options)
SELECT 1, NULL, @e, CONCAT('product/', @e), 'agentic-ai-for-facebook-marketing.html',
       'no-code-and-low-code-agentic-ai-applications.html', 0, 'RP'
FROM dual WHERE @e IS NOT NULL;

-- Flatten existing chains (the many legacy Facebook-era aliases pointed at the
-- old slug, bare and category-prefixed) so nothing 301-hops twice.
UPDATE core_url_rewrite
SET target_path='no-code-and-low-code-agentic-ai-applications.html'
WHERE is_system=0 AND options='RP'
  AND product_id=@e AND @e IS NOT NULL
  AND target_path LIKE '%agentic-ai-for-facebook-marketing.html'
  AND request_path <> 'no-code-and-low-code-agentic-ai-applications.html';
