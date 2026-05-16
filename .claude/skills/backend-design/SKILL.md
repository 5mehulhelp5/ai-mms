---
name: backend-design
description: Design system for the OpenMage admin panel — branding, color tokens, buttons, grids, toolbars, badges. Use when styling or reviewing any adminhtml UI (dark theme, custom modules, RoleManager, dashboards, grids), when a button/toolbar/badge "looks off" or inconsistent, when adding a new admin page, or on requests like "make the admin look more professional", "modern button design", "consistent backend design", "fix the dark theme". Keeps every admin screen visually consistent with the existing token system.
---

# Backend (admin) design system

The admin panel is OpenMage 1.x styled into a custom dark theme. **Do not invent
new colors, paddings, or button styles per-page.** Everything routes through one
token set and a small number of component rules. New admin UI must reuse them so
the panel stays consistent.

## Density preference — compact, not airy

Strongly prefer **compact** layouts. Admin users are power users who want
high information density and short mouse travel — not a marketing landing
page. When in doubt, smaller is better.

Defaults to use unless there's a specific reason otherwise:

- **Buttons in toolbars / action rows**: `height: 28px`, `padding: 2px 14px`, `font-size: 12px`, `border-radius: 6px`. (Page-level Save/Cancel primary buttons stay at the bigger §18 size — those are deliberate emphasis.)
- **Selects / dropdowns in toolbars**: `height: 28px`, `padding: 2px 8px`, `font-size: 12px`, `border-radius: 6px`. Match button height exactly so they sit on the same baseline.
- **Section sub-headers** (bare `<h3>` like "Additional Cache Management"): `font: 700 12px/1.4`, `--t4`, `uppercase`, `letter-spacing: 0.6px`. Not a 26px title.
- **Form-list / stacked-rows panels**: prefer **no card wrapper** — just rows sitting on the page background with a `1px var(--b1)` hairline between them (`tr + tr { border-top }`). Reach for a card (`--d3` bg + border + radius) only when the panel needs to stand apart from neighbouring content.
- **Toolbar / massaction row padding**: `6px 12px` on the wrapper, `gap: 6px` between Actions+select+Submit, `gap: 14px` between selection links.
- **Grid rows**: `6-10px` cell padding, never more.
- **Labels next to inputs**: 12px muted (`--t4`), small `margin-right` (~6px) — they're metadata, not headings.

Anti-pattern: wrapping every section in a `--d3` card with 16-20px padding "for visual separation". On a dense admin page this stacks into nested-panel mush. Stack tightly, separate with thin lines, use a card only when truly needed.

## Where things live

| File | Role |
|------|------|
| `skin/adminhtml/default/default/dark-theme.css` | `:root` design tokens + base dark reset. **Tokens are the single source of truth.** |
| `skin/adminhtml/default/default/sidebar-nav.css` | Component layer: grids, buttons (§18), form panels, toolbars/massaction (§16), filters, KPI cards. Numbered sections — keep them. |
| `skin/adminhtml/default/default/js/sidebar-nav-v2.js` | Grid enhancements: checkbox-column removal, per-row action dropdowns, KPI cards. Has per-grid opt-outs (e.g. `cache_grid_table`). |
| `app/design/adminhtml/default/default/template/` | Admin phtml (header, menu, login, rolemanager). Prefer ID selectors — legacy `boxes.css` has high-specificity rules. |

These are static skin assets — **no build step, no Magento cache clear**. Changes
ship on next deploy; users just hard-refresh.

## Design tokens (never hardcode — use the var)

Defined in `dark-theme.css` `:root`:

- **Surfaces:** `--d0`…`--d6` (darkest→lightest). Page `--d1`, cards `--d3`, raised bars/headers `--d4`, hover `--d5`.
- **Borders:** `--b1` (subtle), `--b2` (default), `--b3` (strong).
- **Text:** `--t1` (headings) → `--t4` (muted/labels) → `--t5` (faint).
- **Accent / brand:** `--brand` (#2563eb, the Tertiary admin primary), `--brand-2`.
- **Semantic:** `--blue/2/3`, `--green/2`, `--red/2`, `--yellow`, `--orange`.
- **Focus ring:** `--ring` — use for every interactive `:focus-visible`.
- **Button gradients:** `--btn-primary[-hover]`, `--btn-success[-hover]`, `--btn-danger[-hover]`.

If a needed shade doesn't exist, add a token to `:root` — don't drop a raw hex
into a component rule.

## Buttons (the canonical component — `sidebar-nav.css` §18)

One language everywhere. Don't restyle buttons per page.

- **Primary** (default `button`, `button.scalable`, `input[type=submit]`): `--btn-primary` gradient, white text, soft elevation. Hover lifts the gradient + blue glow shadow.
- **Success** (`.add`, `.save`, `.success`): `--btn-success`.
- **Danger** (`.delete`, `.cancel`): `--btn-danger`.
- **Secondary/Back** (`.back`, `.secondary`): transparent, `--b2` outline, `--t2` text — quiet, never competes with primary.
- Shared: `min-height:38px`, `padding:8px 20px`, `border-radius:9px`, `font-weight:600`, `:active` press (`translateY(1px)`), `:focus-visible` ring (`--ring`), disabled = `opacity:0.5` + `not-allowed`.

Rules: exactly **one primary** per action area; destructive actions use Danger;
icons go inside the button via the existing `gap`. Magento wraps labels in nested
`<span>` — kill legacy span backgrounds (already handled in §18), don't re-add.

## Grids, toolbars, badges

- **Grids** (`.grid`, §14): dark card, `--b1` border, `border-radius`, compact rows (~`6–10px` cell padding), one entry per row, header in accent, alternating row shade. Let wide grids scroll horizontally — don't force `min-width` that clips columns.
- **Mass-action / toolbar:** slim self-contained card, **detached** from the grid (own `margin-bottom` + full radius — don't fuse it to the grid header), single flat flex row, selection links left, Actions+Submit right with **no nested panel box**. Controls ~`30px` tall. The global rule is `sidebar-nav.css` §16; the trap is that Magento wraps Actions+Submit in a bare `<fieldset>` (no class) and the right `<td>` may contain `<form>` / nested `<div>`s that pick up `--d3` bg + 20px padding from the generic admin form rules, rendering as a doubled gray panel-in-a-panel. §16a flattens every `[id$="_massaction"] fieldset`, `.massaction fieldset`, `.massaction form`, `.massaction form > div` (transparent bg, no border, no padding). §16b strips the dark-pill background off `.massaction a` so Select All / Unselect All / Select Visible / Unselect Visible render as plain blue links — they're navigation, not buttons. §16c sets the selection-links `td` to `inline-flex; gap:14px;`. Wrapper padding stays tight at `6px 12px`. Pattern reference: the `body.adminhtml-cache-index` block at the end of `sidebar-nav.css`.
- **Status badges:** one clean pill — `padding:3px 12px`, `border-radius:999px`, tinted bg at ~15% alpha + solid semantic text color, 1px tinted ring at ~35% alpha. Token map: `notice`/`minor` → `--green`, `major` → `--yellow`, `critical` → `--red`. The global rule lives at `dark-theme.css` §19. **Don't style only the outer `.grid-severity-*`** — Magento 1's legacy `boxes.css` applies the `bg_notifications.gif` sprite to the inner `<span>` at `background-position: 100%`, and the right edge of that sprite is a serrated/torn shape that leaks through as notched edges on the pill. §19a flattens the inner span first (`.grid-severity-* span`, `.cell-status`, `.cell-status span` → `background:none`, `padding:0`, `border:0`); §19b/§19c then style the pill on the outer. If you add a new severity class, extend §19a's selector list too — otherwise the sprite re-appears.
- **KPI cards:** only where genuinely useful. The JS auto-injects them on grids via generic heuristics — opt a grid out (like `cache_grid_table`) when the labels would be wrong or the cards just add clutter.

## Section headers inside admin pages

Magento often emits a sub-section title as a bare `<h3>` (no class) inside a
layout `<table>` — the cache page's "Additional Cache Management" is the
canonical example. The global `h3` is 26px, designed for page titles, and
looks enormous as a sub-section label.

Pattern: scope to the body class, set `<h3>` to a small uppercase muted
label (`font: 700 12px/1.4 …; color: var(--t4); text-transform:uppercase;
letter-spacing:0.6px`), and flatten the wrapper table with
`table:has(> tbody > tr > td > h3)` — `:has()` is widely supported and
precisely matches only the title-bearing layout table, not adjacent
`.form-list` / `.grid` / `.massaction` tables. See the
`body.adminhtml-cache-index` block at the end of `sidebar-nav.css`.

For the `.form-list` of action rows beneath (flush buttons + descriptions),
treat it as one card: `--d3` bg, `--b1` outer border, `border-radius:10px`,
`overflow:hidden`, and use `tr + tr { border-top: 1px solid var(--b1) }`
for hairline separators instead of `tr { border-bottom: ... }` (avoids
ambiguity with `:last-child`). Buttons inside such rows shrink to
~30px height to keep the panel compact.

## Per-page overrides

When a core Magento admin page needs different behavior from the global
enhancements, scope by the body class `body.adminhtml-<route>-<controller>-<action>`
(e.g. `body.adminhtml-cache-index`) and/or the grid's id (`#<grid>_table`), and
add a JS opt-out in `sidebar-nav-v2.js` if the enhancement actively breaks it.
Keep overrides in a clearly commented, numbered section at the end of
`sidebar-nav.css`. Reuse tokens — overrides change *layout*, not the palette.

## Checklist before finishing any admin UI change

1. No raw hex/px-padding that a token or §18/§14 rule already covers.
2. Buttons use the semantic classes; one primary per area.
3. Interactive elements have a `--ring` `:focus-visible` state.
4. New override is body-class/id scoped and won't leak to other grids.
5. Verified in the dark theme at the actual page (hard-refresh; no build/cache).
