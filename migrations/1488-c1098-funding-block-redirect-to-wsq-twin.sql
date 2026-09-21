-- C1098 Google Cloud Certified Associate Cloud Engineer Training — non-WSQ twin
-- of TGS-2023041024, converted from the parent's courseware on 2026-09-21.
--
-- A non-WSQ course carries no funding of its own, so its Funding block points the
-- learner at the funded WSQ version of the same course. The block currently reads
-- only "No funding is available for this course", which is a dead end for exactly
-- the learner who should be told the funded twin exists.
--
-- Target verified 200 on www.tertiarycourses.com.sg (2026-09-21), linked directly
-- so the learner takes no redirect hop.
--
-- Content-only UPDATE: never ->save() a cms/block model (wipes cms_block_store -> 404).
-- SG production only; the guard makes this a no-op on partner sites (MY/GH), which
-- have no WSQ twin.
--
-- Idempotent: re-running writes the same content.

UPDATE cms_block
   SET content = CONCAT(
       '<p>This course is not funded.</p>',
       '<p>A funded WSQ version of the same course is available: ',
       '<a href="https://www.tertiarycourses.com.sg/wsq-google-associate-cloud-engineer-training.html">',
       'WSQ - Google Associate Cloud Engineer Training</a>. ',
       'SkillsFuture Credit, SFEC and PSEA may apply to the WSQ course, subject to eligibility.</p>'
   )
 WHERE identifier = 'course_C1098_funding_and_grant'
   AND EXISTS (SELECT 1 FROM core_config_data
                WHERE path = 'web/unsecure/base_url'
                  AND value LIKE '%tertiarycourses.com.sg%');
