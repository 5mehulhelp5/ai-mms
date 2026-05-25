---
name: HTTP 500 on every route after container restart → mod_headers dropped
description: First thing to check when localhost or live returns 500 on all routes is whether Apache mod_headers is loaded
type: feedback
originSessionId: 9e4e7fca-2797-44ac-9734-21a6583d1d94
---
If `http://localhost:8080/` (or any route) returns Apache's plain "500 Internal Server Error" page with no Magento report under `var/report/`, and `docker logs ai-mms-web-1` shows lines like:

    [core:alert] /var/www/html/.htaccess: Invalid command 'Header', perhaps misspelled or defined by a module not included in the server configuration

then Apache's `mod_headers` has been dropped from the running container. `.htaccess` uses `Header` directives at the top level, so every request 500s until it's re-enabled.

**Why:** Recurring issue. The Dockerfile runs `a2enmod headers expires deflate brotli rewrite` at build time, but some restart paths (image rebuilds without cache, Coolify volume-shadowed `/etc/apache2`) wipe the `mods-enabled/` symlinks at runtime. Fixed permanently in `docker/entrypoint.sh` (2026-05-22) by adding `a2enmod headers expires brotli rewrite deflate` to the entrypoint — a2enmod is idempotent so it's free when modules are already on.

**How to apply:**
- One-shot recovery (without rebuild): `docker exec ai-mms-web-1 a2enmod headers expires brotli rewrite deflate && docker exec ai-mms-web-1 apachectl -k graceful`
- Permanent: ensure `docker/entrypoint.sh` still contains the `a2enmod headers expires brotli rewrite deflate` line before the migration block.
- Diagnostic checklist for "site shows 500" — always run in this order:
  1. `curl -sS -o /tmp/h.html -w "HTTP=%{http_code}\n" -L http://localhost:8080/` — confirm 500
  2. `docker logs --tail 30 ai-mms-web-1` — look for `Invalid command 'Header'`
  3. If found, run the recovery one-liner above
  4. Only after ruling out (2) should you look at `var/report/` for Magento-level fatals
