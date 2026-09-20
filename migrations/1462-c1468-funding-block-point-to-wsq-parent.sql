-- C1468 "Generative AI for Social Media Marketing" — point the Funding block
-- at its own WSQ parent.
--
-- C1468's courseware was duplicated from TGS-2021003023 (live title
-- "WSQ - Generative AI for Social Media Marketing"), so the non-WSQ page's
-- Funding block must redirect to THAT course. A non-WSQ course carries no
-- funding of its own, but the learner reading this page is exactly the person
-- who should be told the funded twin exists.
--
-- Before this change the block pointed at "WSQ - Generative AI for Content
-- Creation" (wsq-generative-ai-for-content-creation.html) — a leftover from
-- when C1468 was "Generative AI for Digital Marketing". That is an unrelated
-- course, so the reader was sent to the wrong funded option.
--
-- Verified before shipping:
--   wsq-generative-ai-for-social-media-marketing.html -> 200 on www.tertiarycourses.com.sg
--
-- Identifier matched by HEX so a stray whitespace character cannot make this
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
         '<a href="https://www.tertiarycourses.com.sg/wsq-generative-ai-for-social-media-marketing.html" ',
         'title="WSQ - Generative AI for Social Media Marketing">',
         'WSQ - Generative AI for Social Media Marketing</a></span></p>'
       ),
       is_active = 1,
       update_time = NOW()
 WHERE HEX(identifier) = '636F757273655F43313436385F66756E64696E675F616E645F6772616E74';

-- Map to store 0 (all stores) only if the mapping is absent. Never ->save() the
-- model; this INSERT is the safe way to guarantee the block renders.
INSERT INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0
  FROM cms_block b
 WHERE HEX(b.identifier) = '636F757273655F43313436385F66756E64696E675F616E645F6772616E74'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s WHERE s.block_id = b.block_id);
