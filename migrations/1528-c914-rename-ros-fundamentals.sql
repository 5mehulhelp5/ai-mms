-- 1528: C914 -> "Robot Operating System (ROS) Fundamentals"
--
-- Renames the non-WSQ ROS course, re-slugs it with permanent 301s from every
-- live URL, and repoints course_image_url at the regenerated cover.
--
-- Content is NOT touched: the existing overview + 4 topics already describe a
-- ROS fundamentals course (workspace/nodes/topics, URDF + Gazebo/RViz, SLAM +
-- navigation), and duration 15h / sessions 2 / $700 is already the non-WSQ
-- house figure (7.5 hrs x 2 days). This change is naming + image only.
--
-- The cover is a PRE-RENDERED PNG on R2 with the title baked in, so the rename
-- alone would keep serving a cover reading "Robotics with ROS". The new object
-- was rendered by MMD_CourseImage_Model_Cover (same code path as the admin
-- cover dialog) and uploaded to shared R2 storage, reachable from prod:
--   course-covers/C914-20260922-151820.png   (156685 bytes, HTTP 200)
-- No badges were passed (C-prefix = non-fundable), matching the empty tag set.
-- The superseded object is left on R2 so reverting is just repointing the URL.
--
-- SG production only; keyed by SKU so a partner site with no C914 no-ops.
-- Idempotent: re-running converges (plain UPDATEs + INSERT IGNORE).

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C914' LIMIT 1);

-- name
SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='name'
   AND entity_type_id=(SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product'));
UPDATE catalog_product_entity_varchar
   SET value = 'Robot Operating System (ROS) Fundamentals'
 WHERE attribute_id = @a_name AND entity_id = @pid AND @pid IS NOT NULL;

-- url_key
SET @a_url := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_key'
   AND entity_type_id=(SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product'));
UPDATE catalog_product_entity_varchar
   SET value = 'robot-operating-system-ros-fundamentals'
 WHERE attribute_id = @a_url AND entity_id = @pid AND @pid IS NOT NULL;

-- meta_title
SET @a_mt := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_title'
   AND entity_type_id=(SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product'));
UPDATE catalog_product_entity_varchar
   SET value = 'Robot Operating System (ROS) Fundamentals'
 WHERE attribute_id = @a_mt AND entity_id = @pid AND @pid IS NOT NULL;

-- meta_description: no day count, <= 255 chars
SET @a_md := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_description'
   AND entity_type_id=(SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product'));
UPDATE catalog_product_entity_varchar
   SET value = 'Robot Operating System (ROS) Fundamentals in Singapore. Build ROS nodes, model and simulate robots in Gazebo and RViz, and program SLAM, navigation and motion in this hands-on course at Tertiary Courses Singapore.'
 WHERE attribute_id = @a_md AND entity_id = @pid AND @pid IS NOT NULL;

-- cover image: repoint at the regenerated PNG (global scope; clear any
-- store-scoped row that would shadow it)
SET @a_ciu := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='course_image_url'
   AND entity_type_id=(SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product'));
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_ciu, 0, @pid,
       'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C914-20260922-151820.png'
 WHERE @pid IS NOT NULL AND @a_ciu IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @pid AND attribute_id = @a_ciu AND store_id <> 0
   AND @pid IS NOT NULL AND @a_ciu IS NOT NULL;

-- Permanent 301s: old slug -> new slug, for the bare URL and each of the three
-- category-prefixed paths C914 is reachable at (categories 3, 56, 217).
SET @sid := (SELECT store_id FROM core_store WHERE store_id > 0 ORDER BY store_id LIMIT 1);

INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT @sid, CONCAT('c914-ros-fundamentals-bare-', @pid),
       'robotics-with-ros.html',
       'robot-operating-system-ros-fundamentals.html',
       0, 'RP', '1528: C914 renamed to Robot Operating System (ROS) Fundamentals'
WHERE @pid IS NOT NULL AND @sid IS NOT NULL;

INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT @sid, CONCAT('c914-ros-fundamentals-cat3-', @pid),
       'adult-training-courses/robotics-with-ros.html',
       'adult-training-courses/robot-operating-system-ros-fundamentals.html',
       0, 'RP', '1528: C914 renamed to Robot Operating System (ROS) Fundamentals'
WHERE @pid IS NOT NULL AND @sid IS NOT NULL;

INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT @sid, CONCAT('c914-ros-fundamentals-cat56-', @pid),
       'iot-robotics-courses-in/robotics-with-ros.html',
       'iot-robotics-courses-in/robot-operating-system-ros-fundamentals.html',
       0, 'RP', '1528: C914 renamed to Robot Operating System (ROS) Fundamentals'
WHERE @pid IS NOT NULL AND @sid IS NOT NULL;

INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT @sid, CONCAT('c914-ros-fundamentals-cat217-', @pid),
       'robot-operating-system-ros-courses/robotics-with-ros.html',
       'robot-operating-system-ros-courses/robot-operating-system-ros-fundamentals.html',
       0, 'RP', '1528: C914 renamed to Robot Operating System (ROS) Fundamentals'
WHERE @pid IS NOT NULL AND @sid IS NOT NULL;

-- Flatten the PRE-EXISTING 301s that still point at the OLD slug, so the
-- historical URLs (ros-for-beginners-914, full-robot-operating-system-ros-*)
-- redirect once to the new slug instead of chaining 301 -> 301.
UPDATE core_url_rewrite
   SET target_path = REPLACE(target_path, 'robotics-with-ros.html',
                             'robot-operating-system-ros-fundamentals.html')
 WHERE is_system = 0
   AND target_path LIKE '%robotics-with-ros.html'
   AND id_path NOT LIKE 'c914-ros-fundamentals-%';
