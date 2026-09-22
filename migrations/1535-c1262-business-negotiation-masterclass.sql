-- C1262: repurpose "Effective Negotiation Training" -> "Business Negotiation Masterclass"
-- Non-WSQ twin of TGS-2023020567 "Unlocking Business Potential with Strategic Negotiation Tactics".
-- 2 days / 15 instructional hours / $700, schedule template B03.
-- Idempotent: every statement is guarded on the current value or uses INSERT ... ON DUPLICATE KEY.
-- SG-only by construction: the SKU C1262 exists only on the SG site.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1262' LIMIT 1);

-- ---------- name ----------
SET @a_name := (SELECT attribute_id FROM eav_attribute a
                JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id AND t.entity_type_code = 'catalog_product'
                WHERE a.attribute_code = 'name');
UPDATE catalog_product_entity_varchar
   SET value = 'Business Negotiation Masterclass'
 WHERE entity_id = @pid AND attribute_id = @a_name;

-- ---------- url_key + 301 from the old slug ----------
SET @a_urlkey := (SELECT attribute_id FROM eav_attribute a
                  JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id AND t.entity_type_code = 'catalog_product'
                  WHERE a.attribute_code = 'url_key');
UPDATE catalog_product_entity_varchar
   SET value = 'business-negotiation-masterclass'
 WHERE entity_id = @pid AND attribute_id = @a_urlkey;

-- The old slug must 301 to the new one. A system row (is_system=1, id_path
-- 'product/<id>') already occupies request_path 'effective-negotiation-training.html',
-- and Magento reclaims that row on the next Catalog URL Rewrites reindex. So write a
-- CUSTOM row (is_system=0) under its own id_path and delete the system squatter, which
-- is the shape that survives a reindex.
DELETE FROM core_url_rewrite
 WHERE request_path = 'effective-negotiation-training.html'
   AND is_system = 1;

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT s.store_id,
       CONCAT('c1262-old-slug-301-', s.store_id),
       'effective-negotiation-training.html',
       'business-negotiation-masterclass.html',
       0, 'RP', 'C1262 repurpose: Effective Negotiation Training -> Business Negotiation Masterclass'
  FROM core_store s
 WHERE s.store_id > 0
ON DUPLICATE KEY UPDATE target_path = VALUES(target_path),
                        options     = VALUES(options),
                        is_system   = 0;

-- category-prefixed variants of the old slug also 301 to the flat new URL
UPDATE core_url_rewrite
   SET target_path = 'business-negotiation-masterclass.html', options = 'RP', is_system = 0
 WHERE request_path LIKE '%/effective-negotiation-training.html';

-- ---------- price: $700 (2 days) - every scope row ----------
SET @a_price := (SELECT attribute_id FROM eav_attribute a
                 JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id AND t.entity_type_code = 'catalog_product'
                 WHERE a.attribute_code = 'price');
UPDATE catalog_product_entity_decimal
   SET value = 700.0000
 WHERE entity_id = @pid AND attribute_id = @a_price;

-- ---------- duration 15 hrs / sessions 2 ----------
SET @a_dur  := (SELECT attribute_id FROM eav_attribute a
                JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id AND t.entity_type_code = 'catalog_product'
                WHERE a.attribute_code = 'duration');
SET @a_sess := (SELECT attribute_id FROM eav_attribute a
                JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id AND t.entity_type_code = 'catalog_product'
                WHERE a.attribute_code = 'sessions');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT e.entity_type_id, @a_dur, 0, @pid, '15'
  FROM catalog_product_entity e WHERE e.entity_id = @pid
ON DUPLICATE KEY UPDATE value = '15';
UPDATE catalog_product_entity_varchar SET value = '15' WHERE entity_id = @pid AND attribute_id = @a_dur;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT e.entity_type_id, @a_sess, 0, @pid, '2'
  FROM catalog_product_entity e WHERE e.entity_id = @pid
ON DUPLICATE KEY UPDATE value = '2';
UPDATE catalog_product_entity_varchar SET value = '2' WHERE entity_id = @pid AND attribute_id = @a_sess;

-- ---------- meta_title / meta_description (no day count) ----------
SET @a_mtitle := (SELECT attribute_id FROM eav_attribute a
                  JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id AND t.entity_type_code = 'catalog_product'
                  WHERE a.attribute_code = 'meta_title');
SET @a_mdesc  := (SELECT attribute_id FROM eav_attribute a
                  JOIN eav_entity_type t ON t.entity_type_id = a.entity_type_id AND t.entity_type_code = 'catalog_product'
                  WHERE a.attribute_code = 'meta_description');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT e.entity_type_id, @a_mtitle, 0, @pid, 'Business Negotiation Masterclass'
  FROM catalog_product_entity e WHERE e.entity_id = @pid
ON DUPLICATE KEY UPDATE value = 'Business Negotiation Masterclass';
UPDATE catalog_product_entity_varchar SET value = 'Business Negotiation Masterclass'
 WHERE entity_id = @pid AND attribute_id = @a_mtitle;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT e.entity_type_id, @a_mdesc, 0, @pid,
       'Master business negotiation - preparation, BATNA, anchoring, framing, concessions and closing - through ten real-world activities at Tertiary Courses Singapore.'
  FROM catalog_product_entity e WHERE e.entity_id = @pid
ON DUPLICATE KEY UPDATE value = VALUES(value);
UPDATE catalog_product_entity_varchar
   SET value = 'Master business negotiation - preparation, BATNA, anchoring, framing, concessions and closing - through ten real-world activities at Tertiary Courses Singapore.'
 WHERE entity_id = @pid AND attribute_id = @a_mdesc;

-- ---------- funding block: flatten the 301 to the WSQ parent's direct URL ----------
UPDATE cms_block
   SET content = '<p>No funding is available for this course</p> <p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-unlocking-business-potential-with-strategic-negotiation-tactics.html" title="WSQ - Unlocking Business Potential with Strategic Negotiation Tactics">WSQ - Unlocking Business Potential with Strategic Negotiation Tactics</a></span></p>'
 WHERE identifier = 'course_C1262_funding_and_grant';
