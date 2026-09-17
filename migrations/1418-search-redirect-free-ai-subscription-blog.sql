-- Search-term redirects -> the "Free AI Subscription now live (SWDA-eligible
-- courses)" blog post.
--
-- Five learner-facing terms about the free AI tool subscription currently land
-- on a generic results page; point them at the announcement post instead.
--
-- Scope is an EXPLICIT term list, not a LIKE pattern: "ai subscription" /
-- "ai tool" are generic substrings that also match course-catalog rows which
-- must keep their existing targets, e.g.
--   "ai tools"                  -> chatgpt-and-generative-ai-courses.html
--   "ai tool subscription"      -> utap.html
--   "utap ai tools subscription"-> utap.html
-- A LIKE sweep would capture those plus every empty %ai tool% row on a rebuilt
-- DB. Verified 2026-09-17: only these five rows point at the blog post.
--
-- NOT (redirect <=> @tgt) is the NULL-safe guard -- it fills unset rows AND
-- overwrites wrong ones, while no-opping on rows already correct. A bare
-- `redirect <> @tgt` would skip every `redirect IS NULL` row.
--
-- Rows are seeded when absent: four of the five terms had no catalogsearch_query
-- row at all (a redirect can only exist on a row), so a pure UPDATE would be a
-- silent no-op on a rebuilt DB.
--
-- SG-only: guarded on store_id 1 / code 'singapore', so MY/GH are a no-op.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/blog/free-ai-subscription-now-live-swda-eligible-courses';

-- Seed any missing term (is_processed = 0 so the storefront does not treat the
-- row as an already-run search; num_results = 1 keeps it out of the
-- "no results" reporting).
INSERT INTO catalogsearch_query
    (query_text, store_id, num_results, popularity, redirect, is_processed, display_in_terms, is_active, updated_at)
SELECT t.qt, 1, 1, 1, @tgt, 0, 1, 1, NOW()
FROM (
    SELECT 'free ai subscription'           AS qt
    UNION ALL SELECT 'free ai subscriptions'
    UNION ALL SELECT '6 months free ai subscription'
    UNION ALL SELECT 'free ai tools'
    UNION ALL SELECT 'free ai tool subscription'
) AS t
WHERE @sg = 1
  AND NOT EXISTS (
      SELECT 1 FROM catalogsearch_query q
      WHERE q.store_id = 1 AND LOWER(q.query_text) = t.qt
  );

-- Point existing rows (and anything seeded above) at the post.
UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 0
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) IN (
      'free ai subscription',
      'free ai subscriptions',
      '6 months free ai subscription',
      'free ai tools',
      'free ai tool subscription'
  );
