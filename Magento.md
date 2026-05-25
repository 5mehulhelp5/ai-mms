# Magento.md — How customization works on this site

A field-notebook for the non-obvious parts of how this OpenMage 1.x install
diverges from stock Magento. Read this before "just adding an EAV attribute"
or "just touching the product edit page" — the obvious path is often the
wrong one here.

Stock-Magento knowledge applies most of the time, but the items below are
where this codebase quietly does its own thing.

---

## 1. There are TWO product-edit pages. Know which one you're on.

### 1a. Stock Magento product-edit  (`catalog_product/edit`)

- URL: `/<frontName>/catalog_product/edit/id/<n>/`
- Rendered by `Mage_Adminhtml_Block_Catalog_Product_Edit_Tabs`
- Each **attribute group** in the product's attribute set becomes its own tab
  (`General`, `Prices`, `Course Details`, `Trainer Details`, `Images`, …)
- Adding a new EAV attribute and attaching it to a group (via migration)
  is enough — Magento renders the field automatically inside that group's
  tab. **This is the path docs/tutorials assume.**

### 1b. Custom "dcf editor" — what users actually use ⚠️

- Lives in [`app/design/adminhtml/default/default/template/dashboard/index.phtml`](app/design/adminhtml/default/default/template/dashboard/index.phtml)
  (a ~13k-line phtml served by the **dashboard controller**, NOT
  `catalog_product/edit`)
- Header reads **"Course Information"**; left sidebar shows: General,
  Course Details, Course Schedule, Lesson Details, Trainer Details,
  Course Images, Categories, Course Review, Marketing, Design, Websites
- Save handler:
  [`app/code/local/MMD/RoleManager/controllers/Adminhtml/CoursesaveController.php`](app/code/local/MMD/RoleManager/controllers/Adminhtml/CoursesaveController.php)
- Sidebar tabs are NOT Magento attribute-group tabs. They're hand-coded
  `<div class="dcf-tab-panel">` sections inside the one big phtml.
- **Each field is hand-rendered.** Adding an EAV attribute does NOT
  auto-surface here — you must:
  1. Add a `<div class="dcf-row">…</div>` block to the relevant tab
     panel in `dashboard/index.phtml`
  2. Add the corresponding `if (($v = $req->getParam(...)) ...)
     $product->setData(...)` line to `CoursesaveController::saveAction`
- JS host: [`skin/adminhtml/default/default/js/product-edit-tools.js`](skin/adminhtml/default/default/js/product-edit-tools.js)
  (look for `dcf-edit-sidebar`, `dcf-section`, `dcf-rail-collapsed`)

### Tell-tale signs you're on the dcf editor (not stock product-edit)

- Body class is `adminhtml-dashboard-index` (not `adminhtml-catalog-product-edit`)
- Page header says "Course Information"
- CSS classes start with `dcf-` (`dcf-tab-panel`, `dcf-row`, `dcf-section-title`, …)
- Field labels are renamed: Course Title (=name), Course Code (=sku),
  Course Fee (=price)

> Worked example — adding `assessment_duration` attribute:
> migration 159 created the EAV, 161 placed it in Course Details group at
> sort 6. That made it appear on the **stock** catalog_product/edit page,
> but NOT on the dcf editor. Real fix:
> [`dashboard/index.phtml:2645-2671`](app/design/adminhtml/default/default/template/dashboard/index.phtml#L2645)
> + [`CoursesaveController.php:122`](app/code/local/MMD/RoleManager/controllers/Adminhtml/CoursesaveController.php#L122).

---

## 2. Attribute renaming via translate.csv

`app/design/adminhtml/default/default/locale/en_US/translate.csv` rewrites
several stock labels at render time. Don't be confused when the UI says
something different from the attribute's `frontend_label`:

| Stock label        | This site shows |
|--------------------|-----------------|
| Products           | Courses         |
| Product Name       | Course Name     |
| Custom Options     | Course Schedule |
| Product Information| Course Information |
| Product Reviews    | Courses Reviews |
| Product            | Course          |

Search before assuming a label is hard-coded.

---

## 3. EAV group structure of the `Courses` attribute set (id=4)

Verified with `Mage::getResourceModel('eav/entity_attribute_group_collection')`:

| Group              | id | sort | Key attributes |
|--------------------|----|------|----------------|
| General            | 7  | 1    | name, sku, tax_class_id, news_from_date, news_to_date, status, url_key, visibility, course_image_url, enable_sg_funding |
| Prices             | 8  | 2    | price, group_price, special_price, special_from_date, special_to_date, cost, tier_price, msrp_* |
| Course Details     | 18 | 3    | short_description, description, **sessions, duration, level, software (=Course Type), assessment_duration, additional_note (=Additional Note), prerequisite (=Course Admin), whoshouldattend (=Job Roles), assessment_methods** |
| Trainer Details    |110 | 4    | trainerprofile |
| Images             | 10 | 5    | image, small_image, thumbnail, media_gallery, gallery |
| Meta Information   | 9  | 6    | meta_title, meta_keyword, meta_description |
| Recurring Profile  | 11 | 7    | is_recurring, recurring_profile |
| Design             | 12 | 8    | custom_design, page_layout, options_container, … |
| Gift Options       | 17 | 9    | gift_message_available |

Note: `Course Details` is where almost every course-specific custom attribute
lives. Use **the "Course Details" group**, not the historical "Course Sections"
group — that one was dropped by migration 150 (see migration 158's header
for the postmortem).

---

## 4. Course-attribute storage quirks

- `sessions` — `backend_type=varchar` (text-typed because admins sometimes
  type "5 half-days"); CAST as UNSIGNED for numeric logic
- `duration` — `backend_type=varchar` (numeric hours, but stored as text)
- `level` — `frontend_input=select`, `source_model=eav/entity_attribute_source_table`
- `software` (= "Course Type") — same shape as level; legacy values
  (WSQ/IBF/CASL/HRDF/SkillsFuture) collapsed into "Funded" by migration 093
- `assessment_methods` — multiselect, `backend_model=eav/entity_attribute_backend_array`
- `assessment_duration` — `frontend_input=select`, option labels:
  `NA, 0.5, 1, 1.5, 2, 2.5, 3` (option_id stored in
  `catalog_product_entity_int`)

---

## 5. SKU prefix = course classification (no separate attribute)

There is **no "is_wsq" attribute**. Course classification is derived
purely from the SKU prefix:

| Prefix       | Meaning                              | Count (snapshot) |
|--------------|--------------------------------------|------------------|
| `TGS-`       | WSQ-accredited (SkillsFuture)        | ~299             |
| `C…`         | Non-WSQ adult / non-funded courses   | many             |
| `M…`         | Non-WSQ "Mastery"                    | many             |
| `VM…`        | Virtual / online                     | some             |
| `K…`         | Kids                                 | some             |

Any "WSQ vs non-WSQ" logic in migrations/observers/templates branches on
`sku LIKE 'TGS-%'`. **Don't add a new attribute when the SKU already says it.**

The TGS- prefix is also the SkillsFuture course-reference number that
powers the lead auto-reply recommender (see [memory: reference_wsq_course_tgs_sku.md](.claude/projects/-Users-alfredang-projects-tertiary-ai-mms/memory/reference_wsq_course_tgs_sku.md)).

---

## 6. Storefront "Course Information" card

Rendered by
[`app/design/frontend/ultimo/default/template/catalog/product/view/rightData.phtml`](app/design/frontend/ultimo/default/template/catalog/product/view/rightData.phtml).
Populates `$_rows[]` from `$_product->get…()` and renders each as an icon
tile. To add a new tile: append to `$_rows` with `label/value/icon` (icon
keys live in `$_icons` in the same file).

The card is paired with three CMS blocks below it:
- `post_course_support`
- `course_cancellation_policy`
- `grant` (residual "Additional Information")

---

## 7. Per-course CMS blocks (NOT EAV)

Most "section" content (Learning Outcomes, Brochure, Skills Framework,
Certification, WSQ Funding, etc.) is **not** stored as product attributes.
It lives as `cms_block` rows keyed `course_<sku>_<section>`. See
[memory: feedback_per_course_cms_block_sections.md](.claude/projects/-Users-alfredang-projects-tertiary-ai-mms/memory/feedback_per_course_cms_block_sections.md).

When migrating an existing inline `<h3>` section out of `description`,
the pattern is:
1. Move the markup into a `cms_block`
2. Strip it from `description` in the same migration (use UNHEX() form
   to avoid MySQL backslash ambiguity — see
   [memory: feedback_migration_generator_skipped_strip.md](.claude/projects/-Users-alfredang-projects-tertiary-ai-mms/memory/feedback_migration_generator_skipped_strip.md))

---

## 8. Frontend funding badges = Magento tag system, not EAV

The colored pills under each course title (WSQ, SkillsFuture Credit, PSEA,
UTAP, IBF, HRDF, SFEC, Absentee Payroll, MCES) are Magento `tag` rows,
not attribute values. See [memory: feedback_funding_badges_via_tags.md](.claude/projects/-Users-alfredang-projects-tertiary-ai-mms/memory/feedback_funding_badges_via_tags.md).

Authoring path: the CourseImage cover dialog's badge checkboxes drive
both the rendered PNG **and** `syncProductTags()` writes. Storefront reads
`getProductBadges()` (filtered to the 9 canonical names).

---

## 9. Indexer & cache rules of thumb

After ANY attribute write outside of an admin form save:

```bash
docker exec ai-mms-web-1 php /var/www/html/shell/indexer.php --reindex catalog_product_flat
docker exec ai-mms-web-1 sh -c "rm -rf /var/www/html/var/cache/* /var/www/html/var/full_page_cache/*"
```

Without the flat reindex the storefront serves stale values silently.
See [memory: feedback_flat_catalog_reindex.md](.claude/projects/-Users-alfredang-projects-tertiary-ai-mms/memory/feedback_flat_catalog_reindex.md).

After ANY change to attribute-set / group / sort_order: **flush
Magento cache** — the attribute-set structure is cached in `config`/`eav`.

Admin mass-action checkboxes are hidden on Index Management + Cache
Management (see [memory](.claude/projects/-Users-alfredang-projects-tertiary-ai-mms/memory/feedback_admin_hidden_row_checkboxes.md)).

---

## 10. Migrations system

- Drop numbered `*.sql` into `migrations/`; runs on container start via
  `docker/entrypoint.sh` → `migrations/apply.php`
- Ledger table: `schema_migrations` — each file runs at most once per DB
- **Splitter quirk**: `apply.php` splits on lines ending with `;` — so
  multi-line string literals must not contain a content line that ends in
  `;`. If unavoidable use `UNHEX('…')` instead of inline strings (see
  [memory: feedback_apply_php_sql_splitter.md](.claude/projects/-Users-alfredang-projects-tertiary-ai-mms/memory/feedback_apply_php_sql_splitter.md))
- Always make migrations idempotent — guard INSERTs with `WHERE NOT EXISTS`
  or use `INSERT IGNORE` / `ON DUPLICATE KEY UPDATE`
- For EAV option seeding pattern, see migration 157 (canonical example)
- Local-dev-only fixups go in `scripts/local-dev/` (never auto-applied)

---

## 11. Admin login is email-only

`MMD/EmailLogin` rewrites `admin/user`. The `admin_user.username` column
is still NOT NULL but is treated as a write-only mirror of `email` —
the Role Management create-user flow sets `username = email` automatically.
Never expose a `username` input.

---

## 12. SG GST is intentionally non-standard

Calculated on the **original course list price** (catalog price before
discount), NOT the discounted subtotal. This is deliberate for SkillsFuture/
WSQ subsidies (tax authority settles GST on pre-subsidy amount). See
`MMD/SingaporePrice`. Don't "fix" this to match Magento's stock behavior.

---

## 13. Shipping is disabled, everywhere, always

All products are courses (instructor-led or virtual). There is **no**
shipping cost on any quote/order/invoice. If you see code that adds or
displays `shipping_amount` / `shipping_method` / tracking — that's legacy
noise. Leave at zero or remove the surfacing.

---

## 14. Multi-country = one install, one catalog, multiple websites

Websites: SG (default), MY, NG, GH, BT, IN. Each has its own domain,
currency, language defaults, and pricing. **Catalog is shared.** When
writing scope-sensitive code:

- Bulk EAV writes via CLI default to **SG website scope (store_id=1)**,
  not admin (`store_id=0`). Always set `Mage::app('admin')` and target
  `store_id=0` explicitly for global writes, and clear per-store overrides.
  See [memory: feedback_eav_save_attribute_scope.md](.claude/projects/-Users-alfredang-projects-tertiary-ai-mms/memory/feedback_eav_save_attribute_scope.md).
- For multi-country country-domain routing (`tertiarycourses.com.<cc>`),
  use the `add-country-store` skill.

---

## 15. Quote items load products "lite" — re-fetch raw attributes in cart/checkout

`$item->getProduct()->getData($customAttr)` returns NULL in the cart/
checkout context. Use `getAttributeRawValue($pid, $code, $storeId)` instead.
See [memory: feedback_quote_item_product_lite_load.md](.claude/projects/-Users-alfredang-projects-tertiary-ai-mms/memory/feedback_quote_item_product_lite_load.md).

---

## 16. Reference: where the live forms actually are

| User-facing form               | Real file |
|--------------------------------|-----------|
| Contact form                   | `app/design/frontend/.../recaptcha/contacts/form.phtml` (NOT `contacts/form.phtml`) — see [memory](.claude/projects/-Users-alfredang-projects-tertiary-ai-mms/memory/reference_contact_form_template.md) |
| Edit Course (admin)            | `app/design/adminhtml/default/default/template/dashboard/index.phtml` (NOT `catalog/product/edit.phtml`) |
| Course list (admin)            | dcf course-list at `dashboard/index.phtml` top half |
| Course Information card (FE)   | `app/design/frontend/ultimo/default/template/catalog/product/view/rightData.phtml` |
| Cover-image dialog (badges)    | `MMD/CourseImage` cover controller + admin block |

---

## TL;DR survival rules

1. **Adding a new course field?** EAV migration is step 1, but you must
   also edit `dashboard/index.phtml` AND `CoursesaveController.php`.
2. **A label looks weird?** Check `translate.csv` before grep-ing for the
   string in templates.
3. **Field exists but storefront shows old value?** Reindex `catalog_product_flat`
   and flush `var/cache/*` + `var/full_page_cache/*`.
4. **WSQ vs non-WSQ?** Branch on `sku LIKE 'TGS-%'`, no new attribute.
5. **Section content in inline HTML?** It probably already moved to a
   `cms_block` keyed `course_<sku>_<section>` — check before editing
   `description`.
6. **Bulk writes from CLI?** Set `Mage::app('admin')` and target
   `store_id=0` explicitly. Then reindex + flush cache.
