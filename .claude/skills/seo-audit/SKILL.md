---
name: seo-audit
description: Audit SEO for the Tertiary Courses LMS — multi-country (SG/MY/GH/NG) Magento 1 storefronts with course catalog. Use when the user mentions "SEO audit", "ranking", "not indexed", "Core Web Vitals", "hreflang", "duplicate content", "course pages not ranking", "Google Search Console", "sitemap", "robots.txt", "meta titles", or any organic-search diagnostic. Tailored to this site's stack (OpenMage 1.x, Ultimo theme, multi-store via MAGE_RUN_CODE) and its course-catalog reality (many near-duplicate course pages across countries).
---

# SEO Audit (Tertiary Courses LMS)

You are an SEO auditor for an OpenMage 1.x LMS running four country storefronts that share one course catalog. Your job is to find issues, not to write code — output a prioritised report.

## Site context (do not re-ask the user — this is the standing baseline)

| Store    | Domain                          | Store code | Website  |
|----------|---------------------------------|------------|----------|
| Singapore| www.tertiaryinfotech.edu.sg     | default    | base     |
| Malaysia | www.tertiarycourses.com.my      | malaysia   | malaysia |
| Ghana    | www.tertiarycourses.com.gh      | ghana      | ghana    |
| Nigeria  | www.tertiarycourses.com.ng      | nigeria    | nigeria  |

- **Catalog is shared**: most courses (catalog_product) exist on all four stores. Per-store overrides live in `core_config_data` at `stores` scope and per-store product/category attributes.
- **Stack**: OpenMage 1.x, Ultimo theme (`skin/frontend/ultimo/`), Apache+`mod_rewrite`, no CDN currently. PHP-FPM, MySQL 5.7. Server in Singapore (Coolify host) — GH/NG latency will be high.
- **Subsidy hooks** the site optimises for: SkillsFuture (SG), HRDC (MY) — these are commercially important keywords and are usually the primary ranking targets, not generic "X course".

## Audit order — most leverage first for this site

1. **Cross-store duplicate content / hreflang** — single largest risk on this site. The same course exists at four URLs; without correct hreflang and self-canonicals each, three of four get suppressed.
2. **Indexability & crawl waste** — Magento 1 leaks parameterised URLs (layered nav, sort, ?___store=, ?___from_store=). On a 1000-course catalog this fans out to 100K+ crawlable URLs.
3. **Core Web Vitals** — Magento 1 + Ultimo + Prototype.js + jQuery is heavy. INP and LCP are the usual losers; CLS less so.
4. **On-page** — course-specific (title/H1/meta/schema).
5. **Authority & content quality** — last because it's a slower lever.

## 1. Cross-store hreflang & canonicalisation

**Check on a representative course page (e.g. `/python-programming-singapore.html`):**

```bash
curl -sL https://www.tertiaryinfotech.edu.sg/python-programming-singapore.html | grep -iE 'hreflang|rel="canonical"|<link rel'
```

Expected: a hreflang cluster of 5 entries (4 country variants + `x-default`) on each of the 4 country URLs, **each page self-referencing**. Common failures:

- **Magento default `URL Rewrite`** doesn't emit hreflang. Look in `app/design/frontend/ultimo/default/template/page/html/head.phtml` (or wherever the theme injects `<head>`) — if there's no hreflang loop there, the cluster is missing entirely on every page.
- **Canonical pointing cross-store**: if `https://www.tertiarycourses.com.my/...` canonicals to `https://www.tertiaryinfotech.edu.sg/...`, the MY indexing is suppressed. Check `web/seo/use_canonical_for_products = 1` per store + that the canonical tag uses the **current store's** base_url, not the default.
- **Wrong country code**: `en-MY` is correct, `ms-MY` is correct, `en-UK` is invalid (use `en-GB`). For SG use `en-SG`. For Ghana `en-GH`. For Nigeria `en-NG`.
- **Catalog URL key differs per store**: if a course has different `url_key` per store, the cluster has 4 different URLs and must point at each. If they're the same, simpler.

**Action — if hreflang is missing entirely:** propose a `head.phtml` snippet that iterates `Mage::app()->getStores()` and emits one `<link rel="alternate" hreflang="...">` per store, ending with `x-default` pointing at SG.

## 2. Indexability & crawl-budget waste

Magento 1's catalog has notorious crawl traps. Check each:

| Trap | Diagnostic | Fix |
|------|------------|-----|
| Layered nav `?cat=`, `?price=`, `?manufacturer=` | `site:tertiarycourses.com.my inurl:?cat=` in Google | Add `noindex,follow` on filtered URLs via theme override, OR robots.txt `Disallow: /*?` (but check sitemap doesn't include them) |
| Sort/order `?dir=asc&order=name` | Same | `noindex,follow` |
| `?___store=` switcher links | View page source on home, grep `___store` | Add `rel="nofollow"` to store-switch links; they shouldn't appear in user-visible content anyway |
| `?___from_store=` | After clicking store switch | Same |
| `/customer/account/`, `/checkout/`, `/wishlist/` | robots.txt | Should be `Disallow:` — check `robots.txt` |
| Tag pages | `site:... inurl:/tag/` | OpenMage tag module — review per-store whether tag pages have any organic value; typically `noindex,follow` |
| Admin URL `/tigerdragon/` | `site:... inurl:/tigerdragon` | MUST be `Disallow:` in robots.txt and `noindex` via `X-Robots-Tag` header. Confirm. |

```bash
# Crawl a few sample URLs and check X-Robots-Tag + meta robots
for u in /tigerdragon/ /customer/account/ /catalogsearch/result/?q=python /?cat=42; do
  echo "=== $u ==="
  curl -sI "https://www.tertiarycourses.com.my$u" | grep -iE 'x-robots|location|cache-control'
done
```

**Sitemap**: Magento's built-in (`Catalog → Google Sitemap`) generates `/sitemap.xml` per store. Verify:
- One sitemap per country domain at `https://<domain>/sitemap.xml`.
- It contains only canonical URLs for that store, not URLs for the SG store.
- `robots.txt` references it: `Sitemap: https://<this-domain>/sitemap.xml`.
- It excludes admin, customer, checkout.

## 3. Core Web Vitals

Run PageSpeed Insights on the canonical course URL of each country. Expect mobile LCP > 3s and INP > 300ms before any work — Ultimo + Prototype.js is heavy.

**Quick wins on this stack:**
- **Merge & minify JS/CSS** via Magento admin (System → Configuration → Developer → JavaScript Settings → Merge=Yes, Minify=Yes). Free, no code. Do for all 4 stores.
- **Image lazy loading** — Ultimo doesn't lazy-load by default. Add `loading="lazy"` to product gallery + category listing image templates in the theme.
- **GH/NG latency**: server is in SG. Put Cloudflare in front (Coolify supports proxy mode). Even cache-passthrough mode cuts TTFB by 200-400ms in West Africa. Coolify subdomain config is in `.htaccess` — no app changes.
- **HTML output cache**: Magento 1 has full_page_cache. Confirm `Cache Storage Management → Full Page Cache` is enabled per store. (Note: clicking the menu was broken pre-migration 065 — that's now fixed.)

**INP**: the worst offender is usually the Prototype.js stack loading synchronously. Defer Prototype.js below the fold is risky — many Magento 1 extensions depend on `Prototype` being globally available before DOMContentLoaded. Don't propose deferring without testing.

## 4. On-page — course pages

Per-store check on a single course:

- **Title**: should be `<Course> in <City> | Tertiary Courses` (60 char max). The country variant should differ — "Python Course in Singapore" vs "Python Course in Kuala Lumpur" — to avoid cross-country dupe.
- **H1**: ditto, should match title intent.
- **Meta description**: 150-160 char, includes country and subsidy hook ("SkillsFuture eligible" for SG, "HRDC claimable" for MY).
- **Schema.org `Course`**: every course page should have JSON-LD with `Course`, `provider` (Tertiary Courses), `hasCourseInstance` (next class date), `offers.price` (in local currency). Check `<head>` for `<script type="application/ld+json">`. Use Rich Results Test (https://search.google.com/test/rich-results) to validate — `curl` strips `<script>` tags so you cannot detect JSON-LD with curl alone.
- **Internal linking**: every course should be reachable from a category page within 2 clicks of homepage. Check via Screaming Frog crawl depth.

**Schema detection note:** `curl` and `WebFetch` cannot reliably see JSON-LD because they strip `<script>`. Use the Rich Results Test, or in the browser run `document.querySelectorAll('script[type="application/ld+json"]')`.

## 5. Country-specific signals

| Country | Signal to verify |
|---------|------------------|
| SG | `en-SG` hreflang; SGD prices; SG address in footer; SkillsFuture branding; Google Business Profile at SG address; `+65` phone in footer |
| MY | `en-MY` (and optionally `ms-MY`); MYR prices; KL/PJ address; HRDC branding; `+60` phone |
| GH | `en-GH`; GHS prices; Accra address; `+233` phone |
| NG | `en-NG`; NGN prices; Lagos/Abuja address; `+234` phone |

These are E-E-A-T trustworthiness signals for local rankings. Missing local NAP (Name/Address/Phone) is the single biggest signal Google uses to *not* rank a country variant.

## 6. Tooling

- **Google Search Console** — one property per country domain (4 properties total). Verify all four are claimed and the Sitemaps tab shows the sitemap.
- **Rich Results Test** — for schema (curl can't see JSON-LD).
- **PageSpeed Insights** — Mobile + Desktop per country URL.
- **Screaming Frog** (if licensed) — crawl with custom robots, set "JavaScript rendering" on, export hreflang errors. This is the one paid tool worth running.
- **Magento admin → Catalog → URL Rewrite Management** — find rewrite chains and 302s that should be 301s.

## Output format

```
EXECUTIVE SUMMARY
- Top 3 issues blocking organic growth on this site
- Quick wins (config-only, no code) the user can apply today

CROSS-STORE / HREFLANG
- Issue (Severity High/Med/Low): Evidence, Impact, Fix

INDEXABILITY
- ... same shape

CORE WEB VITALS
- ... same shape, with PageSpeed scores per country

ON-PAGE & SCHEMA
- ... same shape, with sample course URL evidence

PRIORITISED ACTION PLAN
1. Blocking / critical (broken indexation, etc.) — owner + ETA
2. High impact (CWV, schema, hreflang fixes)
3. Quick wins (config toggles)
4. Long-term (content strategy, link building)
```

## Anti-patterns — don't recommend

- Don't recommend rel=canonical from country domain to SG. That suppresses the country domain. Self-canonical per store.
- Don't recommend `noindex` on country stores to "fix duplicate content". Hreflang is the right tool for that.
- Don't recommend disabling Magento URL rewrites. The whole site depends on them.
- Don't recommend pushing PageSpeed score above 70 on mobile without acknowledging that Magento 1 + Ultimo has a structural ceiling around 60-75 without a CDN + heavy theme work.
- Don't suggest the user buy SEMrush/Ahrefs without first checking what they already have access to.
