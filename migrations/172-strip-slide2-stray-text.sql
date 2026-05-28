-- block_slide2 (SG homepage banner slide 2) contains a stray "&lt;a?"
-- fragment from a past WYSIWYG edit, which renders as visible "<a?" text
-- below the banner on the storefront. Replace the whole content with the
-- clean version. Guarded with WHERE LIKE so it's a no-op if already clean.

UPDATE cms_block
SET content = '<a href="https://www.tertiarycourses.com.sg/comptia-certification-exam-prep-courses.html"><img alt="CompTIA Certification Exam Prep - Tertiary Courses Singapore" src="https://www.tertiarycourses.com.sg/media/wysiwyg/Comptia-cybsercurity.jpg" /></a>'
WHERE identifier = 'block_slide2'
  AND content LIKE '%&lt;a?%';
