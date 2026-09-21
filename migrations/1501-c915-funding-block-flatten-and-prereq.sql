-- C915 PL-400 Microsoft Power Platform Developer Training — storefront cleanup
-- after the non-WSQ courseware conversion from TGS-2023039340.
--
-- Two data-only fixes, both idempotent via their WHERE guards:
--
-- 1. Funding block: the link already points at the WSQ twin, but at the OLD
--    slug (…-pl-400-certification-prep.html), which 301s to
--    …-pl-400.html. Flatten the hop so the block links the live URL directly
--    (verified 200, no redirect, on www.tertiarycourses.com.sg).
--    Content-only UPDATE: never ->save() a cms/block model — that wipes the
--    cms_block_store mapping and 404s the page.
--
-- 2. Prerequisite: the blob carries the WSQ *minimum entry requirement*
--    (3 GCE 'O' Levels / WPL Level 5), which is a WSQ admission criterion and
--    does not apply to a non-WSQ course. It is removed; the Promotion Code,
--    Attitude, Experience, Target Age Group and the hardware requirement are
--    kept. (The stale "Raspberry Pi 4" software line is removed by 1504, which
--    needed a CRLF-aware pattern.)

UPDATE cms_block
   SET content = '<p>No funding is available for this course</p> <p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-microsoft-power-platform-developer-pl-400.html" title="WSQ - Microsoft Power Platform Developer (PL-400)">WSQ - Microsoft Power Platform Developer (PL-400)</a></span><span style="text-decoration: underline;"></span></p>'
 WHERE identifier = 'course_C915_funding_and_grant'
   AND content LIKE '%pl-400-certification-prep%';

-- 2a. Drop the WSQ minimum-entry bullet (3 GCE 'O' Levels / WPL Level 5).
--     A non-WSQ course has no WSQ admission criterion. The surrounding
--     "Knowledge and Skills" list and its first bullet are kept.
UPDATE catalog_product_entity_text t
  JOIN eav_attribute a ON a.attribute_id = t.attribute_id
                      AND a.attribute_code = 'prerequisite'
  JOIN eav_entity_type et ON et.entity_type_id = a.entity_type_id
                         AND et.entity_type_code = 'catalog_product'
  JOIN catalog_product_entity e ON e.entity_id = t.entity_id AND e.sku = 'C915'
   SET t.value = REPLACE(
         t.value,
         '<li>Minimum 3 GCE &lsquo;O&rsquo; Levels Passes including English or WPL Level 5 (Average of Reading, Listening, Speaking &amp; Writing Scores)</li>',
         '')
 WHERE t.value LIKE '%WPL Level 5%';
