---
name: seo-hreflang-per-store-sitemap
description: Cross-store SEO needs both hreflang in head.phtml AND per-host sitemap rewrites; either alone leaves Google treating MY/NG/GH as SG duplicates
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 3aa15a42-b869-46bc-ad14-02fc5f5edbdd
---

When working on multi-country SEO for the four Tertiary Courses storefronts
(SG/MY/GH/NG), **always check three things together** — fixing only one
masks the other two as "still broken":

1. `app/design/frontend/ultimo/default/template/page/html/head.phtml` must
   emit a 4-entry hreflang cluster + x-default, resolving per-store paths
   from `core_url_rewrite` so different per-store url_keys
   (`-malaysia.html`, `-in-ghana.html`) link to each other.
2. `.htaccess` must rewrite `/sitemap.xml` per host to its matching file
   (`sitemap_singapore.xml`, `sitemap_malaysia.xml`, etc.). Without this,
   Magento's sitemap cron last-write-wins and every country domain serves
   the same SG sitemap.
3. Per-store sitemap rows must exist in the `sitemap` table (see
   `migrations/163-per-store-sitemaps.sql`) AND the files must actually
   exist on disk — the daily cron generates them at 03:00 SGT, but on
   first deploy run `scripts/seo/generate-sitemaps.php` once to create
   them immediately.

**Why:** GSC May 2026 showed 9.84K not-indexed vs 1.56K indexed. The dominant
bucket was "Crawled - currently not indexed" (6,450) — caused by missing
hreflang signals across stores. "Page with redirect" (1,227) was caused
by MY/NG/GH `sitemap.xml` serving SG URLs (cross-domain claims).

**How to apply:** Before declaring any cross-store SEO change done, verify:
```bash
# hreflang cluster on a product (should show 4 hreflang + x-default + canonical)
curl -sLS https://www.tertiarycourses.com.my/python-programming-malaysia.html \
  | grep -iE 'hreflang|rel="canonical"'

# each host's sitemap is its own (must NOT all show .com.sg)
for d in sg my ng gh; do
  curl -sL https://www.tertiarycourses.com.$d/sitemap.xml \
    | grep -oE '<loc>[^<]+</loc>' | head -1
done
```

If either check shows wrong values after deploy, the production build is
serving stale cache or migration 163 hasn't run — `docker exec` the
container and inspect `/var/www/html/sitemap_*.xml` directly.

Related: [[flat-catalog-reindex]] (sitemap generator reads the flat catalog,
so reindex must run before regenerating sitemaps after a category url_key
change).
