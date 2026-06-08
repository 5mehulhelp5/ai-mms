# MMS Country-Specific Deployments — Implementation Plan

**Status:** Proposed (planning only — no code or deployment changes have been made)
**Audience:** The engineer who will implement this end-to-end
**Author:** Handoff plan
**Scope:** Turn the single SG-hosted multi-country MMS into a model where each non-SG country runs its **own self-contained instance** of the **same repository**, on **its own Coolify**, with its **own database**, while still being able to **pull SG's `C`-prefix course definitions** on demand.

> ⚠️ This is a planning document only. Do **not** treat any snippet here as final code. Validate every table/column/config path against the live codebase before writing the implementation — this repo changes frequently.

---

## 1. TL;DR (executive summary)

- **One repo, one `main` branch, deployed everywhere.** SG and every country instance build from the *same* repository and the *same* `main`. A push to `main` auto-redeploys **all** instances via each instance's own Coolify GitHub webhook (exactly like SG MMS and all AI-LMS-TMS instances today).
- **One codebase, two modes.** A single environment variable (`MMS_MODE = sg | country`) selects behaviour. SG behaves as today; country instances enable the course-sync importer and (eventually) hide SG-only features. No forks, no divergent branches.
- **Different containerization per deployment _type_, same image.** SG stays a Coolify **Dockerfile application** (web container only) talking to its **separate** MySQL. Each country is a Coolify **Docker Compose application** that bundles **web + MySQL (+ optional Redis)** as **one** Coolify resource (the same delta that exists between TIA-SG LMS and Chariot LMS).
- **Fresh DB, no business data.** A country instance boots from a **sanitized SG dump seed** (schema + EAV + reference config + migration ledger; **zero** products/customers/orders/classes and **zero** secrets). `apply.php` then tops up any newer migrations.
- **Catalog ownership split by SKU prefix.** `C…` courses are **owned by SG** and synced **read-only** into each country (overwrite-on-sync). Country-created courses use a **non-`C` prefix** and are **never** touched by the sync — so local catalogs can never be clobbered.
- **Course sync = definitions only.** Names/descriptions/attributes/category/custom-options/course image (bytes copied + re-hosted on the instance's own media)/SG list price (first import only). **No** schedules, classes, customers, or orders. **On-demand button + optional fail-safe-OFF daily cron.**
- **No secrets in the repo.** API keys, OAuth creds, SMTP passwords, the Magento crypt key, R2 keys — all provided **per-instance via Coolify env**, never committed, and stripped from the seed.
- **Pilot:** Ghana first, then the rest (MY/NG/BT/IN).

---

## 2. Background — how SG MMS works today (so you understand the deltas)

- **Platform:** OpenMage 1.x (Magento 1 LTS), PHP 8.2, MySQL 5.7, Apache, Docker.
- **Single install, six websites.** One DB hosts SG/MY/GH/NG/BT/IN as Magento websites/store views. `MMD_RoleManager_Helper_Data::$websiteToCountryCode` maps `1=SG, 2=MY, 3=GH, 4=NG, 5=BT, 6=IN, 7=SG`. `countryCodeForProduct()` derives a product's country **from its website assignment**, not its SKU.
- **SKU/course-code convention (live data, not just docs):**
  - `C…` — SG instructor-led **non-WSQ** courses (~498).
  - `TGS-…` — SG **WSQ/SkillsFuture** (SKU = TPGateway ref, ~299). Skipped by LMS-style crons (external system owns them).
  - `M…` — courses for the other five countries (~494 each).
  - `E…` self-paced e-learning, `P…` practice exams, `V…` exam vouchers, `K…` kids — **shared product types** assigned to all websites.
  - The only thing the code branches on is **WSQ (`TGS-`) vs not**, gated by SG store.
- **Deployment:** Coolify builds the `Dockerfile` → one web container. The **DB is separate** (managed MySQL, reached at `…:9090`). A push to `main` triggers a Coolify rebuild (GitHub webhook).
- **Migrations:** `migrations/NNN-*.sql` are **incremental** changes applied by `migrations/apply.php`, tracked in a `schema_migrations` ledger. **There is no full base schema in the repo** — migration `001` already assumes an existing Magento DB. A fresh DB therefore needs a base dump first.
- **Secrets/config:**
  - `app/etc/local.xml` — DB creds, **`crypt/key`**, admin frontName. **Gitignored**, not in the image.
  - `.env` — MySQL passwords, R2 (`R2_*`), Turnstile (`TURNSTILE_*`), Google OAuth, SMTP fallback, review API key. **Gitignored**; production sets these in Coolify's env panel.
  - Other secrets live in `core_config_data` (Gmail OAuth tokens, SMTPPro passwords — encrypted with `crypt/key`; MailerLite/Anthropic keys; the trainer-import LMS key; the Courses API keys).
- **Media:** catalog images are served from **Cloudflare R2** (absolute URLs in `course_image_url`); only small theme assets, the email logo, and bank-payment proofs are local. `.dockerignore` excludes the bulk of `media/`.
- **Existing patterns to reuse (don't reinvent):**
  - **External API auth:** `MMD_Courses` API controllers validate header `X-API-Key` against a `core_config_data` key (e.g. `courses/general/wsq_schedule_api_key`) → 401 on mismatch. See `app/code/local/MMD/Courses/controllers/Api/CoursesController.php`.
  - **Cross-system pull + fail-safe toggle + admin card:** the Trainer Import feature (`MMD_RoleManager_Model_TrainerImportService`, `Model/Cron/TrainerImport.php`, config `mmd/trainer_import/{lms_url,api_key,auto_enabled}`, a Users-page card, a `.dcf-toggle-sw` pill with `auto_enabled` absent = OFF). The course-sync importer should mirror this shape almost exactly.
  - **MySQL first-boot seed:** the local `docker-compose.override.yml` mounts `./prod-dump.sql:/docker-entrypoint-initdb.d/prod-dump.sql:ro` — MySQL's official image auto-imports `/docker-entrypoint-initdb.d/*.sql[.gz]` **only on an empty data volume**. This is the mechanism for the country seed.

---

## 3. Goals & non-goals

### Goals
1. Each non-SG country runs an independent instance of the same repo on its own Coolify, with its own DB, fully able to create its **own** courses, schedules, and classes.
2. Country instances boot **clean** (no SG business data) but with a working schema + reference config.
3. Country instances can **pull SG's `C`-prefix course definitions** on demand (and optionally on a schedule), idempotently, without ever overwriting locally-created courses.
4. **One repo / one `main`**; every instance auto-deploys on push via its own Coolify webhook.
5. **No SG secrets** ever land in the shared repo or in a country DB.
6. SG keeps working exactly as today.

### Non-goals (explicitly out of scope for v1)
- Syncing classes/schedules, customers, orders, enrolments, trainers, or any transactional data SG→country.
- Pushing country-created courses **up** to SG.
- Real-time/live catalog replication (the sync is pull, on-demand/cron — eventual consistency).
- Cross-instance SSO or shared sessions.
- Migrating SG itself to the compose/bundled-DB model (SG stays Dockerfile + separate DB).

---

## 4. Glossary

| Term | Meaning |
|---|---|
| **Instance** | One running deployment of the repo (SG, or a specific country). |
| **Mode** | `sg` or `country`, chosen by env var `MMS_MODE`. |
| **Seed** | The sanitized, data-free SQL dump that bootstraps a fresh country DB. |
| **C-course / shared course** | A course owned by SG with SKU starting `C`. Synced read-only into countries. |
| **Local course** | A course created inside a country instance, using a **non-`C`** SKU prefix. Never synced/overwritten. |
| **Sync** | The SG→country pull of C-course **definitions**. |
| **Reserved prefixes** | `C` (synced) and `TGS-` (SG WSQ, never synced). |

---

## 5. Decisions register (confirmed with the lead)

| # | Decision | Choice | Rationale |
|---|---|---|---|
| D1 | Sync payload | **Definitions only** (incl. SG list price on first import + course image bytes re-hosted locally; no classes/customers/orders) | Country owns its own scheduling/classes. |
| D2 | Sync cadence | **On-demand button + optional daily cron (fail-safe OFF)** | Mirrors the trainer-import toggle; safe by default. |
| D3 | Repo model | **One shared repo, one `main`**, env-driven mode, webhook auto-deploy to every instance | Lead wants all instances to track `main` automatically, like SG MMS / AI-LMS-TMS. |
| D4 | Codebase | **One codebase, two modes** (`MMS_MODE`) | No forks/branches to drift; features toggled by env. |
| D5 | DB bootstrap | **Sanitized SG dump seed** | Keeps schema+EAV+config+migration ledger consistent; least-effort correct base. |
| D6 | Course codes | **`C` = SG-synced (overwrite-on-sync); country-created courses use a non-`C` prefix (never synced)** | Guarantees local catalogs are never clobbered while still receiving C-course updates. |
| D7 | Pilot | **Ghana first** | Single market to prove the model before fleet rollout. |

---

## 5A. Decision points — RESOLVED (lead sign-off)

All but **P12** are decided. Implement to the **Chosen** column; the notes are the binding implementation guidance.

### Group 1 — business decisions

| # | Decision | Chosen | Implementation note |
|---|---|---|---|
| **P1** | Pricing/currency for synced `C`-courses | **(a) Sync price ONCE on first import as a default; NEVER overwrite price on later syncs** | Importer sets `price`/`special_price` **only when creating** a C-product; on update it **skips price**. Country owns price thereafter → C-courses are read-only **except price**. |
| **P2** | Local (non-`C`) SKU prefix | **(b) Per-country letter** (`GH…`, `MY…`, `NG…`, `BT…`, `IN…`) | Country-mode create-course guardrail: default/enforce the country letter; reject `C`/`TGS-`. |
| **P3** | Edit synced `C`-courses? | **(a) Lock read-only — EXCEPT the price field** (per P1) | Disable all C-course fields in country admin except `price`. |
| **P4** | SG removes a `C`-course | **(a) Disable locally (`status=2`)** | Never hard-delete (local classes/orders may reference it). |
| **P9** | Course media | **Every instance is fully self-hosted: ALL media (synced + local) lives on the instance's OWN store. The `C`-course sync COPIES the image bytes into that store. No instance ever references another instance's media at runtime.** | **DECIDED: country instances use local-disk media — NO R2 (P9a).** The importer downloads each C-course image from SG **via the sync API** (once, during sync), writes it to the instance's **own `media/` volume**, and sets `course_image_url` to an **instance-relative** URL. SG stays on R2. ⚠️ Implied: `MMD_CourseImage` (today R2-only) needs a **local-disk driver** for `country` mode. See the "Media store — DECIDED" sub-note below + §8.2 + §11. |
| **P11** | Hide SG-only features in country mode | **Hide NOW** — WSQ/`TGS-`/SkillsFuture funding tiles + 6-website store switcher | Build the gating in the initial implementation, not staged. |
| **P8** | Deploy blast radius | **(a) Accept** (rely on pre-push checks) | Revisit a canary/approval gate before onboarding all 5 countries. |

### Group 2 — technical decisions

| # | Decision | Chosen | Note |
|---|---|---|---|
| **P5** | Country DB topology | **(a) Keep SG's 6-website rows, use only the country store** | Simplest for the pilot. |
| **P6** | Admin frontName | **(b) Reuse SG's (`tigerdragon`)** | Keep it env-overridable so a client can set their own later. |
| **P7** | Redis in country stack | **(a) Include Redis** | Country compose ships a `redis` service; generated `local.xml` includes the `redis_session` + `cache` blocks. ⚠️ The SG `Dockerfile` currently `sed`-disables `Cm_RedisSession.xml`; in country mode that must **not** be disabled (re-enable in the image or at boot when `MMS_MODE=country`). See §8.2. |
| **P10** | Seed rebuild ownership | **Case-by-case, by the team** | Guiding goal: **seed + migrations together must cover all bases** so any fresh instance converges. Rebuild the seed when migration replay becomes impractical or config drifts. |
| **P12** | Sync granularity v1 | **(a) Full pull each run** | Every run, fetch & upsert all ~500 `C`-courses (skip image **re-download** when the content hash is unchanged, to avoid re-transferring bytes). Add incremental (delta/hash) later only if runs get slow. |

> **All decision points are resolved.** Nothing is blocking implementation.

### Media store — DECIDED: local disk for country instances (no R2)

**Decision (P9a): country instances use option (ii) — local-disk media. No Cloudflare R2 in country mode.** SG keeps using R2 as today; **country instances do not use R2 at all.** ("Local media is good for now.")

What this means:
- Course images live on the instance's **own persistent `media/` volume** and are served directly by Apache (e.g. `media/catalog/product/...` / `media/course-covers/...`), with an **instance-relative `course_image_url`** (e.g. `https://<country-domain>/media/...`) — never an external/other-instance URL.
- The `C`-course **sync writes the downloaded image bytes to this local `media/` volume** (not to any R2), then sets `course_image_url` to the instance-local path.
- **Implied code work:** `MMD_CourseImage` currently *always* uploads to R2 (`Helper/R2.php`) and stores absolute R2 URLs. In `MMS_MODE=country` it must instead **write to local `media/`** and produce instance-relative URLs. Add a small media-driver switch (R2 in `sg` mode, local disk in `country` mode). This affects: course-cover generation/upload, category images, and the sync importer's media step.
- The `R2_*` env vars are therefore **unused/blank** on country instances.
- **Invariant (unchanged):** at runtime an instance only ever serves URLs pointing at **its own** store.

> The previous "(i) per-instance R2 bucket" option is retained only as a future alternative; **do not implement it now**.

---

## 6. Catalog ownership & course-code model (critical invariant)

This is the conceptual heart of the design — implement it precisely.

### Ownership rules
- **`C…` = SG-owned, country-read-only EXCEPT price (P1+P3).** Created/updated **only** by the sync. In country mode all C-course fields are **locked in admin except the `price` field** — staff can re-price for their local currency, but everything else is SG-managed and overwritten on sync. Label them "Synced from SG".
- **`TGS-…` = SG-only, never synced.** WSQ/SkillsFuture is an SG funding construct. The exporter must exclude `TGS-`.
- **Country-created courses = the per-country letter prefix (P2=b):** `GH…` (Ghana), `MY…`, `NG…`, `BT…`, `IN…`. The country has full agency over these. The **hard rule remains: never `C`, never `TGS-`.**

### The safety invariant (must hold in code)
> The sync importer's create/update/disable scope is **strictly `sku LIKE 'C%'`**. It must **never** insert, update, or disable any non-`C` SKU.

Because local courses are non-`C`, this guarantees the sync can **never** overwrite or delete a country's own catalog, no matter what SG does.

### Create-course guardrail (country mode)
When `MMS_MODE=country`, the "Create Course / Edit Course" save flow (`MMD_RoleManager` `CoursesaveController`) should **reject or auto-rewrite** a `C`/`TGS-` SKU so staff can't accidentally create a SKU that a future sync would clobber. Surface a clear message ("`C…` codes are reserved for SG-synced courses").

### Deletion / retirement policy on sync
If SG removes or disables a `C` course, the importer should **disable** (set `status=2`) the corresponding country product, **not hard-delete** it — a local class/order might reference it. Document this clearly; never `DELETE` catalog rows during sync.

---

## 7. One codebase, two modes

### The mode switch
- New env var **`MMS_MODE`**: `sg` (default) | `country`.
- New env var **`MMS_COUNTRY_CODE`**: required when `country` (e.g. `GH`, `MY`, `NG`, `BT`, `IN`).
- Expose via a small helper, e.g. `Mage::helper('mmd_rolemanager')->getMmsMode()` / `isCountryMode()` reading `getenv('MMS_MODE')` (and/or a `core_config_data` mirror written at boot). Centralise — do not scatter `getenv()` calls.

### Feature matrix (initial; extend as features are gated)
| Feature | `sg` | `country` |
|---|---|---|
| Course-sync **export** endpoint (`/sync/...`) | **On** | Off (or returns 403) |
| Course-sync **import** (button + cron) | Off | **On** |
| WSQ / SkillsFuture / `TGS-` handling, SG funding tiles | On | **Off / hidden** |
| Multi-store (6-website) store switcher | On | **Off** (single store) |
| Create-course SKU guardrail (block `C`/`TGS-`) | Off | **On** |
| Trainer import from LMS | On (as today) | Per-client (likely off initially) |

> Per **P11 (hide now)**, v1 implements the mode plumbing + export/import gating + SKU guardrail **and** hides the SG-only screens (WSQ/`TGS-`/SkillsFuture funding tiles, 6-website store switcher) in `country` mode. Keep a single source of truth for "what's gated by mode" so future toggles are one-liners.

---

## 8. Deployment model

### 8.1 SG (unchanged)
- Coolify **Application** built from `Dockerfile`; **separate** MySQL.
- Env panel sets `MMS_MODE=sg` (or leave default), plus existing secrets.
- Auto-deploy on push to `main` (existing GitHub webhook).

### 8.2 Country (new) — one Coolify Docker-Compose application
- Coolify resource type = **Docker Compose**, pointed at the same repo/`main`, using a **new prod compose file** committed to the repo (e.g. `compose.coolify.yml` or `docker-compose.coolify.yml`).
- The compose stack contains:
  - **`web`** — built from the existing `Dockerfile` (same image as SG).
  - **`db`** — `mysql:5.7`, persistent named volume, `--max_allowed_packet=256M`, utf8 settings (mirror the dev compose's DB tuning).
  - **`redis`** — **included (P7).** The generated `local.xml` must enable the `redis_session` + `cache` blocks (see `app/etc/local.xml.example`), and the image must **not** disable `Cm_RedisSession` in country mode. ⚠️ The SG `Dockerfile` currently `sed`-disables `Cm_RedisSession.xml`; gate that disable on `MMS_MODE` (or re-enable at boot for country) so Redis sessions actually work. With Redis sessions, `session_save` is Redis (not DB).
- **Persistent volumes (Coolify-managed):** `mysql_data` (critical), and **`media/` — which now holds ALL of this instance's catalog images** (locally-created **and** the synced `C`-course covers), since country instances use **local-disk media, not R2** (P9a). Also holds bank-payment proofs + email logo. Nothing is served from another instance. **Size the `media/` volume generously** (SG's catalog media is ~100MB+; a country grows as it syncs C-covers + adds local courses). `var/` is ephemeral.
- **Auto-deploy on push:** configure the country Coolify's GitHub webhook on the same repo/`main`. Every push redeploys SG **and** every country (each Coolify pulls the same `main`). ⚠️ This raises the blast radius of a bad `main` push to **all** instances — see Risks.
- **The prod compose must NOT contain** any of the dev-only bits from `docker-compose.yml`: Windows bind-mounts (`.:/var/www/html`), `${USERPROFILE}/.claude*` mounts, `tmpfs`, `MAGE_IS_DEVELOPER_MODE=1`, `LOCAL_DB_MODE=1`, host `php-local.ini`. It should bake everything via the image and read config from env.

### 8.3 First-boot sequence (country)
1. Coolify creates the stack; `mysql_data` volume is empty.
2. MySQL auto-imports the **seed** from `/docker-entrypoint-initdb.d/country-base.sql.gz` (mounted/copied from the repo) — **only because the volume is empty**.
3. `web` entrypoint waits for DB, **generates `app/etc/local.xml` from env** (if absent), runs `apply.php` (applies any migrations newer than the seed), runs the usual reindex/cache steps.
4. App serves; admin logs in with the seeded admin (must be rotated immediately — see runbook).
5. Admin runs **"Sync Courses from SG"** to populate the C-catalog.

---

## 9. Configuration & secrets

### 9.1 Hard rule
**Nothing secret is committed.** The repo contains only `*.example` templates. All secrets are set per-instance in Coolify's env panel, and the seed is stripped of secret `core_config_data`.

### 9.2 `app/etc/local.xml` generation from env
Because `local.xml` is gitignored and not in the image, the entrypoint must **generate it on first boot from env** (and persist the generated **`crypt/key`** to the volume so it's stable across restarts). Add a script, e.g. `docker/generate-local-xml.sh`, invoked early in `entrypoint.sh` when `local.xml` is missing:
- DB host (`db`), DB name/user/password (from env), admin frontName (env), `session_save=db`.
- `crypt/key`: if a persisted key file exists on the volume, reuse it; else generate a fresh random key, write `local.xml`, and persist the key. **Each instance has its own key.** (This is safe because the seed contains **no** encrypted values — see §10.)

### 9.3 Env contract (per-instance, set in Coolify)
| Var | Used by | Notes |
|---|---|---|
| `MMS_MODE` | mode helper | `sg` \| `country` |
| `MMS_COUNTRY_CODE` | country logic | e.g. `GH` |
| `MMS_BASE_URL` | base-url config | the instance's public URL |
| `MMS_ADMIN_FRONTNAME` | local.xml gen | admin path (don't reuse SG's verbatim if you want isolation) |
| `MYSQL_ROOT_PASSWORD`, `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD` | db + local.xml gen | per-instance |
| `SG_SYNC_URL` | importer | SG's base URL for the export endpoint |
| `SG_SYNC_API_KEY` | importer | the shared secret for the export endpoint |
| `R2_*` (5 vars) | `MMD_CourseImage` | **Country instances: leave BLANK (P9a — local-disk media, no R2).** Only SG sets these. In `country` mode `MMD_CourseImage` writes to the local `media/` volume instead. |
| `TURNSTILE_*` | captcha | optional; blank → captcha off |
| `GOOGLE_OAUTH_*` | admin Google login | optional per client |
| `SMTPPRO_*_FALLBACK_PASSWORD` | SMTP fallback | optional per client |
| (review/marketing keys) | various | optional; blank → stub mode |

> All "optional" features already degrade gracefully when their keys are blank (stub mode / disabled). Confirm this per feature during implementation; do not let a missing key 500 a page.

### 9.4 SG-side key for the export endpoint
Store the export API key in SG's config (e.g. `mmd/course_sync/api_key`), set from SG's Coolify env. The country sets the **same** value as `SG_SYNC_API_KEY`. Rotatable from one place.

---

## 10. Fresh-DB bootstrap seed

### 10.1 Why a seed (not migrations alone)
The repo has **no base schema** — migrations are incremental on top of an existing Magento DB. So a country DB must start from a base dump. We derive it from SG (which already has every table, EAV attribute, attribute set, tax class, country directory, CMS structure, and the migration ledger).

### 10.2 Build it with a reviewable script (do NOT hand-edit a dump)
Add `scripts/provision/build-country-seed.sh` that consumes an SG dump and emits `seed/country-base.sql.gz`. It must be deterministic and auditable.

**KEEP (structure + reference data):**
- All table **schemas** (`mysqldump --no-data` for everything).
- Data for: `eav_*` (attributes, attribute sets/groups, options + option values), `directory_*` (countries/regions/currency), `tax_*`, `core_store`, `core_store_group`, `core_website` (reduced to the single store — see §10.4), `core_config_data` (**non-secret rows only**), CMS structure if required for theme, `schema_migrations` (so the ledger matches the code at seed time), the index/eav metadata tables Magento needs to boot.

**STRIP / TRUNCATE (business data):**
- `catalog_product_*` (all), `catalog_category_*` (keep only root/default category rows), `cataloginventory_*`, `catalog_url*`, `url_rewrite`/`core_url_rewrite`.
- `customer_*`, `sales_*`, `quote*`, `wishlist*`, `review*`, `rating*`, `log_*`, `report_*`, `dataflow_*`.
- `course_runs`, `course_run_*` (enrolments/invitations/attendance/certificate), `courses_trainers`, `mmd_*` operational tables (trainer maps, leads, import logs, product_trainer, feedback responses), `catalogsearch_*`.
- `admin_user` (except one freshly-created seed admin), `admin_role`/`admin_rule` reduced to defaults, `mmd_user_role_map` (empty).

**SANITIZE (secrets):** delete `core_config_data` rows whose `path` matches secret patterns, including but not limited to:
- `smtppro/%`, `%/oauth%`, `%gmail%`, `%client_secret%`, `%api_key%`, `mmd/trainer_import/%`, `mmd/course_sync/%`, `courses/general/%api%`, `mmd_marketing/%`, `payment/%/(login|password|signature|token)`, anything storing an encrypted blob.
- Reset `web/unsecure/base_url` + `web/secure/base_url` (and any per-store base-url rows) to a placeholder; the entrypoint/env sets the real one.

**ASSERT before commit (automated, in the script):**
- 0 rows in every business table listed above.
- 0 `core_config_data` rows matching the secret patterns.
- No occurrence of known SG secret values (grep the dump against a denylist).
- `schema_migrations` count == number of `migrations/*.sql` files at seed-build time.
Fail the build if any assertion trips.

### 10.3 First-boot load
- Ship `seed/country-base.sql.gz`; the compose mounts/copies it to the DB container's `/docker-entrypoint-initdb.d/`. MySQL imports it **only on an empty volume**.
- After DB is up, `apply.php` runs and applies any migrations added to the repo **after** the seed was built (the ledger prevents re-running seeded ones). This is how a country stays current with schema changes shipped to `main`.
- **Re-seed cadence:** rebuild `country-base.sql.gz` periodically (e.g. each release train) so new instances don't have to replay hundreds of migrations. Document who owns this.

### 10.4 Single-store reconciliation
SG's DB models 6 websites. For a country instance pick one approach (decide during Phase 3):
- **(A, simplest)** Keep the multi-website rows but **point only the country's store** at the real domain and leave others inert/disabled. Lowest effort; some unused rows linger.
- **(B, cleaner)** In the seed-build script, reduce `core_website`/`core_store`/`core_store_group` to a single website/store for `MMS_COUNTRY_CODE`, and re-scope `core_config_data` website/store rows accordingly. More work, cleaner topology.
Recommendation: start with **(A)** for the Ghana pilot to de-risk; move to **(B)** once proven.

---

## 11. Course-sync feature (definitions only)

Two halves of the same codebase, gated by `MMS_MODE`.

### 11.1 SG side — export endpoint (`MMS_MODE=sg`)
- New controller, e.g. `MMD_RoleManager` `Sync_ExportController` (or under `MMD_Courses`), route like `GET /sync/courses-export`.
- **Auth:** header `X-API-Key` == `mmd/course_sync/api_key`; else 401. (Reuse the `MMD_Courses` API pattern.)
- **Scope:** products with `sku LIKE 'C%'` only. Exclude `TGS-`, `M`, `E`, `P`, `V`, `K`, etc.
- **Pagination:** `?page=&page_size=` (catalog is ~500 C-courses; page it).
- **Response (per product) — by STABLE keys, never numeric IDs:**
  - `sku`, `type_id`, `attribute_set` **(by name)**, `status`, `visibility`.
  - `attributes`: a map of `attribute_code → value` at store 0 (admin/default scope) for every relevant attribute: `name`, `description`, `short_description`, `url_key`, `price`, `special_price`, `duration`, `software`, `level`, `sessions`, `whoshouldattend`, `prerequisite`, `trainerprofile`, `meta_title/description/keyword`, `course_image_url` (SG's value — **reference only**; the importer re-hosts the bytes locally and does **not** keep this URL — see the `media` block), `course_brochure_url`, plus any course-specific attributes. Resolve select/multiselect to **option labels**, not option IDs.
  - `categories`: array of **category paths by url_key/name** (e.g. `["adult-courses/data-science"]`).
  - `custom_options`: the Course Date / Course Time option structures (title, type, sort, values) — by content, not IDs.
  - `badges/tags`: badge **names** (the `MMD_CourseImage` canonical vocabulary).
  - **`media` (P9):** for each image — `original_filename`, `mime`, **`content_hash`**, and a way to obtain the bytes. Either inline `base64` (simplest; fine at ~500 small covers) **or** an authenticated `media_fetch_path` on this same SG sync endpoint that returns the raw bytes. The importer uses `content_hash` to avoid re-fetching unchanged images. (The bytes come **through the sync API**, so a country never hits SG's R2 directly.)
  - `updated_at` / a content hash (for change detection / incremental sync later).
- **Read-only**; never mutates SG.

### 11.2 Country side — import (`MMS_MODE=country`)
- New `MMD_..._CourseSyncService` modelled on `MMD_RoleManager_Model_TrainerImportService`:
  - cURL `GET SG_SYNC_URL/sync/courses-export` with `X-API-Key: SG_SYNC_API_KEY`, paginate.
  - For each product, **upsert by SKU** (must be `C…`, else skip — the safety invariant):
    - Find-or-create `catalog/product`; map `attribute_set` **by name** → local id; set `type_id`, `status`, `visibility`.
    - Set each attribute by `attribute_code` (map select/multiselect **labels → local option IDs**, creating options if missing).
    - **PRICE (P1):** set `price`/`special_price` **only when the product is being CREATED** (first import). On **update**, **skip price entirely** — the country owns it after first import (local currency). Everything else is overwritten on update.
    - Assign to the **local store/website**.
    - Find-or-create categories by url_key/name; assign.
    - Recreate custom options (Course Date/Time) idempotently.
    - **MEDIA (P9/P9a — copy bytes, re-host on local disk):** fetch each C-course image's bytes from SG **via the sync API** (see §11.1), **write them to THIS instance's local `media/` volume** (no R2 in country mode), and set `course_image_url`/gallery to the **instance-relative** URL (`https://<country-domain>/media/...`). Skip the re-download when the content hash matches what's already stored (idempotent, avoids re-transferring bytes). The instance must **never** end up with a `course_image_url` pointing at SG (or any other instance). Locally-created courses use the same local `media/` store (via the `MMD_CourseImage` local driver).
  - **Disable (not delete)** local `C…` products absent from the export (retirement policy).
  - Reindex (`catalog_url`, flat catalog/category, search) after a run.
  - Write a run-summary log row (fetched / created / updated / disabled / skipped / errors) — mirror `mmd_trainer_import_log`.
- **Trigger surfaces — both live on the Courses dashboard (mirror trainer-import UX):**
  - **Location:** the **Courses dashboard** (the admin "Manage Courses" panel — `adminhtml/dashboard?panel=courses`, template `dashboard/index.phtml`). Put both controls here, role-gated like the existing dashboard banners.
  - Manual **"Sync Courses from SG"** button + a status card (last run, fetched/created/updated/disabled/skipped/errors).
  - A **daily cron**, **DISABLED by default** (`mmd/course_sync/auto_enabled` absent = OFF, fail-safe) — toggled by a **`.dcf-toggle-sw` UI pill** on the same Courses dashboard, with an in-flight lock. Exactly the pattern used by `mmd/trainer_invitation/auto_enabled` and `mmd/trainer_import/auto_enabled` (see the auto-invite banner on All Classes for a working reference). Cron entry in `config.xml` (e.g. daily ~03:00 SGT); the cron self-skips when the flag is OFF.
- **Idempotency:** re-running must converge with no duplicates (upsert by SKU; options/categories find-or-create). Use the content hash to skip unchanged products for speed.

### 11.3 Cross-install ID safety (do not skip)
Never transfer `entity_id`, `attribute_id`, `option_id`, `category_id`, `attribute_set_id`, `website_id`, `store_id`. They differ between installs. Map **only** by stable business keys (sku, attribute_code, attribute-set name, option **label**, category url_key/name, option title). This is the single most common way an EAV cross-install sync silently corrupts data — call it out in code review.

---

## 12. Phased implementation plan

> Build and validate **locally** first (you can run a second compose project to simulate a country instance). Do **not** point at any real Coolify until Phases 1–4 pass locally.

### Phase 1 — Production compose stack
- Add `compose.coolify.yml` (web + mysql 5.7 + **redis** per P7), persistent volumes, healthchecks, `restart: unless-stopped`, **no dev-only mounts/env**.
- **Acceptance:** `docker compose -f compose.coolify.yml up` on a clean machine yields a running web+db with no host bind-mounts and no secrets baked in.

### Phase 2 — Mode plumbing + local.xml-from-env
- Add `MMS_MODE`/`MMS_COUNTRY_CODE` helper(s); add `docker/generate-local-xml.sh`; wire into `entrypoint.sh` (generate if missing, persist crypt key).
- Gate the export endpoint to `sg` and the import to `country`; add the create-course SKU guardrail for `country`.
- **Acceptance:** booting with only env (no committed `local.xml`) produces a working app; `MMS_MODE` flips behaviour; crypt key persists across restarts.

### Phase 3 — Seed builder + first-boot load
- Add `scripts/provision/build-country-seed.sh` (keep/strip/sanitize/assert per §10) → `seed/country-base.sql.gz`.
- Wire the seed into `compose.coolify.yml` via `/docker-entrypoint-initdb.d/`; ensure `apply.php` tops up post-seed migrations.
- **Acceptance:** fresh volume → schema+config present, **0 business rows, 0 secret config rows** (run the assertions), admin loads, `apply.php` reports only post-seed migrations.

### Phase 4 — Course sync
- SG: export endpoint incl. media bytes/hash (§11.1). Country: import service + Courses-dashboard button + fail-safe cron toggle + log (§11.2).
- **`MMD_CourseImage` local-disk driver (P9a):** add a media-driver switch so `country` mode writes images to the local `media/` volume with instance-relative URLs (SG keeps R2). The sync importer and the normal course-cover/category upload flows both use it.
- **Acceptance:** from a clean country instance, "Sync from SG" creates the C-catalog; re-run is idempotent; non-`C` local courses are untouched; retired C-courses get disabled (not deleted); **images are stored on the instance's own `media/` volume and render from the instance's own domain (no SG/R2 URLs anywhere)**.

### Phase 5 — Package + webhook auto-deploy + runbook
- Confirm the same repo/`main` deploys SG (Dockerfile app) and a country (Compose app); document the Coolify webhook setup for a country.
- Write the per-country runbook (§13) and the env reference (§9.3 / appendix).
- **Acceptance:** a push to `main` redeploys both SG and the test country instance automatically.

### Phase 6 — Ghana pilot + fleet rollout
- Stand up Ghana on its Coolify (`http://2.24.131.228:8000/`), run the runbook, validate (§14), then repeat for MY/NG/BT/IN.

---

## 13. Per-country provisioning runbook (Ghana pilot)

1. **Build/refresh the seed** from a current SG dump (`build-country-seed.sh`); verify assertions pass; commit `seed/country-base.sql.gz` (it contains no secrets/data).
2. In **Ghana Coolify** (`http://2.24.131.228:8000/`): create a **Docker Compose** application pointing at the repo + `main`, using `compose.coolify.yml`.
3. Set **env**: `MMS_MODE=country`, `MMS_COUNTRY_CODE=GH`, `MMS_BASE_URL=https://<ghana-domain>`, `MMS_ADMIN_FRONTNAME=<frontname>`, `MYSQL_*`, `SG_SYNC_URL=https://<sg-mms>`, `SG_SYNC_API_KEY=<shared key>`, plus optional per-client SMTP/OAuth/Turnstile. **Leave `R2_*` blank** (country uses local-disk media — P9a).
4. Attach **persistent volumes** (`mysql_data`, `media`).
5. Configure the **GitHub webhook** so pushes to `main` auto-redeploy.
6. Point **DNS** for the Ghana domain at the Coolify app; issue TLS.
7. **First deploy:** confirm seed import → migrations → reindex; check `/version.txt` and a 200 on the storefront + admin.
8. **Rotate the seed admin** password immediately; create real admin users.
9. On SG: ensure `mmd/course_sync/api_key` is set (matches `SG_SYNC_API_KEY`) and the export endpoint is reachable.
10. In Ghana admin: click **"Sync Courses from SG"**; verify the C-catalog appears with images; optionally enable the daily cron toggle.
11. Run the validation checklist (§14). Then replicate for MY/NG/BT/IN.

---

## 14. Testing & validation

- **Fresh-volume boot:** delete the volume, redeploy; confirm seed loads, migrations top up, app serves 200 (storefront + admin), no fatals in logs.
- **No-secrets audit:** grep the running country `core_config_data` + `local.xml` for any SG secret value / secret path → must be empty; confirm the crypt key differs from SG's.
- **No-data audit:** assert business tables are empty pre-sync (products, customers, orders, course_runs, etc.).
- **Sync correctness:** spot-check several C-courses field-by-field vs SG (name, price, attributes, category, custom options). **Confirm images are stored on the instance's own `media/` volume and `course_image_url` points at the instance's own domain — no `r2.dev`/SG URLs anywhere.** Verify select/multiselect came across as the right **labels**.
- **Safety invariant:** create a local non-`C` course, run sync twice → local course untouched; counts stable on the second run (idempotent).
- **Mode isolation:** confirm the export endpoint is 403/absent in country mode and the import is absent in SG mode; confirm `C`/`TGS-` SKUs are blocked in the country create-course flow.
- **Auto-deploy:** push a trivial change to `main` → both SG and Ghana redeploy via webhook.
- **Migration safety:** follow the repo's existing pre-push protocol (lint changed PHP, dry-run `apply.php`, hit affected routes) — see `CLAUDE.md` "Pre-push verification".

---

## 15. Risks & mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| **One `main` auto-deploys to ALL instances** | A bad push breaks SG **and** every country at once | Strict pre-push checks (already mandated in `CLAUDE.md`); consider a staged/canary rollout or a per-instance "deploy gate" later; keep migrations idempotent + reversible. |
| **EAV cross-install ID mismatch** | Silent catalog corruption | Map by stable keys only (§11.3); review explicitly; test labels round-trip. |
| **Seed leaks secrets or data** | Security incident | Automated keep/strip/**assert** script; deny-list grep; never hand-edit dumps; review the assertions in PR. |
| **Migrations assume 6-website topology** | Single-store weirdness | §10.4 reconciliation; pilot with approach (A), move to (B) if needed. |
| **Mode flag scattered** | Inconsistent behaviour | One helper as the single source of truth; feature matrix in this doc. |
| **Crypt-key divergence vs seeded encrypted values** | Undecryptable config | Seed contains **no** encrypted values (sanitized); each instance generates+persists its own key. |
| **Media self-hosting (P9/P9a — local disk)** | Sync transfers image bytes (not just URLs) onto each instance's `media/` volume → more storage + a heavier first sync; needs new `MMD_CourseImage` local-disk driver | Bytes travel through the sync API; importer writes to the local `media/` volume and sets instance-relative URLs; `content_hash` skips unchanged re-downloads. **Zero runtime cross-instance media dependency.** Build the `MMD_CourseImage` local driver (write to `media/` in `country` mode) in Phase 4; size the `media/` volume generously. |
| **Country edits a `C` course** | Lost on next sync | Lock `C` editing in country mode + clear labelling. |

---

## 16. Open questions / future work

- **Incremental sync:** v1 can full-pull; add `updated_at`/hash-based delta + a "changed since" param for large catalogs.
- **Single-store seed (approach B)** once the pilot is stable.
- **Per-instance R2 buckets** — decided **against** for now (country instances use local-disk media, P9a). Retained only as a possible future alternative if a client ever wants object storage.
- **Deploy gating / canary** to reduce the all-instances blast radius of `main`.
- **Pushing country courses up to SG** (explicitly out of scope now).
- **Which SG-only features to hide in country mode** beyond the initial matrix (WSQ, funding tiles, store switcher) — enumerate as they're touched.

---

## 17. Appendices

### Appendix A — Env var reference
See §9.3. Treat every `*_KEY`, `*_SECRET`, `*_PASSWORD`, OAuth, and `crypt/key` as **per-instance, never committed**.

### Appendix B — Seed keep/strip/sanitize lists
See §10.2. The script is the source of truth; this doc is the intent. Keep them in sync.

### Appendix C — Course export/import field contract
See §11.1–11.3. Expand into an exact `attribute_code` list during Phase 4 by enumerating the attributes a real `C` course actually uses (query `catalog_product_entity_*` for one C SKU) — do not guess.

### Appendix D — Key code references (current repo)
- Deployment: `Dockerfile`, `docker/entrypoint.sh`, `docker-compose.yml` (dev), `docker-compose.override.yml` (dev seed pattern).
- Migrations: `migrations/apply.php`, `migrations/*.sql`, `schema_migrations` ledger.
- API-key auth pattern: `app/code/local/MMD/Courses/controllers/Api/CoursesController.php`.
- Pull + toggle + log pattern: `app/code/local/MMD/RoleManager/Model/TrainerImportService.php`, `Model/Cron/TrainerImport.php`, config `mmd/trainer_import/*`.
- Country/website mapping: `app/code/local/MMD/RoleManager/Helper/Data.php` (`$websiteToCountryCode`, `countryCodeForProduct`).
- Course-image / badges / R2: `app/code/local/MMD/CourseImage/*`.
- Config/secrets templates: `app/etc/local.xml.example`, `.env.example`.

---

*End of plan. No code or infrastructure changes have been made — this document is for handoff only.*
