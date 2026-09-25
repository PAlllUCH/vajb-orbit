# dispatch_designer.md — the graphics lane's queue of record

Purged and regenerated 2026-09-25 (owner ask: "too much shit to keep track of
it" — the queue carries only live items; closed work lives in
`MASTER_REPORT.md` §6 and git). Execute one item per order; briefs/prompts
live in the slice folders. **Model: `opencode-go/mimo-v2.6-pro` for every
design worker** on `--reasoning-effort low` (owner standing rule 2026-09-25;
measured that day, `medium` stalls on long worker loops while `low` is fast).
The owner pastes only the handoff block at the bottom.

**File-collision law:** two waves never hold one file (nor the same `test_*`
prefix, nor one `staging/` driver). One live session per workspace.

## The standing ruling (owner, 2026-09-22) — lane law, applies to every item

- Glyph-type icons are **remade as SVG masters** (flat symbol side); depictive
  icons keep **one raster master only** ("we will scale it"); delete all
  non-master rasters **project-side only** (`asset-library/` keeps every
  cut). SVG: flat shapes, `viewBox="0 0 96 96"`, 8-14 flat shapes, fills
  only, at most two tones (Steel `#565C63` + ember `#C8461B`/`#E8703A` where
  danger/warn). A remade glyph's tint variants die with it.

## Queue

| # | Wave | Item | What | Status |
|---|---|---|---|---|
| 14 | D13 | **Armory rework — the design** (owner ask 2026-09-25, verbatim: "rework armory with vision skill and reasoning on how it should like with brainstorming to used and mockups") | `slices/D13-armory-rework/` | **QUEUED — next.** Input: the D12-A0 audit recap (pinned in `D13_BRIEF.md` §3), the live capture in the slice's `_evidence/`, L208. Design only — no code, no docs; the implementation wave follows the owner's ticks. |

## Parked (owner-gated — not queued; say the item and its five-piece lands)

- **D9 item 11** — player-hull visibility (PICK 2026-09-24: scale bump only,
  target ~56 px proposed); waits on the coder waves' `game/` set.
- **D10 item 12** — polish batch (PICKS 2026-09-24: status close-X, launch
  arm countdown, auction hull thumbnails, mining-beam visibility); waits on
  `ui/station/`.
- **D3 item 1** — chrome re-cut (GO 2026-09-24 on
  `staging/phase_f/_preview/review_slots.png`).
- **D3 2a/2b** — painted station rail icons; tint rework + the 540-file
  import-settings cleanup.
- **D4 3/4** — 4K 2× backdrop cuts; B2-1 hover look (flicker/directional
  glow/ember).
- **Items 5/6** — MMO/faction liveries, boss hulls (blocked on the naming
  overhaul); component icons ×18 (verify against `D2_SPLIT.md`).
- **The armory rework's implementation** — after D13's ticks.

## Done

Items 1-13 closed (D2 icon unification, D6 instruments, D7 cockpit rework,
D11 station scene, the D8/D12 fix waves ditched or absorbed); detail in
`.agents/gen/MASTER_REPORT.md` §6. The last closed wave: item 13 = **D11
station scene** (2026-09-25, gate 807 → 812/0, 0 HIGH / 2 MED cured / 7 LOW
L184-L190). The D12 ARMORY fix wave and D8 item 9 were **ditched by the owner
2026-09-25** — the armory takes the D13 rework instead; the audit recap is
preserved in the D13 brief.

## Pipeline law (read before any generation run — AGENTS.md "Asset Generation")

Panel order: render → find objects (`panels.py --detect`) → cut each → key
each → trim. `flare` never returns native alpha — `--post-only`. FX stay RGB
except the four §0.1 names. 2K run = 10 credits = $0.05. Delivery order:
generate → stage → **review sheet → owner approval** → ship → reimport →
`validate_names.py --library`. Generation logs beside every shipped family.

## Handoff (live)

**Designer item 14 = D13 armory rework is QUEUED and ready** (brief
`slices/D13-armory-rework/D13_BRIEF.md`, prompts `D13_prompts.md`; the D12-A0
audit recap and the live capture travel inside the slice). The coder lane's
single live item is item 17 = **S17 jump gates to sector edges**
(`dispatch_coder.md`). Everything else is parked above.
