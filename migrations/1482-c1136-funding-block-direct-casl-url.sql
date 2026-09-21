-- C1136 (CompTIA PenTest+ Training) — point the Funding block at the funded
-- twin's CANONICAL url and correct its label.
--
-- The non-WSQ course carries no funding of its own; its Funding block redirects
-- learners to the funded twin TGS-2026064471. Two things are stale:
--   1. the link targets /wsq-comptia-pentest-exam-prep.html, which 301s to
--      /casl-comptia-pentest-training.html — link straight at the 200 target so
--      the learner does not take an extra hop;
--   2. the twin is a CASL course, not WSQ, so the link text and the lead-in
--      sentence are relabelled to match what the learner lands on.
--
-- Verified 2026-09-21: /casl-comptia-pentest-training.html returns 200 on
-- www.tertiarycourses.com.sg.
--
-- Content-only UPDATE: never ->save() a cms/block model (it wipes cms_block_store
-- and 404s the page). Idempotent — re-running is a no-op once applied.

UPDATE cms_block
   SET content = REPLACE(
         content,
         'https://www.tertiarycourses.com.sg/wsq-comptia-pentest-exam-prep.html',
         'https://www.tertiarycourses.com.sg/casl-comptia-pentest-training.html'
       )
 WHERE identifier = 'course_C1136_funding_and_grant'
   AND content LIKE '%/wsq-comptia-pentest-exam-prep.html%';

UPDATE cms_block
   SET content = REPLACE(content, 'WSQ - CompTIA PenTest+ Training',
                                  'CASL - CompTIA PenTest+ Training')
 WHERE identifier = 'course_C1136_funding_and_grant'
   AND content LIKE '%WSQ - CompTIA PenTest+ Training%';

UPDATE cms_block
   SET content = REPLACE(content, 'For WSQ funding, please checkout the details at',
                                  'For funding, please checkout the details at')
 WHERE identifier = 'course_C1136_funding_and_grant'
   AND content LIKE '%For WSQ funding, please checkout the details at%';
