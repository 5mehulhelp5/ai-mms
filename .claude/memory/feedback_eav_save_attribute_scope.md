---
name: eav-save-attribute-scope
description: "saveAttribute() from a CLI script writes at the script's current store scope (store_id=1 by default), creating a per-store override rather than mutating the admin-default value. Bulk catalog migrations must explicitly set admin scope (store_id=0) or every non-SG country store will silently see the old data."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: e3c7de75-31c0-4c39-abe9-e6fc7ef126b1
---

Background bulk-edit scripts that call `$product->saveAttribute()` from CLI write into the store scope that `Mage::app()` picks up — for this repo that defaults to the SG store (`store_id=1`). The write becomes a per-store override row in `catalog_product_entity_*` (text/varchar/etc.) at `store_id=1`, and the admin-default row at `store_id=0` is untouched. As a result MY/NG/GH/BT/IN keep reading the old value via the admin-scope fallback, and any pre-existing admin value at store 0 (e.g. a default note) gets shadowed only on SG.

**Why:** ran a "move Exam Voucher → Additional Note" migration on 21 CompTIA products. The script saved the cleaned `short_description` and new `additional_note` at SG scope, which (a) dropped a pre-existing "Please bring your own laptop..." default note on SG, (b) left MY/NG/GH/BT/IN with the old Exam Voucher section visible. Required a second repair pass to promote the writes to admin scope (`store_id=0`) and `DELETE` the SG-scope overrides so every country store inherits the same merged value. See [scripts/local-dev/comptia-move-exam-voucher.php](scripts/local-dev/comptia-move-exam-voucher.php) (buggy v1) and [scripts/local-dev/comptia-voucher-fix-scope.php](scripts/local-dev/comptia-voucher-fix-scope.php) (repair).

**How to apply:**
- For bulk catalog migrations that should affect every country, do NOT rely on `saveAttribute()` from a CLI default app context. Either:
  - `$product->setStoreId(0)->saveAttribute(...)` — but resource model may still write to current store; safer is the direct SQL path below.
  - Direct table write at `store_id=0`: `INSERT … ON DUPLICATE KEY UPDATE value=…` against `catalog_product_entity_text/varchar/int/decimal/datetime` for the right `attribute_id`, then `DELETE FROM …_entity_text WHERE attribute_id=? AND store_id!=0` to clear any stale per-store overrides you want to invalidate.
- Before running the bulk write, scan for existing per-store overrides on the same attribute and either merge them or document why they're being clobbered.
- Always reindex `catalog_product_flat` (per-store flat tables — `catalog_product_flat_<store_id>` — each must be rebuilt) and flush `block_html` + `full_page` + `collections` after the write. `shell/indexer.php --reindex catalog_product_flat` is the most reliable rebuilder; `Mage::getModel('index/process')->reindexEverything()` sometimes silently no-ops in CLI without surfacing an error.
- When verifying with `curl`, **never use a `Host: tertiarycourses.com.<tld>` header against localhost** — `.htaccess` 301-redirects non-www to the live `https://www.tertiarycourses.com.<tld>` and you end up scoring the verification against PRODUCTION, not your local container. Hit `http://localhost:8080/<url-key>.html` directly; for a specific store view set `MAGE_RUN_CODE` via query string or env, not via Host header.

Related: [[flat-catalog-reindex]] (sibling lesson — same family of "EAV write looks fine but storefront stays stale" bugs).
