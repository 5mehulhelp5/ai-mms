-- C1433 course topics: copy from the WSQ parent TGS-2023037468.
--
-- The conversion replicates the parent's syllabus, so both catalogue entries must
-- describe the same course. A recycled product entity otherwise keeps the previous
-- course's topics, which read plausibly and survive every courseware scan (those
-- read artifacts, not the storefront) -- incident C1234 (2026-09-19).
--
-- `short_description` ("What's This Course About") is ALREADY byte-identical to the
-- parent's, so only `description` (the topic list, carrying the <!-- LSN_DATA --> JSON)
-- is copied here.
--
-- The parent's topic text was checked to contain no WSQ/SSG/SkillsFuture/funding
-- wording and no day count, so nothing needs scrubbing on the way across.
--
-- Copied row-to-row rather than pasted as a literal, so no HTML escaping is involved.
-- Idempotent: the WHERE excludes rows that already match the parent.

SET @pid_new := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C1433');
SET @pid_wsq := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023037468');

SET @a_desc := (SELECT attribute_id FROM eav_attribute
                 WHERE attribute_code = 'description' AND entity_type_id = 4);

SET @src := (SELECT value FROM catalog_product_entity_text
              WHERE entity_id = @pid_wsq AND attribute_id = @a_desc AND store_id = 0);

UPDATE catalog_product_entity_text
   SET value = @src
 WHERE entity_id = @pid_new
   AND attribute_id = @a_desc
   AND store_id = 0
   AND @src IS NOT NULL
   AND @src <> ''
   AND value <> @src;
