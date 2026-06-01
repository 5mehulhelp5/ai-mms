---
name: Sync remote DB via migration scripts, not dumps
description: For this ai-mms project, any remote DB change must go through a SQL migration script — never propose mysqldump/restore or direct sync
type: feedback
originSessionId: 6ee91dba-c807-4b04-8c7d-d847f2c61521
---
When local and remote databases diverge in this project, always write a SQL migration script (in `migrations/` or `scripts/local-dev/` as appropriate) to bring them into line. Never propose dump-and-restore, direct replication, or other whole-DB sync methods.

**Why:** The user established this convention previously — migrations are reviewable, idempotent where possible, versionable in git, and avoid accidentally overwriting prod data that the local copy doesn't have. A dump-and-restore loses this safety.

**How to apply:** When the user reports local/remote DB drift or asks to "sync" databases, skip straight to drafting the migration SQL. Ask what the *target state* should be (what fields/rows differ and which side is canonical), then write an idempotent script that applies just those changes. Place under `migrations/` for production-bound scripts or `scripts/local-dev/` for local-only fixups — the repo already uses this split.
