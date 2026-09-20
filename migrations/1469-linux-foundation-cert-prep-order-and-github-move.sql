-- 1469: Linux Foundation Certification Exam Prep (url_key
-- 'linux-foundation-certification-exam-prep', SG cat 331) --
--   A) curated listing order for its 6 Kubernetes courses, and
--   B) move the two Github Foundations courses off that page onto the
--      Microsoft Certification Exam Prep page.
--
-- Requested order (WSQ block first, then the non-WSQ block -- both in
-- learning-path order KCNA -> CKAD -> CKA, NOT alphabetical):
--   1. TGS-2023039343  WSQ - Kubernetes and Cloud Native Associate (KCNA)
--   2. TGS-2025053212  WSQ - Certified Kubernetes Application Developer (CKAD)
--   3. TGS-2025054612  WSQ - Certified Kubernetes Administrator (CKA)
--   4. C426            Kubernetes and Cloud Native Associate (KCNA)
--   5. C810            Certified Kubernetes Application Developer (CKAD)
--   6. C1394           Certified Kubernetes Administrator (CKA)
--
-- WHY THE GITHUB MOVE IS A CATEGORY-TREE CHANGE, NOT A ROW DELETE.
-- Cat 331 is an ANCHOR with two children: 409 'Linux Foundation Cert Prep'
-- (the 6 Kubernetes courses) and 396 'Github Certification Prep' (the Github
-- courses). C385 has NO base catalog_category_product row in 331 at all -- it
-- surfaces there purely by anchor inheritance from 396. Deleting index rows
-- would therefore be undone by the next full reindex, which re-derives
-- anchor-inherited rows from the child categories. The durable fix is to
-- REPARENT 396 from 331 to 135 (Microsoft Certification Exam Prep): Github is
-- a Microsoft product, 396 is include_in_menu=0 (a grouping bucket, not a
-- visible menu entry), so the move is invisible in the nav and permanent
-- across reindexes.
--
-- Both Github courses are ALREADY direct members of cat 135, so nothing needs
-- adding there; TGS-2025053207 is additionally added to 135's child 358
-- ('instructor-led-microsoft-exam-prep'), which already carries C385, so the
-- two Microsoft pages agree.
--
-- The non-WSQ order above is NOT alphabetical (alphabetical would give
-- CKA, CKAD, KCNA), so 'linux-foundation-certification-exam-prep' is added to
-- mmd/category_ordering/curated_url_keys -- otherwise the nightly
-- MMD_RoleManager_Model_Cron_CategoryOrdering sweep re-alphabetises it within
-- a day. The sweep still enforces WSQ-first, which this order satisfies.
--
-- Positive positions only (negative pins die on reindex -- see 1195). Writes
-- BOTH catalog_category_product and catalog_category_product_index. Business-key
-- lookups throughout -- clean no-op on partner sites (MY/GH carry no TGS- SKUs
-- and may not carry these categories). Idempotent.

SET @linux  := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'linux-foundation-certification-exam-prep' LIMIT 1
);
SET @linuxchild := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'linux-foundation-certification-exam-prep-courses' LIMIT 1
);
SET @github := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'github-certification-prep-courses' LIMIT 1
);
SET @ms := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'microsoft-certifications-exams' LIMIT 1
);
SET @ms358 := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'instructor-led-microsoft-exam-prep' LIMIT 1
);
SET @p_wsqgh := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025053207');
SET @p_c385  := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C385');

-- ===== A: reparent 'Github Certification Prep' 331 -> 135 =====
-- Re-parenting is what actually removes the Github courses from the Linux
-- listing, because they reach it by anchor inheritance from this child.
-- Guarded on @github's CURRENT parent being @linux so a re-run (or a partner
-- DB where the tree differs) is a clean no-op.

UPDATE catalog_category_entity
SET parent_id = @ms,
    path      = CONCAT('1/2/182/', @ms, '/', @github),
    level     = 4,
    position  = 4
WHERE entity_id   = @github
  AND parent_id   = @linux
  AND @github IS NOT NULL AND @linux IS NOT NULL AND @ms IS NOT NULL;

-- Keep children_count consistent with the move. Magento's children_count is
-- the count of ALL DESCENDANTS (cat 182 carries 49 for 13 direct children), and
-- it is maintained only on the admin save path -- a raw parent_id UPDATE leaves
-- it stale. Recompute it from the tree for the two affected nodes rather than
-- applying a +1/-1 delta: a recompute is self-correcting and idempotent, so a
-- re-run (or an instance whose counter was already stale) converges instead of
-- drifting further. Derived via a subquery over path, which is the same
-- definition Magento's own resource model uses.

UPDATE catalog_category_entity c
SET c.children_count = (
  SELECT COUNT(*) FROM (SELECT entity_id, path FROM catalog_category_entity) d
  WHERE d.path LIKE CONCAT(c.path, '/%')
)
WHERE c.entity_id IN (@linux, @ms)
  AND @linux IS NOT NULL AND @ms IS NOT NULL;

-- The Linux page's remaining child (409) keeps position 1; nothing else moves.

-- Drop the anchor-inherited index rows for the two Github courses under the
-- Linux category. With 396 reparented these are no longer re-derivable, so the
-- delete is durable rather than a temporary patch.
DELETE i FROM catalog_category_product_index i
WHERE i.category_id = @linux
  AND i.product_id IN (@p_wsqgh, @p_c385)
  AND @linux IS NOT NULL;

-- TGS-2025053207 additionally had a DIRECT base row in 331 (C385 never did).
DELETE FROM catalog_category_product
WHERE category_id = @linux
  AND product_id IN (@p_wsqgh, @p_c385)
  AND @linux IS NOT NULL;

-- Category-scoped system rewrites would otherwise keep serving the courses
-- under the Linux category path.
DELETE FROM core_url_rewrite
WHERE category_id = @linux
  AND product_id IN (@p_wsqgh, @p_c385)
  AND @linux IS NOT NULL;

-- ===== B: mirror the WSQ Github course into Microsoft child 358 =====
-- 358 already carries C385 but not the WSQ one; add it so both Microsoft
-- surfaces list the same pair. Position 16 = directly after 358's existing
-- TGS- block (15 rows), keeping WSQ-first intact.

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @ms358, @p_wsqgh, 16 FROM dual
WHERE @ms358 IS NOT NULL AND @p_wsqgh IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @ms358, @p_wsqgh, 16, 1, i.store_id, i.visibility
FROM catalog_category_product_index i
WHERE i.category_id = @ms AND i.product_id = @p_wsqgh
  AND @ms358 IS NOT NULL AND @p_wsqgh IS NOT NULL;

-- ===== C: curated-order exemption for the Linux category =====

UPDATE core_config_data
SET value = CONCAT(value, ',linux-foundation-certification-exam-prep')
WHERE path = 'mmd/category_ordering/curated_url_keys'
  AND scope = 'default' AND scope_id = 0
  AND value NOT LIKE '%linux-foundation-certification-exam-prep%';

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'default', 0, 'mmd/category_ordering/curated_url_keys',
       'linux-foundation-certification-exam-prep'
FROM dual
WHERE NOT EXISTS (
  SELECT 1 FROM (SELECT * FROM core_config_data) c
  WHERE c.path = 'mmd/category_ordering/curated_url_keys'
    AND c.scope = 'default' AND c.scope_id = 0
);

-- ===== D: pin the requested order on the Linux page (331) =====
-- WSQ 1..3, non-WSQ 101..103 (the 100-gap keeps the two blocks separated so a
-- later WSQ addition cannot collide with a non-WSQ pin).

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2023039343' THEN 1     -- WSQ KCNA
  WHEN 'TGS-2025053212' THEN 2     -- WSQ CKAD
  WHEN 'TGS-2025054612' THEN 3     -- WSQ CKA
  WHEN 'C426'           THEN 101   -- KCNA
  WHEN 'C810'           THEN 102   -- CKAD
  WHEN 'C1394'          THEN 103   -- CKA
END
WHERE cp.category_id = @linux AND @linux IS NOT NULL
  AND p.sku IN ('TGS-2023039343','TGS-2025053212','TGS-2025054612','C426','C810','C1394');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2023039343' THEN 1
  WHEN 'TGS-2025053212' THEN 2
  WHEN 'TGS-2025054612' THEN 3
  WHEN 'C426'           THEN 101
  WHEN 'C810'           THEN 102
  WHEN 'C1394'          THEN 103
END
WHERE i.category_id = @linux AND @linux IS NOT NULL
  AND p.sku IN ('TGS-2023039343','TGS-2025053212','TGS-2025054612','C426','C810','C1394');

-- Mirror the same order into child 409, whose own listing shows the same six
-- courses, so the two pages do not disagree.

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2023039343' THEN 1
  WHEN 'TGS-2025053212' THEN 2
  WHEN 'TGS-2025054612' THEN 3
  WHEN 'C426'           THEN 101
  WHEN 'C810'           THEN 102
  WHEN 'C1394'          THEN 103
END
WHERE cp.category_id = @linuxchild AND @linuxchild IS NOT NULL
  AND p.sku IN ('TGS-2023039343','TGS-2025053212','TGS-2025054612','C426','C810','C1394');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2023039343' THEN 1
  WHEN 'TGS-2025053212' THEN 2
  WHEN 'TGS-2025054612' THEN 3
  WHEN 'C426'           THEN 101
  WHEN 'C810'           THEN 102
  WHEN 'C1394'          THEN 103
END
WHERE i.category_id = @linuxchild AND @linuxchild IS NOT NULL
  AND p.sku IN ('TGS-2023039343','TGS-2025053212','TGS-2025054612','C426','C810','C1394');

-- ===== E: drop 'GitHub' from the Linux page meta description =====
-- The page no longer lists any Github course, so the served meta description
-- ("...training in Linux, GitHub, Red Hat, and VMware...") now advertises
-- courses that are not on it. meta_description's backend table for
-- entity_type_id=3 is catalog_category_entity_TEXT -- the stale
-- catalog_category_entity_varchar row for the same attribute is orphaned
-- legacy data and is NOT what renders, so only the text row is rewritten.
-- Guarded on the current value so a re-run, or an instance whose copy was
-- already updated by hand, is a clean no-op.

UPDATE catalog_category_entity_text t
JOIN eav_attribute a ON a.attribute_id = t.attribute_id
 AND a.entity_type_id = 3 AND a.attribute_code = 'meta_description'
SET t.value = 'Prepare for Linux Foundation and CNCF certifications including Certified Kubernetes Administrator (CKA), CKAD and Kubernetes and Cloud Native Associate (KCNA) with hands-on exam prep courses in Singapore.'
WHERE t.entity_id = @linux
  AND @linux IS NOT NULL
  AND t.value LIKE '%GitHub%';

-- ===== F: guarded flat-table mirror =====
-- The storefront category page reads catalog_category_flat_store_N, not EAV, so
-- without this mirror the reparent (E's meta_description, and 396's parent_id /
-- path) stays invisible until someone runs the Category Flat Data indexer --
-- and no PHP reindex runs at deploy on this stack.
--
-- HARD RULE (see the category-ordering skill): there is NO bare
-- catalog_category_flat table, and WHICH per-store tables exist differs per
-- instance (SG carries _store_1..7; partners have their own set). Naming a
-- missing table would abort apply.php and 502 the WHOLE site, so every
-- statement is wrapped in an information_schema existence guard that degrades
-- to a clean DO 0 no-op. Store 1 is the only live store on SG; the legacy
-- _store_2..7 tables are leftovers from the retired multi-store install and are
-- deliberately not touched.

SET @md := 'Prepare for Linux Foundation and CNCF certifications including Certified Kubernetes Administrator (CKA), CKAD and Kubernetes and Cloud Native Associate (KCNA) with hands-on exam prep courses in Singapore.';

SET @sql = IF(
  (SELECT COUNT(*) FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'catalog_category_flat_store_1') > 0
  AND @linux IS NOT NULL,
  CONCAT("UPDATE catalog_category_flat_store_1 SET meta_description = ",
         QUOTE(@md), " WHERE entity_id = ", @linux, " AND meta_description LIKE '%GitHub%'"),
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(
  (SELECT COUNT(*) FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'catalog_category_flat_store_1') > 0
  AND @github IS NOT NULL AND @ms IS NOT NULL AND @linux IS NOT NULL,
  CONCAT("UPDATE catalog_category_flat_store_1 SET parent_id = ", @ms,
         ", path = '1/2/182/", @ms, "/", @github, "', level = 4, position = 4",
         " WHERE entity_id = ", @github, " AND parent_id = ", @linux),
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
