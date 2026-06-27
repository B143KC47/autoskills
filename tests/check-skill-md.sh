#!/usr/bin/env bash
set -e
f="SKILL.md"
grep -q "^name: autoskills$" "$f"
grep -qi "description:.*find" "$f"
grep -q "references/evaluation.md" "$f"
grep -q "references/registry-format.md" "$f"
grep -q "references/folder-scan.md" "$f"
grep -q "scripts/index-local-skills.mjs" "$f"
grep -q "Step 7" "$f"
echo "PASS check-skill-md"
