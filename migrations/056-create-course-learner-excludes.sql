-- Per-course learner exclusion list. Lets the trainer / admin "Remove"
-- a learner from a course's roster *without* cancelling their order.
-- Order-sourced rows (sales_flat_order) and manually-added rows
-- (course_run_enrolments) are both hidden from the View / Remove
-- Learners panel when present here. Re-adding the learner via Add
-- Learner clears the exclusion so the toggle is fully reversible.
--
-- (product_id, learner_email) is the natural key — one row per pair.

CREATE TABLE IF NOT EXISTS `course_learner_excludes` (
    `product_id`     INT UNSIGNED NOT NULL,
    `learner_email`  VARCHAR(255) NOT NULL,
    `excluded_by`    INT UNSIGNED NULL,
    `excluded_at`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`product_id`, `learner_email`),
    KEY `idx_product` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Per-course learner suppression list — non-destructive remove';
