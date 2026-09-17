-- Search-term redirects -> WSQ - Business Innovation with Agentic AI and AI Agents
-- (product 1425, SKU TGS-2023037472)
--
-- Applied live on SG prod 2026-09-17; this file exists so a rebuilt/restored DB
-- keeps the same state.
--
-- NOTE ON SCOPE (deliberate, user-confirmed 2026-09-17):
--   Two OTHER live courses share this wording and are intentionally overridden here:
--     * TGS-2020503395 "WSQ - Business Innovation with AI Agents"
--                      (/wsq-business-innovation-with-ai-agents.html)
--     * TGS-2024049182 "WSQ - Business Transformation with Agentic AI and AI Agents"
--                      (/wsq-business-transformation-with-agentic-ai-and-ai-agents.html)
--   Searches matching their titles are sent to the Business Innovation course above
--   as explicitly requested. Do not "correct" this back without re-asking.
--
-- The '%vibe coding%' exclusion protects
--   "Business Innovation with Agentic Vibe Coding & Agentic AI Workforce",
-- which is a different course and was NOT part of the request.
--
-- Guard is NULL-safe: NOT (redirect <=> @tgt) fills unset rows AND overwrites
-- wrong ones, while no-opping rows already correct. A bare `redirect <> @tgt`
-- would silently skip every `redirect IS NULL` row.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-business-innovation-with-agentic-ai-and-ai-agents.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) NOT LIKE '%vibe coding%'
  AND (
        LOWER(query_text) LIKE '%business innovation%agentic%'
     OR LOWER(query_text) LIKE '%business transformation%agentic%'
     OR LOWER(query_text) LIKE '%business innovation%ai agent%'
     OR LOWER(query_text) LIKE '%business transformation%ai agent%'
  );
