-- "Free AI Subscription" category — reactivate + repurpose the dead "Adobe XD"
-- category (id 313) and move it under AI Courses (252), after Microsoft Copilot
-- Series.
--
-- WHY REPURPOSE 313: it was deactivated, has no child categories, and carried a
-- single stale product link (C999). Adobe XD is not coming back, so the entity
-- is free. Reusing an entity (rather than creating one) keeps the id stable for
-- the mega-menu and avoids a second orphan later.
--
-- The nine courses are the SWDA "Free AI sub" list, taken from the announcement
-- post's own related_skus (mmd_blog_post, url_key
-- free-ai-subscription-now-live-swda-eligible-courses) so the category and the
-- blog post can never disagree. All nine verified 2026-09-17 as enabled
-- (status 1) and visible (visibility 4) on SG.
--
-- Resolved BY NAME/SKU, never by hardcoded id where a lookup exists, so a
-- partner DB with different ids is a clean no-op rather than a wrong write.
-- SG-only: guarded on store_id 1 / code 'singapore'.
--
-- NOTE ON MEMORY feedback_repurposed_category_keeps_old_content_and_position:
-- a repurposed category silently keeps the PREVIOUS life's description, meta,
-- image and position. Every one of those is overwritten below — not just name
-- and url_key — or the page renders Adobe XD copy under an AI heading.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

SET @cat    := 313;                       -- the entity being repurposed
SET @parent := (SELECT v.entity_id
                  FROM catalog_category_entity_varchar v
                  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3
                 WHERE a.attribute_code = 'name' AND v.store_id = 0 AND v.value = 'AI Courses'
                 LIMIT 1);

-- Only proceed when this really is the dead Adobe XD entity on SG. Re-running
-- after the rename finds name 'Free AI Subscription' and @ok stays 1.
SET @ok := (SELECT CASE WHEN @sg = 1 AND @parent IS NOT NULL
                          AND EXISTS (SELECT 1 FROM catalog_category_entity WHERE entity_id = @cat)
                          AND EXISTS (SELECT 1 FROM catalog_category_entity_varchar v
                                        JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3
                                       WHERE v.entity_id = @cat AND a.attribute_code = 'name' AND v.store_id = 0
                                         AND v.value IN ('Adobe XD', 'Free AI Subscription'))
                        THEN 1 ELSE 0 END);

-- ---------------------------------------------------------------------------
-- 1. Re-parent 313 under AI Courses (252) and slot it after Microsoft Copilot
--    Series. Position 5 = directly after Copilot (4); later siblings shift down.
-- ---------------------------------------------------------------------------
SET @copilot_pos := (SELECT position FROM catalog_category_entity
                      WHERE parent_id = @parent
                        AND entity_id = (SELECT v.entity_id
                                           FROM catalog_category_entity_varchar v
                                           JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3
                                          WHERE a.attribute_code = 'name' AND v.store_id = 0
                                            AND v.value = 'Microsoft Copilot Series' LIMIT 1)
                      LIMIT 1);
SET @newpos := IFNULL(@copilot_pos, 4) + 1;

-- Make room: push existing siblings at/after the target slot down by one.
-- Excludes @cat itself so a re-run cannot shove it down repeatedly.
UPDATE catalog_category_entity
   SET position = position + 1
 WHERE @ok = 1 AND parent_id = @parent AND entity_id <> @cat AND position >= @newpos;

UPDATE catalog_category_entity
   SET parent_id = @parent,
       path      = CONCAT('1/2/', @parent, '/', @cat),
       level     = 3,
       position  = @newpos
 WHERE @ok = 1 AND entity_id = @cat;

-- ---------------------------------------------------------------------------
-- 2. Identity + page copy. Written at store_id 0 (default scope) and any
--    store-scoped override row is removed, so store 1 cannot keep showing the
--    old Adobe XD values.
-- ---------------------------------------------------------------------------
DELETE v FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3
 WHERE @ok = 1 AND v.entity_id = @cat AND v.store_id <> 0
   AND a.attribute_code IN ('name','url_key','meta_title','display_mode','page_layout','image');

DELETE t FROM catalog_category_entity_text t
  JOIN eav_attribute a ON a.attribute_id = t.attribute_id AND a.entity_type_id = 3
 WHERE @ok = 1 AND t.entity_id = @cat AND t.store_id <> 0
   AND a.attribute_code IN ('description','meta_description','meta_keywords');

DELETE i FROM catalog_category_entity_int i
  JOIN eav_attribute a ON a.attribute_id = i.attribute_id AND a.entity_type_id = 3
 WHERE @ok = 1 AND i.entity_id = @cat AND i.store_id <> 0
   AND a.attribute_code IN ('is_active','include_in_menu','is_anchor','custom_use_parent_settings','landing_page');

-- varchar attributes
INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, a.attribute_id, 0, @cat,
       CASE a.attribute_code
         WHEN 'name'         THEN 'Free AI Subscription'
         WHEN 'url_key'      THEN 'free-ai-subscription-courses'
         WHEN 'meta_title'   THEN 'Free AI Subscription Courses in Singapore | 6 Months of ChatGPT Plus, Google AI Pro & More'
         WHEN 'display_mode' THEN 'PRODUCTS'
         WHEN 'page_layout'  THEN ''
         WHEN 'image'        THEN ''
       END
  FROM eav_attribute a
 WHERE a.entity_type_id = 3 AND @ok = 1
   AND a.attribute_code IN ('name','url_key','meta_title','display_mode','page_layout','image')
    ON DUPLICATE KEY UPDATE value = VALUES(value);

-- text attributes (category meta_description is a TEXT column, not varchar)
INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, a.attribute_id, 0, @cat,
       CASE a.attribute_code
         WHEN 'description' THEN
'<p>Attend any of the nine WSQ AI courses below and, if you are a Singapore Citizen aged 18 or above, you can claim <strong>six months of a premium AI tool free</strong> &mdash; ChatGPT Plus, Google AI Pro, Manus AI, Microsoft 365 Personal or Singtel AI Pass. The scheme went live on 16 September 2026 under the Skills and Workforce Development Agency (SWDA), and these courses sit on its curated eligible list.</p>
<p>The subscription is <strong>on top of</strong> the SkillsFuture funding these courses already carry &mdash; you are not trading one for the other. Your class must start on or after 1 September 2026, and each person can redeem one subscription in total, however many eligible courses you complete. After you finish the course you will be emailed a redemption form, which you have 60 days to submit; your choice of tool cannot be changed afterwards.</p>'
         WHEN 'meta_description' THEN
'Take a WSQ AI course and claim 6 months of ChatGPT Plus, Google AI Pro, Manus AI, Microsoft 365 Personal or Singtel AI Pass free. Nine SWDA-eligible courses, on top of SkillsFuture funding. For Singapore Citizens aged 18+, classes starting 1 Sep 2026 onwards.'
         WHEN 'meta_keywords' THEN
'free ai subscription, swda ai courses, chatgpt plus free, google ai pro, wsq ai courses singapore, skillsfuture ai'
       END
  FROM eav_attribute a
 WHERE a.entity_type_id = 3 AND @ok = 1
   AND a.attribute_code IN ('description','meta_description','meta_keywords')
    ON DUPLICATE KEY UPDATE value = VALUES(value);

-- int attributes: activate + show in menu, anchored listing like its siblings
INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, a.attribute_id, 0, @cat,
       CASE a.attribute_code
         WHEN 'is_active'                  THEN 1
         WHEN 'include_in_menu'            THEN 1
         WHEN 'is_anchor'                  THEN 1
         WHEN 'custom_use_parent_settings' THEN 0
         WHEN 'landing_page'               THEN NULL
       END
  FROM eav_attribute a
 WHERE a.entity_type_id = 3 AND @ok = 1
   AND a.attribute_code IN ('is_active','include_in_menu','is_anchor','custom_use_parent_settings','landing_page')
    ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------------------
-- 3. Membership: exactly the nine SWDA-eligible courses.
--    Drop the stale Adobe XD product link first, then add the nine in the
--    order the announcement post lists them.
--    Mirrored into catalog_category_product_index -- memory
--    feedback_category_swap_needs_index_mirror: the storefront reads the index
--    table, so a catalog_category_product-only write renders an empty category.
-- ---------------------------------------------------------------------------
DELETE FROM catalog_category_product      WHERE @ok = 1 AND category_id = @cat;
DELETE FROM catalog_category_product_index WHERE @ok = 1 AND category_id = @cat;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, e.entity_id, t.pos
  FROM (
    SELECT 'TGS-2023035977' AS sku, 1 AS pos
    UNION ALL SELECT 'TGS-2023037472', 2
    UNION ALL SELECT 'TGS-2024043854', 3
    UNION ALL SELECT 'TGS-2023036153', 4
    UNION ALL SELECT 'TGS-2023037589', 5
    UNION ALL SELECT 'TGS-2025056983', 6
    UNION ALL SELECT 'TGS-2024043855', 7
    UNION ALL SELECT 'TGS-2019504591', 8
    UNION ALL SELECT 'TGS-2019503161', 9
  ) t
  JOIN catalog_product_entity e ON e.sku = t.sku
 WHERE @ok = 1;

INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, cp.product_id, cp.position, 1, s.store_id, 4
  FROM catalog_category_product cp
  CROSS JOIN core_store s
 WHERE @ok = 1 AND cp.category_id = @cat AND s.store_id > 0;

-- ---------------------------------------------------------------------------
-- 4. URL rewrites.
--    The old slug must keep resolving: adobe-xd-courses.html has live 301
--    ancestors pointing at it. Repoint the category's own system rewrite to the
--    new flat slug (FlatCategoryUrl keeps every category at /<url_key>.html),
--    and leave a 301 from the old slug so nothing 404s.
--    Rows for the retired store 2 are dropped -- memory
--    feedback_store_delete_orphans_and_infoschema_migration_502.
-- ---------------------------------------------------------------------------
DELETE FROM core_url_rewrite
 WHERE @ok = 1 AND category_id = @cat AND store_id NOT IN (0, 1);

-- Retire the stale product-under-category rewrite (C999 is no longer a member).
DELETE FROM core_url_rewrite
 WHERE @ok = 1 AND category_id = @cat AND product_id IS NOT NULL;

-- Point the category's system rewrite at the new slug.
UPDATE core_url_rewrite
   SET request_path = 'free-ai-subscription-courses.html'
 WHERE @ok = 1 AND category_id = @cat AND product_id IS NULL
   AND is_system = 1 AND store_id = 1
   AND request_path = 'adobe-xd-courses.html';

-- 301 the old bare slug to the new one. Remove any is_system = 0 squatter first
-- (INSERT IGNORE silently no-ops against a stale row) -- memory
-- feedback_rename_301_row_squats_id_path_blocks_system_rewrite.
DELETE FROM core_url_rewrite
 WHERE @ok = 1 AND request_path = 'adobe-xd-courses.html' AND is_system = 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, CONCAT('manual-301-', MD5('adobe-xd-courses.html'), '-1'),
       'adobe-xd-courses.html', 'free-ai-subscription-courses.html', 0, 'RP'
 WHERE @ok = 1;
