-- C385 Github Foundations Certification Training (non-WSQ twin of TGS-2025053207)
-- The non-WSQ course carries no funding of its own; point its Funding block at the
-- funded WSQ version so learners who qualify can find it.
--
-- Content-only UPDATE: never ->save() a cms/block model, that wipes cms_block_store
-- and 404s the page (see memory feedback_cms_model_save_wipes_store_mapping).
-- Idempotent: re-running rewrites the same content.
--
-- Target verified 200 (no redirect chain) on www.tertiarycourses.com.sg 2026-09-21.

UPDATE cms_block
   SET content = '<p>This course is not funded.</p><p>A funded WSQ version of the same course is available: <a href="https://www.tertiarycourses.com.sg/wsq-github-foundations-certification-training.html">WSQ - Github Foundations Certification Training</a>. SkillsFuture Credit, SFEC and PSEA may apply to the WSQ course, subject to eligibility.</p>'
 WHERE identifier = 'course_C385_funding_and_grant';
