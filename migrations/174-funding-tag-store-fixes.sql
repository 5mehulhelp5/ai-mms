-- Funding-tag store-scope cleanup.
--
-- Issues being fixed:
--   1. HRDF is a Malaysian government scheme — should only exist on
--      the Malaysia store view. Currently has relations on Malaysia +
--      Ghana + Nigeria + Bhutan + India.
--   2. Courses with names prefixed "IBF" need the IBF tag in Singapore.
--   3. IBF / PSEA / SFEC are Singapore-only schemes — must not exist
--      on any non-Singapore store.
--   4. Every WSQ course (currently tagged with WSQ in Singapore) must
--      also carry PSEA and SFEC tags in Singapore.
--
-- Tag ids are looked up by name so the migration is portable between
-- dev / staging / prod where ids may differ.

-- ============================================================
-- 1. HRDF — keep Malaysia only, drop every other store
-- ============================================================
DELETE tr FROM tag_relation tr
JOIN tag t ON t.tag_id = tr.tag_id
WHERE t.name = 'HRDF' AND tr.store_id <> 2;

-- ============================================================
-- 2. IBF — add to every product whose name starts with "IBF " or
--    "IBF-" in the admin / Singapore scope. Use a NOT EXISTS guard
--    so re-applies are no-ops (also: MySQL treats NULL <> NULL in
--    unique-key checks, so INSERT IGNORE alone would let duplicates
--    sneak through).
-- ============================================================
INSERT INTO tag_relation (tag_id, customer_id, product_id, store_id, active, created_at)
SELECT (SELECT tag_id FROM tag WHERE name = 'IBF' LIMIT 1),
       NULL, p.entity_id, 1, 1, NOW()
FROM (
    SELECT DISTINCT cpe.entity_id
    FROM catalog_product_entity cpe
    JOIN catalog_product_entity_varchar cpev ON cpev.entity_id = cpe.entity_id
    JOIN eav_attribute ea ON ea.attribute_id = cpev.attribute_id AND ea.attribute_code = 'name'
    WHERE (cpev.value LIKE 'IBF %' OR cpev.value LIKE 'IBF-%')
      AND cpev.store_id IN (0, 1)
) p
WHERE NOT EXISTS (
    SELECT 1 FROM tag_relation tr
    WHERE tr.tag_id = (SELECT tag_id FROM tag WHERE name = 'IBF' LIMIT 1)
      AND tr.product_id = p.entity_id
      AND tr.store_id = 1
      AND tr.customer_id IS NULL
);

-- ============================================================
-- 3. IBF / PSEA / SFEC — Singapore-only, drop any non-Singapore
--    relations that may exist (defensive; current state has none).
-- ============================================================
DELETE tr FROM tag_relation tr
JOIN tag t ON t.tag_id = tr.tag_id
WHERE t.name IN ('IBF','PSEA','SFEC') AND tr.store_id <> 1;

-- ============================================================
-- 4. PSEA — mirror every Singapore WSQ relation
-- ============================================================
INSERT INTO tag_relation (tag_id, customer_id, product_id, store_id, active, created_at)
SELECT (SELECT tag_id FROM tag WHERE name = 'PSEA' LIMIT 1),
       NULL, w.product_id, 1, 1, NOW()
FROM (
    SELECT DISTINCT product_id FROM tag_relation
    WHERE tag_id = (SELECT tag_id FROM tag WHERE name = 'WSQ' LIMIT 1)
      AND store_id = 1 AND active = 1
) w
WHERE NOT EXISTS (
    SELECT 1 FROM tag_relation tr
    WHERE tr.tag_id = (SELECT tag_id FROM tag WHERE name = 'PSEA' LIMIT 1)
      AND tr.product_id = w.product_id
      AND tr.store_id = 1
      AND tr.customer_id IS NULL
);

-- ============================================================
-- 5. SFEC — mirror every Singapore WSQ relation
-- ============================================================
INSERT INTO tag_relation (tag_id, customer_id, product_id, store_id, active, created_at)
SELECT (SELECT tag_id FROM tag WHERE name = 'SFEC' LIMIT 1),
       NULL, w.product_id, 1, 1, NOW()
FROM (
    SELECT DISTINCT product_id FROM tag_relation
    WHERE tag_id = (SELECT tag_id FROM tag WHERE name = 'WSQ' LIMIT 1)
      AND store_id = 1 AND active = 1
) w
WHERE NOT EXISTS (
    SELECT 1 FROM tag_relation tr
    WHERE tr.tag_id = (SELECT tag_id FROM tag WHERE name = 'SFEC' LIMIT 1)
      AND tr.product_id = w.product_id
      AND tr.store_id = 1
      AND tr.customer_id IS NULL
);

-- ============================================================
-- 6. Rebuild tag_summary for the affected tags so the Manage
--    Funding Tags grid shows the right per-store counts. Two passes:
--    per-store rows (store_id > 0) and the admin/all roll-up
--    (store_id = 0). Magento's stock aggregator does the same
--    decomposition; we replicate it here so we don't depend on
--    triggering a separate reindex job.
-- ============================================================
DELETE FROM tag_summary
WHERE tag_id IN (
    SELECT tag_id FROM tag WHERE name IN ('IBF','HRDF','PSEA','SFEC')
);

INSERT INTO tag_summary (tag_id, store_id, customers, products, uses, historical_uses, popularity, base_popularity)
SELECT tr.tag_id, tr.store_id, 0,
       COUNT(DISTINCT tr.product_id), 0, 0, 0, 0
FROM tag_relation tr
JOIN tag t ON t.tag_id = tr.tag_id
WHERE t.name IN ('IBF','HRDF','PSEA','SFEC')
GROUP BY tr.tag_id, tr.store_id;

INSERT INTO tag_summary (tag_id, store_id, customers, products, uses, historical_uses, popularity, base_popularity)
SELECT tr.tag_id, 0, 0,
       COUNT(DISTINCT tr.product_id), 0, 0, 0, 0
FROM tag_relation tr
JOIN tag t ON t.tag_id = tr.tag_id
WHERE t.name IN ('IBF','HRDF','PSEA','SFEC')
GROUP BY tr.tag_id;
