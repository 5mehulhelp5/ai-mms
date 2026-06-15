-- Course sync run log — gives admins visibility into each SG→country sync.
-- Mirrors mmd_trainer_import_log in shape. Populated by CourseSyncService.

CREATE TABLE IF NOT EXISTS `mmd_course_sync_log` (
    `log_id`      INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `run_at`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `triggered_by` VARCHAR(64)  NULL     COMMENT 'cron | admin email',
    `fetched`     INT UNSIGNED  NOT NULL DEFAULT 0,
    `created`     INT UNSIGNED  NOT NULL DEFAULT 0,
    `updated`     INT UNSIGNED  NOT NULL DEFAULT 0,
    `disabled`    INT UNSIGNED  NOT NULL DEFAULT 0,
    `skipped`     INT UNSIGNED  NOT NULL DEFAULT 0,
    `errors`      INT UNSIGNED  NOT NULL DEFAULT 0,
    `status`      ENUM('success','partial','error') NOT NULL DEFAULT 'success',
    `message`     TEXT          NULL,
    PRIMARY KEY (`log_id`),
    KEY `idx_run_at` (`run_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
