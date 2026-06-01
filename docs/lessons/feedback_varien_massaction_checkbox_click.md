---
name: varien-massaction-needs-click
description: "To programmatically select a row in a Magento admin grid, call checkbox.click() — assigning .checked = true silently leaves varienGridMassaction at 0 selected"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 7e8e4172-8c26-44bd-9da3-0dfd377aca4e
---

When injecting JS that selects rows in a Magento admin grid (mass-action workflow), always trigger selection via `checkbox.click()` (after checking `!checkbox.checked && !checkbox.disabled`), never via `checkbox.checked = true`.

**Why:** `varienGridMassaction` tracks its selection set through the checkbox's inline `onclick` handler, not the DOM `checked` property. Setting `.checked` directly bypasses the handler, so the mass-action object still believes 0 rows are selected. When Submit fires, its own validator alerts "Please select items" and the form never posts — the user sees a button that does nothing. Symptom: Orphaned Role Resources page — per-row "Actions → Delete" dropdown appeared to fire but nothing happened, and "0 items selected" counter never moved.

**How to apply:** Any time custom JS in [sidebar-nav-v2.js](skin/adminhtml/default/default/js/sidebar-nav-v2.js) (or anywhere else in admin) needs to programmatically tick grid checkboxes — per-row action injections, select-all toggles, "delete all" buttons — use `.click()`. To unselect rows that are currently checked, also `.click()` (it toggles). Pattern is already proven at [sidebar-nav-v2.js:1333](skin/adminhtml/default/default/js/sidebar-nav-v2.js#L1333) in `injectHeaderSelectAll` and applied at [sidebar-nav-v2.js:1186](skin/adminhtml/default/default/js/sidebar-nav-v2.js#L1186) in the per-row action handler. Same rule should govern any future grid-automation JS. Related: [[admin-hidden-row-checkboxes]] — the checkbox column itself is hidden by `removeCheckboxColumn`, which is why programmatic selection is the only path.
