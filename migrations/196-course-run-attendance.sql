-- Manual attendance, per-class (per course_run), MMS-DB-native.
--
-- One row per learner per class (run_id). Keyed by learner_email so it joins
-- cleanly to course_run_enrolments (which carries learner_email) and to
-- customer_entity. Walk-ins (not originally enrolled) are flagged is_walkin
-- and get a customer_entity account + a course_run_enrolments row created at
-- add time, so they appear in the roster like any enrolled learner.
--
-- is_present defaults 0 (absent) — the trainer flips learners to present.
-- Idempotent upserts via the unique (run_id, learner_email) key.

CREATE TABLE IF NOT EXISTS `mmd_course_run_attendance` (
    `attendance_id`     INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `run_id`            INT UNSIGNED  NOT NULL,
    `class_id`          VARCHAR(20)   NULL      COMMENT 'denormalised e.g. SG000042',
    `learner_email`     VARCHAR(255)  NOT NULL,
    `learner_name`      VARCHAR(255)  NULL,
    `customer_id`       INT UNSIGNED  NULL      COMMENT 'customer_entity.entity_id if resolved',
    `is_present`        TINYINT(1)    NOT NULL DEFAULT 0,
    `reason_of_absence` VARCHAR(512)  NULL,
    `is_walkin`         TINYINT(1)    NOT NULL DEFAULT 0,
    `marked_by_admin_id` INT UNSIGNED NULL      COMMENT 'admin_user.user_id who last saved',
    `created_at`        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`attendance_id`),
    UNIQUE KEY `uk_run_learner` (`run_id`, `learner_email`),
    KEY `idx_run`      (`run_id`),
    KEY `idx_class_id` (`class_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
