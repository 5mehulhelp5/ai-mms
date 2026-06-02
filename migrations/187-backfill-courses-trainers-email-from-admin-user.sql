-- Backfill courses_trainers email data from admin_user for the trainer
-- invitation system.
--
-- Background: the trainers EAV multiselect on catalog_product stores option_ids.
-- TrainerInvitationService resolves emails via courses_trainers.relation_id =
-- eav_attribute_option.option_id. Production has 502 EAV trainer options but
-- most have no courses_trainers row, so the invitation queue cannot find emails.
--
-- This migration fills the gap in four passes:
--
--   Pass 1 (INSERT, exact):      EAV option name matches admin_user full name exactly.
--   Pass 2 (INSERT, ACTA-strip): EAV option starts with "ACTA " — strip it, then
--                                match (e.g. "ACTA Patrick Foo" → "Patrick Foo").
--   Pass 3 (UPDATE, exact):      Existing courses_trainers row has no email —
--                                fill from admin_user by exact name.
--   Pass 4 (UPDATE, ACTA-strip): Same but strip "ACTA " prefix before matching.
--
-- Where multiple admin_user accounts share the same full name, the one with the
-- lowest user_id (earliest created) is used — deterministic tie-break.
--
-- Idempotent: INSERTs use LEFT JOIN / WHERE NULL so re-runs are safe.
-- Passes 3+4 only touch rows where email is already empty.

-- Pass 1: INSERT for EAV options with no courses_trainers row — exact name match
INSERT INTO `courses_trainers`
    (relation_id, title, email, status, created_time, update_time)
SELECT
    eao.option_id,
    TRIM(eov.value),
    au.email,
    1,
    NOW(),
    NOW()
FROM eav_attribute_option eao
JOIN eav_attribute a
    ON a.attribute_id = eao.attribute_id AND a.attribute_code = 'trainers'
JOIN eav_attribute_option_value eov
    ON eov.option_id = eao.option_id AND eov.store_id = 0
JOIN admin_user au
    ON au.user_id = (
        SELECT MIN(u.user_id)
        FROM admin_user u
        WHERE LOWER(TRIM(eov.value)) = LOWER(CONCAT(TRIM(u.firstname), ' ', TRIM(u.lastname)))
          AND u.email IS NOT NULL AND u.email != ''
    )
LEFT JOIN courses_trainers ct
    ON ct.relation_id = eao.option_id
WHERE ct.relation_id IS NULL
  AND eov.value IS NOT NULL AND TRIM(eov.value) != '';

-- Pass 2: INSERT for EAV options with "ACTA " prefix and no courses_trainers row
INSERT INTO `courses_trainers`
    (relation_id, title, email, status, created_time, update_time)
SELECT
    eao.option_id,
    TRIM(eov.value),
    au.email,
    1,
    NOW(),
    NOW()
FROM eav_attribute_option eao
JOIN eav_attribute a
    ON a.attribute_id = eao.attribute_id AND a.attribute_code = 'trainers'
JOIN eav_attribute_option_value eov
    ON eov.option_id = eao.option_id AND eov.store_id = 0
   AND eov.value LIKE 'ACTA %'
JOIN admin_user au
    ON au.user_id = (
        SELECT MIN(u.user_id)
        FROM admin_user u
        WHERE LOWER(TRIM(SUBSTRING(eov.value, 6))) = LOWER(CONCAT(TRIM(u.firstname), ' ', TRIM(u.lastname)))
          AND u.email IS NOT NULL AND u.email != ''
    )
LEFT JOIN courses_trainers ct
    ON ct.relation_id = eao.option_id
WHERE ct.relation_id IS NULL
  AND eov.value IS NOT NULL AND TRIM(eov.value) != '';

-- Pass 3: UPDATE existing rows missing email — exact name match
UPDATE `courses_trainers` ct
JOIN (
    SELECT MIN(user_id) AS user_id, LOWER(CONCAT(TRIM(firstname), ' ', TRIM(lastname))) AS full_name, email
    FROM admin_user
    WHERE email IS NOT NULL AND email != ''
    GROUP BY LOWER(CONCAT(TRIM(firstname), ' ', TRIM(lastname)))
) au ON LOWER(TRIM(ct.title)) = au.full_name
SET ct.email = au.email
WHERE (ct.email IS NULL OR ct.email = '')
  AND ct.relation_id > 0;

-- Pass 4: UPDATE existing rows missing email — ACTA-stripped name match
UPDATE `courses_trainers` ct
JOIN (
    SELECT MIN(user_id) AS user_id, LOWER(CONCAT(TRIM(firstname), ' ', TRIM(lastname))) AS full_name, email
    FROM admin_user
    WHERE email IS NOT NULL AND email != ''
    GROUP BY LOWER(CONCAT(TRIM(firstname), ' ', TRIM(lastname)))
) au ON ct.title LIKE 'ACTA %'
   AND LOWER(TRIM(SUBSTRING(ct.title, 6))) = au.full_name
SET ct.email = au.email
WHERE (ct.email IS NULL OR ct.email = '')
  AND ct.relation_id > 0;
