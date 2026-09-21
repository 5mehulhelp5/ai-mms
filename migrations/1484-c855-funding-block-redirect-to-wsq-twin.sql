-- C855 CompTIA Cloud+ Training — non-WSQ twin of TGS-2024049214.
-- A non-WSQ course carries no funding of its own, so its Funding block points the learner
-- at the funded WSQ version of the same course.
-- The existing block linked to /wsq-comptia-cloud-training.html, which 301-redirects to
-- the canonical page; this repoints it directly so the learner takes no redirect hop.
-- Content-only UPDATE: never ->save() a cms/block model (wipes cms_block_store -> 404).
-- SG production only; the guard makes this a no-op on partner sites (MY/GH) which have no WSQ twin.

UPDATE cms_block
   SET content = CONCAT(
       '<p>This course is not funded.</p>',
       '<p>A funded WSQ version of the same course is available: ',
       '<a href="https://www.tertiarycourses.com.sg/wsq-comptia-certified-cloud-training.html">',
       'WSQ - CompTIA Certified Cloud+ Training</a>. ',
       'SkillsFuture Credit, SFEC and PSEA may apply to the WSQ course, subject to eligibility.</p>'
   )
 WHERE identifier = 'course_C855_funding_and_grant'
   AND EXISTS (SELECT 1 FROM core_config_data
                WHERE path = 'web/unsecure/base_url'
                  AND value LIKE '%tertiarycourses.com.sg%');
