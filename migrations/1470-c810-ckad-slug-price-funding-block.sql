-- C810 Certified Kubernetes Application Developer (CKAD) Training
-- Non-WSQ twin of TGS-2025053212. Applied live on SG prod 2026-09-21; this
-- migration keeps a rebuilt DB in the same state. SG-only (store guard).
--
--  1. url_key slug: serve the bare title slug (the -1219 suffix was only in
--     effect because a manual 301 row squatted the bare slug for the WSQ
--     product 255). Old -1219 URL 301s to it.
--  2. price 1600 -> 1400.
--  3. Funding block redirects to the funded WSQ twin.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

-- 1a. remove the manual 301 that squatted the bare slug for the WSQ product
DELETE FROM core_url_rewrite
 WHERE @sg = 1
   AND request_path = 'certified-kubernetes-application-developer-ckad-training.html'
   AND is_system = 0
   AND product_id = 255;

-- 1b. point C810's system rewrite at the bare slug
UPDATE core_url_rewrite
   SET request_path = 'certified-kubernetes-application-developer-ckad-training.html'
 WHERE @sg = 1 AND id_path = 'product/810' AND is_system = 1;

-- 1c. 301 the old suffixed URL at the new one
INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1,
       CONCAT('manual-301-', MD5('certified-kubernetes-application-developer-ckad-training-1219.html'), '-1'),
       'certified-kubernetes-application-developer-ckad-training-1219.html',
       'certified-kubernetes-application-developer-ckad-training.html', 0, 'RP'
 WHERE @sg = 1
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
                   WHERE x.request_path = 'certified-kubernetes-application-developer-ckad-training-1219.html'
                     AND x.store_id = 1 AND x.is_system = 0);

UPDATE core_url_rewrite
   SET target_path = 'certified-kubernetes-application-developer-ckad-training.html',
       options = 'RP', is_system = 0
 WHERE @sg = 1
   AND request_path = 'certified-kubernetes-application-developer-ckad-training-1219.html'
   AND store_id = 1 AND is_system = 0;

-- 2. course fee 1600 -> 1400 (store 0 / default scope)
UPDATE catalog_product_entity_decimal
   SET value = 1400.0000
 WHERE @sg = 1
   AND entity_id = 810
   AND store_id = 0
   AND attribute_id = (SELECT attribute_id FROM eav_attribute
                        WHERE attribute_code = 'price' AND entity_type_id = 4);

-- 3. funding block -> point at the funded WSQ twin.
--    Content-only UPDATE: never ->save() a cms/block model, it wipes
--    cms_block_store and 404s the page (feedback_cms_model_save_wipes_store_mapping).
UPDATE cms_block
   SET content = CONCAT(
     '<p>This course is not funded. A <strong>WSQ-funded version</strong> of the same ',
     'course is available, with SkillsFuture Credit, PSEA, SFEC and Absentee Payroll support ',
     'for eligible learners.</p>',
     '<p><a href="https://www.tertiarycourses.com.sg/wsq-certified-kubernetes-application-developer-ckad-training.html">',
     'View the WSQ Certified Kubernetes Application Developer (CKAD) Training course &raquo;</a></p>')
 WHERE @sg = 1
   AND identifier = 'course_C810_funding_and_grant';
