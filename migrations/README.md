# Database Migrations

SQL migrations kept here are **applied automatically** to both local and production databases. Used for schema changes and config/data updates that must stay in sync across environments.

## Rules

1. **Immutable**: once a migration has been applied, never edit that file. Write a new migration to undo or change something.
2. **Shared only**: only put SQL here that is safe for **both** local dev and production. Local-only setup (URL overrides, test data) belongs in `scripts/local-dev/`, not here.
3. **Naming**: `NNN-short-description.sql`, zero-padded to 3 digits. Alphabetical sort determines run order.
4. **Idempotent when possible**: prefer `INSERT ... ON DUPLICATE KEY UPDATE`, `CREATE TABLE IF NOT EXISTS`, etc. The tracking table prevents re-runs, but idempotent SQL survives partial failures.

## Adding a new migration

1. Create `migrations/NNN-your-change.sql` with the next number.
2. Test locally:
   ```bash
   docker exec ai-mms-web-1 php /var/www/html/migrations/apply.php
   ```
3. Commit and push. Coolify's post-deployment hook applies it to production on next deploy.

## Tracking table

A `schema_migrations` table is auto-created in each DB:

```sql
CREATE TABLE schema_migrations (
    filename VARCHAR(255) PRIMARY KEY,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

Each successfully-run migration inserts one row with its filename.

## First-time setup (bootstrap)

Run **once per database** before the auto-run hook activates. This marks all existing migrations as already-applied so they don't re-run against DBs where they were already manually applied:

```bash
# Local
docker exec ai-mms-web-1 php /var/www/html/migrations/apply.php --bootstrap

# Production (in Coolify app terminal)
php /var/www/html/migrations/apply.php --bootstrap
```

## Production deploy hook

Configured in Coolify: **Application → Configuration → Post-deployment Command**

```
php /var/www/html/migrations/apply.php
```

Runs after each deploy. Fails the deployment if any migration errors, so production stays in a known state.

## If a migration fails

The runner stops at the first failure and exits non-zero. Fix the SQL (or the DB state), then re-run. Successfully-applied migrations before the failure are recorded; they won't re-run.
