-- 1428: C364 -- clear the Unreal-era leftovers missed by 1427.
--
-- 1427 repurposed C364 into "Generative AI for Script Development and
-- Storytelling", but this entity has had two prior lives (Maya -> Unreal
-- Essential Training -> Claude Certified Architect) and three TEXT attributes
-- still rendered Unreal Engine game-development content on the live product page:
--
--   whoshouldattend  -> "Game Developer / 3D Artist / Level Designer / VR
--                        Developer / Gameplay Programmer / VFX Artist ..."
--   prerequisite     -> "Software: Please download and install Unreal Engine
--                        from unrealengine.com"
--   trainerprofile   -> "Tan Wei Liang; ... game developer with more than t0
--                        years experience in game development using Unity and
--                        Unreal."
--
-- Found by reading the RENDERED page after applying 1427, not by grepping the
-- attributes that 1427 happened to touch -- a repurpose of a recycled entity has
-- to sweep the whole product, not just name/slug/topics (memory
-- feedback_recycled_entity_stale_prerequisite_software).
--
-- SOURCES:
-- * whoshouldattend is cloned verbatim from the WSQ parent TGS-2025056983 (the
--   20 creative/content roles), so the funded and unfunded editions agree.
-- * prerequisite is NOT cloned from the WSQ parent: that block carries the WSQ
--   Progressive Wage Model + SWDA funding-eligibility sections, which must never
--   appear on a non-WSQ C-prefix course. Only the SOFTWARE paragraph is swapped
--   (Unreal Engine -> the parent's free Veed.io account); the non-WSQ promo-code
--   line, entry requirements and "Target Age Group" are kept exactly as they are.
-- * trainerprofile drops ONLY the leading "Tan Wei Liang" paragraph (the Unity/
--   Unreal game-dev trainer). Jyoti Chopra and Dr. Alfred Ang are retained. The
--   blob is split on <strong>Name:</strong> boundaries by
--   catalog/product/view/trainers.phtml, so removing one whole <p> keeps the
--   accordion contract intact (memory reference_sg_server_access).
--
-- Every write is an idempotent, content-anchored REPLACE/UPDATE: re-running
-- finds no Unreal text and changes nothing.
-- SG-only via @mms_instance. ASCII-only payload.

SET @is_sg := IF(@mms_instance = 'SG', 1, 0);

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C364');

SET @a_who   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='whoshouldattend');
SET @a_prereq:= (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='prerequisite');
SET @a_tprof := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='trainerprofile');

-- ---------------------------------------------------------------------------
-- 1. Job Roles -- cloned from the WSQ parent TGS-2025056983.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = '<ul><li>Content Creator</li><li>Digital Marketing Executive</li><li>Video Producer</li><li>Scriptwriter</li><li>Storyboard Artist</li><li>Multimedia Designer</li><li>Social Media Manager</li><li>Creative Director</li><li>Brand Storyteller</li><li>Instructional Designer</li><li>Corporate Trainer</li><li>Marketing Communications Specialist</li><li>Advertising Executive</li><li>eLearning Developer</li><li>Copywriter</li><li>Public Relations Officer</li><li>Visual Content Developer</li><li>Digital Strategist</li><li>AI Content Developer</li><li>Creative Technologist</li></ul>'
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_who;

-- ---------------------------------------------------------------------------
-- 2. Software requirement -- Unreal Engine -> Veed.io (the parent's tool).
--    Anchored REPLACE on the exact Unreal paragraph so the surrounding non-WSQ
--    promo/entry/age-group content is untouched.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      '<p>Please download and install Unreal Engine from&nbsp;<a href="https://www.unrealengine.com/en-US/download" title="Unreal Engine" target="_blank">https://www.unrealengine.com/en-US/download</a><a href="https://dialogflow.com/" title="Unreal Engine" target="_blank"><br /></a></p>',
      '<p>Sign up for a free <span style="text-decoration: underline;"><a href="https://www.veed.io/signup" title="Veed.io" target="_blank">Veed.io Account</a></span></p>')
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_prereq
  AND value LIKE '%unrealengine.com%';

-- ---------------------------------------------------------------------------
-- 3. Trainer profile -- drop the Unity/Unreal game-dev trainer paragraph.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = TRIM(LEADING '\n' FROM REPLACE(
      value,
      '<p><strong>Tan Wei Liang; </strong>He is a ACTA Certified game developer with more than t0 years experience in game development using Unity and Unreal.</p>',
      ''))
WHERE @is_sg = 1 AND @e IS NOT NULL AND entity_id = @e AND attribute_id = @a_tprof
  AND value LIKE '%Tan Wei Liang%';
