# dispatch_designer.md — the graphics lane's queue of record

Rebuilt 2026-09-22 after the purge; **re-cut again 2026-09-22 (owner ruling)** for a
two-designer split. **Designer #1 has exactly one job: the icon unification (D2) —
SVG masters for every glyph-type icon + one-master-only for the rest.** Everything
else waits as **designer #2's** queue and the owner dispatches it later.

## The ruling (owner, 2026-09-22)

- Glyph-type icons are **remade as SVG masters** (slot glyphs, equipment-slot
  symbols, `icon_contract_*`, service glyphs, chevrons/pips — the flat symbol
  side; example: `icon_contract_escort` → SVG).
- Depictive icons **keep one raster master only** (example: `icon_equip_drone`
  stays raster). The five-size families (`_48`/`_96`/`_192`/`@2x`) die — Godot
  scales from the one master ("we will scale it").
- **Delete all non-master rasters** — **project-side only**: `vajb-orbit/assets/`
  loses every variant and duplicate; `asset-library/` keeps every cut untouched
  (provenance law + the rollback).
- SVG source rule (this lane's standing style): flat shapes, `viewBox="0 0 48 48"`,
  designed on the 48 grid so the smallest target is pixel-clean; fills only (no
  strokes below 2 units), at most two tones (Steel `#565C63` family + the ember
  accent `#C8461B`/`#E8703A` where the icon carries danger/warn meaning).
  kie.ai cannot generate SVG (image-generator skill: "No native SVG") — the SVG
  set is **hand-authored** here; a pictogram that resists authoring may be
  generated once as a clean-flat raster ("no gradients, no grain") and traced
  (Inkscape), then simplified.
- **Tint boundary:** a remade glyph's tint variants die with it (fills replace
  tint stencils); depictive icons' tint stencils stay in place until designer
  #2's tint rework. Nothing else touches the tint pipeline in this job.

## D2 — designer #1's only job (icon unification)

**Phase C scope extension (owner-granted 2026-09-22, recorded here):** the write
set grows by `game/*_catalog.gd` (mineral ×42, module ×35, component ×18,
station ×5 refs), the five named test files (`test_p1_catalogues`,
`test_ship_grids`, `test_ui_slot_layout`, `test_p2b_services`,
`test_p2b_fitting_panel`) and `tools/derive_icon_tints.gd` + `tools/build_theme.gd`
— **re-point only, no semantic change** (D2_SPLIT §3's bold rows). Without these
Phase C cannot reach 0 asset-path fallout or hold the gate. `@2x` (19 chrome
files) dies with the size variants per this dispatch's ruling — the
"highest-fidelity" swap is rejected (pointless before D3 re-cuts chrome).
Phase A is closed on the owner's ID marks (`staging/d2/svg_ids.txt`): **X = 135
SVG / 139 raster-kept** (D2_SPLIT §1), plan 2 478 PNGs → 839 files.

Run order inside the job (folder law: open `slices/D2-icon-unification/SLICE.md`
first):

1. **Phase A — inventory + split (no writes).** Enumerate every icon symbol from
   `asset-library/INDEX.md`/`_library.json`, `docs/design/ASSET_CATALOG.md`,
   `vajb-orbit/assets/icons/` and `assets/ui/`; classify each **SVG (glyph) vs
   raster-kept (depictive)** with its current file family. Deliver
   `slices/D2-icon-unification/D2_SPLIT.md`. **STOP — owner approves the split
   table** (this is where `icon_equip_drone`-vs-`icon_contract_escort` calls get
   confirmed).
2. **Phase B — SVG authoring** for every SVG-side symbol, one file per symbol
   (`icon_contract_escort.svg`, …; names per `docs/design/ASSET_NAMING_SPEC.md`,
   extension changes, names stay). Review sheet renders every SVG at
   16/24/48/96/192 side by side (the scaling proof). **STOP — owner approves.**
3. **Phase C — masters only + deletion + re-point.** Keep the highest-fidelity
   raster per depictive symbol (one master), delete every size variant and
   duplicate **in `vajb-orbit/assets/`**, re-point every reference (theme
   `vajb_theme.tres`, scenes, `ui/**` code paths) to the one master per symbol
   and let control size scale it. Unify import settings (mipmaps on, lossless,
   3D-detection off). Regenerate `ASSET_CATALOG.md` (`build_catalog.py`), then
   prove: `asset_path_fallout` reads **0 unresolvable** and
   `validate_names.py --library` is green. **STOP — owner approves the before/
   after file-count table.**
4. **Close:** commit; report the collapse count (files before/after per family).

**Parallel guardrails (the coder lane is running item 8):** add/replace/delete is
confined to `vajb-orbit/assets/`, `asset-library/`, `staging/`, `docs/design/`
asset specs, plus the reference files named in Phase C (`vajb_theme.tres`,
`ui/**`, scenes) — the coder's S2.6 file set holds none of them. **Designer #1
must close before coder item 9 starts** (S3 holds `ui/station/*`). Editor
reimports only in quiet windows between coder gate runs. One editor session.

## Designer #2's queue (dispatched later by the owner)

| D-slice | Item | What | Gate |
|---|---|---|---|
| D3 | 1 | **Chrome re-cut** — button/slot plate family (the 1041×1087-cell-stretched defect class: plates, bezel band, bar caps, panel frame) | OWNER-GATED on `staging/phase_f/_preview/review_slots.png` |
| D3 | 2 | **Painted-only station rail icons** (owner 2026-09-23: "in space station the icons on 'MODULES' left menu should have only painted icons so no svg") — swap the station's left-rail/`MODULES` menu icons to **painted raster masters** (generate if no painted master exists for a symbol); SVGs stay for the in-list glyph work elsewhere. One review sheet of the rail at 48/96 px | READY — may ride the owner's live SVG-review session |
| D3 | 2 | **Tint rework** (the depictive remainder): replace or repair the tint-stencil system for raster icons (shader tint or scoped stencils) + the 1 080-file import-settings cleanup left over from D2 | READY |
| D4 | 3 | **4K 2× backdrop cuts** (R8; display target: 4K) | READY |
| D4 | 4 | **B2-1 hover look** — flicker / directional glow / ember | **OWNER PICK NEEDED** first |
| — | 5 | MMO/faction liveries, six boss hulls, `ship_vanguard_damaged` | BLOCKED on the owner's naming overhaul |
| — | 6 | Component icons ×18 (`comp_*`) — if not already covered by D2's split as depictive masters | verify against `D2_SPLIT.md` |

## Pipeline law (read before any run — AGENTS.md "Asset Generation" + "Phase G lane")

Panel order: render → find objects (`panels.py --detect`) → cut each → key each →
trim. A 2×2 sheet's fourth cell is often a second front (IoU > 0.80 = refuse).
`flare` never returns native alpha — `--post-only`. FX stay RGB except the four
§0.1 names. 2K run = 10 credits = $0.05. Delivery order: generate → stage →
**review sheet → owner approval** → ship → reimport → `validate_names.py
--library`. Generation logs beside every shipped family.

## Handoff — designer #1 (the owner pastes this now)

```text
Read .agents/gen/dispatch_designer.md and execute D2 only — the icon unification, your only job this dispatch. Follow the ruling and the three phases exactly: Phase A inventory + split table (STOP for my approval), Phase B hand-authored SVG masters per the SVG source rule with the 16/24/48/96/192 review sheet (STOP for my approval), Phase C masters-only + project-side deletion + reference re-point with the before/after file-count table and asset_path_fallout at 0 unresolvable (STOP for my approval), then close with a commit. kie.ai cannot generate SVG — author the paths; one clean-flat generation + Inkscape trace is allowed for a single stubborn pictogram. The coder lane is running: obey the parallel guardrails, and close before coder item 9. Report after each phase: counts, file families, and the review sheet paths.
```

Designer #2's handoff gets written when the owner dispatches it (same template,
swapping the item block).
