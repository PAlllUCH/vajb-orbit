---
slice: D7
worker: D7-C3
model: "deepseek-v4-flash (crush run, per D7_prompts.md), Godot 4.7.2-stable headless"
status: actionable
gate: "692/0 (D7-C1's baseline) -> 700/0, three times, identical, on scratch stores (XDG_DATA_HOME); a later re-run reads 689/11, all 11 in D7-C2's in-flight armory suites (attribution in Evidence)"
---

# D7-C3 report — ship status modal restyle (UI_SPEC §3.8's Mockup C block on the §3.9 language)

## Result

`ui/hud/ship_status_screen.gd` is now Mockup C's surface on the §3.9 instrument language:
**one flat `ui_status_panel` console plate** (master 1440×1040 = 2× the 720×520 box, no
nine-slice) with **three code-drawn wells** at the mockup's own 1:1 rects — the left render well
(24,60)-(300,428) with the hull side render **aspect-fit into it** and the hardpoint markers as
code-drawn **bone-ringed ember dots**, the right slot well (316,60)-(696,348) with the slot grid
(cells 60×74 on a 72×88 pitch for a 5×3 matrix, the `W1..W5` refs as 10 px `SlotNumber` Labels,
fitted modules as glyph plates on the shipyard plate recipe) and the footer strip
(24,444)-(696,494) with the `HULL`/`SHLD`/`PWR` `cur / max` `HudReadout` Labels. Title Label at
(30,22) + the 26×26 `icon_close` box at (668,20). **Every colour, layout metric and asset path
comes from `CockpitStyle`** (§3.9 rule 5). **Behaviour is untouched**: `test_d6_status.gd` is
byte-identical and **16/16 green**, `test_engine2_hud.gd` is byte-identical, and the D7-C1 suites
are 32/0.

Measured on the live tree (scratch-store probe, `XDG_DATA_HOME=/tmp/d7c3_probe*`; the probe script
was deleted after the numbers were taken):

```
PROBE_MODAL (720,520) body=(720,520)
PROBE_WELLS  [(24,60,276,368), (316,60,380,288), (24,444,672,50)]   # painter == style.status_wells()
PROBE_PLATE  { path: res://assets/ui/ui_status_panel.png, size: (1440,1040), class: TextureRect, stretch: 0 (SCALE) }
PROBE_FRAME  { path: res://assets/ui/ui_cockpit_frame.png, visible: false, patch: 64, scale: (0.5,0.5) }
PROBE_RENDER intact   { native: (960,521),  box: (244, 132.42), pos: (40, 177.79), area: (40,76,244,336) }
PROBE_RENDER damaged  { native: (1023,997), box: (244, 237.80), pos: (40, 125.10) }
PROBE_MARKERS { count: 11, ring: (0.7882,0.8039,0.8235)=#C9CDD2 bone,
                fill: (0.7843,0.2784,0.1216)=#C8471F ember, radius: 5.0, width: 1.0,
                parent: HullRenderBox, first anchor: (33.51, 92.33) }
PROBE_FOOTER HullValue (40,458) "HULL 812 / 1000" | ShieldValue (250,458) "SHLD 240 / 300"
             | PowerValue (470,458) "PWR 3 / 8"  (all HudReadout, 18 px)
PROBE_CHROME title "SHIP STATUS" at (30,22) font 20 | close (668,20) 26x26 icon_close.svg
PROBE_CAPTION "SLOT LAYOUT" at (316,360) | rows band (316,382,380,58), 5 rows
PROBE_GRID   vanguard matrix (4,4), scale 0.757396, cell (45.44379,56.04734),
             pitch (54.53255,66.65089), origin (332,76), pin_cell (60,74), pin_pitch (72,88)
PROBE_GRID_NODE columns 4, children 16, position (332,76), size (207,254)   # inner is (348,256)
PROBE_REFS 11  (e.g. W1 col=1 row=0 fitted=true rect=(386.53,76,45.44,56.05),
                ref inset (4.54,3.03), plate (45.44,56.05), glyph (21.21x24.24) at (12.12,19.69),
                ref font 10, variation SlotNumber)
```

## What shipped, as measured

### `ui/hud/cockpit_style.gd` (C1's Resource, extended — `ui/hud/` is the shared set)

- **palette**: `bone` = STYLE_BIBLE §2.4's Bone Text `#c9cdd2` (the marker ring; §1 has no such
  token, and §3.9 rule 2 names "Bone/Panel-Steel"). The file is still the family's **only** hex
  store: 11 literals, all here.
- **layout** (`status_*`): box 720×520, left well (24,60,276,368), right well (316,60,380,288),
  footer (24,444,672,50), inset 16, cell 60×74 on a 72×88 pitch, ref inset (6,4) / ref zone 26,
  glyph plate 28×32, title (30,22) / 20 px, close 26×26 at margin 52, caption inset 12 / height 18,
  rows inset 4, footer origins 40/250/470 at inset 14, ref font 10, row font 13, marker radius 5 —
  every value is Mockup C's own (`staging/mockup/mockup_rest.py:status()`).
- **assets**: `status_panel_path`, `close_icon_path`, and the **retired** `status_legacy_frame_path`
  (+ patch 64, scale 0.5) so even the retired node's art path lives in the style.
- **derived geometry, computed once** (`cockpit_style.gd:390-517`): `status_wells()`,
  `status_render_area()`, `status_grid_origin()`, `status_grid_inner()`, `status_cell_gap()`,
  `status_grid_scale(columns, rows)`, `status_cell_size_for/pitch_for`, `status_cell_rect`,
  `status_grid_rect`, `status_glyph_rect`, `status_ref_inset_for/zone_for`, `status_caption_rect`,
  `status_rows_rect`, `status_close_rect`, `status_footer_label_pos(index)`. The painter and the
  tests read the same list.

### `ui/hud/ship_status_screen.gd` (restyled, same class, same file)

- **Plate** (`_build_plate`): a plain `TextureRect` at `style.status_panel_path`, full-rect,
  `EXPAND_IGNORE_SIZE` + `STRETCH_SCALE` (measured class "TextureRect", master 1440×1040) with a
  `panel_steel` fill fallback when the path does not resolve.
- **Wells** (`StatusWells`, `:979`): the left and right wells as recesses (shadow top/left in
  `metal_dark`, lit bottom/right in `metal_light`, `void_base` interior) and the footer strip as a
  raised ledge (the mockup's own bevel), code-drawn from `style.status_wells()`.
- **Title / close / caption**: engine `Label`s (`StationPanelTitle` / `StationCaption`, sizes from
  the style) and the `icon_close` `TextureButton` — no baked text anywhere (§3.9 rule 3).
- **Left well**: the render box is aspect-fit into `style.status_render_area()` (the D6 R1-MED-1
  rule kept: the box takes the sprite's own aspect, never the well's height), so the intact
  vanguard draws 244×132.42 and its damaged cut 244×237.80; the **damaged-cut swap rule is
  unchanged** (`repairs_panel.gd`'s own `hull_render`).
- **Markers** (`HardpointMarkers`, `:1029`): the D6 anchors and kinds, drawn as **bone-ringed ember
  dots** (`draw_circle` in `accent_danger` + a `frame_width` `draw_arc` in `bone`) over the render.
  `markers()` keeps the `kind`/`mode`/`facing` fields (the D6 read-back is why the suite still
  passes), and `marker_colours()`/`marker_radius()`/`marker_width()` are the new style read-backs.
- **Right well** (`_refresh_grid`, `:572`): cells on the shipyard plate recipe (`SlotButtonWeapon`
  textures, the module/type glyph in the cell's own style-sized glyph plate) at the style's Mockup C
  geometry, each carrying its ref Label and (when fitted) its module glyph plate; **larger matrices
  are scaled to fit the well** rather than clipped (`status_grid_scale`, floored whole-pixel
  separations so `GridContainer` cannot overrun — the drawn vanguard grid is 207×254 inside the
  348×256 inner area).
- **Footer** (`_refresh_footer`): unchanged arithmetic — the fitting panel's own `_power_of`,
  `ShipFit.fit_legal(hull, _base_fit(fit))[&"power"]` (`ship_status_screen.gd:794-798`), the D6
  formats and `HudReadout` variation; only the origins moved (mockup 40/250/470 at y 458).
- **Behaviour**: `set_open/open/close/toggle/is_open/set_docked/docked/set_hull_slots/set_hull/
  set_pools/_refresh*/apply_theme` and every D6 read-back are unchanged; the retired D6 nine-slice
  frame node survives (hidden) exactly as the D7-C1 precedent retired the old HUD column.

### The cell geometry, per hull (measured, `status_grid_rect`)

| hull | matrix | scale | grid rect | fits inner (348×256)? |
|---|---|---|---|---|
| `ship_fighter` | 4×3 | **1.0000** | 276×250 | yes — the only hull drawn at the exact pin (60×74 on 72×88) |
| vanguard / miner / trader / corvette | 4×4 | 0.7574 | 209.04×256 | yes |
| freighter / gunship / patrol | 4×5 | 0.6009 | 165.86×256 | yes |
| `ship_destroyer` | 5×6 | 0.4981 | 173.32×256 | yes |

The pinned 5×3 canvas is exact: `status_cell_rect(0,0,5,3)` = (332,76,60,74),
`status_cell_rect(4,2,5,3)` = (620,252,60,74), and the whole matrix rect (332,76,348,250) is inside
the inner area (332,76,348,256).

## Tests touched (every row, and why)

- **`tests/test_d6_status.gd` — ZERO rows moved** (`git diff --stat` empty; byte-identical).
  16/16 green with the restyle, including the row that pins the retired nine-slice frame node, the
  toggle guard, the docked guard, the grid/module-row rows, the destroyed-side swap, the marker
  positions **and the no-write proof** (the profile's bytes identical before/after).
- **`tests/test_engine2_hud.gd` — untouched** (byte-identical), green.
- **`tests/test_d6_cluster.gd`, `tests/test_d7_cockpit.gd` — untouched**, 32/0 focused (my
  `CockpitStyle` additions are additive; no cluster default moved).
- **`tests/test_d7_status.gd` — new, 8 rows in 6 groups**: (1) the flat plate + the retired frame +
  the title/close chrome; (2) the three wells at the pinned rects and the painter/style agreement;
  (3) the bone-ringed ember dots on the aspect-fit render; (4+5) the mockup cell geometry, the
  per-hull fit and every drawn cell's ref/glyph plate (plus the ref↔module-row seam); (6) the footer
  figures from `fit_legal`; (7+8) `CockpitStyle`'s default numbers and the user-`.tres` proof (box,
  wells, grid, palette, panel path and footer origins all move with no code edit, then reverse).

No other test file was touched, and no existing test's expectations moved beyond the brief's
`tests that move` list (which names `test_d7_status.gd` as **new** and `test_d6_status.gd` as
untouched — both hold).

## Deviations from the brief / docs (bucket-tagged, each reversible)

1. **(bucket 1) The D6 `ui_cockpit_frame` nine-slice node is retired hidden, not deleted.** §3.8's
   amendment says the `ui_status_panel` plate "replaces `ui_cockpit_frame` here", while the same
   brief pins `test_d6_status.gd` **untouched and byte-green** — and that suite asserts the frame
   node's texture, 64 px patch band and half scale. The visible chrome is the plate alone (the frame
   is `visible = false`); the node stays so the pinned yardstick keeps its subject. Reversal: delete
   the node and that one D6 row.
2. **(bucket 1) The mockup's two left-well caption lines are not drawn.** `mockup_rest.py` prints
   "VANGUARD · FIGHTER" at (44,392) and "5 hardpoints mapped" at (44,408); neither §3.8's Mockup C
   block nor the design report's Mockup C row names them, and no pinned source for a hull display
   name exists (`ShipFit` carries no name field). Reversal: two `Label`s at the mockup's own rects.
3. **(bucket 1) Each drawn grid cell keeps the shipyard's `SlotButtonWeapon` plate texture** (§3.8's
   "on the shipyard plate recipe") rather than the mockup's procedural recess stand-in, and the
   three *panel* wells are code-drawn. Reversal: drop `_apply_plate_textures` and draw a recess per
   cell instead.
4. **(bucket 1) A matrix larger than the pinned 5×3 canvas is scaled to fit, not clipped.** Measured:
   eight of the nine hulls carry more than the canvas's three slot rows (four rows on vanguard /
   miner / trader / corvette, five on freighter / gunship / patrol, six on the destroyer), so a
   literal 60×74/72×88 read would push the destroyer's matrix (514 px tall at the pin) **258 px**
   past the well's 256 px inner height. The scale is a style derivation (`status_grid_scale`,
   `cockpit_style.gd:419`) and the pin is exact for a 5×3 canvas (the fighter's 4×3 draws 60×74 on
   72×88). Reversal: return 1.0 and let the grid overflow.
5. **(bucket 1) The module rows list (D6's `module_rows` surface) rides a 58 px scroll band under
   the `SLOT LAYOUT` caption.** The mockup's own band (360..444) cannot hold the vanguard's five to
   seven 13 px rows; the rows stay engine Labels named `Row<TOKEN><nn>` with their D6 texts, so
   every D6 assertion still reads them. Reversal: enlarge the band/panel, or drop the list and its
   D6 rows.
6. **(bucket 1) The footer strip draws as a raised ledge** (light top/left, dark bottom/right — the
   mockup's own `bevel()`), while the two real wells draw as recesses. §3.9 rule 2 says "recessed
   well"; Mockup C draws the strip the other way and the pin wins. Reversal: `_draw_raised` →
   `_draw_recess`.
7. **(bucket 1) The ref/row/caption Labels use theme variations with style-supplied sizes**:
   `SlotNumber` (exactly the pinned 10 px) + a style colour/size override for the refs,
   `StationCaption` (13 px) for the caption and the module rows, `StationPanelTitle` (20 px) for the
   title, `HudReadout` (18 px, D6-pinned) for the footer. No new number is invented.
8. **(bucket 1/2) `CockpitStyle` gained the `bone` role and the `status_*` block.** §3.9 rule 5
   routes *every* colour/metric/path of *every* cockpit-family surface through the one Resource, so
   the Modal C numbers had to land there; `bone` is STYLE_BIBLE §2.4's value (not a §1 token), kept
   in the same single file as every other hex literal. Reversal: hardcode (the D6 status quo).
9. **(bucket 1) The mount markers lost their facing tick** (Mockup C draws plain dots); the `facing`
   field survives in `markers()`, which is why `test_d6_status.gd`'s facing assertion still holds.
   Reversal: draw the tick again.
10. **(bucket 1) The module glyph modulate now reads the style's `text_primary`/`text_dim`** instead
    of the theme tokens (rule 5; identical values, one source). The outer class's `_token` helper
    went with it; the marker class keeps its own defensive no-style fallback.
11. **(bucket 1, hygiene) One bounded `--headless --editor --quit` pass was run**, only so the new
    `tests/test_d7_status.gd` gets its engine-issued `.uid` sidecar (`.uid` files are tracked in
    this repo; the runner itself loads by path). It registered the new script (and C2's
    `ArmoryStyle`), touched no asset: the D7 `.import` sidecars' md5s are identical before and
    after, and no asset byte changed. No import of A1's plates was needed here (A0b owns that
    pass).
12. **(bucket 2, attribution) `docs/CONTRACTS.md` shows an uncommitted +137 lines** (§20 "S7 affix
    application") in the wave verifier's `modified` list. It is another lane's docs-first (coder
    item 13), not this worker's: my frozen set (`project.godot`, `docs/gameplay/18_engine_spec.md`,
    `docs/gameplay/08_ship_slots_modules.md`, `docs/CONTRACTS.md`, `ui/theme/`, `addons/`, `game/`,
    `autoload/`) diffs empty against the working tree's own content for every path but that one
    shared doc.

## Evidence

Gate, three times, identical, on fresh scratch stores:

```
XDG_DATA_HOME=/tmp/d7c3_gate1 $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
        res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=700 failed=0
XDG_DATA_HOME=/tmp/d7c3_gate2 ... (same command, fresh store)  [SUMMARY] passed=700 failed=0
XDG_DATA_HOME=/tmp/d7c3_gate3 ... (same command, fresh store)  [SUMMARY] passed=700 failed=0
```

The only `SCRIPT ERROR` in every run is the pre-existing benign one at
`tests/test_weapon_fx_f4.gd:178` (`Cannot call method 'call' on a previously freed instance`),
present on the 674 baseline too. Each fresh store holds only `godot/app_userdata/Vajb Orbit/`
`_gate_scratch/` + `logs/`.

The live store is untouched by all three runs (before and after: `profile.cfg` md5
`027e6eb178fca5d6b46cff535465d7be`, `economy_log.txt` md5 `ca40fe2c0ab3bd0f2047723a2d737d9a`,
`profile.cfg` mtime `Sep 24 10:46:57` — the same values D7-C1 recorded).

Focused runs: `--suite=test_d7_status` → `passed=8 failed=0`; `--suite=test_d6_status` →
`passed=16 failed=0`; `--suite=test_d7_cockpit --suite=test_d6_cluster` → `passed=32 failed=0`;
all four together (after the editor pass and with D7-C2's current tree) → `passed=56 failed=0`.

**A concurrent-lane attribution, measured (not this worker's).** The three full-gate runs above
are the tree state D7-C3 shipped. A later re-run (after this worker's bounded
`--headless --editor --quit` pass, run only to generate `tests/test_d7_status.gd.uid`) reads
**689/11**, and every one of the 11 failures is in `test_p2b1_outfitting_panel.gd` (8) and
`test_s5_batteries_v2.gd` (3) — the armory/fitting rows D7-C2 owns. Measured cause: C2's in-flight
`vajb-orbit/ui/station/armory_panel.gd` was written at **11:35:45** (the gate re-run started
11:35:46; `git diff --stat` = +767/−70), and neither failing suite references any D7-C3 surface
(`rg 'CockpitStyle|cockpit_style|ship_status|ShipStatusScreen'` over both suites → no match). No
D7-C3 file is in those rows; the 11 failures are another lane's work in progress and were left
alone. The editor pass itself changed no asset byte (the `.import` sidecars' md5s are unchanged:
`ui_cockpit_panel` `a72e79c9`, `ui_status_panel` `b5f1cbec`).

Frozen-file / hygiene checks for this worker (independent of the wave verifier):

```
git diff --stat -- vajb-orbit/tests/test_d6_status.gd vajb-orbit/tests/test_engine2_hud.gd  -> (empty)
git diff --name-only -- vajb-orbit/project.godot vajb-orbit/ui/theme vajb-orbit/addons \
        vajb-orbit/game vajb-orbit/autoload docs/gameplay/18_engine_spec.md \
        docs/gameplay/08_ship_slots_modules.md                                            -> (empty)
rg 'Color\("#|get_theme_color' vajb-orbit/ui/hud/ship_status_screen.gd
        -> only the marker class's no-style fallback (_token, ship_status_screen.gd:1091)
rg -c 'Color\("#' vajb-orbit/ui/hud/cockpit_style.gd    -> 11 (the family's one hex store)
python3 staging/verify_wave.py verify --baseline d7_start -> problems: [], my three files listed
        (ship_status_screen.gd modified; test_d7_status.gd + cockpit_style.gd added)
```

The measurement probes were temporary suites in `res://tests/` (`test_d7c3_probe*.gd`) and were
deleted after the numbers above were taken; they are not part of the deliverable.

## Files touched

- `vajb-orbit/ui/hud/ship_status_screen.gd` (1093 lines) — the Mockup C restyle
- `vajb-orbit/ui/hud/cockpit_style.gd` (C1's Resource; `bone` + the `status_*` layout/assets block
  + the `status_*` derived functions)
- `vajb-orbit/tests/test_d7_status.gd` (**new**, 571 lines, 8 rows)
- `vajb-orbit/tests/test_d7_status.gd.uid` (engine-generated sidecar)

No `game/`, `autoload/`, `project.godot`, `ui/theme/`, `docs/`, `addons/`, `staging/`,
`asset-library/` or asset byte was touched, and no other test file was modified.

## Follow-ups

| Item | Kind | Where |
|---|---|---|
| The mockup's two left-well caption lines (hull name + "N hardpoints mapped") | unpinned mockup detail (Deviation 2) | `ship_status_screen.gd` left well; needs a hull display name |
| 5×6 hulls draw their matrix at scale 0.498 (cells 29.9×36.9) | metric, owner-tickable (Deviation 4) | `CockpitStyle.status_grid_scale` / `status_cell_size` |
| The module rows band is 58 px and scrolls for hulls with many fitted modules | metric, owner-tickable (Deviation 5) | `CockpitStyle.status_rows_rect()` |
| `ui_seg_*` glyph-only re-authoring (C1's Deviation 9) still needed for the cluster's overlap cure | art defect, not this worker's set | `assets/ui/ui_seg_*.png`, UI_CHROME §12 |
