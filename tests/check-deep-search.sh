#!/usr/bin/env bash
set -e
f="references/deep-search-workflow.md"
# three tiers, highest-capability first
grep -qi "Tier 1" "$f" && grep -qi "Workflow tool" "$f"
grep -qi "Tier 2" "$f" && grep -qi "no Workflow" "$f"
grep -qi "Tier 3" "$f" && grep -qi "Codex" "$f"
# model split: sonnet finders, opus verifiers
grep -q "model: 'sonnet'" "$f"
grep -q "model: 'opus'" "$f"
# adversarial verification grounded in the rubric with verifiable evidence
grep -qi "REFUTE" "$f"
grep -q "evaluation.md" "$f"
grep -qi "observable fact" "$f"
# resilience: one failed finder never kills the search
grep -qi "never abort" "$f"
# SKILL.md step 3 points here and gates the trigger
grep -q "references/deep-search-workflow.md" SKILL.md
grep -qi "no Strong local match" SKILL.md
echo "PASS check-deep-search"
