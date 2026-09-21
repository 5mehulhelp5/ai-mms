-- C756 (AZ-104 Azure Administrator Associate Training) — non-WSQ courseware conversion.
--
-- The Funding block already points at the WSQ twin (TGS-2023039182), but via the
-- OLD slug, which 301s to the canonical one. Flatten it to the direct 200 URL so
-- the learner does not take an extra hop.
--
--   old: /wsq-microsoft-azure-administrator-associate-exam-prep.html          -> 301
--   new: /wsq-microsoft-certified-azure-administrator-associate-az-104.html   -> 200
--
-- Content-only UPDATE. Never ->save() a cms/block model: that wipes cms_block_store
-- and 404s the page (see memory feedback_cms_model_save_wipes_store_mapping).
-- Idempotent: the LIKE guard makes a re-run a no-op.

UPDATE cms_block
   SET content = REPLACE(
         content,
         'https://www.tertiarycourses.com.sg/wsq-microsoft-azure-administrator-associate-exam-prep.html',
         'https://www.tertiarycourses.com.sg/wsq-microsoft-certified-azure-administrator-associate-az-104.html'
       )
 WHERE identifier = 'course_C756_funding_and_grant'
   AND content LIKE '%/wsq-microsoft-azure-administrator-associate-exam-prep.html%';
