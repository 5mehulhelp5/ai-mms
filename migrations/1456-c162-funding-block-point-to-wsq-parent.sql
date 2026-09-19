-- 1456: C162 "Generative AI for 3D Modeling" — repoint the Funding block at
-- its OWN WSQ parent.
--
-- C162 was converted from the WSQ course TGS-2023037544
-- (/wsq-generative-ai-for-3d-modeling.html), but its Funding block still
-- linked to "WSQ - 3D Modelling with Blender for Beginners"
-- (/wsq-3d-modeling-with-blender.html) — an unrelated Blender course picked up
-- from the bulk seed, not this course's twin. A learner following the funding
-- link landed on a different syllabus.
--
-- Non-WSQ courses carry no funding of their own (the "No funding is available"
-- line stays); the block exists purely to point at the funded WSQ equivalent.
-- See project_nonwsq_courseware_no_funding_at_all.
--
-- Content-only UPDATE keyed on identifier. NEVER ->save() a cms/block model
-- here: that wipes cms_block_store and 404s the page
-- (feedback_cms_model_save_wipes_store_mapping).
--
-- Target verified 200 on www.tertiarycourses.com.sg before shipping.
-- Idempotent: re-running writes the same content. Partner-safe — the
-- identifier does not exist on MY/GH, so this is a clean no-op there.

UPDATE cms_block
   SET content = CONCAT(
       '<h2>Funding and Grant Applications</h2>',
       '<p class="p1">No funding is available for this course.</p>',
       '<p>For WSQ funding, please checkout the details at&nbsp;',
       '<span style="text-decoration: underline;">',
       '<a href="https://www.tertiarycourses.com.sg/wsq-generative-ai-for-3d-modeling.html" ',
       'title="WSQ - Generative AI for 3D Modeling">',
       'WSQ - Generative AI for 3D Modeling</a></span></p>')
 WHERE identifier = 'course_C162_funding_and_grant';
