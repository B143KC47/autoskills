#!/usr/bin/env bash
set -e
grep -qi "Recording procedure" references/registry-format.md
grep -q "skillmap-<category>" references/registry-format.md
# outcome notes: objective, verifiable schema + deterministic tier movement + retention
grep -qi "Outcome notes" references/registry-format.md
grep -q "expected:" references/registry-format.md
grep -q "observed:" references/registry-format.md
grep -q "evidence:" references/registry-format.md
grep -qi "Never edit the skill's own upstream" references/registry-format.md
grep -qi "Tier movement" references/registry-format.md
grep -qi "3 newest outcome notes" references/registry-format.md
grep -q "skillmap-research.md" registry/INDEX.md
grep -q "deep-research" registry/skillmap-research.md
# the unsynced placeholder may be listed as unavailable, but must NEVER carry a recommendation tier
! grep -qiE "^\- 0-autoresearch-skill \|.*tier:" registry/skillmap-research.md
# deep-research must be the available recommendation
grep -qE "deep-research \| registry \| tier:Strong" registry/skillmap-research.md
grep -q "name: skillmap-research" registry/skillmap-research.md
echo "PASS check-registry"
