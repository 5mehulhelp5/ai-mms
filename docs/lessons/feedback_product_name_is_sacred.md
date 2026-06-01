---
name: product-name-is-sacred
description: "Templates must render $_product->getName() verbatim — never append \"Course in <country>\", never fall back to meta_title for the H1. meta_title is the right place for SEO suffixes"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 3aa15a42-b869-46bc-ad14-02fc5f5edbdd
---

The product `name` EAV attribute is editorial content the admin team
controls. **Templates must NEVER modify it for rendering** — not the H1,
not the JSON-LD `name`, not the breadcrumb leaf, not the category list
tile, not any related/upsell tile, not future schema (FAQPage, ItemList,
etc.).

This includes:
- No appending country, brand, funding, duration ("Python Course in Singapore")
- No "fall back to meta_title when name is too short" — meta_title
  carries SEO suffixes ("HRD Corp Funded ... | Tertiary Courses Malaysia")
  and re-introduces them through the back door
- No per-store template branching that mutates the rendered name
  (per-store overrides go in the EAV at admin scope, not in PHP)

**Why:** Tried `<name> Course in <country>` as an H1 fallback (commit
`2ad44b974`, 2026-05-26) and a meta_title-based H1; had to revert both
the same day. The admin enters the course name; the template echoes it
verbatim. Any template that alters it is a bug, no matter how
SEO-friendly the modification looks.

**meta_title IS allowed to carry SEO suffixes.** That's its purpose.
It feeds `<title>`, `og:title`, `twitter:title`, and SERP snippets — none
of which are the visible course title on the page itself. As of 2026-05-26:
547 products on MY store have `HRD Corp Funded` in their meta_title and
that's the correct location.

**How to apply:** For any template change touching the rendered course
title, the only acceptable code is:
```php
echo $_helper->productAttribute($_product, $_product->getName(), 'name');
```
For JSON-LD `name` field, same thing:
```php
'name' => (string) $_product->getName(),
```
After any change, validate that `<h1 itemprop="name">` content equals
`$_product->getName()` exactly on both SG and MY stores via curl.

Canonical reference: see "Hard constraints" section in
[SEO_IMPROVEMENT.md](../../../../../projects/tertiary/ai-mms/SEO_IMPROVEMENT.md)
for the full inventory table of which fields may/may not carry suffixes.
