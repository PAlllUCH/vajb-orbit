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

1. **Slot-plate re-cut — BLOCKER, first.** `ui_slot_weapon_{normal,pressed,
   hover,disabled}.png` (880×876 px) and `ui_slot_cargo_*.png` (873×864 px)
   shipped as whole sheet cells in the 2026-09-21 00:17 re-cut; the shipyard
   hardpoints, the launch panel's cargo slots and the HUD slot buttons
   consume them at native size and break layout. **Check the keying cache
   orphans first — the cache holds 235 recoverable cuts** (button plates
   `@2x` 560×112, bezel, panel frame, bar caps, logo, backdrop plate), so
   R7/R8 plates come back the free way; regenerate only what the cache
   cannot cover (this retires `plates_cut.py`'s "needs regeneration,
   $0.05" note). Then `f2_backup.py` first, owner review sheet before
   shipping, then `apply_import_settings.py` + reimport + `qc_f2.py`.
   **Do not run `apply_import_settings.py` unscoped** — it has no `--only`
   and would rewrite 1080 of 1620 `.import` files; the coder lane is adding
   the scoped flag (coder queue item 2).
2. **Standing chrome regression scope (R7)** — menu button plates
   (287×8.6 px, ~90 % transparent), the menu wordmark/logo (Logo slot
   renders empty), credits frame, module-rail icons, OUTFITTING/REFINERY
   background alignment. Recipe and measured table:
   `ui_chrome_regression.md`.
3. **R8 + rest** — 4K 2× backdrop cuts, tint-stencil import settings
   (blocked on the coder lane's `--only` flag for
   `apply_import_settings.py` — never run that script unscoped),
   `_48` zoom buttons (minimap bezel), B2-1 hover direction (owner pick).
4. **Owner-endorsed direction (2026-09-21):** evaluate asset-library
   background plates for the station panels (drydock look). Propose
   candidates as a review sheet; nothing ships without approval.
5. Later lanes (unchanged): MMO/faction liveries, six boss hulls,
   `ship_vanguard_damaged`, F10's credit-cache salvage glyph.

**Verification rule (owner, 2026-09-21):** every shipped cut gets a model-vision
integrity check (contact sheet + measure) before it reaches the owner —
ink box vs expected plate box, no whole-cell cuts, no 90 %-transparent plates.

## Pipeline law (unchanged, per AGENTS.md)

- Generator: the image-generator skill's `kie_generate.py`, run under
  `py -3.14` (never the PATH python — TLS failure). Request `--transparent`
  first for sprites/icons/props and verify with Pillow; **FX are never
  keyed** — they stay RGB on Void Black for additive blending.
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
