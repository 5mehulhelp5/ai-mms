---
name: feedback-auto-reply-store-brand-var
description: "Lead auto-reply templates use {{var store_brand}} (PHP-computed from store code), not {{var store.frontend_name}} (config-dependent). And editing the .html template is NOT enough — the prod render path is core_email_template DB rows, so a migration must rewrite template_text too."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 0009e9f6-a717-4374-9b96-e9284085b609
---

The lead auto-reply branding bug ("TERTIARY INFOTECH ACADEMY" rendered for a Ghana lead — see [[feedback-auto-reply-per-store]]) was permanently fixed by switching the templates away from `{{var store.frontend_name}}` to a new `{{var store_brand}}` variable injected by `MMD_Leads_Helper_Data::getStoreBrandName($storeId)`. That helper hardcodes the per-store-code → brand map in PHP, so it cannot silently fall back when `core_config_data` is missing the per-store override.

**Why:** `{{var store.frontend_name}}` reads `general/store_information/name` and falls back to the default scope if no store-scope override exists. Migration 165 seeded the override on prod and locally, but that store of truth can still be wiped, never-applied on a new env, or overwritten by an admin save. A PHP-side map is immune to all three.

**How to apply:**
- When a transactional email needs per-store branding, prefer injecting a pre-computed brand string from PHP over `{{var store.frontend_name}}` / `{{config path="general/store_information/name"}}`. The injection point is the `$vars` array passed to `sendTransactional()` / `getProcessedTemplate()`.
- **Editing the .html file alone does NOT change prod for transactional emails that have a `core_email_template` row.** `Mage::getStoreConfig('mmd_leads/auto_reply/email_template')` returns a numeric ID → `sendTransactional($id, ...)` loads the row from `core_email_template`, not from the file. The file is only used on the Gmail OAuth path (via `loadDefault('code')`) or when no DB row exists. Any change to the on-disk template must be paired with a `REPLACE(template_text, ...)` migration on the DB row, otherwise SG (Gmail path) updates while MY/GH/NG/BT/IN (sendTransactional path) keep rendering the stale DB content.
- Pattern reference: [migrations/169-auto-reply-store-brand-var.sql](migrations/169-auto-reply-store-brand-var.sql) uses idempotent `REPLACE(template_text, 'old', 'new')` so re-runs are safe.
