-- Attendance feature retired 2026-05-07. The trainer-facing Attendance
-- and standalone E-Attendance UIs are gone, AttendanceController is
-- deleted, and the entry_mode column added by migration 053 is moot.
-- Drop the table outright — no other module reads it.
--
-- course_attendance_tokens was already dropped by migration 048 when
-- the QR check-in flow was first retired; this migration is the second
-- (and final) cleanup pass.

DROP TABLE IF EXISTS course_attendance;
