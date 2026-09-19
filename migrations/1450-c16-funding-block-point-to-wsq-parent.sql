-- C16 "Generative AI for Adobe Photoshop" — point the Funding block at its own WSQ parent.
--
-- C16 was duplicated from TGS-2024045220 "Generative AI (GenAI) Visuals in Photoshop
-- and Firefly", so the non-WSQ page's Funding block must redirect to THAT course.
-- It was pointing at "WSQ - Generative AI for Content Creation", an unrelated course.
--
-- NOTE: the block identifier carries a stray SPACE — 'course_C16 _funding_and_grant'
-- (hex ...433136 20 5F...). Matching on the clean identifier finds nothing, so the
-- guard below matches the identifier by HEX. See memory
-- feedback_cms_block_identifier_whitespace_taint.
--
-- Content-only UPDATE: never ->save() a cms/block model, which wipes cms_block_store
-- and 404s the page. See memory feedback_cms_model_save_wipes_store_mapping.
--
-- Idempotent: re-running rewrites the same content.

UPDATE cms_block
   SET content = CONCAT(
         '<h2>Funding and Grant Applications</h2>\n',
         '<p>No funding is available for this course</p>\n',
         '<p>For WSQ funding, please checkout the details at&nbsp;',
         '<span style="text-decoration: underline;">',
         '<a href="https://www.tertiarycourses.com.sg/wsq-generative-ai-genai-visuals-in-photoshop-and-firefly.html" ',
         'title="WSQ - Generative AI (GenAI) Visuals in Photoshop and Firefly">',
         'WSQ - Generative AI (GenAI) Visuals in Photoshop and Firefly</a></span></p>'
       )
 WHERE HEX(identifier) = '636F757273655F433136205F66756E64696E675F616E645F6772616E74';
