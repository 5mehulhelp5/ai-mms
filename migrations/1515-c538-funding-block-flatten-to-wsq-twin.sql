-- C538 "Basic Accounting using Xero" — point the Funding block straight at its
-- WSQ parent TGS-2026064172.
--
-- The block already linked to the right course, but via the legacy slug
-- /wsq-xero-accounting-course.html, which 301s to
-- /casl-xero-essentials-for-smes-streamlining-accounting-and-tax-operations.html.
-- Flatten the hop and use the parent's real title.
--
-- Content-only UPDATE: never ->save() a cms/block model, that wipes
-- cms_block_store and 404s the page (feedback_cms_model_save_wipes_store_mapping).
-- Idempotent: guarded on the old href, so a re-run is a no-op.

UPDATE cms_block
   SET content = CONCAT(
         '<p class="p1">No funding is available for this course.</p> ',
         '<p>For WSQ funding, please checkout the details at&nbsp;',
         '<span style="text-decoration: underline;">',
         '<a href="https://www.tertiarycourses.com.sg/casl-xero-essentials-for-smes-streamlining-accounting-and-tax-operations.html" ',
         'title="WSQ - Xero Essentials for SMEs: Streamlining Accounting and Tax Operations">',
         'WSQ - Xero Essentials for SMEs: Streamlining Accounting and Tax Operations',
         '</a></span></p>')
 WHERE identifier = 'course_C538_funding_and_grant'
   AND content LIKE '%wsq-xero-accounting-course.html%';
