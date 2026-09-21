-- C1071 AI-901 Microsoft Azure AI Fundamentals: point the Funding block at its
-- WSQ twin TGS-2023021100, the course it was duplicated from.
--
-- A non-WSQ course carries no funding of its own, but the learner reading its
-- page is often exactly the person who should be told the funded WSQ version
-- exists. Content-only UPDATE: never ->save() a cms/block model, which wipes
-- the cms_block_store mapping and 404s the page.
--
-- Idempotent: the WHERE guard makes a re-run a no-op once applied.
-- Target verified 200 (no redirect) on www.tertiarycourses.com.sg.

UPDATE cms_block
   SET content = '<p>No funding is available for this course</p> <p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-microsoft-azure-ai-fundamentals-ai-900.html" title="WSQ - Microsoft Azure AI Fundamentals (AI-900)">WSQ - Microsoft Azure AI Fundamentals (AI-900)</a></span><span style="text-decoration: underline;"></span></p>'
 WHERE identifier = 'course_C1071_funding_and_grant'
   AND content NOT LIKE '%wsq-microsoft-azure-ai-fundamentals-ai-900%';
