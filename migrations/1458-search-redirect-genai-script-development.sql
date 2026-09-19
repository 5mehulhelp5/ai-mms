-- Search-term redirect: "genai script development" (and the full course title)
-- -> WSQ - Generative AI for Script Development and Storytelling (SKU TGS-2025056983, product 1866)
--
-- Applied live on SG prod 2026-09-20 (2 rows: 77944, 78555 -- both previously empty).
-- This file exists so a rebuilt/restored DB keeps the state.
--
-- NULL-safe guard NOT (redirect <=> @tgt): fills unset rows AND overwrites wrong
-- ones, while no-opping on rows already correct. A bare `redirect <> @tgt` would
-- silently skip every `redirect IS NULL` row.
--
-- Keyword '%script development%' is tight: it cannot match the large families of
-- empty rows around 'javascript', 'apps script', 'shell scripting' or the
-- 'data storytelling' courses. Collateral check on prod returned count=0.
--
-- SG-only: the target is a WSQ (TGS-) course, which does not exist on MY/GH.
-- The store guard makes this a no-op on partner sites.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-generative-ai-for-script-development-and-storytelling.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%script development%';
