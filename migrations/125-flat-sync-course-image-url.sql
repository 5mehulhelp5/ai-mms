-- Follow-up to migration 124: propagate course_image_url from EAV into the
-- per-store flat catalog tables. The storefront list/grid renders from
-- catalog_product_flat_<store_id>, NOT from EAV directly — without this
-- sync the new R2 URLs sit in the EAV row but the cards still show the
-- placeholder image (Infortis_Image helper reads $product->getData(...)
-- which on a flat-collection product reflects the flat row, not EAV).
--
-- A full `php shell/indexer.php --reindex catalog_product_flat` would do
-- this and more, but we don't have a shell hook during deploy — direct
-- column UPDATEs are the supported workaround for narrow attribute syncs.
--
-- Idempotent: re-running it is a no-op when EAV and flat already match.

SET @aid := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='course_image_url' LIMIT 1);

UPDATE catalog_product_flat_1 f
JOIN catalog_product_entity_varchar v
       ON v.entity_id = f.entity_id AND v.attribute_id = @aid AND v.store_id = 0
SET f.course_image_url = v.value
WHERE @aid IS NOT NULL AND (f.course_image_url IS NULL OR f.course_image_url <> v.value);

UPDATE catalog_product_flat_2 f
JOIN catalog_product_entity_varchar v
       ON v.entity_id = f.entity_id AND v.attribute_id = @aid AND v.store_id = 0
SET f.course_image_url = v.value
WHERE @aid IS NOT NULL AND (f.course_image_url IS NULL OR f.course_image_url <> v.value);

UPDATE catalog_product_flat_3 f
JOIN catalog_product_entity_varchar v
       ON v.entity_id = f.entity_id AND v.attribute_id = @aid AND v.store_id = 0
SET f.course_image_url = v.value
WHERE @aid IS NOT NULL AND (f.course_image_url IS NULL OR f.course_image_url <> v.value);

UPDATE catalog_product_flat_4 f
JOIN catalog_product_entity_varchar v
       ON v.entity_id = f.entity_id AND v.attribute_id = @aid AND v.store_id = 0
SET f.course_image_url = v.value
WHERE @aid IS NOT NULL AND (f.course_image_url IS NULL OR f.course_image_url <> v.value);

UPDATE catalog_product_flat_5 f
JOIN catalog_product_entity_varchar v
       ON v.entity_id = f.entity_id AND v.attribute_id = @aid AND v.store_id = 0
SET f.course_image_url = v.value
WHERE @aid IS NOT NULL AND (f.course_image_url IS NULL OR f.course_image_url <> v.value);

UPDATE catalog_product_flat_6 f
JOIN catalog_product_entity_varchar v
       ON v.entity_id = f.entity_id AND v.attribute_id = @aid AND v.store_id = 0
SET f.course_image_url = v.value
WHERE @aid IS NOT NULL AND (f.course_image_url IS NULL OR f.course_image_url <> v.value);

UPDATE catalog_product_flat_7 f
JOIN catalog_product_entity_varchar v
       ON v.entity_id = f.entity_id AND v.attribute_id = @aid AND v.store_id = 0
SET f.course_image_url = v.value
WHERE @aid IS NOT NULL AND (f.course_image_url IS NULL OR f.course_image_url <> v.value);

-- Bust block_html and FPC caches so storefront re-renders. core_cache_tag
-- maps cache keys to product/category tags; nuking it forces a regen on
-- next request without dropping the whole core_cache table.
TRUNCATE TABLE core_cache_tag;
