# autoskills

> A meta-skill for [Claude Code](https://claude.com/claude-code): **a skill that finds the right skills.**

`autoskills` takes an engineering problem, a codebase, or your current task and finds the best-matching skills from **both** your local library and the online ecosystem — ranked together in one list. It evaluates each candidate against an explicit quality rubric, recommends the best fit, and records what worked to a persistent registry so future searches get smarter. After recommending, it can write an auto-maintained reminder into the target repo's `CLAUDE.md` so future sessions there use those skills automatically.

It supersedes the online-only `find-skills` skill by adding local search, scoring, and persistent memory.

## Features

- **Local + online search** — gathers candidates from your invokable skills and the `npx skills` ecosystem, ranked together.
- **Quality rubric** — scores each candidate on Fit, Trust, Track-record, Freshness, and Specificity, with a sanity gate that drops unreadable/placeholder skills.
- **Persistent memory** — a hybrid registry (global store + a one-line per-project pointer) that remembers which skills solved which problems.
- **Availability-aware** — only recommends skills usable right now; catalogs preferred-but-unsynced ones without recommending them.
- **Repo-local reminders** — offers to write a consent-gated, idempotent `CLAUDE.md` block so future agents in a repo know which skills to use.

## Install

`autoskills` is a Claude Code skill. Copy it into your skills directory:

```bash
git clone <this-repo-url> autoskills
cp -r autoskills ~/.claude/skills/autoskills
```

It is then available to the `Skill` tool. The installed folder doubles as the global registry home at `~/.claude/skills/autoskills/registry/`.

## Usage

Invoke it whenever you want to find a skill:

- "What skill should I use for X?" / "find a skill for X" / "is there a skill that does X?"
- Point it at a repo/folder and ask which skills apply.
- Starting a problem (research, fine-tuning, evaluation, UI, debugging…) where a skill could help.

The workflow (see [`SKILL.md`](SKILL.md)):

| Step | What it does |
|---|---|
| 0 | Detect input mode (problem / folder / current task) |
| 1 | Consult memory (registry) |
| 2 | Gather local candidates |
| 3 | Gather online candidates |
| 4 | Evaluate & rank with the rubric |
| 5 | Present the top 3–5 |
| 6 | Decide (recommend / record gap / build new) |
| 7 | Record the outcome to the registry |
| 8 | Offer a repo-local `CLAUDE.md` reminder |

## Repository layout

| Path | Purpose |
|---|---|
| `SKILL.md` | The orchestration workflow (entry point) |
| `references/` | Rubric, registry format, folder-scan map, `CLAUDE.md` procedure |
| `scripts/` | Optional dependency-free Node helpers (local index; `CLAUDE.md` upsert) |
| `registry/` | Seeded problem→skill registry |
| `tests/` | Bash checks for the docs and behavioral tests for the scripts |
| `docs/superpowers/` | Design specs and implementation plans |

## Development

Requires Bash and Node.js (no npm dependencies). Run the full suite:

```bash
bash tests/check-integration.sh   # runs every doc check + behavioral tests
```

## License

Licensed under the Apache License, Version 2.0 — see [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).

Copyright © 2026 KO Ho Tin.
