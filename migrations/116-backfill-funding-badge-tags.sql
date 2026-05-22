-- One-time backfill: assign canonical funding-badge tags to existing
-- courses so the storefront chips appear on day one, without anyone
-- re-running the cover dialog on every product.
--
-- Rules:
--   - SG (website_id=1, store_id=1) products with SKU LIKE 'TGS-%' get the
--     full WSQ-funded set: WSQ, SkillsFuture Credit, UTAP, Absentee Payroll, MCES.
--   - MY (website_id=2, store_id=2) products get HRDF.
--   - Non-TGS SG, NG, GH, BT, IN courses get no tags by default. Admins add
--     them case-by-case via the cover dialog (Phase 3 wiring persists those).
--
-- Tag IDs are resolved at run-time via name so the migration is portable
-- across DBs where the seed IDs (Phase 1, migration 115) may differ.
--
-- INSERT IGNORE is harmless here — the (tag_id, product_id, store_id)
-- combination has no unique constraint, so the de-dup is done in the
-- SELECT via LEFT JOIN ... IS NULL.

-- ── SG: TGS-* courses → WSQ funding set ────────────────────────────────
INSERT INTO tag_relation (tag_id, product_id, store_id, active, created_at)
SELECT t.tag_id, cpe.entity_id, 1, 1, NOW()
FROM tag t
JOIN catalog_product_entity cpe
JOIN catalog_product_website cpw ON cpw.product_id = cpe.entity_id AND cpw.website_id = 1
LEFT JOIN tag_relation tr
       ON tr.tag_id = t.tag_id AND tr.product_id = cpe.entity_id AND tr.store_id = 1
WHERE t.name IN ('WSQ', 'SkillsFuture Credit', 'UTAP', 'Absentee Payroll', 'MCES')
  AND t.status = 1
  AND cpe.sku LIKE 'TGS-%'
  AND tr.tag_relation_id IS NULL;

-- ── MY: every product → HRDF ────────────────────────────────────────────
INSERT INTO tag_relation (tag_id, product_id, store_id, active, created_at)
SELECT t.tag_id, cpe.entity_id, 2, 1, NOW()
FROM tag t
JOIN catalog_product_entity cpe
JOIN catalog_product_website cpw ON cpw.product_id = cpe.entity_id AND cpw.website_id = 2
LEFT JOIN tag_relation tr
       ON tr.tag_id = t.tag_id AND tr.product_id = cpe.entity_id AND tr.store_id = 2
WHERE t.name = 'HRDF'
  AND t.status = 1
  AND tr.tag_relation_id IS NULL;

-- ── Recompute tag_summary for the touched (tag, store) pairs ────────────
-- One row per (tag_id, store_id). Uses INSERT...ON DUPLICATE KEY UPDATE
-- since tag_summary has a composite PK on (tag_id, store_id).
INSERT INTO tag_summary (tag_id, store_id, products, uses, customers, popularity, historical_uses, base_popularity)
SELECT tr.tag_id, tr.store_id,
       COUNT(DISTINCT tr.product_id),
       COUNT(*),
       COUNT(DISTINCT tr.customer_id),
       COUNT(DISTINCT tr.product_id),
       0, 0
FROM tag_relation tr
JOIN tag t ON t.tag_id = tr.tag_id
WHERE t.name IN ('WSQ', 'SkillsFuture Credit', 'UTAP', 'Absentee Payroll', 'MCES', 'HRDF')
GROUP BY tr.tag_id, tr.store_id
ON DUPLICATE KEY UPDATE
    products  = VALUES(products),
    uses      = VALUES(uses),
    customers = VALUES(customers),
    popularity = VALUES(popularity);
