---
name: mobile-box-additional-hide-direct-child
description: "Mobile hide rule for product-view bottom tabs must use `.product-view > .box-additional` — unqualified `.box-additional` also kills the options + Register Your Interest CTA in the secondary column."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 290e9fe4-80fa-4ebd-b0f2-550c3f880281
---

On the product (course) page, the mobile hide rule for the bottom
tabs section must be scoped to a **direct child** of `.product-view`,
not every `.box-additional`.

**Why:** The product layout has TWO different `.box-additional`
wrappers:

1. `.product-view > .box-additional.grid12-8` — the bottom
   Course-Details / Course-Info / Job-Roles / Reviews tabs (intended
   to be hidden on mobile per spec).
2. `.product-secondary-column .inner .box-additional` — wraps
   `.container2-wrapper` which holds the custom options
   (Mode of Training, Course Date, Sponsorship, Funding Eligibility…)
   AND the "Register Your Interest" add-to-cart button.

A blanket `.catalog-product-view .box-additional { display:none }`
inside the `@media (max-width:770px)` block kills #2 as well,
leaving phone users with the price but no options and no CTA — i.e.
the page becomes unbookable on mobile.

**How to apply:** When adding/editing mobile hide rules for the bottom
tabs wrapper, always use the direct-child combinator:

```css
.catalog-product-view .product-view > .box-additional { display: none !important; }
```

NOT:

```css
.catalog-product-view .box-additional { display: none !important; }  /* WRONG */
```

Verified at [skin/frontend/ultimo/default/css/custom.css:671](skin/frontend/ultimo/default/css/custom.css#L671).
Related: the mobile flex-order block at [skin/frontend/ultimo/default/css/custom.css:2125](skin/frontend/ultimo/default/css/custom.css#L2125)
assigns `order:13` to `.product-secondary-column .box-additional` —
which only works if it isn't display:none'd away first.

See also [[ultimo-box-additional-float-clear]] for the OTHER common
`.box-additional` gotcha in this codebase (clear:both vs clear:none).
