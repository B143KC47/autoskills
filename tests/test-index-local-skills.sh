#!/usr/bin/env bash
set -e
# Hermetic behavioral test: builds its own fixture skill roots instead of
# depending on any particular machine's ~/.claude/skills contents, so it
# passes identically on CI runners and on any user's clone.
script="scripts/index-local-skills.mjs"
tmp=$(mktemp -d)
root="$tmp/skills"
mkdir -p "$root/good-skill" "$root/empty-skill" "$root/bodyless-skill" "$root/.system"

# dot-entries (e.g. Codex's bundled ~/.codex/skills/.system) must be skipped
printf -- '---\nname: hidden\ndescription: must not list\n---\nbody\n' > "$root/.system/SKILL.md"

# ok: readable SKILL.md — with CRLF (Windows) frontmatter, which must still
# yield a description.
printf -- '---\r\nname: good-skill\r\ndescription: Fine-tune helpers for tests\r\n---\r\n\r\nBody text.\r\n' > "$root/good-skill/SKILL.md"
# empty: directory without SKILL.md (created above, left bare)
# bodyless: frontmatter only, no body -> empty
printf -- '---\nname: bodyless-skill\ndescription: has no body\n---\n' > "$root/bodyless-skill/SKILL.md"

# unsynced: dead symlink. Symlink creation can be unavailable on Windows
# without Developer Mode — skip only that case there; CI (Linux) always runs it.
symlink_ok=1
node -e "require('fs').symlinkSync(process.argv[1], process.argv[2], 'dir')" \
  "$tmp/missing-target" "$root/unsynced-skill" 2>/dev/null || symlink_ok=0

# Point the script at the fixture root (native path form where cygpath exists,
# e.g. Git Bash on Windows; POSIX path elsewhere).
export AUTOSKILLS_SKILL_ROOTS="$(cygpath -w "$root" 2>/dev/null || echo "$root")"

out=$(node "$script")
# 0. Dot-entries are never listed (Codex .system bundles, .DS_Store, ...).
! echo "$out" | grep -qF ".system"
# 1. Statuses classified correctly, descriptions parsed through CRLF frontmatter.
echo "$out" | grep -qF "good-skill | ok | Fine-tune helpers for tests"
echo "$out" | grep -qF "empty-skill | empty"
echo "$out" | grep -qF "bodyless-skill | empty | has no body"
if [ "$symlink_ok" = 1 ]; then
  # 2. A dead symlink is surfaced by NAME but never usable: unsynced, not ok.
  echo "$out" | grep -qF "unsynced-skill | unsynced"
  ! echo "$out" | grep -qF "unsynced-skill | ok"
else
  echo "SKIP unsynced case (symlinks unsupported on this machine)"
fi

# 3. Keyword filter matches name OR description, case-insensitively.
filtered=$(node "$script" fine)
echo "$filtered" | grep -qF "good-skill"
! echo "$filtered" | grep -qF "empty-skill"

# 4. Robustness: a nonexistent root must not crash and lists nothing.
none=$(AUTOSKILLS_SKILL_ROOTS="$tmp/does-not-exist" node "$script")
[ -z "$none" ]

# 5. Default roots (no override) must never crash, whatever this machine has.
unset AUTOSKILLS_SKILL_ROOTS
node "$script" >/dev/null

rm -rf "$tmp"
echo "PASS test-index-local-skills"
