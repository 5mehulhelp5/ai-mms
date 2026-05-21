-- Drop the Pearson VUE and HRD Corp logo `<img>` tags from the Malaysia
-- footer block (cms_block id=34, `block_footer_column5`). The list text
-- ("Pearson VUE Authorised Test Center" / "HRD Corp Approved Training
-- Provider") stays -- only the visual badge images are removed.
--
-- Idempotent: REPLACE() on already-stripped content is a no-op.

UPDATE cms_block
SET content = REPLACE(content,
'<img alt="Pearson VUE Authorised Test Center" src="https://www.tertiarycourses.com.sg/media/wysiwyg/Pearson-VUE-ATC-small.png" title="Pearson VUE Authorised Test Center with Tertiary Courses" />',
'')
WHERE block_id = 34;

UPDATE cms_block
SET content = REPLACE(content,
'<img alt="" src="https://www.tertiarycourses.com.sg/media/wysiwyg/HRD_Corp_Approved_Training_Provider_Tertiary_Courses_Malaysia.png" />',
'')
WHERE block_id = 34;
