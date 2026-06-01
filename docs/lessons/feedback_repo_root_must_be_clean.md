---
name: feedback-repo-root-must-be-clean
description: "Never leave screenshots, scratch scripts, or temp artifacts in the repo root — clean up the moment work is done"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: a52d9030-edfc-4ed7-bf91-fab26ec9bc30
---

Never leave screenshots, scratch PHP scripts, sitemap duplicates, `tmp/` dirs, `.DS_Store`, or any other temp artifacts sitting in the repo root. Clean them up at the end of any task that produced them.

**Why:** The user explicitly said "the code base must always be clean and lightweight." On 2026-05-28 the root had accumulated 14 Playwright PNG screenshots (phase0-*, phase2-*, phase4-*, mobile-options-fix.png, tc-homepage-up.png ≈ 12MB total), a `tmp/` dir with old backups, a one-off `reset_admin_password.php` in the webroot (real security risk — if it ever shipped, anyone hitting the URL could reset the admin password), 7 duplicate `sitemap_*.xml` files (underscore variant of the canonical `sitemap-*.xml` hyphen versions), and a stale `commit-version.txt` superseded by the Docker-built `/version.txt`.

**How to apply:**
- When taking screenshots via Playwright/MCP for verification, save to `/tmp/` or `.playwright-mcp/` (already gitignored), never repo root. Delete them when done.
- Never write a one-off PHP script (password reset, debug dump, data fix) into the webroot — put it under `scripts/local-dev/` or `scripts/maintenance/` per CLAUDE.md convention, and delete after use if truly one-shot.
- The canonical per-country sitemap filenames are `sitemap-<country>.xml` (hyphen). If the generator ever emits `sitemap_<country>.xml` (underscore), that's a bug — fix the generator, don't ship both.
- Before any `git push`, glance at `ls` of the repo root and `git status --short` for `??` lines. Anything that isn't source, config, or a tracked asset gets removed first.
