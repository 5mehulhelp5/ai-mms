-- Malaysia store: standardise the trainee-name textarea options to match SG.
--
-- MY product pages currently expose two textareas:
--   1. "Name(s) on Certificate"                              (type=area, REQUIRED)
--   2. "Additional Message or Emails for Course Notification" (type=area, optional)
--
-- SG exposes just one — "Add your company trainee names (Optional)" (optional).
-- The product team wants MY to mirror SG.
--
-- Strategy:
--   For products that live on the Malaysia website (cpw.website_id = 2) AND are
--   NOT also on the SG website (website_id = 1):
--     - Delete the "Additional Message…" option outright (option + titles + prices).
--     - Rename the "Name(s) on Certificate" option to
--       "Add your company trainee names (Optional)" and set is_require = 0.
--
--   Products that live on BOTH MY and SG are skipped — SG owns the option in
--   that case and changes would affect the SG storefront. There are currently
--   2 such products (see WHERE NOT EXISTS guard); operations can hand-edit
--   those in admin if needed.
--
-- Idempotent: the UPDATE/DELETE filters key off the original titles, so a
-- second run finds nothing to change.

-- ---------------------------------------------------------------------------
-- 1. Drop the "Additional Message or Emails for Course Notification" option
--    on MY-only products. Delete dependent rows first (no FK ON DELETE CASCADE
--    on this schema, so child tables must be cleaned explicitly).
-- ---------------------------------------------------------------------------
CREATE TEMPORARY TABLE _my_drop_options AS
SELECT DISTINCT cpo.option_id
FROM catalog_product_option cpo
JOIN catalog_product_option_title cpot
    ON cpot.option_id = cpo.option_id AND cpot.store_id = 0
JOIN catalog_product_website cpw_my
    ON cpw_my.product_id = cpo.product_id AND cpw_my.website_id = 2
WHERE cpot.title = 'Additional Message or Emails for Course Notification'
    AND NOT EXISTS (
        SELECT 1 FROM catalog_product_website cpw_sg
        WHERE cpw_sg.product_id = cpo.product_id AND cpw_sg.website_id = 1
    );

DELETE FROM catalog_product_option_title
WHERE option_id IN (SELECT option_id FROM _my_drop_options);

DELETE FROM catalog_product_option_price
WHERE option_id IN (SELECT option_id FROM _my_drop_options);

DELETE FROM catalog_product_option
WHERE option_id IN (SELECT option_id FROM _my_drop_options);

DROP TEMPORARY TABLE _my_drop_options;

-- ---------------------------------------------------------------------------
-- 2. Rename "Name(s) on Certificate" to the SG-style title and relax the
--    required flag, on MY-only products.
-- ---------------------------------------------------------------------------
CREATE TEMPORARY TABLE _my_rename_options AS
SELECT DISTINCT cpo.option_id
FROM catalog_product_option cpo
JOIN catalog_product_option_title cpot
    ON cpot.option_id = cpo.option_id AND cpot.store_id = 0
JOIN catalog_product_website cpw_my
    ON cpw_my.product_id = cpo.product_id AND cpw_my.website_id = 2
WHERE cpot.title = 'Name(s) on Certificate'
    AND NOT EXISTS (
        SELECT 1 FROM catalog_product_website cpw_sg
        WHERE cpw_sg.product_id = cpo.product_id AND cpw_sg.website_id = 1
    );

UPDATE catalog_product_option_title
SET title = 'Add your company trainee names (Optional)'
WHERE option_id IN (SELECT option_id FROM _my_rename_options)
    AND title = 'Name(s) on Certificate';

UPDATE catalog_product_option
SET is_require = 0
WHERE option_id IN (SELECT option_id FROM _my_rename_options)
    AND is_require = 1;

DROP TEMPORARY TABLE _my_rename_options;
