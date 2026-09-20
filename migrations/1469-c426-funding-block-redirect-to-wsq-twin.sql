-- C426 Kubernetes and Cloud Native Associate (KCNA) Training — non-WSQ twin of TGS-2023039343.
-- A non-WSQ course carries no funding of its own, so its Funding block points the learner
-- at the funded WSQ version of the same course.
-- Content-only UPDATE: never ->save() a cms/block model (wipes cms_block_store -> 404).
-- SG production only; the guard makes this a no-op on partner sites (MY/GH) which have no WSQ twin.

UPDATE cms_block
   SET content = CONCAT(
       '<p>This course is not funded.</p>',
       '<p>A funded WSQ version of the same course is available: ',
       '<a href="https://www.tertiarycourses.com.sg/wsq-kubernetes-and-cloud-native-associate-kcna-training.html">',
       'WSQ - Kubernetes and Cloud Native Associate (KCNA) Training</a>. ',
       'SkillsFuture Credit, SFEC and PSEA may apply to the WSQ course, subject to eligibility.</p>'
   )
 WHERE identifier = 'course_C426_funding_and_grant'
   AND EXISTS (SELECT 1 FROM core_config_data
                WHERE path = 'web/unsecure/base_url'
                  AND value LIKE '%tertiarycourses.com.sg%');
