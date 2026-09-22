-- C22: repurpose
--   "Effective Communication Training"  (1 day,  $350)
--   -> "Communication Masterclass"      (2 days, $700)
--
-- Content (short_description, topics/description, meta) is copied from the WSQ
-- parent TGS-2023037467 "Mastering the Art of Communication to Enhance Team
-- Collaboration and Customer Satisfaction", with the WSQ-only layer stripped
-- (no funding tables, no SSG/SkillsFuture wording, no assessment) per the
-- non-WSQ convention.
--
-- whoshouldattend already matches the parent verbatim -- deliberately untouched.
--
-- The `prerequisite` blob keeps its Promotion Code / Minimum Entry Requirement /
-- Software-Hardware sections but DROPS everything from "SWDA (formerly SSG)
-- Training Grant" onward: that section quoted a $15 grant and a "$309.82 net
-- fee" derived from the old $350 price, and no other $700 non-WSQ course (C19,
-- C141, C161, ...) carries a SWDA/SkillsFuture/UTAP section at all.
--
-- NOT in this file: the schedule template switch A18 (gid 187) -> B05 (gid 271,
-- the non-WSQ counterpart of the parent's "(SG) WSQ-B05", gid 273).
-- custom_options_relation is keyed per OPTION, so a SQL switch leaves the course
-- with no schedule options at all. That switch is a CODE path -- run it via the
-- admin "Switch Template" button / CoursesaveController::switchScheduleTemplateAction.
-- (Verified: 0 admin_managed option values on C22, so nothing to carry over.)
--
-- ALSO NOT in this file: the R2 cover PNG re-render. The course TITLE is baked
-- into the image, so the existing C22-20260717-162834.png keeps showing the old
-- name until the cover is regenerated.
--
-- SG-only course (C-prefix). Guarded on the SG store so this is a no-op on the
-- MY/GH partner servers, which run the same migration chain.
-- Idempotent: safe to re-run.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
-- NOTE: the SKU is stored with a TRAILING SPACE ('C22 '); match on TRIM.
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C22');

-- ================================================================ name ====
SET @a_name := (SELECT attribute_id FROM eav_attribute a
                JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'name');

UPDATE catalog_product_entity_varchar
SET value = 'Communication Masterclass'
WHERE @sg = 1 AND @pid IS NOT NULL
  AND entity_id = @pid AND attribute_id = @a_name;

-- ============================================================= url_key ====
SET @a_urlkey := (SELECT attribute_id FROM eav_attribute a
                  JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                  WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'url_key');

UPDATE catalog_product_entity_varchar
SET value = 'communication-masterclass'
WHERE @sg = 1 AND @pid IS NOT NULL
  AND entity_id = @pid AND attribute_id = @a_urlkey;

SET @a_urlpath := (SELECT attribute_id FROM eav_attribute a
                   JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                   WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'url_path');

UPDATE catalog_product_entity_varchar
SET value = 'communication-masterclass.html'
WHERE @sg = 1 AND @pid IS NOT NULL
  AND entity_id = @pid AND attribute_id = @a_urlpath;

-- =============================================================== price ====
SET @a_price := (SELECT attribute_id FROM eav_attribute a
                 JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                 WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'price');

UPDATE catalog_product_entity_decimal
SET value = 700.0000
WHERE @sg = 1 AND @pid IS NOT NULL
  AND entity_id = @pid AND attribute_id = @a_price;

-- ================================================== duration / sessions ===
-- Non-WSQ day length is 7.5 hrs x days -> 2 days = 15 hrs. (The parent's 16 hrs
-- includes the WSQ assessment block, which the non-WSQ twin drops.)
SET @a_dur  := (SELECT attribute_id FROM eav_attribute a
                JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'duration');
SET @a_sess := (SELECT attribute_id FROM eav_attribute a
                JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'sessions');

UPDATE catalog_product_entity_varchar
SET value = '15'
WHERE @sg = 1 AND @pid IS NOT NULL
  AND entity_id = @pid AND attribute_id = @a_dur;

UPDATE catalog_product_entity_varchar
SET value = '2'
WHERE @sg = 1 AND @pid IS NOT NULL
  AND entity_id = @pid AND attribute_id = @a_sess;

-- ======================================================== image labels ====
SET @a_imglbl  := (SELECT attribute_id FROM eav_attribute a
                   JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                   WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'image_label');
SET @a_simglbl := (SELECT attribute_id FROM eav_attribute a
                   JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                   WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'small_image_label');
SET @a_thmblbl := (SELECT attribute_id FROM eav_attribute a
                   JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                   WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'thumbnail_label');

UPDATE catalog_product_entity_varchar
SET value = 'Communication Masterclass'
WHERE @sg = 1 AND @pid IS NOT NULL
  AND entity_id = @pid
  AND attribute_id IN (@a_imglbl, @a_simglbl, @a_thmblbl);

-- ============================================================ meta data ===
-- meta_title / meta_description are varchar(255); both fit.
SET @a_mtitle := (SELECT attribute_id FROM eav_attribute a
                  JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                  WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'meta_title');
SET @a_mdesc  := (SELECT attribute_id FROM eav_attribute a
                  JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                  WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'meta_description');

UPDATE catalog_product_entity_varchar
SET value = 'Communication Masterclass | Tertiary Courses Singapore'
WHERE @sg = 1 AND @pid IS NOT NULL
  AND entity_id = @pid AND attribute_id = @a_mtitle;

UPDATE catalog_product_entity_varchar
SET value = 'Evaluate workplace communication practices, develop a communications plan and close communication gaps to strengthen team collaboration and customer satisfaction in this 2-day masterclass in Singapore.'
WHERE @sg = 1 AND @pid IS NOT NULL
  AND entity_id = @pid AND attribute_id = @a_mdesc;

SET @a_mkey := (SELECT attribute_id FROM eav_attribute a
                JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'meta_keyword');

UPDATE catalog_product_entity_text
SET value = 'Communication Masterclass, Workplace Communication, Communications Plan, Communication Channels, Team Collaboration, Customer Satisfaction, Communication Barriers, Coaching'
WHERE @sg = 1 AND @pid IS NOT NULL
  AND entity_id = @pid AND attribute_id = @a_mkey;

-- ===================================================== short_description ==
-- Copied from the parent, with the WSQ framing dropped.
SET @a_sdesc := (SELECT attribute_id FROM eav_attribute a
                 JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                 WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'short_description');

UPDATE catalog_product_entity_text
SET value = CONCAT(
  '<p>This masterclass empowers participants to evaluate workplace communication practices and develop strategies ',
  'that foster collaboration and customer satisfaction. Gain expertise in identifying communication gaps, ',
  'selecting effective communication channels, and implementing best practices to enhance workplace communication. ',
  'Learn how to assess communication effectiveness and implement tools that align with organizational goals.</p>',
  '<p>Participants will also explore trends in communication planning, including setting communication objectives, ',
  'identifying target audiences, and overcoming communication barriers. With a focus on coaching and problem-solving, ',
  'this course equips learners with the skills to address workplace communication challenges, promote seamless ',
  'collaboration, and build stronger relationships with customers.</p>'
)
WHERE @sg = 1 AND @pid IS NOT NULL
  AND entity_id = @pid AND attribute_id = @a_sdesc;

-- ================================================ description (topics) ====
-- The three topics of the parent TGS-2023037467, verbatim, in the non-WSQ
-- course-topic markup. The leading LSN_DATA comment is the structured mirror
-- the course-outline UI reads; it must stay in sync with the HTML below it.
-- (The OLD C22 description carried a 4-topic LSN_DATA block from the previous
-- course -- it is replaced wholesale here, not appended to.)
SET @a_desc := (SELECT attribute_id FROM eav_attribute a
                JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'description');

UPDATE catalog_product_entity_text
SET value = CONCAT(
  '<!-- LSN_DATA: [',
    '{"title":"Topic 1: Evaluate Workplace Communications Practices","subsecs":[',
      '{"title":"Introduction to workplace communication","links":[]},',
      '{"title":"Best practices in workplace communications","links":[]},',
      '{"title":"Effective communication strategies and tools","links":[]},',
      '{"title":"Communication channels","links":[]},',
      '{"title":"Evaluate workplace communications practices","links":[]}]},',
    '{"title":"Topic 2: Develop Communications Plan","subsecs":[',
      '{"title":"Introduction to communications planning","links":[]},',
      '{"title":"Identifying communication goals","links":[]},',
      '{"title":"Determining target audiences","links":[]},',
      '{"title":"Selecting communication channels","links":[]},',
      '{"title":"Criteria to evaluate effectiveness of communication strategies","links":[]},',
      '{"title":"Develop and implement communications plan","links":[]}]},',
    '{"title":"Topic 3: Identify Solutions to Address Communication Gaps and Barriers","subsecs":[',
      '{"title":"Identifying Communication gaps and barriers","links":[]},',
      '{"title":"Methods to coaching","links":[]},',
      '{"title":"Identify solutions to address communication gaps and barriers","links":[]}]}',
  '] -->\n',
  '<h3 class="course-topic-h3">Topic 1: Evaluate Workplace Communications Practices</h3>\n<ul>\n',
  '<li>Introduction to workplace communication</li>\n',
  '<li>Best practices in workplace communications</li>\n',
  '<li>Effective communication strategies and tools</li>\n',
  '<li>Communication channels</li>\n',
  '<li>Evaluate workplace communications practices</li>\n</ul>\n',
  '<h3 class="course-topic-h3">Topic 2: Develop Communications Plan</h3>\n<ul>\n',
  '<li>Introduction to communications planning</li>\n',
  '<li>Identifying communication goals</li>\n',
  '<li>Determining target audiences</li>\n',
  '<li>Selecting communication channels</li>\n',
  '<li>Criteria to evaluate effectiveness of communication strategies</li>\n',
  '<li>Develop and implement communications plan</li>\n</ul>\n',
  '<h3 class="course-topic-h3">Topic 3: Identify Solutions to Address Communication Gaps and Barriers</h3>\n<ul>\n',
  '<li>Identifying Communication gaps and barriers</li>\n',
  '<li>Methods to coaching</li>\n',
  '<li>Identify solutions to address communication gaps and barriers</li>\n</ul>\n'
)
WHERE @sg = 1 AND @pid IS NOT NULL
  AND entity_id = @pid AND attribute_id = @a_desc;

-- ======================================================== prerequisite ====
-- Drop the SWDA / SkillsFuture-claim / UTAP tail (priced off the old $350 fee);
-- keep the sections every other $700 non-WSQ course keeps.
SET @a_prereq := (SELECT attribute_id FROM eav_attribute a
                  JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id
                  WHERE t.entity_type_code = 'catalog_product' AND a.attribute_code = 'prerequisite');

UPDATE catalog_product_entity_text
SET value = CONCAT(
  '<h2>Promotion Code</h2>\n<p>Your will get 10% discount voucher for 2nd course onwards if you write us a ',
  '<span style="text-decoration: underline;"><a href="https://g.page/r/CeH-OtN8J4r9EB0/review" target="_blank">Google review</a>.</span></p>\n',
  '<h2>Minimum Entry Requirement</h2>\n<p>Knowledge and Skills</p>\n<ul>\n',
  '<li>Able to operate using computer functions</li>\n',
  '<li>Minimum 3 GCE &lsquo;O&rsquo; Levels Passes including English or WPL Level 5 (Average of Reading, Listening, Speaking &amp; Writing Scores)</li>\n</ul>\n',
  '<p>Attitude</p>\n<ul>\n<li>Positive Learning Attitude</li>\n<li>Enthusiastic Learner</li>\n</ul>\n',
  '<p>Experience</p>\n<ul>\n<li>Minimum of 1 year of working experience.</li>\n</ul>\n',
  '<p>Target Age Group: 21-65 years old</p>\n',
  '<h2>Minimum Software/Hardware Requirement</h2>\n',
  '<p><strong>Software:</strong> NIL</p>\n',
  '<p><strong>Hardware:</strong> Windows and Mac Laptops</p>\n'
)
WHERE @sg = 1 AND @pid IS NOT NULL
  AND entity_id = @pid AND attribute_id = @a_prereq;

-- ======================================================== 301 rewrites ====
-- Every stored path that resolved to the old slug must 301 to the new bare
-- slug. options='RP' IS the 301; an empty options column is a 302.
--
-- This entity was repurposed before (old "1-day-ibooks-author-..." rows still
-- point here), and most existing RP rows target CATEGORY-PREFIXED paths
-- (adult-training-courses/..., business-soft-skills-courses/... ). Those
-- prefixed paths stop resolving once the slug changes, so they are flattened
-- to the new BARE slug here -- otherwise they 301 into a 404.
--
-- 1) Repoint existing RP rows whose TARGET was any old-slug path (bare or
--    category-prefixed).
UPDATE core_url_rewrite
SET target_path = 'communication-masterclass.html', options = 'RP', is_system = 0
WHERE @sg = 1
  AND options = 'RP'
  AND target_path LIKE '%effective-communication-training.html';

-- 2) Turn the old SYSTEM rows into permanent redirects to the new bare slug.
--    The indexer recreates the system rows for the new slug.
UPDATE core_url_rewrite
SET target_path = 'communication-masterclass.html', options = 'RP', is_system = 0
WHERE @sg = 1 AND @pid IS NOT NULL
  AND product_id = @pid
  AND request_path LIKE '%effective-communication-training.html'
  AND target_path LIKE 'catalog/product/view/id/%';

-- 3) Belt and braces: a bare old-slug -> new-slug row in the default (0) and
--    SG (1) scopes even if the rows above were missing.
INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('manual-301-', MD5('effective-communication-training.html'), '-', s.store_id),
       'effective-communication-training.html',
       'communication-masterclass.html', 0, 'RP'
FROM (SELECT 0 AS store_id UNION ALL SELECT 1 AS store_id) s
WHERE @sg = 1
  AND NOT EXISTS (
    SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
    WHERE x.request_path = 'effective-communication-training.html'
      AND x.store_id = s.store_id
  );

-- ==================================================== search redirects ====
UPDATE catalogsearch_query
SET redirect = REPLACE(redirect,
                       'effective-communication-training.html',
                       'communication-masterclass.html')
WHERE @sg = 1
  AND redirect LIKE '%effective-communication-training.html';

-- ====================================================== funding block =====
-- The Funding card already names the correct parent, but its href
-- (wsq-effective-workplace-communications.html) is an OLD slug that 200s only
-- by 301-chaining to the parent's real URL. Flatten it to the target that
-- resolves 200 with no hop.
UPDATE cms_block
SET content = CONCAT(
  '<p>No funding is available for this course.</p> ',
  '<p>For WSQ funding, please checkout the details at&nbsp;',
  '<span style="text-decoration: underline;">',
  '<a href="https://www.tertiarycourses.com.sg/wsq-mastering-the-art-of-communication-to-enhance-team-collaboration-and-customer-satisfaction.html" ',
  'title="WSQ - Mastering the Art of Communication to Enhance Team Collaboration and Customer Satisfaction">',
  'WSQ - Mastering the Art of Communication to Enhance Team Collaboration and Customer Satisfaction',
  '</a></span></p>'
)
WHERE @sg = 1
  AND identifier = 'course_C22_funding_and_grant';
