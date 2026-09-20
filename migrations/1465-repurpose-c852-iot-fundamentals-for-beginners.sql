-- 1465: Repurpose C852
--   OLD: "Agentic AI for IoT"
--   NEW: "Internet of Things (IoT) Fundamentals for Beginners"
-- SKU unchanged (C852). Non-WSQ C-prefix course: 2 days / 15 hrs / $700.
--
-- Content follows the WSQ parent TGS-2020504020
-- (wsq-internet-of-things-iot-fundamental-for-beginners.html): same 4 topics,
-- same "What's This Course About" prose, same job roles.
--
-- This is a REPURPOSE, not a retitle -- the subject moves from agentic AI /
-- ESP8266 + IoTFlow to beginner IoT fundamentals -- so content AND taxonomy
-- surfaces both change.
--
-- Surfaces touched:
--   1  name / meta_title
--   2  meta_description / meta_keyword
--   3  url_key + url_path (deleted at every scope so the rewrite indexer
--      regenerates) + explicit 301 from the old bare slug + chain flatten
--   4  description      -> the WSQ parent's 4 topics
--   5  short_description-> the WSQ parent's About prose (kit note dropped:
--                          the non-WSQ twin does not carry the WSQ kit
--                          disclaimer)
--   6  whoshouldattend  -> the WSQ parent's job roles
--   7  prerequisite     -> beginner entry (no Arduino/C++ assumed); Software
--                          section keeps the Arduino IDE + CH210x driver only
--                          (Node JS was for the IoTFlow agent stack)
--   8  *_label (3) + media_gallery_value.label -> the real rendered alt text
--   9  categories       -> drop Agentic AI Series (189), AI Applications
--                          Series (139), AI Courses (252), AI for Robotics
--                          (377). Keeps 3/56/73/143, matching the WSQ parent.
--  10  course_image_url -> fresh R2 cover rendered from the NEW title
--                          (re-rendered out-of-band after deploy; the PNG
--                          bakes the title, so the old one reads
--                          "Agentic AI for IoT")
--  11  funding block    -> repoint at the course's OWN WSQ parent
--                          (currently points at the unrelated Agentic AI for
--                          Business Process Automation)
--  12  catalogsearch_query rows that named the old agentic slug
--
-- Deliberately NOT touched:
--   - image / small_image / thumbnail: filesystem PATHS; renaming 404s the JPG.
--     The storefront renders the R2 cover (course_image_url). The existing
--     path is already topic-correct
--     (/g/e/getting-started-with-iot-hands-on-training-for-beginners.jpg).
--   - price (700), duration (15), sessions (2): unchanged; already the
--     standard non-WSQ 2-day shape. (The WSQ parent is 16 hrs; the non-WSQ
--     day is 7.5 hrs x 2 = 15 -- feedback_nonwsq_duration_is_7p5_hours_per_day.)
--   - software (198 = Non-funded), level (11 = Beginner), agegroup: correct.
--   - trainerprofile: bios carry no agentic-AI-specific teaching claim.
--   - brochure block: regenerated out-of-band from the new title.
-- Partner-safe: C852 exists only on SG => @e IS NULL on MY/GH => every
-- statement no-ops. All replacement text is clean ASCII (apply.php uses utf8).

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C852' LIMIT 1);

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpth  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_sdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_who     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');
SET @a_prereq  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');
SET @a_ilabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_slabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_tlabel  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');

-- --------------------------------------------------------------- 1. name
UPDATE catalog_product_entity_varchar
   SET value = 'Internet of Things (IoT) Fundamentals for Beginners'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- meta_title: store the PLAIN title. MMD_Seotitle appends the brand postfix at
-- render time, so baking "| Tertiary Courses Singapore" here duplicates it.
-- (The OLD row did bake it -- fix that here.)
UPDATE catalog_product_entity_varchar
   SET value = 'Internet of Things (IoT) Fundamentals for Beginners'
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND @e IS NOT NULL;

-- ------------------------------------------------------- 2. meta description
-- meta_description is varchar(255) -- keep under the cap or the write truncates.
UPDATE catalog_product_entity_varchar
   SET value = 'Learn how smart devices sense, connect and share data. Cover IoT sensors, actuators, wireless protocols, cloud data and analytics in this hands-on 2-day beginner course in Singapore.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = 'IoT, Internet of Things, IoT for Beginners, Sensors, Actuators, ESP8266, MQTT, REST API, Cloud Computing, IoT Analytics, IoT Security, Course, Singapore'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------- 3. url_key / url_path / 301
-- Clear any is_system = 0 squatter on the NEW path first: INSERT IGNORE would
-- silently no-op against a stale row.
DELETE FROM core_url_rewrite
 WHERE request_path = 'internet-of-things-iot-fundamentals-for-beginners.html'
   AND is_system = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'internet-of-things-iot-fundamentals-for-beginners'
 WHERE entity_id = @e AND attribute_id = @a_urlkey AND @e IS NOT NULL;

-- Drop url_path at EVERY scope so the URL-rewrite indexer regenerates it.
-- (C852 has BOTH a store-0 and a store-1 url_path row -- the store-1 one would
-- otherwise shadow the new slug.)
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlpth AND @e IS NOT NULL;

-- Explicit 301 for the old BARE slug.
--
-- An is_system = 1 rewrite already SQUATS the old bare slug (id_path
-- 'product/852', url_rewrite_id 781112), so a bare INSERT IGNORE hits the
-- unique key and silently no-ops, leaving the old URL resolving to the product
-- with no redirect (feedback_repurpose_301_needs_system_row_delete). Delete the
-- system row first; the rewrite indexer regenerates a system row for the NEW
-- slug.
DELETE FROM core_url_rewrite
 WHERE product_id = @e AND is_system = 1
   AND request_path = 'agentic-ai-for-iot.html'
   AND @e IS NOT NULL;

-- The indexer auto-301s the category paths.
INSERT IGNORE INTO core_url_rewrite
    (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT s.store_id, NULL, @e,
       CONCAT('product/', @e),
       'agentic-ai-for-iot.html',
       'internet-of-things-iot-fundamentals-for-beginners.html',
       0, 'RP', '1465 repurpose 301'
  FROM core_store s
 WHERE s.store_id > 0 AND @e IS NOT NULL;

-- Flatten the inherited chains. C852 carries a LOT of history (nodemcu-*,
-- internet-of-things-iot-esp32-*, getting-started-with-iot-*): those rows
-- already 301 into the OLD bare slug and would become 2-hop redirects.
-- Anchor on target_path so every foreign alias is repointed
-- (feedback_rename_chain_flatten_must_anchor_request_path).
UPDATE core_url_rewrite
   SET target_path = 'internet-of-things-iot-fundamentals-for-beginners.html'
 WHERE is_system = 0
   AND target_path = 'agentic-ai-for-iot.html'
   AND request_path <> 'agentic-ai-for-iot.html'
   AND @e IS NOT NULL;

-- Category-scoped chains (e.g. 'adult-training-courses/agentic-ai-for-iot.html').
UPDATE core_url_rewrite
   SET target_path = REPLACE(target_path, 'agentic-ai-for-iot.html', 'internet-of-things-iot-fundamentals-for-beginners.html')
 WHERE is_system = 0
   AND target_path LIKE '%/agentic-ai-for-iot.html'
   AND @e IS NOT NULL;

-- --------------------------------------------------------- 4. description
-- The WSQ parent's 4 topics, in the non-WSQ house shape.
UPDATE catalog_product_entity_text
   SET value = '<h3 class="course-topic-h3">Topic 1 Overview of Internet of Things (IoT)</h3>\n<ul>\n<li>What is IoT?</li>\n<li>Sensors and Actuators for IoT</li>\n<li>Wireless Communication Technologies for IoT</li>\n<li>IoT Applications and Use Cases</li>\n</ul>\n<h3 class="course-topic-h3">Topic 2 Collect and Post Data to Cloud</h3>\n<ul>\n<li>Cloud Computing for IoT</li>\n<li>Setup Cloud Computing Account</li>\n<li>Collect Data with Sensors</li>\n<li>Transmit Data using ESP8266</li>\n<li>Post Data to Cloud using MQTT or REST API</li>\n</ul>\n<h3 class="course-topic-h3">Topic 3 Read Data and Remote Control Devices from Cloud</h3>\n<ul>\n<li>Read Data using MQTT or REST API</li>\n<li>Remote Control Devices from Cloud</li>\n</ul>\n<h3 class="course-topic-h3">Topic 4 IoT Data Analytics and Visualization</h3>\n<ul>\n<li>Analyze IoT Data on Cloud</li>\n<li>Visualize IoT Data on Cloud</li>\n<li>IoT Security</li>\n</ul>\n'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

-- --------------------------------------------------- 5. short_description
-- The WSQ parent's About prose. The parent's red "IoT kit not included" note
-- is a WSQ-specific disclaimer and is NOT carried into the non-WSQ twin.
UPDATE catalog_product_entity_text
   SET value = '<p>Curious about how the Internet of Things (IoT) is reshaping the world around you? This IoT Fundamentals for Beginners course offers a solid foundation for understanding this transformative technology. Learn the basics of how smart devices communicate, collect data, and interact with the environment. Explore key IoT components such as sensors, actuators, and network protocols, providing you with the essential knowledge to understand and engage with IoT systems.</p><p>Beyond the fundamental concepts, this course dives into practical applications. Learn how to analyze data from IoT devices, enabling informed decision-making. You will also discover how IoT is applied across various sectors, such as healthcare, smart cities, and industrial automation. By grasping these concepts and their real-world applications, you will be well-equipped to navigate the ever-expanding landscape of IoT, whether for personal interest or professional advancement.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0 AND @e IS NOT NULL;

-- ----------------------------------------------------- 6. whoshouldattend
-- The WSQ parent's job roles (beginner / strategy oriented), replacing the
-- old deep IoT-engineering list that suited the agentic course.
UPDATE catalog_product_entity_text
   SET value = '<ul><li>IoT Product Manager</li><li>Innovation Manager</li><li>IoT Solutions Architect</li><li>Smart City Planner</li><li>R&amp;D Specialist</li><li>Business Strategist</li><li>Digital Transformation Lead</li><li>Manufacturing Process Manager</li><li>IoT Data Analyst</li><li>Connected Devices Engineer</li><li>Operations Manager (IoT-focused)</li><li>Smart Grid Specialist</li><li>Home Automation Developer</li><li>Supply Chain Innovation Manager</li><li>Industrial Automation Strategist</li></ul>'
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0 AND @e IS NOT NULL;

-- -------------------------------------------------------- 7. prerequisite
-- Beginner course: drop the "Basic Arduino / Basic C++" assumption. Keep the
-- Software Requirement block (this is the non-WSQ entry apparatus, NOT the WSQ
-- funding apparatus -- the WSQ parent's version must not be copied here).
-- Node JS is dropped with the IoTFlow agent stack.
UPDATE catalog_product_entity_text
   SET value = '<h2>Prerequisite</h2><p>This course assumes the following:</p><ul><li>Basic computer literacy</li><li>No prior IoT or programming experience required</li></ul><h2>Software Requirement</h2><ul><li>Download and install Arduino IDE <a href="https://www.arduino.cc/en/Main/Software" rel="noopener noreferrer" target="_blank">https://www.arduino.cc/en/Main/Software</a></li><li>Download and install CH210x USB to UART driver <a href="https://www.silabs.com/products/development-tools/software/usb-to-uart-bridge-vcp-drivers" rel="noopener noreferrer" target="_blank">https://www.silabs.com/products/development-tools/software/usb-to-uart-bridge-vcp-drivers</a></li></ul>'
 WHERE entity_id = @e AND attribute_id = @a_prereq AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------------------------- 8. alt text
UPDATE catalog_product_entity_varchar
   SET value = 'Internet of Things (IoT) Fundamentals for Beginners'
 WHERE entity_id = @e
   AND attribute_id IN (@a_ilabel, @a_slabel, @a_tlabel)
   AND @e IS NOT NULL;

-- The media-gallery per-image label is the REAL rendered alt/title on the
-- product-page zoom gallery (feedback_media_gallery_label_is_the_real_alt_text).
-- C852's still reads "Getting Started with IoT Hands-On Training for Beginners"
-- from an earlier life.
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'Internet of Things (IoT) Fundamentals for Beginners'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ----------------------------------------------------------- 9. categories
-- Drop the AI taxonomy: the course is no longer an AI course.
-- Resolve BY NAME so the statement is partner-safe and id-drift-proof
-- (feedback_course_repurpose_cross_site_rollout step 5).
DELETE cp FROM catalog_category_product cp
  JOIN catalog_category_entity_varchar cv
    ON cv.entity_id = cp.category_id AND cv.store_id = 0
   AND cv.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name')
 WHERE cp.product_id = @e
   AND cv.value IN ('Agentic AI Series', 'AI Applications Series', 'AI Courses', 'AI for Robotics')
   AND @e IS NOT NULL;

-- Mirror the removal into the category index, else the course keeps rendering
-- in those listings until a full reindex (feedback_category_swap_needs_index_mirror).
DELETE ci FROM catalog_category_product_index ci
  JOIN catalog_category_entity_varchar cv
    ON cv.entity_id = ci.category_id AND cv.store_id = 0
   AND cv.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name')
 WHERE ci.product_id = @e
   AND cv.value IN ('Agentic AI Series', 'AI Applications Series', 'AI Courses', 'AI for Robotics')
   AND @e IS NOT NULL;

-- Drop the now-dead category rewrites for those four.
DELETE FROM core_url_rewrite
 WHERE product_id = @e
   AND id_path IN ('product/852/189', 'product/852/139', 'product/852/252', 'product/852/377')
   AND @e IS NOT NULL;

-- --------------------------------------------------------- 10. R2 cover
-- The cover PNG bakes the course title, so the old one reads "Agentic AI for
-- IoT". Placeholder is NOT written here: the fresh PNG is rendered + uploaded
-- out-of-band after deploy and its URL written then
-- (feedback_cover_renderer_change_needs_rerender_of_r2_pngs). Clearing any
-- store-scoped override so the store-0 value wins once it is refreshed.
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e
   AND attribute_id = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url')
   AND store_id <> 0
   AND @e IS NOT NULL;

-- ----------------------------------------------------- 11. funding block
-- Point at the course's OWN WSQ parent (TGS-2020504020), not the unrelated
-- Agentic AI for Business Process Automation it inherited.
UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-internet-of-things-iot-fundamental-for-beginners.html" title="WSQ - Internet of Things (IoT) Fundamental for Beginners">WSQ - Internet of Things (IoT) Fundamental for Beginners</a></span></p>'
 WHERE identifier = 'course_C852_funding_and_grant';

-- ------------------------------------------------- 12. search redirects
-- Repoint any stored redirect that still names the old agentic slug.
-- Only touches rows already pointing AT this course -- never overwrites an
-- unrelated intentional redirect.
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/internet-of-things-iot-fundamentals-for-beginners.html'
 WHERE redirect LIKE '%agentic-ai-for-iot.html';

-- ------------------------------------------- 13. stale custom option
-- "Replaced with ESP32-CAM" (option_id 17664) is a required radio left over
-- from an earlier life of this entity; it renders on the live product page and
-- makes no sense on a beginner fundamentals course.
--
-- Safe to delete in SQL: this is a PRODUCT-LEVEL option, NOT a schedule
-- template member. Verified on prod -- no row in custom_options_group has
-- 17664 in its hash_options blob, so the "never switch templates in SQL" rule
-- (feedback_schedule_template_switch_never_in_sql) does not apply here. The
-- Course Date / Course Time / Mode of Training / Sponsorship options are the
-- template-managed ones and are left completely untouched.
--
-- Resolve the option BY TITLE + product so the statement is id-drift-proof and
-- no-ops on partners. C1194 carries the same option and is NOT touched.
DELETE o FROM catalog_product_option o
  JOIN catalog_product_option_title ot
    ON ot.option_id = o.option_id AND ot.store_id = 0
 WHERE o.product_id = @e
   AND ot.title = 'Replaced with ESP32-CAM'
   AND @e IS NOT NULL;

-- Schedule: the Course Date option already carries the SAME 16 dates as the
-- WSQ parent TGS-2020504020 (verified on prod 2026-09-20), so no schedule
-- change is needed. Course Time correctly stays 9:30am - 5:30pm: the non-WSQ
-- day is 7.5 hrs (15 hrs / 2 days) against the WSQ parent's 8-hr day
-- (feedback_nonwsq_duration_is_7p5_hours_per_day).
