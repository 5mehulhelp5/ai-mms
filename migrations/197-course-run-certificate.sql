-- Certificate of Achievement issuance log, per-class per-learner.
--
-- One row per (run_id, learner_email). A row exists once a certificate has
-- been issued (generated + emailed) for that learner in that class — this is
-- the idempotency guard so the auto-send cron never double-sends.
--
-- The PDF itself is NOT stored on disk: it is regenerated on demand from this
-- row's snapshotted fields (learner_name, course_title, dates) when downloaded,
-- and attached fresh when emailed. cert_no is a stable human reference.

CREATE TABLE IF NOT EXISTS `mmd_course_run_certificate` (
    `certificate_id`  INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `run_id`          INT UNSIGNED  NOT NULL,
    `class_id`        VARCHAR(20)   NULL,
    `course_sku`      VARCHAR(64)   NULL,
    `course_title`    VARCHAR(255)  NULL,
    `trainer_name`    VARCHAR(255)  NULL,
    `start_date`      DATE          NULL,
    `end_date`        DATE          NULL,
    `learner_email`   VARCHAR(255)  NOT NULL,
    `learner_name`    VARCHAR(255)  NULL,
    `customer_id`     INT UNSIGNED  NULL,
    `cert_no`         VARCHAR(40)   NULL      COMMENT 'human reference e.g. SG000042-0007',
    `token`           VARCHAR(64)   NULL      COMMENT 'public download token',
    `status`          ENUM('issued','sent','error') NOT NULL DEFAULT 'issued',
    `error_message`   VARCHAR(512)  NULL,
    `issued_by_admin_id` INT UNSIGNED NULL,
    `sent_at`         DATETIME      NULL,
    `created_at`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`certificate_id`),
    UNIQUE KEY `uk_run_learner` (`run_id`, `learner_email`),
    UNIQUE KEY `uk_token` (`token`),
    KEY `idx_run`   (`run_id`),
    KEY `idx_email` (`learner_email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
