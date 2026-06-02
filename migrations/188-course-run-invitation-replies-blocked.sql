-- Add invitation_replies_blocked flag to course_runs.
--
-- When set to 1, the trainer invitation respond endpoint will reject any
-- further Accept clicks (returning the "blocked" page) while still allowing
-- Decline clicks.  Mirrors the LMS "Block Reply / Unblock Reply" toggle.
--
-- Use case: admin has manually confirmed a trainer via another channel but
-- a pending invitation email is still in flight.  Blocking replies prevents
-- a late Accept from overwriting the manual assignment.
--
-- Idempotent: column is added only if it does not already exist.

ALTER TABLE `course_runs`
    ADD COLUMN `invitation_replies_blocked` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0
    AFTER `invitation_paused`;
