-- Backfill courses_trainers from the eav_attribute_option list of trainer
-- names. The View Trainers admin panel reads from courses_trainers, but
-- historically only the multiselect attribute (eav_attribute_option /
-- eav_attribute_option_value) was kept up to date — leaving the View
-- Trainers panel showing 1 row while the Assign Trainer dropdown showed
-- ~270 trainers. This migration aligns the two: every distinct trainer
-- name in the multiselect now also gets a row in courses_trainers.
--
-- Defensive variant: INSERT IGNORE so any row that hits a UNIQUE / FK /
-- strict-mode constraint is silently skipped instead of aborting the
-- whole migration. Production MySQL is stricter than local MySQL 5.7,
-- so the previous version (plain INSERT + NOT EXISTS) failed there.
-- Idempotent — re-runs are safe; any pre-existing rows just get skipped.

INSERT IGNORE INTO courses_trainers
    (relation_id, title, address, city, zip, country_id, region_id, region,
     email, profile_image, status, trainer_type, gender, linkedin_url,
     telephone, created_time, update_time)
SELECT
    COALESCE(eaov.option_id, 0) AS relation_id,
    TRIM(eaov.value)            AS title,
    ''                          AS address,
    ''                          AS city,
    ''                          AS zip,
    'SG'                        AS country_id,
    ''                          AS region_id,
    ''                          AS region,
    ''                          AS email,
    ''                          AS profile_image,
    1                           AS status,
    CASE
        WHEN eaov.value LIKE 'ACTA %' THEN 'ACLP'
        ELSE 'non-ACLP'
    END                         AS trainer_type,
    ''                          AS gender,
    ''                          AS linkedin_url,
    ''                          AS telephone,
    NOW()                       AS created_time,
    NOW()                       AS update_time
FROM eav_attribute_option_value eaov
INNER JOIN eav_attribute_option eao ON eao.option_id = eaov.option_id
INNER JOIN eav_attribute        ea  ON ea.attribute_id = eao.attribute_id
WHERE ea.attribute_code = 'trainers'
  AND ea.entity_type_id = 4
  AND eaov.store_id = 0
  AND eaov.value IS NOT NULL
  AND TRIM(eaov.value) <> ''
  AND NOT EXISTS (
      SELECT 1 FROM courses_trainers ct
      WHERE LOWER(TRIM(ct.title)) = LOWER(TRIM(eaov.value))
  );
