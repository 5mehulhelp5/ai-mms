-- C1162 (CompTIA Linux+ Training) — point the Funding block at the WSQ twin's
-- CANONICAL url instead of the legacy slug that 301-redirects.
--
-- The non-WSQ course carries no funding of its own; its Funding block redirects
-- learners to the funded WSQ twin (TGS-2024048316). The block currently links to
-- /wsq-comptia-linux-training.html, which 301s to
-- /wsq-comptia-certified-linux-training.html. Link straight at the 200 target so
-- the learner does not take an extra hop.
--
-- Content-only UPDATE: never ->save() a cms/block model (it wipes cms_block_store
-- and 404s the page). Idempotent — re-running is a no-op once applied.

UPDATE cms_block
   SET content = REPLACE(
         content,
         'https://www.tertiarycourses.com.sg/wsq-comptia-linux-training.html',
         'https://www.tertiarycourses.com.sg/wsq-comptia-certified-linux-training.html'
       )
 WHERE identifier = 'course_C1162_funding_and_grant'
   AND content LIKE '%/wsq-comptia-linux-training.html%';
