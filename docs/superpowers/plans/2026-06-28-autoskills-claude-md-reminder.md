# autoskills CLAUDE.md Reminder — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** After autoskills recommends skills for a repo, offer to write an idempotent, auto-maintained block into that repo's `CLAUDE.md` so future agent sessions are reminded to use those skills.

**Architecture:** Add a conditional, consent-gated **Step 8** to `SKILL.md`, documented in a new `references/claude-md.md`. The only piece with real logic — the idempotent merge into an existing `CLAUDE.md` — is an optional, dependency-free Node helper (`scripts/upsert-claude-md.mjs`) that owns the markers and is verified by a behavioral test. Build in the dev repo, then redeploy to `~/.claude/skills/autoskills/`.

**Tech Stack:** Markdown (SKILL.md + reference), Node.js (one optional helper, no npm deps), Bash tests.

## Global Constraints

- Skill name is exactly `autoskills`. Two locations: **dev** = your local clone (`<repo-root>/`); **runtime** = `~/.claude/skills/autoskills/`. Build in dev (Tasks 1–3), deploy in Task 4.
- The helper script is **optional**: the skill must work fully without it (manual Read→Edit fallback documented in the reference).
- Block markers are exactly `<!-- BEGIN autoskills -->` and `<!-- END autoskills -->`. Content outside the markers is NEVER modified.
- **Consent gate:** the skill prints the exact block + target path, then STOPS and waits for explicit confirmation before any Write/Edit/script run.
- Never write `unsynced`/unavailable catalog names into `CLAUDE.md` — only Strong/Decent, usable skills.
- Dates in any written content use the session's current date (today: 2026-06-28); do not invent dates.
- Git author = the repo's configured git identity; never use "CLAUDE". This repo uses **no** `Co-Authored-By` trailer — match it.
- Branch: `feat/autoskills-claude-md-reminder` (already created).

---

### Task 1: Idempotent `upsert-claude-md.mjs` helper (behavioral TDD)

**Files:**
- Create: `scripts/upsert-claude-md.mjs`
- Test: `tests/test-upsert-claude-md.sh`

**Interfaces:**
- Consumes: nothing (reads target `CLAUDE.md` from disk; block content from stdin).
- Produces: CLI `node scripts/upsert-claude-md.mjs <target-path>` reading inner block content from **stdin**, wrapping it in `<!-- BEGIN autoskills -->`/`<!-- END autoskills -->`, and upserting into `<target-path>`. Prints `created|updated|appended <path>` to stderr. Idempotent.

- [ ] **Step 1: Write the failing test**

Create `tests/test-upsert-claude-md.sh`:
```bash
#!/usr/bin/env bash
set -e
script="scripts/upsert-claude-md.mjs"
tmp=$(mktemp -d)

# Case 1: create when file is absent
f="$tmp/CLAUDE.md"
printf 'ALPHA' | node "$script" "$f"
grep -q "BEGIN autoskills" "$f"
grep -q "END autoskills" "$f"
grep -q "ALPHA" "$f"

# Case 2: in-place replace when markers present (old content gone, exactly one marker pair)
printf 'BRAVO' | node "$script" "$f"
grep -q "BRAVO" "$f"
! grep -q "ALPHA" "$f"
[ "$(grep -c 'BEGIN autoskills' "$f")" = "1" ]

# Case 3: append, preserving user content, when no markers present
g="$tmp/USER.md"
printf '# My Project\nuser stuff\n' > "$g"
printf 'CHARLIE' | node "$script" "$g"
grep -q "My Project" "$g"
grep -q "user stuff" "$g"
grep -q "CHARLIE" "$g"
grep -q "BEGIN autoskills" "$g"

# Case 4: idempotency — identical input twice yields a byte-identical file
h="$tmp/IDEM.md"
printf 'DELTA' | node "$script" "$h"
cp "$h" "$h.first"
printf 'DELTA' | node "$script" "$h"
diff "$h.first" "$h"
[ "$(grep -c 'BEGIN autoskills' "$h")" = "1" ]

rm -rf "$tmp"
echo "PASS test-upsert-claude-md"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test-upsert-claude-md.sh`
Expected: FAIL (`Cannot find module .../upsert-claude-md.mjs`).

- [ ] **Step 3: Write `scripts/upsert-claude-md.mjs`**

Create `scripts/upsert-claude-md.mjs`:
```javascript
#!/usr/bin/env node
// Idempotently upserts an autoskills-maintained block into a target CLAUDE.md.
// Inner block content is read from stdin; THIS script owns the BEGIN/END markers
// so they can never drift. Content outside the markers is never modified.
// Usage: node upsert-claude-md.mjs <target-CLAUDE.md-path>   < block-content
import { readFileSync, writeFileSync, existsSync } from 'node:fs';

const BEGIN = '<!-- BEGIN autoskills -->';
const END = '<!-- END autoskills -->';

const target = process.argv[2];
if (!target) {
  console.error('usage: node upsert-claude-md.mjs <target-CLAUDE.md-path> < block-content');
  process.exit(2);
}

const inner = readFileSync(0, 'utf8').trim();   // fd 0 = stdin
const block = `${BEGIN}\n${inner}\n${END}`;

let action;
if (!existsSync(target)) {
  writeFileSync(target, block + '\n');
  action = 'created';
} else {
  const text = readFileSync(target, 'utf8');
  const b = text.indexOf(BEGIN);
  const e = text.indexOf(END);
  if (b !== -1 && e !== -1 && e > b) {
    writeFileSync(target, text.slice(0, b) + block + text.slice(e + END.length));
    action = 'updated';
  } else {
    writeFileSync(target, text.replace(/\s*$/, '') + '\n\n' + block + '\n');
    action = 'appended';
  }
}
console.error(`${action} ${target}`);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test-upsert-claude-md.sh`
Expected: `PASS test-upsert-claude-md`.

- [ ] **Step 5: Commit**

```bash
git add scripts/upsert-claude-md.mjs tests/test-upsert-claude-md.sh
git commit -m "feat: add idempotent CLAUDE.md block upsert helper"
```

---

### Task 2: `references/claude-md.md` reference + doc-presence test

**Files:**
- Create: `references/claude-md.md`
- Test: `tests/check-claude-md.sh`

**Interfaces:**
- Consumes: `scripts/upsert-claude-md.mjs` (Task 1) — references it as the optional merge mechanism.
- Produces: the Step 8 procedure SKILL.md depends on — location resolution, markers, merge cases, content template (Use-directly vs Install-first split), consent flow.

- [ ] **Step 1: Write the failing test**

Create `tests/check-claude-md.sh`:
```bash
#!/usr/bin/env bash
set -e
f="references/claude-md.md"
grep -q "BEGIN autoskills" "$f"
grep -q "END autoskills" "$f"
grep -qi "rev-parse --show-toplevel" "$f"      # location resolution
grep -qi "STOP" "$f"                            # consent gate
grep -qi "Use directly" "$f"                    # template split (invokable now)
grep -qi "Install first" "$f"                   # template split (online, uninstalled)
grep -q "upsert-claude-md.mjs" "$f"             # optional helper referenced
echo "PASS check-claude-md"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/check-claude-md.sh`
Expected: FAIL (`references/claude-md.md: No such file or directory`).

- [ ] **Step 3: Write `references/claude-md.md`**

Create `references/claude-md.md`:
````markdown
# Repo-local skill reminder (`CLAUDE.md`) — Step 8 procedure

After recommending skills, persist a repo-local reminder so future agent sessions in that repo are nudged to use them. Claude Code auto-loads `CLAUDE.md` from the project root at session start.

## When to offer (gate)
Offer ONLY when BOTH hold:
1. A concrete repo/folder is in play — folder-scan mode (2) OR current-task work inside a project.
2. At least one **Strong** or **Decent** skill was recommended.
Skip for abstract problem-description queries with no repo. Never include `unsynced`/unavailable catalog names.

## 1. Resolve the target (root, never a subfolder)
- **Folder-scan mode:** the scanned folder (its git toplevel if it is a repo).
- **Current-task work:** `git rev-parse --show-toplevel`. If that fails (not a git repo), fall back to the current working directory.
- If cwd is a subdirectory of a repo, `git rev-parse --show-toplevel` already returns the repo root — write there.
- Target = `<resolved-root>/CLAUDE.md`.

## 2. Build the block content
Distinguish skills usable NOW from online skills that must be installed first — otherwise the next agent reads "use skill X", can't find X, and is stuck.

Template (inner content; the markers are added for you by the helper / shown below for the manual path):
```markdown
<!-- Maintained by the autoskills skill. Edits between these markers may be overwritten on the next run. -->
## Recommended skills for this project (autoskills)

Detected domain(s): <domain list>. Use these skills proactively — don't wait to be asked.

**Use directly (already invokable):**
- `<skill-name>` — <use-when>

**Install first, then use** (online, not yet installed):
- `<owner/repo@skill>` — <use-when> · install: `npx skills add <owner/repo@skill> -g -y`

Full problem→skill history: consult `~/.claude/skills/autoskills/registry/`.

_Last updated by autoskills: <session-date>._
```
Rules:
- Registry/local **invokable** skill (usable via the `Skill` tool now) → **Use directly**.
- **Online** skill → **Install first** — UNLESS the user accepted its install in Step 6, then it is invokable and moves to **Use directly**.
- Omit the **Install first** subsection entirely if there are no uninstalled online recommendations.
- Only Strong/Decent skills. Date = session's current date.

## 3. Offer, then STOP (consent gate)
Print the exact block and the resolved target path, then **STOP and wait for explicit confirmation**. Do NOT run any Write/Edit/script before the user says yes. On decline, skip — the Step 7 registry/memory recording still stands.

## 4. Upsert on confirm
Markers (exact): `<!-- BEGIN autoskills -->` … `<!-- END autoskills -->`.

**Preferred — deterministic helper** (it owns the markers; reads inner content from stdin):
```bash
node ~/.claude/skills/autoskills/scripts/upsert-claude-md.mjs <root>/CLAUDE.md  < block-content
```

**Manual fallback (no script).** Read the target first, then:
- **File absent:** create `CLAUDE.md` containing `<!-- BEGIN autoskills -->\n<inner>\n<!-- END autoskills -->`.
- **Markers present:** copy the current `BEGIN…END` block **verbatim** from what you Read as the Edit `old_string`, and replace it with the new block. Never reconstruct it from memory.
- **No markers:** append the block after the existing content (preserve everything already there).

Report what changed (`created` / `updated in place` / `appended`).

## Merge cases (summary)
| Case | Action |
|---|---|
| File absent | Create with the block only. |
| Markers present | Replace `BEGIN…END` inclusive; preserve everything outside. |
| File exists, no markers | Append the block; preserve existing content. |

Running twice with identical input yields a byte-identical file (idempotent).
````

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/check-claude-md.sh`
Expected: `PASS check-claude-md`.

- [ ] **Step 5: Commit**

```bash
git add references/claude-md.md tests/check-claude-md.sh
git commit -m "feat: add CLAUDE.md reminder reference and doc-presence test"
```

---

### Task 3: Wire Step 8 into `SKILL.md` + integration test

**Files:**
- Modify: `SKILL.md` (insert Step 8 after Step 7; extend the Reference files list)
- Modify: `tests/check-integration.sh` (add new files to must-exist; run new tests; assert Step 8 wired)

**Interfaces:**
- Consumes: `references/claude-md.md` (Task 2), `scripts/upsert-claude-md.mjs` (Task 1).
- Produces: the live Step 8 in the workflow; an integration check that all cross-references resolve.

- [ ] **Step 1: Write the failing test (update integration check first)**

Replace the entire contents of `tests/check-integration.sh` with:
```bash
#!/usr/bin/env bash
set -e
# every file SKILL.md references must exist
for ref in references/evaluation.md references/registry-format.md references/folder-scan.md references/claude-md.md scripts/index-local-skills.mjs scripts/upsert-claude-md.mjs registry/INDEX.md registry/skillmap-research.md; do
  test -f "$ref" || { echo "MISSING $ref"; exit 1; }
done
# supersede note present
grep -qi "find-skills" SKILL.md
# Step 8 (CLAUDE.md reminder) wired in
grep -q "Step 8" SKILL.md
grep -q "references/claude-md.md" SKILL.md
# all per-file checks still pass
for t in check-skill-md check-evaluation check-registry check-folder-scan check-claude-md; do bash "tests/$t.sh" >/dev/null; done
bash tests/test-index-local-skills.sh >/dev/null
bash tests/test-upsert-claude-md.sh >/dev/null
echo "PASS check-integration"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/check-integration.sh`
Expected: FAIL on `grep -q "Step 8" SKILL.md` (Step 8 not in SKILL.md yet).

- [ ] **Step 3: Add Step 8 to `SKILL.md`**

In `SKILL.md`, insert the following block immediately AFTER the Step 7 block (after the line ending `(Create the project `memory/` + `MEMORY.md` if absent.)`) and BEFORE the `## Reference files` heading:

```markdown
## Step 8 — Offer a repo-local skill reminder (CLAUDE.md)
**Only when** (a) input mode is folder-scan or current-task work inside a project, AND (b) ≥1 **Strong/Decent** skill was recommended. Otherwise skip. Full procedure: `references/claude-md.md`.

1. **Resolve the target** — the repo/folder root in play: the scanned folder (mode 2), else `git rev-parse --show-toplevel` (fall back to cwd if not a git repo). Target = `<root>/CLAUDE.md`. Never a subfolder.
2. **Build the block** — list the Strong/Decent picks, splitting **Use directly (already invokable)** from **Install first, then use** (online, not yet installed). Never list `unsynced`/unavailable names. Add the registry pointer + session date (template in `references/claude-md.md`).
3. **Offer + STOP** — print the exact block and resolved target path, then STOP and wait for explicit confirmation. Do not Write/Edit before the user says yes.
4. **Upsert on confirm** — pipe the block content to the helper (it adds the markers):
   `node ~/.claude/skills/autoskills/scripts/upsert-claude-md.mjs <root>/CLAUDE.md  < block-content`
   or use the manual Read→Edit fallback in `references/claude-md.md`. Report what changed. On decline, skip — Step 7 recording still stands.
```

- [ ] **Step 4: Extend the Reference files list in `SKILL.md`**

In the `## Reference files` list at the bottom of `SKILL.md`, after the `- `references/folder-scan.md` …` line, add:
```markdown
- `references/claude-md.md` — when/where/how to write the repo-local CLAUDE.md reminder (Step 8).
```
And after the `- `scripts/index-local-skills.mjs` …` line, add:
```markdown
- `scripts/upsert-claude-md.mjs` — optional idempotent CLAUDE.md block upsert (Step 8).
```

- [ ] **Step 5: Run integration + full suite to verify pass**

Run:
```bash
bash tests/check-integration.sh
```
Expected: `PASS check-integration` (this internally runs every other test).

- [ ] **Step 6: Commit**

```bash
git add SKILL.md tests/check-integration.sh
git commit -m "feat: wire Step 8 CLAUDE.md reminder into autoskills workflow"
```

---

### Task 4: Deploy to runtime + acceptance

**Files:**
- Modify (runtime): `~/.claude/skills/autoskills/` (copy of the skill)

**Interfaces:**
- Consumes: the completed skill in the dev repo (Tasks 1–3).
- Produces: an installed, active skill whose Step 8 is live, verified by an end-to-end dry run. Registry preserved.

- [ ] **Step 1: Deploy (preserve runtime registry)**

Run (Git Bash, from the dev repo root):
```bash
DEST="$HOME/.claude/skills/autoskills"
mkdir -p "$DEST/references" "$DEST/scripts"
cp SKILL.md "$DEST/"
cp references/*.md "$DEST/references/"
cp scripts/*.mjs "$DEST/scripts/"
if [ ! -d "$DEST/registry" ]; then cp -r registry "$DEST/registry"; echo "seeded registry"; else echo "kept existing registry"; fi
ls "$DEST" "$DEST/references" "$DEST/scripts"
```
Expected: the tree lists `SKILL.md`, `references/claude-md.md`, `scripts/upsert-claude-md.mjs`, and `kept existing registry` (or `seeded registry` on first deploy).

- [ ] **Step 2: Acceptance — deployed helper works + is idempotent**

Run:
```bash
DEST="$HOME/.claude/skills/autoskills"
tmp=$(mktemp -d)
printf 'ECHO-TEST' | node "$DEST/scripts/upsert-claude-md.mjs" "$tmp/CLAUDE.md"
grep -q "BEGIN autoskills" "$tmp/CLAUDE.md" && grep -q "ECHO-TEST" "$tmp/CLAUDE.md"
cp "$tmp/CLAUDE.md" "$tmp/first"
printf 'ECHO-TEST' | node "$DEST/scripts/upsert-claude-md.mjs" "$tmp/CLAUDE.md"
diff "$tmp/first" "$tmp/CLAUDE.md" && echo "IDEMPOTENT OK"
rm -rf "$tmp"
```
Expected: `IDEMPOTENT OK`.

- [ ] **Step 3: Acceptance — deployed SKILL.md has Step 8**

Run:
```bash
grep -q "Step 8" "$HOME/.claude/skills/autoskills/SKILL.md" && echo "STEP8 DEPLOYED"
```
Expected: `STEP8 DEPLOYED`.

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "chore: deploy autoskills CLAUDE.md reminder + pass acceptance" --allow-empty
```

---

## Self-Review

**Spec coverage** (spec §→task):
- §3 New Step 8 (separate from Step 7) → Task 3.
- §4 Location resolution (`rev-parse --show-toplevel` → cwd) → Task 2 reference §1, Task 3 Step 8.
- §5 Idempotent markers + 3 merge cases + optional helper → Task 1 (script + behavioral test), Task 2 reference.
- §6 Content template (Use-directly vs Install-first split) → Task 2 reference; doc-presence in `check-claude-md.sh`.
- §7 Keep both persistence layers → unchanged (Step 7 untouched); Step 8 is additive.
- §8 Consent STOP gate → Task 2 reference §3, Task 3 Step 8 (3).
- §9 Files changed → Tasks 1–4.
- §10 Testing strategy (behavioral + doc-presence + integration) → Task 1 (behavioral), Task 2 (doc-presence), Task 3 (integration).
- §11 Out of scope → respected (no auto-write, no outside-marker edits, one file at root).

**Placeholder scan:** No "TBD/TODO". Every code/test block is complete and inline. Template `<...>` tokens are intentional fill-ins documented by adjacent rules, not unfinished plan content.

**Type/name consistency:** Markers `<!-- BEGIN autoskills -->`/`<!-- END autoskills -->`, script name `upsert-claude-md.mjs`, stdin-in/path-arg interface, and test names (`test-upsert-claude-md`, `check-claude-md`) are used identically across Tasks 1–4 and the integration check.

No gaps found.
