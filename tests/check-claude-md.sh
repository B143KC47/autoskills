#!/usr/bin/env bash
set -e
f="references/claude-md.md"
grep -q "BEGIN autoskills" "$f"
grep -q "END autoskills" "$f"
grep -qi "rev-parse --show-toplevel" "$f"      # location resolution
grep -qi "STOP" "$f"                            # consent gate
grep -qi "Use directly" "$f"                    # template split (available to a fresh session)
grep -qi "Make available first" "$f"            # template split (online/session-only)
grep -qi "Get-Content" "$f"                     # cross-shell (PowerShell) upsert recipe
grep -q "YYYY-MM-DD" "$f"                        # explicit date format
grep -q "upsert-claude-md.mjs" "$f"             # optional helper referenced
echo "PASS check-claude-md"
