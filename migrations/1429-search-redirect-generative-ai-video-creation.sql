-- Search-term redirect: "Generative AI for Video Creation" and its close variants
-- -> WSQ - Creating Engaging Videos with Generative AI (GenAI)
--
-- Applied live on SG prod 2026-09-19 (18 rows changed); this file keeps the state
-- across a DB rebuild/restore.
--
-- Scope is deliberately tight. Several OTHER live video+AI courses share these
-- tokens and must NOT be captured:
--   wsq-agentic-ai-for-video-creation.html
--   wsq-automate-creative-video-editing-with-agentic-ai-workflows-and-n8n.html
--   wsq-automate-video-and-voice-ai-agents-with-n8n.html
--   wsq-generative-ai-for-image-and-video-creation.html
--   build-end-to-end-agentic-ai-for-short-form-video-creation.html
-- Hence the NOT LIKE exclusions below. Collateral check after apply: rows on the
-- target that do not contain 'video' must be unchanged pre-existing rows only.
--
-- NULL-safe guard NOT (redirect <=> @tgt): fills unset rows AND overwrites the
-- rows that pointed at the 301-chaining ...generative-ai.html (no -genai) slug.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-creating-engaging-videos-with-generative-ai-genai.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%video%'
  AND (   LOWER(query_text) LIKE '%generative%'
       OR LOWER(query_text) LIKE '%genai%'
       OR LOWER(query_text) LIKE '%gen ai%'
       OR LOWER(query_text) LIKE '%gai %')
  AND LOWER(query_text) NOT LIKE '%agentic%'
  AND LOWER(query_text) NOT LIKE '%image%'
  AND LOWER(query_text) NOT LIKE '%n8n%'
  AND LOWER(query_text) NOT LIKE '%voice%'
  AND LOWER(query_text) NOT LIKE '%short-form%'
  AND LOWER(query_text) NOT LIKE '%editing%'
  AND LOWER(query_text) NOT LIKE '%vibe%'
  AND LOWER(query_text) NOT LIKE '%opencv%'
  AND LOWER(query_text) NOT LIKE '%digital transformation%';
