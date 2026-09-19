-- C209 "Automate Business Processes with Agentic AI Workflows" — point the Funding
-- block at its own WSQ parent.
--
-- C209's courseware was duplicated from TGS-2024045801 "Agentic AI for Business
-- Process Automation" (live title "WSQ Building Agentic AI Workflows to Automate
-- Business Processes"), so the non-WSQ page's Funding block must redirect to THAT
-- course.
--
-- The block's anchor TEXT and title attribute already name the right course, but the
-- href pointed at an unrelated course —
-- wsq-creating-ai-agent-with-microsoft-semantic-kernel.html — which now 301s, so the
-- link was both wrong and a redirect hop. Verified before shipping:
--   wsq-agentic-ai-for-business-process-automation.html          -> 200
--   wsq-creating-ai-agent-with-microsoft-semantic-kernel.html    -> 301  (the old target)
--
-- Identifier is clean here (no whitespace taint), but it is still matched by HEX so a
-- stray space introduced later cannot make this silently no-op. See memory
-- feedback_cms_block_identifier_whitespace_taint.
--
-- Content-only UPDATE: never ->save() a cms/block model, which wipes cms_block_store
-- and 404s the page. See memory feedback_cms_model_save_wipes_store_mapping.
--
-- Idempotent: re-running rewrites the same content.

UPDATE cms_block
   SET content = CONCAT(
         '<p>For WSQ funding, please checkout the details at&nbsp;',
         '<a href="https://www.tertiarycourses.com.sg/wsq-agentic-ai-for-business-process-automation.html" ',
         'title="WSQ - Building Agentic AI Workflows to Automate Business Processes">',
         '<span style="text-decoration: underline;">',
         'WSQ - Building Agentic AI Workflows to Automate Business Processes',
         '</span></a></p>'
       )
 WHERE HEX(identifier) = '636F757273655F433230395F66756E64696E675F616E645F6772616E74';
