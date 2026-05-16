---
name: openmage-frontend-developer
description: Build or modify the customer-facing storefront for this OpenMage 1.x LMS — Infortis Ultimo theme. Use when the user mentions "frontend", "storefront", "Ultimo", "homepage", "category page", "product page", "course page", "checkout", "header", "footer", "responsive", "mobile", "category navigation", or any customer-facing UI. Covers layout XML, phtml templates, Prototype.js/jQuery patterns (NOT RequireJS/KnockoutJS — those are Magento 2), and LESS/CSS overrides. For admin/backend UI, use the backend-design skill instead.
---

# OpenMage Frontend Developer (Tertiary Courses LMS storefront)

You are modifying the customer-facing storefront — what visitors see at `https://www.tertiaryinfotech.edu.sg/`, `https://www.tertiarycourses.com.my/`, etc. **For admin theme work, hand off to the `backend-design` skill.**

## Stack reality

- **Theme**: Infortis_Ultimo (premium Magento 1 theme). Theme files live at:
  - `skin/frontend/ultimo/default/` (CSS, JS, images)
  - `app/design/frontend/ultimo/default/` (layout XML, phtml templates)
  - `skin/frontend/base/default/` and `app/design/frontend/base/default/` — Magento 1 base, lowest fallback
- **Base theme inheritance order** (cascade up): `ultimo/default` → `base/default` → core. Override by putting a file in the higher-precedence theme path with the *same relative path*.
- **JS**: **Prototype.js + jQuery (in no-conflict mode)**. NOT RequireJS, NOT KnockoutJS. Those are Magento 2 — they will not work here.
- **CSS**: Ultimo uses LESS compiled at theme build time. The compiled output is in `skin/frontend/ultimo/default/css/`. Most "edits" are done by adding rules to `css/custom-styles.css` (loaded last, wins on specificity), not recompiling LESS.
- **Mobile**: Ultimo has a built-in responsive grid; breakpoints are in its LESS. The breakpoints commonly used: 480, 600, 768, 980, 1200.
- **No CDN currently**. Server in Singapore. GH/NG latency is high — every asset request costs 200-400ms there.

## Cascade rule (Ultimo override pattern)

To override **any** core file, copy it from its source path to the *same relative path* under `ultimo/default`. Examples:

| Override of | Put your copy at |
|-------------|------------------|
| Core product view template | `app/design/frontend/ultimo/default/template/catalog/product/view.phtml` |
| Core checkout cart template | `app/design/frontend/ultimo/default/template/checkout/cart.phtml` |
| Core header | `app/design/frontend/ultimo/default/template/page/html/header.phtml` |
| Ultimo's own product price | (already under `ultimo/default`; edit in place — or copy to a child theme if one exists) |

**Don't edit `app/design/frontend/base/default/` or `app/design/frontend/default/default/`.** Those are core/legacy. Anything you put there is fragile.

## Common tasks

### Adding a CSS rule

For most one-off changes, append to `skin/frontend/ultimo/default/css/custom-styles.css`. It's loaded last → wins specificity ties.

```css
/* Course detail page — emphasise the SkillsFuture badge */
.product-shop .skillsfuture-badge {
    background: #ffd700;
    padding: 4px 10px;
    border-radius: 4px;
    font-weight: 700;
}
```

For larger changes, find the source LESS file in `skin/frontend/ultimo/default/css/infortis/` and modify, then recompile via the theme's build (if your local has a `grunt` / theme build pipeline configured). If not configured, stick to `custom-styles.css` — recompiling Ultimo's LESS requires its original toolchain.

### Adding a JS interaction

Use the existing jQuery (already loaded by Ultimo, no-conflict, so `jQuery(...)` or `$j(...)` depending on theme — check `head.phtml` for the alias). Add a small inline script in the relevant phtml, or a new JS file referenced from `local.xml`.

```html
<script type="text/javascript">
    jQuery(function($) {
        $('.course-card').on('click', function () {
            // track click ...
        });
    });
</script>
```

Avoid global pollution and don't load a third jQuery. The page already has Prototype.js *and* jQuery — adding a third lib breaks the page.

### Adding a new block to a page

Use layout XML, not by editing phtml directly. Edit `app/design/frontend/ultimo/default/layout/local.xml` (create it if it doesn't exist — it's the canonical "this is my customisation" file):

```xml
<?xml version="1.0"?>
<layout>
    <catalog_product_view>
        <reference name="product.info.extrahint">
            <block type="core/template" name="mmd.subsidy_hint"
                   template="mmd/courses/subsidy-hint.phtml" />
        </reference>
    </catalog_product_view>
</layout>
```

Then create `app/design/frontend/ultimo/default/template/mmd/courses/subsidy-hint.phtml`.

### Translating / changing copy

Never hardcode English strings in templates. Use:

```php
<?= $this->__('Download Syllabus') ?>
```

Then add the translation to `app/locale/<locale>/translate.csv` if needed.

Many copy changes live in `core_config_data` (e.g. `design/header/welcome`, footer blocks) — propose a migration (see migration 060, 062, 067 as examples) instead of editing templates.

### Country-specific frontend differences

Per-store overrides happen via:
1. **`design/theme/*` config per store** (System → Configuration → Design, scope=store). Lets you ship a different theme per country if needed.
2. **CMS blocks scoped to a store** — e.g. `block_footer_column5` is "Malaysia Footer Row 1". Edit via admin Catalog → CMS → Static Blocks → filter by store.
3. **Phtml conditional**:
```php
<?php $cc = Mage::helper('mmd_rolemanager')->getActiveCountryCode(); ?>
<?php if ($cc === 'MY'): ?>
    <p><?= $this->__('HRDC claimable') ?></p>
<?php endif; ?>
```

Prefer 1 or 2 over 3. Phtml `if` chains for country diff get tangled.

## Performance (Core Web Vitals)

This is the slowest part of the stack. Easy wins:

- **Magento JS/CSS merge & minify** is OFF by default. Enable in System → Configuration → Developer → JavaScript Settings + CSS Settings. Per store. Free, no code.
- **Lazy-load product images** — Ultimo doesn't by default. Add `loading="lazy"` to `<img>` tags in:
  - `template/catalog/product/list.phtml` (category grid)
  - `template/catalog/category/products.phtml`
  - `template/catalog/product/gallery.phtml` (product detail — but NOT the LCP hero image)
- **Defer non-critical JS** — Ultimo loads a lot. Audit via Chrome DevTools → Coverage tab.
- **Don't add heavy 3rd-party scripts** (chat widgets, analytics tag managers) without measuring INP impact first.

## Multi-store SEO touchpoints (handled here, not in admin)

When editing templates, the **hreflang cluster** lives in head:

```php
<?php foreach (Mage::app()->getStores() as $store): ?>
    <link rel="alternate"
          hreflang="<?= $this->escapeHtml($store->getConfig('general/locale/code_iso')) ?>"
          href="<?= $this->escapeUrl($store->getCurrentUrl(false)) ?>" />
<?php endforeach; ?>
<link rel="alternate" hreflang="x-default"
      href="<?= $this->escapeUrl(Mage::app()->getStore('default')->getCurrentUrl(false)) ?>" />
```

If you're not seeing hreflang in `view-source:` of any country page, it's missing. Add to `app/design/frontend/ultimo/default/template/page/html/head.phtml` (override). See the `seo-audit` skill for more context.

## Security in templates

Every output must be escaped — even data you "trust":

```php
<?= $this->escapeHtml($product->getName()) ?>
<?= $this->escapeUrl($url) ?>
<?php /* For JS string interpolation: */ ?>
<script>var foo = "<?= $this->jsQuoteEscape($value) ?>";</script>
```

Never `<?= $value ?>` raw. Never `<?= $_GET['x'] ?>` — Magento has `Mage::app()->getRequest()->getParam('x')` which routes through input sanitisation; even then, escape on output.

## Cache invalidation after template/layout changes

Magento aggressively caches layout XML and block output. After editing:

1. Clear cache: `docker exec ai-mms-web-1 sh -c 'rm -rf /var/www/html/var/cache/* /var/www/html/var/full_page_cache/*'`
2. Or via admin: System → Cache Management → flush the relevant types.
3. If only CSS changed: hard-refresh the browser (`Cmd+Shift+R`). CSS files have version query strings appended; Magento bumps them when you click "Merge & Minify" or change theme files.

## Anti-patterns — don't

- Don't import RequireJS, KnockoutJS, or Magento 2's `Magento_Ui` JS components. They will not work; this is Magento 1.
- Don't use `<?php echo` in templates — use `<?=`. Don't omit escaping.
- Don't edit `app/design/frontend/base/default/`. Override into `ultimo/default` instead.
- Don't recompile Ultimo's LESS unless you have the original toolchain configured. Use `custom-styles.css`.
- Don't load extra jQuery, Bootstrap, or other CSS frameworks — Ultimo already provides a grid + components. Adding another framework breaks layout in subtle ways.
- Don't change Prototype.js. Magento 1 core depends on it; removing it breaks checkout.
- Don't put pricing logic, country logic, or DB queries in `.phtml`. Move to the Block class (`getMyData()`).
- Don't add inline `<style>` blocks in phtml that override CSS files — they're hard to find later. Use `custom-styles.css`.

## Workflow

1. Identify the page / block you want to change. View page source in browser; templates often reveal themselves via comments like `<!-- BEGIN page/html/header.phtml -->`.
2. Find the source template (`grep -rln "<some unique string>" app/design/frontend/ skin/frontend/`).
3. Copy to `ultimo/default` at the same relative path. Don't edit in place if it's in `base/`.
4. Make your change. Escape output. Use `$this->__()` for strings.
5. Clear cache, reload, verify across SG/MY/GH/NG stores (use the store-switcher or directly visit each domain locally with header injection: `curl -H "Host: www.tertiarycourses.com.my" http://localhost:8080/`).
6. Run the `openmage-code-reviewer` skill if PHP/XML changed.
7. If a copy/text change → consider whether it belongs in `core_config_data` (migration) rather than a template — see migration 067 as the pattern.

## Related

- **backend-design** — for admin theme + adminhtml UI.
- **openmage-code-reviewer** — review your phtml/XML changes.
- **seo-audit** — hreflang, schema, meta tags, Core Web Vitals.
- **web-accessibility** — WCAG, keyboard nav, screen-reader friendliness for forms / modals.
