#!/usr/bin/env bash
set -e
grep -qi "Recording procedure" references/registry-format.md
grep -q "skillmap-<category>" references/registry-format.md
grep -q "skillmap-research.md" registry/INDEX.md
grep -q "deep-research" registry/skillmap-research.md
# the unsynced placeholder may be listed as unavailable, but must NEVER carry a recommendation tier
! grep -qiE "^\- 0-autoresearch-skill \|.*tier:" registry/skillmap-research.md
# deep-research must be the available recommendation
grep -qE "deep-research \| registry \| tier:Strong" registry/skillmap-research.md
grep -q "name: skillmap-research" registry/skillmap-research.md
echo "PASS check-registry"
