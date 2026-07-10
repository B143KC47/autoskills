#!/usr/bin/env bash
set -e
f="references/deep-search-workflow.md"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
# extract the first ```js fenced block
awk '/^```js$/{flag=1;next}/^```$/{flag=0}flag' "$f" > "$tmp/block.js"
test -s "$tmp/block.js" || { echo "no js block found in $f"; exit 1; }
# the block is a Workflow script: top-level await + return, `export const meta`.
# Wrap in an async IIFE (legalizes await/return) and strip the export keyword,
# then let node parse it — a pure syntax check, nothing executes.
{
  printf '(async () => {\n'
  sed 's/^export const meta/const meta/' "$tmp/block.js"
  printf '\n})();\n'
} > "$tmp/wrapped.js"
node --check "$tmp/wrapped.js"
echo "PASS check-workflow-syntax"
