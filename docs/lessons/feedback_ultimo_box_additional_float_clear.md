---
name: ultimo-box-additional-float-clear
description: Ultimo product-view tabs container (.box-additional.grid12-8) clear policy — pick based on which column is currently tallest; clear:both leaves a gap under shorter columns, clear:none lets tabs rise into the gap
metadata:
  node_type: memory
  type: feedback
  originSessionId: 089e3fb3-1b18-476a-9a29-85c162b163d2
---

The lower `.box-additional.grid12-8` (Course Details / Course Info /
Job Roles / Trainers / Review tabs) sits after `</form>` and floats
left at 66% width. There is no clearfix on the form, so the three
inner `.grid12-4` floats (img / primary / secondary) leak. The clear
rule on `.product-view > .box-additional` chooses one of two tradeoffs:

- `clear: both` — tabs always drop below the tallest column. Safe
  layout-wise but leaves a tall empty band under the two shorter
  columns when one column dominates.
- `clear: none` — tabs slide up into the gap beside whichever column
  is tallest. Closes the gap, but the tabs visually overlap the
  bottom of the tall column's territory.

**Why:** The "tallest column" has flipped over time. Originally the
left/image column became tallest after we stacked Course Information /
Post-Course Support cards there, so tabs would slide up beside the
short right column (looked like tabs were injected into column 2).
Fix at the time: `clear: both`. Later the booking right-column grew
taller (sticky card + extras) while the left+center shortened, so
`clear: both` then left a huge gap below left+center — switched to
`clear: none` on 2026-05-24. Then the cms/block migration added more
content to the Certification card (Pearson Vue paragraphs, per-course
External Certification copy, etc.), pushing the left+center stack
taller than the right column again. `clear: none` started displacing
the tabs to the right of the right column. Flipped back to `clear:
both` on 2026-05-25. Then on 2026-05-25 (later same day) the right
booking sidebar regained dominance on most product pages, leaving a
large empty gap above the tabs under the shorter left+center stack —
flipped back to `clear: none`.

**How to apply:** Before changing this rule, check which column is
currently tallest on a representative product page (e.g.
[/vibe-coding-for-multi-agent-ai-systems.html](https://www.tertiarycourses.com.my/vibe-coding-for-multi-agent-ai-systems.html)).
If the right secondary column is dominant → `clear: none` (tabs rise
beside it). If the left/image column is dominant → `clear: both`
(otherwise tabs slide into column 2). The rule lives at
[skin/frontend/ultimo/default/css/custom.css:471](skin/frontend/ultimo/default/css/custom.css#L471).
Do NOT add `clear` to the inner columns themselves — they must remain
floated for the three-column layout.
