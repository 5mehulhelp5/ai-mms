-- Strip the trailing "Guided Farm Tour" image-gallery section from product
-- 1064 (WSQ Basic Urban Farming with Hydroponics). The four <img> URLs in
-- that section are now surfaced via the right-column Photo Gallery instead,
-- so the in-description copy is redundant (and rendered as broken icons
-- locally because the wysiwyg files were missing).
--
-- Idempotent: keyed on MD5 of the current description so a second run is a
-- no-op once applied. If the description is later edited, this migration
-- will silently skip rather than truncate unexpected content.

UPDATE catalog_product_entity_text t
JOIN eav_attribute a ON a.attribute_id = t.attribute_id
SET t.value = TRIM(SUBSTRING_INDEX(t.value, '<h2>Guided Farm Tour', 1))
WHERE t.entity_id = 1064
  AND a.attribute_code = 'description'
  AND MD5(t.value) = '29ca099ca586c4d67434e244cde064d7';
