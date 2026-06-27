# Repo-local skill reminder (`CLAUDE.md`) — Step 8 procedure

After recommending skills, persist a repo-local reminder so future agent sessions in that repo are nudged to use them. Claude Code auto-loads `CLAUDE.md` from the project root (and ancestors) at session start. Because this file is committed and travels to other machines/clones, only persist skills a FRESH session elsewhere can actually use.

## When to offer (gate)
Offer ONLY when BOTH hold:
1. The recommendation pertains to THIS repo — the user explicitly scanned/pointed at this folder (mode 2), OR a file in this repo was read/edited this session (current-task work). The cwd merely sitting inside some git repo does NOT qualify — don't write (say) fine-tuning advice into an unrelated repo just because you happen to be standing in it.
2. At least one **Strong** or **Decent** skill was recommended.

Skip for abstract problem-description queries (mode 1) with no repo in play. Never include `unsynced`/unavailable catalog names.

## 1. Resolve the target (repo root, never a subfolder)
- **Folder-scan mode (2):** the scanned folder; if it sits inside a git repo, its toplevel (`git -C <folder> rev-parse --show-toplevel`).
- **Current-task work:** `git rev-parse --show-toplevel`. If that fails (not a git repo), walk up from the cwd to the nearest project-root marker (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `.hg`, …) and use that; only if none is found, use the cwd.
- If the cwd is a subdirectory of a repo, `git rev-parse --show-toplevel` already returns the repo root — write there.
- **Monorepo note:** the block lands at the git repo root by design (one CLAUDE.md per repo, loaded for every package). Keep entries broad, or skip Step 8 if the recommendation is specific to a single package.
- Target = `<resolved-root>/CLAUDE.md`.

## 2. Build the block content
Goal: a FUTURE agent in a fresh session (possibly on another machine) must be able to act on every line. So split skills by whether they will be AVAILABLE to that future session — not by whether they happen to be loaded right now.

- **Use directly** — the skill will be available to a fresh session in this repo: installed GLOBALLY (e.g. `npx skills add … -g`) or committed into the repo's skill config. Name it by the exact identifier a future agent invokes via the `Skill` tool, INCLUDING any `plugin:skill` namespace (e.g. `superpowers:brainstorming`).
- **Make available first, then use** — anything NOT guaranteed to a fresh session: an online skill not yet installed, OR a skill only enabled in the current session / only readable on this machine. Give the one-line install/enable command.

Template (inner content; the helper adds the markers — see §4):
```markdown
<!-- Maintained by the autoskills skill. Edits between these markers may be overwritten on the next run. -->
## Recommended skills for this project (autoskills)

Detected domain(s): <domain list>. Use these skills proactively — don't wait to be asked.

**Use directly** (invoke by exact `Skill`-tool name, e.g. `plugin:skill`):
- `<skill-name>` — <use-when>

**Make available first, then use**:
- `<owner/repo@skill>` — <use-when> · install: `npx skills add <owner/repo@skill> -g -y`

Full problem→skill history: consult `~/.claude/skills/autoskills/registry/`.

_Last updated by autoskills: <YYYY-MM-DD>._
```
Rules:
- Put a skill under **Use directly** only if it is globally installed or repo-committed (portable). A skill invokable only in THIS session goes under **Make available first** with how to enable it, or is omitted.
- An online skill the user accepted installing in Step 6 (`-g`) is now portable → **Use directly**.
- **Omit any subsection that would be empty** (no dangling header).
- Only Strong/Decent skills. Date = the session's current date in `YYYY-MM-DD`.

## 3. Offer, then STOP (consent gate)
Print the exact block and the resolved target path, then **STOP and wait for explicit confirmation**. Do NOT Write/Edit, run the upsert helper, or otherwise modify any file before the user says yes. (We offer rather than auto-write because `CLAUDE.md` is user-owned and git-tracked.) On decline, skip — the Step 7 registry/memory recording still stands.

## 4. Upsert on confirm
Markers (exact, each alone on its line): `<!-- BEGIN autoskills -->` … `<!-- END autoskills -->`.

**Preferred — deterministic helper** (it owns the markers and reads inner content from stdin). First write the built inner block to a temp file using ABSOLUTE paths (the scratchpad is fine), then run the form for your shell:
- Git Bash: `node /abs/path/upsert-claude-md.mjs /abs/root/CLAUDE.md < /abs/tmp/block.md`
- PowerShell: `Get-Content /abs/tmp/block.md -Raw | node /abs/path/upsert-claude-md.mjs /abs/root/CLAUDE.md`

Use resolved absolute paths, not `~` (node does not expand `~`; PowerShell also reserves `<`). The helper refuses empty or marker-bearing content and exits non-zero — fix the content and retry.

**Manual fallback (portable default, no script).** Read the target first, then:
- **File absent:** create `CLAUDE.md` with `<!-- BEGIN autoskills -->`, the inner content, then `<!-- END autoskills -->`, each marker alone on its line.
- **A managed block present:** copy the current `BEGIN…END` block **verbatim** from what you Read as the Edit `old_string`, and replace it with the new block. Never reconstruct it from memory.
- **No managed block:** append the block after the existing content (preserve everything already there).

Report what changed (`created` / `updated in place` / `appended`).

## Merge cases (summary)
| Case | Action |
|---|---|
| File absent | Create with the block only. |
| One managed block | Replace `BEGIN…END` in place; preserve everything outside. |
| Several managed blocks | Replace the first; remove the duplicates. |
| File exists, no managed block | Append the block; preserve existing content. |

The helper detects only a well-formed block (BEGIN and END each alone on their own line), so prose that merely mentions a marker — or a stray marker line — is left untouched. Re-running with identical input is idempotent (only the dated line changes, and only when the session date changes).
