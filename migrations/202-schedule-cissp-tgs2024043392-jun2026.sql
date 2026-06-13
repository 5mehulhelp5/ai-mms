-- Add SG evening-class schedule to WSQ CISSP (TGS-2024043392).
--
-- Business context: TGS- courses are skipped by class-formation (external
-- SkillsFuture system), so a "schedule" the learner can register for is a
-- Course Date custom-option value on the product. This adds:
--   * Course Date value  "22 Jun-1 Jul 2026 (Mahesh)"   (trainer: Mahesh)
--   * Course Time value  "6:00pm - 10:00pm"             (6PM-10PM evening run)
--
-- Product TGS-2024043392 lives in the base (SG) website only, so store_id=0
-- values are SG-scoped in effect. Option IDs are resolved by SKU+title so the
-- migration is portable across local/prod auto-increment IDs. Idempotent:
-- each value is inserted only when no value with that title already exists,
-- and the title/price rows attach only when a fresh value row was created.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024043392');

SET @date_opt := (
  SELECT o.option_id FROM catalog_product_option o
  JOIN catalog_product_option_title ot ON ot.option_id = o.option_id AND ot.store_id = 0
  WHERE o.product_id = @pid AND ot.title = 'Course Date' LIMIT 1
);

SET @time_opt := (
  SELECT o.option_id FROM catalog_product_option o
  JOIN catalog_product_option_title ot ON ot.option_id = o.option_id AND ot.store_id = 0
  WHERE o.product_id = @pid AND ot.title = 'Course Time' LIMIT 1
);

-- ---------- Course Date: "22 Jun-1 Jul 2026 (Mahesh)" ----------
-- sort_order 173 places it chronologically between the 6/13/.. Jun (172) and
-- 29 Jun-3 Jul (174) entries already present.
-- reg_course holds the machine-readable start date in m/d/y (22 Jun 2026);
-- dependent_ids is set empty to mirror the canonical "+ Add session" writer
-- (CoursesaveController). Both columns are NOT NULL without a default, so they
-- must be explicit under apply.php's strict-mode PDO connection.
INSERT INTO catalog_product_option_type_value (option_id, sku, sort_order, reg_course, dependent_ids)
SELECT @date_opt, '', 173, '6/22/26', '' FROM dual
WHERE @date_opt IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM catalog_product_option_type_value v
    JOIN catalog_product_option_type_title vt ON vt.option_type_id = v.option_type_id AND vt.store_id = 0
    WHERE v.option_id = @date_opt AND vt.title = '22 Jun-1 Jul 2026 (Mahesh)'
  );

SET @date_val := IF(ROW_COUNT() > 0, LAST_INSERT_ID(), NULL);

INSERT INTO catalog_product_option_type_title (option_type_id, store_id, title)
SELECT @date_val, 0, '22 Jun-1 Jul 2026 (Mahesh)' FROM dual WHERE @date_val IS NOT NULL;

INSERT INTO catalog_product_option_type_price (option_type_id, store_id, price, price_type)
SELECT @date_val, 0, 0.0000, 'fixed' FROM dual WHERE @date_val IS NOT NULL;

-- ---------- Course Time: "6:00pm - 10:00pm" ----------
INSERT INTO catalog_product_option_type_value (option_id, sku, sort_order, reg_course, dependent_ids)
SELECT @time_opt, '', 2, '', '' FROM dual
WHERE @time_opt IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM catalog_product_option_type_value v
    JOIN catalog_product_option_type_title vt ON vt.option_type_id = v.option_type_id AND vt.store_id = 0
    WHERE v.option_id = @time_opt AND vt.title = '6:00pm - 10:00pm'
  );

SET @time_val := IF(ROW_COUNT() > 0, LAST_INSERT_ID(), NULL);

INSERT INTO catalog_product_option_type_title (option_type_id, store_id, title)
SELECT @time_val, 0, '6:00pm - 10:00pm' FROM dual WHERE @time_val IS NOT NULL;

INSERT INTO catalog_product_option_type_price (option_type_id, store_id, price, price_type)
SELECT @time_val, 0, 0.0000, 'fixed' FROM dual WHERE @time_val IS NOT NULL;
