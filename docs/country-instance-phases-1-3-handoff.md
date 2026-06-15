# Country Instance Deployment — Phases 1–6 Handoff

**Status:** Phases 1–5 complete and locally verified. Phase 6 (Ghana Coolify) in progress.
**Tested with:** Ghana (GH) local stack on port 8082.
**Next:** Phase 6 — Stand up Ghana on Coolify at `http://2.24.131.228:8000/`, run runbook, validate.

This document records exactly what was built, how it works, and how to replicate it
for each new country. Read alongside the implementation plan at
`docs/country-instance-deployment-implementation-plan.md` and the standalone
operator runbook at `docs/country-instance-runbook.md`.

---

## Phase 1 — Production compose stack

### What was built

`compose.coolify.yml` — the Coolify-ready Docker Compose file that every country
instance uses as its build pack. It bundles **web + MySQL 5.7 + Redis** into a
single Coolify resource, mirroring the shape that SG-AI-LMS-TMS uses today.

### Key design choices

| Decision | What we did | Why |
|----------|-------------|-----|
| Web + DB + Redis in one file | `compose.coolify.yml` defines all three services | SG's DB is managed/external; country instances own their DB |
| No host bind-mounts | Only named volumes (`mysql_data`, `media`) | Bind mounts are dev-only; Coolify manages volumes |
| `media/` as a named volume | `- media:/var/www/html/media` | Country instances use local-disk media (no R2). ALL images live here — synced C-covers, local covers, uploads |
| Seed mounted at initdb | `./seed/country-base.sql.gz:/docker-entrypoint-initdb.d/...` | MySQL auto-imports `initdb.d/*.sql.gz` only on an empty volume — safe no-op on restarts |
| `expose: "80"` not `ports` | Coolify's Traefik handles routing | No port conflicts between country instances on the same Coolify host |
| `restart: unless-stopped` on all services | All three services | Survives container restarts without Coolify re-triggering a deploy |
| All secrets via env, never hardcoded | `${VAR:-}` substitution throughout | Secrets live in Coolify's Environment Variables panel |

### Files created

- **`compose.coolify.yml`** — the production compose stack

### How to replicate for a new country

1. No file changes needed — `compose.coolify.yml` is country-agnostic.
2. In Coolify: create a **Docker Compose** application, point it at the repo + `main`,
   select `compose.coolify.yml` as the compose file.
3. Set the env vars listed in §Env contract below.
4. Attach persistent volumes: `mysql_data`, `media`.

---

## Phase 2 — Mode plumbing + `local.xml`-from-env

### What was built

Three pieces that together let the app boot from env vars alone (no committed
`local.xml`) and switch behaviour between `sg` and `country` modes.

### 2a — `docker/generate-local-xml.sh`

A PHP-in-bash script that writes `app/etc/local.xml` at container startup from
env vars. Called by `entrypoint.sh` when `MMS_MODE=country`.

**Crypt key resolution order:**
1. `MMS_CRYPT_KEY` env var (explicit, preferred for stable Coolify deployments)
2. `/var/www/html/media/.crypt_key` persisted on the `media` volume (survives deploys)
3. Generate new random key, write to `media/.crypt_key`, print a warning with the
   value so you can pin it in Coolify env

**What the generated `local.xml` contains:**
- DB connection pointing at `db` (the compose service name)
- `session_save=db` (base; Redis session block also included — see 2b)
- Redis session block (`redis_session`) pointing at `redis:6379`, db 1
- Redis cache block (`cache` → `Cm_Cache_Backend_Redis`) pointing at `redis:6379`, db 0
- Admin frontName from `MMS_ADMIN_FRONTNAME` env
- Empty `mmd_marketing` block (API keys are set separately via env)

**Files created:**
- **`docker/generate-local-xml.sh`**

### 2b — `docker/entrypoint.sh` — country mode boot sequence

Two lines added at the top of the migration block, gated on `MMS_MODE=country`:

```bash
if [ "${MMS_MODE:-}" = "country" ]; then
    # 1. Re-enable Cm_RedisSession (Dockerfile sed disables it for SG which has no Redis)
    sed -i 's|<active>false</active>|<active>true</active>|' \
        /var/www/html/app/etc/modules/Cm_RedisSession.xml

    # 2. Delete the SG-specific local.xml baked into the image, regenerate from env
    rm -f "$LOCAL_XML"
    bash /var/www/html/docker/generate-local-xml.sh
fi
```

**Why:** The Dockerfile bakes SG's `local.xml` (host=`db_mysql`, no Redis) into the
image and also `sed`-disables `Cm_RedisSession.xml`. Country instances need the
opposite — Redis enabled, `local.xml` pointing at `db` with Redis blocks. The
entrypoint undoes both at runtime.

**Files modified:**
- **`docker/entrypoint.sh`**

### 2c — SKU guardrail (`CoursesaveController.php`)

When `MMS_MODE=country`, the "Save Course" controller rejects any attempt to
**create or rename** a course with a `C…` or `TGS-…` SKU. These prefixes are
reserved for SG-synced courses; a locally-created one would be silently clobbered
on the next import.

```php
if (strtolower((string) getenv('MMS_MODE')) === 'country') {
    $_proposedSku = $req->getParam('course_code') ?: $req->getParam('general_course_code');
    if ($_proposedSku !== null && $_proposedSku !== '') {
        $_proposedUpper = strtoupper(ltrim((string) $_proposedSku));
        $_isReserved = substr($_proposedUpper, 0, 1) === 'C'
                    || substr($_proposedUpper, 0, 4) === 'TGS-';
        $_isChanging  = (string) $_proposedSku !== (string) $product->getSku();
        if ($_isReserved && $_isChanging) {
            throw new Exception('"C…" and "TGS-…" course codes are reserved ...');
        }
    }
}
```

The check only fires when the proposed SKU **differs** from the current one — so
editing other fields on an already-synced C-course (which echoes the existing SKU
back) is not blocked.

**Files modified:**
- **`app/code/local/MMD/RoleManager/controllers/Adminhtml/CoursesaveController.php`**
  (block inserted after product load, before "Basic fields" section, ~line 61)

### 2d — Store switcher pill filter (`Branchscope/Helper/Data.php`)

`getCountryStorePillOptions()` returns the set of store pills for the global Store
View bar. In `country` mode, only the single relevant country store pill should show;
the full 6-country bar is SG-only.

**Files modified:**
- **`app/code/local/MMD/Branchscope/Helper/Data.php`**

### Env contract for Phase 2

| Var | Required | Example | Notes |
|-----|----------|---------|-------|
| `MMS_MODE` | Yes | `country` | Triggers the entire country boot path |
| `MMS_COUNTRY_CODE` | Yes | `GH` | Used for pill display and class_id prefix |
| `MMS_BASE_URL` | Yes | `http://localhost:8082/` | Written to `core_config_data` base URLs |
| `MMS_ADMIN_FRONTNAME` | No | `tigerdragon` | Default: `tigerdragon` |
| `MMS_CRYPT_KEY` | Recommended | 32-char hex | Generate: `php -r "echo bin2hex(random_bytes(16));"` |
| `MYSQL_HOST` | No | `db` | Default: `db` (the compose service name) |
| `MYSQL_DATABASE` | Yes | `mms_gh` | |
| `MYSQL_USER` | Yes | `magento` | |
| `MYSQL_PASSWORD` | Yes | (strong) | |

---

## Phase 3 — Seed builder + first-boot load

### What was built

A reproducible script that produces a clean bootstrap dump from an SG production
backup, and the resulting seed file that gets auto-loaded into a fresh country DB.

### 3a — `scripts/provision/build-country-seed.sh`

Takes an SG mysqldump file as input, strips all business data and secrets, and
outputs `seed/country-base.sql.gz`. Designed to be re-run whenever the migration
count grows enough that replaying from a stale seed becomes slow.

**What the script keeps (structure + reference data):**
- All table schemas (DDL)
- `eav_*` (attribute definitions, sets, groups, option values)
- `directory_*` (countries, regions, currencies)
- `tax_class`, `tax_rate`, `tax_rule`
- `core_store`, `core_store_group`, `core_website` (the full 6-store topology)
- `core_config_data` — non-secret rows only (theme, locale, payment config, etc.)
- `admin_user` — the single seeded admin account (password rotated after deploy)
- `admin_role`, `admin_rule` — default role structure
- `schema_migrations` — so `apply.php` doesn't re-run already-seeded migrations
- CMS pages/blocks needed for theme

**What the script strips / truncates:**
- All product, category, catalog data
- All customer, order, quote data
- `course_runs`, `course_run_enrolments`, `courses_trainers`
- `admin_user` rows beyond the seed account; `mmd_user_role_map`
- `catalogsearch_*`, `log_*`, `report_*`, `dataflow_*`

**What the script sanitizes (secrets removed from `core_config_data`):**
- SMTP credentials (`smtppro/%`)
- OAuth tokens (`%oauth%`, `%gmail%`, `%client_secret%`)
- API keys (`%api_key%`, `courses/general/%`)
- Trainer import config (`mmd/trainer_import/%`)
- Payment gateway credentials (`payment/%/(login|password|signature|token)`)
- Base URLs (reset to placeholder; entrypoint rewrites them at boot)

**Assertions (script fails if any trip):**
- 0 rows in every business table
- 0 `core_config_data` rows matching secret patterns
- No known SG secret values in the dump (grep against a denylist)
- `schema_migrations` count == `migrations/*.sql` file count

**Files created:**
- **`scripts/provision/build-country-seed.sh`**
- **`seed/country-base.sql.gz`** (output, committed via `.gitignore` exception `!seed/country-base.sql.gz`)

### 3b — First-boot load mechanism

The seed is mounted into the MySQL container at
`/docker-entrypoint-initdb.d/country-base.sql.gz` (line in `compose.coolify.yml`):

```yaml
volumes:
  - ./seed/country-base.sql.gz:/docker-entrypoint-initdb.d/country-base.sql.gz:ro
```

MySQL's official image auto-imports everything in `/docker-entrypoint-initdb.d/`
**only on an empty `mysql_data` volume**. On subsequent starts the import is skipped
silently — so the mount is safe to leave permanently.

After the seed loads, `apply.php` runs and tops up any migrations added to `main`
after the seed was built. The `schema_migrations` ledger in the seed prevents
re-running the migrations already captured there.

### How to rebuild the seed

Run against an SG dump when the migration count has grown significantly:

```bash
./scripts/provision/build-country-seed.sh /path/to/sg-production-dump.sql
# output: seed/country-base.sql.gz
# All assertions must pass before committing
git add seed/country-base.sql.gz
git commit -m "chore(seed): rebuild country-base seed (NNN migrations)"
```

---

## Local testing — running a country stack

Use a separate `.env.<country>` file and project name to avoid colliding with the
SG dev stack.

### Example: Ghana on port 8082

```bash
# .env.gh (gitignored)
MMS_COUNTRY_CODE=GH
MMS_BASE_URL=http://localhost:8082/
MMS_ADMIN_FRONTNAME=tigerdragon
MMS_CRYPT_KEY=<32-char hex>
MYSQL_ROOT_PASSWORD=gh_root_local
MYSQL_DATABASE=mms_gh
MYSQL_USER=magento
MYSQL_PASSWORD=magento_gh_local
```

Local-test override (`compose.coolify.local-test.yml`, gitignored):

```yaml
services:
  web:
    ports:
      - "8082:80"
    environment:
      - MMS_MODE=country
      - LOCAL_DB_MODE=1          # rewrites base_url to localhost:8082
      - SKIP_MIGRATIONS=0        # run migrations on first boot
```

Start/stop:

```bash
# Start GH stack
docker compose -f compose.coolify.yml -f compose.coolify.local-test.yml \
  --env-file .env.gh -p ai-mms-gh up -d

# Stop GH stack (stop SG stack FIRST if both are running — they share the bridge network driver)
docker compose -p ai-mms-sg down
docker compose -f compose.coolify.yml -f compose.coolify.local-test.yml \
  --env-file .env.gh -p ai-mms-gh down
```

Fresh-volume test (wipes the GH DB — seeds again on next up):

```bash
docker compose -f compose.coolify.yml -f compose.coolify.local-test.yml \
  --env-file .env.gh -p ai-mms-gh down -v
docker compose -f compose.coolify.yml -f compose.coolify.local-test.yml \
  --env-file .env.gh -p ai-mms-gh up -d
```

### Verifying Phase 3 seed assertions locally

After `up -d` and the DB has finished importing:

```bash
CONTAINER=$(docker ps --filter "name=ai-mms-gh-db" --format "{{.Names}}" | head -1)

# 0 product rows
docker exec "$CONTAINER" mysql -umagento -pmagento_gh_local mms_gh \
  -e "SELECT COUNT(*) FROM catalog_product_entity;"

# 0 customer rows
docker exec "$CONTAINER" mysql -umagento -pmagento_gh_local mms_gh \
  -e "SELECT COUNT(*) FROM customer_entity;"

# 0 order rows
docker exec "$CONTAINER" mysql -umagento -pmagento_gh_local mms_gh \
  -e "SELECT COUNT(*) FROM sales_flat_order;"

# 0 secret config rows (should return empty)
docker exec "$CONTAINER" mysql -umagento -pmagento_gh_local mms_gh \
  -e "SELECT path FROM core_config_data WHERE path LIKE '%api_key%' OR path LIKE '%oauth%' OR path LIKE 'smtppro/%';"
```

---

## .gitignore additions

```gitignore
# Country instance local-test overrides (never commit)
compose.coolify.local-test.yml
.env.gh
.env.my
.env.ng
.env.bt
.env.in

# Seed IS committed (contains no secrets/data)
!seed/country-base.sql.gz
```

---

## Known gotchas

| Symptom | Cause | Fix |
|---------|-------|-----|
| `site can't be reached` after `--build` | `var/session`, `var/log`, `var/tmp`, `var/report` dirs don't exist (selective bind-mounts mean `var/` comes from image which only has `.htaccess`) | Add tmpfs mounts for those dirs in `docker-compose.yml` (local dev only) |
| Admin login hangs / 503 | Non-MMD `app/code/local/` dirs (Infortis, Aschroder, etc.) are APFS-phantom in the macOS Docker build context — Docker VirtioFS reads them as 0-byte | Bind-mount those dirs from host in `docker-compose.yml`; restore from a fresh clone if needed |
| GH stack: `Network ... is still in use` on down | Stale SG containers attached to the same bridge network | Shut down SG stack first, then GH |
| `--env-file` required | Without it, Compose uses `.env` (SG credentials) for the GH stack | Always pass `--env-file .env.gh` to every GH compose command |
| Crypt key changes on redeploy | `media/.crypt_key` not persisted, or `MMS_CRYPT_KEY` not pinned | Pin the key in Coolify env after first boot (script prints the value) |
| `apply.php` fails: `error 1366 Incorrect string value` | Migrations that pull data from legacy tables may contain invalid UTF-8 bytes | Filter with `WHERE LENGTH(col) = CHAR_LENGTH(col)`; see CLAUDE.md "Pre-push verification" |

---

## Phase 4 — Course sync

**Status:** Complete and locally tested (2026-06-12).

### What was built

Four pieces that together implement the SG → country C-course sync, gated by `MMS_MODE`.

### 4a — SG export endpoint (`MMD_Courses_Api_Sync_ExportController`)

**File:** `app/code/local/MMD/Courses/controllers/Api/Sync/ExportController.php`

- Route: `GET /courses/api_sync_export` (served by the existing `courses` frontend router — no config.xml change needed)
- Auth: `X-API-Key` header must match `mmd/course_sync/api_key` in `core_config_data`
- Scope: products with `sku LIKE 'C%'` only; TGS- excluded
- Pagination: `?page=&page_size=` (default 50, max 100)
- Response per course: `sku`, `type_id`, `attribute_set` (name), `status`, `visibility`, `attributes` (select/multiselect resolved to **labels**, not IDs), `categories` (url_key paths), `custom_options` (by title), `badges`, `course_image_url`, `updated_at`
- **Mode guard:** returns 403 when `MMS_MODE=country` — export is SG-only
- **Cross-install safety:** zero numeric IDs exported; everything keyed by stable strings

### 4b — Country importer (`MMD_RoleManager_Model_CourseSyncService`)

**File:** `app/code/local/MMD/RoleManager/Model/CourseSyncService.php`

- Paginates through the SG export endpoint; upserts each C-course by SKU
- **Safety invariant:** skips any product whose SKU doesn't start with `C` — can never clobber local courses
- **Price rule (P1):** sets `price` / `special_price` only when **creating** a new product; skips price on updates so the country owns it after first import
- **Media (P9a):** fetches image bytes from SG via the sync API, writes to the instance's own `media/` volume via the `LocalDisk` driver, stores an instance-relative `course_image_url` — never an SG/R2 URL
- **Retirement:** if a C-course disappears from the SG export, its local product is **disabled** (status=2), never deleted
- After each run: reindexes `catalog_url`, flat catalog/category, search; writes a log row to `mmd_course_sync_log`

### 4c — Fail-safe cron (`MMD_RoleManager_Model_Cron_CourseSync`)

**File:** `app/code/local/MMD/RoleManager/Model/Cron/CourseSync.php`
**Config:** `app/code/local/MMD/RoleManager/etc/config.xml` (cron schedule: `0 3 * * *` — 03:00 SGT)

- Self-skips when `MMS_MODE != country` or `mmd/course_sync/auto_enabled` is absent/0
- In-flight lock via `mmd/course_sync/running` to prevent overlapping runs
- Fail-safe OFF by default — toggled from the Courses dashboard UI pill

### 4d — Admin controller + UI (`CoursesyncController` / `add-course-btn.phtml`)

**Files:**
- `app/code/local/MMD/RoleManager/controllers/Adminhtml/CoursesyncController.php`
- `app/design/adminhtml/default/default/template/rolemanager/add-course-btn.phtml`

- `runAction`: triggers a manual sync run; returns JSON with fetched/created/updated/disabled/skipped/errors counts
- `statusAction`: returns last run summary from `mmd_course_sync_log`
- `toggleAutoAction`: flips `mmd/course_sync/auto_enabled` in `core_config_data`
- UI: "Sync Courses from SG" button + last-run status card + auto-sync toggle pill on the Courses dashboard (visible in `country` mode only)

### 4e — Local-disk media driver (`MMD_CourseImage_Helper_LocalDisk`)

**File:** `app/code/local/MMD/CourseImage/Helper/LocalDisk.php`

- Used by `CourseSyncService` when `MMS_MODE=country` (SG uses R2 via `Helper/R2.php`)
- `saveFromUrl($sourceUrl, $sku)`: downloads bytes, writes to `media/course-covers/<sku>.jpg`, returns the instance-relative public URL
- `contentHash($sku)`: MD5 of the stored file — importer uses this to skip unchanged images on re-sync

### 4f — Migration (`migrations/202-course-sync-log.sql`)

Creates the `mmd_course_sync_log` table:

| Column | Type | Notes |
|--------|------|-------|
| `log_id` | INT PK AUTO | |
| `run_at` | DATETIME | start time |
| `duration_s` | INT | seconds |
| `fetched` | INT | total courses from SG |
| `created` | INT | new products inserted |
| `updated` | INT | existing products updated |
| `disabled` | INT | retired C-courses disabled |
| `skipped` | INT | unchanged (hash match) |
| `errors` | INT | |
| `error_detail` | TEXT | last error message |
| `triggered_by` | VARCHAR(20) | `manual` or `cron` |

### Env vars added in Phase 4

| Var | Where set | Notes |
|-----|-----------|-------|
| `SG_SYNC_URL` | Country Coolify | SG base URL; blank = sync disabled |
| `SG_SYNC_API_KEY` | Both SG + country Coolify | Shared secret; must match on both sides |

The SG side reads `SG_SYNC_API_KEY` from env and writes it to `core_config_data['mmd/course_sync/api_key']` at boot (via the entrypoint). Country side sends it as the `X-API-Key` header.

---

## Phase 5 — Package + runbook

**Status:** Complete (2026-06-12).

### What was built

Two operator-facing documents and one template file that make Phase 6 (and all future country deployments) self-service.

### 5a — Standalone operator runbook

**File:** `docs/country-instance-runbook.md`

Covers: pre-flight checklist, seed rebuild, Coolify application creation, env var table, persistent volume setup, GitHub webhook wiring, first deploy steps, post-deploy setup (pin crypt key, rotate seed admin, create users, run first sync, enable cron), validation checklist (fresh-volume boot, no-secrets audit, no-data audit, sync correctness, safety invariant, mode isolation, auto-deploy), fleet rollout table for MY/NG/BT/IN, and a troubleshooting table.

### 5b — Env var template

**File:** `.env.country.example`

Complete annotated template for all env vars required/optional on a country Coolify deployment. Includes generation commands for crypt key and passwords, and clearly marks `R2_*` as unused in country mode.

### Store bar fixes (also landed in Phase 5)

Two store-bar UI fixes that ensure country instances show only **SG + own country** pills rather than all 6:

| File | What changed |
|------|-------------|
| `app/code/local/MMD/Branchscope/Helper/Data.php` | `getCountryStorePillOptions()` filters to `allowed = [1, countryStoreId]` when `MMS_MODE=country` |
| `app/design/adminhtml/default/default/template/dashboard/index.phtml` | `$_pageStoreToCountry` filtered by same env-var logic for the Edit Course inline store bar |

### Delete Course button fix (also landed in Phase 5)

`CoursesaveController::deleteCourseAction()` — POST-only JSON endpoint that bypasses Magento URL-key CSRF for the delete button. Also blocks deletion of C/TGS- prefix courses in country mode (they'd be restored on next sync). The `devDeleteCourse()` JS in `dashboard/index.phtml` was updated to use `fetch()` AJAX instead of a form submit.

---

## Phase 6 — Ghana Coolify deployment

**Status:** Not started. Ready to proceed.

### Pre-conditions (all met)

- [x] `compose.coolify.yml` committed and on `main`
- [x] `seed/country-base.sql.gz` committed and on `main`
- [x] `docs/country-instance-runbook.md` written
- [x] Ghana Coolify server: `http://2.24.131.228:8000/`
- [x] Env vars generated (see below)

### Generated env values for Ghana production

These were generated on 2026-06-12. Store them securely before use.

```
MMS_MODE=country
MMS_COUNTRY_CODE=GH
MMS_BASE_URL=https://ai-mms-gh.tertiaryinfo.tech/    ← confirm this domain
MMS_ADMIN_FRONTNAME=tigerdragon
MMS_CRYPT_KEY=fda5278884d146b413ced20788e6085e

MYSQL_ROOT_PASSWORD=0af96e1c184e485ea0169228
MYSQL_DATABASE=mms_gh
MYSQL_USER=magento
MYSQL_PASSWORD=d807840fc1b2145df3b674bd

SG_SYNC_URL=https://ai-mms.tertiaryinfo.tech/
SG_SYNC_API_KEY=0f73be29f7b72b5881ce13aa69c2f8a5aebf4f24d86de249
```

**Also set on SG Coolify** (so the export endpoint accepts the key):
```
SG_SYNC_API_KEY=0f73be29f7b72b5881ce13aa69c2f8a5aebf4f24d86de249
```

Leave all `R2_*`, `TURNSTILE_*`, `GOOGLE_OAUTH_*`, and `SMTPPRO_*` blank for now.

### Steps remaining

Follow `docs/country-instance-runbook.md` §3–§5 in order:

1. Log into `http://2.24.131.228:8000/` → New Resource → **Docker Compose**
2. Source: GitHub → `ai-mms` repo → branch `main` → compose file `compose.coolify.yml`
3. Paste the env vars above into the Environment Variables panel
4. Attach persistent volumes: `mysql_data` → `/var/lib/mysql`, `media` → `/var/www/html/media`
5. Configure GitHub webhook (Coolify Webhooks tab → copy URL → add to GitHub repo Settings → Webhooks)
6. Point DNS for the Ghana domain at `2.24.131.228`; issue TLS in Coolify
7. **First deploy** — watch build logs for `generate-local-xml` and `apply.php` output
8. Pin `MMS_CRYPT_KEY` from logs if it printed a warning (already set above so this should be a no-op)
9. Rotate the seed admin password immediately
10. Admin → Manage Courses → **Sync Courses from SG** → verify C-catalog appears with images
11. Run the validation checklist from the runbook §5

### Fleet rollout after Ghana

Once Ghana is validated, repeat for: MY → NG → BT → IN (each needs its own `MMS_COUNTRY_CODE`, `MYSQL_DATABASE`, domain, and freshly generated `MMS_CRYPT_KEY` + DB passwords).
