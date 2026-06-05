-- Store the generated certificate PDF as the source of truth (LMS
-- overwrite-in-place model): one artifact per (run_id, learner_email), served
-- verbatim on download instead of regenerating. Regeneration overwrites this
-- blob in place at the same token — no version history.
--
-- source records which generator produced the bytes ('mpdf' today; room for
-- 'drive' if a Slides pipeline is ever added).

ALTER TABLE `mmd_course_run_certificate`
    ADD COLUMN `pdf_blob` LONGBLOB NULL AFTER `error_message`,
    ADD COLUMN `source`   VARCHAR(16) NULL AFTER `pdf_blob`;
