-- Search-term redirects -> WSQ - Generative AI for Interviewing (TGS-2024051421, product 626)
--
-- Context: the course was RENAMED. The old slug
--   wsq-improve-hiring-decisions-with-genai-assisted-interview-questioning.html
-- is a 301 (options='RP') onto wsq-generative-ai-for-interviewing.html, so every
-- search row still carrying the old slug cost the user an extra hop. This points
-- the terms straight at the final URL (one hop) and adds the previously-empty
-- "genai interviewing" / "genai interview" / "ai interviewing" rows.
--
-- Guard notes:
--  * NOT (redirect <=> @tgt) is NULL-safe: it fills unset rows AND overwrites the
--    stale old-slug rows, while no-opping on rows already correct. A bare
--    `redirect <> @tgt` would skip every redirect IS NULL row.
--  * The term matching is deliberately TIGHT (explicit list + course-title
--    patterns). A bare '%genai%' or '%interview%' LIKE would capture the ~180
--    unrelated empty %genai% rows on a rebuilt DB.
--  * SG-only: WSQ/TGS- courses do not exist on MY/GH, so the store guard makes
--    this a no-op there.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-generative-ai-for-interviewing.html';

-- 1. The requested term + its close variants, and the course-title families.
UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND (
        LOWER(query_text) IN (
          'genai interviewing',
          'genai interview',
          'ai interviewing',
          'interviewing',
          'interview',
          'wsq interview',
          'generative ai for interviewing'
        )
     OR LOWER(query_text) LIKE '%genai assisted interview%'
     OR LOWER(query_text) LIKE '%genai interview questioning%'
     OR LOWER(query_text) LIKE '%ai assisted interview question%'
     OR LOWER(query_text) LIKE '%generative ai for interviewing%'
  );

-- 2. Flatten any row still aimed at the retired slug onto the live URL.
--    (Covers 'Improve Hiring Decision', the TGS- code, 'hiring', 'decisions', etc.
--     which already belonged to this course but routed through the 301.)
UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND redirect LIKE '%improve-hiring-decisions%';
