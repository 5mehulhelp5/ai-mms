# SEO & Accessibility Improvement Plan

Living document for the Tertiary Courses multi-store SEO/accessibility rollout.
Update statuses inline as items ship — don't delete completed lines (history is the point).

**Baseline (2026-05-26 audit, GSC):** 9,840 not-indexed vs 1,560 indexed.
Worst buckets: Crawled-not-indexed 6,450 / Page with redirect 1,227 / Excluded by noindex 1,149.

**Target:** Indexed ≥ 6,500 (≈80% of canonical URLs) and Crawled-not-indexed < 1,000 by end of Q3 2026.

---

## ✅ Completed (Week 0, shipped 2026-05-26)

| # | Item | Commit | Validation |
|---|------|--------|------------|
| 0.1 | hreflang cluster (en-SG/MY/GH/NG + x-default) in `head.phtml` | `219789f` | `curl ... \| grep hreflang` ≥ 5 on every page ✅ |
| 0.2 | Per-host `/sitemap.xml` rewrites in `.htaccess` | `219789f` | each `.com.<cc>/sitemap.xml` serves own URLs ✅ |
| 0.3 | Per-store sitemap rows + generator script | `mig 163` + `scripts/seo/generate-sitemaps.php` | 7 sitemap_*.xml files exist on disk ✅ |
| 0.4 | robots.txt: per-host Sitemap directives + parameter Disallows + `/tigerdragon/` block | `219789f` | identical 866B file on all hosts ✅ |
| 0.5 | Magento cache cleared + full reindex on local | manual | localhost emits hreflang ✅ |

**Outstanding from Week 0:** Trigger `scripts/seo/generate-sitemaps.php` **on production** so the files exist immediately (daily cron 03:00 SGT otherwise).

---

## Week 1 — Quick wins (shipped 2026-05-26)

Owner: TBD. Low risk, each item is a 1-file or 1-template change.

| # | Item | File(s) | Status |
|---|------|---------|--------|
| 1.1 | Remove `maximum-scale=1.0, user-scalable=no` from viewport meta (WCAG 1.4.4) | [head.phtml](app/design/frontend/ultimo/default/template/page/html/head.phtml) | ✅ `2ad44b974` |
| 1.2 | Add OG/Twitter card tags to head.phtml | [head.phtml](app/design/frontend/ultimo/default/template/page/html/head.phtml) | ✅ `2ad44b974` |
| 1.3 | Fix product H1 to use `meta_title \|\| name + " Course in " + country` | [view.phtml:742](app/design/frontend/ultimo/default/template/catalog/product/view.phtml#L742) | ✅ `2ad44b974` |
| 1.4 | Add `loading="lazy"` to catalog list images (6 templates) | list.phtml, related_multi/tabbed.phtml, upsell.phtml, new.phtml, list_featured_slider.phtml | ✅ `6d200a8c6` (Week 1.5) |
| 1.5 | Set `<html lang>` per store (en-SG / en-MY / en-GH / en-NG / en-BT / en-IN) | 1column.phtml + 2/3-column templates | ✅ `2ad44b974` |

**Validation after Week 1 ships:**
```bash
# 1.1
curl -sLS https://www.tertiarycourses.com.sg/ | grep viewport
# Expect: no "maximum-scale", no "user-scalable=no"

# 1.2
curl -sLS https://www.tertiarycourses.com.sg/python-programming.html | grep -ciE 'og:|twitter:'
# Expect: ≥5

# 1.3
curl -sLS https://www.tertiarycourses.com.sg/python-programming.html | grep -oE '<h1[^>]*>[^<]*</h1>'
# Expect: H1 longer than 30 chars, contains "Singapore" or course context

# 1.4
curl -sLS https://www.tertiarycourses.com.sg/ | grep -c 'loading="lazy"'
# Expect: ≥30 (was 0)

# 1.5
for d in sg my ng gh; do
  echo -n "  .com.$d → "; curl -sLS "https://www.tertiarycourses.com.$d/" | grep -oE '<html [^>]+lang="[^"]+"' | head -1
done
# Expect: lang="en-SG" / en-MY / en-NG / en-GH
```

---

## Week 2 — Schema + caching (shipped 2026-05-26)

| # | Item | File(s) | Status |
|---|------|---------|--------|
| 2.1 | Add `Course` JSON-LD to product pages (`name`, `description`, `provider`, `offers`, `hasCourseInstance`, `image`) | [head.phtml](app/design/frontend/ultimo/default/template/page/html/head.phtml) (in `<head>`, conditional on $_product) | ✅ `142128b26` |
| 2.2 | Enable HSTS header — **soft version**: `max-age=31536000`, no includeSubDomains, no preload | [.htaccess](.htaccess#L13-L25) | ✅ `9b4e39ecd` |
| 2.3 | Set `Cache-Control: public, max-age=300` on catalog HTML | `.htaccess` LocationMatch OR Magento FPC config | ⏸️ **Deferred to backlog** — needs hole-punching design (cart badge / customer-group prices leak across cache) |
| 2.4 | Validate `Course` schema with Rich Results Test on 5 sample courses | https://search.google.com/test/rich-results | ☐ Pending — run after Coolify deploy completes |

**Risk note 2.2 — what we did:** HSTS deployed in `<IfModule mod_headers.c>` wrapper (matches existing defensive pattern from mod_headers incident). Only the bare host is locked — no includeSubDomains so e.g. `mail.tertiarycourses.com.sg` is safe even without TLS. After ≥3 months of clean operation we can escalate to `includeSubDomains; preload` if desired.

**Risk note 2.3 — why deferred:** Magento 1 emits user-specific HTML on catalog pages (cart count badge, "logged in as X" in header, customer-group pricing). Changing `Cache-Control` to `public` without hole-punching (or refactoring those fragments to AJAX) means proxy/CDN layers could serve one user's session to another. This is a multi-day refactor disguised as a 1-line change. Moved to backlog as B.7.

---

## Validation commands — Week 1 + 2 (run after Coolify rebuilds finish)

```bash
# Week 1.1 — viewport (no maximum-scale, no user-scalable=no)
curl -sLS https://www.tertiarycourses.com.sg/ | grep -oE '<meta name="viewport"[^/]+'
# Expected: width=device-width, initial-scale=1

# Week 1.2 — OG / Twitter cards on a product page (≥9 lines)
curl -sLS https://www.tertiarycourses.com.sg/notion-essential-training.html | grep -ciE 'og:|twitter:'

# Week 1.3 — product H1 with country in title
curl -sLS https://www.tertiarycourses.com.sg/notion-essential-training.html | grep -oE '<h1 itemprop="name">[^<]+'
# Expected: contains "Tertiary Courses Singapore" (SG) or "Malaysia" (MY) etc.

# Week 1.4 — lazy-loaded list images
curl -sLS https://www.tertiarycourses.com.sg/programming-courses.html | grep -c 'loading="lazy"'
# Expected: ≥15 (was 0)

# Week 1.5 — per-store html lang
for d in sg my ng gh; do
  echo -n "  .com.$d → "; curl -sLS "https://www.tertiarycourses.com.$d/" | grep -oE '<html [^>]+lang="[^"]+"' | head -1
done
# Expected: en-SG / en-MY / en-NG / en-GH

# Week 2.1 — Course JSON-LD validates
curl -sLS https://www.tertiarycourses.com.sg/notion-essential-training.html \
  | grep -oE '<script type="application/ld\+json">[^<]+</script>' \
  | sed 's|</script>||;s|<script[^>]*>||' | python3 -m json.tool
# Expected: { "@type": "Course", "name": "...", "provider": {...}, "offers": {...} }

# Week 2.2 — HSTS header on every host
for d in www.tertiarycourses.com.sg www.tertiarycourses.com.my www.tertiarycourses.com.ng www.tertiarycourses.com.gh www.tertiaryinfotech.edu.sg; do
  echo -n "  $d → "; curl -sI "https://$d/" | grep -i strict-transport
done
# Expected: Strict-Transport-Security: max-age=31536000
```

## Week 3 — Structural (partial ship 2026-05-26)

| # | Item | File(s) | Status |
|---|------|---------|--------|
| 3.1 | Replace `<div class="header/main/footer">` with `<header>/<main>/<footer>` HTML5 landmarks (classes preserved, additive) | header.phtml, footer.phtml, 1column/2col-left/2col-right/3col templates | ✅ `8a630b260` |
| 3.2 | Add `aria-expanded` toggling to Ultimo mega menu items | `infortis/ultramegamenu/mainmenu.phtml` + JS | ☐ Deferred — needs block override + JS togglers, not cosmetic |
| 3.3 | Decide on "Use Categories Path for Product URLs" (currently YES, redirects 1.3K short URLs — wastes crawl) | Admin → Catalog → SEO config + URL rewrite reindex | ☐ **High-risk; ship in its own dedicated week** with no other SEO changes (4-8 week stabilisation window in GSC) |
| 3.4 | Demote logo H1 wrapper to div (was keyword-stuffed brand slogan, not a real H1) | [logo.phtml](app/design/frontend/ultimo/default/template/page/html/logo.phtml) | ✅ `8a630b260` |
| 3.4b | Add a real H1 inside the homepage hero CMS block | admin → CMS → Static Blocks (hero block on homepage) | ☐ Pending — content task, needs admin |

**Risk note 3.3:** Flipping the SEO category-path setting will **301 every existing long URL back to the short URL**. Google must re-crawl all 1,365 catalog URLs. Plan a 4-week stabilisation window after this change; don't combine with other indexability changes.

---

## Ongoing — every Monday

- [ ] Open GSC Page Indexing report for each of the 4 country properties
- [ ] Record indexed-vs-not-indexed counts in the table below
- [ ] On any reduced "Not indexed" bucket, click **Validate Fix**
- [ ] Run `curl ... | grep hreflang` on 3 random products as smoke test (catches deployment regressions)
- [ ] If indexed count hasn't moved in 2 consecutive weeks, audit which bucket is stuck and add a Week N+1 line item

### Weekly tracker (fill in each Monday)

| Date | SG indexed | MY indexed | NG indexed | GH indexed | Total not-indexed | Notes |
|---|---|---|---|---|---|---|
| 2026-05-26 (baseline) | — | — | — | — | 9,840 | Pre-fix. GSC was aggregated, not per-country. Re-baseline next Monday. |
| 2026-06-01 | | | | | | |
| 2026-06-08 | | | | | | |
| 2026-06-15 | | | | | | |
| 2026-06-22 | | | | | | |
| 2026-06-29 | | | | | | |

---

## Backlog (no scheduled week yet)

| # | Item | Why parked |
|---|------|------------|
| B.1 | Fix HTTP→HTTPS redirect from 302 to 301 | Lives at Coolify/LB layer, not in repo. Needs ops access. |
| B.2 | Add Cloudflare in front for GH/NG TTFB | Infra change, separate decision (cost + DNS handover). |
| B.3 | Find + 301 the source of `/tableau-training.html` 404 backlink | One-off. Pull from GSC "Not found" report when convenient. |
| B.4 | Add FAQ schema to high-traffic course pages | Bigger content task — needs FAQs written per course. |
| B.5 | Consolidate 32 inline `<style>` blocks on homepage into custom.css | CWV minor win; depends on CMS block audit. |
| B.6 | Add `Organization` + `BreadcrumbList` JSON-LD globally (currently microdata only) | Microdata works; JSON-LD is cleaner but not urgent. |
| B.7 | `Cache-Control: public, max-age=300` on catalog HTML (originally Week 2.3) | Hole-punching design required — cart badge / customer-group pricing leak across shared cache. Multi-day refactor. |
| B.8 | Escalate HSTS to `includeSubDomains; preload` | Wait ≥3 months from 2026-05-26 with no incidents, then audit every subdomain for HTTPS readiness before flipping. |

---

## How to use this document

- **Read first** before starting any SEO-related change — Week N items are pre-vetted and ordered for safety
- **Update statuses in this file** in the same commit that ships the change (don't let the doc drift)
- **Use the weekly tracker** as the single source of truth for "is the fix working" rather than ad-hoc curl checks
- When a Week's items all ship, add a horizontal rule and start the next week's notes below

The companion memory file is
[`feedback_seo_hreflang_per_store_sitemap.md`](.claude/memory/) — read that
before touching hreflang/sitemap code so the Week 0 lessons don't get
re-learned.
