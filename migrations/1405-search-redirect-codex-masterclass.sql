-- 1405: Point the "codex masterclass" search terms at the Codex Masterclass
--       course page (C989), and the "code masterclass" terms at the Claude
--       Code Masterclass course page (C1417).
--
-- Live rows before this change (both empty -- a fill, not a correction):
--   'codex masterclass'         pop 2  => []
--   'claude codex masterclass'  pop 1  => []
-- Applied live on SG prod first; both verified 302 -> target.
--
-- Match notes:
--  * Requires BOTH '%codex%' AND '%masterclas%'. The 'codex' keyword alone is
--    generic on this catalog -- SG prod carries ~25 empty codex typo rows
--    (cdex, coedx, ocdex, ...) already pointed at codex-ai-series.html by
--    earlier work -- so a bare '%codex%' NULL-fill would hijack the series
--    listing. The two-term AND keeps it surgical.
--  * '%masterclas%' (one trailing 's') also catches the common dropped-s typo
--    and any future variant row; rows are created by real searchers after a
--    migration is written, so a frozen exact-term IN() list would miss them.
--  * NOT (redirect <=> @tgt) is the NULL-safe guard -- fills unset rows AND
--    overwrites wrong ones, no-ops on rows already correct. A bare
--    redirect <> @tgt silently skips every redirect IS NULL row.
--
-- Collateral check on prod returned one row, 'c0989' -- a pre-existing
-- SKU-style search for C989 set 2026-07-20, already pointing at this same
-- course page. Correct as-is and deliberately left alone.
--
-- SG-only data (@sg guard); COUNT tested with > 0, not = 1.

SET @sg   := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @codex := 'https://www.tertiarycourses.com.sg/codex-masterclass.html';
SET @code  := 'https://www.tertiarycourses.com.sg/claude-code-masterclass.html';

-- codex masterclass -> Codex Masterclass (C989)
UPDATE catalogsearch_query
SET redirect = @codex, num_results = 1, is_processed = 1
WHERE @sg > 0
  AND store_id = 1
  AND NOT (redirect <=> @codex)
  AND LOWER(query_text) LIKE '%codex%'
  AND LOWER(query_text) LIKE '%masterclas%';

-- code masterclass -> Claude Code Masterclass (C1417)
--
-- ORDER MATTERS + the NOT LIKE '%codex%' exclusion is load-bearing: 'codex'
-- CONTAINS the substring 'code', so a bare '%code%' pattern matches every
-- codex row too and would clobber the redirect set immediately above. Live
-- rows 'codex masterclass' and 'claude codex masterclass' both matched
-- '%code%' on prod -- without this exclusion they would have been retargeted
-- at the wrong course. Verified: exactly 2 rows changed
-- ('Claude Code Masterclass', 'code masterclass') and both codex rows kept
-- their own target.
UPDATE catalogsearch_query
SET redirect = @code, num_results = 1, is_processed = 1
WHERE @sg > 0
  AND store_id = 1
  AND NOT (redirect <=> @code)
  AND LOWER(query_text) LIKE '%code%'
  AND LOWER(query_text) NOT LIKE '%codex%'
  AND LOWER(query_text) LIKE '%masterclas%';
