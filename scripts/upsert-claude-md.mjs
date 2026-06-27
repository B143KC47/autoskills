#!/usr/bin/env node
// Idempotently upserts an autoskills-maintained block into a target CLAUDE.md.
// Inner block content is read from stdin; THIS script owns the BEGIN/END markers.
//
// Safety invariant: only a WELL-FORMED managed block — a `<!-- BEGIN autoskills -->`
// line and a matching `<!-- END autoskills -->` line, each ALONE on its own line,
// with no BEGIN line between them — is ever replaced. Any other text (prose that
// merely mentions a marker, a stray/orphaned marker line, content between blocks)
// is preserved verbatim. On update, the first managed block is replaced in place
// and any extra duplicate managed blocks are removed, so the file always converges
// to exactly one block.
//
// Usage: node upsert-claude-md.mjs <target-CLAUDE.md-path>   < block-content
import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { dirname } from 'node:path';

const BEGIN = '<!-- BEGIN autoskills -->';
const END = '<!-- END autoskills -->';

// A managed block: BEGIN line, then body containing NO further BEGIN line
// (tempered token), then END line. CRLF-tolerant. Global + multiline.
const BLOCK_RE = new RegExp(
  String.raw`^[ \t]*<!-- BEGIN autoskills -->[ \t]*\r?\n` +
    String.raw`(?:(?!^[ \t]*<!-- BEGIN autoskills -->[ \t]*\r?$)[\s\S])*?` +
    String.raw`^[ \t]*<!-- END autoskills -->[ \t]*(?=\r?$)`,
  'gm'
);

function fail(msg) {
  console.error(msg);
  process.exit(2);
}

const target = process.argv[2];
if (!target) fail('usage: node upsert-claude-md.mjs <target-CLAUDE.md-path> < block-content');

// Normalize stdin to LF and trim; reject empty and marker-bearing content.
const inner = readFileSync(0, 'utf8').replace(/\r\n/g, '\n').trim();
if (!inner) fail('error: empty block content on stdin');
for (const line of inner.split('\n')) {
  if (line.trim() === BEGIN || line.trim() === END) {
    fail('error: block content must not contain an autoskills marker line');
  }
}

let action, out;
if (!existsSync(target)) {
  mkdirSync(dirname(target) || '.', { recursive: true });
  out = `${BEGIN}\n${inner}\n${END}\n`;
  action = 'created';
} else {
  const raw = readFileSync(target, 'utf8');
  const eol = raw.includes('\r\n') ? '\r\n' : '\n';
  const block = `${BEGIN}${eol}${inner.replace(/\n/g, eol)}${eol}${END}`;
  if (BLOCK_RE.test(raw)) {
    let n = 0;
    out = raw.replace(BLOCK_RE, () => (n++ === 0 ? block : ''));
    action = 'updated';
  } else {
    out = raw.replace(/[\r\n]*$/, '') + `${eol}${eol}${block}${eol}`;
    action = 'appended';
  }
}

try {
  writeFileSync(target, out);
} catch (e) {
  fail(`error: cannot write ${target}: ${e.message}`);
}
console.error(`${action} ${target}`);
