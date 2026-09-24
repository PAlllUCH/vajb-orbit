# D2_SPLIT — icon inventory + SVG/raster split

**Status:** Phase A complete 2026-09-22. **The split is decided by the owner's ID file,
not by this document.** Sheets carry global IDs `#1..#274` (`staging/d2/mark_sheets/D2_MARK_01..10.png`);
the owner writes the IDs to remake as SVG into `staging/d2/svg_ids.txt`; everything not
listed keeps ONE raster master. Phase C deletes all size variants either way.

## 1. Inventory (project-side, `vajb-orbit/assets/`)

274 symbols on the sheets = 270 icon symbols (`assets/icons/`, tint excluded) + 4 company
emblems (`assets/ui/ui_insignia_*`). Not on the sheets (out of the icon axis): `logo_vajb_orbit`,
3 `ui_backdrop_*`, 21 chrome symbols (`ui_button_plate_*`, `ui_slot_*`, `ui_bar_caps[_alt]`,
`ui_minimap_bezel`, `ui_panel_frame[_alt]`) — raster chrome, D3's family, see §4.
All 299 symbol masters are inventoried here (274 on sheets + 25 off).

Every icon symbol currently ships as a five-size raster family (`<name>.png` master +
`_16`/`_48`/`_96`/`_192` cuts) plus four tint stencils (`icons/tint/<name>_{16,48,96,192}.png`).
19 chrome symbols add an `@2x` cut. Totals: **2 478 PNGs** (+ one `.import` each) =
1 350 icon family files + 1 080 tint stencils + 48 `ui/` files. md5-duplicate PNGs: 0.

| Family | Symbols | IDs | Class (evidence) | Sheet |
|---|---|---|---|---|
| `slot/` | 8 | 1-8 | flat-glyph — ruling: "slot glyphs", "equipment-slot symbols" (`_engine`,`_power`) | 1 |
| `contract/` | 5 | 9-13 | flat-glyph — ruling names `icon_contract_*` (anchor: `#9 icon_contract_escort` → SVG) | 1 |
| `service/` | 3 | 14-16 | flat-glyph — ruling: "service glyphs" | 1 |
| `hud/` | 7 | 17-23 | flat-glyph (close, gear, hull, logout, shield, zoom ±) | 1 |
| `cargo/` | 7 | 24-30 | flat-glyph (incl. `icon_credits`) | 1 |
| `weapon/` | 8 | 31-38 | mixed — `#31 icon_ammo` flat; `#32-33 icon_ammo_{laser,rocket}` painted (catalog D); 34-38 flat | 2 |
| `module/` | 27 | 39-65 | flat-glyph (ICONS_SPEC §8.2 panels a/b/c) | 2 |
| `mineral/` | 20 | 66-85 | flat-glyph (§8.1) | 3 |
| `ingot/` | 20 | 86-105 | flat-glyph (§8.1) | 3 |
| `insignia/` | 3 | 106-108 | flat-glyph per catalog (marks read embossed — see §5 tick 2) | 4 |
| `booster/` | 6 | 109-114 | painted (catalog E) | 4 |
| `equip/` | 7 | 115-121 | painted (catalog D) — anchor: `#115 icon_equip_drone` stays raster | 4 |
| `map/` | 9 | 122-130 | painted (catalog D) | 5 |
| `status/` | 9 | 131-139 | painted (catalog E) | 5 |
| `alt/` | 131 | 140-270 | parked off-brief art (NAMING_SPEC §3) — see §5 tick 3 | 5-9 |
| `ui_insignia/` | 4 | 271-274 | company emblems — see §5 tick 2 | 10 |

Class evidence: `ASSET_CATALOG.md` masters read either "Flat single-colour glyph master"
(B/F phases) or "Painted icon master" (D/E phases); the two ruling anchors land exactly on
that line (`icon_contract_escort` flat → SVG, `icon_equip_drone` painted → raster).
"chevrons/pips" (ruling) resolve inside the named sets — `icon_slot_b` is the chevron
(ICONS_SPEC §8.3), `icon_contract_escort` carries the two travelling chevrons (§8.4);
there is no standalone chevron/pip symbol.

Ruling-reference reading: X the flat-glyph rows = IDs `1-31, 34-108` (106 symbols).

**The split (owner's marks in `staging/d2/svg_ids.txt`, parsed incl. `A to B` ranges,
2026-09-22 — this is the authority): X = 135 SVG / blank = 139 raster-kept.**
X = IDs `1-31`, `34-105` (every flat glyph except the three insignia) + 32 picked `alt/`
marks (147-149, 155, 157, 159, 164, 168, 169, 174, 176-178, 182, 188, 189, 202, 204,
207, 209, 213, 214, 219-221, 228, 237, 251, 259, 261, 262, 269 — the chevrons/pips and
module-mark side of the parked art). Raster-kept = insignia 106-108 (tick 2 answered:
raster), all painted (32-33, 109-139), the other 99 alt, ui emblems 271-274.
Both anchors hold (#9 SVG, #115 raster). Machine list: `staging/d2/svg_picked.tsv`.

## 2. What Phase C does per cell

| Cell marked | Keeps | Deletes project-side | Tint stencils |
|---|---|---|---|
| X (SVG) | `icons/<fam>/<name>.svg` (new) | 5 rasters + `.import` | 4 stencils die (fills replace them) |
| blank (raster) | `<name>.png` master (highest-fidelity cut) | `_16/_48/_96/_192` (+`.import`) | 4 stencils stay (D3 item 2 rework) |

Names stay per `ASSET_NAMING_SPEC.md` §2 ("one file per glyph, no suffix"); only the
extension changes. Consumers that build paths by concatenation (`TINT_DIR`/`*_48.png`)
are re-pointed to the one master per symbol and let control size scale it.

## 3. Reference blast radius (Phase C re-point targets)

| Site | Refs | In the dispatch's named write set? |
|---|---|---|
| `ui/theme/vajb_theme.tres` | 18 (chrome only, zero icon refs) | yes |
| `ui/**` panels + screens (TINT_DIR concat + literals) | ~50 | yes |
| scenes (`*.tscn`) | ~20 | yes |
| `game/mineral_catalog.gd` | 42 (`_48` literals/format strings) | **no — tick 1** |
| `game/module_catalog.gd` | 35 | **no — tick 1** |
| `game/component_catalog.gd` | 18 (aliases cargo glyphs) | **no — tick 1** |
| `game/station_catalog.gd` | 5 | **no — tick 1** |
| `tests/test_p1_catalogues.gd`, `test_ship_grids.gd`, `test_ui_slot_layout.gd`, `test_p2b_services.gd`, `test_p2b_fitting_panel.gd` | 9 (`_48` format strings) | **no — tick 1** |
| `tools/derive_icon_tints.gd` (derives tints by name appending), `tools/build_theme.gd` | 1 each | **no — tick 1** |

`@2x` has **zero** code references — deletion touches nothing. `panel_*` atlas masters
exist only in the library, not in the project. `asset_path_fallout` (MASTER_REPORT:123,
"181 asset literals, 0 unresolvable") has no surviving tool in the tree; Phase C recreates
it as `staging/d2/asset_path_fallout.py` with that exact report shape and writes
`asset_path_fallout.md` into this folder.

## 4. Numbers Phase C will report

Before: 2 478 PNGs (1 350 family + 1 080 tint + 48 ui). After (owner split, X = 135):
**135 SVG + 164 raster masters + 540 tint stencils = 839 files; 1 774 PNGs deleted**,
zero `_16/_48/_96/_192/@2x` remaining. D3's "1 080-file import-settings cleanup" becomes
exactly 540. Formula for any X: `X` SVG + `(299 − X)` masters + `(270 − X) × 4` tint.

## 5. Owner ticks

1. **Extended write set** (§3, rows in bold) — **ASKED 2026-09-22, pending**: without
   `game/*_catalog.gd`, 5 tests and 2 tools, Phase C cannot reach 0 fallout or keep the
   gate at 437/0. Tick = re-point only, no semantic change.
2. **Insignia (106-108) + company emblems (271-274)** — **SETTLED by the ID file**: both
   kept raster (not marked).
3. **alt/ (140-270)** — **SETTLED per-pick**: 32 marked → SVG, 99 keep one raster master.
4. **`@2x` (19 chrome files)** — **ASKED 2026-09-22, pending**: default = die (the ruling's
   five-size death list). The "highest-fidelity" reading would swap `@2x` bytes under the
   base names and double the theme's nine-slice margins — heavier and pointless before D3
   re-cuts chrome.

## 6. Amendments (owner, 2026-09-22)

- **96 grid supersedes the 48-grid source rule**: SVGs are authored with
  `viewBox="0 0 96 96"` and richer interior detail (8-14 flat shapes per icon).
  The ruling's `viewBox="0 0 48 48"` is retired for this set. Reversal: re-author at
  48 viewBox (coordinate mapping is mechanical ×0.5).
- **Batches capped at ~10 icons per worker** (15 batches, 6-11 each) for output
  quality. The first wave (5 workers, 30+ icons each, 48 grid) was stopped and its
  outputs cleared before any file landed.
- **Palette note for the review STOP**: the owner's test `rocket_48.svg` filled with
  `#e8eef5`, which is outside the STYLE_BIBLE fixed palette; the authored set uses
  the sanctioned ramp (`#C9CDD2` default body, `#8D939B`, `#565C63`, `#3A3F46`,
  `#2B2F35`, `#232629`, ember pair for danger/warn symbols only). Swap-in of
  `#e8eef5` is a one-line colour substitution across the set if the owner prefers it.

## 7. Phase B outcome (2026-09-22)

135 SVG masters authored into `staging/d2/svg/` by 15 `opencode-go/mimo-v2.6-flash`
batches (effort medium, 6-11 icons each; one batch died on a stream transport error and
was re-dispatched alone). `staging/d2/validate_svg.py`: **135/135 pass, 0 fail** (a few
cosmetic warnings: single path numbers a hair outside the 96 canvas). Review sheet
(scaling proof 16/24/48/96/192): `staging/d2/review/D2_SVG_REVIEW_01..05.png`
(27 symbols per sheet, half-scale `_check_NN.jpg` copies beside them). Awaiting owner
approval before Phase C ships into `vajb-orbit/assets/`.

## 8. Review round and compile (owner, 2026-09-22, after the wave commit)

Playtest finding: fine details disappear in play. Ran a 5-agent audit of the shipped
set, authored batches B2 (`svg_v2/`, mimo-v2.6-flash, hardened legibility) and B3
(`svg_v3/`, deepseek-flash, one shared style constitution + exemplars), and the owner
compiled the three batches from `D2_COMPARE_01..06.png` via `svg_compile.csv`:
**B3 × 66, B2 × 55, B1 × 14, 0 pending** — merged by `staging/d2/merge_compile.py`
(per-icon authority: `svg_compile_result.csv`). Structure unchanged (839 files);
proofs: validator 135/135, fallout 379 refs / 0 unresolvable, gate 524/0.
Full narrative: `D2-R0_report.md`.

## Evidence

Contact sheets of every master: `staging/d2/_masters_catalog.png` (139),
`staging/d2/_masters_alt.png` (131). Mark sheets (owner surface): `staging/d2/mark_sheets/D2_MARK_01..10.png`
+ `MARK_INDEX.tsv` (id, name, family, class, px, sheet, cell). Regenerate with
`python3 staging/d2/build_mark_sheets.py`.
