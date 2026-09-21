-- C134 "QuickBooks Online Plus Training (Cloud Version)" — point the Funding
-- block straight at its funded parent TGS-2020505113.
--
-- The block already linked to the right course, but via the legacy slug
-- /wsq-quickbooks-online-plus-course.html, which 301s to
-- /casl-quickbooks-accounting-system-for-small-and-medium-enterprises.html.
-- Flatten the hop and use the parent's real (CASL) title.
--
-- Content-only UPDATE: never ->save() a cms/block model, that wipes
-- cms_block_store and 404s the page (feedback_cms_model_save_wipes_store_mapping).
-- Idempotent: guarded on the old href, so a re-run is a no-op.

UPDATE cms_block
   SET content = CONCAT(
         '<p class="p1">No funding is available for this course.</p> ',
         '<p>For WSQ funding, please checkout the details at&nbsp;',
         '<span style="text-decoration: underline;">',
         '<a href="https://www.tertiarycourses.com.sg/casl-quickbooks-accounting-system-for-small-and-medium-enterprises.html" ',
         'title="CASL - Quickbooks Accounting System for Small and Medium Enterprises">',
         'CASL - Quickbooks Accounting System for Small and Medium Enterprises',
         '</a></span></p>')
 WHERE identifier = 'course_C134_funding_and_grant'
   AND content LIKE '%wsq-quickbooks-online-plus-course.html%';
