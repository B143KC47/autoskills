#!/usr/bin/env bash
set -e
# files the skill depends on must exist (the reference docs + helper scripts;
# this is a curated dependency list, not an auto-derived scan of SKILL.md)
for ref in references/evaluation.md references/registry-format.md references/folder-scan.md references/claude-md.md references/deep-search-workflow.md config.json.example scripts/index-local-skills.mjs scripts/upsert-claude-md.mjs registry/INDEX.md registry/skillmap-research.md; do
  test -f "$ref" || { echo "MISSING $ref"; exit 1; }
done
# supersede note present
grep -qi "find-skills" SKILL.md
# Step 8 (CLAUDE.md reminder) wired in
grep -q "Step 8" SKILL.md
grep -q "references/claude-md.md" SKILL.md
# all per-file checks still pass
for t in check-skill-md check-evaluation check-registry check-folder-scan check-claude-md check-config check-deep-search; do bash "tests/$t.sh" >/dev/null; done
bash tests/test-index-local-skills.sh >/dev/null
bash tests/test-upsert-claude-md.sh >/dev/null
echo "PASS check-integration"
