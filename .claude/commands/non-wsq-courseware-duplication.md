---
description: Duplicate an existing WSQ course's courseware (PPT, Lesson Plan, Learner Guide, labs/activities) into its NON-WSQ twin — strip the WSQ layer, retime the day to 9:30am–5:30pm, retitle/recode to the non-WSQ course, then push to GitHub, Google Drive and the storefront LMS.
argument-hint: "<WSQ title>" <TGS-code> "<non-WSQ title>" <C-code>
allowed-tools: Bash, Read, Edit, Write, Grep, Glob, AskUserQuestion, Skill
---

# /non-wsq-courseware-duplication — copy WSQ courseware into a non-WSQ course

Replicate a **built** WSQ courseware set as its non-WSQ (C-prefix) twin, then publish it.

**Arguments:** `$ARGUMENTS` — WSQ course title, WSQ course code (`TGS-…`), non-WSQ course title, non-WSQ course code (`C…`).

Load the **`wsq-to-non-wsq`** skill and follow it — it owns the conversion mechanics
(`scripts/convert_deck.py`, `scripts/convert_docs.py`, `scripts/renumber_toc_pages.py`,
`scripts/verify.py`), the read-only-source safety rules and the hard-won gotchas.
This command is the *end-to-end run sheet* around that skill: what to copy, what to
change, and where to publish.

## 0. Collect the inputs — never guess

Ask (AskUserQuestion) and stop for anything missing:

| Input | Needed for |
|---|---|
| WSQ course title + `TGS-` code | source identification |
| non-WSQ course title + `C` code | retitle / recode |
| WSQ source repo URL | cloning `source-wsq/` |
| **non-WSQ GitHub repo URL** | `/github-push-course` |
| **Google Drive courseware folder link** | `/non-wsq-gdrive-push` |
| non-WSQ product page URL on tertiarycourses.com.sg | labs README link rewrite |
| **WSQ product page URL** (the `/wsq-…html` twin) | the funding block's redirect target (§8) |

Do not invent a repo URL, a Drive folder or a product slug. A wrong Drive folder
silently republishes over another course.

**Inspect the Drive folder as soon as you have the link** — don't wait until §7.2.
List its subfolders and note which of the five (Trainer Slides, Learner Slides,
Learner Guide, Lesson Plan, Activities) are missing and which already hold another
course's files. Both shape the run: missing folders must be created and filled, and a
foreign course's files mean you stop and confirm before swapping.

## 1. Copy ONLY these four artifacts

Copy from the WSQ source: the **slide deck (PPT)**, the **Lesson Plan (LP)**, the
**Learner Guide (LG)** and the **labs / activities**. Nothing else.

**Never copy** the assessment set — WA, PP, case study, marking guides, answer keys.
A non-WSQ course has no assessment. If `assessment/` exists in the source, leave it
behind; it must never reach the new repo, Drive or the LMS.

**Drop ALL funding content — no exceptions.** A non-WSQ course carries no funding, so
the courseware must contain none: no SkillsFuture, WSQ funding, subsidy, grant or
scheme names, and no funding *placeholders* either. This catches people out because
the funding often sits in ordinary teaching material rather than in a WSQ-branded
slide — a marketing course's prompt template with
`Funding: [E.G. UP TO 70% WSQ FUNDING, SKILLSFUTURE CREDIT ELIGIBLE]`, or a "verify
your funding claims" note. Remove the funding field, rule or sentence and keep the
surrounding lesson; genericise only where the teaching point is about regulated claims
generally (`trust signal`, `credential`), never by swapping one scheme name for
another. The `scan_prohibited.py` scan flags every one of these and will block the
push until they are gone. The **only** place funding may appear is the storefront
Funding block, which redirects to the WSQ twin — see §8.

The WSQ repo is **read-only input**. Clone it to `source-wsq/`, add `source-wsq/` to
the new repo's `.gitignore`, never commit/edit inside it, and confirm
`git -C source-wsq status --short` prints nothing before and after the run.

## 2. The PPT — strip the WSQ layer

Run `convert_deck.py` per the skill. `--inspect` **first**, every time: confirm the
WSQ slide indexes against this deck's own dump — they differ per course, and
hard-coding another course's indexes silently deletes real content.

Remove entirely:

- WSQ-branded slides (cover eyebrow, WSQ/SSG/SkillsFuture/funding, TGS reference)
- **Assessment** slides — Briefing for Assessment, Assessment & Funding, Assessment
  Flow, Courseware & Assessment on the LMS
- **Learning Outcomes** slide (WSQ competency framing) — but see §6: it **stays** in
  the Lesson Plan
- **TRAQOM** survey — rewritten in place into the **Course Feedback** slide (rewrite
  the existing shape's text; never `add_slide()`)
- Digital attendance (AM/PM/Assessment QR), the 75%-attendance funding rule, the TSC
  code badge

Then retitle/recode, renumber the static footer page numbers, and re-verify.

## 3. The LP and LG — retime to 9:30am – 5:30pm

**The house figure is fixed: 9:30am – 5:30pm, 7.5 instructional hours per day — so
7.5 hrs for a 1-day course and 15 hrs for a 2-day course.** Do not derive a different
daily total from the WSQ parent or from break arithmetic; set the day headings,
`Day total:` lines and the repo README to this figure and make the schedule rows fit
it. 7.5 teaching hours inside a 480-minute day leaves only **30 minutes of break** —
one 30-minute lunch and no separate tea breaks — so the WSQ parent's 60-min lunch plus
two 15-min teas must be rewritten, not carried over. Carrying them over silently
yields 6.5 h/day (13 hrs over two days) and contradicts the storefront.

**Then confirm the non-WSQ course's DAY COUNT against the storefront — it is often
shorter than the WSQ parent.** The WSQ course is usually 2 days; its non-WSQ twin is
frequently **1 day** at a lower fee. Read the live product page before retiming:

```bash
curl -sS "https://www.tertiarycourses.com.sg/<slug>.html" \
  | grep -oE "[0-9]+-day|[0-9]+ day|\$[0-9,]+\.[0-9]{2}" | sort -u
```

A `$350` fee at the standard `$350/day` rate means **one day**, whatever the WSQ
source says. Ask the user which topics the shorter day covers (compress all of them,
or drop the later topics) — don't silently ship the WSQ day count. When it collapses
to one day, the LP loses its second schedule table, its `Day 2` heading **and** the
`Day 2` TOC entry, the deck's outline slide becomes `Course Outline — 1 Day` with the
Day 1 / Day 2 cards rebuilt as **Morning / Afternoon**, and every "two-day" phrase in
the LP overview and the repo README becomes "one-day". Incident: C11 (2026-09-19)
shipped a 2-day LP for a 1-day course because the WSQ parent's structure was inherited
unquestioned.

Copy both, then apply:

1. **Retime every schedule row and heading to a 9:30am–5:30pm day.** The WSQ day runs
   9:30am–6:30pm including the assessment block; the non-WSQ day ends at 5:30pm.
   The converter's built-in rule only covers the older `9:00 AM – 6:00 PM` form, so
   pass the retiming explicitly, e.g.:
   ```
   --sub "9:30 AM – 6:30 PM=>9:30 AM – 5:30 PM"
   --sub "9:30am – 6:30pm=>9:30am – 5:30pm"
   --sub "6:30 PM=>5:30 PM"
   ```
   Grep the source LP/LG for every time literal first (`grep -o '[0-9]\{1,2\}[:.][0-9]\{2\} *[APap][Mm]'`)
   and cover each form you find — including the table cells, which are separate from
   the prose.

   **If that grep returns nothing, the LP is hour-based, not clock-based** — newer
   generators schedule by duration (`4 hours`, `Day total: 8 hours`, a `Time` column
   whose cells read `4 hours` / `Guided practice`) and contain no `6:30pm` to
   substitute. `--sub` retiming then silently does nothing. Handle it directly:
   - **Every non-WSQ LP is presented as 9:30am – 5:30pm regardless**, so rewrite the
     day headings to `Day N · 9:30am – 5:30pm` and each `Day total:` line to
     `7.5 instructional hours (9:30am – 5:30pm).` even though the source never stated
     a clock time.
   - **Reconcile the hours against the 7.5 h/day house figure** (the storefront should
     already agree — `Duration 15 hrs`, `9:30am - 5:30pm` for a 2-day course; if it
     does not, flag the product page rather than bending the LP). The WSQ topic hours
     will exceed it by roughly the assessment block. Adjust the per-topic `Time` cells
     until they sum to 450 min/day, and make the day totals agree.
   - **Which topic gives up the time is a judgement call — ask.** Topics are usually
     equal-weight (same mechanism and lab counts), so there is no correct answer in
     the data. Offer concrete splits with their day totals and let the user pick.
2. **Remove the assessment** — the assessment rows in the schedule table, the
   Assessment and Evidence Plan section, marking guides, and sentence-level
   references buried inside otherwise-useful paragraphs (drop the sentence, keep the
   paragraph).
3. **Reallocate the freed time** into lab/practice/recap so each day still totals its
   instructional hours and the last row lands on 5:30pm. If the arithmetic does not
   close, **ask the user** whether the day shortens or teaching expands — do not
   silently leave a gap.
4. Retitle, recode, remap slide references through the kept-slide map, and rerun
   `renumber_toc_pages.py` (Word's TOC is a field and will not refresh itself).

## 4. The labs / activities

Copy the `labs/` tree. Rewrite the course name, the course code, the repo URL and the
**product URL** in `labs/README.md`, `labs/CLAUDE.md`, `labs/course-activities.md` and
any lab that cites them. The WSQ product URL (`/wsq-<slug>.html`) must be repointed at
the non-WSQ product page — ask for that URL, don't invent the slug.

**Rebuild every lab PDF that sits beside a rewritten `.md`.** Lab folders commonly ship
a `.pdf` next to each `.md` (README, prompts, evidence-template, story-assets). Editing
only the Markdown leaves those PDFs carrying the **WSQ course code**, and they are what
the learner actually opens. `verify.py` reads Markdown, so the stale PDFs pass the scan
silently. Regenerate each one and re-check:

```bash
for md in $(find labs -name '*.md'); do
  [ -f "${md%.md}.pdf" ] || continue
  soffice --headless --convert-to pdf:writer_pdf_Export "$md" --outdir "$(dirname "$md")" >/dev/null 2>&1
done
for f in $(find labs -name '*.pdf'); do pdftotext "$f" - | grep -l 'TGS-' >/dev/null && echo "STALE: $f"; done
```

Also fix the **version string inside the labs** (`· <code> · v2.0`) before rebuilding —
it is not the course code, so the code rewrite misses it.

## 5. Verify before publishing — both scans must pass

```bash
python3 ~/.claude/skills/wsq-to-non-wsq/scripts/verify.py \
  --old-code <TGS-code> --old-title "<WSQ title>"
python3 ~/.claude/skills/non-wsq-courseware-qa/scan_prohibited.py .
```

**Scan the repo README too — the QA scan does not.** `scan_prohibited.py` reads
courseware artifacts, so a root `README.md` copied from the WSQ repo keeps its
`| Programme | WSQ |` row, its `16 hours, plus 2 hours of assessment` duration and,
worst of all, a `| Funding | Up to 70% course-fee funding… |` row — the funding content
§1 forbids. Strip those rows and set the duration to the storefront figure before
committing.

**Verify the feedback slide by its shapes, not the converter's exit code.**
`--feedback-slide` may rewrite only the subtitle and leave the eyebrow (`TRAQOM`) and
all three card bodies (`AM` / `PM` / `ASSESSMENT` → "Record assessment attendance")
intact. Dump the slide's shapes after converting and rewrite each remaining one in
place, writing through `paragraph.runs[0]` and blanking the trailing runs so the card
fonts survive.

Then export PDFs (**one `soffice` invocation per file** — a mixed Impress/Writer run
converts only some) and **look at the pixels** — render the cover, the rewritten
feedback slide, the retimed schedule table and any slide whose text changed:

```bash
pdftoppm -png -r 60 -f 1 -l 1 courseware/<deck>.pdf /tmp/cover
```

A text-only check is not sufficient: rewriting a shape's text can collapse paragraphs
and shift a card. Check specifically that no schedule row still reads 6:30pm and that
no assessment row survived — **PPT and DOCX tables are invisible to text-frame
passes** and are the single easiest place to leave WSQ content behind.

Do not proceed to §6 on a failing scan.

## 6. Judgement calls — ask, don't guess

- A slide mixing course content with funding content.
- **"Learning Outcomes"** — remove from the **deck**, keep in the **Lesson Plan**.
- The schedule not closing on 5:30pm after the assessment block is removed.

The destination GitHub repo holding a different course is **not** a judgement call —
the conversion always replaces `main`. See §7.1.

## 7. Publish — in this order

Run each only after the previous one succeeds.

1. **`/github-push-course <non-WSQ repo URL>`** — writes the courseware README
   (hero + registration link, outcomes, topics/labs, repo structure), sets the repo
   About, and excludes `assessment/` and `source-wsq/`. Point `origin` at the
   **non-WSQ repo**, confirm with `git remote -v` — never the TGS remote — before the
   first push.

   **Always replace `main`.** This conversion is the authoritative courseware for the
   course, so whatever is on `main` — an older copy, or a different course built
   independently by `non-wsq-courseware-build` under the same code — is superseded.
   Don't branch, don't ask which wins, don't open a PR. Read the remote first
   (`git log --oneline origin/main`, `git ls-tree -r --name-only origin/main`) so the
   swap is recorded and the lease has a SHA, then push with
   `--force-with-lease=main:<verified-remote-sha>` — never a bare `--force`, so a
   concurrent push aborts instead of being clobbered. Say in the final report what was
   replaced.
2. **`/non-wsq-gdrive-push <Drive courseware folder link>`** — dry-run first, then push.

   **All five folders must exist, and every one must have an `archive/`.** The five are
   **Trainer Slides, Learner Slides, Learner Guide, Lesson Plan and Activities**. The
   destination is a *replacement*, so this is a precondition of the push, not a
   nice-to-have — work through it before you upload:

   **a. Inventory the destination first.** List what the Drive root actually holds and
   compare against the five:
   ```bash
   rclone lsd gdrive: --drive-root-folder-id <FOLDER_ID>
   ```
   Name each folder as **present** or **missing**. Do not assume the set is complete
   because the last course had it — partner/legacy course folders routinely ship with
   three of the five.

   **b. Create every missing folder — never skip the artifact.** A missing folder means
   the LMS record ends up short a link, which is the failure this step exists to
   prevent. Create it (the pusher does this automatically, and `--dry-run` prints
   `(will be created)`), or by hand:
   ```bash
   rclone mkdir "gdrive:<Folder Name>"        --drive-root-folder-id <FOLDER_ID>
   rclone mkdir "gdrive:<Folder Name>/archive" --drive-root-folder-id <FOLDER_ID>
   ```
   Then upload the matching artifact into it. Never leave a folder uncreated and the
   field blank.

   **c. Every folder gets a lowercase `archive/` — including the ones you are not
   replacing.** Every pre-existing file that is not byte-identical to an incoming one
   is **moved** into it. Nothing on Drive is ever deleted. The pusher creates
   `archive/` on first push, renames an `Archive`/`archives` variant to canonical
   lowercase, and merges an `old versions/`-style folder into it. **Confirm an
   `archive/` line appears in the dry-run plan for every folder that holds old files**
   — if one is missing, create it rather than uploading alongside the stale copy.

   **d. Activities is additive by default — pass `--mirror`.** This conversion
   *replaces* the course, so the retired labs must move into `Activities/archive/`;
   otherwise the previous course's labs sit beside the new ones and learners cannot
   tell which set is current. Only stay additive when the trainer keeps
   datasets/templates there, and then archive the old labs by hand.

   **e. Archive by file ID.** Drive allows duplicate filenames, so matching by name
   alone silently moves only the first. Moving many files: use `rclone moveto`
   (server-side, self-refreshing token), not raw Drive API `PATCH …?addParents=`
   loops, which hit 403 `rateLimitExceeded` and then 401 mid-run.

   **f. Read the dry-run plan before pushing.** If a destination folder holds a
   *different* course's files, stop and confirm with the user — the archive is
   recoverable, but the swap must be deliberate.

   **Verify after the push**: re-list the root and confirm all five folders exist, each
   has an `archive/`, and the new artifacts are in place. No assessment is ever
   uploaded.

3. **`/non-wsq-lms-push <C-code>`** — writes the Drive links onto the storefront course
   record. Dry-run first; never write a blank over a good link.

   All five fields — Trainer Slides, Learner Slides, Lesson Plan, Learner Guide and
   Activities — must resolve, because §7.2b guaranteed every folder exists and holds
   its artifact. If the dry run still shows a field unresolved, go back and fix Drive
   (create the folder, upload the artifact, re-run the Drive push so the link
   resolves) — do **not** push a short record. A field whose Drive file does not exist
   must be **reported**, never written blank over a good value.

4. **`/non-wsq-schedule <C-code>`** — put the course on the **counterpart schedule
   option template** of its WSQ parent, so both intakes sit on the same slot in the
   training calendar. **Run this on every conversion, never only on request** — read
   both templates from the DB and confirm the codes match even when you have no
   reason to suspect a mismatch. A recycled product entity keeps the *retired*
   course's template, so a freshly converted course routinely starts on the wrong
   one while looking completely finished.

   **The non-WSQ course's schedule option template must match the WSQ course's
   schedule option template.** These are the storefront custom-option templates that
   carry the class dates — the WSQ catalogue prefixes every template `(SG) WSQ-`, the
   non-WSQ catalogue uses the bare code:

   ```
   WSQ course on  "(SG) WSQ-A08 Wed/Sat 2nd wk"
   non-WSQ goes on          "A08 Wed/Sun 2nd wk"
   ```

   **Match on the template CODE, never the weekday names** — `WSQ-A08` is Wed/**Sat**
   while non-WSQ `A08` is Wed/**Sun**, deliberately, so matching on days lands the
   course on the wrong template. The `non-wsq-schedule` skill owns the full rule, the
   code table and the switching mechanics; follow it rather than editing options here.

   **Never do this in SQL.** `custom_options_relation` is per-`option_id`, so a
   DELETE+INSERT wipes the schedule and leaves duplicate orphan options — it is a
   CODE path only. See memory `feedback_schedule_template_switch_never_in_sql`.

   A conversion that ships courseware but leaves the course on its old (or a
   mismatched) template is incomplete — the learner sees class dates that do not line
   up with the WSQ intake.

## 8. Point the course's Funding block at the WSQ twin

A non-WSQ course carries **no funding of its own**, but the learner reading its page is
often exactly the person who should be told the funded WSQ version exists. So the
non-WSQ product page's Funding block **redirects to the WSQ course it was duplicated
from** — which this conversion always has, by definition.

Mechanism (SG production only — partner sites have no WSQ twin):

- The block is a cms/block with identifier **`course_C###_funding_and_grant`**.
- Ship it as an **idempotent content-only** `migrations/NNN-*.sql`:
  ```sql
  UPDATE cms_block
     SET content = '<... link to the WSQ course ...>'
   WHERE identifier = 'course_C###_funding_and_grant';
  ```
- **NEVER `->save()` a cms/block model** — it wipes the `cms_block_store` mapping and
  404s the page. A content-only SQL `UPDATE` is the only safe form. See memory
  `feedback_cms_model_save_wipes_store_mapping`.
- Link to the **WSQ product page** (`/wsq-<slug>.html`) — the `TGS-` twin named in §0.
  Use "IBF funding" wording instead when the funded twin is an IBF course.
- **Validate the target returns 200** on `www.tertiarycourses.com.sg` before shipping;
  a funding block pointing at a 404 is worse than no block.
- The block is keyed by `C###`, so confirm the identifier exists first — if the course
  has no funding block yet, create it rather than silently skipping the step.

Follow the repo `CLAUDE.md` pre-push verification (migration dry-run via the real
`apply.php`) before pushing.

Report at the end: the four artifacts produced, the WSQ content removed, the retiming
applied, both scan results, the four publish targets with their links (GitHub, Drive,
LMS, schedule template), the schedule option template the course now sits on and the
WSQ template it matches, and the funding block's redirect target.
