-- C1394 Certified Kubernetes Administrator (CKA) Training — non-WSQ twin of TGS-2025054612.
-- A non-WSQ course carries no funding of its own, so its Funding block points the learner
-- at the funded WSQ version of the same course.
--
-- Fixes a wrong target: the previous content linked to
-- wsq-certified-kubernetes-administrator-cka-exam-prep-synchronous-e-learning.html, which
-- 301s to the KCNA course — a different course entirely. The correct twin is the CKA
-- parent TGS-2025054612 at wsq-certified-kubernetes-administrator-cka-training.html (200, no chain).
--
-- Content-only UPDATE: never ->save() a cms/block model (wipes cms_block_store -> 404).
-- SG production only; the guard makes this a no-op on partner sites (MY/GH) which have no WSQ twin.

UPDATE cms_block
   SET content = CONCAT(
       '<p>This course is not funded.</p>',
       '<p>A funded WSQ version of the same course is available: ',
       '<a href="https://www.tertiarycourses.com.sg/wsq-certified-kubernetes-administrator-cka-training.html">',
       'WSQ - Certified Kubernetes Administrator (CKA) Training</a>. ',
       'SkillsFuture Credit, SFEC and PSEA may apply to the WSQ course, subject to eligibility.</p>'
   )
 WHERE identifier = 'course_C1394_funding_and_grant'
   AND EXISTS (SELECT 1 FROM core_config_data
                WHERE path = 'web/unsecure/base_url'
                  AND value LIKE '%tertiarycourses.com.sg%');
