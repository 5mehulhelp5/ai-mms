---
name: apache-rewrite-e-flag-redirect-prefix
description: "env vars set via RewriteRule [E=name:1] become REDIRECT_name after the front-controller rewrite to /index.php; mod_headers env= check must use the prefixed name"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 94ce57ff-75b1-4afa-9d79-792d4f24649b
---

When setting an Apache env var via `RewriteRule ^foo - [E=name:1]` in
`.htaccess` and reading it later in `Header always set X env=name`, the
header will NOT fire if the request is subsequently rewritten internally
(e.g. Magento's `RewriteRule .* index.php [L]` front controller).
mod_rewrite prefixes env vars with `REDIRECT_` on each internal subrequest,
so by the time mod_headers runs at response time, the var is
`REDIRECT_name`, not `name`.

**Why:** Spent ~30 minutes debugging "Indexed, though blocked by robots.txt"
fix where `Header always set X-Robots-Tag ... env=noindex_url` silently did
nothing. Debug header `%{noindex_url}e` returned `(null)` while
`%{REDIRECT_noindex_url}e` returned `1`. Same trap applies to any [E=] flag
set before the front-controller rewrite.

**How to apply:** When adding env-conditioned headers in this repo's
`.htaccess`, either:
- Use `env=REDIRECT_<name>` in the Header directive (single internal
  rewrite is the common case — see `.htaccess` `X-Robots-Tag` setup for
  /directory/currency/switch/ and /catalog/seo_sitemap/), or
- Set the env unconditionally with `SetEnvIf` against the original
  request line BEFORE any rewrite happens (only works if you can match
  on a header that isn't touched by mod_rewrite — `Request_URI` in
  .htaccess context evaluates AFTER per-dir rewriting, so it sees
  /index.php and never matches the original URL).

The companion gotcha: `SetEnvIfExpr "%{REQUEST_URI} =~ ..."` in .htaccess
also evaluates against the rewritten /index.php, so don't try to use that
either — go through the [E=] + REDIRECT_ path.
