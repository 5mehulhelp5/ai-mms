-- C437 Claude Certified Architect - Foundations Certification — non-WSQ twin of TGS-2026061312.
-- A non-WSQ course carries no funding of its own, so its Funding block points the learner
-- at the funded WSQ version of the SAME course.
--
-- The block pointed at "WSQ - Agentic AI Applications with Claude Code", which is a DIFFERENT
-- course. This repoints it at C437's actual WSQ parent, /wsq-claude-certified-architect-foundation.html
-- (verified HTTP 200, and that page reports Course Code TGS-2026061312).
--
-- House format preserved exactly — only the href/title/anchor text change.
-- Content-only UPDATE: never ->save() a cms/block model (wipes cms_block_store -> 404).
-- Guarded on the existing wrong target so a re-run is a no-op.
-- SG production only; the base_url guard makes this a no-op on partner sites (MY/GH).

UPDATE cms_block
   SET content = CONCAT(
       '<h2>Funding and Grant Applications</h2>\n',
       '<p>No funding is available for this course</p>\n',
       '<p>For WSQ funding, please checkout the details at&nbsp;',
       '<span style="text-decoration: underline;">',
       '<a href="https://www.tertiarycourses.com.sg/wsq-claude-certified-architect-foundation.html"',
       ' title="WSQ - Claude Certified Architect Foundation">',
       'WSQ - Claude Certified Architect Foundation</a></span></p>'
   )
 WHERE identifier = 'course_C437_funding_and_grant'
   AND content LIKE '%wsq-agentic-ai-applications-with-claude-code%'
   AND EXISTS (SELECT 1 FROM core_config_data
                WHERE path = 'web/unsecure/base_url'
                  AND value LIKE '%tertiarycourses.com.sg%');
