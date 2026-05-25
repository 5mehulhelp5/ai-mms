---
name: Funding badges live in Magento tag system, not an EAV attribute
description: Storefront funding-badge chips (WSQ, SFC, etc.) read from tag_relation, written by cover dialog
type: feedback
originSessionId: 178e0ee5-743e-437d-b83d-177b1fc148bc
---
The 9 canonical funding badges (`WSQ`, `SkillsFuture Credit`, `PSEA`, `UTAP`, `IBF`, `HRDF`, `SFEC`, `Absentee Payroll`, `MCES`) are stored as **Magento tags** on each product, not as a custom EAV multiselect attribute. The cover-image dialog's badge checkboxes are the canonical admin UI — ticking them runs `MMD_CourseImage_Helper_Data::syncProductTags()` which diff-syncs `tag_relation` rows. Storefront chips on the catalog list page + product view page read `getProductBadges()` which queries `tag` JOIN `tag_relation`, filtered to the 9 canonical names + `status=APPROVED`.

**Why:** the user explicitly chose the tag approach over a new EAV attribute on the basis of "less risk" — no schema migration on the product_entity tables, no flat-catalog column addition, and Magento's tag CRUD already exists in admin. The decision came after we considered (a) a multiselect EAV attribute and (b) reusing the cover-dialog checkbox state directly; tags won because they're already persistent and admin-editable. The legacy `1`-`5` rating-style tags that already exist in `tag` (5 rows, ~700 relations) are ignored because the renderer whitelists by name.

**How to apply:** if asked to add another funding badge — append the name to `Helper/Data.php::getAllBadges()`, add a `course-badge--<key>` CSS class to [skin/frontend/ultimo/default/css/custom.css](skin/frontend/ultimo/default/css/custom.css), add a row to the `getBadgeCssClass()` map, and seed a `tag` row via a new migration. Do NOT add a column to the EAV. If asked "where do badges come from?" — they come from `tag_relation`, not from a product attribute. After any direct DB tag write, reindex `catalog_product_flat` and flush `block_html`/FPC because the flat-catalog memory still applies even though the tag query bypasses the flat table (the listing block IS cached).
