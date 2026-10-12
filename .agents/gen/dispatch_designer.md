# dispatch_designer.md — the graphics lane's queue of record

Purged and regenerated 2026-10-08 (owner clear-out: live items only — the done
items and closed handoff entries live verbatim in
`_archive/dispatch_designer_done_2026-10-07.md` and
`_archive/dispatch_done_2026-10-08.md`, the wave recaps in
`MASTER_REPORT.md` §6). Execute one item per order; briefs/prompts live in the
slice folders.

**Model roster (owner, 2026-10-03, standing):** very demanding design work runs
`hyper/glm-5.3` @ high; other design work `hyper/glm-5.3-flash` (or
`hyper/qwen3.8-flash`) @ high. MiMo (`xiaomi/mimo-v2.6-pro`) stays available
when named. Image lane: glm-5.3-flash @ max driving kie.ai
`gpt-image-2-5-flare-text-to-image`.

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

1. **D24 — the station-overhaul design round (P4 opener; queued 2026-10-12).**
   The owner's build-2 playtest asks (nine items, verbatim in
   `phases/P4-station-overhaul/PHASE.md`, measured state in
   `docs/design/STATION_HUB.md` §22) become pinned design: the OVERVIEW 3×3
   grid of nine, the buy-confirmation law, the C-key Cargo overlay, the launch
   sequence + cues, the armory equipped list, refinery LOAD ALL + machine read
   + the CRAFT tab, exchange bulk sell, the shipyard build rework, and the
   T-174/T-175/T-176 cures folded in. Brief:
   `slices/D24-station-overhaul-design/D24_BRIEF.md`; prompts:
   `D24_prompts.md` (A1 `hyper/glm-5.3` @ high, then the mandatory R1).
   **No implementation wave dispatches before this closes** (owner: workers
   need a design).

## Parked (owner-gated — not queued; say the item and its five-piece lands)

## Done

Items 1–20 closed (D2 icon unification through D22 screen integrity; the D8/D12
fix waves ditched or absorbed). Detail: `_archive/dispatch_designer_done_2026-10-07.md`
and `MASTER_REPORT.md` §6.

## Pipeline law (read before any generation run — AGENTS.md "Asset Generation")

Panel order: render → find objects (`panels.py --detect`) → cut each → key
each → trim. `flare` never returns native alpha — `--post-only`. FX stay RGB
except the four §0.1 names. 2K run = 10 credits = $0.05. Delivery order:
generate → stage → **review sheet → owner approval** → ship → reimport →
`validate_names.py --library`. Generation logs beside every shipped family.
