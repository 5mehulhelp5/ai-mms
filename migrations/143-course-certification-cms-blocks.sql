-- Seed a per-store `course_certification` CMS block for MY/GH/NG/BT/IN/Infotech.
-- Singapore (store_id = 1) is intentionally NOT seeded — SG renders a
-- TGS-aware standardised writeup directly in view.phtml (Cert of Completion
-- ± OpenCerts) keyed off the SKU prefix, which can't be expressed in a
-- single static CMS block. All other stores get a uniform "Certificate of
-- Completion from Tertiary Courses" card so the left-column Certification
-- card mirrors the SG layout instead of leaving the Cert blurb inline in
-- the course narrative.
--
-- Re-runnable: deletes any existing rows for this identifier first.

DELETE bs FROM cms_block_store bs INNER JOIN cms_block b ON b.block_id = bs.block_id WHERE b.identifier = 'course_certification';
DELETE FROM cms_block WHERE identifier = 'course_certification';

-- ===== Malaysia (store_id = 2) =====
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active) VALUES ('Malaysia — Course Certification', 'course_certification', '<ul class="course-policy-list"><li><strong>Certificate of Completion from Tertiary Courses</strong> - Upon meeting at least 75% attendance and passing the assessment(s), participants will receive a Certificate of Completion from Tertiary Courses.</li></ul>', NOW(), NOW(), 1);
INSERT INTO cms_block_store (block_id, store_id) VALUES (LAST_INSERT_ID(), 2);

-- ===== Ghana (store_id = 3) =====
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active) VALUES ('Ghana — Course Certification', 'course_certification', '<ul class="course-policy-list"><li><strong>Certificate of Completion from Tertiary Courses</strong> - Upon meeting at least 75% attendance and passing the assessment(s), participants will receive a Certificate of Completion from Tertiary Courses.</li></ul>', NOW(), NOW(), 1);
INSERT INTO cms_block_store (block_id, store_id) VALUES (LAST_INSERT_ID(), 3);

-- ===== Nigeria (store_id = 4) =====
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active) VALUES ('Nigeria — Course Certification', 'course_certification', '<ul class="course-policy-list"><li><strong>Certificate of Completion from Tertiary Courses</strong> - Upon meeting at least 75% attendance and passing the assessment(s), participants will receive a Certificate of Completion from Tertiary Courses.</li></ul>', NOW(), NOW(), 1);
INSERT INTO cms_block_store (block_id, store_id) VALUES (LAST_INSERT_ID(), 4);

-- ===== Bhutan (store_id = 5) =====
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active) VALUES ('Bhutan — Course Certification', 'course_certification', '<ul class="course-policy-list"><li><strong>Certificate of Completion from Tertiary Courses</strong> - Upon meeting at least 75% attendance and passing the assessment(s), participants will receive a Certificate of Completion from Tertiary Courses.</li></ul>', NOW(), NOW(), 1);
INSERT INTO cms_block_store (block_id, store_id) VALUES (LAST_INSERT_ID(), 5);

-- ===== India (store_id = 6) =====
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active) VALUES ('India — Course Certification', 'course_certification', '<ul class="course-policy-list"><li><strong>Certificate of Completion from Tertiary Courses</strong> - Upon meeting at least 75% attendance and passing the assessment(s), participants will receive a Certificate of Completion from Tertiary Courses.</li></ul>', NOW(), NOW(), 1);
INSERT INTO cms_block_store (block_id, store_id) VALUES (LAST_INSERT_ID(), 6);

-- ===== Infotech (store_id = 7) =====
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active) VALUES ('Infotech — Course Certification', 'course_certification', '<ul class="course-policy-list"><li><strong>Certificate of Completion from Tertiary Infotech</strong> - Upon meeting at least 75% attendance and passing the assessment(s), participants will receive a Certificate of Completion from Tertiary Infotech.</li></ul>', NOW(), NOW(), 1);
INSERT INTO cms_block_store (block_id, store_id) VALUES (LAST_INSERT_ID(), 7);
