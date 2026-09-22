-- 1543: create C914's Funding block, pointing at its WSQ twin.
--
-- C914 "Robot Operating System (ROS) Fundamentals" is the non-WSQ twin of
-- TGS-2020513213 "WSQ - Fundamentals of Robot Operating System ROS for
-- Beginners" (courseware duplicated 2026-09-23). A non-WSQ course carries no
-- funding of its own, but the learner reading its page is exactly the person
-- who should be told the funded version exists -- so the Funding block points
-- at the WSQ course, matching the course_C009_funding_and_grant pattern.
--
-- C914 had no funding block at all (only course_C914_brochure), so this
-- CREATES one rather than updating.
--
-- The target was validated before shipping:
--   https://www.tertiarycourses.com.sg/wsq-fundamentals-of-robot-operating-system-ros-for-beginners.html
--   -> HTTP 200, no redirect chain.
--
-- NEVER ->save() a cms/block model: that wipes cms_block_store and 404s the
-- page. Content-only SQL, with the store row inserted explicitly at store 0
-- (the convention every other course_C*_funding_and_grant block uses).
--
-- SG production only -- the WSQ twin exists only on SG. Partner sites get the
-- block too but it is harmless there (it is only rendered for C914, and a
-- partner site has no C914). Idempotent: a NOT EXISTS-guarded INSERT plus a
-- keyed UPDATE, so re-running converges and never duplicates.

-- cms_block.identifier is indexed but NOT unique (IDX_CMS_BLOCK_IDENTIFIER is a
-- plain BTREE), so INSERT IGNORE does NOT dedupe -- a second run would create a
-- SECOND block row with the same identifier and the storefront would then pick
-- one arbitrarily. Guard on a NOT EXISTS subselect instead, which is genuinely
-- idempotent. (Verified by running this migration twice locally.)
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT
  'Course C914 - Funding And Grant',
  'course_C914_funding_and_grant',
  '<p>No funding is available for this course</p> <p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-fundamentals-of-robot-operating-system-ros-for-beginners.html" title="WSQ - Fundamentals of Robot Operating System ROS for Beginners">WSQ - Fundamentals of Robot Operating System ROS for Beginners</a></span></p>',
  NOW(), NOW(), 1
FROM DUAL
WHERE NOT EXISTS (
  SELECT 1 FROM (SELECT block_id FROM cms_block WHERE identifier = 'course_C914_funding_and_grant') AS x
);

-- Converge the content if the block already existed with different copy.
UPDATE cms_block
   SET content = '<p>No funding is available for this course</p> <p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-fundamentals-of-robot-operating-system-ros-for-beginners.html" title="WSQ - Fundamentals of Robot Operating System ROS for Beginners">WSQ - Fundamentals of Robot Operating System ROS for Beginners</a></span></p>',
       update_time = NOW()
 WHERE identifier = 'course_C914_funding_and_grant';

-- Store mapping (store 0 = all stores), the convention used by every other
-- course_C*_funding_and_grant block. Without this row the block 404s.
-- cms_block_store has PK (block_id, store_id) so INSERT IGNORE IS correct here.
INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block WHERE identifier = 'course_C914_funding_and_grant';
