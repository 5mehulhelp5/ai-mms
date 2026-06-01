# Lessons / hard-won knowledge

Field notes on the non-obvious traps in this OpenMage 1.x LMS — the kind of bug
where the fix is obvious *once you know the cause* but the cause is invisible
(a cache layer, an indexer, a theme override, a hidden ACL, an env quirk).

**Index:** see [MEMORY.md](MEMORY.md).

## How to use

- **Before** touching code in an area, scan `MEMORY.md` for matching entries.
  If a memory contradicts what the code seems to show, verify against current
  code — these are point-in-time observations, not live state.
- **After** any non-obvious fix (i.e. the surprise came from invisible
  behaviour, not a syntax/logic bug visible in the diff), add a new
  `feedback_*.md` file capturing:
  - The rule (what to do or avoid)
  - **Why:** the concrete incident or constraint that justifies the rule
  - **How to apply:** when it kicks in + a file:line that demonstrates the
    working pattern.
- Then add a one-line pointer to `MEMORY.md` under the matching section.

## File naming

- `feedback_<slug>.md` — rules / lessons learned.
- `reference_<slug>.md` — pointers to "the live file is actually X, not the
  decoy Y" kind of facts.

Cross-link related lessons with `[[other-slug]]`.

## Mirror

This folder is mirrored from each developer's local Claude Code memory at
`~/.claude/projects/-Users-alfredang-projects-tertiary-ai-mms/memory/`.
When you add a lesson here, also drop a copy in your local memory dir so
your own Claude sessions pick it up automatically. (We may automate this
later.)
