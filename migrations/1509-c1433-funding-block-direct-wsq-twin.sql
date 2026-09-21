-- C1433 funding block: point directly at the WSQ twin, no 301 hop.
--
-- The block linked to /wsq-microsoft-power-bi-data-analyst-pl-300-exam-prep-course.html,
-- which 301s to /wsq-microsoft-power-bi-data-analyst-associate-pl-300.html
-- (verified 200, no further hop). Flatten it so the learner's click does not
-- chain -- the same fix shipped for C740 (1493) and C1358 (1492).
--
-- Content-only UPDATE. NEVER ->save() a cms/block model: that wipes
-- cms_block_store and 404s the page (feedback_cms_model_save_wipes_store_mapping).
--
-- Idempotent: guarded on the old href, so a re-run matches nothing.

UPDATE cms_block
   SET content = REPLACE(
         content,
         'https://www.tertiarycourses.com.sg/wsq-microsoft-power-bi-data-analyst-pl-300-exam-prep-course.html',
         'https://www.tertiarycourses.com.sg/wsq-microsoft-power-bi-data-analyst-associate-pl-300.html')
 WHERE identifier = 'course_C1433_funding_and_grant'
   AND content LIKE '%wsq-microsoft-power-bi-data-analyst-pl-300-exam-prep-course.html%';
