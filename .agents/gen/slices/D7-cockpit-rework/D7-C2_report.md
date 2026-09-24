---
slice: D7
worker: D7-C2
model: "deepseek-v4-flash (crush run, per D7_prompts.md), Godot 4.7.2-stable headless"
files:
  - vajb-orbit/ui/station/armory_style.gd (new)
  - vajb-orbit/ui/station/armory_panel.gd
  - vajb-orbit/ui/station/armory_panel.tscn
  - vajb-orbit/tests/test_d7_armory.gd (new)
status: actionable
gate: "692 (C1's close) -> 700 (C3 landed mid-run, +8) -> 711/0 with this suite's 11, twice, identical, on scratch stores"
---

# D7-C2 report — ARMORY cockpit restyle (surface only)

## Result

The ARMORY pane is now mounted on the **painted console plate** `ui_armory_console` (a plain
`TextureRect`, no nine-slice, drawn at Mockup A's own canvas × section 10's `@2x` recipe =
**872 × 956**), its three groups inside **code-drawn recessed wells** at the pinned Mockup A rects
(UI_CHROME §12 Amendment 2: the plate is flat, the wells are code), each rack `B1..B7` on
`ui_armory_rack_plate` in the **4+3 bay grid** with the W cells as the machined slot recesses and the
**SALVO figure in three `ui_seg_*` cells**, INVENTORY/AMMUNITION rows on `ui_armory_row_plate`, the
selected bay wearing the section 3.2 **ember frame**. **Surface only**: every transaction, drag-drop
rule, refusal and the panel contract are byte-unchanged (asserted in the new suite), and every colour,
layout metric and asset path comes from **`ArmoryStyle`, a `CockpitStyle`** (UI_SPEC §3.9 rule 5).

`tests/test_d7_armory.gd` — **11 new rows, 11 pass**. **No other test file was touched**
(`git diff --name-only -- vajb-orbit/tests/` → this worker's own file only).

Live frame, the pane running as a standalone scene in the editor (three screenshots across the pass:
the plate + wells, the 4+3 bays with B1 framed in ember, the SALVO captions beside their cells, the
inventory rows and the six ammunition cards in 3 × 2).

## The measured geometry (nothing invented)

All numbers below are the **drawn** values (the style's logical pins × `art_scale` 2, section 10's
`@2x` recipe); the logical halves are the style's own exports and are what UI_SPEC §3.10 pins.

| element | drawn | logical | source |
|---|---|---|---|
| console block | 872 × 956, master 1744 × 1816 | 436 × 478 | Mockup A's canvas × `art_scale`; the master is the shipped file's own box |
| racks well | (30, 122) 812 × 390 | (15, 61) 406 × 195 | Mockup A (30,122)-(842,512) |
| inventory well | (30, 570) 812 × 170 | (15, 285) 406 × 85 | Mockup A (30,570)-(842,740) |
| ammunition well | (30, 796) 812 × 136 | (15, 398) 406 × 68 | Mockup A's 44 **+ 24** (see Deviation 3) |
| caption band | 30 | 15 | the mockup's 30 px gap above each well |
| rack bay | 194 × 182, 7 in a 4+3 grid at (44,136) + (col·202, row·190) | 97 × 91, gap 4 | §3.10's bay pin; the master's own box |
| W cell recess | 40 × 44 on a 44 pitch at (10,38) | 20 × 22 on 22 | §3.10 / Mockup A's `x+10+44s`, `y+38..y+82` |
| SALVO drum cell | 40 × 72 on a 42 pitch at (64,104), caption at (10,112) | 20 × 36 on 21 | Mockup A's `cx = x+64`, `y+104`, step 42 |
| inventory row | 812 × 44 | 22 tall, 20 × 18 icon slot | §3.10 |
| ammunition card | 265.33 × 64, three across | 32 tall | §3.10; 2 rows of 3 = the nine pinned |
| row plate nine-slice | margins 32/8/32/8 (texture px) | — | A0's own note for the 192 × 64 master |

**The pane's own rect was measured live** (the station shell's chain, 1920 × 1080): `ModuleHost`
1496 × 860 @ (400,162), `HostMargin` 1432 × 796, the **ARMORY pane 1392 × 756 @ (452,214)**,
`ArmoryScroll` 1392 × 673, `PaneHeader` 1392 × 41, `PaneFooter` 1392 × 18, an ammunition row's own
minimum 1380 × 76 (the S5 `ROW_HEIGHT`). A0's `measure_armory.gd` measured the pane's *minimums* at
its own host (pane min 878 × 95, body 703 × 874) and pinned the 872 × 908 content frame from Mockup
A's canvas; this pass keeps that frame and reports the shell's real one (Deviation 4).

## What shipped, file by file

### `ui/station/armory_style.gd` (**new**, `class_name ArmoryStyle extends "res://ui/hud/cockpit_style.gd"`)

The armory's one style surface: section 3.9 rule 5, on top of the family's own Resource. It **extends
`CockpitStyle`** (so the palette, `ui_seg_*` asset idiom, `colour()`/`seg_path()`/`texture()` lookups
are the cluster's own - one colour store, no second palette) and adds `@export_group("armory layout")`
(art_scale, canvas, three wells, caption band, bay size/gap/origin/columns, slot count/size/pitch/
origin, ledge, SALVO caption/cells/size/pitch/original/caption-font, the two row heights, row gap,
row-plate margins, the danger and selected frame widths) and `@export_group("armory assets")`
(`console_path`, `rack_plate_path`, `row_plate_path`). **Zero hex literals** live here (the palette is
inherited). Derived readers: `block_size`, `pinned_wells`, `group_rect`, `drawn_well`, `growth`,
`bay_rect`, `bay_row_count`, `bay_grid_height`, `slot_rect`, `salvo_cell_rect`, `salvo_width`,
`rows_height`, `drawn`, `drawn_vector`, `drawn_rect`, `row_plate_sides`. `ARMORY_USER_PATH` is the
override file (`res://ui/station/armory_style_user.tres`); a user `.tres` restyles **and** relayouts
the pane with no code edit (asserted).

### `ui/station/armory_panel.gd` (rewritten surface, same contract)

- **Mount**: the pane root is a plain `Control` (was `VBoxContainer`); `PaneHeader` (title/subtitle/
  tag), `ArmoryScroll` and `PaneFooter` stay the pane's own strips. Inside the scroll: `ArmoryBody`
  (the console block, `custom_minimum_size` = the style's `block_size`) carrying the plate, a
  code-built `ConsoleWells` control and the three group boxes.
- **`ConsoleWells`**: the three recesses (fill `void_base`, dark top/left and lit bottom/right bevels
  in the style's tokens) plus one bay card per rack - the whole well/bay chrome is code (§3.9 rule 4).
- **Bays**: `RackRow` (a `PanelContainer`, the existing suites' contract) with `Box` →
  `BayPlate` (the rack plate at the master's own 194 × 182), `BayMarks` (the fitted cells' block and
  the selected bay's ember frame), `Head` (`B<n>`, the key hint, the S5 state line, the drop cue),
  `Barrels` (the S5 chips) and `Salvo` (the ledge, the three drum cells and the `SALVO s` caption).
- **SALVO figure**: the rack's own `_rack_cycle` (the slowest member, unchanged) in **hundredths of a
  second**, three cells, zero-padded - `060` for the cannon's 0.6 s, `120` for the rocket's 1.2 s,
  blanks for a rack with no travelling member. The S5 `State` label keeps its text
  (`SALVO 0.6 s` / `READY`) and its visibility for `rack_rows()`/the old suites; its ink is
  transparent so the bay shows one cadence (Deviation 6).
- **Inventory rows**: 44 drawn (22 logical) on the row plate, the `OWNED ×n` cell kept; **ammunition
  cards**: 265.33 × 64, three across × two rows on the row plate, the S5 cell anatomy (Icon, Title,
  Meta, Held + Caption, Price + Caption, Status) intact but laid out as the mockup's compact card.
- **Danger rows**: the section 3.1/3.1b treatment verbatim - a code-drawn 1 px frame on the card and
  the state label in `accent_danger`; the held/price/status *digits never recolour* (asserted).
- **Selected bay**: `selected_rack()` / `set_selected_rack()`, following focus on a rack's chips
  (default B1 - the standard fit's delivered laser); nothing is written.
- **Kept byte-identical**: `status_requested`, `refresh_profile`, `focus_primary`, every `rack_rows()`
  / `inventory_rows()` / `inventory_view_rows()` read-back, `drag_inventory` / `drag_barrel` /
  `can_drop` / `drop`, `install_weapon` / `move_barrel` / `remove_barrel`, every refusal wording and
  constant, `_seed_fit`/`_unseed_fit`, the composed `PlayerProfile` writes only.

### `ui/station/armory_panel.tscn` (rebuilt around the console)

`Armory (Control)` → `PaneHeader` (icon/title/subtitle/tag) · `ArmoryScroll` → `ArmoryBody` →
`ConsolePlate` (the console master) + `RacksMargin` → `RacksBox` → `RacksCaption` (`BATTERY RACKS`) +
`RackRows`, `InventoryMargin` → `InventoryBox` → `InventoryCaption` + `InventoryRows`, `AmmoMargin` →
`AmmoBox` → `AmmoCaption` + `ArmoryHeader` + `ArmoryRows` · `PaneFooter`. **The pinned path
`ArmoryScroll/ArmoryBody/RacksMargin/RacksBox/RacksCaption` and every unique name the S5/P2-B1 suites
read survive** (`%ArmoryRows`, `%RackRows`, `%InventoryRows`, `%PanelTag`, `%PaneFooter`,
`%PaneSubtitle`, `%ArmoryHeader`, `%ArmoryScroll`); the scene still names no MODULES/ModuleRows.

## Tests touched (every row, and why)

**`tests/test_d7_armory.gd` — new, 11 rows in seven groups**, all green:

| group | rows |
|---|---|
| the console | `test_the_pane_mounts_on_the_painted_console_plate` |
| the wells | `test_the_three_wells_mount_at_the_mockup_rects` |
| the bay grid | `test_the_racks_draw_the_4_3_bay_grid_on_the_rack_plate` |
| the W cells | `test_the_w_cells_are_the_machined_slot_recesses` |
| the SALVO strip | `test_the_salvo_strip_renders_the_cycle_figure` |
| the row plates | `test_the_rows_ride_the_row_plate_at_the_pinned_heights` |
| danger rows | `test_danger_rows_follow_section_3_1_and_3_1b` |
| surface only | `test_a_refused_drop_writes_nothing`, `test_the_drag_ordering_and_the_close_are_unchanged` |
| the style | `test_a_user_tres_restyles_and_relayouts_with_no_code_edit`, `test_the_style_extends_cockpit_style_with_the_pinned_metrics` |

**No other test file moved** (`test_engine2_hud.gd`, `test_d6_cluster.gd`, `test_d6_status.gd`,
`test_p2b1_outfitting_panel.gd`, `test_s4_batteries.gd`, `test_s5_batteries_v2.gd`,
`test_s5_ammo_cargo.gd`, `test_d7_cockpit.gd`, `test_d7_status.gd` — all byte-green, re-measured).

## Deviations from the brief / docs (bucket-tagged, each reversible)

1. **(bucket 2) The armory's style extension lives in `ui/station/armory_style.gd`, not as fields in
   `ui/hud/cockpit_style.gd`.** Measured cause: this worker's `VAJB_WORKER_FILES` is
   `vajb-orbit/ui/station/,vajb-orbit/tests/` and the enforcement hook *denies* `ui/hud/` with
   `"outside this worker's declared file set. Allowed: vajb-orbit/ui/station/,vajb-orbit/tests/.
   Report deviations in your report file instead of editing."` The armory's style is therefore a
   **subclass of the family's one `CockpitStyle`** (same palette, same `ui_seg_*` parts, same
   `texture()`/`colour()` helpers - asserted by
   `test_the_style_extends_cockpit_style_with_the_pinned_metrics`), with the armory's own layout and
   asset paths in its own file. Reversal: move the two `@export_group("armory …")` blocks into
   `cockpit_style.gd` and delete the subclass + the `.uid`. **Needs the developer/designer's word**
   (a `VAJB_WORKER_FILES` set).
2. **(bucket 2) The SALVO figure is seconds × 100, not the brief's "seconds ×10".** The approved
   literal is Mockup A's own `073` for 0.73 s (owner "Looks good", 2026-09-24), and 0.73 × 10 = 7.3 is
   not a drum figure; × 100 gives 73 → `073` exactly. Measured, no fallback was needed: the cannon's
   0.6 s → `060`, the rocket's 1.2 s → `120`, a laser rack (no travelling member) → blanks, and the
   format holds any real cadence up to 9.99 s in three cells. Reversal: the plain `Label` the pane
   shows today (the S5 `State` line, which still answers through `rack_rows()`).
3. **(bucket 2) The ammunition well is 68 logical (drawn 136), not Mockup A's 44.** The pane ships
   **six** packs where the mockup drew three, and Mockup A's own three-boxes-across arrangement needs
   two rows: 2 × 32 + the 4 px gap = 68 exactly. The block is therefore 872 × **956** drawn against
   the shipped master's 1744 × **1816** - a 1.0 × 1.053 fill, i.e. a 5 % vertical scale, no crop, no
   nine-slice. Reversal: the 44 well with a clipping set, or a 908 block with 22-logical pack rows.
4. **(bucket 1/2) The console is a fixed block (Mockup A's canvas × `art_scale`) left-aligned in the
   pane's scroll, not stretched to the pane's own measured rect.** Measured: the shipping pane is
   **1392 × 756** (landscape, aspect 1.84) against the mockup's 0.96 - drawing the 1744 × 1816 master
   into it would scale 1.0 × 0.42, which is the D3 stretched-plate defect class §3.7/§3.10 forbid.
   The pane's extra width shows the host's own `PanelRaised` chrome, the way every other station pane
   leaves slack. Reversal: `ArmoryStyle.canvas` (and a wider plate master).
5. **(bucket 1) The group boxes and the bay head/chips are `VBoxContainer`s/`HBoxContainer`s whose own
   row layout is corrected after each sort** (`Container.sort_children` → `_position_group`,
   `_lay_bays`, `_lay_ammo`, `_position_head`, `_position_slots`). Cause: the existing S5/P2-B1 suites
   cast `%RackRows`/`%ArmoryRows`/`%InventoryRows` to `VBoxContainer` and read the bays' `Box/Head/...`
   and `Box/Barrels` by path, so custom containers were not available; a VBox's own minimum is the sum
   of its children's, which measured **1274 px** for the seven bays and grew the whole console. The
   bays/cards therefore declare `custom_minimum_size = (1,1)` and their drawn rect is set outright.
   Reversal: purpose-built container classes (breaks those casts).
6. **(bucket 1) The S5 state line's ink is transparent while its node keeps the text and stays
   visible.** `test_p2b1_outfitting_panel.gd` reads `Box/Head/State`'s text (`SALVO 0.6 s`) and
   asserts it is visible, and §3.10's approved strip is the visible readout; both hold, the bay shows
   one cadence. Reversal: restore the ink and drop the strip's `SALVO s` caption.
7. **(bucket 1) The barrel chips' names are transparent ink inside their slot; the fitted cell is a
   code-drawn block (`BayMarks`) in the machined recess.** Mockup A draws a block per fitted cell and
   no name; the chip keeps its pinned text (the suites read it), its drag payload, its focus and its
   `✕` (a 14 px corner button), and its name is also its tooltip. Reversal: drop the colour override
   and the marks.
8. **(bucket 2) The shipped `ui_armory_rack_plate`'s decorative slots do not align with the pinned W
   cells** (A0's own Deviation 9, re-measured on the shipped master here): the four recesses are
   ~10 px wide on a ~34 px pitch at x 41..152, y 68..130, while §3.10 pins the cells at 40 × 44 drawn
   on a 44 px pitch at the bay's (10, 38). **The pin wins** (the cells are geometry - drop targets,
   chip seats, marks - and the art's recesses are decoration). Reversal: a re-render of the rack plate
   to the pin (A0b/F1's call; A0 reported it and the wave shipped the plate).
9. **(bucket 1) The drop cue is one clipped 9 px line over the empty slots.** Measured: an autowrap
   `Label`'s minimum size is its height at one character per line - 669 px here, which pushed the bay
   to 673 and the whole console with it. The cue's text stays `RACK_INSTALL_CUE` (pinned by P2-B1);
   only its presentation is capped. Reversal: shorten the constant or re-render a bay with room.
10. **(bucket 3 — owner tick) The bay's key hint `(1)..(7)` is drawn from the rack's ordinal**, per
    Mockup A's own legend; the input map's `weapon_1..7` order is what `RACK_COUNT`/`_build_rack`
    already follow, so the two cannot drift - but a rebind that reorders the actions would make the
    hint a lie. Reported for the owner; reversal: drop the hint.

## Evidence

Gate (twice, identical counts, scratch stores; the only `SCRIPT ERROR` is the pre-existing benign one
in `test_weapon_fx_f4.gd:178`, present on the 692 baseline too):

```
XDG_DATA_HOME=/tmp/d7c2_final1 $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
        res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=711 failed=0
XDG_DATA_HOME=/tmp/d7c2_final2 ... (same command, fresh store)
[SUMMARY] passed=711 failed=0
```

The focused runs: `-- --suite=test_d7_armory` → `passed=11 failed=0`; the four suites this pane's
surface could touch (`test_p2b1_outfitting_panel`, `test_s4_batteries`, `test_s5_batteries_v2`,
`test_s5_ammo_cargo`) → `passed=59 failed=0`.

The live store: **every gate run is scratch-redirected and left it alone** - after both final runs
`profile.cfg` still read md5 `027e6eb178fca5d6b46cff535465d7be` and `economy_log.txt`
`ca40fe2c0ab3bd0f2047723a2d737d9a`, both identical to C1's pre-work record. **One exception, measured
and reported**: the editor-driven **station-shell** integration run (the last screenshot) uses the live
`user://` (an editor-launched game cannot be XDG-redirected), and Godot's debounced `SaveDebounce`
flush rewrote `profile.cfg` at **11:49** (`027e6eb…` -> `174804b151037044cc152c86a626ec98`, 5947 ->
6055 bytes). It is a re-serialisation of the loaded account, not a reset: the file still carries the
owner's own progress (`credits=4625`, three owned ships, the mineral/ammo cargo, `save_version=7`),
`economy_log.txt` is **byte-identical** (no transaction ran), no pane input was driven, and the MCP game
runs used `autosave=false` (no scene was written). **The pre-11:49 bytes are not recoverable**; the
reversal is an owner-driven play session, and the only other copy on disk is
`profile.cfg.bak-20260923-163525` (yesterday, save_version 6 - older, not a restore target). Flagged
for the orchestrator's close-out check.

Live geometry, read out of the running pane (`game_eval`, standalone run at 1920 × 1080):

```
pane                 (1920.0, 1080.0) @(0.0, 0.0)      # the standalone host
ArmoryScroll         (1920.0, 1004.0) @(0.0, 47.0)
ArmoryScroll/ArmoryBody      (872.0, 956.0) @(1.0, 48.0)
.../RacksMargin              (812.0, 420.0) @(31.0, 140.0)
.../RacksMargin/RacksBox     (812.0, 420.0) @(31.0, 140.0)
%RackRows            (800.0, 372.0) @(31.0, 163.0)     # = block (44, 136)
bay0                 (194.0, 182.0) @(31.0, 163.0)
bay1                 (194.0, 182.0) @(233.0, 163.0)   # + 202
bay3                 (194.0, 182.0) @(637.0, 163.0)
bay4                 (194.0, 182.0) @(31.0, 353.0)    # + 190
bay6                 (194.0, 182.0) @(435.0, 353.0)
%ArmoryRows          (812.0, 208.0) @(31.0, 804.5)
AmmoMargin           (812.0, 166.0) @(31.0, 814.0)
```

The rack plate's decorative slots, re-measured with Pillow on the shipped master (194 × 182): four
dark runs on a ~34 px pitch, `x 41..50 / 74..84 / 109..119 / 143..152`, `y 68..130` - the misalignment
Deviation 8 records.

Screenshots (editor `game` source): the pane as a custom run - the plate with its three recesses and
the 4+3 bays, B1's ember frame, the `SALVO s` captions beside their three cells, the inventory rows
and the six ammunition cards (3 × 2) on their row plates - and the **real shell**
(`res://ui/screens/station.tscn`, ARMORY selected), where the whole pane, the rail, the header and the
footer read together and the console's fixed 872 px block leaves the host's own `PanelRaised` chrome to
its right (Deviation 4). All frames are recorded in the session log; the pane was left stopped and no
scene was saved by the MCP calls (`autosave=false`).

## Files touched

- `vajb-orbit/ui/station/armory_style.gd` (**new**, 226 lines) + `.uid` — the armory's `CockpitStyle`
- `vajb-orbit/ui/station/armory_panel.gd` (2275 lines) — the console/well/bay/card surface; every
  transaction and read-back unchanged
- `vajb-orbit/ui/station/armory_panel.tscn` (180 lines) — the console's node tree, pinned paths kept
- `vajb-orbit/tests/test_d7_armory.gd` (**new**, 792 lines, 11 rows) + `.uid`

No `docs/`, `game/`, `autoload/`, `project.godot`, `ui/theme/`, `addons/`, `ui/hud/` or `assets/`
byte was written by this worker. (The working tree also carries C1's `ui/hud/*` + `test_d6_cluster.gd`,
C3's `ui/hud/ship_status_screen.gd` + `test_d7_status.gd`, the art lane's `.import` sidecars and
`assets/ui/generation_log_d7.md`, and another lane's `docs/CONTRACTS.md` / `docs/gameplay/09|15` /
`staging/**` deltas — none of them this worker's.)

## Follow-ups

| Item | Kind | Where |
|---|---|---|
| The armory's style fields belong in `ui/hud/cockpit_style.gd` (file-set denial) | bucket 2, needs the developer | `VAJB_WORKER_FILES`, Deviation 1 |
| The rack plate's slots are ~34 px off the pinned W cells | art (A0's Deviation 9, bucket 2) | `assets/ui/ui_armory_rack_plate.png` |
| `SALVO s`'s approved figure is ×100, not the brief's ×10 | docs wording | D7 brief / UI_SPEC §3.10 |
| The key hint `(1)..(7)` trusts the input map's order | owner tick | Deviation 10 |
| The ammunition well's 44 -> 68 growth (six packs) | docs wording | UI_SPEC §3.10 / UI_CHROME §12 |
| A0b's ship/import pass still owns the six D7 art files | art lane | `staging/phase_g/ship_d7.py` |
| The live `profile.cfg` was rewritten by the editor-driven station run (a debounced flush of the loaded account, no transaction) | close-out check | Evidence above; pre-11:49 bytes unrecoverable |
