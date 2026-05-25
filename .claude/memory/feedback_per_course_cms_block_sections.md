---
name: per-course-cms-block-sections
description: "5 course sections (Learning Outcomes / Brochure / Skills Framework / Certification / WSQ Funding) are stored in per-course cms/block rows keyed `course_<sku>_<section>`. Storefront reads block-first with regex fallback. WSQ fees auto-compute from price — never enter manually."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 7e8e4172-8c26-44bd-9da3-0dfd377aca4e
---

The 5 storefront product-page sections — Learning Outcomes, Brochure, Skills Framework, Certification, WSQ Funding — are stored in per-course Magento `cms/block` rows with identifier convention `course_<sku>_<section>`. The storefront reads from the block first and falls back to short_description regex extraction only if the block is empty. Regex extraction stays in [view.phtml](app/design/frontend/ultimo/default/template/catalog/product/view.phtml) as a permanent belt-and-braces fallback — never delete it.

**Why:** earlier attempts removed the regex fallback after a "cms/block primary" cutover and content vanished from the storefront for any product whose block was empty. The fix architecture has the cms/block as the primary source AND keeps regex as the safety net — so even if a future bootstrap run misses a product, the storefront never silently loses content. Additional context: an unrelated `strip-sg-short-description-sections.php` script (now deleted) once stripped section headings out of `short_description`, removing the very content the regex needed; if a future regression like that recurs, the cms/block content stays intact and renders normally.

**How to apply:**
- Storefront read pattern lives in [view.phtml ~85-265](app/design/frontend/ultimo/default/template/catalog/product/view.phtml#L85): `$_courseSectionHtml('xxx')` for each of the 5 sections; if empty, regex extract from `$shortDescription`. WSQ post-processor (drop legacy fee table, wrap sub-schemes in `.wsq-sub` divs) runs regardless of source — feed it the RAW inner HTML.
- SG Certification (`store_id == 1`) intentionally renders a hardcoded SKU-based template (TGS-* → Cert + OpenCert; others → Cert only) and IGNORES the per-course cms/block. The block is editable in admin but only takes effect on MY/GH/NG/BT/IN stores. Documented in the panel hint.
- WSQ Funding cms/block content is the SFC/UTAP/PSEA narrative ONLY. Course fee, GST, and funding amounts are auto-calculated downstream from `$_product->getFinalPrice()` in the WSQ card — never enter fee tables or amounts in the block. The post-processor strips any embedded `<table>` defensively, but ops should not paste those in.
- Bootstrap: [scripts/local-dev/cms-block-phase01.php](scripts/local-dev/cms-block-phase01.php). `--dry-run` (default) writes a JSON report to media/migrations-reports/. `--apply` upserts cms/block rows. `--overwrite` clobbers existing non-empty blocks. Verifies content_md5 matches baseline after run (proves no drift between regex and cms/block content).
- Admin edit UI is in the **Course Details** tab on the Course Edit dashboard ([dashboard/index.phtml ~2738](app/design/adminhtml/default/default/template/dashboard/index.phtml#L2738) — search `cms_block_learning_outcomes`). 5 textarea panels right after Course Description. Save flow in [CoursesaveController.php ~123](app/code/local/MMD/RoleManager/controllers/Adminhtml/CoursesaveController.php#L123) — empty submission DELETEs the cms/block row, non-empty UPSERTs.
- Adding a new section in the future: append to `$_cmsPanels` (dashboard/index.phtml), `$_cmsSections` (CoursesaveController), and add a `$_courseSectionHtml('newcode')` call site in view.phtml. Naming `course_<sku>_<newcode>`. No schema migration needed — `cms_block` is a generic table.
- DO NOT seed templated content (e.g. "standard WSQ narrative") into blocks. The bootstrap only copies what regex extracts from `short_description`. Empty extractions create no block. Template-seeding caused parity drift in past attempts.
- DO NOT modify `short_description` content. The strip script is gone; if anyone re-adds one, refuse it — the regex fallback depends on those headings staying in `short_description`.

Related: [[varien-massaction-needs-click]] (different topic).
