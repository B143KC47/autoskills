#!/usr/bin/env bash
set -e
f="references/folder-scan.md"
grep -qi "Signal" "$f"
grep -q "requirements.txt" "$f"
grep -q "package.json" "$f"
grep -qi "Explore" "$f"
echo "PASS check-folder-scan"
