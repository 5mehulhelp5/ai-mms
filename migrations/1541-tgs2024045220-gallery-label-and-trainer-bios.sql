-- 1541: TGS-2024045220 -- media-gallery label + trainer bios still name the old course
--
-- Follow-up to 1540. Two places kept the pre-retitle course name and were
-- both visible on the live product page after 1540 applied:
--
--   1. catalog_product_entity_media_gallery_value.label -- the product image
--      gallery carries its OWN label, separate from the image_label /
--      small_image_label / thumbnail_label EAV attributes that 1540 updated.
--      It is what renders as the cover's alt="" and title="" text, so the
--      page still read the old course name twice.
--
--      It also spells the old title "(GAI)" where the EAV `name` spelled it
--      "(GenAI)", which is exactly why 1540's equality-matched label update
--      did not catch it. Matched here on the stable substring instead.
--
--   2. trainerprofile -- each trainer bio quotes the course by name in its
--      second paragraph ("In “<old title>,” <trainer> ..."). There are
--      several trainers on this course, so the phrase occurs many times.
--
-- Both are rewritten by REPLACE() on the old title text rather than by
-- wholesale overwrite, so trainer-specific copy is preserved and re-running
-- converges (the second run finds nothing left to replace).
--
-- Only the course TITLE changes; the WSQ prefix is retained in prose exactly
-- as 1540 retained it in `name`.
--
-- SG production only; keyed by SKU so a partner site with no TGS-2024045220
-- no-ops. Idempotent.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024045220' LIMIT 1);
SET @etype := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code='catalog_product');

-- 1. Media gallery label -> new title. Covers both the "(GAI)" and "(GenAI)"
--    spellings of the old name, at every store scope.
UPDATE catalog_product_entity_media_gallery_value v
  JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
   SET v.label = 'WSQ - Generative AI for Photoshop'
 WHERE g.entity_id = @pid AND @pid IS NOT NULL
   AND v.label LIKE '%Visuals in Photoshop and Firefly';

-- 2. Trainer bios: swap the quoted course title, leaving the rest of each
--    bio untouched. Two REPLACE passes for the two spellings in use.
SET @a_tp := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='trainerprofile' AND entity_type_id=@etype);
UPDATE catalog_product_entity_text
   SET value = REPLACE(
                 REPLACE(value,
                   'Generative AI (GenAI) Visuals in Photoshop and Firefly',
                   'Generative AI for Photoshop'),
                 'Generative AI (GAI) Visuals in Photoshop and Firefly',
                 'Generative AI for Photoshop')
 WHERE attribute_id = @a_tp AND entity_id = @pid
   AND @pid IS NOT NULL AND @a_tp IS NOT NULL;
