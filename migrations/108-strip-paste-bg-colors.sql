-- Strip the light-grey `background-color` inline styles that have accumulated
-- across catalog_product_entity_text from years of Google-Docs / Word paste
-- contamination. Four observed shades + their `style="..."` wrappers:
--   rgb(221, 221, 221)  -- #dddddd
--   #dddddd
--   #d3d3d3 (lightgrey)
--   #f4f4f4
-- These render as visible light-grey bars on the dark course-edit Quill
-- editor and on the dark course-detail preview, since the page background
-- is slate and the grey is much lighter.
--
-- 816 short_description rows + 232 prerequisite + 1 trainerprofile rows are
-- affected. Two REPLACE() passes per value: first the standalone
-- style attribute (`style="background-color: X;"`), then the mid-style
-- fragment (so compound `style="color:#111;background-color:X;"` also
-- gets neutralised). Idempotent.

-- ── rgb(221, 221, 221) ─────────────────────────────────────────
UPDATE catalog_product_entity_text SET value = REPLACE(value, ' style="background-color: rgb(221, 221, 221);"', '') WHERE value LIKE '%background-color: rgb(221, 221, 221)%';
UPDATE catalog_product_entity_text SET value = REPLACE(value, ' style="background-color: rgb(221, 221, 221)"',  '') WHERE value LIKE '%background-color: rgb(221, 221, 221)%';
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'background-color: rgb(221, 221, 221);', '')       WHERE value LIKE '%background-color: rgb(221, 221, 221)%';
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'background-color: rgb(221, 221, 221)',  '')       WHERE value LIKE '%background-color: rgb(221, 221, 221)%';

-- ── #dddddd ────────────────────────────────────────────────────
UPDATE catalog_product_entity_text SET value = REPLACE(value, ' style="background-color: #dddddd;"', '') WHERE value LIKE '%background-color: #dddddd%';
UPDATE catalog_product_entity_text SET value = REPLACE(value, ' style="background-color: #dddddd"',  '') WHERE value LIKE '%background-color: #dddddd%';
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'background-color: #dddddd;', '')         WHERE value LIKE '%background-color: #dddddd%';
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'background-color: #dddddd',  '')         WHERE value LIKE '%background-color: #dddddd%';

-- ── #d3d3d3 ────────────────────────────────────────────────────
UPDATE catalog_product_entity_text SET value = REPLACE(value, ' style="background-color: #d3d3d3;"', '') WHERE value LIKE '%background-color: #d3d3d3%';
UPDATE catalog_product_entity_text SET value = REPLACE(value, ' style="background-color: #d3d3d3"',  '') WHERE value LIKE '%background-color: #d3d3d3%';
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'background-color: #d3d3d3;', '')         WHERE value LIKE '%background-color: #d3d3d3%';
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'background-color: #d3d3d3',  '')         WHERE value LIKE '%background-color: #d3d3d3%';

-- ── #f4f4f4 ────────────────────────────────────────────────────
UPDATE catalog_product_entity_text SET value = REPLACE(value, ' style="background-color: #f4f4f4;"', '') WHERE value LIKE '%background-color: #f4f4f4%';
UPDATE catalog_product_entity_text SET value = REPLACE(value, ' style="background-color: #f4f4f4"',  '') WHERE value LIKE '%background-color: #f4f4f4%';
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'background-color: #f4f4f4;', '')         WHERE value LIKE '%background-color: #f4f4f4%';
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'background-color: #f4f4f4',  '')         WHERE value LIKE '%background-color: #f4f4f4%';
