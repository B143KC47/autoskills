#!/usr/bin/env bash
set -e
f="references/evaluation.md"
grep -qi "Sanity gate" "$f"
for d in "Fit" "Trust" "Track record" "Freshness" "Specificity"; do grep -q "$d" "$f"; done
for t in "Strong" "Decent" "Weak" "No fit"; do grep -q "$t" "$f"; done
echo "PASS check-evaluation"
