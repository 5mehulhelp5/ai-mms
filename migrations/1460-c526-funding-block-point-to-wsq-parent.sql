-- 1460: C526 "No Code and Low Code Agentic AI Applications" -- create its
--       Funding block and point it at the funded WSQ twin.
--
-- C526 is the non-WSQ replication of TGS-2026062147
-- ("WSQ - No Code and Low Code Agentic AI Applications"), so it carries no
-- funding of its own. But the learner reading this page is exactly the person
-- who should be told the funded WSQ version exists -- hence the house pattern:
-- the non-WSQ page's Funding block states that no funding applies and links to
-- the WSQ course.
--
-- C526 had no funding block at all (it was never created for the retired
-- Facebook Marketing course this entity used to hold), so this INSERTs it
-- rather than UPDATEing -- matching the shape of the existing
-- course_C###_funding_and_grant blocks (store 0, is_active = 1,
-- "Course C### - Funding And Grant").
--
-- Target verified 200 on www.tertiarycourses.com.sg before shipping:
--   https://www.tertiarycourses.com.sg/wsq-no-code-and-low-code-agentic-ai-applications.html
--
-- NEVER ->save() a cms/block model: it wipes cms_block_store and 404s the
-- page. Content-only SQL is the safe form. See memory
-- feedback_cms_model_save_wipes_store_mapping.
--
-- Idempotent: INSERT IGNORE on the unique identifier, then an UPDATE so a
-- re-run converges the content either way. The store mapping is inserted
-- separately and only when missing, so an existing mapping is never disturbed.

INSERT IGNORE INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
VALUES (
  'Course C526 - Funding And Grant',
  'course_C526_funding_and_grant',
  '<p>No funding is available for this course</p> <p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-no-code-and-low-code-agentic-ai-applications.html" title="WSQ - No Code and Low Code Agentic AI Applications">WSQ - No Code and Low Code Agentic AI Applications</a></span></p>',
  NOW(), NOW(), 1
);

-- Converge the content on a re-run (and repair it if it was ever edited away).
UPDATE cms_block
   SET content = '<p>No funding is available for this course</p> <p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-no-code-and-low-code-agentic-ai-applications.html" title="WSQ - No Code and Low Code Agentic AI Applications">WSQ - No Code and Low Code Agentic AI Applications</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE identifier = 'course_C526_funding_and_grant';

-- Map to store 0 (all stores) only if the mapping is absent.
INSERT INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0
  FROM cms_block b
 WHERE b.identifier = 'course_C526_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s WHERE s.block_id = b.block_id);
