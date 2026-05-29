-- Fix missing start/end time on run_id=1 (C1434, SG, 07 May 2026).
-- Class was created manually before the UI enforced time entry.
-- Using the standard C1434 time slot (09:30–17:30).

UPDATE `course_runs`
   SET course_start_time = '09:30:00',
       course_end_time   = '17:30:00'
 WHERE run_id = 1
   AND (course_start_time IS NULL OR course_start_time = '');
