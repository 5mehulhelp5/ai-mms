-- MMD_Leads: track the storefront contact-form auto-reply.
--
-- When a visitor submits the Contact Us form, MMD now sends them an
-- automatic acknowledgement email (matched course info). These two
-- columns record whether that auto-reply went out, so operators can spot
-- failed sends in the Tertiary -> Leads grid.
--
--   auto_reply_status : pending | sent | failed | skipped
--   auto_replied_at   : timestamp of a successful auto-reply
--
-- Idempotent: INFORMATION_SCHEMA guard around each ADD COLUMN (the runner
-- splits on ';' at end-of-line, so no stored procedures).

SET @has := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME = 'mmd_lead'
               AND COLUMN_NAME = 'auto_reply_status');
SET @sql := IF(@has = 0,
    'ALTER TABLE mmd_lead ADD COLUMN `auto_reply_status` VARCHAR(16) NOT NULL DEFAULT ''pending'' AFTER status',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME = 'mmd_lead'
               AND COLUMN_NAME = 'auto_replied_at');
SET @sql := IF(@has = 0,
    'ALTER TABLE mmd_lead ADD COLUMN `auto_replied_at` DATETIME NULL DEFAULT NULL AFTER auto_reply_status',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Existing leads predate the auto-reply feature — mark them 'skipped' so
-- the grid does not imply an acknowledgement is still owed. Runs once
-- (ledger-tracked); new rows inserted afterwards default to 'pending'.
UPDATE mmd_lead SET auto_reply_status = 'skipped' WHERE auto_reply_status = 'pending';
