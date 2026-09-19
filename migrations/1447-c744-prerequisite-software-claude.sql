-- 1446: Follow-up to 1442. C744's `prerequisite` still carried the Software
-- requirement from the entity's PRE-Claude life:
--
--   "Please download and install Unreal Engine from unrealengine.com ..."
--   (plus a stray dialogflow.com <a> left over from an even earlier repurpose)
--
-- This entity has been recycled twice, so the stale software paragraph survived
-- both the Unreal -> Claude Certified Associate repurpose and 1442
-- (feedback_recycled_entity_stale_prerequisite_software). It rendered live on
-- /claude-design-for-ux-ui.html under "Minimum Software/Hardware Requirement".
--
-- Only the Software <p> is replaced -- the entry requirements, attitude,
-- experience, age group and Hardware lines are generic house copy and stay.
--
-- Matched by REPLACE on the exact stale fragment so the surrounding copy is
-- untouched and a re-run is a no-op. Guarded on the fragment still being
-- present, so this is a clean no-op on partner sites and on re-apply.
--
-- NB the stored value uses LITERAL backslash-n, not real newlines -- the
-- fragment below is byte-matched against the live value.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C744');
SET @a_pre := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='prerequisite');

UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      '<p>Please download and install Unreal Engine from&nbsp;<a href="https://www.unrealengine.com/en-US/download" title="Unreal Engine" target="_blank">https://www.unrealengine.com/en-US/download</a><a href="https://dialogflow.com/" title="Unreal Engine" target="_blank"><br /></a></p>',
      '<p>A Claude account (Free, Pro or Team) at&nbsp;<a href="https://claude.ai/" title="Claude" target="_blank">https://claude.ai/</a>. A modern web browser is all that is required &mdash; no local install needed.</p>'
    )
WHERE entity_id = @e
  AND attribute_id = @a_pre
  AND @e IS NOT NULL
  AND value LIKE '%unrealengine.com%';
