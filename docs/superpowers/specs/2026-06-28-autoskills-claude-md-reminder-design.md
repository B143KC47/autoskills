# autoskills — repo-local `CLAUDE.md` skill reminder — Design Spec

**Date:** 2026-06-28
**Status:** Approved (design); pending implementation plan
**Working dir:** `<repo-root>` (git repo; branch `feat/autoskills-claude-md-reminder`)
**Builds on:** `docs/superpowers/specs/2026-06-26-autoskills-design.md`

## 1. Purpose

After autoskills finds, evaluates, and records the right skills, persist a **repo-local reminder** so that *future* agent sessions opened in that repo are automatically nudged to use the recommended skills — without the user having to re-run autoskills or remember which skills apply.

The mechanism is the project's `CLAUDE.md`: Claude Code auto-loads `CLAUDE.md` from the project root (and ancestors) at session start. Writing a tailored, auto-maintained block there means the next agent that opens the repo sees "use these skills proactively" before doing anything.

This **extends** the existing Step 7 ("Record the outcome"); it does not replace it. The two persistence layers are complementary and live in genuinely different places (§7).

## 2. Locked decisions (from brainstorming, 2026-06-28)

| Decision | Choice |
|---|---|
| Consent model | **Offer + write on confirm.** Autoskills prints the exact proposed block and the target path, STOPS, and writes only after the user confirms. `CLAUDE.md` is user-owned and git-tracked. |
| Scope (which input modes) | **Folder-scan mode (2) and current-task work inside a project.** Never for abstract problem-description queries that have no repo in play. |
| Relationship to existing memory pointer | **Keep both.** `CLAUDE.md` is the repo-local, git-tracked reminder; the `memory/MEMORY.md` pointer remains for cross-project registry recall. Different roles, different locations (§7). |
| Trigger condition | Only when ≥1 **Strong or Decent** skill was recommended. Never writes `unsynced`/unavailable catalog names (consistent with the availability-aware gate from the base design). |
| Idempotency | A delimited **auto-maintained block**, upserted in place. Content outside the markers is never touched. |
| Merge mechanism | Optional deterministic helper script `scripts/upsert-claude-md.mjs` (mirrors the existing `index-local-skills.mjs` pattern). The skill must also work **without** it via a documented manual Read→Edit procedure. |

## Amendment (2026-06-28): adversarial-review hardening

A multi-agent adversarial review (run post-implementation) confirmed a data-loss **blocker** plus a portability gap; both are fixed. Deltas to the design below:

- **Merge (§5):** the helper no longer uses bare `indexOf`. It matches only a **well-formed managed block** via a line-anchored, BEGIN-tempered regex (BEGIN and END each alone on their own line, no BEGIN between), replaces the **first in place** and **removes duplicate** blocks, **rejects** empty or marker-bearing stdin, is **CRLF-aware** (preserves the file's EOL; idempotent on CRLF), and `mkdir -p`s the parent with clean errors. Prose mentioning a marker, or a stray marker line, is never matched — closing the "delete user content between a stray BEGIN and the real END" hole. The behavioral test covers all these cases.
- **Template buckets (§6):** split by **future-session availability**, not session-scoped invokability. **Use directly** = globally installed (`-g`) or repo-committed (portable to a fresh clone); name by exact `Skill`-tool id incl. any `plugin:skill` namespace. **Make available first** = online-uninstalled or session-only/local-only skills, with the enable command. Omit empty subsections. This prevents a committed `CLAUDE.md` from telling another machine to use a skill it doesn't have.
- **Gate (§3):** Step 8 fires only when the recommendation **pertains to this repo** (scanned/pointed-at, or a repo file touched this session) — not merely because the cwd happens to sit in a git repo.
- **Location (§4):** non-git fallback **walks up to the nearest project-root marker** (`package.json`/`pyproject.toml`/`go.mod`/…) before defaulting to cwd; monorepo behavior (block at repo root) documented as a chosen outcome.
- **Consent (§8):** the prohibition explicitly names running the helper/script (not just Write/Edit) as a forbidden pre-consent action.
- **Invocation (§5.3):** documented as a **cross-shell** recipe — temp-file + `node … < file` (Git Bash) or `Get-Content … -Raw | node …` (PowerShell), absolute paths (no `~`) — with the manual Read→Edit fallback as the portable default.

## 3. Where it fits in the workflow

New **Step 8** in `SKILL.md`: *"Offer a repo-local skill reminder (`CLAUDE.md`)."*

Kept separate from Step 7 because the conditions differ:
- **Step 7** ("Record the outcome") is **unconditional** — always update the global registry + ensure the project memory pointer.
- **Step 8** is **conditional** (needs a concrete repo in play AND a Strong/Decent recommendation) and **consent-gated** (offer, then write on confirm).

Step 8 runs after Step 7, using the same ranked recommendations produced in Steps 5–6.

## 4. Location resolution

The target is the **root of the repo/folder in play**, never a subfolder:

1. **Folder-scan mode (2):** the scanned folder. If it is a git repo, its toplevel.
2. **Current-task work:** resolve the repo root via `git rev-parse --show-toplevel`. If the command fails (not a git repo), fall back to the current working directory.
3. If the cwd is a **subdirectory** of a repo, `git rev-parse --show-toplevel` already returns the repo root — write there, not in the subdirectory.

Target path: `<resolved-root>/CLAUDE.md`.

## 5. Idempotent managed block

### 5.1 Markers (exact, stable — used for literal matching)

```
<!-- BEGIN autoskills -->
...managed content...
<!-- END autoskills -->
```

The first content line inside is a human-facing warning that edits within the markers may be overwritten.

### 5.2 Merge cases (the only piece with real logic)

> **Read the file first.** Whether done by the agent manually or by the helper script, the existing `CLAUDE.md` MUST be read before writing. The failure mode to avoid is reconstructing the block or the surrounding file from memory.

| Case | Action |
|---|---|
| File absent | Create `CLAUDE.md` containing just the block (markers + content). |
| File exists, markers present | Replace everything from `<!-- BEGIN autoskills -->` through `<!-- END autoskills -->` (inclusive) with the freshly built block. User content outside the markers is preserved verbatim. |
| File exists, no markers | Append the block to the end (after a blank-line separator). Existing content is preserved verbatim. |

Running twice with identical input produces a byte-identical file (idempotent).

### 5.3 Helper script — `scripts/upsert-claude-md.mjs` (optional)

- **Owns the markers.** Reads the inner content from **stdin**; wraps it in the BEGIN/END markers itself so markers can never drift or be mangled by the model.
- **Usage:** `node scripts/upsert-claude-md.mjs <target-CLAUDE.md-path> < block-content`
- **Behavior:** implements the three cases in §5.2 via literal marker search + string slicing (no regex on user content). Writes the file; prints `created|updated|appended <path>` to stderr.
- **Dependency-free** Node (Windows-friendly), matching `index-local-skills.mjs`.
- **Consent stays in the skill, not the script:** the agent builds the content, shows it to the user, STOPS for confirmation, and only then pipes it to the script. The script is pure mechanism.

The skill must remain fully usable without the script: `references/claude-md.md` documents the manual fallback (Read `CLAUDE.md` → copy the current `BEGIN…END` block **verbatim** as the Edit `old_string` and replace; or append; or create).

## 6. Content template

Built from the Step 5–6 ranked recommendations. Critically, it **distinguishes skills a future agent can invoke immediately from online skills that must be installed first** — otherwise the next session reads "use skill X", can't find X, and is stuck.

```markdown
<!-- BEGIN autoskills -->
<!-- Maintained by the autoskills skill. Edits between these markers may be overwritten on the next run. -->
## Recommended skills for this project (autoskills)

Detected domain(s): <domain list>. Use these skills proactively — don't wait to be asked.

**Use directly (already invokable):**
- `<skill-name>` — <use-when>

**Install first, then use** (online, not yet installed):
- `<owner/repo@skill>` — <use-when> · install: `npx skills add <owner/repo@skill> -g -y`

Full problem→skill history: consult `~/.claude/skills/autoskills/registry/`.

_Last updated by autoskills: <session-date>._
<!-- END autoskills -->
```

Rules:
- A registry/local **invokable** skill (usable via the `Skill` tool now) goes under **Use directly**.
- An **online** skill goes under **Install first** — UNLESS the user accepted its install back in Step 6, in which case it is now invokable and moves to **Use directly**.
- The **Install first** subsection is omitted entirely when there are no uninstalled online recommendations.
- Only Strong/Decent skills appear. Never list `unsynced`/unavailable catalog names.
- Date uses the session's current date.

## 7. Why keep both persistence layers (not redundant)

| Layer | Location | Tracked by git? | Scope | Role |
|---|---|---|---|---|
| Project memory pointer (Step 7) | `~/.claude/projects/<hash>/memory/MEMORY.md` (home dir) | No (machine-local) | This machine, this project | Makes the agent aware the **global registry** exists (cross-project recall). |
| `CLAUDE.md` block (Step 8) | `<repo-root>/CLAUDE.md` | **Yes** (travels with the repo) | Anyone who clones/opens the repo | Tells the next agent **which specific skills** to use here, proactively. |

They target different audiences and survive different events (a fresh clone has the `CLAUDE.md`; a machine-local memory file does not). Keeping both is deliberate.

## 8. Consent flow (imperative)

Step 8 / `references/claude-md.md` MUST instruct, in imperative terms:

1. Build the managed-block content from the Strong/Decent recommendations.
2. Print the **exact block** and the **resolved target path**.
3. **STOP and wait for explicit user confirmation.** Do not run any Write/Edit/script before the user says yes.
4. On confirm: upsert via the helper script (or the manual Read→Edit fallback), then report what changed (`created` / `updated in place` / `appended`).
5. On decline: skip silently; the registry/memory recording from Step 7 still stands.

## 9. Files changed

| File | Change |
|---|---|
| `SKILL.md` | Add **Step 8**; link `references/claude-md.md`; mention `scripts/upsert-claude-md.mjs` in the reference list. |
| `references/claude-md.md` | **New.** When to offer, location resolution (§4), markers + merge cases (§5), content template (§6), consent flow (§8). |
| `scripts/upsert-claude-md.mjs` | **New.** Deterministic idempotent upsert (§5.3). Optional helper. |
| `tests/check-claude-md.sh` | **New.** Doc-presence checks: Step 8 in SKILL.md, reference exists with markers/consent/template/merge-cases. |
| `tests/test-upsert-claude-md.sh` | **New.** Behavioral checks: create / in-place replace / append-preserving / idempotency. |
| `tests/check-integration.sh` | Add `references/claude-md.md` and `scripts/upsert-claude-md.mjs` to the must-exist list. |
| (runtime) `~/.claude/skills/autoskills/` | **Redeploy** after build — the feature is only live once deployed (the existing deploy copies `references/*.md` and `scripts/`, so the new files are covered; registry is preserved). |

## 10. Testing strategy

- **Behavioral (real assertions):** `test-upsert-claude-md.sh` exercises the script over the three merge cases + idempotency in a temp dir. This is where correctness is actually verified — grep-on-docs cannot.
- **Doc-presence:** `check-claude-md.sh` asserts the SKILL.md step and reference content exist and cross-reference correctly.
- **Integration:** `check-integration.sh` confirms all SKILL.md cross-references resolve, including the two new files.

## 11. Out of scope (YAGNI)

- No auto-write without confirmation (consent model forbids it).
- No editing of content outside the markers, ever.
- No CI/git-hook auto-refresh of the block.
- No multi-file fan-out (one `CLAUDE.md` at the repo root only).
- No removal/migration of the existing memory pointer.

## 12. Risks & mitigations

| Risk | Mitigation |
|---|---|
| Clobbering user `CLAUDE.md` content | Markers + slice-based upsert; never touch outside markers; read-before-write; consent gate. |
| Listing an uninstalled online skill as directly usable | Template splits "Use directly" vs "Install first" (§6). |
| Block drifts from the registry over time | Re-running autoskills re-upserts in place; the block is dated. |
| Model reconstructs the block from memory instead of copying | Helper script owns the merge; manual fallback says copy the read block **verbatim**. |
| "Tests pass" misread as "merge works" | Behavioral test (§10) verifies merge; doc-presence tests are clearly separate. |
| Editing dev repo only | Redeploy step is explicit (§9). |
