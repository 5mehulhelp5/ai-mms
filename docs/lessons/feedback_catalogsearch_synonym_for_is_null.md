---
name: catalogsearch-synonym-for-is-null
description: "catalogsearch_query.synonym_for defaults to NULL, not empty string — `WHERE synonym_for = ''` matches zero rows"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 264c0dd6-3c02-4f4e-8645-88e6e0248624
---

The `synonym_for` (and `redirect`) columns on `catalogsearch_query` are
nullable VARCHAR with a default of NULL — they do NOT default to `''`.
Any predicate that filters "rows not yet curated" must therefore handle
both: `(synonym_for IS NULL OR synonym_for = '')`. A WHERE clause of
just `synonym_for = ''` will silently match zero rows.

**Why:** Migration 168 (catalogsearch synonyms) ran cleanly with status OK
but mapped only 2 rows on the first attempt — its WHERE clause was
`AND src.synonym_for = ''`. Verifying with `SELECT … synonym_for IS NULL
AS is_null` showed every row returned `is_null = 1`. Rewriting all 35
UPDATEs to `(src.synonym_for IS NULL OR src.synonym_for = '')` then
mapped 149 rows across 34 canonical terms on the next run.

**How to apply:** Any time you write SQL or PHP that filters
`catalogsearch_query` for "not curated" / "available for mapping" rows,
include both branches:

```sql
-- migrations
WHERE  src.query_text IN (...)
  AND  (src.synonym_for IS NULL OR src.synonym_for = '');
```

```php
// PHP (e.g. MMD_Adminhtml_Helper_SearchSpam::curatedGuard)
"(synonym_for IS NULL OR synonym_for = '') "
. "AND (redirect IS NULL OR redirect = '')"
```

The spam-cleanup helper at
`app/code/local/MMD/Adminhtml/Helper/SearchSpam.php::curatedGuard()`
already does this correctly — copy that pattern, don't write a bare
`= ''` check.

Linked: [[migration-generator-skipped-strip]] (related class of "the
migration ran but did nothing" bugs).
