-- 1523: C689 -> "Scrum Master and Design Sprint Masterclass"
-- Non-WSQ twin of TGS-2024045803 (WSQ Scrum Master Fundamentals for High-Performing Teams).
--   * rename + new url_key (old slug 301s to the new one)
--   * 2 days / 15 instructional hours / $700
--   * schedule template A07 -> B03 (matches the parent's (SG) WSQ-B03)  [applied via CODE path, not here]
--   * description + topics copied from the WSQ parent, WSQ branding stripped, no day count
--   * funding block redirects to the funded WSQ twin
-- SG production only. Idempotent. Guarded on sku so partner sites are untouched.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C689');

-- ---------- identity ----------
SET @a_name := (SELECT a.attribute_id FROM eav_attribute a JOIN eav_entity_type t ON t.entity_type_id=a.entity_type_id
                WHERE t.entity_type_code='catalog_product' AND a.attribute_code='name');
SET @a_urlkey := (SELECT a.attribute_id FROM eav_attribute a JOIN eav_entity_type t ON t.entity_type_id=a.entity_type_id
                WHERE t.entity_type_code='catalog_product' AND a.attribute_code='url_key');
SET @a_mtitle := (SELECT a.attribute_id FROM eav_attribute a JOIN eav_entity_type t ON t.entity_type_id=a.entity_type_id
                WHERE t.entity_type_code='catalog_product' AND a.attribute_code='meta_title');
SET @a_mdesc := (SELECT a.attribute_id FROM eav_attribute a JOIN eav_entity_type t ON t.entity_type_id=a.entity_type_id
                WHERE t.entity_type_code='catalog_product' AND a.attribute_code='meta_description');
SET @a_short := (SELECT a.attribute_id FROM eav_attribute a JOIN eav_entity_type t ON t.entity_type_id=a.entity_type_id
                WHERE t.entity_type_code='catalog_product' AND a.attribute_code='short_description');
SET @a_desc := (SELECT a.attribute_id FROM eav_attribute a JOIN eav_entity_type t ON t.entity_type_id=a.entity_type_id
                WHERE t.entity_type_code='catalog_product' AND a.attribute_code='description');
SET @a_dur := (SELECT a.attribute_id FROM eav_attribute a JOIN eav_entity_type t ON t.entity_type_id=a.entity_type_id
                WHERE t.entity_type_code='catalog_product' AND a.attribute_code='duration');
SET @a_sess := (SELECT a.attribute_id FROM eav_attribute a JOIN eav_entity_type t ON t.entity_type_id=a.entity_type_id
                WHERE t.entity_type_code='catalog_product' AND a.attribute_code='sessions');
SET @a_price := (SELECT a.attribute_id FROM eav_attribute a JOIN eav_entity_type t ON t.entity_type_id=a.entity_type_id
                WHERE t.entity_type_code='catalog_product' AND a.attribute_code='price');

UPDATE catalog_product_entity_varchar
   SET value = 'Scrum Master and Design Sprint Masterclass'
 WHERE entity_id = @pid AND attribute_id = @a_name;

UPDATE catalog_product_entity_varchar
   SET value = 'scrum-master-and-design-sprint-masterclass'
 WHERE entity_id = @pid AND attribute_id = @a_urlkey;

UPDATE catalog_product_entity_varchar
   SET value = 'Scrum Master and Design Sprint Masterclass'
 WHERE entity_id = @pid AND attribute_id = @a_mtitle;

UPDATE catalog_product_entity_varchar
   SET value = 'Lead high-performing Agile teams. Master Scrum roles, events, artifacts and design sprint facilitation at Tertiary Courses Singapore.'
 WHERE entity_id = @pid AND attribute_id = @a_mdesc;

-- ---------- duration / sessions: 2 days x 7.5 h = 15 instructional hours ----------
UPDATE catalog_product_entity_varchar SET value = '15' WHERE entity_id = @pid AND attribute_id = @a_dur;
UPDATE catalog_product_entity_varchar SET value = '2'  WHERE entity_id = @pid AND attribute_id = @a_sess;

-- ---------- fee: $700 (every scope row) ----------
UPDATE catalog_product_entity_decimal
   SET value = 700.0000
 WHERE entity_id = @pid AND attribute_id = @a_price;

-- ---------- description + topics, copied from the WSQ parent ----------
UPDATE catalog_product_entity_text
   SET value = '<p>The Scrum Master and Design Sprint Masterclass equips learners with essential knowledge and skills to implement Agile Scrum practices effectively. The course introduces Scrum foundations, covering Agile principles, Scrum frameworks, and core roles, including the Scrum Master as a servant leader, Product Owner, and Development Team. Participants will learn to manage role responsibilities while fostering collaboration by sharing Agile artifacts and establishing team norms to drive performance.</p>\n<p>The course delves into Agile and Scrum project management, emphasizing sprint planning, backlog refinement, and progress tracking using burn-down and burn-up charts. Learners will gain expertise in facilitating Scrum meetings such as daily scrums, sprint reviews, and retrospectives. By mastering Scrum artifacts and understanding the definition of done, participants will enhance their ability to lead high-performing teams and deliver successful Agile projects.</p>'
 WHERE entity_id = @pid AND attribute_id = @a_short;

UPDATE catalog_product_entity_text
   SET value = '<h3 class="course-topic-h3">Topic 1: Scrum Foundations</h3>\n<ul>\n<li>Agile overview</li>\n<li>Scrum foundation</li>\n<li>Scrum framework</li>\n</ul>\n<h3 class="course-topic-h3">Topic 2: Scrum Roles</h3>\n<ul>\n<li>Scrum master role</li>\n<li>Scrum master as servant leader</li>\n<li>Product owner</li>\n<li>Product owner responsibilities</li>\n<li>Development team</li>\n<li>Shared resources</li>\n<li>Establishing norms</li>\n<li>Team spaces</li>\n</ul>\n<h3 class="course-topic-h3">Topic 3: Agile &amp; Scrum Meetings</h3>\n<ul>\n<li>Scrum events overview</li>\n<li>Sprint planning</li>\n<li>Daily scrum</li>\n<li>Backlog refinement</li>\n<li>Sprint review</li>\n<li>Sprint retrospective</li>\n</ul>\n<h3 class="course-topic-h3">Topic 4: Scrum &amp; Agile Project Management</h3>\n<ul>\n<li>Tracking and reporting progress</li>\n<li>Burn-down charts</li>\n<li>Burn-up charts</li>\n</ul>\n<h3 class="course-topic-h3">Topic 5: Scrum Artifacts</h3>\n<ul>\n<li>Product backlog</li>\n<li>Backlog ordering</li>\n<li>Product increment</li>\n<li>Definition of done</li>\n</ul>'
 WHERE entity_id = @pid AND attribute_id = @a_desc;

-- ---------- 301: old slug -> new slug ----------
-- The system rewrite (is_system=1, id_path product/<id>) is regenerated by the
-- Catalog URL Rewrites indexer, which must run after this migration. Here we
-- only (a) drop the stale system row so the indexer rebuilds it on the new slug,
-- and (b) add the custom 301 from the old slug.
DELETE FROM core_url_rewrite
 WHERE id_path = CONCAT('product/', @pid)
   AND request_path = 'scrum-master-masterclass.html';

INSERT IGNORE INTO core_url_rewrite
       (store_id, id_path, request_path, target_path, is_system, options, description)
VALUES (1, CONCAT('c689-rename-301/', @pid), 'scrum-master-masterclass.html',
        'scrum-master-and-design-sprint-masterclass.html', 0, 'RP', 'C689 rename 301');

-- Flatten any EXISTING 301 that pointed at the old slug, so it does not become
-- a 301 -> 404 chain (e.g. scrum-master-basic-training.html).
UPDATE core_url_rewrite
   SET target_path = 'scrum-master-and-design-sprint-masterclass.html'
 WHERE target_path = 'scrum-master-masterclass.html'
   AND is_system = 0
   AND EXISTS (SELECT 1 FROM catalog_product_entity WHERE sku = 'C689');

-- ---------- funding block -> the funded WSQ twin ----------
UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>\n<p>This Masterclass is not funded. If you need course-fee funding, the WSQ version of this course is eligible for up to 70% WSQ funding subsidy:</p>\n<p><a href="https://www.tertiarycourses.com.sg/wsq-scrum-master-fundamentals-for-high-performing-teams.html">WSQ Scrum Master Fundamentals for High-Performing Teams</a></p>'
 WHERE identifier = 'course_C689_funding_and_grant'
   AND EXISTS (SELECT 1 FROM catalog_product_entity WHERE sku = 'C689');
