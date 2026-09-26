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
| 15 | D14 | ARMORY chrome composition — brainstorm + Amendment 5 (owner 2026-09-26) | The pane must read as clean as AUCTION/SHIPYARD: per-surface chrome pinned from the art's own cut size, and the owner's "anchors + relative positioning" rule written as mechanism so two workers cannot diverge. Owner's words, the sibling idiom (`file:line`) and the measured defect table: `slices/D14-armory-chrome-composition/D14_BRIEF.md`; captures in its `_evidence/`. Design only (docs + mockup); shares no file with the coder lane's S19 wave. | **live** |

## Parked (owner-gated — not queued; say the item and its five-piece lands)


## Done

Items 1-13 closed (D2 icon unification, D6 instruments, D7 cockpit rework,
D11 station scene, the D8/D12 fix waves ditched or absorbed); detail in
`.agents/gen/MASTER_REPORT.md` §6. Item 14 = **D13 armory rework — design**
closed 2026-09-25 (gate 877/0 unmoved, 0 HIGH / 0 MED / 2 LOW L221-L222; A0 ran
interactively in the owner's session, R1 in-session; owner ticks: T1 y with
"all resolutions work", **T2 = B full-width dashboard**, T3-T8 y). Before that:
item 13 = **D11 station scene** (2026-09-25, gate 807 → 812/0, 0 HIGH / 2 MED
cured / 7 LOW L184-L190). The D12 ARMORY fix wave and D8 item 9 were
**ditched by the owner 2026-09-25** — the armory takes the D13 rework instead;
the audit recap is preserved in the D13 brief.

## Pipeline law (read before any generation run — AGENTS.md "Asset Generation")

Panel order: render → find objects (`panels.py --detect`) → cut each → key
each → trim. `flare` never returns native alpha — `--post-only`. FX stay RGB
except the four §0.1 names. 2K run = 10 credits = $0.05. Delivery order:
generate → stage → **review sheet → owner approval** → ship → reimport →
`validate_names.py --library`. Generation logs beside every shipped family.

## Handoff (live)

**Item 15 = D14 ARMORY chrome composition — brainstorm first, then Amendment 5.**
The owner's ask (verbatim) and the measured defects are in
`.agents/gen/slices/D14-armory-chrome-composition/D14_BRIEF.md`; work Q1–Q6 with
him, then draft `UI_SPEC.md` §3.10 Amendment 5 (per-surface chrome + the
containers/anchors law) and the revised mockup band, and bring back a tick list.
Design only — no code wave until he ticks. The coder lane's live item is
**item 26 = S19 directional armour** (`dispatch_coder.md`); it holds
`vajb-orbit/tests/` + `vajb-orbit/tools/`, so the armory composition's
implementation wave is queued behind it.
