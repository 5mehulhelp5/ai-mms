-- 1408: Point the "agentic ai for video (creation)" search terms at the
--       WSQ - Agentic AI for Video Creation course page (TGS-2023036088).
--
-- Live rows before this change (all empty -- a fill, not a correction):
--   'agentic ai for video creation'        pop 2  => []
--   'WSQ – Agentic AI for Video Creation'  pop 2  => []   (en-dash variant)
--   'WSQ - Agentic AI for Video Creation'  pop 1  => []   (hyphen variant)
--   'agentic ai for video'                 pop 1  => []
-- Applied live on SG prod first; all verified 302 -> target.
--
-- Match notes:
--  * The keyword MUST stay tight. A bare '%agentic%' or '%video%' would be a
--    disaster here: SG prod carries a SEPARATE live course,
--    wsq-automate-creative-video-editing-with-agentic-ai-workflows-and-n8n
--    (verified 200), which already legitimately owns 'agentic ai video',
--    'agentic video', 'agentic ai videos', 'creative video editing with
--    agentic AI workflows' and several full-title rows. Those must NOT be
--    retargeted -- both courses are live and each should stay findable.
--    Requiring the literal phrase 'agentic ai for video' (note the "for")
--    is what separates this course's terms from the n8n course's terms.
--  * The second pattern '%agentic ai%vid%creation%' catches the title-shaped
--    rows where punctuation/casing varies (the en-dash vs hyphen WSQ prefix).
--  * NOT (redirect <=> @tgt) is the NULL-safe guard -- fills unset rows AND
--    overwrites wrong ones, no-ops on rows already correct. A bare
--    redirect <> @tgt silently skips every redirect IS NULL row.
--
-- The 'cretation' typo row is seeded explicitly, NOT matched by pattern: the
-- user asked for that exact misspelling and no sane LIKE pattern covers an
-- arbitrary typo without also sweeping in the n8n course's rows. INSERT is
-- guarded by a NOT EXISTS so it stays idempotent (catalogsearch_query has no
-- unique key on (query_text, store_id) -- a plain INSERT ... ON DUPLICATE KEY
-- silently creates duplicate rows; that happened during live apply and had to
-- be cleaned up).
--
-- Collateral check on prod returned two rows, 'c436' and 'c0436' -- pre-existing
-- SKU-style searches for this same course, already pointing at this page.
-- Correct as-is and deliberately left alone.
--
-- SG-only data (@sg guard); COUNT tested with > 0, not = 1.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-agentic-ai-for-video-creation.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg > 0
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND ( LOWER(query_text) LIKE '%agentic ai for video%'
     OR LOWER(query_text) LIKE '%agentic ai%vid%creation%' );

-- Seed the requested 'cretation' typo row (idempotent).
INSERT INTO catalogsearch_query
  (query_text, store_id, num_results, popularity, redirect, is_processed)
SELECT 'agentic ai for video cretation', 1, 1, 1, @tgt, 1
FROM DUAL
WHERE @sg > 0
  AND NOT EXISTS (
    SELECT 1 FROM (SELECT * FROM catalogsearch_query) q
    WHERE q.store_id = 1
      AND LOWER(q.query_text) = 'agentic ai for video cretation'
  );
