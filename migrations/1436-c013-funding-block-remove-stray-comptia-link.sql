-- C013 (Generative AI for Project Management) — clean the Funding block and
-- keep it pointing at its own WSQ twin.
--
-- C013 is the non-WSQ duplicate of TGS-2024049183 "WSQ - Project Management with
-- Generative AI (GenAI)" (courseware duplicated 2026-09-19). The block already
-- existed and already linked the correct WSQ twin, but it also carried a stray
-- second anchor to an UNRELATED course:
--   https://www.tertiarycourses.com.sg/wsq-comptia-cloud-training.html
-- wrapping nothing but a <br />. It renders invisible, so nobody noticed, but it
-- is a live link from the project-management page to a CompTIA Cloud+ course —
-- verified present in the served HTML on production before this migration.
--
-- Non-WSQ courses carry no funding of their own, so the block's only job is to
-- redirect to the funded WSQ equivalent. Target verified HTTP 200 (no redirect
-- chain) on www.tertiarycourses.com.sg before shipping:
--   https://www.tertiarycourses.com.sg/wsq-project-management-with-generative-ai-genai.html
--
-- Content-only UPDATE: never ->save() a cms/block model, which wipes the
-- cms_block_store mapping and 404s the page.
--
-- Idempotent: the UPDATE re-asserts the canonical copy, so a re-run is a no-op;
-- the store mapping uses INSERT IGNORE on the (block_id, store_id) PK.
-- Partner-safe: SG-only content, and a no-op on any DB where the block is absent.

UPDATE cms_block
   SET content = '<p>No funding is available for this course</p> <p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-project-management-with-generative-ai-genai.html" title="WSQ - Project Management with Generative AI (GenAI)" target="_blank">WSQ - Project Management with Generative AI (GenAI)</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE identifier = 'course_C013_funding_and_grant';

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block WHERE identifier = 'course_C013_funding_and_grant';
