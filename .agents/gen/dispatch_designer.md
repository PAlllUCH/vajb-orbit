# DISPATCHER — Graphics orchestrator (hand this file to the designer agent)

You are the **graphics orchestrator** for the Vajb Orbit project. The owner
hands you this file instead of pasting task lists. Your job: run the art
queue below through the established generation → review → ship pipeline,
stopping for the owner at every approval gate.

**Law, read in this order before anything:** `AGENTS.md` (workspace root —
asset generation + pipeline rules), `docs/design/STYLE_BIBLE.md` (§2.5 alien
palettes, §9.1 alien style block addendum, §8 prompt rules),
`docs/design/FX_SPEC.md` (§0 emission rule, §0.1 generation rules, §7 Phase G
inventory), `docs/design/ASSET_WIRING_HANDOFF.md`, `docs/design/ASSET_NAMING_SPEC.md`
(the name law — §1 grammar, §4 closed variant list),
`docs/design/UI_CHROME_ASSETS_SPEC.md`, `.agents/gen/ui_chrome_regression.md`
(the chrome recipe), and `docs/design/ASSET_CATALOG.md` before wiring anything
into scenes. Context for this wave: `.agents/gen/playtest_fullloop_20260921.md`.

**Ship naming law (ASSET_NAMING_SPEC §1–§4 + SHIPS_SPEC):**
`ship_<hull>[_<qualifier>][_<angle>]` — hull first (class/identity),
livery/state as qualifier (`ship_fighter_concord_`, `_damaged_`), then the
closed angle list `_front` / `_three_quarter` / `_side` / `_back` (bosses:
single centred render, no angle). Never invent a name; use the exact
per-hull name list in `SHIPS_SPEC.md` or a name the spec sanctions.

## Current queue (execute top-down)

**Closed since the last revision:** the slot-plate blocker (item 1) — the
recovered cuts shipped, the review sheets were approved and the 19 hi-DPI cuts
reimported with the theme's frame margin matched (`b512a63`); the R7 chrome
regression — the recovered chrome is live; the FX re-cut (2026-09-21, 122 RGBA
files, every effect four frames, report
`.agents/gen/designer_fx_recut_report.md`). Do not re-run them.

1. **Component icons (18) — the one real gap.** `comp_scrap_1..3`,
   `comp_mech_1..3`, `comp_weap_1..3`, `comp_ore_1..3`, `comp_elec_1..3`,
   `comp_pow_1..3` per `docs/gameplay/03_components.md` §3 — no icon family
   exists, and the SHIPYARD build recipes (`10_ship_acquisition.md` §3) and the
   crafting phase consume them. 09 §3's icon rule applies (quartet, `_96`
   default for new consumers). Review sheet before shipping.
2. **Re-cuts owed (existing masters):** the `_48` cuts of `icon_zoom_plus` /
   `icon_zoom_minus` (the HUD renders the `_96` into 28 px boxes, 3.43 texels/px,
   no mips — `ui_chrome_regression.md`); the tint-stencil import-settings pass
   (1 080 files, mipmaps on / lossless / 3D off) — **now scoped**: T1 shipped
   `apply_import_settings.py --only`, so run it scoped, never unscoped.
3. **Decisions owed (a pick may add generation):** B2-1 hover direction (the
   owner picks after a standalone 1080p/1440p look); station-panel backplates
   (evaluate the asset-library plates; review sheet, nothing ships without
   approval); the four `ui_slot_inventory_*` plates (L34 — ship, re-cut or
   drop); `ship_vanguard_damaged` (exists on disk, zero consumers — wire,
   commission more damage tiers, or park).
4. **Gated on the owner:** the 4K 2× backdrop cuts (B2-2's display-target
   decision) and the full backlog detail:
   `.agents/gen/designer_generation_backlog.md` (the queue of record for the
   graphics lane — read it in full).

**Verification rule (owner, 2026-09-21):** every shipped cut gets a model-vision
integrity check (contact sheet + measure) before it reaches the owner —
ink box vs expected plate box, no whole-cell cuts, no 90 %-transparent plates.

## Pipeline law (unchanged, per AGENTS.md)

- Generator: the image-generator skill's `kie_generate.py`, run under
  `py -3.14` (never the PATH python — TLS failure). Request `--transparent`
  first for sprites/icons/props and verify with Pillow; FX follow FX_SPEC
  §0.1's 2026-09-21 amendment — the four non-additive effects
  (`fx_smoke_plume`, `fx_acid_burn`, `fx_dust_streak`,
  `fx_hull_critical_vignette`) carry alpha, everything else stays RGB on
  Void Black for additive blending, and every shipped frame passed the
  ink-vs-matte QC before it reached the owner.
- Every generated asset records prompt + seed + model + date in the family's
  generation log next to `vajb-orbit/assets/` (AI art is not CC0).
- **The delivery order is fixed:** generate/cut → stage → **review sheet for
  owner approval** → ship (`ship_batch.py` / `ship_batch_g.py`, editor
  reimport, `derive_icon_tints.gd` + `build_catalog.py` when icons are
  touched). A review sheet goes to the owner and NOTHING ships without their
  approval.
- Never hand-edit shipped art; regenerate through the drivers. Reimport
  through the editor (`filesystem_manage`), not while the game is playing.
- Give tools **staged** paths (a bare `ships/<file>.png` resolves to
  `assets/` and rewrites shipped art); after rewriting asset bytes, touch the
  sources and run `--headless --import`, then audit `.ctex` md5s (`qc_f2.py`).

## Stop points (ask the owner)

- Every review sheet (approval gate).
- Any palette/prompt deviation you think the art needs beyond what
  STYLE_BIBLE/FX_SPEC already sanction — propose, never improvise.
- Pricing/model questions for the image generator (the 10-credit = $0.05/2K
  run basis is the console's authority).

## Report

After each batch: a designer report in `.agents/gen/` (`designer_<batch>_
report.md`) — files staged, review-sheet paths for the owner, generation-log
paths, and which sheets await approval.
