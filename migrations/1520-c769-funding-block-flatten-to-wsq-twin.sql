-- C769 "Statistical Process Control (SPC) Training" — point the Funding block
-- straight at its funded parent TGS-2026064862.
--
-- The block already linked to the right course, but via the legacy slug
-- /wsq-spc-training.html, which 301s to
-- /casl-statistical-process-control-spc-in-manufacturing.html.
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
         '<a href="https://www.tertiarycourses.com.sg/casl-statistical-process-control-spc-in-manufacturing.html" ',
         'title="CASL - Statistical Process Control (SPC) in Manufacturing">',
         'CASL - Statistical Process Control (SPC) in Manufacturing',
         '</a></span></p>')
 WHERE identifier = 'course_C769_funding_and_grant'
   AND content LIKE '%wsq-spc-training.html%';
