---
slice: D7
worker: D7-C1
model: "deepseek-v4-flash (crush run, per D7_prompts.md), Godot 4.7.2-stable headless"
status: actionable
gate: "674/0 (pre-work baseline) -> 692/0, twice, identical, on scratch stores"
---

# D7-C1 report — cluster rework (v7 layout + CockpitStyle) + digit fix + compass dedup + old-column removal

## Result

The cockpit instrument cluster is now Mockup v7's surface, and every colour, layout metric and
asset path it uses comes from one `CockpitStyle` Resource (UI_SPEC §3.9 rule 5): **464×256** flat
`ui_cockpit_panel` plate, **code-drawn wells** at the pinned rects (UI_CHROME §12 Amendment 2),
left bay = the §3.6 gauge + the `B1..B5` battery lamps band, middle bay = the two value dials
**FUEL**/**ENRG**, right bay = one full-interior-height readout well with **SPD / HULL / SHLD /
AMMO** spread on the pinned 50.7 px pitch. The compass, the HDG row and the dial's heading tick
are gone (`compass()` / `compass_heading()` answer as stubs); the old HUD column (§3.1 crest
bars, §3.2 `AmmoPanel`, §3.4 cargo block) is retired; every §7 frozen method keeps its signature
and stays callable. **Gate 692/0 twice, identical** (baseline before this work: 674/0).

Measured live (headless probe, `XDG_DATA_HOME` scratch): cluster `custom_minimum_size`
(464, 256) at global (12, 812) inside `CanvasLayer/BottomLeft/Blocks`; gauge bay 120×120; every
drum 20×36 at x 36/58/80/102, **0 overlapping pairs and 0 cells outside their row** in all four
rows; five lamps 22×22 on 25 px centres (band 122) with B1 lit; dials 72×72 at (214, 78) and
(214, 181) with **23 px** between their well rims; the five code-drawn wells at
(35, 48.5, 120, 120), (32, 185, 126, 36), (174, 38, 80, 80), (174, 141, 80, 80) and
(279, 32, 150, 189.1).

## What shipped, as measured

### `ui/hud/cockpit_style.gd` (new, `class_name CockpitStyle extends Resource`)

`@export_group`s exactly as §3.9 rule 5 names them — **palette** (10 fields: `panel_steel` +
the nine §1 tokens, each default carrying its token name), **layout** (box, band, three bay
widths, gutter, well inset, foot/row height, row pitch, row insets, label zone + font, drum cell
+ pitch, frame width, dial radius/rim/centres/wedges/sweep/needle/hub/label font, gauge size,
lamp count/size/gap/font/corner) and **assets** (`panel_path`, `gauge_face_path`,
`gauge_needle_path`, the `ui_seg_*` dir/prefix/blank/pct parts).

- `CockpitStyle.USER_PATH = "res://ui/hud/cockpit_style_user.tres"`; `load_style(path)` returns
  that file when it exists (checked by script identity) and the built-in defaults otherwise — a
  path that does not resolve is a silent fallback, never a broken cluster.
- The script is reached through `SCRIPT_PATH` rather than its own global class name, so the
  family parses in a headless gate whose class table predates the file (the D6 lesson for
  `ship_status_screen.gd`). The class name still ships for the user's `.tres`.
- Derived geometry is computed once, here, and both the painter and the tests read it:
  `interior/left_bay/middle_bay/right_bay/foot_well/gauge_centre/gauge_well_radius/lamp_width/
  lamp_origin/lamp_rect/row_width/rows_top/row_x/row_rect/cell_rect/rows_bottom/readout_well/
  dial_well_radius/dial_clearance/dial_sweep/dial_start/wells/colour/lamp_fill/seg_path/texture`.
- **Zero hex literals outside this one file**: `rg 'Color\("#|get_theme_color|has_theme_color'
  ui/hud/cockpit_cluster.gd` → no match. The palette defaults are §1's own values (each
  documented with its token name), so this file is the cockpit family's single colour store, the
  way `vajb_theme.tres` is for every other surface (bucket-1 reading of §3.9 rule 5 vs the
  brief's "no hex literals" hard rule — see Deviation 8).

Measured derivations (the probe output in Evidence): interior (32, 32, 400, 192); bays
(32, 32, 126, 192) / (165, 32, 104, 192) / (276, 32, 156, 192) with 7 px gutters and the right bay
flush at 432; foot well (32, 185, 126, 36); gauge centre (95, 108.5) r 60; lamps w 122 origin
(34, 192); row w 122 x 283 top 33 pitch 50.7 → rows at y 33 / 83.7 / 134.4 / 185.1, last bottom
**221.1** against the foot band's 221.1; readout well (279, 32, 150, 189.1); dial wells r 40,
clearance **23.0**; sweep 4.712 rad (270°).

### `ui/hud/cockpit_cluster.gd` (reworked; same `class_name`, same file)

- **Panel**: a plain `TextureRect` (never a nine-slice) at `style.panel_path`, full-rect, with a
  `panel_steel` fill fallback when the path does not resolve. A1's flat plate (928×512 RGBA)
  ships; the cluster takes any master because the node scales to the box.
- **Wells** (`Wells`, a `Control`): the gauge disc, the foot band, the two dial discs and the
  readout well, code-drawn — filled in `void_base` with a recess bevel (shadow top/left in
  `metal_dark`, lit bottom/right in `metal_light`). `wells()` / `Wells.well_rects()` return the
  very list the painter walks.
- **Battery lamps** (`LampBand`): five `StyleBoxFlat` lamps (corner radius and 1 px border from
  the style), the selected rack's lamp filled with `lamp_fill(accent_danger_bright)` (derived:
  `ember_bright.darkened(0.75)`, so a restyle moves it) + `accent_danger_bright` border and
  caption, the rest `void_panel_raised` / `metal_dark` / `text_dim`. Captions `B1..B5` are engine
  `Label`s (no baked text).
- **Two value dials** (`ValueDial`): 72×72, 270° arc of 10 thin wedges + needle + hub + a 12 px
  name `Label` over the lower face; `round(100 × value / maximum)` clamped 0..100 (`maximum == 0`
  reads 0); the FUEL dial's danger read is `≤ 15 %` (and an empty tank with capacity) → lit arc
  `accent_danger`, needle `accent_danger_bright`. Read-backs: `percent/fraction/danger/
  lit_wedges/needle_colour/dial_label/dial_key`.
- **Readout rows** (`ReadoutRow`, now a code-positioned `Control`, not an `HBoxContainer`): the
  11 px label in the 36 px zone + four drums placed at `style.cell_rect(i)` with
  `EXPAND_IGNORE_SIZE` + `STRETCH_SCALE`, so each `ui_seg_*` sprite is **fill-fitted to exactly
  20×36 on the 22 px pitch** and no container can stretch a cell into its neighbour (the D6
  overlap class' blind spot: the row's geometry is now exact before any layout pass, which is
  also why the test can assert it headlessly). Read-backs kept: `cells/percent_lit/percent_cell/
  digit_cells/cell_rects/label_token/frame_token/framed/label_colour/frame_colour/label_node/
  label_text/apply_theme`.
- **Read-backs**: `readouts() -> {spd, hull, shield, ammo}`; `compass()` → `null`; and
  `compass_heading()` → `0.0` (both stubs, per Mockup v7 + CONTRACTS §18's keep-callable rule);
  plus `pool_readings()` (the dials' post-clamp `{value, maximum, percent, danger}`),
  `value_dial(key)`, `lamp_band()`, `active_rack()`, `wells()`, `style()`, `set_style()`,
  `set_style_file()`, `set_ammo(rounds)`, `set_active_rack(ordinal)`. `gauge_bay()` survives so
  `hud.gd` still attaches the §3.6 dial it owns.
- **Digit semantics unchanged**: SPD `int(round(prograde.length()))` 4 cells 0..9999; HULL/SHLD
  `int(round(current))` 4 cells 0..9999; AMMO `int(round(loaded))` 4 cells 0..9999; leading
  blanks never zeros; danger = label role + a 1 px frame, **digits never recolour**.

### `ui/hud/hud.gd` (reworked in place)

- **Heading tick retired** (UI_SPEC §3.6's 2026-09-24 amendment): `Speedometer` no longer holds
  a heading vector or `HEADING_LENGTH`, and `_draw` draws no tick. `set_speedometer(ratio,
  prograde, heading)` and `set_reading(ratio, prograde, heading)` keep their signatures; the
  heading argument is accepted and ignored. Every §3.6 read-back (`filled_segments`,
  `overdrive_segment`, `needle_colour`, `SEGMENTS` 10, `SWEEP` 1.5π, `OVERDRIVE` 0.9, the 120×120
  box) is untouched.
- **`set_surface_paths(face, needle)`** (additive, §3.9 rule 5): the dial's painted face and
  needle come from the style's asset paths, falling back to the D6 preloads when a path does not
  resolve. `_build_speedometer` passes the cluster's style paths.
- **The old column**: `_retire_old_column()` hides the five widgets (TopLeft `HullBlock`,
  `ShieldBlock`; `AmmoPanel`; `CargoToggle`; `CargoPanel`) and `retired_widgets()` exposes them
  for the absence assertion. They stay in the scene because §3.7 keeps the §7 API callable with
  "hidden/no-op widgets where nothing remains to drive". `set_cargo_open` still latches and still
  emits `cargo_toggled` (so `game.gd`'s mirror and the key keep working) but the panel stays
  hidden. §3.1b's pool blocks are **not** retired (Deviation 10).
- **The two new pushes** (no new sim feed): `_refresh_weapon()` now also calls
  `_cockpit.set_active_rack(_active_slot + 1)` and `_cockpit.set_ammo(_ammo)` — the same rack
  ordinal the weapon grid selects and the same ammo figure the retired panel showed.
- `readouts()`'s no-cluster fallback updated to the v7 shape `{spd, hull, shield, ammo}`.

### Digit fit law — measured

The law is now structural (cells positioned at style rects, never container-laid-out) and the
test asserts the drawn rects: for all four rows, 4 cells each, size exactly (20, 36), x at
36 / 58 / 80 / 102 (pitch 22, 2 px disjoint gaps), pairwise disjoint, each enclosed by its row
(122 × 36). The D6 status quo measured on the live frame was the same 20/22 geometry (probe on
the pre-change tree: `overlaps=0`), so the *node* geometry was already right — see Deviation 9
for what actually collides and why it is not this worker's file set.

### `CockpitStyle` override proof

`test_a_user_tres_restyles_and_relayouts_with_no_code_edit` writes a `CockpitStyle` to
`user://d7_cockpit_style_probe.tres` (box 600×300, `bay_left` 150, `row_pitch` 60, cell 24×40 on
26, `text_dim` (0.1, 0.9, 0.2), `dial_top` (280, 90)), routes it through the cluster with
`set_style_file(path)`, and asserts: the box becomes 600×300 on `custom_minimum_size`, the bay
and pitch move, the drum cell is fill-fitted at 24×40, the drawn row label's colour **is** the
file's palette value, and the dial well's centre is the file's (280, 90). It then drops the file
(`set_style_file(USER_PATH)`) and asserts the shipped 464×256 box returns — the override is not a
one-way door. The file is deleted in teardown; the gate's `user://` lives in the scratch store.

## Tests touched (every row, and why)

**`tests/test_engine2_hud.gd` — ZERO rows moved** (byte-identical, verified by `git diff`).
Measured reason: that suite never asserted the heading tick (`rg 'heading|tick|HEADING'` finds no
assertion there), so §3.6's amendment retires nothing from it. The brief's "only the heading-tick
rows move" is satisfied by moving none; its §3.1b/§3.5/§3.6/§3.10 rows are all green.

**`tests/test_d6_cluster.gd` — 14 rows, 4 unchanged, 10 changed (4 of them renamed).** The
brief says only the compass rows move, but Mockup v6/v7 reworks every surface this suite
measures, so the alternative was 9 rows erroring out. Measured: with the reworked cluster and the
*unmodified* D6 suite, 9 of its rows raised runtime errors
(`Invalid access to property 'fuel_pct'` / `Cannot call method 'call' on a null value`) and the
harness counted **8 of them as PASS** (a runtime error aborts the method before any assertion
records a failure) — the re-aim was mandatory, not cosmetic.

| # | row | disposition |
|---|---|---|
| 1 | `test_the_cluster_is_the_pinned_box_with_the_dial_and_the_compass_inside` | **renamed** `..._with_the_gauge_and_the_dials_inside`; asserts 464×256, the 120×120 gauge bay, the four rows, both dials + the FUEL caption |
| 2 | `test_the_section_3_6_dial_contract_holds_through_the_cluster` | **unchanged** |
| 3 | `test_the_readouts_are_the_clamped_ints_the_digits_show` | changed: ammo leg, the four-key shape, the two percents off the dials |
| 4 | `test_the_digit_cells_pad_with_blanks_never_leading_zeros` | changed: the FUEL pad → the AMMO pad (every v7 row is four cells) |
| 5 | `test_the_readouts_clamp_at_their_cell_maxima` | changed: percents off the dials; + the AMMO 0..9999 clamp |
| 6 | `test_a_pool_with_no_capacity_reads_zero` | changed: reads the FUEL dial (percent 0, no danger, no wedge) |
| 7 | `test_the_percent_cell_lights_only_on_the_fuel_and_energy_rows` | **renamed** `test_the_percent_cell_retired_with_the_fuel_and_energy_rows`; asserts the absence |
| 8 | `test_hull_below_a_quarter_brightens_the_label_and_frames_the_row` | **unchanged** |
| 9 | `test_fuel_at_or_below_fifteen_percent_frames_the_row` | **renamed** `..._dangers_the_dial`; needle/arc/wedge reads + the ENRG dial's no-danger rule |
| 10 | `test_an_empty_tank_frames_the_fuel_row_bright` | **renamed** `test_an_empty_tank_dangers_the_fuel_dial` |
| 11 | `test_the_overdrive_read_is_strict_at_exactly_point_nine` | **unchanged** |
| 12 | `test_danger_reads_never_recolour_the_digits` | changed: the fuel leg → the needle, the frame leg → the critical hull row, the sweep covers the four surviving rows |
| 13 | `test_the_compass_rose_rotates_against_the_heading` | **renamed** `test_the_compass_retired_with_mockup_v7`; `compass() == null`, the stub heading |
| 14 | `test_the_compass_heading_maps_into_zero_to_359` | **renamed** `test_the_heading_stub_answers_zero_for_every_heading`; the four headings all read 0.0, `readouts()` carries no `hdg` |

No D6 row was retired, so the suite's row count is unchanged (14).

**`tests/test_d7_cockpit.gd` — new, 18 rows** in six groups: the box/interior/bays (1), the wells
at the pinned rects + the flat-plate architecture (2), the two dial rims (1), the digit fit law
(3), the stack's full-height spread + the engine Labels (2), the lamps (2), the AMMO row feed +
the rack mapping through `set_hull_slots` (2), the retired column + the frozen API + the retired
tick (3), and `CockpitStyle` (3). No other file's tests were touched.

**Not touched** (re-measured green): `test_ui_slot_layout.gd` (the weapon grid is hidden, not
gone, so its rows still measure it), `test_d6_status.gd`, `test_p2b*`, `test_s5_*`.

## Deviations from the brief / docs (bucket-tagged, each reversible)

1. **(bucket 2) `test_d6_cluster.gd` needed 10 rows, not 1.** Cause measured above (9 rows
   errored, 8 silently passing). Reversal: restore the D6 suite and the D6 surface.
2. **(bucket 2) `test_engine2_hud.gd` needed 0 rows.** The brief named rows that do not exist.
   Reversal: none needed.
3. **(bucket 1) The gauge well is Ø120 centred at (95, 108.5), not the mockup's Ø112 at
   (95, 86).** The mockup draws a 106 px-radius face; the pinned §3.6 dial is 120×120, which
   cannot fit a Ø112 well, and the mockup's own centre puts its well 2 px above the interior.
   The well is now the dial's exact 120×120, centred in the left bay's gauge area (interior top
   → foot well top), so the dial sits 22.5 px lower than the mockup's. Reversal:
   `CockpitStyle.gauge_size` (and a centre override) restore the mockup's placement.
4. **(bucket 1) The row block's placement is 7 px in from the right bay and 1 px down from the
   interior top (the mockup's own measured 283 / 33), and the readout well is derived from the
   rows so the last row's bottom lands on the foot band (221.1 vs 221).** Reversal:
   `row_x_inset` / `row_inset` / `well_inset`.
5. **(bucket 1) The old column is hidden, not deleted.** §3.7 itself sanctions "hidden/no-op
   widgets"; deleting the nodes would have broken `test_ui_slot_layout.gd`'s weapon-grid rows and
   every `@onready` unique-name lookup for a gain no test could see. Reversal: delete the five
   nodes from `hud.tscn` and the `retired_widgets()` seam.
6. **(bucket 1) The dial centres use the pin's x = 214.** The mockup script's own 2× centre is
   434 → 217 (the middle bay's centre); the 3 px difference is invisible and the pin wins.
7. **(bucket 1) `Speedometer.set_surface_paths` is new (additive).** §3.9 rule 5 wants the
   dial's asset paths in the style; the §3.6 contract's read-backs and the `accent_nav` needle
   precedent are untouched, and the D6 preloads remain the fallback.
8. **(bucket 1/2) The style holds §1's hex values as its export defaults.** §3.9 rule 5 says
   "Defaults = this spec's numbers" and §1's numbers are hex; the brief's "no hex literals"
   rule is satisfied everywhere else (measured: the cluster and `hud.gd`'s D7 paths hold none).
   Reversal: make the palette resolve token names from the theme instead.
9. **(bucket 2/3 — the art half of the owner's overlap finding, NOT fixed here) The shipped
   `ui_seg_*` masters are opaque plate tiles.** Measured with Pillow: every master is 48×88 with
   `alpha_bbox` (0, 0, 48, 88) — full-bleed opaque — and `ui_seg_8`'s lit ink is 40×76 inside it.
   At the pinned 20×36 that ink is 16.7×31.7 and each cell's *plate* is a 20×36 tile, so adjacent
   plates sit 2 px apart and their unlit ghost outlines (40/48 of the sprite's width) read as the
   collision the owner measured. The recorded cure is UI_CHROME §12's post-mockup amendment
   (re-author the twelve cells glyph-only with transparent backgrounds); A0 left them
   byte-identical because the brief's hard rule says so, and `assets/` is not this worker's set.
   **Needs the art lane or F1; the cluster is ready to take the re-cut with no code change** (the
   style's `seg_dir`/`seg_prefix` and the fill-fit rects are unchanged). Reversal: none — this is
   a defect cure that has not happened yet.
10. **(bucket 3 — an owner tick) §3.1b's energy/fuel bars survive,** so the TopLeft pool blocks
    and the EMERGENCY FLIGHT banner still duplicate the new FUEL/ENRG dials. §3.7's retirement
    list names §3.1's crest bars, §3.2's `AmmoPanel` and §3.4's cargo block only, and §3.1b's own
    rows must stay green. The owner's wording ("all of old HUD should be gone") reads wider than
    the spec's list — reported for the owner's tick. Reversal: hide the pool blocks too (and move
    `test_engine2_hud.gd`'s four §3.1b rows).
11. **(bucket 1) The lamps band is five wide, and the input map reaches seven racks:** 
    `set_active_rack(6|7)` lights nothing rather than clamping onto B5. Reversal:
    `CockpitStyle.lamp_count`.
12. **(bucket 1) `readouts()`'s no-cluster fallback shape** was updated to the v7 four keys (it
    mirrored the retired `fuel_pct`/`energy_pct`).
13. **(bucket 1, hygiene) I ran `--headless --editor --path "$VAJB_PROJ" --quit` twice** (to
    register the new `CockpitStyle` global class and to import the D7 art that A0/A1 staged).
    That wrote Godot's own `.import` sidecars for the 10 D7 art files (`assets/ui/*.png.import`,
    `assets/icons/panel_*.png.import`) — **A0b owns that pass** and should re-run its
    import/`apply_import_settings` step over them; the sidecars are Godot defaults and harmless
    (the cluster loads the textures as imported). Also note the gate's `test_d7_cockpit.gd` row
    that reads `panel.texture.resource_path` needs the sidecar to exist for A1's plate.

## Evidence

Gate (twice, identical; scratch stores; the only `SCRIPT ERROR` is the pre-existing benign one in
`test_weapon_fx_f4.gd:178`, present on the 674 baseline too):

```
XDG_DATA_HOME=/tmp/d7c1_final1 $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
        res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=692 failed=0
XDG_DATA_HOME=/tmp/d7c1_final2 ... (same command, fresh store)
[SUMMARY] passed=692 failed=0
```

The live store is untouched by both runs (before and after: `profile.cfg` md5
`027e6eb178fca5d6b46cff535465d7be`, `economy_log.txt` md5 `ca40fe2c0ab3bd0f2047723a2d737d9a`,
`profile.cfg` mtime `Sep 24 10:46`). Each fresh store holds only `_gate_scratch/` + `logs/`.

Layout probe (scratch script, deleted after the measurement; `XDG_DATA_HOME=/tmp/d7c1_probe`):

```
PROBE_CLUSTER  {"min":[464.0,256.0], "pos":[12.0,812.0], "size":[464.0,256.0]}
PROBE_GAUGE_BAY {"pos":[47.0,860.5], "size":[120.0,120.0]}
PROBE_ROW spd  cells=4 overlaps=0 outside=0 size=(122.0, 36.0)
PROBE_CELL spd 0 rect=[P: (36.0, 0.0), S: (20.0, 36.0)] tex=res://assets/ui/ui_seg_blank.png
PROBE_CELL spd 3 rect=[P: (102.0, 0.0), S: (20.0, 36.0)] tex=res://assets/ui/ui_seg_0.png
   (hull / shld / ammo rows identical: 4 cells, overlaps=0, outside=0)
PROBE_WELL 0 [P: (35.0, 48.5), S: (120.0, 120.0)]
PROBE_WELL 1 [P: (32.0, 185.0), S: (126.0, 36.0)]
PROBE_WELL 2 [P: (174.0, 38.0), S: (80.0, 80.0)]
PROBE_WELL 3 [P: (174.0, 141.0), S: (80.0, 80.0)]
PROBE_WELL 4 [P: (279.0, 32.0), S: (150.0, 189.1)]
PROBE_LAMPS count=5 lit=1
PROBE_LAMP 0 rect=[P: (34.0, 192.0), S: (22.0, 22.0)] label=B1 colour=(0.9098,0.3843,0.1647,1.0)
PROBE_DIAL fuel rect=(178.0, 42.0) min=(72.0, 72.0) percent=0 needle=(0.7882,0.8196,0.8627,1.0) label=FUEL
PROBE_DIAL enrg rect=(178.0, 145.0) min=(72.0, 72.0) percent=0 needle=(0.7882,0.8196,0.8627,1.0) label=ENRG
PROBE_COMPASS null=true heading=0.0
PROBE_READOUTS {"ammo":0,"hull":0,"shield":0,"spd":0}
PROBE_POOLS {"enrg":{...},"fuel":{...}}
PROBE_RETIRED [false,false,false,false,false]
```

The style's own derivations (the same scratch probe, on `CockpitStyle.defaults()`):

```
PROBE_INTERIOR [P: (32.0, 32.0), S: (400.0, 192.0)]
PROBE_BAYS L=[P: (32.0, 32.0), S: (126.0, 192.0)] M=[P: (165.0, 32.0), S: (104.0, 192.0)] R=[P: (276.0, 32.0), S: (156.0, 192.0)]
PROBE_FOOT [P: (32.0, 185.0), S: (126.0, 36.0)]
PROBE_GAUGE centre=(95.0, 108.5) r=60.0
PROBE_LAMPS w=122.0 origin=(34.0, 192.0) r0=[P: (34.0, 192.0), S: (22.0, 22.0)] r4=[P: (134.0, 192.0), S: (22.0, 22.0)]
PROBE_ROW w=122.0 x=283.0 top=33.0 r0=[P: (283.0, 33.0), S: (122.0, 36.0)] r3=[P: (283.0, 185.1), S: (122.0, 36.0)] bottom=221.1
PROBE_WELL (readout) [P: (279.0, 32.0), S: (150.0, 189.1)]
PROBE_DIAL r=40.0 clear=23.0 sweep=4.71238898038469
```

The digit masters (Pillow, `assets/ui/ui_seg_*.png`):

```
ui_seg_8   (48, 88) alpha_bbox (0, 0, 48, 88) lit_bbox (4, 6, 44, 82) lit_w 40
ui_seg_1   (48, 88) alpha_bbox (0, 0, 48, 88) lit_w 11
ui_seg_blank (48, 88) alpha_bbox (0, 0, 48, 88) no lit ink
```

The D7 art the cluster reads (as of A1's ship, 11:15): `ui_cockpit_panel.png` 928×512 RGBA,
`ui_gauge_face.png` 240×240 RGBA.

The families this worker must leave alone are byte-identical to A0's D6 record:
`ui_seg_0` `7a884ea0`, `ui_seg_blank` `f9c2f26f`, `ui_compass_rose` `56f2f9ff`,
`ui_compass_lubber` `84a0babc`, `ui_gauge_needle` `87e66a2c`, `ui_cockpit_frame` `cfc4e234`.

The old suite against the reworked cluster (the reason the D6 rows moved) — 9 error sites:

```
SCRIPT ERROR: Invalid access to property or key 'fuel_pct' ... (lines 144, 171, 178)
SCRIPT ERROR: Cannot call method 'call' on a null value ... (lines 183, 218, 227, 253, 274)
SCRIPT ERROR: Invalid access to property or key 'custom_minimum_size' on Nil ... (line 94)
```

Commands: `$GODOT_CONSOLE --headless --editor --path "$VAJB_PROJ" --quit` (class cache + import;
no errors/warnings), then the gate; `--suite=test_d7_cockpit --suite=test_d6_cluster` for the
focused runs (`passed=32 failed=0`).

Frozen-file check for this worker (independent of the wave verifier):

```
git diff --name-only -- vajb-orbit/tests/            -> vajb-orbit/tests/test_d6_cluster.gd
git diff --stat -- vajb-orbit/tests/test_engine2_hud.gd -> (empty: byte-identical)
git diff --name-only -- vajb-orbit/project.godot vajb-orbit/ui/theme \
        docs/gameplay/18_engine_spec.md docs/gameplay/08_ship_slots_modules.md \
        docs/CONTRACTS.md vajb-orbit/game vajb-orbit/autoload vajb-orbit/addons  -> (empty)
```

`python3 staging/verify_wave.py verify --baseline d7_start` (run for information; the
orchestrator owns the close-out invocation): my three files appear under `modified`, and the two
new files under `added`. Its one forbidden hit, **`docs/CONTRACTS.md`**, is **not this worker's**:
it is S6's committed close-out (`git log -1 -- docs/CONTRACTS.md` → `1bc4d08`, 2026-09-24
10:47:57, the travel-wave boundary commit, which landed after the `d7_start` snapshot at
`639df19` 10:22) and `git diff docs/CONTRACTS.md` is empty. Same-lane/other-lane deltas in that
run: `docs/design/UI_SPEC.md`, `docs/design/UI_CHROME_ASSETS_SPEC.md`, `staging/**` (the D7
design + art lanes), and `.agents/gen/_state/*`, `docs/CONTRACTS.md`, `docs/gameplay/12|13`,
`dispatch_coder.md` (S6).

## Files touched

- `vajb-orbit/ui/hud/cockpit_style.gd` (**new**, 332 lines) — the one style Resource (§3.9 rule 5)
- `vajb-orbit/ui/hud/cockpit_style.gd.uid` (generated)
- `vajb-orbit/ui/hud/cockpit_cluster.gd` (893 lines) — the v7 cluster rework
- `vajb-orbit/ui/hud/hud.gd` — heading tick retired, old column retired, the two new pushes, the
  dial's style-supplied surface paths, `readouts()` fallback shape
- `vajb-orbit/tests/test_d7_cockpit.gd` (**new**, 569 lines, 18 rows) + `.uid`
- `vajb-orbit/tests/test_d6_cluster.gd` — 10 of 14 rows re-aimed (4 renamed), 4 byte-green

## Follow-ups

| Item | Kind | Where |
|---|---|---|
| Re-author `ui_seg_*` glyph-only (transparent) — the plate tiles are the measured collision | art defect (Deviation 9) | `assets/ui/ui_seg_*.png`, UI_CHROME §12's post-mockup amendment |
| A0b's ship/import pass over the D7 art (sidecars exist from this worker's import) | art lane | `staging/phase_g/ship_d7.py` |
| §3.1b's pool bars still duplicate the new FUEL/ENRG dials (owner tick) | design question (Deviation 10) | UI_SPEC §3.1b/§3.7 |
| The mockup's gauge placement (Ø112 @ (95, 86)) vs the pinned 120×120 dial (Deviation 3) | metric, owner-tickable | `CockpitStyle.gauge_size` |
| Racks 6/7 have no lamp (the band is five wide, the map reaches seven) | metric (Deviation 11) | `CockpitStyle.lamp_count` |
