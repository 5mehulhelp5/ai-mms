---
name: wsq-lms-sync
description: Pull WSQ (TGS-) course data — the six courseware links (Learner Slides, Learner Guide, Lesson Plan, Trainer Slides, Courseware Link, Brochure Link) and the Approved Trainer list — from AI-LMS-TMS (lms-tms.tertiaryinfotech.com), the source of truth for WSQ courses, into the MMS storefront (ai-mms). Use when asked to "pull courseware from the LMS/TMS", "sync approved trainers", "the course page has no Learner Guide / Lesson Plan", "update WSQ courseware links", or when MMS course data is stale versus the TMS.
---

# WSQ LMS→MMS sync

**Direction is always LMS-TMS → MMS.** AI-LMS-TMS is the source of truth for WSQ
(`TGS-`) courseware links and approved trainers. MMS (the storefront) mirrors them.
Never write storefront values back into the TMS with this skill — `/lms-push` is the
separate, deliberate path for publishing freshly-built courseware INTO the TMS.

## The two systems

| | AI-LMS-TMS | MMS (this repo) |
|---|---|---|
| Live | `https://lms-tms.tertiaryinfotech.com` | `https://www.tertiarycourses.com.sg` |
| Repo | `github.com/alfredang/AI-LMS-TMS` — local `../ai-lms-tms` | `github.com/…/ai-mms` — this repo |
| Stack | Next.js 16 (Pages Router) + PostgreSQL 17, raw SQL | OpenMage 1.x + MySQL 5.7 |
| Deploy | Coolify, push to `main` | Coolify, push to `main` |
| Course row | `course` table, keyed `course_code` | `catalog_product_entity`, keyed `sku` |

**The join key is the course code** — `course.course_code` (TMS) == `sku` (MMS), e.g.
`TGS-2023036088`. Nothing else is shared; there are no common ids.

## Architecture invariant — API only, never the DB

> Only the LMS app connects to the LMS database. **Every other system exchanges data
> over the HTTPS API (443), never the DB directly.**

That is what makes the LMS DB network-hardening safe, so **do not** query LMS Postgres
to build an MMS migration, even though `scratch/db-tunnel.sh` exists and would work.
Tight polling of the prod host also risks a fail2ban SSH ban. Pull over HTTPS.

## Reading from the TMS

`GET /api/external/courses` — the course-level feed. Auth is a header:
`x-api-key: $EXTERNAL_API_KEY_FOR_CLAWDBOT`.

**MMS already holds these credentials** — reuse them, do not provision a new secret:

```php
Mage::getStoreConfig('mmd/trainer_import/lms_url')   // https://lms-tms.tertiaryinfotech.com
Mage::getStoreConfig('mmd/trainer_import/api_key')   // the shared key
```

Useful params: `course_code=` (exact), `search=` (ILIKE on title/code), `page` /
`limit` (default 500, max 1000), and `fields=` for a comma-separated subset.

```bash
curl -s -H "x-api-key: $KEY" \
  "https://lms-tms.tertiaryinfotech.com/api/external/courses?limit=1000&fields=course_code,title,learner_slides_url,learner_guide_url,lesson_plan_url,trainer_slides_url,courseware_link,brochure_link,trainers_list,trainers_email_list"
```

### `fields=` fails SILENTLY on an unknown name

The handler filters requested fields against a server-side `FIELD_MAP` allow-list and
**drops anything not in it, with no error** — you get `200 OK` and a row that is simply
missing the column. A field that "returns nothing" usually means it is not in the
allow-list, not that the data is empty. Verify against `FIELD_MAP` in
`pages/api/external/courses.ts` before concluding a course has no courseware.

(This is exactly how the three courseware fields below went unnoticed: they were absent
from the allow-list and every request for them came back clean but empty.)

## Field mapping — the names differ

Both sides use the same names **except Learner Slides**. Get this wrong and you will
mirror the PPT into the PDF slot.

| Card label | TMS DB column | TMS API field | MMS field |
|---|---|---|---|
| Learner Slides | `course.slides_url` ⚠️ | `learner_slides_url` | `learner_slides_url` |
| Learner Guide | `learner_guide_url` | `learner_guide_url` | `learner_guide_url` |
| Lesson Plan | `lesson_plan_url` | `lesson_plan_url` | `lesson_plan_url` |
| Trainer Slides | `trainer_slides_url` | `trainer_slides_url` | `trainer_slides_url` |
| Courseware Link | `courseware_link` | `courseware_link` | `courseware_link` |
| Brochure Link | `brochure_link` | `brochure_link` | `brochure_link` |

⚠️ The TMS **column** is `slides_url`; the API aliases it to `learner_slides_url` to
match MMS. When reading the DB or the LMS UI code, expect `slides_url`.

MMS also has `lab_url` (Activities folder) with **no TMS counterpart** — never blank it
during a sync.

## Approved trainers — different shapes on each side

| | TMS | MMS |
|---|---|---|
| Storage | `course.trainers_list` + `course.trainers_email_list` — delimited **text** on the course row | `mmd_product_trainer` — a real junction table (`product_id`, `user_id`, `sort_order`) |
| Identity | a name string, email list maintained separately | `admin_user.user_id` with the `trainer` role in `mmd_user_role_map` |

Parsing the TMS strings — mirror `lib/trainerInvitations.ts::splitTrainerList`:
**split on `|` when a pipe is present, otherwise on `,`** (legacy rows), trim, drop empties.

**The two lists are positionally independent.** A name may have no matching email and
vice versa, so only zip them by index after confirming the counts match; otherwise treat
the **email list as authoritative** — email is the shared identity between the systems.

Because MMS keys approved trainers by `admin_user.user_id`, an imported trainer must
already exist as an operator account. `MMD_RoleManager_Model_TrainerImportService`
(`/api/external/trainers-export`) creates/roles those accounts — **run the trainer import
first**, then map the approved list. A TMS trainer with no MMS account cannot be linked;
report them rather than silently dropping them.

## Writing into MMS

Ship an **idempotent SQL migration** (`migrations/NNN-*.sql`) — data pulled live must
survive a DB rebuild. Two upsert targets: `course_courseware` (per-product key/value
row) and `mmd_product_trainer` (approved pool).

There is also a live write API — `POST /courses/api_courseware` with header
`X-API-Key: <courses/general/wsq_schedule_api_key>`, body `sku` plus any writable field
(`trainer_slides_url`, `learner_slides_url`, `lesson_plan_url`, `learner_guide_url`,
`lab_url`, `courseware_link`, `brochure_link`). It writes **only the keys present**, so
it updates one link without blanking the rest. Use it for immediate effect, but a
migration is still required for durability.

### Migration rules that bite here

- **Partner-safe.** The same migrations run on SG, MY and GH servers. WSQ is
  SG-only, so guard on the SKU prefix (`TGS-`) — a `TGS-` match is naturally a no-op on
  partner DBs, but never assume a product_id means the same course on another server.
- **Never hardcode `block_id`/`product_id` keys** — they drift between local and prod.
  Resolve products by `sku`.
- **UTF-8 sanitise anything from legacy tables**, or `apply.php` dies on error 1366 and
  every host 502s. Trainer names are a real risk here.
- Dry-run the **real runner**, never the `mysql` client:
  `docker exec ai-mms-web-1 php /var/www/html/migrations/apply.php`

## Order of operations

1. **Extend the TMS API first if a field is missing** — add it to `FIELD_MAP` in
   `pages/api/external/courses.ts`, push, and wait for the Coolify build. A pull cannot
   invent a field the allow-list omits.
2. `GET /api/external/courses` for all `TGS-` courses (`limit=1000`).
3. Run the trainer import so approved trainers have MMS accounts.
4. Generate the idempotent migration; resolve by `sku` / email.
5. `apply.php` dry-run locally, lint, verify a course page, then push.

## Verifying

Check a known-good course end to end. `TGS-2023036088` ("Agentic AI for Video Creation")
has all six links populated and is a good canary:

```bash
curl -s -H "x-api-key: $KEY" \
  "https://lms-tms.tertiaryinfotech.com/api/external/courses?course_code=TGS-2023036088&fields=course_code,learner_guide_url,lesson_plan_url,trainer_slides_url,trainers_list"
```

A course whose links are blank in the TMS is **not** a sync bug — the TMS is the source
of truth, and blank there means blank. Fix it in the TMS (or via `/lms-push`), not by
writing a value into MMS that the TMS does not have.

## Related

- `/lms-push` — the opposite direction: publish freshly-built Drive links INTO the TMS.
- `course-catalog-api` — the MMS read-only course feeds.
- `MMD_Courses_Model_LmsTmsCourseRun` / `LmsTrainerLookup` — existing read-only LMS
  clients in MMS; copy their curl + failure-is-non-fatal pattern rather than inventing one.
