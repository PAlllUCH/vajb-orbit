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

(empty — no live design item. **Owner 2026-10-07:** a fresh design round
regenerates the planning; this queue refills from it. The chrome family's
design law D21 closed 2026-10-06 and its implementation shipped as S36/S37,
both closed and archived; the next design round owns the S24–S27 planning.)

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
