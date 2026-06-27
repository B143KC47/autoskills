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
Two local sources, in priority order:
1. **Invokable skills (PRIMARY).** The skills currently available to the `Skill` tool — listed in your in-context available-skills list. These are guaranteed usable right now. This registry, not the filesystem, is the source of truth for "what I can actually use."
2. **Catalog (enrichment).** Names under `~/.claude/skills/` and `~/.agents/skills/`. Many symlink into `~/.orchestra/skills/`, which can be unsynced on a given machine — so a catalog name is a useful candidate *signal* even when its content is unreadable. For speed, run the helper:
   `node ~/.claude/skills/autoskills/scripts/index-local-skills.mjs <keyword>`
   It prints `name | status | description`, where status is `ok` (usable), `empty`, `unsynced` (dead symlink — content unavailable; restore `~/.orchestra/skills` to use), or `missing`.

Match both sources against the query. Treat `unsynced`/`empty` catalog entries as **available-by-name only**: you MAY surface the name as a flagged "catalog: currently unavailable" note, but the Step 4 sanity gate drops it from the scored/ranked recommendations until its content resolves.

## Step 3 — Gather ONLINE candidates
- `npx skills find <query>` — search the ecosystem.
- Check the skills.sh leaderboard for popular domain skills.
- Optionally `WebSearch` for emerging/just-released skills.
Capture for each: name, owner/source, install count, stars if available.

## Step 4 — Evaluate & rank
Apply `references/evaluation.md`:
- Sanity gate: **drop** candidates whose content can't be read — empty/missing SKILL.md OR an `unsynced`/`missing` catalog entry. A dropped name is never scored or offered as a "closest candidate" in Step 6; you may mention it only as a flagged "catalog: currently unavailable" note. (An *invokable* skill passes the gate even if its on-disk folder is a dead symlink.)
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

## Step 8 — Offer a repo-local skill reminder (CLAUDE.md)
**Only when** (a) the recommendation pertains to THIS repo — you scanned/pointed at this folder (mode 2) or read/edited a file in it this session (cwd merely being a git repo doesn't count) — AND (b) ≥1 **Strong/Decent** skill was recommended. Otherwise skip. Full procedure: `references/claude-md.md`.

1. **Resolve the target** — the repo root in play: the scanned folder's git toplevel (mode 2), else `git rev-parse --show-toplevel` (if not a git repo, walk up to the nearest project-root marker, else cwd). Target = `<root>/CLAUDE.md`. Never a subfolder.
2. **Build the block** — split **Use directly** (skills available to a fresh session: globally installed or repo-committed; name them by exact `Skill`-tool id incl. any `plugin:skill`) from **Make available first** (online-uninstalled or session-only skills, with the install/enable command). Omit an empty subsection. Never list `unsynced`/unavailable names. Add the registry pointer + session date (`YYYY-MM-DD`). Template in `references/claude-md.md`.
3. **Offer + STOP** — print the exact block and resolved target path, then STOP and wait for explicit confirmation. Do not Write/Edit, run the helper, or modify any file before the user says yes.
4. **Upsert on confirm** — write the inner block to a temp file, then run the cross-shell helper (absolute paths; see `references/claude-md.md` §4) or use the manual Read→Edit fallback. Report what changed. On decline, skip — Step 7 recording still stands.

## Reference files
- `references/evaluation.md` — scoring rubric + tiers + sanity gate.
- `references/registry-format.md` — registry schema, paths, recording procedure.
- `references/folder-scan.md` — codebase signal → skill-domain mapping (input mode 2).
- `references/claude-md.md` — when/where/how to write the repo-local CLAUDE.md reminder (Step 8).
- `scripts/index-local-skills.mjs` — optional fast local index.
- `scripts/upsert-claude-md.mjs` — optional idempotent CLAUDE.md block upsert (Step 8).
