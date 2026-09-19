-- C169 "Generative AI for Interviewing" — point the Funding block at its own WSQ twin.
--
-- C169 is a recycled product entity: its Funding block still linked to
-- "WSQ - Learn C++ Fundamentals with AI Assisted Tools and Vibe Coding", the WSQ
-- twin of the course this entity used to hold (C Programming). After the
-- non-WSQ conversion from TGS-2024051421 the block must point at
-- /wsq-generative-ai-for-interviewing.html (verified HTTP 200 on SG).
--
-- Content-only UPDATE by identifier. Never ->save() a cms/block model: that wipes
-- cms_block_store and 404s the page (memory feedback_cms_model_save_wipes_store_mapping).
-- Idempotent: re-running rewrites the same content.

UPDATE cms_block
   SET content = CONCAT(
         '<h2>Funding and Grant Applications</h2>\n',
         '<p>No funding is available for this course</p>\n',
         '<p>For WSQ funding, please checkout the details at&nbsp;',
         '<span style="text-decoration: underline;">',
         '<a href="https://www.tertiarycourses.com.sg/wsq-generative-ai-for-interviewing.html" ',
         'title="WSQ - Generative AI for Interviewing">',
         'WSQ - Generative AI for Interviewing</a></span></p>')
 WHERE identifier = 'course_C169_funding_and_grant';

