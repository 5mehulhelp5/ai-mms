---
name: Flat catalog must be reindexed after attribute writes
description: This install runs flat_catalog_product=1 — saveAttribute() alone leaves the storefront stale
type: feedback
originSessionId: 9e4e7fca-2797-44ac-9734-21a6583d1d94
---
When writing product attribute values via `$product->getResource()->saveAttribute($product, 'attr_code')` in this codebase, the storefront keeps serving the old value until the `catalog_product_flat` index is rebuilt for the affected product(s) and the `block_html` + `full_page` + `collections` caches are flushed.

**Why:** The install has `catalog/frontend/flat_catalog_product = 1`. The frontend reads from `catalog_product_flat_<store_id>` (a denormalized snapshot), not from EAV. `saveAttribute` updates EAV only. Listing slider HTML is additionally held in `block_html` cache. Discovered during MMD_CourseImage bulk run (2026-05-22) — 299 TGS courses had `course_image_url` saved but storefront kept the old images until flat reindex.

**How to apply:**
- For per-product saves in a controller, call `Mage::getResourceSingleton('catalog/product_flat_indexer')->updateProduct($id, $storeId)` per store, then `Mage::app()->cleanCache(['catalog_product_' . $id])`.
- For batch operations, prefer one whole-index reindex via `Mage::getModel('index/process')->load('catalog_product_flat', 'indexer_code')->reindexEverything()` at the end, plus `cleanType('block_html')`, `cleanType('full_page')`, `cleanType('collections')`.
- The simpler `$product->save()` triggers both via observers but is heavyweight (full product save + all indexers).
- **For SQL migrations under `migrations/*.sql`:** there is no PHP shell hook during deploy, so reindex via direct UPDATEs from `catalog_product_entity_<type>` into each `catalog_product_flat_<store_id>` (stores 1..7 in this install), and `TRUNCATE TABLE core_cache_tag` at the end to force block_html/FPC regen. Seen in [migrations/125-flat-sync-course-image-url.sql](migrations/125-flat-sync-course-image-url.sql) — the prior migration 124 wrote the R2 URLs into EAV only and the storefront kept serving the placeholder until 125 mirrored the column into the flat tables.
