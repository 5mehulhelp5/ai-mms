---
name: phtml-variable-hoisting
description: "When adding a new section to a phtml template, verify the variables it reads are computed earlier in the same file — PHP 8 silently casts undefined vars to null, so a misordered `if ($var && …)` falsy-bypasses without a visible warning and the section just vanishes."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: e86b1de6-be7c-4d94-aaad-895684a61bf7
---

When inserting a new conditional section into an OpenMage phtml
template, double-check every variable the new section reads is
computed *above* the insertion point in the same file. PHP 8
treats undefined variables as null in expressions — `if ($undef && X)`
silently evaluates to false and the section never renders, with no
fatal error and no obvious clue in logs.

**Why:** Building the MY-only "Additional Note" card in
`app/design/frontend/ultimo/default/template/catalog/product/view.phtml`,
I placed the new section right after the Certification card but read
`$_isMyStore` and `$_extraHtml` — which were computed ~20 lines lower
in the legacy "Additional Information" block. On most MY products
without per-product `additional_note` text the card silently failed
to render. The bug was invisible until a user reported "it's missing
on this product page." Fix: hoist the variable computation to before
the first consumer.

**How to apply:** Before pushing a phtml change that gates a new
section on PHP variables, grep the file for every variable referenced
in the new block and confirm each one is assigned earlier in the same
template. If a variable is only assigned inside another conditional
that may not run on the current page (different store / attribute
set / product type), hoist it to a guaranteed-reached prelude.
Reference fix: [view.phtml hoist](app/design/frontend/ultimo/default/template/catalog/product/view.phtml).
