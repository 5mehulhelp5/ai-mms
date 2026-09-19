-- 1439 built the C169 Funding block with CONCAT(...'\n'...), which MySQL stored as a
-- LITERAL backslash-n rather than a newline. Harmless to rendering but wrong in the
-- source; rewrite the block as a single plain string with real line breaks.
-- Content-only UPDATE by identifier (never ->save() a cms/block model).

UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>
<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-generative-ai-for-interviewing.html" title="WSQ - Generative AI for Interviewing">WSQ - Generative AI for Interviewing</a></span></p>'
 WHERE identifier = 'course_C169_funding_and_grant';
