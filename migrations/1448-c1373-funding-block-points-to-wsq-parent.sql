-- C1373 "Generative AI for Video Creation" is the non-WSQ twin of
-- TGS-2024043855 "WSQ - Creating Engaging Videos with Generative AI (GenAI)".
--
-- The non-WSQ course carries no funding of its own, so its Funding block
-- redirects to the funded WSQ course it was duplicated from. The block was
-- pointing at an unrelated WSQ course (wsq-generative-ai-for-content-creation),
-- left over from the product entity's previous life.
--
-- Content-only UPDATE: never ->save() a cms/block model, which wipes the
-- cms_block_store mapping and 404s the page.
-- Target verified 200 on www.tertiarycourses.com.sg.
-- Idempotent: re-running writes the same content.

UPDATE cms_block
   SET content = CONCAT(
         '<h2>Funding and Grant Applications</h2>',
         '<p>No funding is available for this course</p>',
         '<p>For WSQ funding, please checkout the details at&nbsp;',
         '<span style="text-decoration: underline;">',
         '<a href="https://www.tertiarycourses.com.sg/wsq-creating-engaging-videos-with-generative-ai-genai.html" ',
         'title="WSQ - Creating Engaging Videos with Generative AI (GenAI)">',
         'WSQ - Creating Engaging Videos with Generative AI (GenAI)</a></span></p>')
 WHERE identifier = 'course_C1373_funding_and_grant';
