-- Search-term redirects -> WSQ Develop Multi AI Agent Applications with Gemini Agent ADK
-- Applied live on SG prod 2026-09-14; this file keeps the state across a DB rebuild.
-- Patterns are tight on purpose: a bare %gemini% would sweep in Gemini Spark,
-- Google Workspace Gemini, Dialogflow and CrewAI/AutoGen rows.
-- NULL-safe guard fills empty rows AND overwrites wrong ones (row 71939 pointed
-- at the old "LLM Applications with Google Gemini" course).

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-develop-multi-ai-agent-applications-with-gemini-agent-adk.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg > 0
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND (
       LOWER(query_text) LIKE '%gemini%sdk%'
    OR LOWER(query_text) LIKE '%sdk%gemini%'
    OR LOWER(query_text) LIKE '%gemini%adk%'
    OR LOWER(query_text) LIKE '%gemini%multi%agent%'
    OR LOWER(query_text) LIKE '%multi%agent%gemini%'
  );
