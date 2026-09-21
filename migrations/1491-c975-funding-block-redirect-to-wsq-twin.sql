-- C975 Cisco Certified Network Associate (CCNA) Training — non-WSQ twin of TGS-2023037854.
-- A non-WSQ course carries no funding of its own, so its Funding block points the learner
-- at the funded WSQ version of the SAME course.
--
-- The block already targeted the right course but via a stale slug,
-- /wsq-certified-network-associate-ccna.html, which 301-chains to
-- /wsq-cisco-certified-network-associate-ccna.html. This flattens it to the canonical
-- URL (verified HTTP 200 directly, no redirect hop) so the learner never takes the extra hop.
--
-- House format preserved exactly — only the href/title/anchor text change.
-- Content-only UPDATE: never ->save() a cms/block model (wipes cms_block_store -> 404).
-- Guarded on the existing stale target so a re-run is a no-op.
-- SG production only; the base_url guard makes this a no-op on partner sites (MY/GH).

UPDATE cms_block
   SET content = CONCAT(
       '<h2>Funding and Grant Applications</h2>\n',
       '<p>No funding is available for this course</p>\n',
       '<p>For WSQ funding, please checkout the details at&nbsp;',
       '<span style="text-decoration: underline;">',
       '<a href="https://www.tertiarycourses.com.sg/wsq-cisco-certified-network-associate-ccna.html"',
       ' title="WSQ - Cisco Certified Network Associate (CCNA)">',
       'WSQ - Cisco Certified Network Associate (CCNA)</a></span></p>'
   )
 WHERE identifier = 'course_C975_funding_and_grant'
   AND content LIKE '%wsq-certified-network-associate-ccna.html%'
   AND content NOT LIKE '%wsq-cisco-certified-network-associate-ccna.html%'
   AND EXISTS (SELECT 1 FROM core_config_data
                WHERE path = 'web/unsecure/base_url'
                  AND value LIKE '%tertiarycourses.com.sg%');
