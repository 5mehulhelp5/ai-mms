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

## Week 1 — Quick wins (target ship: 2026-05-30)

Owner: TBD. Low risk, each item is a 1-file or 1-template change.

| # | Item | File(s) | Status |
|---|------|---------|--------|
| 1.1 | Remove `maximum-scale=1.0, user-scalable=no` from viewport meta (WCAG 1.4.4) | [head.phtml:33](app/design/frontend/ultimo/default/template/page/html/head.phtml#L33) | ☐ |
| 1.2 | Add OG/Twitter card tags to head.phtml | [head.phtml](app/design/frontend/ultimo/default/template/page/html/head.phtml) (after hreflang block) | ☐ |
| 1.3 | Fix product H1 to use `meta_title \|\| name + " Course in " + country` | [view.phtml:742](app/design/frontend/ultimo/default/template/catalog/product/view.phtml#L742) | ☐ |
| 1.4 | Add `loading="lazy"` to non-hero images | category list, footer CMS blocks | ☐ |
| 1.5 | Set `<html lang>` per store (en-SG / en-MY / en-GH / en-NG) | [1column.phtml:65](app/design/frontend/ultimo/default/template/page/1column.phtml#L65) + 2/3-column templates | ☐ |

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

## Week 2 — Schema + caching (target ship: 2026-06-06)

| # | Item | File(s) | Status |
|---|------|---------|--------|
| 2.1 | Add `Course` JSON-LD to product view (`name`, `description`, `provider`, `offers`, `hasCourseInstance`) | new partial included from view.phtml | ☐ |
| 2.2 | Enable HSTS header (re-enable commented line in `.htaccess`) | [.htaccess:11](.htaccess#L11) | ☐ |
| 2.3 | Set `Cache-Control: public, max-age=300` on catalog HTML (NOT on customer/checkout) | `.htaccess` LocationMatch OR Magento FPC config | ☐ |
| 2.4 | Validate `Course` schema with Rich Results Test on 5 sample courses | manual | ☐ |

**Risk note 2.2:** HSTS is a one-way street. Once a browser sees it, it refuses HTTP for a year. Confirm every subdomain serves HTTPS cleanly **before** enabling.

**Risk note 2.3:** Changing Cache-Control to `public` means logged-in user state could leak via shared cache if Vary headers are wrong. Test logged-in vs logged-out view of the same product page returns the right cart state. Easier: keep no-store as default and add `Cache-Control: public` only on robot-detected user agents OR on routes that are demonstrably stateless.

---

## Week 3–4 — Structural (target ship: 2026-06-20)

| # | Item | File(s) | Status |
|---|------|---------|--------|
| 3.1 | Replace `<div class="header/main/footer">` with `<header>/<main>/<footer>` HTML5 landmarks | `page/1column.phtml`, `2columns-*.phtml`, `3columns.phtml`, header.phtml, footer.phtml | ☐ |
| 3.2 | Add `aria-expanded` toggling to Ultimo mega menu items | `page/html/topmenu.phtml` + Ultimo menu JS | ☐ |
| 3.3 | Audit + decide on "Use Categories Path for Product URLs" (current=Yes, redirects 1.3K short URLs to long ones — wastes crawl) | Admin → Catalog → SEO config + URL rewrite reindex | ☐ |
| 3.4 | Fix homepage H1 — move keyword phrase to real H1 inside hero block, demote logo wrapper to div | header.phtml + hero CMS block | ☐ |

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
