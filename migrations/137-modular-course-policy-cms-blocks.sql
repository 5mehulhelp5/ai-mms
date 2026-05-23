-- Split the per-store "grant" CMS block into two modular blocks:
--   post_course_support           — "Post-Course Support" content
--   course_cancellation_policy    — "Course Cancellation/Reschedule Policy" content
-- The legacy "grant" block is kept (cleared for stores where it only held
-- those two sections; trimmed for MY/Infotech which had additional content).
-- This is re-runnable: it deletes any existing rows for the two new
-- identifiers before re-inserting.

DELETE bs FROM cms_block_store bs INNER JOIN cms_block b ON b.block_id = bs.block_id WHERE b.identifier IN ('post_course_support', 'course_cancellation_policy');
DELETE FROM cms_block WHERE identifier IN ('post_course_support', 'course_cancellation_policy');

-- ===== Singapore (store_id = 1) =====
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active) VALUES ('Singapore — Post-Course Support', 'post_course_support', '<ul class="course-policy-list"><li>We provide free consultation related to the subject matter after the course.</li><li>Please email your queries to <a href="mailto:enquiry@tertiaryinfotech.com">enquiry@tertiaryinfotech.com</a> and we will forward your queries to the subject matter experts.</li></ul>', NOW(), NOW(), 1);
INSERT INTO cms_block_store (block_id, store_id) VALUES (LAST_INSERT_ID(), 1);
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active) VALUES ('Singapore — Course Cancellation/Reschedule Policy', 'course_cancellation_policy', '<ul class="course-policy-list"><li>You can register your interest without upfront payment. There is no penalty for withdrawal of the course before the class commences.</li><li>We reserve the right to cancel or re-schedule the course due to unforeseen circumstances. If the course is cancelled, we will <strong class="policy-refund">refund 100%</strong> for any paid amount.</li><li>Note the venue of the training is subject to changes due to availability of the classroom.</li></ul>', NOW(), NOW(), 1);
INSERT INTO cms_block_store (block_id, store_id) VALUES (LAST_INSERT_ID(), 1);
UPDATE cms_block SET content = '' WHERE block_id = 22;

-- ===== Malaysia (store_id = 2) =====
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active) VALUES ('Malaysia — Post-Course Support', 'post_course_support', '<p>We may provide consultation related to the subject matter after the course. Please email your queries to <a href="mailto:sales@tertiarycourses.com.my">sales@tertiarycourses.com.my</a> and we will forward your queries to the subject matter experts and get back to you as soon as possible.</p>', NOW(), NOW(), 1);
INSERT INTO cms_block_store (block_id, store_id) VALUES (LAST_INSERT_ID(), 2);
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active) VALUES ('Malaysia — Course Cancellation/Reschedule Policy', 'course_cancellation_policy', '<p>We reserve the right to cancel or re-schedule the course due to unforeseen circumstances. If the course is cancelled, we will <strong class="policy-refund">refund 100%</strong> to participants.</p><p class="policy-note">Note: the venue of the training is subject to changes due to class size and availability of the classroom. The minimum class size to start a class is 3 Pax.</p>', NOW(), NOW(), 1);
INSERT INTO cms_block_store (block_id, store_id) VALUES (LAST_INSERT_ID(), 2);
UPDATE cms_block SET content = '<p><strong>Disclaimer:</strong> The course dates displayed on our website are tentative and subject to trainer availability. We will confirm the final date after checking with the trainer. You are also welcome to email us your preferred date at <a href="mailto:sales@tertiarycourses.com.my">sales@tertiarycourses.com.my</a>, and we will do our best to coordinate with the trainer''s schedule.</p>' WHERE block_id = 64;

-- ===== Ghana (store_id = 3) =====
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active) VALUES ('Ghana — Post-Course Support', 'post_course_support', '<p>We provide free consultation related to the subject matter after the course. Please email your queries to <a href="mailto:info@tertiarycourses.com.gh">info@tertiarycourses.com.gh</a> and we will forward your queries to the subject matter experts and get back to you as soon as possible.</p>', NOW(), NOW(), 1);
INSERT INTO cms_block_store (block_id, store_id) VALUES (LAST_INSERT_ID(), 3);
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active) VALUES ('Ghana — Course Cancellation/Reschedule Policy', 'course_cancellation_policy', '<p>We reserve the right to cancel or re-schedule the course due to unforeseen circumstances. If the course is cancelled, we will <strong class="policy-refund">refund 100%</strong> to participants.</p><p class="policy-note">Note: the venue of the training is subject to changes due to class size and availability of the classroom. The minimum class size to start a class is 3 Pax.</p>', NOW(), NOW(), 1);
INSERT INTO cms_block_store (block_id, store_id) VALUES (LAST_INSERT_ID(), 3);
UPDATE cms_block SET content = '' WHERE block_id = 65;

-- ===== Nigeria (store_id = 4) =====
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active) VALUES ('Nigeria — Post-Course Support', 'post_course_support', '<p>We provide free consultation related to the subject matter after the course. Please email your queries to <a href="mailto:info@tertiarycourses.com.ng">info@tertiarycourses.com.ng</a> and we will forward your queries to the subject matter experts and get back to you as soon as possible.</p>', NOW(), NOW(), 1);
INSERT INTO cms_block_store (block_id, store_id) VALUES (LAST_INSERT_ID(), 4);
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active) VALUES ('Nigeria — Course Cancellation/Reschedule Policy', 'course_cancellation_policy', '<p>We reserve the right to cancel or re-schedule the course due to unforeseen circumstances. If the course is cancelled, we will <strong class="policy-refund">refund 100%</strong> to participants.</p><p class="policy-note">Note: the venue of the training is subject to changes due to class size and availability of the classroom. The minimum class size to start a class is 3 Pax.</p>', NOW(), NOW(), 1);
INSERT INTO cms_block_store (block_id, store_id) VALUES (LAST_INSERT_ID(), 4);
UPDATE cms_block SET content = '' WHERE block_id = 69;

-- ===== Bhutan (store_id = 5) =====
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active) VALUES ('Bhutan — Post-Course Support', 'post_course_support', '<p>We provide free consultation related to the subject matter after the course. Please email your queries to <a href="mailto:info@tertiarycourses.bt">info@tertiarycourses.bt</a> and we will forward your queries to the subject matter experts and get back to you as soon as possible.</p>', NOW(), NOW(), 1);
INSERT INTO cms_block_store (block_id, store_id) VALUES (LAST_INSERT_ID(), 5);
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active) VALUES ('Bhutan — Course Cancellation/Reschedule Policy', 'course_cancellation_policy', '<p>We reserve the right to cancel or re-schedule the course due to unforeseen circumstances. If the course is cancelled, we will <strong class="policy-refund">refund 100%</strong> to participants.</p><p class="policy-note">Note: the venue of the training is subject to changes due to class size and availability of the classroom. The minimum class size to start a class is 3 Pax.</p>', NOW(), NOW(), 1);
INSERT INTO cms_block_store (block_id, store_id) VALUES (LAST_INSERT_ID(), 5);
UPDATE cms_block SET content = '' WHERE block_id = 81;

-- ===== India (store_id = 6) =====
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active) VALUES ('India — Post-Course Support', 'post_course_support', '<p>We provide free consultation related to the subject matter after the course. Please email your queries to <a href="mailto:info@tertiarycourses.co.in">info@tertiarycourses.co.in</a> and we will forward your queries to the subject matter experts and get back to you as soon as possible.</p>', NOW(), NOW(), 1);
INSERT INTO cms_block_store (block_id, store_id) VALUES (LAST_INSERT_ID(), 6);
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active) VALUES ('India — Course Cancellation/Reschedule Policy', 'course_cancellation_policy', '<p>We reserve the right to cancel or re-schedule the course due to unforeseen circumstances. If the course is cancelled, we will <strong class="policy-refund">refund 100%</strong> to participants.</p><p class="policy-note">Note: the venue of the training is subject to changes due to class size and availability of the classroom. The minimum class size to start a class is 3 Pax.</p>', NOW(), NOW(), 1);
INSERT INTO cms_block_store (block_id, store_id) VALUES (LAST_INSERT_ID(), 6);
UPDATE cms_block SET content = '' WHERE block_id = 97;

-- ===== Infotech (store_id = 7) =====
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active) VALUES ('Infotech — Post-Course Support', 'post_course_support', '<ul class="course-policy-list"><li>We provide free consultation related to the subject matter after the course.</li><li>Please email your queries to <a href="mailto:enquiry@tertiaryinfotech.com">enquiry@tertiaryinfotech.com</a> and we will forward your queries to the subject matter experts.</li></ul>', NOW(), NOW(), 1);
INSERT INTO cms_block_store (block_id, store_id) VALUES (LAST_INSERT_ID(), 7);
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active) VALUES ('Infotech — Course Cancellation/Reschedule Policy', 'course_cancellation_policy', '<ul class="course-policy-list"><li>You can register your interest without upfront payment. There is no penalty for withdrawal of the course before the class commences.</li><li>We reserve the right to cancel or re-schedule the course due to unforeseen circumstances. If the course is cancelled, we will <strong class="policy-refund">refund 100%</strong> for any paid amount.</li><li>Note the venue of the training is subject to changes due to availability of the classroom.</li></ul>', NOW(), NOW(), 1);
INSERT INTO cms_block_store (block_id, store_id) VALUES (LAST_INSERT_ID(), 7);
UPDATE cms_block SET content = '<h3>Duration</h3><p>2 months (Full Time)</p><h3>Assessment</h3><p>3 hours online assessment after each module</p><h3>Class (No of teacher : student): 1:20</h3><h3>Intake</h3><ul class="disc"><li>3 Nov 2025 to 29 Sep 2026</li><li>4 May 2026 to 26 June 2026</li><li>2 Jan 2026 to 2 Mar 2026</li><li>2 Mar 2026 to 27 Apr 2026</li></ul><h3>Enrolment Requirement</h3><ul class="disc"><li>Age: 21 years old and above</li><li>Language Proficiency: At least C6 for GCE "O" Level English</li><li>Academic: At least C6 for GCE "O" Level in any 3 subjects</li></ul><h3>Graduation Requirement</h3><ul class="disc"><li>Attendance: 75%</li><li>Assessment: Passed</li></ul>' WHERE block_id = 109;
