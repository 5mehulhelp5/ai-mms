-- 1467: Add C695 "Agentic AI Applications with Codex" to the Codex AI Series
--       category (id 283, url_key 'codex-ai-series', child of 252 AI Courses).
--
-- C695 was repurposed to a Codex course by 1466 but was never added to the
-- Codex AI Series listing, so the series page showed only its WSQ parent and
-- the three other Codex courses.
--
-- Ordering follows the house rule (category-ordering skill): funded TGS- SKUs
-- FIRST, then non-WSQ C- SKUs ALPHABETICAL by course name. Resulting order:
--   1  TGS-2023041081  WSQ - Agentic AI Applications with Codex   (funded)
--   2  C695            Agentic AI Applications with Codex         (A...)
--   3  C818            Codex for Digital Marketing                (Codex for D...)
--   4  C427            Codex for Work Automation                  (Codex for W...)
--   5  C989            Codex Masterclass                          (Codex M...)
--
-- Category 283 is an ANCHOR category (is_anchor = 1), so membership in the
-- parent alone does NOT put the course in this listing -- an explicit
-- catalog_category_product row is required
-- (feedback_anchor_inheritance_masks_missing_category_membership).
--
-- Both tables are written: catalog_category_product (the source of truth) AND
-- catalog_category_product_index (what the storefront listing actually reads).
-- Writing only the first leaves the course invisible until a full reindex
-- (feedback_category_swap_needs_index_mirror).
--
-- Resolve the category BY url_key, and the products BY SKU, so the migration is
-- id-drift-proof across instances. Partner-safe: neither C695 nor category 283
-- exists on MY/GH => @c / @e resolve NULL => every statement no-ops.
-- Idempotent: INSERT ... ON DUPLICATE KEY UPDATE, safe to re-run.

SET @c := (SELECT e.entity_id
             FROM catalog_category_entity e
             JOIN catalog_category_entity_varchar uk
               ON uk.entity_id = e.entity_id AND uk.store_id = 0
              AND uk.attribute_id = (SELECT attribute_id FROM eav_attribute
                                      WHERE entity_type_id = 3 AND attribute_code = 'url_key')
            WHERE uk.value = 'codex-ai-series'
            LIMIT 1);

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C695' LIMIT 1);

-- ------------------------------------------------------------ membership
INSERT INTO catalog_category_product (category_id, product_id, position)
SELECT @c, @e, 2
 WHERE @c IS NOT NULL AND @e IS NOT NULL
ON DUPLICATE KEY UPDATE position = VALUES(position);

-- ------------------------------------------------------- renumber the rest
-- Shift the three existing C- courses down one slot so the alphabetical run
-- stays contiguous. Addressed BY SKU, not by position, so a re-run cannot
-- cascade-shift them a second time.
UPDATE catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
   SET cp.position = CASE p.sku
                       WHEN 'TGS-2023041081' THEN 1
                       WHEN 'C695'           THEN 2
                       WHEN 'C818'           THEN 3
                       WHEN 'C427'           THEN 4
                       WHEN 'C989'           THEN 5
                       ELSE cp.position
                     END
 WHERE cp.category_id = @c
   AND p.sku IN ('TGS-2023041081', 'C695', 'C818', 'C427', 'C989')
   AND @c IS NOT NULL;

-- --------------------------------------------------------- index mirror
-- The storefront listing reads catalog_category_product_index. Mirror the row
-- for every store that already indexes this category, copying that store's own
-- visibility/status values from a sibling row so the new row is consistent.
INSERT INTO catalog_category_product_index
       (category_id, product_id, position, is_parent, store_id, visibility)
SELECT DISTINCT i.category_id, @e, 2, i.is_parent, i.store_id, i.visibility
  FROM catalog_category_product_index i
 WHERE i.category_id = @c
   AND @c IS NOT NULL AND @e IS NOT NULL
   AND i.product_id = (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023041081' LIMIT 1)
ON DUPLICATE KEY UPDATE position = VALUES(position);

-- Keep the index positions in step with the source table.
UPDATE catalog_category_product_index i
  JOIN catalog_product_entity p ON p.entity_id = i.product_id
   SET i.position = CASE p.sku
                      WHEN 'TGS-2023041081' THEN 1
                      WHEN 'C695'           THEN 2
                      WHEN 'C818'           THEN 3
                      WHEN 'C427'           THEN 4
                      WHEN 'C989'           THEN 5
                      ELSE i.position
                    END
 WHERE i.category_id = @c
   AND p.sku IN ('TGS-2023041081', 'C695', 'C818', 'C427', 'C989')
   AND @c IS NOT NULL;
