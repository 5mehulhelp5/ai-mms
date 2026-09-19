-- 1457: C744 "Claude Design for UX/UI" -- the Sessions tile still reads 2.
--
-- 1442 set duration = 7.5 (1 day) and the price to $350, but `sessions` was
-- left on the 2 it inherited from the retired 2-day certification course. The
-- product page therefore advertised "Sessions 2 days" against its own 7.5-hour
-- Duration tile -- the C1234 failure mode named in the wsq-to-non-wsq skill §9.
--
-- Verified on prod before shipping: short_description and description already
-- carry the copy derived from the WSQ parent (TGS-2026064709), 4 topics against
-- the parent's 4, and meta_description already says "1-day". `sessions` was the
-- only surface still stating the old day count.
--
-- Idempotent. Store scope 0, per-store overrides cleared.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C744');
SET @a_sess := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='sessions');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sess, 0, @e, '1' FROM dual WHERE @e IS NOT NULL AND @a_sess IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND attribute_id=@a_sess AND store_id<>0
  AND @e IS NOT NULL AND @a_sess IS NOT NULL;
