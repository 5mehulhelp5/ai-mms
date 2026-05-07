-- Per-course list of "Additional Documents" the developer can attach
-- (e.g. attendance pptx, slides, PDF handouts). Surfaced in the
-- trainer + learner course-detail panel under "Additional Documents".
-- Replaces the hardcoded sample row that used to render the same fake
-- file ("Attendance-Navigating Digital Threats.pptx" uploaded by
-- "consult@sgventure-consulting.com") for every course.
--
-- One row per file. (product_id, filename) intentionally NOT unique —
-- two distinct uploads can share a name with different URLs.

CREATE TABLE IF NOT EXISTS `course_documents` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `product_id`  INT UNSIGNED NOT NULL,
    `filename`    VARCHAR(255) NOT NULL,
    `file_url`    VARCHAR(1000) NOT NULL DEFAULT '',
    `uploaded_by` VARCHAR(255) NOT NULL DEFAULT '',
    `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_product` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Per-course Additional Documents list';
