-- Drop the "Training Centers venue :" heading text (and its trailing <br/>)
-- from the SG contact CMS blocks. The icon + address line is self-evident;
-- the heading was redundant and visually noisy.
--
-- SG page block (id=23) uses `<br/>` (no space); SG footer block (id=7) uses
-- `<br />` (with space) — each variant is replaced explicitly.
--
-- Other countries use "Training Center Locations :" (different wording) and
-- are intentionally left alone.
--
-- Idempotent: REPLACE() on already-stripped content is a no-op.

UPDATE cms_block
SET content = REPLACE(content, 'Training Centers venue : <br/>', '')
WHERE block_id = 23;

UPDATE cms_block
SET content = REPLACE(content, 'Training Centers venue : <br />', '')
WHERE block_id = 7;
