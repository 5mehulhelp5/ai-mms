-- C11 (Generative AI for SEO) — point the Funding block at its own WSQ twin.
--
-- C11 is the non-WSQ duplicate of TGS-2020503501 "Generative AI for Search
-- Engine Optimization (SEO)", but its funding block cross-linked to
-- "WSQ - Generative AI for Content Creation" — a different course. A learner
-- reading the non-WSQ SEO page and wanting the funded version was sent to the
-- wrong subject entirely.
--
-- Non-WSQ courses carry no funding of their own, so the block's job is purely
-- to redirect to the funded WSQ equivalent. Target verified 200 on
-- www.tertiarycourses.com.sg before shipping.
--
-- Content-only UPDATE: never ->save() a cms/block model, which wipes the
-- cms_block_store mapping and 404s the page.
-- Idempotent: matches on the old href, so a re-run after it has been applied
-- is a no-op.

UPDATE cms_block
   SET content = REPLACE(
         REPLACE(
           content,
           'https://www.tertiarycourses.com.sg/wsq-generative-ai-for-content-creation.html',
           'https://www.tertiarycourses.com.sg/wsq-generative-ai-for-search-engine-optimization-seo.html'
         ),
         'WSQ - Generative AI for Content Creation',
         'WSQ - Generative AI for Search Engine Optimization (SEO)'
       )
 WHERE identifier = 'course_C11_funding_and_grant'
   AND content LIKE '%wsq-generative-ai-for-content-creation.html%';
