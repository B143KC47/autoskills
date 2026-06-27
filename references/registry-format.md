# Registry Format & Recording Procedure

The registry is the skill's persistent memory. It is HYBRID:
- **Global store** (cross-project, read every invoke): `~/.claude/skills/autoskills/registry/`
- **Project pointer** (auto-loaded each session): one line in the project's `memory/MEMORY.md`

Claude Code memory is project-scoped only (no global tier), and `MEMORY.md` auto-loads the first ~200 lines each session. The global registry gives cross-project recall; the project pointer makes the agent aware the registry exists.

## Files

### registry/INDEX.md
One line per category. Annotate availability so a glance shows what's usable now:
```
# autoskills registry index
- [research](skillmap-research.md) — deep-research (available); autoresearch + ideation catalogued but unsynced
- [fine-tuning](skillmap-fine-tuning.md) — trl-fine-tuning, unsloth
```

### registry/skillmap-<category>.md
Uses Claude Code memory frontmatter for a consistent format. The `source` field is one of:
`registry` (invokable via the Skill tool) · `local` (readable on disk) · `online:owner/repo` (ecosystem) · `catalog` (known name whose content is currently unreadable/`unsynced`).
```
---
name: skillmap-<category>
description: Skills that work for <category> problems
metadata:
  type: reference
---

# <category>

## Works (available now)
- <skill-name> | <registry|local|online:owner/repo> | tier:<Strong|Decent> | uses:<n> | last:<YYYY-MM-DD> | <note>

## Preferred but currently unavailable (optional — catalog/unsynced)
- <skill-name> | catalog | unavailable | <why / restore hint, e.g. restore ~/.orchestra/skills>

## Gaps
- <unmet need> | noted:<YYYY-MM-DD> | <what was missing>
```

**Rule:** only entries under `## Works (available now)` carry a `tier:` (a recommendation). Catalogued-but-`unsynced` skills go under `## Preferred but currently unavailable` with NO tier — recorded so the preference survives, never recommended until their content resolves.

## Recording procedure (SKILL.md Step 7)
1. Pick/normalize `<category>` (kebab-case; reuse an existing one from INDEX.md if it fits).
2. If `skillmap-<category>.md` is missing, create it from the template above.
3. Record the outcome:
   - **Chosen & usable** → append/update under `## Works (available now)` (increment `uses`, set `last` to today, give a `tier:`).
   - **Preferred but unsynced/unreadable** → record under `## Preferred but currently unavailable` (no `tier:`; add a restore hint).
   - **No fit** → add to `## Gaps`.
4. Add/refresh the category line in `INDEX.md` (with availability annotation) if new.
5. Ensure the project pointer line exists in `<project>/memory/MEMORY.md` (create folder/file if absent):
   `- [autoskills] consult ~/.claude/skills/autoskills/registry/ for problem→skill history`

> Dates: use the session's current date; do not invent one.
