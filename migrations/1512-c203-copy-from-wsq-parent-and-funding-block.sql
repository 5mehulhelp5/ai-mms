-- C203 "IoT with Raspberry Pi": align the product page with its WSQ parent
-- TGS-2020505433, whose built courseware was converted into C203's non-WSQ
-- courseware (deck / Lesson Plan / Learner Guide / 4 labs).
--
-- Three data-only changes, all idempotent:
--
--   1. `description` (the topic list) copied from the parent, so both catalogue
--      entries describe the same four topics as the converted courseware. C203
--      carried a DIFFERENT 4-topic syllabus ("Getting Started with Raspberry Pi
--      and IoTFlow" ...), which reads plausibly and survives every courseware
--      scan -- those read artifacts, not the storefront (incident C1234).
--      The parent's topic HTML contains no WSQ/SSG/SkillsFuture/funding wording
--      and no day count, so nothing needs scrubbing on the way across. Copied
--      row-to-row rather than pasted, so no HTML escaping is involved.
--
--   2. `meta_description` rewritten without the "2-day course" phrase. It is a
--      varchar capped at 255 and feeds <meta>, og:description and the JSON-LD.
--      The Duration/Sessions tiles (15 hrs / 2) already state the length, so the
--      prose must not restate it and risk contradicting them later.
--
--   3. The Funding and Grant block repointed at the funded WSQ twin. A non-WSQ
--      course carries no funding of its own, but the learner reading this page
--      is exactly the person who should be told the funded version exists. The
--      block currently reads "No funding is available for this course".
--      Target verified 200 on www.tertiarycourses.com.sg with no 301 hop.
--
-- NEVER ->save() a cms/block model: that wipes cms_block_store and 404s the
-- page (memory feedback_cms_model_save_wipes_store_mapping). Content-only UPDATE.

SET @pid_new := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C203');
SET @pid_wsq := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2020505433');

SET @a_desc := (SELECT attribute_id FROM eav_attribute
                 WHERE attribute_code = 'description' AND entity_type_id = 4);
SET @a_meta := (SELECT attribute_id FROM eav_attribute
                 WHERE attribute_code = 'meta_description' AND entity_type_id = 4);

-- 1. topics from the parent -------------------------------------------------
SET @src := (SELECT value FROM catalog_product_entity_text
              WHERE entity_id = @pid_wsq AND attribute_id = @a_desc AND store_id = 0);

UPDATE catalog_product_entity_text
   SET value = @src
 WHERE entity_id = @pid_new
   AND attribute_id = @a_desc
   AND store_id = 0
   AND @src IS NOT NULL
   AND @src <> ''
   AND value <> @src;

-- 2. meta_description without the day count (every scope row) ----------------
UPDATE catalog_product_entity_varchar
   SET value = 'Build IoT projects with the Raspberry Pi and the IoTFlow platform. Connect sensors, control devices, build dashboards and automations in this hands-on course at Tertiary Courses Singapore.'
 WHERE entity_id = @pid_new
   AND attribute_id = @a_meta
   AND value LIKE '%2-day course%';

-- 3. funding block -> the funded WSQ twin ------------------------------------
UPDATE cms_block
   SET content = CONCAT(
         '<h2>Funding and Grant Applications</h2>',
         '<p>This course is not eligible for funding. If you would like to use ',
         'SkillsFuture Credit or claim WSQ course fee funding, take the funded ',
         'WSQ version of this course instead: ',
         '<a href="https://www.tertiarycourses.com.sg/wsq-mastering-raspberry-pi-hands-on-practical-applications-for-beginners.html">',
         'WSQ - Mastering Raspberry Pi: Hands-On Practical Applications for Beginners</a>.</p>')
 WHERE identifier = 'course_C203_funding_and_grant'
   AND content NOT LIKE '%wsq-mastering-raspberry-pi-hands-on-practical-applications-for-beginners.html%';
