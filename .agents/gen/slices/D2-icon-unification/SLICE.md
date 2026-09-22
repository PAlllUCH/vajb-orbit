---
slice: D2
phase: n/a (graphics lane, parallel)
lane: design
status: active
gate_baseline: "437/0"
---

# D2 — Icon unification

## Goal
Every glyph-type icon exists as one hand-authored SVG master on the 48 grid; every
depictive icon exists as exactly one raster master. `vajb-orbit/assets/` loses every
size variant (`_16`/`_48`/`_96`/`_192`/`@2x`) and every remade glyph's tint stencils;
Godot scales from the one master.

## In scope
- The SVG/raster split for all 274 icon symbols (owner marks the split; `D2_SPLIT.md`)
- Hand-authored SVG masters per the SVG source rule (`dispatch_designer.md`, ruling block)
- 16/24/48/96/192 review sheet, owner-approved
- Project-side deletion of non-master rasters + re-point of every reference
  (`vajb_theme.tres`, scenes, `ui/**`, and the flagged `game/*_catalog.gd` / tests / tools
  once the owner ticks the extended write set)
- Import-settings unification (mipmaps on, lossless, 3D-detection off) for surviving masters
- `ASSET_CATALOG.md` regeneration; `asset_path_fallout` at 0 unresolvable;
  `validate_names.py --library` green

## Out of scope
- `asset-library/` cuts stay untouched (provenance law + rollback)
- The depictive tint-stencil system (designer #2, D3 item 2) and its import-settings cleanup
- Chrome re-cut (D3 item 1), 4K backdrops (D4), hover look (D4), liveries/boss hulls
- `comp_*` component icons: none exist on disk; `game/component_catalog.gd` aliases six
  `cargo` symbols (verified 2026-09-22) — D3/D2 queue item 6 is answered by `D2_SPLIT.md`

## Acceptance criteria
- [ ] AC1 — one SVG master per X'd symbol, `viewBox="0 0 96 96"` (owner amendment
  2026-09-22 superseding the ruling's 48-grid source rule: more detail, 8-14 flat
  shapes per icon), fills only (no strokes), at most two tones (Steel `#565C63` family
  + ember `#C8461B`/`#E8703A` only where the icon carries danger/warn meaning)
- [ ] AC2 — review sheet renders every SVG at 16/24/48/96/192 side by side; owner approves
- [ ] AC3 — `vajb-orbit/assets/icons|ui` holds exactly one file per non-X'd symbol (plus
  surviving depictive tint stencils); zero `_16/_48/_96/_192/@2x` remain
- [ ] AC4 — `asset_path_fallout` reads 0 unresolvable and `validate_names.py --library` green
- [ ] AC5 — universal gate stays `[SUMMARY] passed=437 failed=0`

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| D2-A01..D2-A0n (Phase B SVG batches, mimo-v2.6-flash) | `staging/d2/svg/<name>.svg` per assigned ID list | `D2-A_BRIEF.md` |
| D2-C0 (Phase C consolidation, this session) | `vajb-orbit/assets/**`, `staging/d2/**`, `docs/design/ASSET_CATALOG.md`, `vajb-orbit/ui/**`, `vajb-orbit/ui/theme/vajb_theme.tres`, scenes, `game/*_catalog.gd`, `tests/test_p1_catalogues.gd`, `tests/test_ship_grids.gd`, `tests/test_ui_slot_layout.gd`, `tests/test_p2b_services.gd`, `tests/test_p2b_fitting_panel.gd`, `vajb-orbit/tools/derive_icon_tints.gd` (pending owner tick) | in `D2_SPLIT.md` |

## References
- `.agents/gen/dispatch_designer.md` — the ruling + SVG source rule + parallel guardrails
- `docs/design/ASSET_NAMING_SPEC.md` §2/§3/§5 — names stay, extension changes; derived
  suffixes are not part of a name
- `docs/design/ASSET_CATALOG.md` — flat-glyph vs painted wording (split evidence)
- `docs/design/ICONS_SPEC.md` §8 — glyph panel provenance

## Carries forward
- D3 item 2's "1080-file import-settings cleanup" shrinks by 4 files per X'd symbol
  (glyph tint stencils die in D2); exact remainder is in `D2_SPLIT.md` after Phase C
