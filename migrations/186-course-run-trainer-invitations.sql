-- Trainer invitation system for course_runs.
--
-- Adds:
--   1. course_run_trainer_invitations — tracks every invitation sent to a
--      trainer for a class run, with token-based accept/decline flow and
--      auto-escalation to the next trainer on decline.
--   2. invitation_paused column on course_runs — admin can pause further
--      invitations for a specific run without touching the invitation log.

ALTER TABLE `course_runs`
    ADD COLUMN `invitation_paused` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0
        COMMENT 'When 1, auto-sweep and manual send are blocked for this run'
    AFTER `created_by`;

CREATE TABLE IF NOT EXISTS `course_run_trainer_invitations` (
    `id`               INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    `run_id`           INT UNSIGNED    NOT NULL COMMENT 'FK → course_runs.run_id',
    `trainer_option_id` INT UNSIGNED   NULL     COMMENT 'EAV option_id — set on course_runs on accept',
    `trainer_name`     VARCHAR(255)    NOT NULL,
    `trainer_email`    VARCHAR(255)    NOT NULL,
    `token`            VARCHAR(64)     NOT NULL COMMENT 'Random hex token for the public respond URL',
    `status`           ENUM('pending','accepted','declined','blocked','resent')
                                       NOT NULL DEFAULT 'pending',
    `email_subject`    TEXT            NULL     COMMENT 'Cached subject line for audit',
    `email_body`       LONGTEXT        NULL     COMMENT 'Cached body HTML for audit',
    `sent_at`          DATETIME        NULL,
    `responded_at`     DATETIME        NULL,
    `created_at`       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP
                                                ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY  `uk_token`  (`token`),
    KEY `idx_run_created`   (`run_id`, `created_at`),
    KEY `idx_run_status`    (`run_id`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='One row per trainer invitation sent for a course run.';
