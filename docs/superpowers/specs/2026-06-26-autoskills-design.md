# autoskills — Design Spec

**Date:** 2026-06-26
**Status:** Approved (design); pending implementation plan
**Working dir:** `<repo-root>` (not a git repo — spec is not committed)

## 1. Purpose

A meta-skill ("a skill that finds skills"). Given an engineering **problem**, a **codebase/folder**, or the **current task** in conversation, it:

1. Auto-finds the most suitable skills from **both** the local library and the online ecosystem, ranked together in one list.
2. **Evaluates** each candidate's quality against an explicit rubric.
3. Recommends the best fit (and offers to install online ones).
4. **Records** the outcome to a persistent registry so future searches get smarter ("research problem → autoresearch-style skills").

It supersedes and extends the existing `find-skills` skill, which is online-only and has no memory. `autoskills` cross-references `find-skills` rather than duplicating it.

## 2. Locked decisions (from brainstorming)

| Decision | Choice |
|---|---|
| Search scope | **Both** local + online, gathered every time and ranked together in one unified list |
| Memory store | **Hybrid**: global registry folder (read on invoke) + a one-line auto-loaded pointer in each project's `MEMORY.md` |
| No-match fallback | Present **closest candidates** with caveats, then user chooses: (a) use closest, (b) record gap, (c) write a new skill via `write-a-skill` (then record it) |
| Input modes | All three: problem description, folder/codebase scan, current-task auto-activation |
| Architecture | Instruction-driven orchestrator + reference files + one **optional** local-index helper script |

### Verified facts grounding these decisions
- Claude Code memory is **project-scoped only** — no user-global tier exists (confirmed empirically: 14 separate per-project `memory/MEMORY.md` folders, no global one; and via official docs at code.claude.com/docs/en/memory.md). `MEMORY.md` auto-loads the first ~200 lines / 25KB each session; topic files load on demand. → This is why the registry must be a fixed global path the skill reads on invoke, with only a pointer living in project memory.
- **Local skill content is mostly unsynced on this machine (corrected during implementation).** ~103 of 118 entries under `~/.claude/skills/` (and most of `~/.agents/skills/`) are broken symlinks into `~/.orchestra/skills/`, which is **missing**. So `0-autoresearch-skill` is a **broken symlink** (not an "empty folder" as first thought), and `brainstorming-research-ideas` / `creative-thinking-for-research` are unreadable AND not invokable here. The only invokable research skill is `deep-research` (via the `Skill`-tool registry, not the filesystem). → The skill's source of truth for "what I can use" is the **invokable Skill-tool registry**, with the filesystem catalog as best-effort enrichment carrying availability labels (`ok`/`empty`/`unsynced`). See the plan's "Amendment (2026-06-26)" section.

## 3. Input modes

1. **Problem description** — user describes a task in words ("help me do RL fine-tuning on limited VRAM"). The skill extracts domain + task keywords to form a query.
2. **Folder / codebase scan** — user points at a repo/folder. The skill inspects files (languages, frameworks, configs like `requirements.txt`/`pyproject.toml`/`package.json`/`Dockerfile`, READMEs, notebooks, training scripts) and proposes a *toolkit* of relevant skills. May delegate scanning to the `Explore` agent for breadth.
3. **Current task (auto-activate)** — the skill's `description` triggers it mid-conversation when the agent notices a problem a skill could help with, and it proactively suggests one.

## 4. Core workflow (`SKILL.md`)

0. **Detect input mode** (problem text / folder path / mid-conversation task).
1. **Build query** — extract domain + task keywords. For folder mode, scan files first (see `references/folder-scan.md`) and synthesize the inferred needs into one or more queries.
2. **Consult memory** — read the global registry for matching problem-categories; surface prior wins and known gaps.
3. **Gather local candidates** — index `~/.claude/skills/*/SKILL.md` frontmatter (name + description), match against the query. Optionally use the helper script for speed.
4. **Gather online candidates** — `npx skills find <query>`, the skills.sh leaderboard, and optional `WebSearch` for emerging skills.
5. **Evaluate & rank** — score every candidate with the rubric (§5); auto-drop empty/placeholder skills via the sanity gate. Produce one unified ranked list.
6. **Present** top 3–5: name · source (local/online) · score + tier · why it fits · how to use or install.
7. **Decide:**
   - **Strong match(es):** recommend; for online skills offer install (`npx skills add <owner/repo@skill> -g -y`).
   - **No strong match:** present the closest candidates with explicit caveats, then ask the user to choose:
     - (a) use a closest skill anyway,
     - (b) record the gap and proceed manually,
     - (c) build a new skill via the `write-a-skill` workflow, then record it.
8. **Record outcome** — update/create the global registry file for the problem-category (skill chosen, tier/rating, date, increment use count, note gaps); ensure the project `MEMORY.md` pointer exists.

## 5. Evaluation rubric (`references/evaluation.md`)

**Sanity gate (pass/fail):** a candidate with a missing or empty `SKILL.md`, or no substantive instructions, auto-fails (catches placeholders like `0-autoresearch-skill`).

**Score 0–2 on each dimension (max 10):**

| Dimension | What it measures |
|---|---|
| **Fit / Relevance** | Description + triggers actually match the problem's domain and the specific task; scope covers the need without being adjacent or overly broad |
| **Trust / Provenance** | *Online:* source reputation (anthropics, vercel-labs, microsoft = high), install count (1K+ good, <100 caution), GitHub stars. *Local:* real content vs placeholder, where it came from |
| **Track record** | Registry shows it worked before for similar problems (number of successful uses, user rating). Unknown = 1 |
| **Freshness / Maintenance** | Recently updated; not abandoned; references current tools/versions |
| **Specificity / Cost** | Appropriately scoped (a focused skill beats a kitchen-sink one); reasonable token/complexity cost to apply |

**Tiers:** 8–10 = **Strong** · 5–7 = **Decent** (use with note) · 3–4 = **Weak** (caveat) · 0–2 = **No fit**.

## 6. Memory: hybrid registry (`references/registry-format.md`)

**Global store (cross-project, read on invoke):**
```
~/.claude/skills/autoskills/registry/
├── INDEX.md                  # one-line-per-category index
└── skillmap-<category>.md    # one file per problem-category
```
Each `skillmap-<category>.md` records: the problem-category, skills that worked (name, source, tier/rating, #uses, last-used date, notes), and known gaps. Files use the Claude Code memory frontmatter format (`name`, `description`, `metadata.type: reference`).

**Project pointer (auto-loaded each session):** when the skill runs inside a project, it ensures a one-line pointer exists in that project's `memory/MEMORY.md`:
> `- [autoskills] consult the global registry at ~/.claude/skills/autoskills/registry/ for problem→skill history`

**Seeding (as amended):** the registry ships with a starter `skillmap-research.md` recommending only the **invokable** `deep-research` (tier:Strong) under "Works (available now)". The user's preferred `autoresearch` and the ideation skills (`brainstorming-research-ideas`, `creative-thinking-for-research`) are recorded under "Preferred but currently unavailable" (no tier; restore `~/.orchestra/skills` to use) — never recommended while unsynced. See the "Verified facts" amendment above and the plan's "Amendment (2026-06-26)".

## 7. File structure

```
autoskills/
├── SKILL.md                      # orchestration workflow (§4)
├── references/
│   ├── evaluation.md             # scoring rubric + tiers + sanity gate (§5)
│   ├── registry-format.md        # registry schema, paths, project-pointer convention (§6)
│   └── folder-scan.md            # codebase-signal → skill-domain mapping (mode 2)
├── scripts/
│   └── index-local-skills.*      # OPTIONAL helper: lists local skills + descriptions, Windows-friendly
└── registry/
    ├── INDEX.md                  # seeded
    └── skillmap-research.md      # seeded with real research skills
```

The skill's own folder doubles as the global registry home (`~/.claude/skills/autoskills/registry/`) once installed there.

## 8. Architecture rationale

**Instruction-driven orchestrator** chosen over (B) a script-heavy indexer and (C) a bare prompt-only skill. `SKILL.md` drives the agent through the workflow using existing tools (Glob/Grep/Explore for local, Bash `npx skills` + WebSearch for online, memory files for recording). Reference files give the rubric and registry their rigor; one optional helper script speeds local indexing. Lightweight, transparent, easy to evolve, and resilient on Windows (no required build step).

## 9. Out of scope (YAGNI)

- No real-time online index cache / database.
- No automatic install of skills without user confirmation.
- No background daemon or scheduled re-scan.
- No cross-machine memory sync (Claude Code does not support it).

## 10. Open implementation choices (decide in plan)

- Helper script language: Node vs PowerShell vs Python (must be Windows-friendly). It is **optional** — the skill must work without it.
- Exact category taxonomy for `skillmap-*` files (start small; grow on demand).
