---
name: feedback-chrome-icons-need-important
description: "Bare-glyph chrome icons (topbar bell, theme toggle, avatar) must declare every visual reset with !important — the generic admin button rule wins otherwise and the icon ships as a bordered box."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 337733ba-6878-4dd5-b9a2-e78af5d7df13
---

When building a chrome-level icon (topbar bell, sidebar header icon, page-header gutter glyph) on this OpenMage admin, every visual reset must carry `!important`. The button "look" comes from at least a dozen properties baked into `sidebar-nav.css` §18 + `boxes.css`'s generic `<button>` and `.admin-main button` rules: `padding`, `border`, `border-radius`, `background`, `background-image`, `box-shadow`, `text-shadow`, `min-width`, `min-height`, `line-height`, `font-size`. Miss any one and the cascade wins — the glyph renders as a rounded blue button with the SVG centered inside it.

**Why:** 2026-05-29 incident — the audit-issues bell was added to `.admin-topbar` with `border:0; background:transparent;` (no `!important`). It shipped as a 28×28 rounded blue outline box because `.admin-main button { border: 1px solid … }` and friends had higher cascade weight at merge time. User screenshot showed a hollow rounded rectangle with the `19` badge floating in the corner — no bell glyph visible. Adding `!important` across every property (and resetting `box-shadow` / `background-image` / `text-shadow` / `min-width` explicitly) was the only fix. See [[backend-design]] skill — "Hard rule: icon > button for chrome-level actions" section now codifies this with the override trap callout.

**How to apply:** Whenever you add a new icon to admin chrome (anything inside `.admin-topbar`, `.admin-sidebar`, or page header gutters), copy the canonical pattern from the backend-design skill verbatim — don't drop the `!important` declarations even if the icon looks fine in your local test, because the merged CSS bundle order varies. Reference implementation: `.audit-bell-btn` in `skin/adminhtml/default/default/dark-theme.css` (the audit bell next to theme toggle and user avatar). Severity color rules must also chain class selectors (`.foo-icon-btn.foo-icon-critical`) and use `!important` to win against the base `color: #cbd5e1 !important`. Use `filter: drop-shadow(…)` for glow — `box-shadow` reintroduces the rectangle behind the glyph and reads as button chrome.
