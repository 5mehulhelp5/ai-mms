-- 1406: C1417 "Claude Code Masterclass" -- align the non-WSQ course with its
--       WSQ parent TGS-2025052468 "WSQ - Agentic AI Applications with Claude Code".
--
-- Four coupled changes, all on C1417 only:
--
--   1. Schedule template   B17 Tues-Wed/Sat-Sun 4th wk  ->  A08 Wed/Sun 2nd wk
--   2. Course Date rows    the 17 B17 two-day pairs     ->  the WSQ parent's 25 A08 dates
--   3. Course Fee          $700.00                      ->  $350.00
--   4. Class info          2 sessions / 15 hrs          ->  1 session / 7.5 hrs
--
-- WHY THE TEMPLATE CODE, NOT THE WEEKDAY NAMES
-- The WSQ catalogue prefixes templates "(SG) WSQ-"; the non-WSQ catalogue uses
-- the bare code. The counterpart is the one sharing the CODE:
--
--     (SG) WSQ-A08 Wed/Sat 2nd wk   ->   A08 Wed/Sun 2nd wk
--
-- The day names deliberately differ (WSQ-A08 runs its second day Sat, non-WSQ
-- A08 runs Sun). Matching on days lands the course on the wrong template.
-- C1417 sat on B17 -- a leftover from the course this product record previously
-- held, not the A08 its WSQ parent runs on.
--
-- WHY THE DATE ROWS ARE COPIED EXPLICITLY
-- custom_options_relation.group_id is only a LABEL saying which calendar pattern
-- a course follows; each course owns its own catalog_product_option_type_value
-- rows. Repointing group_id alone would relabel C1417 as A08 while leaving the
-- B17 two-day dates in place. The admin's "Switch Template" button rewrites both;
-- this migration does the same in SQL. reg_course is the column that actually
-- drives the schedule (the title is display text), so it is copied too.
--
-- Duration is 7.5 hrs, NOT the WSQ parent's 8 -- non-WSQ runs a 1-day 7.5-hour
-- class (no assessment slot). Sessions/duration are stored as bare numbers; the
-- product template appends the " days" / " hrs" suffix.
--
-- Orders are unaffected: Magento snapshots chosen options as serialized text on
-- sales_flat_order_item, so rewriting option values never rewrites order history.
-- C1417's 10 order items are all 2023-24 rows referencing long-deleted
-- option_type_ids from the product record's previous course anyway.
--
-- Idempotent: every statement is keyed off the live data, and re-running copies
-- the same WSQ rows again. IDs are resolved by SKU, never hardcoded.

-- ---------------------------------------------------------------------------
-- Resolve ids by SKU (never hardcode entity_ids -- they differ per instance).
-- ---------------------------------------------------------------------------
SET @nonwsq_id = (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C1417');
SET @wsq_id    = (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025052468');

SET @grp_a08 = (SELECT group_id FROM custom_options_group
                 WHERE title NOT LIKE '(SG)%' AND title LIKE 'A08 %' LIMIT 1);

SET @opt_nonwsq = (SELECT o.option_id FROM catalog_product_option o
                     JOIN catalog_product_option_title t
                       ON t.option_id = o.option_id AND t.store_id = 0
                    WHERE o.product_id = @nonwsq_id AND t.title LIKE '%Course Date%' LIMIT 1);
SET @opt_wsq    = (SELECT o.option_id FROM catalog_product_option o
                     JOIN catalog_product_option_title t
                       ON t.option_id = o.option_id AND t.store_id = 0
                    WHERE o.product_id = @wsq_id AND t.title LIKE '%Course Date%' LIMIT 1);

-- Guard: if any lookup missed (course absent on this instance, or no A08
-- template), @ok is 0 and every write below becomes a no-op rather than
-- writing NULLs or nuking an unrelated product's options.
SET @ok = IF(@nonwsq_id IS NOT NULL AND @wsq_id IS NOT NULL AND @grp_a08 IS NOT NULL
             AND @opt_nonwsq IS NOT NULL AND @opt_wsq IS NOT NULL, 1, 0);

-- ---------------------------------------------------------------------------
-- 1. Schedule template -> A08. Repoints every option row this course has.
-- ---------------------------------------------------------------------------
SET @sql = IF(@ok,
  'UPDATE custom_options_relation SET group_id = @grp_a08 WHERE product_id = @nonwsq_id',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ---------------------------------------------------------------------------
-- 2. Course Date rows -> the WSQ parent's A08 dates.
--    Drop the old child rows (price + title) before the values they hang off.
-- ---------------------------------------------------------------------------
SET @sql = IF(@ok,
  'DELETE p FROM catalog_product_option_type_price p
     JOIN catalog_product_option_type_value v ON v.option_type_id = p.option_type_id
    WHERE v.option_id = @opt_nonwsq', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@ok,
  'DELETE t FROM catalog_product_option_type_title t
     JOIN catalog_product_option_type_value v ON v.option_type_id = t.option_type_id
    WHERE v.option_id = @opt_nonwsq', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@ok,
  'DELETE FROM catalog_product_option_type_value WHERE option_id = @opt_nonwsq', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Copy the WSQ parent's rows. sort_order is carried across so it can key the
-- title/price joins below (option_type_id is auto-assigned on insert).
SET @sql = IF(@ok,
  'INSERT INTO catalog_product_option_type_value
     (option_id, sku, sort_order, reg_course, customoptions_qty, `default`,
      in_group_id, dependent_ids, weight, admin_managed)
   SELECT @opt_nonwsq, v.sku, v.sort_order, v.reg_course, v.customoptions_qty,
          v.`default`, v.in_group_id, v.dependent_ids, v.weight, v.admin_managed
     FROM catalog_product_option_type_value v
    WHERE v.option_id = @opt_wsq
    ORDER BY v.sort_order', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@ok,
  'INSERT INTO catalog_product_option_type_title (option_type_id, store_id, title)
   SELECT nv.option_type_id, 0, ot.title
     FROM catalog_product_option_type_value nv
     JOIN catalog_product_option_type_value sv
       ON sv.option_id = @opt_wsq AND sv.sort_order = nv.sort_order
     JOIN catalog_product_option_type_title ot
       ON ot.option_type_id = sv.option_type_id AND ot.store_id = 0
    WHERE nv.option_id = @opt_nonwsq', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Date rows carry no surcharge; the course fee is the product price.
SET @sql = IF(@ok,
  'INSERT INTO catalog_product_option_type_price (option_type_id, store_id, price, price_type)
   SELECT nv.option_type_id, 0, 0.0000, ''fixed''
     FROM catalog_product_option_type_value nv
    WHERE nv.option_id = @opt_nonwsq', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ---------------------------------------------------------------------------
-- 3. Course Fee -> $350.00 (GST-exclusive; the theme derives the incl. figure).
-- ---------------------------------------------------------------------------
SET @attr_price = (SELECT attribute_id FROM eav_attribute
                    WHERE attribute_code = 'price'
                      AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type
                                             WHERE entity_type_code = 'catalog_product'));
SET @sql = IF(@ok,
  'UPDATE catalog_product_entity_decimal SET value = 350.0000
    WHERE entity_id = @nonwsq_id AND attribute_id = @attr_price AND store_id = 0', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ---------------------------------------------------------------------------
-- 4. Class info -> 1 session / 7.5 hrs.
-- ---------------------------------------------------------------------------
SET @attr_sessions = (SELECT attribute_id FROM eav_attribute
                       WHERE attribute_code = 'sessions'
                         AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type
                                                WHERE entity_type_code = 'catalog_product'));
SET @attr_duration = (SELECT attribute_id FROM eav_attribute
                       WHERE attribute_code = 'duration'
                         AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type
                                                WHERE entity_type_code = 'catalog_product'));

SET @sql = IF(@ok AND @attr_sessions IS NOT NULL,
  'UPDATE catalog_product_entity_varchar SET value = ''1''
    WHERE entity_id = @nonwsq_id AND attribute_id = @attr_sessions AND store_id = 0', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@ok AND @attr_duration IS NOT NULL,
  'UPDATE catalog_product_entity_varchar SET value = ''7.5''
    WHERE entity_id = @nonwsq_id AND attribute_id = @attr_duration AND store_id = 0', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
