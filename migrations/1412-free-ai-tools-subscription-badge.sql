-- 1412: "Free AI Tools Subscription" funding/perk badge for the nine AI
-- courses eligible for the 6-month free AI tools subscription.
--
-- The badge tag drives BOTH the storefront pill under the course title
-- (rendered as the short label "Free AI Tools") and the new promotional
-- card that sits directly above the WSQ Funding card on the product page
-- — one source of truth, so the two can never drift apart.
--
-- Partner-safe: every SKU here is TGS- (SG-only). On MY/GH the SELECT
-- returns no rows => guarded no-op. Idempotent: the tag is seeded only if
-- absent and each relation is inserted only if not already present.

INSERT INTO tag (name, status, first_store_id)
  SELECT 'Free AI Tools Subscription', 1, 1 FROM dual
  WHERE NOT EXISTS (SELECT 1 FROM tag WHERE name = 'Free AI Tools Subscription');

SET @aitools := (SELECT tag_id FROM tag WHERE name = 'Free AI Tools Subscription' LIMIT 1);

-- One row per (tag, product, store). tag_relation is store-scoped and the
-- storefront chip renderer filters by store_id, so write for store 1 (SG)
-- which is the only store these TGS- courses are visible in.
INSERT INTO tag_relation (tag_id, customer_id, product_id, store_id, active, created_at)
  SELECT @aitools, NULL, e.entity_id, 1, 1, NOW()
  FROM catalog_product_entity e
  WHERE e.sku IN (
      'TGS-2025056983', -- Storytelling and Storyboarding with Generative AI
      'TGS-2023035977', -- Agentic AI Automation with n8n
      'TGS-2023037589', -- Generative AI for Content Creation
      'TGS-2024043855', -- Creating Engaging Videos with Generative AI (GenAI)
      'TGS-2023037472', -- Digital Transformation and Business Innovation with GenAI
      'TGS-2024043854', -- Build a Human-AI Workforce with Autonomous AI Agents
      'TGS-2023036153', -- Mastering Prompt Engineering for GenAI Content Creation
      'TGS-2019503161', -- Python Fundamental Course for Beginners
      'TGS-2019504591'  -- AI Vibe Coding with Python
    )
    AND @aitools IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM tag_relation r
      WHERE r.tag_id = @aitools AND r.product_id = e.entity_id AND r.store_id = 1
    );

-- Keep the admin Tags grid's product counts accurate (syncProductTags does
-- the same recompute when badges are edited from Edit Course).
DELETE FROM tag_summary WHERE tag_id = @aitools AND @aitools IS NOT NULL;

INSERT INTO tag_summary (tag_id, store_id, customers, products, uses, historical_uses, popularity)
  SELECT r.tag_id, r.store_id, COUNT(DISTINCT r.customer_id), COUNT(DISTINCT r.product_id),
         COUNT(r.tag_relation_id), COUNT(r.tag_relation_id), COUNT(DISTINCT r.product_id)
  FROM tag_relation r
  WHERE r.tag_id = @aitools AND @aitools IS NOT NULL AND r.active = 1
  GROUP BY r.tag_id, r.store_id;
