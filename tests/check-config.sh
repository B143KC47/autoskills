#!/usr/bin/env bash
set -e
f="config.json.example"
# valid JSON with the four documented keys and safe defaults
node -e "
const c = JSON.parse(require('fs').readFileSync('$f', 'utf8'));
if (c.auto_install !== false) throw new Error('auto_install must default to false');
if (c.min_tier !== 'strong') throw new Error('min_tier must default to strong');
if (typeof c.trust_floor !== 'number') throw new Error('trust_floor must be a number');
if (typeof c.finders !== 'number' || c.finders < 1) throw new Error('finders must be >=1');
"
# SKILL.md wires the config in
grep -q "config.json" SKILL.md
grep -qi "auto_install" SKILL.md
grep -qi "auto-install never bypasses the sanity gate" SKILL.md
echo "PASS check-config"
