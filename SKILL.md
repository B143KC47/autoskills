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

## Step 0 — Detect input mode & read config
Read `config.json` from this skill's own directory (fall back to defaults if missing/malformed — warn on malformed). See `config.json.example` for the schema: `auto_install` (default false), `min_tier` ("strong"), `trust_floor` (1), `finders` (4).

Then detect input mode:
1. **Problem description** — a task in words. Extract domain + task keywords → query.
2. **Folder / codebase** — a path. Scan it first (`references/folder-scan.md`) to infer needs, then form one query per detected domain.
3. **Current task** — mid-conversation. Use the task at hand as the query.
4. **Work start (proactive)** — the user begins substantive work: run Step 1's fast path automatically (one file read). Escalate further only if its trigger conditions are met.

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

## Step 3 — Deep search ONLINE candidates (capability-tiered)
**Trigger:** run this step only when (a) Step 2 produced no Strong local match, OR (b) the user explicitly asked to find/search skills online. Otherwise skip straight to Step 4 with local candidates.

Pick the highest tier your harness supports (`references/deep-search-workflow.md` has the full procedure and the Tier 1 script template):
1. **Workflow tier** (Claude Code, `Workflow` tool): run the template — `config.finders` parallel Sonnet finder agents (ecosystem `npx skills find`, skills.sh leaderboard, web search for new releases, GitHub SKILL.md search), dedup barrier, then one Opus verifier per candidate applying `references/evaluation.md` adversarially with structured output.
2. **Agent tier** (subagents but no Workflow tool): parallel finder agents + one Opus verification agent over the merged, deduped list.
3. **Inline tier** (no subagents — e.g. Codex): run the same finder queries yourself sequentially, then apply the rubric to each candidate yourself. Requires only shell + web; no Claude-specific tools.

Capture per candidate: name, owner/source, install count, stars if available.
- **Offline fallback:** a finder whose network/`npx` call fails returns nothing — continue with the remaining sources (or local candidates only) and say so in Step 5.

## Step 4 — Evaluate & rank
Apply `references/evaluation.md`: sanity gate (drop candidates whose content can't be read — an invokable skill always passes), score survivors 0–2 on Fit, Trust, Track-record, Freshness, Specificity (max 10), apply the Fit gate (Fit 0 → drop), tier them, and merge local + online into ONE ranked list. Tier-1/2 online candidates arrive pre-scored by the Opus verifiers — merge, don't re-score.

## Step 5 — Present
Show the top 3–5, one line each:
`<name> · <local|online> · <score>/10 <tier> · why it fits · how to use/install`
For online skills include: `npx skills add <owner/repo@skill> -g -y`.

## Step 6 — Decide
- **Auto-install (config-gated):** if `config.auto_install` is true AND the top online pick is tier **Strong** (or better than `config.min_tier`) AND its Trust score ≥ `config.trust_floor`, install it (`npx skills add <owner/repo@skill> -g -y`) and use it immediately — then REPORT what was installed and why (never silent). Auto-install never bypasses the sanity gate; if the install fails, fall back to asking the user.
- **Strong match(es):** recommend the top pick; offer to install online ones.
- **No strong match (best tier < Decent):** present the closest candidates WITH caveats, then ask the user to choose:
  (a) use a closest skill anyway, (b) record the gap and proceed manually, (c) build a new skill via `write-a-skill`, then record it.

## Step 7 — Record the outcome (auto, on work finish)
When the work the skill was recommended for finishes — including when the agent finishes it autonomously — self-assess BEFORE claiming done: *did each skill used this session actually help?*
- **Helped** → `uses+1`, refresh `last`, add a short evidence note.
- **Did NOT help** → downgrade its tier and append an **outcome note** in the objective, verifiable format of `references/registry-format.md` (date, project, task, expected vs observed, evidence pointer). Never edit the skill's upstream `SKILL.md` — the registry entry is the record; the rubric's Track-record dimension reads it on the next search.

Always update memory (`references/registry-format.md`):
1. Global registry: create/update `~/.claude/skills/autoskills/registry/skillmap-<category>.md` (chosen skill: name, source, tier, date, uses+1, note — or the gap). Update `INDEX.md`.
2. Project pointer: ensure the current project's `memory/MEMORY.md` contains
   `- [autoskills] consult ~/.claude/skills/autoskills/registry/ for problem→skill history`
   (create the project `memory/` + `MEMORY.md` if absent).

## Step 8 — Offer a repo-local skill reminder (CLAUDE.md)
Only when (a) the recommendation pertains to THIS repo — you scanned/pointed at it (mode 2) or read/edited a file in it this session (cwd merely being a git repo doesn't count) — AND (b) ≥1 **Strong/Decent** skill was recommended. Follow `references/claude-md.md`: resolve the repo root, build the block (never list unavailable names), then **print the block + target path, STOP, and write only after an explicit yes** (helper or Read→Edit fallback).

## Reference files
- `references/deep-search-workflow.md` — Tier 1 Workflow script template + Tier 2/3 fallback procedures (Step 3).
- `references/evaluation.md` — scoring rubric + tiers + sanity gate + Fit gate.
- `references/registry-format.md` — registry schema, paths, recording procedure.
- `references/folder-scan.md` — codebase signal → skill-domain mapping (input mode 2).
- `references/claude-md.md` — the repo-local CLAUDE.md reminder procedure (Step 8).
- `scripts/index-local-skills.mjs` — fast local index (`AUTOSKILLS_SKILL_ROOTS` overrides the scanned roots).
- `scripts/upsert-claude-md.mjs` — idempotent CLAUDE.md block upsert (Step 8).
- `config.json.example` — config schema (auto_install, min_tier, trust_floor, finders); live config is the user-created `config.json` beside it.
