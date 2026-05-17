# Local Dev SQL Scripts

SQL that is **local-dev only** — NOT applied on production. Run these manually against your local DB after importing a fresh production dump.

## What's here

- `003-enable-all-products.sql` — re-enables all courses (production keeps ~441 archived)
- `004-set-localhost-urls.sql` — points base URLs at `http://localhost:8080/`
- `005-disable-admin-captcha.sql` — disables admin captcha that can fail in dev containers
- `006-import-reviews-2026-04-to-05-17.sql` — backfills 403 course reviews + votes from the 2026-05-17 production backup (range 2026-04-01..2026-05-17) and recomputes `review_entity_summary` for the 95 affected products
- `007-import-orders-2026-04-07-to-05-17.sql` — clean-append backfill of 350 course orders (entity_id 46360..46709, range 2026-04-07..2026-05-17) from the 2026-05-17 production backup, with addresses/items/payments/status history/grid/invoices/tax dependents

## Apply to local DB

```bash
for f in scripts/local-dev/*.sql; do
  docker exec -i ai-mms-db_mysql-1 mysql -u magento -pmagento123 courses_backupDB < "$f"
done
```

## DO NOT put these in `migrations/`

Files in `migrations/` auto-apply on production via Coolify's post-deployment hook. Anything that would break production (like rewriting base URLs to localhost) must stay out of that folder.
