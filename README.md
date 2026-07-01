<div align="center">

# 🧭 autoskills

**A meta-skill for [Claude Code](https://claude.com/claude-code) — _a skill that finds the right skills._**

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Built for Claude Code](https://img.shields.io/badge/Built%20for-Claude%20Code-d97757)](https://claude.com/claude-code)
[![Type](https://img.shields.io/badge/type-skill-8A2BE2)](SKILL.md)
[![Install](https://img.shields.io/badge/install-npx%20skills-CB3837?logo=npm&logoColor=white)](https://www.npmjs.com/package/skills)

**English** · [简体中文](docs/README.zh-CN.md) · [繁體中文](docs/README.zh-TW.md) · [日本語](docs/README.ja.md) · [한국어](docs/README.ko.md)

</div>

---

`autoskills` takes an engineering problem, a codebase, or your current task and finds the best-matching skills from **both** your local library and the online ecosystem — ranked together in one list. It evaluates each candidate against an explicit quality rubric, recommends the best fit, and records what worked to a persistent registry so future searches get smarter. After recommending, it can write an auto-maintained reminder into the target repo's `CLAUDE.md` so future sessions there use those skills automatically.

It supersedes the online-only `find-skills` skill by adding local search, scoring, and persistent memory.

## ✨ Features

- **Local + online search** — gathers candidates from your invokable skills and the `npx skills` ecosystem, ranked together.
- **Quality rubric** — scores each candidate on Fit, Trust, Track-record, Freshness, and Specificity, with a sanity gate that drops unreadable/placeholder skills.
- **Persistent memory** — a hybrid registry (global store + a one-line per-project pointer) that remembers which skills solved which problems.
- **Availability-aware** — only recommends skills usable right now; catalogs preferred-but-unsynced ones without recommending them.
- **Repo-local reminders** — offers to write a consent-gated, idempotent `CLAUDE.md` block so future agents in a repo know which skills to use.

## 📦 Install

`autoskills` is a Claude Code skill. Install it with the [`skills`](https://www.npmjs.com/package/skills) CLI:

```bash
npx skills add B143KC47/autoskills -g -a claude-code -y
```

Or install manually:

```bash
git clone https://github.com/B143KC47/autoskills.git
cp -r autoskills ~/.claude/skills/autoskills
```

It is then available to the `Skill` tool. The installed folder doubles as the global registry home at `~/.claude/skills/autoskills/registry/`.

## 🚀 Usage

Invoke it whenever you want to find a skill:

- "What skill should I use for X?" / "find a skill for X" / "is there a skill that does X?"
- Point it at a repo/folder and ask which skills apply.
- Starting a problem (research, fine-tuning, evaluation, UI, debugging…) where a skill could help.

The 8-step workflow: detect input mode → consult memory (with a fast path when the registry already knows a strong, invokable match) → gather local + online candidates → evaluate & rank with the rubric → present the top 3–5 → decide → record the outcome → offer a repo-local `CLAUDE.md` reminder. Full detail in [`SKILL.md`](SKILL.md).

## 💡 Example

> **You:** "find me a skill for deep, cited research on a technical topic"

`autoskills` recalls past wins from the registry, gathers local **and** online candidates, scores each against the rubric, and replies with one ranked list:

```text
1. deep-research · local · 9/10 Strong · fan-out web search, adversarial fact-checking,
   cited report — matches the ask · already invokable
2. find-skills   · local · 5/10 Decent · discovers/installs skills but online-only,
   no synthesis · invokable
   …online candidates are scored into the same list, each with its `npx skills add …` line
```

It recommends **deep-research**, then records the win so the next research query ranks faster — and offers to drop a `CLAUDE.md` reminder so future sessions in the repo reach for it automatically.

## 🗂️ Repository layout

| Path | Purpose |
|---|---|
| `SKILL.md` | The orchestration workflow (entry point) |
| `references/` | Rubric, registry format, folder-scan map, `CLAUDE.md` procedure |
| `scripts/` | Optional dependency-free Node helpers (local index; `CLAUDE.md` upsert) |
| `registry/` | Seeded problem→skill registry |
| `tests/` | Bash checks for the docs and behavioral tests for the scripts |

## 🛠️ Development

Requires Bash and Node.js (no npm dependencies). Run the full suite:

```bash
bash tests/check-integration.sh   # runs every doc check + behavioral tests
```

## 📄 License

Licensed under the Apache License, Version 2.0 — see [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).

Copyright © 2026 KO Ho Tin.
