# Deep Search — capability-tiered procedure (SKILL.md Step 3)

Goal: many cheap finders sweep the online ecosystem from different angles; a stronger
model then verifies each candidate against the rubric. Pick the HIGHEST tier your
harness supports. All tiers produce the same output shape, so Step 4 merging is identical.

## Candidate shape (all tiers)
```json
{ "name": "", "source": "owner/repo@skill or url", "installs": 0, "stars": 0,
  "description": "", "url": "" }
```

## Verified shape (after verification, all tiers)
```json
{ "candidate": { }, "scores": { "fit": 0, "trust": 0, "track": 0, "fresh": 0, "spec": 0 },
  "total": 0, "tier": "Strong|Decent|Weak|No fit", "evidence": ["observable fact ..."] }
```

## Finder angles (used by every tier)
1. **Ecosystem:** `npx skills find <query>` (plus 1–2 keyword variants).
2. **Leaderboard:** skills.sh leaderboard entries for the domain.
3. **Fresh releases:** web search for recently published skills in the domain.
4. **GitHub:** repo search for `SKILL.md` files matching the query.

If `config.finders` > 4, split angle 1 into more query variants. A finder whose
network/`npx` call fails returns `[]` — never abort the whole search for one angle.

## Tier 1 — Workflow tool (Claude Code)
Fill `<QUERY>`, `<FINDERS>` (from config), `<TRACK_RECORD>` (relevant registry lines, or
"none") into this template and run it via the `Workflow` tool:

```js
export const meta = {
  name: 'autoskills-deep-search',
  description: 'Fan out skill finders, then verify each candidate against the rubric',
  phases: [
    { title: 'Find', detail: 'parallel finders, one search angle each', model: 'sonnet' },
    { title: 'Verify', detail: 'one adversarial verifier per candidate', model: 'opus' },
  ],
}
const CANDIDATES = { type: 'object', properties: { candidates: { type: 'array', items: {
  type: 'object', properties: { name: {type:'string'}, source: {type:'string'},
    installs: {type:'number'}, stars: {type:'number'}, description: {type:'string'},
    url: {type:'string'} }, required: ['name','source','description'] } } },
  required: ['candidates'] }
const VERDICT = { type: 'object', properties: {
  scores: { type: 'object', properties: { fit:{type:'number'}, trust:{type:'number'},
    track:{type:'number'}, fresh:{type:'number'}, spec:{type:'number'} },
    required: ['fit','trust','track','fresh','spec'] },
  total: {type:'number'}, tier: {type:'string'},
  evidence: { type: 'array', items: {type:'string'} } },
  required: ['scores','total','tier','evidence'] }

const ANGLES = args.angles // finder prompts built from the 4 angles + query variants
phase('Find')
const found = await parallel(ANGLES.map((a, i) => () =>
  agent(a, { label: `find:${i}`, phase: 'Find', model: 'sonnet', schema: CANDIDATES })))
// barrier justified: dedup needs every finder's output
const seen = new Set()
const deduped = found.filter(Boolean).flatMap(r => r.candidates)
  .filter(c => !seen.has(c.source) && seen.add(c.source))
log(`${deduped.length} unique candidates`)
phase('Verify')
const verified = await parallel(deduped.map(c => () =>
  agent(`Adversarially verify this skill candidate for the task "${args.query}".
Apply the autoskills rubric (read ~/.claude/skills/autoskills/references/evaluation.md):
score 0-2 on Fit, Trust, Track-record, Freshness, Specificity; Fit 0 => tier "No fit".
Registry track-record for it: ${args.trackRecord}. Try to REFUTE fit; if its content or
claims cannot be read/verified, drop it (total 0). Every evidence line must be an
observable fact (install count, repo date, quoted description), not an opinion.
Candidate: ${JSON.stringify(c)}`,
    { label: `verify:${c.name}`, phase: 'Verify', model: 'opus', schema: VERDICT })
    .then(v => ({ candidate: c, ...v }))))
return { verified: verified.filter(Boolean).filter(v => v.tier !== 'No fit')
  .sort((a, b) => b.total - a.total) }
```

Pass `args: { query, angles, trackRecord }` where `angles` is one finder prompt per
angle, e.g. `"Run \`npx skills find <query>\` in a shell and return every result as a
candidate object; empty list if the command fails."`

## Tier 2 — subagents, no Workflow tool
Dispatch the finder angles as parallel general-purpose agents (Sonnet-class if the
harness lets you choose). Dedup by `source` yourself, then dispatch ONE Opus-class
verification agent with the full deduped list, the rubric text, and the registry
track-record; require the Verified shape per candidate.

## Tier 3 — inline (no subagents — e.g. Codex)
Run the same four finder angles yourself, sequentially, with shell + web only.
Dedup by `source`, then score each candidate yourself with `evaluation.md`, writing an
`evidence` list of observable facts per candidate before assigning the tier. The
procedure is identical — only the parallelism and the second model are missing.

## After any tier
Feed the surviving verified candidates into SKILL.md Step 4 (merge with local — do not
re-score them) and Step 6 (auto-install gate reads `config.json`).
