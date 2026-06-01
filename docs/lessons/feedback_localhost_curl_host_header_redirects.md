---
name: localhost-curl-host-header-redirects-to-prod
description: "Curling localhost:8080 with -L and Host header for a country domain silently follows a 301 to https production and reads the LIVE site, not local. Drop the Host header (or skip -L) when verifying local changes."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 9a95c018-7aae-455a-9f8a-d2c8fbeed8ce
---

When testing storefront changes on the local container, do NOT do this:

```bash
curl -sS -L "http://localhost:8080/some/path.html" -H 'Host: tertiarycourses.com.sg' -o /tmp/out.html
```

Apache (or .htaccess) returns a 301 to `https://www.tertiarycourses.com.sg/some/path.html` for Host-header requests on port 80, and `curl -L` follows the redirect to the **live production HTTPS site**. You end up grepping the production HTML and concluding your local edits "didn't take effect" — even after container restarts, opcache resets, and cache flushes.

**Why:** Localhost works fine; the trap is purely a curl-follows-redirect issue. There's no way to spot it without checking `-w "HTTP=%{http_code}\n"` (you'll see HTTP=200, but it's the prod 200, not the local one) or reading curl's verbose output for the redirect hop.

**How to apply:** When verifying local storefront changes, use ONE of:

- Drop the Host header entirely: `curl -sS "http://localhost:8080/path.html?z=$RANDOM"` — Apache serves the default vhost, which is the SG store locally.
- Drop `-L` so the redirect is not followed: `curl -sS -I -H 'Host: ...' http://localhost:8080/...` and inspect the Location header.
- Use `--resolve` to pin the hostname to 127.0.0.1: `curl --resolve www.tertiarycourses.com.sg:8080:127.0.0.1 https://www.tertiarycourses.com.sg/...` (but requires local TLS).

Lost ~20 minutes on this in 2026-05-26 chasing a phantom "my layout XML edits don't take effect" bug while in fact the edits were perfect and curl was reading production the whole time. The smoking gun came from `curl -sS -I http://localhost:8080/ -H 'Host: tertiarycourses.com.sg'` which printed `Location: https://www.tertiarycourses.com.sg/`.

Related: [[flat-catalog-reindex]] for actual storefront staleness debugging.
