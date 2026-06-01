---
name: feedback-button-as-card-needs-text-align-left
description: "When using <button> as a full-width card row (role-select, etc.), explicitly set text-align:left, font-family:inherit, color:inherit — UA defaults will center the label and override the page font."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 3a58fe58-e60a-4afb-9016-1009f7cbf327
---

When a `<button>` is styled as a full-width row/card (e.g. `.role-card` in role-select.phtml), the user-agent button defaults silently fight your layout:

- `text-align: center` — centers the inner text between any flex siblings (icon left, chevron right) instead of letting it sit next to the icon.
- `font-family` / `color` — fall back to OS button defaults, not the page styles.

**Why:** the role-selection screen rendered "Learner / Trainer / Developer…" labels centered in the middle of each row, looking like a distorted layout. Root cause was not a flex bug but the browser default `text-align: center` on `<button>`. See [rolemanager.css](../../../../../projects/tertiary/ai-mms/skin/adminhtml/default/default/rolemanager.css) `.role-card` block.

**How to apply:** any time a `<button>` is used as a list row / card / nav item, add `text-align: left; font-family: inherit; color: inherit;` to its CSS. If the button is wrapped in `<form style="display:inline">` to make a POST link, also force `form { display: block; width: 100% }` (scoped via `body:has(...)`) so the button can actually span its container — inline forms can collapse a `width:100%` child to content-width.

Related: [[feedback-rolemanager-css-page-scoped-bleed]] for the body:has() scoping pattern used on this same page.
