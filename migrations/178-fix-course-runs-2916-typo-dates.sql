-- Fix 8 course_runs rows where the year was entered as 2916 instead of 2016.
-- These are real completed registrations from 2016; correcting the dates moves
-- them into the Completed bucket for accurate historical viewing.

UPDATE `course_runs` SET course_start_date = '2016-04-21', course_end_date = '2016-04-21' WHERE run_id = 126;
UPDATE `course_runs` SET course_start_date = '2016-07-23', course_end_date = '2016-07-23' WHERE run_id = 251;
UPDATE `course_runs` SET course_start_date = '2016-08-07', course_end_date = '2016-08-07' WHERE run_id = 304;
UPDATE `course_runs` SET course_start_date = '2016-09-03', course_end_date = '2016-09-03' WHERE run_id = 355;
UPDATE `course_runs` SET course_start_date = '2016-12-18', course_end_date = '2016-12-18' WHERE run_id = 465;
UPDATE `course_runs` SET course_start_date = '2016-12-18', course_end_date = '2016-12-18' WHERE run_id = 471;
UPDATE `course_runs` SET course_start_date = '2016-12-21', course_end_date = '2016-12-21' WHERE run_id = 509;
UPDATE `course_runs` SET course_start_date = '2016-12-23', course_end_date = '2016-12-23' WHERE run_id = 525;
