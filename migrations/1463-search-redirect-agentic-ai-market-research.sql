-- Redirect "agentic ai market research" / "agentic ai for market research"
-- to the WSQ Agentic AI for Market Research course page.
--
-- SG-only (WSQ / TGS- courses do not exist on MY/GH) -- the store guard makes
-- this a no-op on partner sites.
--
-- Pattern is deliberately TIGHT ('agentic ai%market research'): a bare
-- '%market research%' would sweep in the unrelated "Market Research Using
-- Google Analytics 4" rows, several of which are empty on prod and two of
-- which already point correctly at the GA4 course.
--
-- NOT (redirect <=> @tgt) is NULL-safe: it fills unset rows AND overwrites
-- wrong ones, while no-opping on rows already correct.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-agentic-ai-for-market-research.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%agentic ai%market research%';
