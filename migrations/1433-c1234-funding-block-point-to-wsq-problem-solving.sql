-- C1234 (Generative AI for Problem Solving) — create the Funding block and
-- point it at its own WSQ twin.
--
-- C1234 is the non-WSQ duplicate of TGS-2023036653 "WSQ - Generative AI for
-- Problem Solving" (courseware duplicated 2026-09-19). The course had no
-- course_C1234_funding_and_grant block at all, so the product page showed nothing
-- where every other non-WSQ course tells the learner where the funded version is.
--
-- Non-WSQ courses carry no funding of their own, so the block's only job is to
-- redirect to the funded WSQ equivalent. Target verified HTTP 200 (no redirect
-- chain) on www.tertiarycourses.com.sg before shipping:
--   https://www.tertiarycourses.com.sg/wsq-generative-ai-for-problem-solving.html
--
-- Content-only INSERT/UPDATE: never ->save() a cms/block model, which wipes the
-- cms_block_store mapping and 404s the page.
--
-- Idempotent:
--   * the INSERT is guarded by NOT EXISTS on the identifier, so a re-run inserts
--     nothing (cms_block.identifier has NO unique key — a bare INSERT IGNORE
--     would happily create a duplicate);
--   * the UPDATE re-asserts the canonical copy either way;
--   * the store mapping uses INSERT IGNORE on the (block_id, store_id) PK.
-- Partner-safe: SG-only content, but the guards make it a no-op on any DB where
-- the block is absent or already correct.

INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT
  'Course C1234 - Funding And Grant',
  'course_C1234_funding_and_grant',
  '<p>No funding is available for this course</p> <p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-generative-ai-for-problem-solving.html" title="WSQ - Generative AI for Problem Solving">WSQ - Generative AI for Problem Solving</a></span></p>',
  NOW(), NOW(), 1
FROM DUAL
WHERE NOT EXISTS (
  SELECT 1 FROM (SELECT block_id FROM cms_block WHERE identifier = 'course_C1234_funding_and_grant') AS existing
);

UPDATE cms_block
   SET content = '<p>No funding is available for this course</p> <p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-generative-ai-for-problem-solving.html" title="WSQ - Generative AI for Problem Solving">WSQ - Generative AI for Problem Solving</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE identifier = 'course_C1234_funding_and_grant';

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block WHERE identifier = 'course_C1234_funding_and_grant';
