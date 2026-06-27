#!/usr/bin/env bash
set -e
# 1. Must NOT crash when the skills dir is full of broken/unsynced symlinks.
out=$(node scripts/index-local-skills.mjs fine)
# 2. Name-based match works even when the skill's content is unsynced.
echo "$out" | grep -qi "trl-fine-tuning"
# 3. The autoresearch placeholder is surfaced but never usable: its status must
#    be 'unsynced' or 'empty' (it is a dead symlink here), and never 'ok'.
status=$(node scripts/index-local-skills.mjs autoresearch)
echo "$status" | grep -qE "0-autoresearch-skill \| (unsynced|empty)"
! echo "$status" | grep -q "0-autoresearch-skill | ok"
# 4. CRLF frontmatter must still yield a description for a resolving (ok) skill.
desc=$(node scripts/index-local-skills.mjs write-a-skill)
echo "$desc" | grep -qE "write-a-skill \| ok \| .+"
echo "PASS test-index-local-skills"
