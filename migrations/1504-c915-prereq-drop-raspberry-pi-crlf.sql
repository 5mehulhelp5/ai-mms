-- C915 — final follow-up: 1502/1503 no-opped because the line endings were wrong.
--
-- Ground truth from HEX(SUBSTRING(...)): the stored blob uses CRLF (0x0D 0x0A),
-- not LF and not a literal backslash-n. Built here with CHAR(13),CHAR(10) so the
-- pattern is explicit in the SQL and cannot be mangled by .gitattributes, which
-- LF-normalises migrations/*.sql.
--
-- Drops the stale "Raspberry Pi 4" software requirement (left over from an
-- unrelated course; PL-400 needs no Raspberry Pi). The Hardware line
-- (Windows or Mac laptops) is the real requirement and is kept.
--
-- Idempotent: the WHERE guard makes a re-run a no-op once applied.

UPDATE catalog_product_entity_text t
  JOIN eav_attribute a ON a.attribute_id = t.attribute_id
                      AND a.attribute_code = 'prerequisite'
  JOIN eav_entity_type et ON et.entity_type_id = a.entity_type_id
                         AND et.entity_type_code = 'catalog_product'
  JOIN catalog_product_entity e ON e.entity_id = t.entity_id AND e.sku = 'C915'
   SET t.value = REPLACE(
         t.value,
         CONCAT('<p><strong>Software:</strong></p>', CHAR(13), CHAR(10),
                '<ul>', CHAR(13), CHAR(10),
                '<li><a href="https://www.tertiaryrobotics.com/raspberry-pi-products/raspberry-pi-4.html" title="Raspberry PI 4" target="_blank">Raspberry Pi 4</a></li>', CHAR(13), CHAR(10),
                '</ul>', CHAR(13), CHAR(10)),
         '')
 WHERE t.value LIKE '%raspberry-pi-4%';
