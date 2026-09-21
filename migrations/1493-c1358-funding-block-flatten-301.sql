-- C1358 PL-900 Microsoft Power Platform Fundamentals Training (non-WSQ twin of TGS-2023039923)
-- The Funding block already pointed at the funded WSQ version, but via the OLD slug
-- /wsq-microsoft-power-platform-fundamentals-exam-prep.html, which 301s to
-- /wsq-microsoft-power-platform-fundamentals-pl-900.html. Flatten the hop so the link
-- goes straight to the live URL.
--
-- Content-only UPDATE: never ->save() a cms/block model, that wipes cms_block_store
-- and 404s the page (see memory feedback_cms_model_save_wipes_store_mapping).
-- Idempotent: re-running rewrites the same content.
--
-- Target verified 200 with 0 redirects on www.tertiarycourses.com.sg 2026-09-21,
-- and confirmed to be TGS-2023039923 (the actual WSQ parent of C1358).

UPDATE cms_block
   SET content = '<p>No funding is available for this course</p> <p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-microsoft-power-platform-fundamentals-pl-900.html" title="WSQ - Microsoft Power Platform Fundamentals (PL-900)">WSQ - Microsoft Power Platform Fundamentals (PL-900)</a></span></p>'
 WHERE identifier = 'course_C1358_funding_and_grant';
