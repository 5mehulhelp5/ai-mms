---
name: feedback-auto-reply-per-store
description: "Lead auto-reply must brand and recommend per store — frontend_name needs a per-store core_config_data override, and the catalog/product collection must use addStoreFilter() or it pulls SG-only products into MY/NG/GH/BT/IN recommendations"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f570d33f-cdc6-48ac-b286-0ee06f5eae81
---

The contact-form auto-reply (`MMD_Leads_Helper_Data::sendAutoReply`) is a single template (`mmd_leads/auto_reply.html`) that renders `{{var store.frontend_name}}` in the header + signature. Two non-obvious pitfalls when a non-SG visitor receives a wrong-looking email:

1. **`store.frontend_name` falls back to default scope when the per-store override is missing.** `Mage_Core_Model_Store::getFrontendName()` reads `general/store_information/name` at the store's own scope, then falls back to the website / default scope. If only the default value is seeded ("Tertiary Infotech Academy"), every store renders that — even though the storefront looks right. Fix: seed `general/store_information/name` at `scope='stores'` for every country store (migration 165-per-store-frontend-name.sql).

2. **`setStoreId($storeId)` alone does NOT scope a product collection to that store's website.** It only sets the attribute scope. The catalog is shared across all websites, so a SG-only product can still be returned to an MY lead unless you also call `->addStoreFilter($storeId)` (joins on `catalog_product_website`). Without it, recommendations leak across countries even with `sku_prefix` / `exclude_sku_prefix` filters.

**Why:** A real lead reported the auto-reply rendering "TERTIARY INFOTECH ACADEMY" in the header even though the storefront link in the same email was tertiarycourses.com.my. Inspection showed (a) `frontend_name` had no MY-scope override in prod, and (b) `_scoreCourses` / `_findCourseByCode` didn't add `addStoreFilter`, so SG-only catalog entries could win the score.

**How to apply:**
- Any new transactional email that uses `{{var store.frontend_name}}` for branding — verify `general/store_information/name` is seeded at each store's scope, not just default.
- Any product collection that drives per-country logic (recommendations, badges, cross-sells, sitemap) — always pair `setStoreId($storeId)` with `addStoreFilter($storeId)`. See [[feedback_eav_save_attribute_scope]] for the EAV-write equivalent.
- The Singapore-only WSQ rule is enforced by `_getRecommenderSpec('singapore')` returning `sku_prefix => 'TGS-'`; non-SG stores set `exclude_sku_prefix => 'TGS-'` so the shared catalog doesn't leak SG WSQ courses into their auto-reply.
