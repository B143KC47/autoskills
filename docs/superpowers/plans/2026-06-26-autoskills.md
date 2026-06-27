# autoskills Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `autoskills`, a meta-skill that finds the best skills (local + online) for a problem/codebase/current task, evaluates them with a rubric, recommends the best, and records outcomes to a persistent hybrid registry.

**Architecture:** Instruction-driven orchestrator. `SKILL.md` drives an 8-step workflow using existing tools (Glob/Grep/Explore for local, Bash `npx skills` + WebSearch for online, memory files for recording). Three reference files carry the rubric, registry schema, and folder-scan logic. One optional dependency-free Node script speeds local indexing. The skill is developed in the project dir, then deployed to `~/.claude/skills/autoskills/` which is both its installed home and the global registry root.

**Tech Stack:** Markdown (SKILL.md + references), Node.js (one optional helper script, no npm deps), Claude Code memory format for the registry.

## Global Constraints

- Skill name is exactly `autoskills`. Folder name matches.
- Two locations: **dev** = your local clone (`<repo-root>/`); **installed/runtime** = `~/.claude/skills/autoskills/`. Build in dev, deploy in Task 7.
- Global registry root (runtime): `~/.claude/skills/autoskills/registry/`. The skill must read it on every invoke.
- Claude Code memory is **project-scoped only** (no global tier); `MEMORY.md` auto-loads first ~200 lines. Cross-project recall comes from the global registry, not project memory.
- NEVER recommend `0-autoresearch-skill` — it is an empty placeholder folder. Real research skills: `deep-research`, `brainstorming-research-ideas`, `creative-thinking-for-research`.
- The helper script is **optional**: the skill must work fully without it.
- Dates in recorded files use the session's current date (today: 2026-06-26); do not invent dates.
- **Git is optional.** The project is not a git repo. Task 0 (optional) runs `git init`. If you skip it, also skip every `git commit` step — they are checkpoints, not requirements.
- In the user's git history, never use "CLAUDE" as the author — use the user's name.

---

## Amendment (2026-06-26): availability-aware local search

Implementation surfaced an environment fact that corrects a core premise: on this machine, ~103 of 118 entries under `~/.claude/skills/` (and most of `~/.agents/skills/`) are **broken symlinks** into `~/.orchestra/skills/`, which is **missing/unsynced**. So the original "read `~/.claude/skills/*/SKILL.md` for descriptions" assumption is unreliable here. Corrections applied (commit on top of Task 4):

1. **Source of truth = the invokable `Skill`-tool registry** (in-context available-skills list), PRIMARY. Filesystem catalog is best-effort enrichment.
2. **Indexer (Task 5)** is availability-aware: never crashes on dead symlinks; classifies each name `ok` / `empty` / `unsynced` / `missing`; scans both roots; always emits the NAME (a usable match signal); CRLF-tolerant frontmatter parsing.
3. **Sanity gate (Task 2)** fails unreadable/`unsynced` content; an invokable skill passes even if its on-disk folder is a dead symlink.
4. **Seed registry (Task 3)** recommends only the invokable `deep-research`; the user's preferred `autoresearch` and the ideation skills are recorded as *catalogued-but-unsynced* (restore `~/.orchestra/skills` to use), never recommended until resolved.

User decision: build robust now, restore `~/.orchestra/skills` as a follow-up. The skill works in both states.

---

### Task 0 (Optional): Initialize git for checkpointing

**Files:**
- Create: `.gitignore`

**Interfaces:**
- Produces: a git repo so later `git commit` steps work. If skipped, ignore all commit steps.

- [ ] **Step 1: Initialize repo**

Run (from project root):
```bash
git init && printf "node_modules/\n*.log\n" > .gitignore
```
Expected: `Initialized empty Git repository`.

- [ ] **Step 2: First commit**

```bash
git add docs .gitignore
git commit -m "chore: add autoskills design spec and plan"
```
Expected: a commit is created. (Author = user's name, not "CLAUDE".)

---

### Task 1: SKILL.md — orchestration workflow

**Files:**
- Create: `SKILL.md`
- Test: `tests/check-skill-md.sh`

**Interfaces:**
- Produces: the skill entry point with valid frontmatter (`name: autoskills`, trigger-rich `description`) and the 8-step workflow that references `references/evaluation.md`, `references/registry-format.md`, `references/folder-scan.md`, and `scripts/index-local-skills.mjs`.

- [ ] **Step 1: Write the failing test**

Create `tests/check-skill-md.sh`:
```bash
#!/usr/bin/env bash
set -e
f="SKILL.md"
grep -q "^name: autoskills$" "$f"
grep -qi "description:.*find" "$f"
grep -q "references/evaluation.md" "$f"
grep -q "references/registry-format.md" "$f"
grep -q "references/folder-scan.md" "$f"
grep -q "scripts/index-local-skills.mjs" "$f"
grep -q "Step 7" "$f"
echo "PASS check-skill-md"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/check-skill-md.sh`
Expected: FAIL (`SKILL.md: No such file or directory`).

- [ ] **Step 3: Write SKILL.md**

Create `SKILL.md`:
````markdown
---
name: autoskills
description: Finds the best skills (local + online) for an engineering problem, codebase, or current task; evaluates each candidate with a quality rubric; recommends the best fit; and records what worked to a persistent registry so it gets smarter over time. Use when the user asks "what skill should I use for X", "find a skill for X", "is there a skill that can...", points at a repo/folder and asks which skills apply, or is starting a problem (research, fine-tuning, evaluation, deployment, UI, debugging, etc.) where an existing skill could help.
---

# autoskills — find, evaluate, and remember the right skills

A meta-skill: a skill that finds skills. Given a problem, a codebase, or the current task, it gathers candidate skills from BOTH the local library and the online ecosystem, ranks them by an explicit quality rubric, recommends the best, and records the outcome so future searches improve.

Supersedes the online-only `find-skills` skill (no rubric, no memory). Reuse its `npx skills` knowledge; this skill adds local search, scoring, and persistent recording.

## When to use
- "What skill should I use for X?" / "find a skill for X" / "is there a skill that does X?"
- You point at a repo/folder and ask which skills apply.
- You are starting a problem (research, fine-tuning, evaluation, deployment, UI, debugging…) and a skill could help — activate proactively.

## Step 0 — Detect input mode
1. **Problem description** — a task in words. Extract domain + task keywords → query.
2. **Folder / codebase** — a path. First scan it (`references/folder-scan.md`) to infer needs, then form one or more queries.
3. **Current task** — mid-conversation. Use the task at hand as the query.

## Step 1 — Consult memory (cross-project recall)
Read the global registry BEFORE searching:
- `~/.claude/skills/autoskills/registry/INDEX.md` — category index.
- `~/.claude/skills/autoskills/registry/skillmap-<category>.md` — for any matching category.
Note prior wins (skills that worked) and known gaps. Prior wins get a Track-record boost in scoring.

## Step 2 — Gather LOCAL candidates
List `~/.claude/skills/*/SKILL.md`, read each frontmatter `name` + `description`, match against the query. For speed you MAY run the helper:
`node ~/.claude/skills/autoskills/scripts/index-local-skills.mjs <keyword>`
which prints `name | status(ok/empty) | description`. Skills marked `empty` fail the sanity gate (Step 4).

## Step 3 — Gather ONLINE candidates
- `npx skills find <query>` — search the ecosystem.
- Check the skills.sh leaderboard for popular domain skills.
- Optionally `WebSearch` for emerging/just-released skills.
Capture for each: name, owner/source, install count, stars if available.

## Step 4 — Evaluate & rank
Apply `references/evaluation.md`:
- Sanity gate: drop candidates with empty/missing SKILL.md.
- Score each survivor 0–2 on Fit, Trust, Track-record, Freshness, Specificity (max 10).
- Tier: 8–10 Strong · 5–7 Decent · 3–4 Weak · 0–2 No fit.
Merge local + online into ONE ranked list.

## Step 5 — Present
Show the top 3–5, one line each:
`<name> · <local|online> · <score>/10 <tier> · why it fits · how to use/install`
For online skills include: `npx skills add <owner/repo@skill> -g -y`.

## Step 6 — Decide
- **Strong match(es):** recommend the top pick; offer to install online ones.
- **No strong match (best tier < Decent):** present the closest candidates WITH caveats, then ask the user to choose:
  - (a) use a closest skill anyway,
  - (b) record the gap and proceed manually,
  - (c) build a new skill via the `write-a-skill` skill, then record it.

## Step 7 — Record the outcome
Always update memory (`references/registry-format.md`):
1. Global registry: create/update `~/.claude/skills/autoskills/registry/skillmap-<category>.md` (add the chosen skill: name, source, tier, date, uses+1, note — or the gap). Update `INDEX.md`.
2. Project pointer: ensure the current project's `memory/MEMORY.md` contains:
   `- [autoskills] consult ~/.claude/skills/autoskills/registry/ for problem→skill history`
   (Create the project `memory/` + `MEMORY.md` if absent.)

## Reference files
- `references/evaluation.md` — scoring rubric + tiers + sanity gate.
- `references/registry-format.md` — registry schema, paths, recording procedure.
- `references/folder-scan.md` — codebase signal → skill-domain mapping (input mode 2).
- `scripts/index-local-skills.mjs` — optional fast local index.
````

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/check-skill-md.sh`
Expected: `PASS check-skill-md`.

- [ ] **Step 5: Commit** (skip if no git)

```bash
git add SKILL.md tests/check-skill-md.sh
git commit -m "feat: add autoskills SKILL.md orchestration workflow"
```

---

### Task 2: Evaluation rubric reference

**Files:**
- Create: `references/evaluation.md`
- Test: `tests/check-evaluation.sh`

**Interfaces:**
- Consumes: nothing.
- Produces: the rubric SKILL.md Step 4 depends on — sanity gate + 5 dimensions (Fit, Trust, Track record, Freshness, Specificity/Cost) + tiers (Strong/Decent/Weak/No fit).

- [ ] **Step 1: Write the failing test**

Create `tests/check-evaluation.sh`:
```bash
#!/usr/bin/env bash
set -e
f="references/evaluation.md"
grep -qi "Sanity gate" "$f"
for d in "Fit" "Trust" "Track record" "Freshness" "Specificity"; do grep -q "$d" "$f"; done
for t in "Strong" "Decent" "Weak" "No fit"; do grep -q "$t" "$f"; done
echo "PASS check-evaluation"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/check-evaluation.sh`
Expected: FAIL (file missing).

- [ ] **Step 3: Write references/evaluation.md**

Create `references/evaluation.md`:
````markdown
# Skill Evaluation Rubric

Judge whether a candidate skill is GOOD for the specific problem at hand. Produces a 0–10 score and a tier.

## Sanity gate (pass/fail — do this first)
A candidate AUTO-FAILS (score 0, drop it) if any of:
- No `SKILL.md`, or `SKILL.md` has no body beyond frontmatter.
- Empty/placeholder folder (e.g., `0-autoresearch-skill` is empty — never recommend it).
- Frontmatter has no `description` (can't tell what it does).

## Score 0–2 on each dimension (max 10)
0 = absent/bad · 1 = partial/unknown · 2 = strong.

| Dimension | 2 (strong) | 1 (partial/unknown) | 0 (bad) |
|---|---|---|---|
| **Fit / Relevance** | Description + triggers squarely match the domain AND the specific task | Adjacent domain, or only partly covers the task | Wrong domain / wrong task |
| **Trust / Provenance** | Online: reputable owner (anthropics, vercel-labs, microsoft) and/or 1K+ installs and/or healthy stars. Local: substantive content, known origin | Unknown owner, 100–1K installs, or local with thin content | <100 installs / unknown author / placeholder |
| **Track record** | Registry shows it worked before for a similar problem (≥1 successful use or good rating) | No registry history (default) | Registry shows it failed / was a poor fit |
| **Freshness** | Updated recently; references current tools/versions | Age unknown | Clearly abandoned / obsolete tools |
| **Specificity / Cost** | Focused on exactly this need; low overhead | Broad but usable | Kitchen-sink/unfocused or very heavy for the need |

## Tiers
- **8–10 Strong** — recommend.
- **5–7 Decent** — recommend with a note on the weak dimension.
- **3–4 Weak** — only offer as a "closest" fallback, with caveats.
- **0–2 No fit** — drop.

## Tie-breakers
1. Higher Track record (proven beats unproven).
2. Higher Fit.
3. Local over online when tied (no install, already trusted).
````

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/check-evaluation.sh`
Expected: `PASS check-evaluation`.

- [ ] **Step 5: Commit** (skip if no git)

```bash
git add references/evaluation.md tests/check-evaluation.sh
git commit -m "feat: add skill evaluation rubric"
```

---

### Task 3: Registry format + seeded registry

**Files:**
- Create: `references/registry-format.md`
- Create: `registry/INDEX.md`
- Create: `registry/skillmap-research.md`
- Test: `tests/check-registry.sh`

**Interfaces:**
- Consumes: nothing.
- Produces: the registry schema + recording procedure SKILL.md Step 7 depends on, and a seeded `research` category pointing to REAL skills.

- [ ] **Step 1: Write the failing test**

Create `tests/check-registry.sh`:
```bash
#!/usr/bin/env bash
set -e
grep -qi "Recording procedure" references/registry-format.md
grep -q "skillmap-<category>" references/registry-format.md
grep -q "skillmap-research.md" registry/INDEX.md
grep -q "deep-research" registry/skillmap-research.md
# must NOT seed the empty placeholder as a recommendation
! grep -qiE "^\- 0-autoresearch-skill \|" registry/skillmap-research.md
grep -q "name: skillmap-research" registry/skillmap-research.md
echo "PASS check-registry"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/check-registry.sh`
Expected: FAIL (files missing).

- [ ] **Step 3a: Write references/registry-format.md**

Create `references/registry-format.md`:
````markdown
# Registry Format & Recording Procedure

The registry is the skill's persistent memory. It is HYBRID:
- **Global store** (cross-project, read every invoke): `~/.claude/skills/autoskills/registry/`
- **Project pointer** (auto-loaded each session): one line in the project's `memory/MEMORY.md`

Claude Code memory is project-scoped only (no global tier), and `MEMORY.md` auto-loads the first ~200 lines each session. The global registry gives cross-project recall; the project pointer makes the agent aware the registry exists.

## Files

### registry/INDEX.md
One line per category:
```
# autoskills registry index
- [research](skillmap-research.md) — deep-research, brainstorming-research-ideas
- [fine-tuning](skillmap-fine-tuning.md) — trl-fine-tuning, unsloth
```

### registry/skillmap-<category>.md
Uses Claude Code memory frontmatter for a consistent format:
```
---
name: skillmap-<category>
description: Skills that work for <category> problems
metadata:
  type: reference
---

# <category>

## Works
- <skill-name> | <local|online:owner/repo> | tier:<Strong|Decent> | uses:<n> | last:<YYYY-MM-DD> | <note>

## Gaps
- <unmet need> | noted:<YYYY-MM-DD> | <what was missing>
```

## Recording procedure (SKILL.md Step 7)
1. Pick/normalize `<category>` (kebab-case; reuse an existing one from INDEX.md if it fits).
2. If `skillmap-<category>.md` is missing, create it from the template above.
3. Append/update the chosen skill under `## Works` (increment `uses`, set `last` to today) OR the gap under `## Gaps`.
4. Add the category to `INDEX.md` if new.
5. Ensure the project pointer line exists in `<project>/memory/MEMORY.md` (create folder/file if absent):
   `- [autoskills] consult ~/.claude/skills/autoskills/registry/ for problem→skill history`

> Dates: use the session's current date; do not invent one.
````

- [ ] **Step 3b: Write registry/INDEX.md**

Create `registry/INDEX.md`:
```markdown
# autoskills registry index

Problem-category → skills known to work. See each skillmap file for details.

- [research](skillmap-research.md) — deep-research, brainstorming-research-ideas, creative-thinking-for-research
```

- [ ] **Step 3c: Write registry/skillmap-research.md**

Create `registry/skillmap-research.md`:
```markdown
---
name: skillmap-research
description: Skills that work for research problems (literature review, multi-source synthesis, idea generation)
metadata:
  type: reference
---

# research

## Works
- deep-research | local | tier:Strong | uses:0 | last:2026-06-26 | fan-out web search + adversarial verification + cited report
- brainstorming-research-ideas | local | tier:Decent | uses:0 | last:2026-06-26 | generate/refine research directions
- creative-thinking-for-research | local | tier:Decent | uses:0 | last:2026-06-26 | lateral idea generation

## Gaps
- (none recorded yet)

> Note: `0-autoresearch-skill` is an empty placeholder folder — do NOT recommend it. Use the skills above for research problems.
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/check-registry.sh`
Expected: `PASS check-registry`.

- [ ] **Step 5: Commit** (skip if no git)

```bash
git add references/registry-format.md registry/ tests/check-registry.sh
git commit -m "feat: add registry format and seeded research category"
```

---

### Task 4: Folder-scan reference

**Files:**
- Create: `references/folder-scan.md`
- Test: `tests/check-folder-scan.sh`

**Interfaces:**
- Consumes: nothing.
- Produces: the signal→domain mapping SKILL.md Step 0 (folder mode) depends on.

- [ ] **Step 1: Write the failing test**

Create `tests/check-folder-scan.sh`:
```bash
#!/usr/bin/env bash
set -e
f="references/folder-scan.md"
grep -qi "Signal" "$f"
grep -q "requirements.txt" "$f"
grep -q "package.json" "$f"
grep -qi "Explore" "$f"
echo "PASS check-folder-scan"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/check-folder-scan.sh`
Expected: FAIL (file missing).

- [ ] **Step 3: Write references/folder-scan.md**

Create `references/folder-scan.md`:
````markdown
# Folder / Codebase Scan → Skill Domains (input mode 2)

When pointed at a repo/folder, infer what skills would help: detect signals, then map signals → domains → queries.

## How to scan
1. Glob top-level + key files. For breadth, dispatch the `Explore` agent.
2. Read manifests/configs and the README.
3. Collect signals from the table; produce one query per detected domain.

## Signal → domain table
| Signal (files / contents) | Inferred domain | Example queries |
|---|---|---|
| `requirements.txt`, `pyproject.toml`, `*.py` | Python project | (refine by libs below) |
| `package.json`, `*.ts/tsx`, `next.config.*` | Web / JS/TS | react, nextjs, frontend-design |
| `torch`, `transformers`, `*.ipynb`, training loop | ML training | fine-tuning, deepspeed, flash-attention, peft |
| `trl`, `peft`, `lora`, RLHF configs | Fine-tuning / RL | trl-fine-tuning, unsloth, grpo-rl-training |
| `lm-eval`, benchmark/eval scripts | Model evaluation | lm-evaluation-harness, nemo-evaluator |
| `Dockerfile`, k8s manifests, CI yaml | DevOps / deploy | docker, deploy, ci-cd |
| `vllm`, `sglang`, serving config | Inference serving | vllm, sglang, tensorrt-llm |
| vector DB clients (`chroma`, `faiss`, `qdrant`, `pinecone`) | Retrieval / RAG | chroma, faiss, langchain, llamaindex |
| many untested modules / low coverage | Testing | tdd, testing, playwright |
| `*.tsx`/`*.vue`/`*.svelte` + styling | UI/UX | ui-ux-pro-max, frontend-design |

## Output
A proposed *toolkit*: for each detected domain run Steps 2–5 of the main workflow and present the top skill per domain, grouped by domain. Record the toolkit under a `skillmap-<stack>.md` category if useful.
````

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/check-folder-scan.sh`
Expected: `PASS check-folder-scan`.

- [ ] **Step 5: Commit** (skip if no git)

```bash
git add references/folder-scan.md tests/check-folder-scan.sh
git commit -m "feat: add folder-scan signal mapping"
```

---

### Task 5: Optional local-index helper script

**Files:**
- Create: `scripts/index-local-skills.mjs`
- Test: `tests/test-index-local-skills.sh`

**Interfaces:**
- Consumes: reads `~/.claude/skills/*/SKILL.md` directly via Node `fs` (no input from other tasks).
- Produces: CLI `node scripts/index-local-skills.mjs [keyword]` printing `name | status | description` per skill (status `ok`/`empty`); count goes to stderr. Marks folders with no/empty SKILL.md as `empty`.

- [ ] **Step 1: Write the failing test**

Create `tests/test-index-local-skills.sh`:
```bash
#!/usr/bin/env bash
set -e
out=$(node scripts/index-local-skills.mjs fine)
echo "$out" | grep -qi "trl-fine-tuning"        # keyword match works
empty=$(node scripts/index-local-skills.mjs autoresearch)
echo "$empty" | grep -q "0-autoresearch-skill | empty"   # placeholder flagged empty
echo "PASS test-index-local-skills"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test-index-local-skills.sh`
Expected: FAIL (`Cannot find module .../index-local-skills.mjs`).

- [ ] **Step 3: Write scripts/index-local-skills.mjs**

Create `scripts/index-local-skills.mjs`:
```javascript
#!/usr/bin/env node
// Lists local skills with name + description; flags empty/placeholder skills.
// Usage: node index-local-skills.mjs [keyword]
import { readdirSync, readFileSync, existsSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { homedir } from 'node:os';

const SKILLS_DIR = join(homedir(), '.claude', 'skills');
const keyword = (process.argv[2] || '').toLowerCase();

function parseFrontmatter(text) {
  if (!text.startsWith('---')) return {};
  const end = text.indexOf('\n---', 3);
  if (end === -1) return {};
  const out = {};
  for (const line of text.slice(3, end).split('\n')) {
    const m = line.match(/^(\w+):\s*(.*)$/);
    if (m) out[m[1]] = m[2].trim();
  }
  return out;
}

let rows = [];
for (const name of readdirSync(SKILLS_DIR)) {
  const dir = join(SKILLS_DIR, name);
  if (!statSync(dir).isDirectory()) continue;
  const skillFile = join(dir, 'SKILL.md');
  let status = 'ok', desc = '';
  if (!existsSync(skillFile)) {
    status = 'empty';
  } else {
    const text = readFileSync(skillFile, 'utf8');
    const body = text.replace(/^---[\s\S]*?\n---/, '').trim();
    desc = parseFrontmatter(text).description || '';
    if (body.length === 0) status = 'empty';
  }
  rows.push({ name, desc, status });
}

if (keyword) {
  rows = rows.filter(r =>
    r.name.toLowerCase().includes(keyword) ||
    r.desc.toLowerCase().includes(keyword));
}

for (const r of rows.sort((a, b) => a.name.localeCompare(b.name))) {
  console.log(`${r.name} | ${r.status} | ${r.desc.slice(0, 140)}`);
}
console.error(`\n${rows.length} skill(s)${keyword ? ` matching "${keyword}"` : ''}.`);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test-index-local-skills.sh`
Expected: `PASS test-index-local-skills`.

- [ ] **Step 5: Commit** (skip if no git)

```bash
git add scripts/index-local-skills.mjs tests/test-index-local-skills.sh
git commit -m "feat: add optional local-skill indexer script"
```

---

### Task 6: Integration verification

**Files:**
- Test: `tests/check-integration.sh`

**Interfaces:**
- Consumes: all files from Tasks 1–5.
- Produces: proof that SKILL.md's cross-references all resolve and the supersede note is present.

- [ ] **Step 1: Write the failing test**

Create `tests/check-integration.sh`:
```bash
#!/usr/bin/env bash
set -e
# every file SKILL.md references must exist
for ref in references/evaluation.md references/registry-format.md references/folder-scan.md scripts/index-local-skills.mjs registry/INDEX.md registry/skillmap-research.md; do
  test -f "$ref" || { echo "MISSING $ref"; exit 1; }
done
# supersede note present
grep -qi "find-skills" SKILL.md
# all per-file checks still pass
for t in check-skill-md check-evaluation check-registry check-folder-scan; do bash "tests/$t.sh" >/dev/null; done
bash tests/test-index-local-skills.sh >/dev/null
echo "PASS check-integration"
```

- [ ] **Step 2: Run test to verify it fails (if any gap)**

Run: `bash tests/check-integration.sh`
Expected: PASS if Tasks 1–5 complete; otherwise it names the missing file. If `find-skills` note is missing, add one line to SKILL.md (already included in Task 1 — verify).

- [ ] **Step 3: Fix any gaps surfaced, then re-run**

Run: `bash tests/check-integration.sh`
Expected: `PASS check-integration`.

- [ ] **Step 4: Commit** (skip if no git)

```bash
git add tests/check-integration.sh
git commit -m "test: add cross-reference integration check"
```

---

### Task 7: Deploy to ~/.claude/skills + acceptance dry-run

**Files:**
- Create (runtime): `~/.claude/skills/autoskills/` (copy of the skill)

**Interfaces:**
- Consumes: the completed skill in the project dir.
- Produces: an installed, active skill at `~/.claude/skills/autoskills/` whose registry is live, verified by an end-to-end dry run.

- [ ] **Step 1: Deploy (preserve any existing runtime registry)**

Run (Git Bash). Copies skill files; only seeds `registry/` if it does not already exist so accumulated memory is never clobbered:
```bash
DEST="$HOME/.claude/skills/autoskills"
mkdir -p "$DEST/references" "$DEST/scripts"
cp SKILL.md "$DEST/"
cp references/*.md "$DEST/references/"
cp scripts/index-local-skills.mjs "$DEST/scripts/"
if [ ! -d "$DEST/registry" ]; then cp -r registry "$DEST/registry"; echo "seeded registry"; else echo "kept existing registry"; fi
ls -R "$DEST"
```
Expected: the tree lists SKILL.md, references/, scripts/, registry/.

- [ ] **Step 2: Acceptance — local candidate surfacing**

Run:
```bash
node "$HOME/.claude/skills/autoskills/scripts/index-local-skills.mjs" rl
```
Expected: output includes RL/fine-tuning skills such as `grpo-rl-training` and/or `trl-fine-tuning`, and `0-autoresearch-skill | empty` does NOT appear under an `rl` filter (it has no match) — confirming keyword filtering works.

- [ ] **Step 3: Acceptance — sanity gate catches the placeholder**

Run:
```bash
node "$HOME/.claude/skills/autoskills/scripts/index-local-skills.mjs" autoresearch
```
Expected: `0-autoresearch-skill | empty | ` — proving the gate flags placeholders.

- [ ] **Step 4: Acceptance — registry recall + record (manual workflow dry-run)**

Manually execute SKILL.md Steps 1 and 7 for the query "research":
1. Read `~/.claude/skills/autoskills/registry/skillmap-research.md` → confirm it recommends `deep-research` (Strong) and NOT `0-autoresearch-skill`.
2. Simulate recording a win: append a line under `## Works` for a hypothetical `deep-research` use with today's date, then revert (this is a dry run — restore the file).
Expected: the registry reads cleanly and the recording procedure is unambiguous.

- [ ] **Step 5: Final commit** (skip if no git)

```bash
git add -A
git commit -m "chore: deploy autoskills and pass acceptance dry-run"
```

---

## Self-Review

**Spec coverage** (spec §→task):
- §1 Purpose / supersede find-skills → Task 1 (SKILL.md body + supersede note), Task 6 (verifies note).
- §2 Search scope both/ranked → Task 1 Steps 2–4.
- §3 Input modes (problem/folder/current task) → Task 1 Step 0, Task 4 (folder).
- §4 Workflow 8 steps → Task 1.
- §5 Evaluation rubric (sanity gate + 5 dims + tiers) → Task 2.
- §6 Hybrid registry (global + project pointer) → Task 3 + Task 1 Step 7.
- §7 File structure → Tasks 1–5; deploy → Task 7.
- §8 Architecture (instruction-driven + optional script) → Task 5 (optional), all others instruction-based.
- §9 Out of scope → respected (no daemon, no auto-install, no cache).
- §10 Open choices: helper-script language = **Node** (guaranteed present via `npx`); category taxonomy starts with `research`, grows on demand. Both resolved.

**Placeholder scan:** No "TBD/TODO"; every file's full content is inline; every test has real commands and expected output.

**Type/name consistency:** Script flag/columns (`name | status | description`), registry fields (`tier`, `uses`, `last`), and file paths (`references/*.md`, `registry/skillmap-<category>.md`, `~/.claude/skills/autoskills/`) are used identically across Tasks 1, 3, 5, 6, 7.

No gaps found.
