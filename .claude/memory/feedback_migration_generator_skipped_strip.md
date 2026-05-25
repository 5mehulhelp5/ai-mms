---
name: migration-generator-skipped-strip-when-local-already-migrated
description: "Generators that scrape/read local DB to emit prod-bound SQL must NOT skip steps when local is already in the target state — the generated migration will silently no-op on prod for those products. Also: SQL string escapes (\\r\\n) can fail to take effect on prod even when local works; use UNHEX('...') hex literals for byte-exact REPLACE() substrings to avoid backslash-interpretation surprises."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: e3c7de75-31c0-4c39-abe9-e6fc7ef126b1
---

When a migration generator reads from local DB to produce prod-bound SQL, do NOT short-circuit emission based on local's current state. The generator pattern in migrations/151 and the AWS analogue both had:

```php
if (strpos($desc, 'Certification Exam at Pearson Vue') === false) {
    continue; // already stripped in this scope
}
if (!preg_match($pattern, $desc, $mr, PREG_OFFSET_CAPTURE)) {
    continue;
}
```

That skips the strip-SQL emission for any product whose local row was already cleaned by an earlier dev script. Result: the migration file ships to prod with NO strip statement for those products, prod stays stale, and you only catch it when a user notices the live page still showing the section.

Additionally, even when strip statements WERE emitted (migration 152), MySQL on prod did not apply the `REPLACE(value, '<text>\r\n<text>', '')` despite the substring matching the stored bytes exactly. The parallel `CONCAT()` statement in the same migration did run, so the file executed; the most likely cause is a backslash-escape interpretation difference between prod's MySQL and local's that left `\r\n` as literal backslash-r-backslash-n on prod instead of CR+LF.

**Why:** Hit this twice in one session — CompTIA Pearson Vue + CompTIA Exam Voucher both shipped a "migration applied" status but no prod data change. Required migration 156 as a rescue: live-scrape prod, build `REPLACE(value, UNHEX('hex'), '')` statements that bypass string-escape interpretation entirely.

**How to apply:**
- When building a prod-bound generator from local data, ALWAYS emit unconditional strip statements (UPDATE / REPLACE) — let idempotency come from `REPLACE()` being a no-op on rows that don't contain the substring, not from a generator-side check that depends on local state. Same goes for `INSERT ... WHERE NOT EXISTS` and `UPDATE ... WHERE NOT LIKE` guards — let the SQL be self-idempotent rather than skipping emission.
- For any `REPLACE()` whose search string contains `\r`, `\n`, `\\`, or escaped quotes, prefer `REPLACE(value, UNHEX('<bin2hex of bytes>'), '')` over the string-literal form. UNHEX takes a hex literal with zero escape interpretation — what you put in is exactly the bytes MySQL searches for. Pattern: `$hex = bin2hex($exactSubstring);` then `"UPDATE ... REPLACE(value, UNHEX('{$hex}'), '')"`.
- Verify generators that produce SQL from `media/migrations-reports/` backup payloads the same way: re-run the diagnostic against prod's rendered HTML (binary mode read — Python text mode strips `\r\n` to `\n` and creates a false positive that the substring matches).
- Reference fix: [scripts/local-dev/generate-strip-prod-leftover-sections.php](scripts/local-dev/generate-strip-prod-leftover-sections.php) → [migrations/156-strip-leftover-prod-sections.sql](migrations/156-strip-leftover-prod-sections.sql).

Related: [[eav-save-attribute-scope]] (sibling "looks-fine-locally but prod is stale" pattern).
