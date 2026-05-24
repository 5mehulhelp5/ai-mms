-- Reformat MY (store_id=2) and GH (store_id=3) versions of the two
-- right-rail course-policy CMS blocks into the same bulleted-list
-- markup that SG (store_id=1) uses. The legacy <p>...</p> content
-- (seeded by migration 137) renders as a paragraph blob and looks
-- visually inconsistent next to the SG version. Symptom on the live
-- course page: SG sidebar has tidy red-dot bullets, MY/GH has a wall
-- of text with one yellow callout.
--
-- Each country keeps its own copy — only the markup changes:
--   MY post_course_support → 2 bullets (sales@tertiarycourses.com.my)
--   GH post_course_support → 2 bullets (info@tertiarycourses.com.gh)
--   MY/GH course_cancellation_policy → 2 bullets (refund "to participants",
--                                                 venue + class-size note)
--
-- Idempotent: the `content LIKE '<p>%'` guard skips rows that have
-- already been converted to <ul> by an earlier run or a later admin
-- edit, so re-applying never clobbers manual changes.
--
-- NG (4), BT (5), IN (6) still carry the same legacy <p> markup;
-- left untouched here because the original task scoped this fix to
-- MY and GH only. Extend with the same pattern if/when needed.

-- ===== Malaysia (store_id = 2) =====
UPDATE cms_block b
  JOIN cms_block_store s ON s.block_id = b.block_id
   SET b.content = '<ul class="course-policy-list"><li>We may provide consultation related to the subject matter after the course.</li><li>Please email your queries to <a href="mailto:sales@tertiarycourses.com.my">sales@tertiarycourses.com.my</a> and we will forward your queries to the subject matter experts and get back to you as soon as possible.</li></ul>',
       b.update_time = NOW()
 WHERE b.identifier = 'post_course_support'
   AND s.store_id   = 2
   AND b.content LIKE '<p>%';

UPDATE cms_block b
  JOIN cms_block_store s ON s.block_id = b.block_id
   SET b.content = '<ul class="course-policy-list"><li>We reserve the right to cancel or re-schedule the course due to unforeseen circumstances. If the course is cancelled, we will <strong class="policy-refund">refund 100%</strong> to participants.</li><li>Note: the venue of the training is subject to changes due to class size and availability of the classroom. The minimum class size to start a class is 3 Pax.</li></ul>',
       b.update_time = NOW()
 WHERE b.identifier = 'course_cancellation_policy'
   AND s.store_id   = 2
   AND b.content LIKE '<p>%';

-- ===== Ghana (store_id = 3) =====
UPDATE cms_block b
  JOIN cms_block_store s ON s.block_id = b.block_id
   SET b.content = '<ul class="course-policy-list"><li>We provide free consultation related to the subject matter after the course.</li><li>Please email your queries to <a href="mailto:info@tertiarycourses.com.gh">info@tertiarycourses.com.gh</a> and we will forward your queries to the subject matter experts and get back to you as soon as possible.</li></ul>',
       b.update_time = NOW()
 WHERE b.identifier = 'post_course_support'
   AND s.store_id   = 3
   AND b.content LIKE '<p>%';

UPDATE cms_block b
  JOIN cms_block_store s ON s.block_id = b.block_id
   SET b.content = '<ul class="course-policy-list"><li>We reserve the right to cancel or re-schedule the course due to unforeseen circumstances. If the course is cancelled, we will <strong class="policy-refund">refund 100%</strong> to participants.</li><li>Note: the venue of the training is subject to changes due to class size and availability of the classroom. The minimum class size to start a class is 3 Pax.</li></ul>',
       b.update_time = NOW()
 WHERE b.identifier = 'course_cancellation_policy'
   AND s.store_id   = 3
   AND b.content LIKE '<p>%';
