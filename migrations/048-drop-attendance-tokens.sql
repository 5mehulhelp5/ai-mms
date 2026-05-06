-- Drop course_attendance_tokens — backed the E-Attendance feature (the
-- inline section on the trainer course detail that generated a QR /
-- check-in link per session). The UI was removed 2026-05-06 along with
-- AttendanceController::generateTokenAction and ::checkinAction, so
-- nothing reads or writes this table any more.
--
-- course_attendance (the actual attendance records table) stays — it's
-- still written by AttendanceController::saveAction from the Manual
-- Attendance flow.

DROP TABLE IF EXISTS course_attendance_tokens;
