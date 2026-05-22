-- Add class_id to course_runs: a human-readable, country-prefixed sequential
-- identifier generated at row-creation time (e.g. SG000042, MY000007).
-- NULL is allowed so existing rows remain valid before the backfill runs.
-- The unique constraint prevents duplicates while still permitting multiple NULLs.

ALTER TABLE `course_runs`
    ADD COLUMN `class_id` VARCHAR(16) DEFAULT NULL AFTER `run_id`,
    ADD UNIQUE KEY `uk_class_id` (`class_id`);
