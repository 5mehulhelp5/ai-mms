-- 1527: flatten C523's funding block link to the WSQ twin's direct URL
--
-- The block linked to wsq-project-management-professional-pmp-training.html,
-- which 301s to wsq-project-management-professional.html. The hop is avoidable
-- and the direct URL is the canonical one.
--
-- Content-only UPDATE: never ->save() a cms/block model, that wipes
-- cms_block_store and 404s the page (feedback_cms_model_save_wipes_store_mapping).
-- Guarded on the old URL so a re-run is a no-op.

UPDATE cms_block
   SET content = REPLACE(content,
        'wsq-project-management-professional-pmp-training.html',
        'wsq-project-management-professional.html')
 WHERE identifier = 'course_C523_funding_and_grant'
   AND content LIKE '%wsq-project-management-professional-pmp-training.html%';
