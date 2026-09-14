-- 1399: Repoint the "Claude Cowork" search terms at the Codex AI Series category.
--
-- Supersedes migration 1396, which sent these same rows to
-- claude-cowork-masterclass.html. That page is still live (HTTP 200); this is a
-- deliberate retarget requested 2026-09-15, not a rot fix. 1396 is left
-- untouched because an edited migration never re-runs on prod -- this file
-- runs after it and wins on a rebuilt DB.
--
-- 5 rows corrected live on SG prod before writing this file; all 5 verified
-- 302 -> target. Collateral check clean (no non-cowork/codex row acquired the
-- target). NOT (redirect <=> @tgt) is the NULL-safe guard: it fills unset rows
-- AND overwrites wrong ones.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/codex-ai-series.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg > 0
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%cowork%';
