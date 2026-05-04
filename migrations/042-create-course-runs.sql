-- course_runs — one row per Create New Class submission.
--
-- Each row is a specific scheduled instance of a source course product.
-- When admin creates a class via the Create New Class form, a row goes
-- in here capturing every field they entered (venue, mode, vacancy,
-- admin email, registration window, trainer option_id, course dates).
-- The trainer's "My Assigned Classes" view joins this table back to
-- the source product so the card shows what the admin entered, not
-- the underlying product attributes.
--
-- Idempotent — CREATE TABLE IF NOT EXISTS lets this re-run safely.

CREATE TABLE IF NOT EXISTS `course_runs` (
    `run_id`             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `product_id`         INT UNSIGNED NOT NULL,
    `course_sku`         VARCHAR(64)  NOT NULL,
    `trainer_option_id`  INT UNSIGNED NULL,
    `reg_open_date`      DATE NULL,
    `reg_close_date`     DATE NULL,
    `course_start_date`  DATE NULL,
    `course_end_date`    DATE NULL,
    `venue_block`        VARCHAR(64)  NULL,
    `venue_street`       VARCHAR(255) NULL,
    `venue_building`     VARCHAR(255) NULL,
    `venue_floor`        VARCHAR(32)  NULL,
    `venue_unit`         VARCHAR(32)  NULL,
    `postal_code`        VARCHAR(16)  NULL,
    `room`               VARCHAR(128) NULL,
    `wheelchair`         TINYINT(1)   NOT NULL DEFAULT 0,
    `mode_of_training`   TINYINT(1)   NOT NULL DEFAULT 1,
    `admin_email`        VARCHAR(255) NULL,
    `vacancy`            CHAR(1)      NOT NULL DEFAULT 'A',
    `created_at`         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`run_id`),
    KEY `idx_product`            (`product_id`),
    KEY `idx_trainer`            (`trainer_option_id`),
    KEY `idx_product_trainer`    (`product_id`, `trainer_option_id`),
    KEY `idx_course_dates`       (`course_start_date`, `course_end_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
