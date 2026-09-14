-- 1396: Redirect "Claude Cowork Masterclass" search terms to their own course page.
--
-- These rows were previously pointed at claude-ai-series.html (a correction,
-- not a fill) -- verified live on SG prod before writing this migration.
-- Already applied live; this migration keeps a rebuilt/restored DB in sync.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/claude-cowork-masterclass.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg > 0
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%cowork%';
