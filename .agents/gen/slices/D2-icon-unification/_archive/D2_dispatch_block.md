# D2 dispatch block (archived 2026-09-24)

Archival, not deletion (folder law). This is the verbatim D2 job spec, its
parallel guardrails and its handoff paragraph as they stood in
`.agents/gen/dispatch_designer.md` until 2026-09-24. **D2 is DONE 2026-09-22**
(commit `7c1ae06`) — see `D2_SPLIT.md` (incl. §6's owner amendments) and
`_state/WAVEBOARD.md` §Closed. The lane's standing ruling + SVG source rule stay
in `dispatch_designer.md`; the guardrails below are D2-era (they name the waves
running at the time) and are superseded by that file's standing guardrails.

---

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

**Parallel guardrails (D2-era — the coder lane was running item 8 at the time):**
add/replace/delete is confined to `vajb-orbit/assets/`, `asset-library/`,
`staging/`, `docs/design/` asset specs, plus the reference files named in Phase C
(`vajb_theme.tres`, `ui/**`, scenes) — the coder's S2.6 file set held none of
them. **Designer #1 had to close before coder item 9 started** (S3 held
`ui/station/*`). Editor reimports only in quiet windows between coder gate runs.
One editor session.

## Handoff — designer #1 (as pasted 2026-09-22)

```text
Read .agents/gen/dispatch_designer.md and execute D2 only — the icon unification, your only job this dispatch. Follow the ruling and the three phases exactly: Phase A inventory + split table (STOP for my approval), Phase B hand-authored SVG masters per the SVG source rule with the 16/24/48/96/192 review sheet (STOP for my approval), Phase C masters-only + project-side deletion + reference re-point with the before/after file-count table and asset_path_fallout at 0 unresolvable (STOP for my approval), then close with a commit. kie.ai cannot generate SVG — author the paths; one clean-flat generation + Inkscape trace is allowed for a single stubborn pictogram. The coder lane is running: obey the parallel guardrails, and close before coder item 9. Report after each phase: counts, file families, and the review sheet paths.
```
