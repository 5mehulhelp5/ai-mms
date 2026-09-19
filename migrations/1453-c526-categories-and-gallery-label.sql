-- 1453: C526 "No Code and Low Code Agentic AI Applications" -- clean up the two
--       leftovers migration 1451 did not cover: stale category memberships and
--       the stale media-gallery label.
--
-- Split from 1451 deliberately: 1451 is the content/schedule/URL repurpose,
-- this is the catalog placement that depends on it.
--
-- 1. CATEGORIES. C526 was a Facebook marketing course, so it sat in three
--    marketing categories that no longer describe it:
--
--      8   Digital Marketing        -> remove
--      118 Social Media Marketing   -> remove
--      162 Facebook                 -> remove
--
--    and it is missing the one its WSQ parent (TGS-2026062147) sits in:
--
--      282 n8n AI Automations       -> add
--
--    Kept: 3 (All Courses -- master listing), 55 (Infocomm Technology),
--    189 (Agentic AI Series), 252 (AI Courses). Those four already match the
--    parent. The parent's WSQ-only categories (196/292/301/325) are correctly
--    NOT added -- C526 is non-WSQ and carries no funding.
--
--    Both catalog_category_product AND catalog_category_product_index are
--    written: the storefront reads the index, so a membership change that
--    skips the index mirror is invisible until a full reindex.
--
-- 2. GALLERY LABEL. The single gallery row still reads "Complete Facebook
--    Marketing & Advertising SkillsFuture Training in Singapore", which the
--    product template emits as the cover image's alt/title text -- so the new
--    cover was being announced to screen readers and Google under the OLD
--    course name. Relabelled to the current course title.
--
--    The underlying image VALUE (/c/o/complete-facebook-training_1.jpg) is left
--    alone: the storefront renders course_image_url (the R2 PNG repointed in
--    1451), not this gallery file, so swapping it would be churn with no
--    visible effect.
--
-- Idempotent. Store scope 0. IDs resolved by SKU, never hardcoded.

SET @e = (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C526');

-- ---------------------------------------------------------------- categories
DELETE FROM catalog_category_product
WHERE product_id = @e AND @e IS NOT NULL AND category_id IN (8, 118, 162);

DELETE FROM catalog_category_product_index
WHERE product_id = @e AND @e IS NOT NULL AND category_id IN (8, 118, 162);

-- Add n8n AI Automations (282), positioned at the end of the listing.
-- Guarded on the category existing so a partner instance without it no-ops.
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT 282, @e, COALESCE((SELECT MAX(position) + 1 FROM catalog_category_product cp
                           WHERE cp.category_id = 282), 1)
FROM dual
WHERE @e IS NOT NULL
  AND EXISTS (SELECT 1 FROM catalog_category_entity WHERE entity_id = 282);

-- Mirror into the index the storefront actually reads. store_id/visibility and
-- is_parent are copied from a sibling row in the same category so the new row
-- matches whatever shape this instance uses.
INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT 282, @e,
       COALESCE((SELECT MAX(position) + 1 FROM catalog_category_product cp
                  WHERE cp.category_id = 282), 1),
       i.is_parent, i.store_id, i.visibility
  FROM catalog_category_product_index i
 WHERE i.category_id = 282 AND @e IS NOT NULL
 GROUP BY i.store_id, i.is_parent, i.visibility;

-- ---------------------------------------------------------------- gallery label
UPDATE catalog_product_entity_media_gallery_value v
  JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
   SET v.label = 'No Code and Low Code Agentic AI Applications'
 WHERE g.entity_id = @e AND @e IS NOT NULL;
