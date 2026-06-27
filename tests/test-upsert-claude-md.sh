#!/usr/bin/env bash
set -e
script="scripts/upsert-claude-md.mjs"
tmp=$(mktemp -d)
begins() { grep -c 'BEGIN autoskills' "$1"; }

# Case 1: create when file is absent
f="$tmp/CLAUDE.md"
printf 'ALPHA' | node "$script" "$f"
grep -q "BEGIN autoskills" "$f"
grep -q "END autoskills" "$f"
grep -q "ALPHA" "$f"

# Case 2: in-place replace when markers present (old content gone, exactly one marker pair)
printf 'BRAVO' | node "$script" "$f"
grep -q "BRAVO" "$f"
! grep -q "ALPHA" "$f"
[ "$(begins "$f")" = "1" ]

# Case 3: append, preserving user content, when no markers present
g="$tmp/USER.md"
printf '# My Project\nuser stuff\n' > "$g"
printf 'CHARLIE' | node "$script" "$g"
grep -q "My Project" "$g"
grep -q "user stuff" "$g"
grep -q "CHARLIE" "$g"
grep -q "BEGIN autoskills" "$g"

# Case 4: idempotency — identical input twice yields a byte-identical file
h="$tmp/IDEM.md"
printf 'DELTA' | node "$script" "$h"
cp "$h" "$h.first"
printf 'DELTA' | node "$script" "$h"
diff "$h.first" "$h"
[ "$(begins "$h")" = "1" ]

# Case 5 (BLOCKER): a stray inline BEGIN marker plus a real managed block must NOT delete user content
b="$tmp/STRAY.md"
printf 'keep-A <!-- BEGIN autoskills --> keep-B\n<!-- BEGIN autoskills -->\nOLD\n<!-- END autoskills -->\n' > "$b"
printf 'NEW' | node "$script" "$b"
grep -q "keep-A" "$b"           # user prose preserved
grep -q "keep-B" "$b"           # text after an inline marker preserved (was deleted by the old code)
grep -q "NEW" "$b"              # managed block updated
! grep -q "OLD" "$b"            # old managed content replaced

# Case 6: a stray END in user prose must not cause block accumulation across runs
p="$tmp/PROSE.md"
printf 'docs mention <!-- END autoskills --> in text\n' > "$p"
printf 'ONE' | node "$script" "$p"
printf 'ONE' | node "$script" "$p"
grep -q "docs mention" "$p"
[ "$(begins "$p")" = "1" ]      # exactly one managed block, not two

# Case 7: two pre-existing managed blocks collapse to one (stale duplicate removed)
d="$tmp/DUP.md"
printf '<!-- BEGIN autoskills -->\nOLD1\n<!-- END autoskills -->\nmid\n<!-- BEGIN autoskills -->\nOLD2\n<!-- END autoskills -->\n' > "$d"
printf 'FRESH' | node "$script" "$d"
[ "$(begins "$d")" = "1" ]
grep -q "FRESH" "$d"
grep -q "mid" "$d"              # user content between blocks preserved
! grep -q "OLD2" "$d"           # stale duplicate removed

# Case 8: stdin containing a marker line is rejected (non-zero exit, file untouched)
m="$tmp/NOPE.md"
printf 'pre-existing\n' > "$m"
if printf 'x\n<!-- BEGIN autoskills -->\ny' | node "$script" "$m" 2>/dev/null; then
  echo "FAIL: marker-bearing stdin should be rejected"; exit 1
fi
diff <(printf 'pre-existing\n') "$m"   # file unchanged

# Case 9: empty / whitespace-only stdin is rejected
e="$tmp/EMPTY.md"
if printf '   \n' | node "$script" "$e" 2>/dev/null; then
  echo "FAIL: empty stdin should be rejected"; exit 1
fi
[ ! -f "$e" ]                   # nothing written

# Case 10: CRLF file updates idempotently
c="$tmp/CRLF.md"
printf '# Title\r\nbody\r\n' > "$c"
printf 'CRLFTEST' | node "$script" "$c"
cp "$c" "$c.first"
printf 'CRLFTEST' | node "$script" "$c"
diff "$c.first" "$c"            # idempotent on a CRLF file
[ "$(begins "$c")" = "1" ]
grep -q "Title" "$c"

# Case 11: create into a not-yet-existing subdirectory succeeds (parent dirs made)
s="$tmp/newdir/sub/CLAUDE.md"
printf 'SUBDIR' | node "$script" "$s"
grep -q "SUBDIR" "$s"

# Case 12 (BLOCKER scenario 2): a truncated managed block (BEGIN alone, no END)
# followed by user text must never lose that text, across repeated runs.
t12="$tmp/TRUNC.md"
printf '<!-- BEGIN autoskills -->\nuser-line-keepme\nmore user text\n' > "$t12"
printf 'FRESH12' | node "$script" "$t12"
grep -q "user-line-keepme" "$t12"          # preserved on first (append) run
printf 'FRESH12' | node "$script" "$t12"
grep -q "user-line-keepme" "$t12"          # still preserved on second (update) run
grep -q "more user text" "$t12"
grep -q "FRESH12" "$t12"

rm -rf "$tmp"
echo "PASS test-upsert-claude-md"
