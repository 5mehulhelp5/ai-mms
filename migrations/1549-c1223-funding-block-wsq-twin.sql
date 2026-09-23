-- 1549: C1223 funding block -> point at the funded WSQ twin
--
-- Follow-up to 1547 (C1223 activated + repurposed to "AI for Lean
-- Manufacturing"). A non-WSQ C-prefix course carries no funding of its own,
-- but the learner reading its page is exactly the person who should be told
-- the funded WSQ version exists -- so the Funding block links to the WSQ twin
-- it was duplicated from, TGS-2023020425.
--
-- PROBED on prod before writing:
--   * cms_block 'course_C1223_funding_and_grant' EXISTS (block_id 3407) and
--     currently holds only the placeholder "<p>No funding is available for
--     this course</p>" -- left over from the 5S course.
--   * the link target https://www.tertiarycourses.com.sg/wsq-ai-for-lean-manufacturing.html
--     returns HTTP 200 DIRECTLY (not via a 301) -- verified before shipping,
--     since a funding block pointing at a 404 is worse than no block.
--   * wording + markup copied from the established sibling blocks
--     (course_C009/C012/C013_funding_and_grant) so this page matches the rest
--     of the non-WSQ catalogue.
--
-- Content-only UPDATE. NEVER ->save() a cms/block model: that wipes the
-- cms_block_store mapping and 404s the page.
--
-- SG production only; keyed by identifier so a partner site without this block
-- no-ops. Idempotent: re-running writes the same content.

UPDATE cms_block
   SET content = CONCAT(
     '<p>No funding is available for this course</p> ',
     '<p>For WSQ funding, please checkout the details at&nbsp;',
     '<span style="text-decoration: underline;">',
     '<a href="https://www.tertiarycourses.com.sg/wsq-ai-for-lean-manufacturing.html" ',
     'title="WSQ - AI for Lean Manufacturing" target="_blank">',
     'WSQ - AI for Lean Manufacturing</a></span></p>')
 WHERE identifier = 'course_C1223_funding_and_grant';
