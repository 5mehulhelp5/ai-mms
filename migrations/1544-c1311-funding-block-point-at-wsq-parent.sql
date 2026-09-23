-- 1544: C1311 funding block -> point at its real WSQ parent
--
-- C1311 "Generative AI for Sustainability Reporting" is the non-WSQ twin of
-- TGS-2023036644 "AI for Sustainability Reporting". A non-WSQ course carries no
-- funding of its own, so its Funding block redirects the learner to the funded
-- WSQ course it was duplicated from.
--
-- The stored block pointed at "WSQ - Generative AI for Content Creation", an
-- UNRELATED course left over from a previous life of this C-entity. That URL
-- returns 200, so the defect is invisible to a link check — it is simply the
-- wrong course. Repointed at the actual parent, verified HTTP 200 with zero
-- redirect hops:
--   https://www.tertiarycourses.com.sg/ai-for-sustainability-reporting.html
--
-- Content-only UPDATE: never `->save()` a cms/block model, which wipes the
-- cms_block_store mapping and 404s the page.
-- SG production only; keyed by identifier so a partner site without it no-ops.
-- Idempotent: re-running writes the same content.

UPDATE cms_block
   SET content = CONCAT(
     '<h2>Funding and Grant Applications</h2>',
     '<p>No funding is available for this course</p>',
     '<p>For WSQ funding, please checkout the details at&nbsp;',
     '<span style="text-decoration: underline;">',
     '<a href="https://www.tertiarycourses.com.sg/ai-for-sustainability-reporting.html" ',
     'title="AI for Sustainability Reporting">AI for Sustainability Reporting</a>',
     '</span></p>')
 WHERE identifier = 'course_C1311_funding_and_grant';
