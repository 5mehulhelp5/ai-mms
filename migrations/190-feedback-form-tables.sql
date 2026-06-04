-- Course feedback form system.
--
-- mmd_feedback_form_template  — one active template (global, single provider).
--   sections column holds a JSON array of { id, title, fields[] } objects where
--   each field has { id, label, type, autofill, readonly, required, options }.
--
-- mmd_feedback_form_response  — one row per learner submission.
--   Course context columns (course_title, trainer_name, etc.) are snapshotted at
--   submit time so responses remain readable even if the class run is later edited.
--   answers column holds a flat JSON object of { field_id: value }.

CREATE TABLE IF NOT EXISTS `mmd_feedback_form_template` (
    `template_id`  INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `title`        VARCHAR(255)  NOT NULL DEFAULT 'Course Feedback Form',
    `sections`     LONGTEXT      NOT NULL COMMENT 'JSON array of section objects',
    `is_active`    TINYINT(1)    NOT NULL DEFAULT 1,
    `created_at`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`template_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `mmd_feedback_form_response` (
    `response_id`   INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `template_id`   INT UNSIGNED  NULL,
    `run_id`        INT UNSIGNED  NULL     COMMENT 'course_runs.run_id',
    `class_id`      VARCHAR(20)   NULL     COMMENT 'e.g. SG000042',
    `course_sku`    VARCHAR(64)   NULL,
    `course_title`  VARCHAR(255)  NULL,
    `trainer_name`  VARCHAR(255)  NULL,
    `start_date`    DATE          NULL,
    `end_date`      DATE          NULL,
    `learner_name`  VARCHAR(255)  NULL,
    `learner_email` VARCHAR(255)  NULL,
    `answers`       LONGTEXT      NOT NULL COMMENT 'JSON object field_id => value',
    `submitted_at`  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`response_id`),
    KEY `idx_run_id`    (`run_id`),
    KEY `idx_submitted` (`submitted_at`),
    KEY `idx_class_id`  (`class_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
