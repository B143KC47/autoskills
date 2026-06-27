# Skill Evaluation Rubric

Judge whether a candidate skill is GOOD for the specific problem at hand. Produces a 0–10 score and a tier.

## Sanity gate (pass/fail — do this first)
A candidate AUTO-FAILS (score 0, drop it) if any of:
- No `SKILL.md`, or `SKILL.md` has no body beyond frontmatter.
- Content unreadable: empty folder, OR a broken/`unsynced` symlink (e.g., `0-autoresearch-skill` symlinks into the missing `~/.orchestra/skills` on this machine — never recommend a skill whose content can't be read; you may surface its name at most as "catalog: currently unavailable").
- Frontmatter has no `description` (can't tell what it does).

> An *invokable* skill (present in the `Skill`-tool registry) passes the gate even if its on-disk folder is a dead symlink — it is usable now. The gate only drops candidates that are neither invokable nor readable.

## Score 0–2 on each dimension (max 10)
0 = absent/bad · 1 = partial/unknown · 2 = strong.

| Dimension | 2 (strong) | 1 (partial/unknown) | 0 (bad) |
|---|---|---|---|
| **Fit / Relevance** | Description + triggers squarely match the domain AND the specific task | Adjacent domain, or only partly covers the task | Wrong domain / wrong task |
| **Trust / Provenance** | Online: reputable owner (anthropics, vercel-labs, microsoft) and/or 1K+ installs and/or healthy stars. Local: invokable via the `Skill` tool and/or substantive readable content, known origin | Unknown owner, 100–1K installs, or local with thin content | <100 installs / unknown author / placeholder / `unsynced` (unreadable) |
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
