---
name: short-description-unicode-whitespace
description: "Catalog short_description / description HTML contains Microsoft-pasted Unicode whitespace (U+202F narrow no-break space, U+00A0 NBSP) — ASCII \\s in regex won't match it"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 089e3fb3-1b18-476a-9a29-85c162b163d2
---

When scrubbing or matching content inside `catalog_product_entity_text`
(short_description, description) with PCRE, use a Unicode-aware
whitespace class — never bare `\s`. Microsoft Word / Outlook paste
injects U+202F (narrow no-break space, bytes `e2 80 af`) and U+00A0
(NBSP, bytes `c2 a0`) into the markup, especially right before
closing tags like `</strong>` or `</h2>`. Bare `\s` is ASCII-only
under PCRE and will silently skip those rows.

**Why:** During the 138-strip-course-objectives migration, the first
draft regex matched 192/234 rows. The 42 misses all turned out to
have `<strong>Course objectives\xe2\x80\xaf</strong>` — the trailing
U+202F before `</strong>` defeated the `\s*</strong>` tail. A hex
dump of [migrations/138-strip-course-objectives-and-disclaimer.sql](migrations/138-strip-course-objectives-and-disclaimer.sql)
generator output proved it. Failing to handle this would have left a
"Course objectives" heading visible on the affected SKUs (e.g. AZ-500
Microsoft Azure Security Technologies, vid 136109).

**How to apply:** When writing PCRE against EAV text columns, define a
whitespace token like
`$WS = '(?:\s|&nbsp;|\x{00A0}|\x{2007}|\x{202F})';` and use it with
the `/u` (Unicode) modifier in every place you'd normally write `\s*`
or `\s+`. Also widen the title alternative if the section name may
have been pasted with Unicode dashes or curly quotes. After running,
verify by re-querying for the literal marker text — if any row still
contains the section header markup, suspect another invisible
codepoint and hex-dump the offending region with
`for ($i=0;$i<strlen($f);$i++) printf('%02x ', ord($f[$i]));`.
