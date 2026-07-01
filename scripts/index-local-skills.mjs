#!/usr/bin/env node
// Lists local skills with name + description and an availability status.
// Robust to broken/unsynced symlinks: many entries under ~/.claude/skills and
// ~/.agents/skills symlink into ~/.orchestra/skills, which may be absent on a
// given machine. We NEVER crash on a dead link, and we ALWAYS emit the skill
// NAME — a name is a usable match signal even when its linked content is gone.
// Usage: node index-local-skills.mjs [keyword]
// Roots default to ~/.claude/skills and ~/.agents/skills; override with the
// AUTOSKILLS_SKILL_ROOTS env var (platform path-delimiter-separated) — used by
// the hermetic tests and useful for nonstandard skill locations.
//
// Status values:
//   ok        SKILL.md is readable and non-empty (usable now)
//   empty     resolves but no SKILL.md / empty body
//   unsynced  broken/dead symlink — content unavailable (restore ~/.orchestra/skills)
//   missing   path not present / not a directory
import { readdirSync, readFileSync, existsSync, lstatSync, statSync } from 'node:fs';
import { join, delimiter } from 'node:path';
import { homedir } from 'node:os';

const ROOTS = process.env.AUTOSKILLS_SKILL_ROOTS
  ? process.env.AUTOSKILLS_SKILL_ROOTS.split(delimiter).filter(Boolean)
  : [
      join(homedir(), '.claude', 'skills'),
      join(homedir(), '.agents', 'skills'),
    ];
const RANK = { ok: 3, empty: 2, unsynced: 1, missing: 0 };
const keyword = (process.argv[2] || '').toLowerCase();

function parseFrontmatter(text) {
  if (!text.startsWith('---')) return {};
  const end = text.indexOf('\n---', 3);
  if (end === -1) return {};
  const out = {};
  const fm = text.slice(3, end).replace(/\r/g, ''); // tolerate CRLF (Windows) line endings
  for (const line of fm.split('\n')) {
    const m = line.match(/^(\w+):\s*(.*)$/);
    if (m) out[m[1]] = m[2].trim();
  }
  return out;
}

// Classify one skill entry. Never throws.
function classify(dir) {
  let isLink = false;
  try { isLink = lstatSync(dir).isSymbolicLink(); } catch { return { status: 'missing', desc: '' }; }
  let target;
  try { target = statSync(dir); } catch { return { status: isLink ? 'unsynced' : 'missing', desc: '' }; }
  if (!target.isDirectory()) return { status: 'missing', desc: '' };
  const skillFile = join(dir, 'SKILL.md');
  if (!existsSync(skillFile)) return { status: 'empty', desc: '' };
  let text;
  try { text = readFileSync(skillFile, 'utf8'); } catch { return { status: 'unsynced', desc: '' }; }
  const body = text.replace(/^---[\s\S]*?\n---/, '').trim();
  const desc = parseFrontmatter(text).description || '';
  return { status: body.length === 0 ? 'empty' : 'ok', desc };
}

// Merge across roots, keeping the best status and any description found.
const byName = new Map();
for (const root of ROOTS) {
  let names = [];
  try { names = readdirSync(root); } catch { continue; }
  for (const name of names) {
    const c = classify(join(root, name));
    const prev = byName.get(name);
    if (!prev || RANK[c.status] > RANK[prev.status]) {
      byName.set(name, { name, status: c.status, desc: c.desc || (prev ? prev.desc : '') });
    } else if (prev && !prev.desc && c.desc) {
      prev.desc = c.desc;
    }
  }
}

let rows = [...byName.values()];
if (keyword) {
  rows = rows.filter(r =>
    r.name.toLowerCase().includes(keyword) ||
    r.desc.toLowerCase().includes(keyword));
}

for (const r of rows.sort((a, b) => a.name.localeCompare(b.name))) {
  console.log(`${r.name} | ${r.status} | ${r.desc.slice(0, 140)}`);
}
const counts = rows.reduce((a, r) => (a[r.status] = (a[r.status] || 0) + 1, a), {});
console.error(`\n${rows.length} skill(s)${keyword ? ` matching "${keyword}"` : ''} — ${JSON.stringify(counts)}`);
