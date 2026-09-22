-- 1531: TGS-2026064710 -> "CASL - IoT with Arduino"
--
-- Repurposes the IoT course from microcontrollers-in-general onto Arduino
-- specifically. Keeps the CASL prefix (the course stays a TGS- funded SKU;
-- the CASL tag and the other five funding tags are untouched).
--
-- What was ALREADY correct on prod and is deliberately NOT touched:
--   * the course outline (`description`) — the stored Topics 1-4 and their
--     sub-bullets are byte-identical to the requested outline, including the
--     LSN_DATA JSON header the "What You'll Learn" renderer reads.
--   * the supplied LO1-LO4 are the learning outcomes behind those same four
--     topics; this product renders the outline only (there is no separate LO
--     block, and no cms_block exists for this SKU), so there is nothing to
--     write for them.
--   * categories (11), tags (6), trainers, price, duration, sessions.
--
-- What WAS stale and is fixed here: the entity has had several prior lives
-- (Raspberry Pi Zero -> Raspberry Pi Pico W -> Hands-On Guide -> CASL) and the
-- metas, About copy and image alt labels still described the Pico W life:
--   * name, url_key
--   * meta_title — note it must NOT start with "WSQ": MMD_Seotitle prepends
--     "WSQ funded" at render time for TGS- SKUs on the SG site, and the stored
--     title starting with "WSQ" is what produced the live
--     "WSQ funded WSQ IoT Implementation with Raspberry Pi Pico W" duplication.
--   * meta_description (<= 255 chars, varchar column), meta_keyword
--   * short_description — the About copy, rewritten to the supplied text.
--   * image_label / small_image_label / thumbnail_label (the real alt text).
--     The image/small_image/thumbnail PATHS are left alone on purpose —
--     they are filesystem paths and renaming them would 404 the gallery.
--   * course_image_url -> the regenerated R2 cover (title is baked into the
--     PNG, so the rename alone would keep serving "Hands-On Guide ...").
--     Rendered via MMD_CourseImage_Model_Cover with the product's existing
--     badge set (CASL|PSEA|UTAP|SFEC|Absentee Payroll|MCES), verified HTTP 200:
--       course-covers/TGS-2026064710-20260922-152702.png  (133726 bytes)
--
-- SG production only; keyed by SKU so a partner site without this SKU no-ops.
-- Idempotent: plain UPDATEs + INSERT IGNORE / ON DUPLICATE KEY UPDATE.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026064710' LIMIT 1);
SET @et  := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');

-- ---------------------------------------------------------------- name
SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='name' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'CASL - IoT with Arduino'
 WHERE attribute_id = @a_name AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- url_key
SET @a_url := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_key' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'casl-iot-with-arduino'
 WHERE attribute_id = @a_url AND entity_id = @pid AND @pid IS NOT NULL;

-- url_path (global + any store rows)
SET @a_upath := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_path' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'casl-iot-with-arduino.html'
 WHERE attribute_id = @a_upath AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- meta_title
-- No leading "WSQ": MMD_Seotitle adds the "WSQ funded" prefix at render time.
SET @a_mt := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_title' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'IoT with Arduino Course | Tertiary Courses Singapore'
 WHERE attribute_id = @a_mt AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- meta_description
SET @a_md := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_description' AND entity_type_id=@et);
UPDATE catalog_product_entity_varchar
   SET value = 'Learn IoT with Arduino in Singapore. Program microcontrollers, wire sensors and actuators, send data over MQTT and build cloud dashboards with triggers in this hands-on course at Tertiary Courses Singapore.'
 WHERE attribute_id = @a_md AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- meta_keyword
SET @a_mk := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_keyword' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = 'IoT with Arduino, Arduino, Internet of Things, IoT, Microcontroller, MQTT, Sensors, IoT Cloud Dashboard, CASL'
 WHERE attribute_id = @a_mk AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- short_description (About This Course)
SET @a_sd := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description' AND entity_type_id=@et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<p>This course provides a practical, hands-on introduction to the Internet of Things (IoT) using Arduino. Participants will learn how IoT systems work and develop the skills to build connected applications using Arduino microcontrollers, sensors, actuators, communication technologies, and cloud platforms.</p>',
     '<p>Learners will set up the Arduino programming environment, write and upload programs, interface with sensors and electronic components, and collect real-time data from physical devices. The course also covers connecting Arduino-based devices to networks and using MQTT communication protocols to exchange data between IoT devices and cloud services.</p>',
     '<p>Participants will learn to configure IoT cloud dashboards to visualise and monitor sensor data, manage device data, and create triggers and automated responses based on predefined conditions. Through practical activities, learners will build IoT solutions that integrate hardware, software, connectivity, and cloud-based monitoring.</p>',
     '<p>The course also introduces essential IoT security practices, including device security, secure communication, access control, and data protection. By the end of the course, participants will be able to design, develop, test, and manage Arduino-based IoT applications for a range of real-world use cases.</p>',
     '<p><br></p>',
     '<p><strong style="color: rgb(255, 0, 0);">Note that the IoT kit is used for the training. The course fee does not include the kit.</strong></p>')
 WHERE attribute_id = @a_sd AND entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- image alt labels
-- Labels only; the image PATHS stay as-is (filesystem paths).
UPDATE catalog_product_entity_varchar v
   JOIN eav_attribute a ON a.attribute_id = v.attribute_id
    SET v.value = 'CASL - IoT with Arduino'
  WHERE v.entity_id = @pid AND @pid IS NOT NULL
    AND a.entity_type_id = @et
    AND a.attribute_code IN ('image_label','small_image_label','thumbnail_label');

UPDATE catalog_product_entity_media_gallery_value g
   JOIN catalog_product_entity_media_gallery m ON m.value_id = g.value_id
    SET g.label = 'CASL - IoT with Arduino'
  WHERE m.entity_id = @pid AND @pid IS NOT NULL;

-- ---------------------------------------------------------------- cover image
SET @a_ciu := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='course_image_url' AND entity_type_id=@et);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @et, @a_ciu, 0, @pid,
       'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026064710-20260922-152702.png'
 WHERE @pid IS NOT NULL AND @a_ciu IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @pid AND attribute_id = @a_ciu AND store_id <> 0
   AND @pid IS NOT NULL AND @a_ciu IS NOT NULL;

-- ---------------------------------------------------------------- URL rewrites
SET @sid := (SELECT store_id FROM core_store WHERE store_id > 0 ORDER BY store_id LIMIT 1);

-- Free the OLD slug: the is_system=1 rows use id_path 'product/<id>...' — the
-- same id_path the 301 would need — so INSERT IGNORE would silently no-op and
-- refreshProductRewrite() would mint a '-1300' suffix for the NEW slug.
DELETE FROM core_url_rewrite
 WHERE product_id = @pid AND is_system = 1 AND @pid IS NOT NULL
   AND request_path LIKE '%casl-hands-on-guide-to-iot-development-with-microcontrollers.html';

-- Clear any is_system=0 squatter sitting on the NEW paths.
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND request_path LIKE '%casl-iot-with-arduino.html';

-- 301 old -> new: bare path plus each of the 11 category-prefixed paths.
INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT @sid,
       CONCAT('tgs2026064710-iot-arduino-', t.slot, '-', @pid),
       CONCAT(t.prefix, 'casl-hands-on-guide-to-iot-development-with-microcontrollers.html'),
       CONCAT(t.prefix, 'casl-iot-with-arduino.html'),
       0, 'RP', '1531: TGS-2026064710 renamed to CASL - IoT with Arduino'
  FROM (
        SELECT 'bare'   AS slot, ''                                AS prefix
  UNION SELECT 'cat3',           'adult-training-courses/'
  UNION SELECT 'cat15',          'latest-courses/'
  UNION SELECT 'cat56',          'iot-robotics-courses-in/'
  UNION SELECT 'cat74',          'raspberry-pi-courses-in/'
  UNION SELECT 'cat143',         'internet-of-things-iot-training-in/'
  UNION SELECT 'cat290',         'pic-microcontroller-courses/'
  UNION SELECT 'cat292',         'wsq-funded-courses/'
  UNION SELECT 'cat293',         'wsq-finance-mfg-green-courses/'
  UNION SELECT 'cat301',         'wsq-it-security-courses/'
  UNION SELECT 'cat327',         'wsq-iot-robotics-courses/'
  UNION SELECT 'cat328',         'electronics-coures/'
  ) t
 WHERE @pid IS NOT NULL AND @sid IS NOT NULL;

-- Flatten the PRE-EXISTING 301s that still target the OLD slug, so the many
-- historical URLs (wsq-internet-of-things-iot-raspberry-pi-zero,
-- wsq-hands-on-guide-to-iot-development-with-microcontrollers, ...) redirect
-- ONCE to the new slug instead of chaining 301 -> 301.
UPDATE core_url_rewrite
   SET target_path = REPLACE(target_path,
                             'casl-hands-on-guide-to-iot-development-with-microcontrollers.html',
                             'casl-iot-with-arduino.html')
 WHERE is_system = 0
   AND target_path LIKE '%casl-hands-on-guide-to-iot-development-with-microcontrollers.html'
   AND id_path NOT LIKE 'tgs2026064710-iot-arduino-%';

-- ---------------------------------------------------------------- search redirects
-- Five stored search terms point at the pre-CASL slug, which now 301-chains.
-- Repoint them straight at the live URL.
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/casl-iot-with-arduino.html'
 WHERE redirect IN (
        'https://www.tertiarycourses.com.sg/wsq-hands-on-guide-to-iot-development-with-microcontrollers.html',
        'https://www.tertiarycourses.com.sg/casl-hands-on-guide-to-iot-development-with-microcontrollers.html');
