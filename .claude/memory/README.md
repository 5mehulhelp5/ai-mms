# Project memory — shared lessons learned

This directory is a **shared snapshot** of the project's accumulated
"don't repeat this mistake" notebook. Each file captures a non-obvious
bug, gotcha, or convention that bit us at least once, with:

- The rule (what to do or avoid)
- **Why:** the concrete incident or constraint that justifies the rule
- **How to apply:** when this rule kicks in, plus the working
  file:line that demonstrates it

`MEMORY.md` is the one-line index — scan it first.

## How this gets used

Claude Code sessions in this repo automatically load `MEMORY.md` into
context (see [CLAUDE.md](../../CLAUDE.md)'s "Self-improvement journal"
section), so every future session — anyone's, on any machine — starts
already aware of these landmines.

Team members working without Claude can still read these files as a
plain-English field notebook: each one names a concrete file/line so
you can jump straight to the working code.

## How to add an entry

After fixing a non-obvious bug (anything where the surprise came from
invisible behavior — cache layer, indexer, theme override, hidden ACL,
gateway quirk — rather than from a syntax error visible in the diff):

1. Add `feedback_<short-slug>.md` here with the rule + Why + How to apply.
2. Add a one-line pointer at the bottom of `MEMORY.md`.
3. Commit + push.

Keep entries terse — one screen each. The audience is "future you at
2am" or a teammate hitting the same wall next quarter.

## Source of truth

The canonical copy lives in each developer's personal Claude memory dir
(`~/.claude/projects/-Users-*-ai-mms/memory/`). This `.claude/memory/`
directory is the shared mirror, kept in sync with periodic copy-overs.
If you edit files here, also update your personal copy (and vice
versa) so the next session you start picks up your changes.
