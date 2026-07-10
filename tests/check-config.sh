#!/usr/bin/env bash
set -e
f="config.json.example"
# valid JSON with the five documented keys and safe defaults
node -e "
const c = JSON.parse(require('fs').readFileSync('$f', 'utf8'));
if (c.auto_install !== false) throw new Error('auto_install must default to false');
if (c.min_tier !== 'strong') throw new Error('min_tier must default to strong');
if (typeof c.trust_floor !== 'number' || c.trust_floor < 2) throw new Error('trust_floor must default to >=2 — unattended installs need reputable-owner trust');
if (typeof c.finders !== 'number' || c.finders < 1) throw new Error('finders must be >=1');
if (typeof c.max_verify !== 'number' || c.max_verify < 1) throw new Error('max_verify must be >=1');
"
# SKILL.md wires the config in
grep -q "config.json" SKILL.md
grep -qi "auto_install" SKILL.md
grep -qi "max_verify" SKILL.md
grep -qi "auto-install never bypasses the sanity gate" SKILL.md
# a mid-session install is not yet Skill-tool invokable; content is skimmed before use
grep -qi "Read its installed .SKILL.md. from disk" SKILL.md
grep -qi "skim its content for suspicious instructions" SKILL.md
echo "PASS check-config"
