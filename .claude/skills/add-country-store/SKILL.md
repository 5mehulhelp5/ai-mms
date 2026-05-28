---
name: add-country-store
description: Wire a new country domain (e.g. tertiarycourses.com.<cc>) to its Magento store view. Use when adding a new market storefront, fixing a country domain that redirects to the default site, or normalizing an existing store's code/base_url to match the SG/MY/GH/NG/BT/IN pattern. Triggers on phrases like "add Malaysia store", "wire .com.<tld> to store", ".com.<x> redirecting to ai-mms", "country domain not showing", "set up new country", "configure new store".
---

# Add a country store

Use this skill to wire one country domain to one Magento store view, consistent with how Ghana (.com.gh), Nigeria (.com.ng), and Malaysia (.com.my) are wired. The exact same shape every time — no improvisation.

## The four touchpoints

Adding a country store *always* hits these four places, in this order:

1. **`.htaccess`** — `SetEnvIf Host` block routing the host to `MAGE_RUN_CODE=<store_code> MAGE_RUN_TYPE=store`, plus the non-www→www redirect.
2. **DB migration `migrations/NNN-set-<country>-store-base-url.sql`** — sets `web/unsecure/base_url`, `web/secure/base_url`, `web/secure/use_in_frontend`, scoped to the store. If the store was originally created with a legacy code (e.g. `'english'` for MY), the migration *first* renames `core_store.code` to match the country.
3. **Coolify "Domains" field** — append both `https://<country-domain>` and `https://www.<country-domain>` to the comma-separated list. Trigger a redeploy.
4. **DNS at the registrar** — A record for apex and CNAME (or A) for `www`, pointing at the Coolify host's public IP.

Skipping any one of these is the bug, every time.

## Critical invariant: store code MUST match MAGE_RUN_CODE

`.htaccess` sets `MAGE_RUN_CODE=<x> MAGE_RUN_TYPE=store`. Magento then looks for `core_store.code = '<x>'`. If no store matches, Magento falls back to the default scope — whose `base_url` is `https://ai-mms.tertiaryinfo.tech/` — and 301-redirects there. That's the "why is .com.my redirecting to ai-mms" failure mode.

So: **the store_code in DB and the MAGE_RUN_CODE in .htaccess must be identical strings.** Naming convention: lowercase country name (`ghana`, `nigeria`, `malaysia`, `bhutan`, `india`). Don't reuse legacy codes like `english`. The website code (`core_website.code`) is allowed to differ, but the store code (`core_store.code`) is what `MAGE_RUN_TYPE=store` matches.

## Migration template

Use this exact shape — copy from `migrations/061-set-ghana-store-base-url.sql` or `migrations/066-set-malaysia-store-base-url.sql`. Replace `<COUNTRY>`, `<TLD>`, and (only if the store has a legacy code) include the rename block.

```sql
-- Wire www.tertiarycourses.com.<TLD> to the <Country> store view.
-- Mirrors migrations 061 (Ghana) and 066 (Malaysia).

-- [INCLUDE ONLY IF the store currently has a legacy code]
-- Rename core_store.code so .htaccess MAGE_RUN_CODE=<country> matches a real store.
UPDATE core_store
SET code = '<country>'
WHERE code = '<legacy_code>' AND website_id = <wid>;

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'web/unsecure/base_url', 'https://www.tertiarycourses.com.<TLD>/'
FROM core_store s WHERE s.code = '<country>'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'web/secure/base_url', 'https://www.tertiarycourses.com.<TLD>/'
FROM core_store s WHERE s.code = '<country>'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'stores', s.store_id, 'web/secure/use_in_frontend', '1'
FROM core_store s WHERE s.code = '<country>'
ON DUPLICATE KEY UPDATE value = VALUES(value);
```

Rules for the migration:
- **Numbered prefix** — next available NNN under `migrations/`. Check `ls migrations/ | tail -5` first.
- **Idempotent** — `ON DUPLICATE KEY UPDATE` on the inserts; the `UPDATE` row only runs if the legacy code still exists.
- **Resolve store_id via `code` lookup**, never hardcode `store_id=N` — store IDs differ across environments.
- **Three rows minimum**: unsecure base_url, secure base_url, use_in_frontend=1. Don't add more unless asked.

## .htaccess block (template)

Add immediately after the existing country blocks (around line 35-49 in `.htaccess`):

```apache
## tertiarycourses.com.<TLD> → <Country> store view
SetEnvIf Host ^(www\.)?tertiarycourses\.com\.<TLD>$ MAGE_RUN_CODE=<country>
SetEnvIf Host ^(www\.)?tertiarycourses\.com\.<TLD>$ MAGE_RUN_TYPE=store

## Redirect non-www to www for tertiarycourses.com.<TLD>
RewriteCond %{HTTP_HOST} ^tertiarycourses\.com\.<TLD>$ [NC]
RewriteRule ^(.*)$ https://www.tertiarycourses.com.<TLD>/$1 [L,R=301]
```

Escape every literal `.` in regex (`\.`). The `<country>` value in `MAGE_RUN_CODE` MUST be the same string you set as `core_store.code` in the migration.

## Verification (local, before pushing)

```bash
# Apply the migration locally
docker exec ai-mms-web-1 php /var/www/html/migrations/apply.php

# Confirm the rename and base_url stuck
docker exec ai-mms-db_mysql-1 mysql -umagento -pmagento123 courses_backupDB -e "
  SELECT store_id, code, website_id, name FROM core_store WHERE code = '<country>';
  SELECT scope_id, path, value FROM core_config_data
    WHERE scope = 'stores' AND path LIKE 'web/%base_url'
      AND scope_id = (SELECT store_id FROM core_store WHERE code = '<country>');
"
```

Expect exactly one store row with the new code, and two base_url rows with the new domain.

## Coolify + DNS handoff (user, not Claude)

After committing + pushing, tell the user:

1. **Coolify Domains field** — paste the full comma-separated list. Always append the new pair to the existing list; never replace. Format:
   ```
   https://ai-mms.tertiaryinfo.tech,https://tertiaryinfotech.edu.sg,https://www.tertiaryinfotech.edu.sg,https://tertiarycourses.com.ng,https://www.tertiarycourses.com.ng,https://tertiarycourses.com.gh,https://www.tertiarycourses.com.gh,...,https://tertiarycourses.com.<TLD>,https://www.tertiarycourses.com.<TLD>
   ```
2. **DNS** — A record on apex + CNAME (or A) on `www`, pointing at the Coolify host IP that `.com.gh` / `.com.ng` already resolve to.
3. **Redeploy** in Coolify so Let's Encrypt issues the cert and Caddy/Traefik picks up the new vhost.

Do NOT advise the user to enable "Force HTTPS to primary domain" or any Coolify domain-redirect toggle — `.htaccess` handles non-www→www on its own; the Coolify toggle would 301 every country domain to ai-mms and break this whole pattern.

## Commit message shape

One commit per country, matching the existing style:

```
Wire www.tertiarycourses.com.<TLD> to the <Country> store

[short context — what the migration does and why; reference 061/066 as precedent if relevant]
```

## Admin Store View bar — must filter grid data, not just decorate

A new country store is only "wired" when the admin Store View bar
(`MMD_Branchscope_Block_Store_Switcher`, injected globally via
`layout/branchscope.xml`) actually filters every store-scoped admin grid
to that country. The pill writes `?store=N` into the URL; each grid
must honour it. **Showing the pill bar while ignoring `?store=` is the
forbidden state** — it lies to the operator about what they're looking at.

### How filtering works under the hood

- Pill URL: `Mage::helper('branchscope')->buildPillUrl($storeId)` — adds
  `?store=N` to the current route. Active id resolves via
  `getActiveStoreId()` (URL param → session → SG default).
- The Store View bar only renders on routes in
  `MMD_Branchscope_Helper_Data::isStoreScopedRoute()` (catalog, sales,
  customer, cms, newsletter, promo, reports, leads, seoaudit, etc.).
  If your new grid doesn't appear in that allow-list, add it there;
  conversely, never add a controller whose data has no store dimension.
- The grid itself is responsible for applying the filter. Stock Magento
  is inconsistent: catalog product / sales order / customer grids honour
  `?store=` natively, but Reviews, Search Terms, Tag, Newsletter Problem,
  and several reports do not.

### Wiring filter into a grid that doesn't filter natively

Override `_beforeLoadCollection` (NOT `_prepareCollection`) so the store
id is set **before** `load()` runs and `_beforeLoad` builds the SQL. Calling
`addStoreFilter()` after `parent::_prepareCollection()` is too late on
many collections — the parent calls `$collection->load()` internally
and the join is baked with `store_id = 0`.

```php
protected function _beforeLoadCollection()
{
    parent::_beforeLoadCollection();
    $storeId = (int) $this->getRequest()->getParam('store', 0);
    if ($storeId > 0 && $this->getCollection()) {
        $this->getCollection()->addStoreFilter($storeId);
    }
    return $this;
}
```

Reference: [Block/Review/Grid.php](app/code/local/MMD/Adminhtml/Block/Review/Grid.php) — the Reviews & Ratings grid had to be patched this way because `Mage_Adminhtml_Block_Review_Grid` only calls `addStoreData()` (display-only) and never `addStoreFilter()`. Same shape applies to any other grid where `?store=` is silently ignored.

### Verify after adding a new country

Per new store, walk every admin grid on the `isStoreScopedRoute()`
allow-list and confirm:

1. `?store=<new_id>` returns only that country's rows.
2. `?store=0` (or no param) returns all rows.
3. Cross-store rows (e.g. shared course products) appear under every
   store as expected based on `catalog_product_website` membership.

If a grid still shows global rows under a country pill, it's a missing
`addStoreFilter` in that grid's MMD override (or a missing override
entirely). Treat it as part of the country-wiring change, not as a
follow-up.

## Anti-patterns — don't

- Don't hardcode `store_id=2` etc. Always `WHERE code = '<country>'`.
- Don't set `web/cookie/cookie_domain` for the new store — empty (request-host) is correct so the cookie works on whichever country domain the user visits.
- Don't enable Magento's `web/url/redirect_to_base = 1` "globally to fix things" — it'll cross-redirect country domains to whatever scope has the longest base_url match.
- Don't put rules under `default` scope (scope_id=0) — that scope is the fallback for unmatched MAGE_RUN_CODE and should keep pointing at `ai-mms.tertiaryinfo.tech`.
- Don't reuse a legacy store code (`english`, etc). Rename it in the same migration. Grep for hardcoded refs first: `grep -rn "'<legacy_code>'" app/code/local migrations .htaccess`.

## Quick reference: existing country wiring

| Country  | website_id | store_id | store code | domain                        | migration |
|----------|------------|----------|------------|-------------------------------|-----------|
| Singapore| 1          | 1        | default    | www.tertiaryinfotech.edu.sg   | (default) |
| Malaysia | 2          | 2        | malaysia   | www.tertiarycourses.com.my    | 066       |
| Ghana    | 3          | 3        | ghana      | www.tertiarycourses.com.gh    | 061       |
| Nigeria  | 4          | 4        | nigeria    | www.tertiarycourses.com.ng    | 059       |
| Bhutan   | 5          | 5        | bhutan     | (not yet wired)               | —         |
| India    | 6          | 6        | india      | (not yet wired)               | —         |
