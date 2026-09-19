-- C1798 "Agentic AI for Digital Marketing and Advertising" — point the Funding
-- block at its own WSQ parent.
--
-- C1798's courseware was duplicated from TGS-2025056988 "Agentic AI for Digital
-- Marketing" (live title "WSQ - Agentic AI for Digital Marketing"), so the
-- non-WSQ page's Funding block must redirect to THAT course. A non-WSQ course
-- carries no funding of its own, but the learner reading this page is exactly
-- the person who should be told the funded twin exists.
--
-- Before this change the block read only "No funding is available for this
-- course." with no onward link (see migration 1455's notes), so the reader was
-- given a dead end rather than the funded option.
--
-- Verified before shipping:
--   wsq-agentic-ai-for-digital-marketing.html  -> 200 on www.tertiarycourses.com.sg
--
-- Identifier is clean here (no whitespace taint — hex confirmed), but it is
-- still matched by HEX so a stray space introduced later cannot make this
-- silently no-op. See memory feedback_cms_block_identifier_whitespace_taint.
--
-- Content-only UPDATE: never ->save() a cms/block model, which wipes
-- cms_block_store and 404s the page. See memory
-- feedback_cms_model_save_wipes_store_mapping.
--
-- SG production only — partner sites (MY/GH) have no WSQ twin. The guard is the
-- identifier itself: the block does not exist on partner DBs, so this is a
-- no-op there.
--
-- Idempotent: re-running rewrites the same content.

UPDATE cms_block
   SET content = CONCAT(
         '<p>No funding is available for this course</p> ',
         '<p>For WSQ funding, please checkout the details at&nbsp;',
         '<span style="text-decoration: underline;">',
         '<a href="https://www.tertiarycourses.com.sg/wsq-agentic-ai-for-digital-marketing.html" ',
         'title="WSQ - Agentic AI for Digital Marketing">',
         'WSQ - Agentic AI for Digital Marketing</a></span></p>'
       ),
       is_active = 1,
       update_time = NOW()
 WHERE HEX(identifier) = '636F757273655F43313739385F66756E64696E675F616E645F6772616E74';

-- Map to store 0 (all stores) only if the mapping is absent. Never ->save() the
-- model; this INSERT is the safe way to guarantee the block renders.
INSERT INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0
  FROM cms_block b
 WHERE HEX(b.identifier) = '636F757273655F43313739385F66756E64696E675F616E645F6772616E74'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s WHERE s.block_id = b.block_id);
