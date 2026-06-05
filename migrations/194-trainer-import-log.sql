-- Trainer import (from LMS) run log — gives admins visibility into each sync.
-- The importer itself is idempotent (matches admin_user by email, UNIQUE
-- user_id+role_code in mmd_user_role_map); this table only records outcomes.

CREATE TABLE IF NOT EXISTS `mmd_trainer_import_log` (
    `log_id`        INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `run_at`        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `triggered_by`  VARCHAR(64)   NULL      COMMENT 'cron | admin email',
    `fetched`       INT UNSIGNED  NOT NULL DEFAULT 0,
    `accounts_created` INT UNSIGNED NOT NULL DEFAULT 0,
    `roles_added`   INT UNSIGNED  NOT NULL DEFAULT 0,
    `emails_backfilled` INT UNSIGNED NOT NULL DEFAULT 0,
    `skipped`       INT UNSIGNED  NOT NULL DEFAULT 0,
    `errors`        INT UNSIGNED  NOT NULL DEFAULT 0,
    `status`        ENUM('success','partial','error') NOT NULL DEFAULT 'success',
    `message`       TEXT          NULL,
    PRIMARY KEY (`log_id`),
    KEY `idx_run_at` (`run_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
