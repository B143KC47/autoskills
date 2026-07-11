#!/usr/bin/env bash
set -e
f="SKILL.md"
grep -q "^name: autoskills$" "$f"
grep -qi "description:.*find" "$f"
# SDO: description states triggers only ("Use when..."), never the workflow
grep -q "^description: Use when" "$f"
! grep -qi "^description:.*rubric" "$f"
! grep -qi "^description:.*registry" "$f"
# workflow invariants
grep -qi "Fast path" "$f"
grep -qi "Offline fallback" "$f"
grep -qi "When NOT to use" "$f"
grep -q "references/evaluation.md" "$f"
grep -q "references/registry-format.md" "$f"
grep -q "references/folder-scan.md" "$f"
grep -q "scripts/index-local-skills.mjs" "$f"
grep -q "Step 7" "$f"
# catalog covers Codex's user-level skills root too
grep -q ".codex/skills" "$f"
echo "PASS check-skill-md"
