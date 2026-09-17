-- Cache-bust the homepage carousel slide 3 banner image URL.
--
-- The image bytes at the R2 key were replaced (migration/session work on
-- 2026-09-17: swapped the AWS-branded certification-partner banner for the
-- non-AWS variant) but R2 serves the object with no Cache-Control header,
-- so browsers/any front CDN kept the old cached bytes under the same URL
-- indefinitely. Appending a version query string forces a fresh fetch
-- without touching the R2 object itself.
--
-- Scoped to the unique SG anchor (the R2 key + tertiarycourses.com.sg link)
-- per feedback_home_carousel_r2_banners -- never key off the bare filename,
-- since the same asset name is not necessarily shared, but matching by the
-- full URL keeps this a precise, idempotent swap either way.
--
-- SG-only (block_id 18 is the store_id=1-mapped block_slide3 row); no-op on
-- partner DBs where this identifier/content won't match.

UPDATE cms_block
SET content = REPLACE(
    content,
    'wysiwyg/wsq-skillsfuture-certification-exam-prep-courses.jpg"',
    'wysiwyg/wsq-skillsfuture-certification-exam-prep-courses.jpg?v=20260918"'
)
WHERE identifier = 'block_slide3'
  AND content LIKE '%tertiarycourses.com.sg/certification-exam-prep-courses.html%'
  AND content LIKE '%wysiwyg/wsq-skillsfuture-certification-exam-prep-courses.jpg"%';
