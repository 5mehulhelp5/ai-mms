-- 1404: Split the "cowork" search terms between the Masterclass course page
--       and the Claude AI Series category.
--
--   *masterclas* terms  -> claude-cowork-masterclass.html   (the course itself)
--   all other cowork    -> claude-ai-series.html            (the series listing)
--
-- Supersedes 1399, which sent every cowork row to codex-ai-series.html.
-- 1399 is left untouched (an already-applied migration never re-runs on prod);
-- this higher-numbered file runs after it and wins on a rebuilt DB.
--
-- Live state before this change (all six on codex-ai-series.html):
--   Claude Cowork / Claude Cowork Masterclass / Cowork / WSQ - Claude Cowork /
--   claude cowork masterclas / claude cowork courses
-- Applied live on SG prod first; all six verified 302 -> their new target.
--
-- Match notes:
--  * '%masterclas%' (one trailing 's') deliberately catches both the correct
--    spelling and the real 'claude cowork masterclas' typo row, plus any
--    future variant -- new rows appear after a migration is written, so a
--    frozen exact-term IN() list would miss them.
--  * NOT (redirect <=> @tgt) is the NULL-safe guard: it fills unset rows AND
--    overwrites wrong ones, while no-opping on rows already correct. A bare
--    redirect <> @tgt would skip every redirect IS NULL row.
--  * Both patterns are anchored on 'cowork', which is specific enough that the
--    NULL-fill cannot sweep in unrelated empty rows. Collateral check on prod
--    returned zero non-cowork rows on either target.
--
-- Search redirects are per-store data; SG only (@sg guard). The COUNT is
-- tested with > 0 rather than = 1 (the SG guard count is not always 1).

SET @sg   := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @mc   := 'https://www.tertiarycourses.com.sg/claude-cowork-masterclass.html';
SET @cas  := 'https://www.tertiarycourses.com.sg/claude-ai-series.html';

-- Masterclass terms -> the course page
UPDATE catalogsearch_query
SET redirect = @mc, num_results = 1, is_processed = 1
WHERE @sg > 0
  AND store_id = 1
  AND NOT (redirect <=> @mc)
  AND LOWER(query_text) LIKE '%cowork%'
  AND LOWER(query_text) LIKE '%masterclas%';

-- Every other cowork term -> the Claude AI Series listing
UPDATE catalogsearch_query
SET redirect = @cas, num_results = 1, is_processed = 1
WHERE @sg > 0
  AND store_id = 1
  AND NOT (redirect <=> @cas)
  AND LOWER(query_text) LIKE '%cowork%'
  AND LOWER(query_text) NOT LIKE '%masterclas%';
