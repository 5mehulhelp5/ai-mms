-- course_run_enrolments — admin-driven enrolments managed via the
-- Assign Learners panel. Separate from sales_flat_order so the admin
-- can attach a learner to a class without creating a fake order.
--
-- Idempotent — CREATE TABLE IF NOT EXISTS lets this re-run safely.

CREATE TABLE IF NOT EXISTS `course_run_enrolments` (
    `enrolment_id`   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `product_id`     INT UNSIGNED NOT NULL,
    `run_id`         INT UNSIGNED NULL,
    `learner_email`  VARCHAR(255) NOT NULL,
    `learner_name`   VARCHAR(255) NULL,
    `created_at`     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`enrolment_id`),
    UNIQUE KEY `uk_product_run_email` (`product_id`, `run_id`, `learner_email`),
    KEY `idx_product` (`product_id`),
    KEY `idx_run`     (`run_id`),
    KEY `idx_email`   (`learner_email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
