-- C203 "What's This Course About": drop the "2-day course" phrase.
--
-- 1512 copied the topic list from the WSQ parent and cleared the day count from
-- meta_description, but short_description keeps its own opener: "This hands-on
-- 2-day course teaches you how to use the Raspberry Pi ...".
--
-- The Sessions (2) and Duration (15 hrs) tiles already state the length, so the
-- prose must not restate it -- a copied day count is exactly what contradicted
-- the tiles on C1234. The parent's own short_description is NOT copied here: it
-- names the WSQ course ("Our WSQ Internet of Things (IoT) Management with
-- Raspberry Pi course ...") and a non-WSQ page must not carry WSQ branding, so
-- only the offending phrase is removed and the existing copy is kept.
--
-- Idempotent: guarded on the phrase, so a re-run matches nothing.
-- Updates EVERY scope row -- a lingering store-scope override would otherwise
-- keep serving the old copy.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C203');
SET @a   := (SELECT attribute_id FROM eav_attribute
              WHERE attribute_code = 'short_description' AND entity_type_id = 4);

UPDATE catalog_product_entity_text
   SET value = REPLACE(value, 'This hands-on 2-day course teaches you',
                              'This hands-on course teaches you')
 WHERE entity_id = @pid
   AND attribute_id = @a
   AND value LIKE '%hands-on 2-day course teaches you%';
