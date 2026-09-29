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
| 16 | D15 | Flight feel & feedback design (phase P3) | Resolve the feel tick sheet (T-feel-1..7, S19 T1–T7, CONTRACTS §22 T3, L39/L103/L182/L57) with values + reversals + tick ids; FX/AUDIO spec amendment drafts (mine cue, chip sparks, arc interval, anti-flam wiring note); the quadrant-feed + hit-marker composition under A5.2. Five-piece: `slices/D15-flight-feedback/`. Design only. | **live** (D14 closed 2026-09-29) · coder item 28 (S22) waits on its ticks |
| 17 | D16 | Station identity & contracts UI design (phase P3) | CONTRACTS panel spec (14 §2 + R-S25-1), insurance/vaults panels (14 §3/§4), the nine places' identity treatment with shipped chrome only, the W3 name tick sheet. Five-piece: `slices/D16-station-ui/`. Design only. | queued · after 16; S24/S25/S26 cite it |

## Parked (owner-gated — not queued; say the item and its five-piece lands)


## Done

Items 1-15 closed (D2 icon unification, D6 instruments, D7 cockpit rework,
D11 station scene, the D8/D12 fix waves ditched or absorbed); detail in
`.agents/gen/MASTER_REPORT.md` §6. Item 15 = **D14 armory chrome composition**
closed **2026-09-29** (owner): Amendment 5's follow-ups and the §3.10 **A5.4**
per-surface chrome table landed in `4c0de38`, and the armory's own cure shipped in
the coder lane's S20/A5 (gate 914/0 unmoved, the pane's chrome chosen by each
surface's own cut size). Item 14 = **D13 armory rework — design**
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

**Item 16 = D15 flight feel & feedback design** (paste the block at the bottom of
`.agents/gen/slices/D15-flight-feedback/D15_prompts.md`): resolve the feel tick
sheet with values, reversals and tick ids, draft the FX/AUDIO amendments, and
compose the quadrant feed and hit marker under UI_SPEC §3.10 A5.2. Design only —
the coder lane's S22 (item 28) implements the ticks it returns.
**Item 15 = D14 closed 2026-09-29** (owner): Amendment 5's follow-ups and the
§3.10 A5.4 per-surface chrome table landed in `4c0de38`; the armory's own cure
shipped in S20/A5. The coder lane's queue is phase **P3**
(`dispatch_coder.md` items 28–33; order and collisions in `WAVEBOARD.md`
§Queued) and runs its items between this lane's — D15 (item 16) feeds coder item
28, D16 (item 17) feeds items 30/31/32.
