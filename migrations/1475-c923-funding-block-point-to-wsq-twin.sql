-- C923 (CompTIA Data+ Training) — point the Funding block at its WSQ twin.
--
-- The non-WSQ course carries no funding of its own, but the learner reading its
-- page should be told the funded WSQ version exists. The block already pointed at
-- the WSQ course via the OLD slug (wsq-comptia-data-training.html), which
-- 301-chains to the canonical URL; this flattens it to the canonical target so
-- the link resolves in one hop.
--
-- Target verified 200 on www.tertiarycourses.com.sg:
--   https://www.tertiarycourses.com.sg/wsq-comptia-certified-data-training.html
--
-- Content-only UPDATE: never ->save() a cms/block model (it wipes cms_block_store
-- and 404s the page). SG production only; partner sites have no WSQ twin, and the
-- WHERE clause makes this a no-op where the block does not exist.

UPDATE cms_block
   SET content = '<p>No funding is available for this course</p> <p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-comptia-certified-data-training.html" title="WSQ - CompTIA Certified Data+ Training" target="_blank">WSQ - CompTIA Certified Data+ Training</a></span></p>'
 WHERE identifier = 'course_C923_funding_and_grant';
