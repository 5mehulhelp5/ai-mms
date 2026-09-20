-- C1048 CompTIA Server+ Training — non-WSQ twin of TGS-2024048318.
-- A non-WSQ course carries no funding of its own, so its Funding block points the learner
-- at the funded WSQ version of the same course.
--
-- Target verified 200 (no redirect chain) on www.tertiarycourses.com.sg:
--   wsq-comptia-certified-server-training.html  =  TGS-2024048318, the course this
--   courseware was duplicated from.
--
-- Content-only UPDATE: never ->save() a cms/block model (wipes cms_block_store -> 404).
-- SG production only; the guard makes this a no-op on partner sites (MY/GH) which have no WSQ twin.

UPDATE cms_block
   SET content = CONCAT(
       '<p>This course is not funded.</p>',
       '<p>A funded WSQ version of the same course is available: ',
       '<a href="https://www.tertiarycourses.com.sg/wsq-comptia-certified-server-training.html">',
       'WSQ - CompTIA Certified Server+ Training</a>. ',
       'SkillsFuture Credit, SFEC and PSEA may apply to the WSQ course, subject to eligibility.</p>'
   )
 WHERE identifier = 'course_C1048_funding_and_grant'
   AND EXISTS (SELECT 1 FROM core_config_data
                WHERE path = 'web/unsecure/base_url'
                  AND value LIKE '%tertiarycourses.com.sg%');
