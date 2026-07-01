---
name: autoskills
description: Use when the user asks "what skill should I use for X", "find a skill for X", or "is there a skill that can...", points at a repo/folder and asks which skills apply, or is starting a problem (research, fine-tuning, evaluation, deployment, UI, debugging, etc.) where an existing skill could help.
---

# autoskills — find, evaluate, and remember the right skills

A meta-skill: given a problem, a codebase, or the current task, gather candidate skills from BOTH the local library and the online ecosystem, rank them with an explicit rubric, recommend the best, and record the outcome so future searches improve.

Supersedes the online-only `find-skills` skill (no rubric, no memory); reuse its `npx skills` knowledge.

## When to use
- "What skill should I use for X?" / "find a skill for X" / "is there a skill that does X?"
- You point at a repo/folder and ask which skills apply.
- You are starting a problem (research, fine-tuning, evaluation, deployment, UI, debugging…) where a skill could help — activate proactively.

## When NOT to use
- The user already named the exact skill — just invoke it.
- A fitting skill is already loaded and working for the current task.
- The task is a trivial one-liner where any search costs more than it saves.

## Step 0 — Detect input mode
1. **Problem description** — a task in words. Extract domain + task keywords → query.
2. **Folder / codebase** — a path. Scan it first (`references/folder-scan.md`) to infer needs, then form one query per detected domain.
3. **Current task** — mid-conversation. Use the task at hand as the query.

## Step 1 — Consult memory (cross-project recall)
Read the global registry BEFORE searching:
- `~/.claude/skills/autoskills/registry/INDEX.md` — category index.
- `~/.claude/skills/autoskills/registry/skillmap-<category>.md` — for any matching category.
Prior wins get a Track-record boost in scoring; note known gaps.

**Fast path:** if a matching category already lists a `tier:Strong` skill that is invokable right now and squarely fits the specific task, recommend it directly — skip Steps 2–4, continue from Step 5, and mention that a full search is available on request. Otherwise run the full search.

## Step 2 — Gather LOCAL candidates
Two local sources, in priority order:
1. **Invokable skills (PRIMARY).** The in-context available-skills list of the `Skill` tool — the source of truth for "usable right now".
2. **Catalog (enrichment).** Names under `~/.claude/skills/` and `~/.agents/skills/`; some may be broken symlinks whose content is unreadable. For speed run the helper (from a shell that expands `~`, e.g. bash):
   `node ~/.claude/skills/autoskills/scripts/index-local-skills.mjs <keyword>`
   It prints `name | status | description` (`ok` / `empty` / `unsynced` / `missing`).
Match both sources against the query. Only invokable or `ok` entries can be recommended; the Step 4 sanity gate drops the rest (mention them at most as "catalog: currently unavailable").

## Step 3 — Gather ONLINE candidates
- `npx skills find <query>` — search the ecosystem; also check the skills.sh leaderboard for popular domain skills, and optionally `WebSearch` for just-released ones.
- Capture per candidate: name, owner/source, install count, stars if available.
- **Offline fallback:** if `npx` or the network fails, continue with local candidates only and say so in Step 5.

## Step 4 — Evaluate & rank
Apply `references/evaluation.md`: sanity gate (drop candidates whose content can't be read — an invokable skill always passes), score survivors 0–2 on Fit, Trust, Track-record, Freshness, Specificity (max 10), apply the Fit gate (Fit 0 → drop), tier them, and merge local + online into ONE ranked list.

## Step 5 — Present
Show the top 3–5, one line each:
`<name> · <local|online> · <score>/10 <tier> · why it fits · how to use/install`
For online skills include: `npx skills add <owner/repo@skill> -g -y`.

## Step 6 — Decide
- **Strong match(es):** recommend the top pick; offer to install online ones.
- **No strong match (best tier < Decent):** present the closest candidates WITH caveats, then ask the user to choose:
  (a) use a closest skill anyway, (b) record the gap and proceed manually, (c) build a new skill via `write-a-skill`, then record it.

## Step 7 — Record the outcome
Always update memory (`references/registry-format.md`):
1. Global registry: create/update `~/.claude/skills/autoskills/registry/skillmap-<category>.md` (chosen skill: name, source, tier, date, uses+1, note — or the gap). Update `INDEX.md`.
2. Project pointer: ensure the current project's `memory/MEMORY.md` contains
   `- [autoskills] consult ~/.claude/skills/autoskills/registry/ for problem→skill history`
   (create the project `memory/` + `MEMORY.md` if absent).

## Step 8 — Offer a repo-local skill reminder (CLAUDE.md)
Only when (a) the recommendation pertains to THIS repo — you scanned/pointed at it (mode 2) or read/edited a file in it this session (cwd merely being a git repo doesn't count) — AND (b) ≥1 **Strong/Decent** skill was recommended. Follow `references/claude-md.md`: resolve the repo root, build the block (never list unavailable names), then **print the block + target path, STOP, and write only after an explicit yes** (helper or Read→Edit fallback).

## Reference files
- `references/evaluation.md` — scoring rubric + tiers + sanity gate + Fit gate.
- `references/registry-format.md` — registry schema, paths, recording procedure.
- `references/folder-scan.md` — codebase signal → skill-domain mapping (input mode 2).
- `references/claude-md.md` — the repo-local CLAUDE.md reminder procedure (Step 8).
- `scripts/index-local-skills.mjs` — fast local index (`AUTOSKILLS_SKILL_ROOTS` overrides the scanned roots).
- `scripts/upsert-claude-md.mjs` — idempotent CLAUDE.md block upsert (Step 8).
