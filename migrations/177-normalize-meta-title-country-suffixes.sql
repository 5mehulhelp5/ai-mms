-- Bulk-normalise every product meta_title on every country store view so it
-- ends with "| Tertiary Courses <CorrectCountry>". Pre-migration audit
-- (2026-05-29) found ~508 titles wrong across all 6 stores:
--   - 65 had a country suffix pointing at the wrong country
--     (e.g. "Tertiary Courses South Africa" on Bhutan,
--           "Tertiary Courses Singapore Ghana" double-country gaffe,
--           "Tertiary Courses Nigera" / "Malaysi" typos)
--   - 443 had NO country suffix at all (mostly Malaysia, 384 rows)
--
-- Strategy per row:
--   - If value already ends with the correct "| Tertiary Courses <country>",
--     leave alone.
--   - If value contains "| Tertiary Courses <anything>", lop off that segment
--     and re-append the correct suffix.
--   - If value has no "| Tertiary Courses" segment at all, append " | Tertiary
--     Courses <country>".
--
-- SUBSTRING_INDEX(value, '| Tertiary Courses', 1) gives the substring before
-- the FIRST occurrence, which is what we want — handles the
-- "| Tertiary Courses Singapore Ghana" double-country shape too (the whole
-- bad tail gets discarded).
--
-- TRIM keeps the join clean when SUBSTRING_INDEX leaves a trailing space.
--
-- Idempotent: each UPDATE's WHERE clause filters out rows that already match
-- the target shape, so re-runs are no-ops.

SET @meta_title_id := (SELECT attribute_id FROM eav_attribute
    WHERE entity_type_id = 4 AND attribute_code = 'meta_title');

-- ===== Store 1: Singapore =====
UPDATE catalog_product_entity_varchar
SET value = CONCAT(TRIM(TRAILING ' ' FROM TRIM(SUBSTRING_INDEX(value, '| Tertiary Courses', 1))), ' | Tertiary Courses Singapore')
WHERE attribute_id = @meta_title_id AND store_id = 1
  AND value LIKE '%| Tertiary Courses%'
  AND value NOT LIKE '%| Tertiary Courses Singapore';

UPDATE catalog_product_entity_varchar
SET value = CONCAT(TRIM(value), ' | Tertiary Courses Singapore')
WHERE attribute_id = @meta_title_id AND store_id = 1
  AND value <> '' AND value IS NOT NULL
  AND value NOT LIKE '%Tertiary Courses%';

-- ===== Store 2: Malaysia =====
UPDATE catalog_product_entity_varchar
SET value = CONCAT(TRIM(TRAILING ' ' FROM TRIM(SUBSTRING_INDEX(value, '| Tertiary Courses', 1))), ' | Tertiary Courses Malaysia')
WHERE attribute_id = @meta_title_id AND store_id = 2
  AND value LIKE '%| Tertiary Courses%'
  AND value NOT LIKE '%| Tertiary Courses Malaysia';

UPDATE catalog_product_entity_varchar
SET value = CONCAT(TRIM(value), ' | Tertiary Courses Malaysia')
WHERE attribute_id = @meta_title_id AND store_id = 2
  AND value <> '' AND value IS NOT NULL
  AND value NOT LIKE '%Tertiary Courses%';

-- ===== Store 3: Ghana =====
UPDATE catalog_product_entity_varchar
SET value = CONCAT(TRIM(TRAILING ' ' FROM TRIM(SUBSTRING_INDEX(value, '| Tertiary Courses', 1))), ' | Tertiary Courses Ghana')
WHERE attribute_id = @meta_title_id AND store_id = 3
  AND value LIKE '%| Tertiary Courses%'
  AND value NOT LIKE '%| Tertiary Courses Ghana';

UPDATE catalog_product_entity_varchar
SET value = CONCAT(TRIM(value), ' | Tertiary Courses Ghana')
WHERE attribute_id = @meta_title_id AND store_id = 3
  AND value <> '' AND value IS NOT NULL
  AND value NOT LIKE '%Tertiary Courses%';

-- ===== Store 4: Nigeria =====
UPDATE catalog_product_entity_varchar
SET value = CONCAT(TRIM(TRAILING ' ' FROM TRIM(SUBSTRING_INDEX(value, '| Tertiary Courses', 1))), ' | Tertiary Courses Nigeria')
WHERE attribute_id = @meta_title_id AND store_id = 4
  AND value LIKE '%| Tertiary Courses%'
  AND value NOT LIKE '%| Tertiary Courses Nigeria';

UPDATE catalog_product_entity_varchar
SET value = CONCAT(TRIM(value), ' | Tertiary Courses Nigeria')
WHERE attribute_id = @meta_title_id AND store_id = 4
  AND value <> '' AND value IS NOT NULL
  AND value NOT LIKE '%Tertiary Courses%';

-- ===== Store 5: Bhutan =====
UPDATE catalog_product_entity_varchar
SET value = CONCAT(TRIM(TRAILING ' ' FROM TRIM(SUBSTRING_INDEX(value, '| Tertiary Courses', 1))), ' | Tertiary Courses Bhutan')
WHERE attribute_id = @meta_title_id AND store_id = 5
  AND value LIKE '%| Tertiary Courses%'
  AND value NOT LIKE '%| Tertiary Courses Bhutan';

UPDATE catalog_product_entity_varchar
SET value = CONCAT(TRIM(value), ' | Tertiary Courses Bhutan')
WHERE attribute_id = @meta_title_id AND store_id = 5
  AND value <> '' AND value IS NOT NULL
  AND value NOT LIKE '%Tertiary Courses%';

-- ===== Store 6: India =====
UPDATE catalog_product_entity_varchar
SET value = CONCAT(TRIM(TRAILING ' ' FROM TRIM(SUBSTRING_INDEX(value, '| Tertiary Courses', 1))), ' | Tertiary Courses India')
WHERE attribute_id = @meta_title_id AND store_id = 6
  AND value LIKE '%| Tertiary Courses%'
  AND value NOT LIKE '%| Tertiary Courses India';

UPDATE catalog_product_entity_varchar
SET value = CONCAT(TRIM(value), ' | Tertiary Courses India')
WHERE attribute_id = @meta_title_id AND store_id = 6
  AND value <> '' AND value IS NOT NULL
  AND value NOT LIKE '%Tertiary Courses%';
