# P2-A — W5 report: the layout consumers (shipyard grid, launch rows, HUD cells)

**Worker:** W5 (coder, the layout consumers). **Wave:** P2-A ship slot frames.
**Brief (law):** `.agents/gen/p2a_slot_frames_wave_task.md` §3 (the pin) + §4 row W5 + §5 + §6.
**File set (`VAJB_WORKER_FILES`):** `vajb-orbit/ui/station/shipyard_panel.gd`,
`vajb-orbit/ui/station/shipyard_panel.tscn`, `vajb-orbit/ui/station/launch_panel.gd`,
`vajb-orbit/ui/components/slot_button.gd`, `vajb-orbit/ui/hud/hud.gd`,
`vajb-orbit/tests/test_ui_slot_layout.gd`. Five shipped files touched (four scripts, one
scene) and one suite rewritten; **no** `assets/**`, no theme, no `project.godot`, no
`addons/**`, no `docs/**`, no `hud.tscn`.
**Status:** complete. The suite is 12/12 green, the full gate measured **358 passed / 0
failed** with every file of this pass on disk, and every item of §3's W5 row plus the
task's own text is implemented.

**One deviation, mechanical, same as D0's and W3's:** the `edit`/`write` tools were refused
twice for an **absolute** path (`.agents/gen/p2a_w5_report.md`) — the PreToolUse hook denies
absolute paths on this host (brief §6), and it also reports "outside this worker's declared
file set" for a path inside it when the path is absolute. Every code edit was re-issued
workspace-relative and landed; this report was written with a shell heredoc, exactly as D0
did, because a report path is outside `VAJB_WORKER_FILES` by design.

**One read-time note, not a defect:** the brief and the fenced prompt both name
`.agents/gen/p2a_w4_report.md` as required reading. **It did not exist** when this pass
started (W4 was still running). W4's *code* landed mid-pass — `game.gd`'s
`_push_hull_slots()`/`_hull_slot_cells()`, `player_state.gd`'s `weapons`/`set_weapons` and
`player_ship.gd`'s anchors are on disk and were read — and it is **payload-compatible** with
this HUD to the key: `{slot, index, module, icon, fitted, selectable}`, one entry per W cell
of `ShipFit.grid_cells`, `icon` from `ModuleCatalog.icon_path`, `selectable` from
`WeaponsScript.GROUPS_MAX` (`game.gd:1388-1406`). R1 should re-check that pairing against the
W4 report once it lands.

---

## 1. Files changed

| File | Change | Δ |
|---|---|---|
| `ui/station/shipyard_panel.gd` | `%HardpointSlots` becomes a `GridContainer` rebuilt per selection from `ShipFit.grid_cells`; gap cells, slot-glyph plates, the new caption, the `hull/shield/cargo/engines/slots` rows, the `"%d HULL · %d SLOTS"` meta | +144 / −30 |
| `ui/station/shipyard_panel.tscn` | `HardpointSlots` `HBoxContainer` → `GridContainer`, `separation` → `h_separation`/`v_separation` 4 | +3 / −2 |
| `ui/station/launch_panel.gd` | `ENGINES` + `SLOT CELLS` brief rows (nine rows, the pin's order), `_slot_cell_count` | +20 / −3 |
| `ui/components/slot_button.gd` | `configure_cell()` added; `configure()` untouched | +18 / −0 |
| `ui/hud/hud.gd` | `set_hull_slots()`, `hull_slots()`, `_rebuild_weapon_slots()`, the cell-icon/selectability helpers, `GROUPS_MAX` + the weapon slot glyph | +72 / −0 |
| `tests/test_ui_slot_layout.gd` | the three pinned sections rewritten to `ShipFit`; five tests added | +457 / −38 |

`git diff --numstat` over the six: **+714 / −73** across the four scripts, the one scene and
the one suite. (A `git diff --stat` over `vajb-orbit/ui vajb-orbit/tests` also lists
`tests/test_engine2_wiring.gd` and `tests/test_p1_profile.gd` — W1/W2/W4's, not this
worker's.)

## 2. What shipped, mapped to the pin (CONTRACTS §11 · `docs/CONTRACTS.md:1003-1018`)

### SHIPYARD (`ui/station/shipyard_panel.gd`)

| Pin | Implementation |
|---|---|
| `%HardpointSlots` is a `GridContainer` | the scene node type changed; `@onready var _hardpoints: GridContainer` (`:116`); `h_separation`/`v_separation` = `PLATE_SEPARATION` 4, set once in `_build_layout_grid()` |
| `columns` = `ShipFit.grid_size(hull).x` | `_set_layout_grid()` `:364`; 4 for eight hulls, 5 for the Destroyer (measured in §4) |
| rebuilt per selection from `ShipFit.grid_cells(hull)` | `_refresh_preview()` → `_set_layout_grid(_selected_id)` `:532`; `_refresh_all()` runs it on `refresh_profile` too, so a hull switch on the list or an active-ship change rebuilds it |
| one cell per matrix cell, gaps included | the loop walks `grid_cells` in row-major order and adds exactly one child per entry (`:366-371`); `grid.get_child_count() == grid_cells(hull).size()` is asserted for all nine hulls |
| a gap is an empty 48×48 `Control` with no plate | `_make_gap_cell()` `:376`, `custom_minimum_size = Vector2(48, 48)`, `MOUSE_FILTER_IGNORE`, no plate |
| a slot cell is a 48 px disabled plate carrying its type's glyph | `_make_slot_cell()` `:386`: `_make_plate(..., SlotButtonWeapon, 48)`, `disabled = true`, an `Icon` `TextureRect` inset 6 px (`PLATE_ICON_INSET`, the same inset `slot_button.tscn` uses) carrying `assets/icons/slot/icon_slot_<stem>_48.png` via `SLOT_GLYPHS` (`:53`), modulated `text_dim` |
| caption `SLOT LAYOUT · %d CELLS · %d ENGINES` (`_hardpoint_caption`) | `HARDPOINT_CAPTION` `:88`; the var keeps its name; `CELLS` is the non-gap cell count counted in the build loop, `ENGINES` is `grid_counts(hull)[&"engines"]` — one hull, one read (`:372-373`) |
| `STAT_ROWS` = `hull, shield, cargo, engines, slots`, labels `HULL`/`SHIELD`/`CARGO`/`ENGINES`/`SLOT CELLS` | `:72-78`; `_stat_value()` `:430` reads the catalogue for the first three and `ShipFit` for `engines`/`slots`, for the selected **and** the active hull |
| list meta `"%d HULL · %d SLOTS"` | `META_FORMAT` `:85`, `_build_row()` `:194` with `_slot_cell_count(ship_id)` |
| no matrix → no cells, caption empty, never a stale hull | the empty branch clears the cell list, sets `columns = 1` and empties the caption before returning (`:360-363`) |

### LAUNCH (`ui/station/launch_panel.gd`)

`BRIEF_ROWS` is the pin's nine rows in the pin's order
(`destination, hull_name, hull, shield, engines, hardpoints, slots, cargo, ammo`) with the
labels `DESTINATION, ACTIVE HULL, HULL LIMIT, SHIELD LIMIT, ENGINES, HARDPOINTS, SLOT
CELLS, CARGO, AMMUNITION` (`:70-79`). `_refresh_brief()` fills `engines` from
`ShipFit.grid_counts(active_id)` and `slots` from `_slot_cell_count(active_id)`; `hull`,
`shield`, `hardpoints` and `cargo` keep reading the catalogue row, and the ammo line is
untouched. **The cargo plate strip and its five plates are byte-identical** to the pre-wave
code (5 × 40 px, separation 6, icons unchanged) — the test still measures them.

### COMPONENT (`ui/components/slot_button.gd`)

```gdscript
func configure_cell(
	variation: StringName, icon: Texture2D, cell: Vector2, icon_token: StringName = TOKEN_INACTIVE
) -> void
```
Sets `theme_type_variation`, `ignore_texture_size = true`, `custom_minimum_size = cell`
(the caller's number, not the variation's), the icon and its token, `_number_text = ""`, then
`_apply_plates`/`_push_icon`/`_push_number`. `configure()`'s signature and body are
untouched (the diff adds 18 lines and deletes none); both are asserted in the suite,
including that a layout cell carries no number and that a 4096 px plate cannot grow an
explicitly-stated cell.

### HUD (`ui/hud/hud.gd`)

```gdscript
func set_hull_slots(hull_id: StringName, cells: Array) -> void
func hull_slots() -> Array
```
`set_hull_slots` records the hull id and a copy of the cells, then `_rebuild_weapon_slots()`:
it removes and frees the previous cells (an immediate `remove_child` so the grid's own
layout is correct the same frame, then `queue_free`, the shipped `_ensure_cargo_cells`
idiom), sets `columns = maxi(mini(count, GROUPS_MAX), 1)` — the pin's
`mini(cells.size(), 5)`, with the `maxi` only guarding the one value a `GridContainer`
refuses (0, an empty push) — then builds one `SlotButton` per cell with `configure_cell`,
`disabled = not _weapon_cell_selectable(index, cell)` and the existing
`_on_weapon_slot_pressed` binding, and re-runs `_refresh_weapon()`.

* `GROUPS_MAX` is **not** a literal: `const GROUPS_MAX: int = WeaponComponent.GROUPS_MAX`
  (`game/weapons.gd:134`, the same 5 the input map's `weapon_1..5` binds), so the HUD and the
  weapon component cannot drift.
* A cell whose `module` is empty draws `SLOT_GLYPH_WEAPON` =
  `res://assets/icons/slot/icon_slot_w_48.png` dimmed (`TOKEN_TEXT_DIM`); a fitted cell draws
  the path it was handed (`cell.icon`), falling back to the slot glyph if that path is empty
  or does not resolve.
* `selectable` is enforced here, not only trusted: `index < GROUPS_MAX and cell.selectable`
  (`_weapon_cell_selectable`), so a 7-W capital's cells 5–6 are drawn but disabled whatever a
  producer sends.
* `_build_weapon_slots()` is untouched: a HUD with nothing pushed still draws the default
  five-family grid, so no existing consumer loses its row.
* `bind`, `_on_weapon_changed`, `_pull_state`, `_on_weapon_slot_pressed` and the ammo label
  path are **unchanged**, as the pin requires. `hud.tscn` is byte-identical (it was not in
  the file set); `columns` is set in code.

## 3. The pinned signature check (grep-able)

```
ui/hud/hud.gd:634            func set_hull_slots(hull_id: StringName, cells: Array) -> void
ui/hud/hud.gd:642            func hull_slots() -> Array
ui/components/slot_button.gd:75  func configure_cell(
ui/station/shipyard_panel.gd:355 func _set_layout_grid(hull_id: StringName) -> void
ui/station/shipyard_panel.gd:88  const HARDPOINT_CAPTION := "SLOT LAYOUT · %d CELLS · %d ENGINES"
ui/station/shipyard_panel.gd:85  const META_FORMAT := "%d HULL · %d SLOTS"
```

## 4. Measured per hull — grid size, columns, cells, plates (the suite's own output)

Every row is measured by `test_the_layout_grid_builds_every_hulls_matrix`, which drives the
**panel's own** `_set_layout_grid()` through all nine `ShipFit.SLOT_GRIDS` keys and reads the
shipped scene back (child count, `columns`, each child's `custom_minimum_size`, the grid's
`get_combined_minimum_size().x` and the caption):

| hull_id | matrix (cols × rows) | `columns` | matrix cells | plates (slot cells) | gaps | grid width | 08 §3 Total |
|---|---|:-:|---:|---:|---:|---:|:-:|
| `ship_fighter` | 4 × 3 | 4 | 12 | 8 | 4 | 204 | 8 |
| `ship_vanguard` | 4 × 4 | 4 | 16 | 11 | 5 | 204 | 11 |
| `ship_miner` | 4 × 4 | 4 | 16 | 12 | 4 | 204 | 12 |
| `ship_trader` | 4 × 4 | 4 | 16 | 13 | 3 | 204 | 13 |
| `ship_corvette` | 4 × 4 | 4 | 16 | 13 | 3 | 204 | 13 |
| `ship_freighter` | 4 × 5 | 4 | 20 | 15 | 5 | 204 | 15 |
| `ship_gunship` | 4 × 5 | 4 | 20 | 14 | 6 | 204 | 14 |
| `ship_patrol` | 4 × 5 | 4 | 20 | 17 | 3 | 204 | 17 |
| `ship_destroyer` | 5 × 6 | 5 | 30 | 23 | 7 | 256 | 23 |

The **plates** column is 08 §3's Total column cell for cell (8/11/12/13/13/15/14/17/23) and
every row's `gap` count is `cells − plates`, so a gap is provably not counted as a slot. Grid
width is `cols × 48 + (cols − 1) × 4` (204 for four columns, 256 for the capital's five).

HUD cells per hull, from `test_the_hud_grid_wraps_and_marks_cells_past_the_group_count` and
`test_the_hud_slot_cells_keep_their_cell_sizes` (both derive the count from `ShipFit`, then
push it):

| hull | W cells pushed = drawn | HUD `columns` | not selectable |
|---|:-:|:-:|:-:|
| `ship_destroyer` | 7 | 5 | 2 (indices 5, 6) |
| the active hull of the run (`ship_fighter` at the time of the raw log) | 2 | 2 | 0 |

## 5. Panel minima, before and after

Measured with `get_combined_minimum_size()` on the shipped scenes under the shipped theme,
which is the quantity the station shell sizes a panel from and the quantity the D3 playtest's
overflow was.

| Panel | Before this wave | After this pass | Viewport | Verdict |
|---|---|---|---|---|
| SHIPYARD (`ship_fighter` selected; 4-column grid) | 1308 × 1788 (`weapon_fx_f4_gate_after.txt:254`, 7-plate strip 360 wide) | **1278 × 1372** | 1920 × 1080 | narrower: the 4-column grid (204) is inside the 300 px stat column, where the 360 px strip no longer forced it |
| SHIPYARD after the widest grid built (Destroyer, 5 columns, 256) | — | **1278 × 1372** (unchanged) | 1920 × 1080 | the capital's grid still fits the stat column |
| SHIPYARD with a 4096 px plate pushed onto every cell | 1308 × 1788 | **1278 × 1372** (identical to before the art swap) | 1920 × 1080 | guard holds |
| LAUNCH | 952 × 1985 (`weapon_fx_f4_gate_after.txt:256`) | **952 × 2045** | 1920 × 1080 | width unchanged; height +60 px = the two new brief rows (~30 px each). The launch panel's minimum height was **already** 1985 > 1080 before this wave (the panel has no `ScrollContainer`; the shell clips/scrolls it), so this is a pre-existing property of the screen, not a new one — recorded, not "fixed", because the launcher layout is not this wave's |
| LAUNCH with a 4096 px plate pushed onto every cargo plate | 952 × 1985 | **952 × 2045** (identical to before the art swap) | 1920 × 1080 | guard holds |

The launch button's own minimum is 71 × 88 (was 71 × 88) and the cargo strip is 224 × 40 in
both runs, so the D3 symptom (ship list at x = −2393, LaunchButton at x = 3178) cannot
recur: the widths are inside the frame and a 4096 px plate moves neither.

## 6. The suite — the three pinned sections, the guards, and what was added

`tests/test_ui_slot_layout.gd` went from 7 tests to **12**. The three pinned sections:

1. **The strip** (`test_the_hardpoint_grid_is_the_selected_hulls_matrix`, was
   `test_the_hardpoint_strip_is_seven_48px_cells`) — the hull comes from the panel's own
   `_selected_id`, the cell count and `columns` come from `ShipFit.grid_cells`/`grid_size`,
   and the sweep asserts one child per matrix cell, a gap as a bare `Control` (not a
   `TextureButton`) still reserving 48 px, every plate a disabled `TextureButton` with
   `ignore_texture_size`, `custom_minimum_size` and `get_combined_minimum_size()` of exactly
   48 px, `gaps == cells − plates`, `plates == ShipFit.grid_counts`' total, and the grid's
   width `cols × 48 + (cols − 1) × 4`. The literal 7 is gone from the file.
2. **The panel minima** — the shipyard and launch minima are asserted against the live
   viewport read from `ProjectSettings` (unchanged rule), and the shipyard's grid width is now
   derived from the selected hull's matrix; the launch panel's cargo strip is still measured
   as five 40 px cells with its 6 px separation and the LAUNCH button is still asserted inside
   the frame.
3. **The HUD cell count** (`test_the_hud_slot_cells_keep_their_cell_sizes`) — the count is
   `ShipFit.grid_counts(active_hull)[&"weapons"]`, the cells pushed by the test are built from
   `ShipFit.grid_cells` + `ModuleCatalog.icon_path`, and the assertions read the HUD back
   (`_weapon_slots.size() == count`, `_weapon_grid.columns == mini(count, GROUPS_MAX)`,
   `hull_slots().size() == pushed.size()`). The literal 5 is gone; `GROUPS_MAX` is read from
   `weapons.gd`.

Every D3 guard property is intact and now swept over more sites:

* `ignore_texture_size = true` at every plate site — the file-literal test is unchanged, and
  every plate the suite walks (shipyard grid, shipyard gaps' neighbours, both panels, the HUD
  weapon row and cargo grid, the component under `configure` and `configure_cell`) is asserted
  node by node.
* the 48 px weapon / 40 px cargo cells — asserted at every one of those sites.
* **a 4096 px plate cannot grow a panel or the grid** — four measurements: the shipyard grid +
  panel, the launch cargo strip + panel, the HUD weapon cell, and an explicit `configure_cell`
  cell.

Added tests (5): `test_the_shipyard_layout_glyphs_are_the_slot_types` (each plate's `Icon`
texture resource path equals 09 §1's `icon_slot_<stem>_48.png` for **its own** matrix type,
with the file's existence on disk), `test_the_layout_grid_builds_every_hulls_matrix` (the §4
table), `test_the_shipyard_caption_and_stat_rows_read_the_selected_hull` (the caption string,
the five row names/labels and both value columns against `ShipFit`/the catalogue, and the
`"%d HULL · %d SLOTS"` meta of all nine list rows), `test_the_launch_brief_rows_are_the_nine_pinned_rows`
(the nine names, labels, and the `ENGINES`/`SLOT CELLS`/`HARDPOINTS` values against
`ShipFit`/the catalogue), `test_the_hud_grid_wraps_and_marks_cells_past_the_group_count` (the
7-cell capital wraps at `GROUPS_MAX`, cells 5–6 disabled, each cell's icon path).

Raw output of the rewritten suite:

```text
$ godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200 -- --suite=test_ui_slot_layout
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
[RUN] suites=test_ui_slot_layout
[PASS] test_ui_slot_layout.gd.test_every_plate_site_sets_ignore_texture_size
[ui_slot_layout] launch with (4096.0, 4096.0) art: strip (224.0, 40.0), panel (952.0, 2045.0) (before (952.0, 2045.0))
[PASS] test_ui_slot_layout.gd.test_oversized_plate_art_cannot_grow_the_launch_panel
[ui_slot_layout] shipyard ship_fighter with (4096.0, 4096.0) art: grid (204.0, 152.0), panel (1278.0, 1372.0) (before (1278.0, 1372.0))
[PASS] test_ui_slot_layout.gd.test_oversized_plate_art_cannot_grow_the_shipyard_panel
[ui_slot_layout] launch: strip (224.0, 40.0) (art (40.0, 40.0)), panel minimum (952.0, 2045.0), LaunchButton minimum (71.0, 88.0), viewport (1920.0, 1080.0)
[PASS] test_ui_slot_layout.gd.test_the_cargo_strip_is_five_40px_cells
[ui_slot_layout] shipyard ship_fighter: grid (204.0, 152.0) (12 matrix cells, 8 plates, 4 cols), panel minimum (1278.0, 1372.0), viewport (1920.0, 1080.0)
[PASS] test_ui_slot_layout.gd.test_the_hardpoint_grid_is_the_selected_hulls_matrix
[ui_slot_layout] hud ship_destroyer: 7 cells, columns 5, 2 not selectable
[PASS] test_ui_slot_layout.gd.test_the_hud_grid_wraps_and_marks_cells_past_the_group_count
[ui_slot_layout] hud ship_fighter: 2 x (48.0, 48.0) (art (48.0, 48.0)), columns 2, and 40 x (40.0, 40.0) (art (40.0, 40.0))
[PASS] test_ui_slot_layout.gd.test_the_hud_slot_cells_keep_their_cell_sizes
[ui_slot_layout] launch ship_fighter: 9 brief rows, ENGINES 1, SLOT CELLS 8
[PASS] test_ui_slot_layout.gd.test_the_launch_brief_rows_are_the_nine_pinned_rows
[ui_slot_layout] ship_fighter: matrix 4x3, columns 4, cells 12 (8 plates, 4 gaps), grid width 204
[ui_slot_layout] ship_vanguard: matrix 4x4, columns 4, cells 16 (11 plates, 5 gaps), grid width 204
[ui_slot_layout] ship_miner: matrix 4x4, columns 4, cells 16 (12 plates, 4 gaps), grid width 204
[ui_slot_layout] ship_trader: matrix 4x4, columns 4, cells 16 (13 plates, 3 gaps), grid width 204
[ui_slot_layout] ship_corvette: matrix 4x4, columns 4, cells 16 (13 plates, 3 gaps), grid width 204
[ui_slot_layout] ship_freighter: matrix 4x5, columns 4, cells 20 (15 plates, 5 gaps), grid width 204
[ui_slot_layout] ship_gunship: matrix 4x5, columns 4, cells 20 (14 plates, 6 gaps), grid width 204
[ui_slot_layout] ship_patrol: matrix 4x5, columns 4, cells 20 (17 plates, 3 gaps), grid width 204
[ui_slot_layout] ship_destroyer: matrix 5x6, columns 5, cells 30 (23 plates, 7 gaps), grid width 256
[ui_slot_layout] shipyard after all nine grids: panel minimum (1278.0, 1372.0), viewport (1920.0, 1080.0)
[PASS] test_ui_slot_layout.gd.test_the_layout_grid_builds_every_hulls_matrix
[ui_slot_layout] shipyard ship_fighter: caption 'SLOT LAYOUT · 8 CELLS · 1 ENGINES', 5 stat rows, 9 list metas
[PASS] test_ui_slot_layout.gd.test_the_shipyard_caption_and_stat_rows_read_the_selected_hull
[ui_slot_layout] shipyard ship_fighter: 8 slot glyphs checked
[PASS] test_ui_slot_layout.gd.test_the_shipyard_layout_glyphs_are_the_slot_types
[ui_slot_layout] slot component: weapon art (48.0, 48.0) -> cell (48.0, 48.0), cargo art (40.0, 40.0) -> cell (40.0, 40.0)
[PASS] test_ui_slot_layout.gd.test_the_slot_component_keeps_its_cell_whatever_the_plate_art_is
[SUMMARY] passed=12 failed=0
```

exit 0, no `SCRIPT ERROR`, no leak line, no `WARNING` of any kind from that run (log
`/tmp/p2a_w5_suite.log`).

## 7. Gate evidence

| Run | Result |
|---|---|
| This suite alone | **`passed=12 failed=0`, exit 0** (7 before; +5) |
| Full gate, every file of this pass on disk, W4's suite not yet written (`/tmp/p2a_w5_gate.log`, first run) | **`passed=358 failed=0`, exit 0** — 353 (W1+W2+W3+W4's code) + this suite's +5 |
| Full gate, after W4's `tests/test_p2a_launch_fit.gd` landed mid-pass (`/tmp/p2a_w5_gate.log`, second run) | `passed=369 failed=1` — the one red is **W4's**, not this worker's: `[FAIL] test_p2a_launch_fit.gd.test_the_launch_reads_the_profiles_fit_through_the_base_ids: the instance id resolved to the base id the resolver reads` |
| W4's suite **alone** (reproduces it outside any UI suite) | `passed=11 failed=1`, the same assertion — so the red belongs to W4's in-flight file set (`game.gd`/`player_state.gd`/`autoload/player_profile.gd`), which R1 must measure after W4 finishes |

The count never shrank: 7 → 12 in this suite, 353 → 358 in the gate with this pass alone.

**Warnings/errors ledger.** The one `SCRIPT ERROR: Cannot call method 'call' on a previously
freed instance` (at `tests/test_weapon_fx_f4.gd:176`) is **pre-existing** — it is present
verbatim in the recorded pre-wave gates (`weapon_fx_f4_gate_after.txt`,
`slice2_5_s3_gate.txt`) and the test still passes. The one `WARNING: EconomyLog: could not
open user://p1l_missing_dir_do_not_create/...` is another suite's negative-path case. The
exit line `WARNING: 80 ObjectDB instances were leaked at exit` is also pre-existing and
byte-identical to the pre-wave record (`slice2_5_s3_gate.txt:346`); **this suite alone leaks
nothing** (`grep -c leaked /tmp/p2a_w5_suite.log` = 0), which matters because the headless
runner runs every test inside one frame and therefore never flushes a `queue_free`.

**Cross-worker integration measured, not assumed.** W4's suite launches `game.tscn` off the
real `PlayerProfile`, pushes the Vanguard's three W cells into the shipped HUD and asserts
`hud.hull_slots().size() == 3` (`test_p2a_launch_fit.gd:334-335`) — that test **passes**, so
`set_hull_slots`/`hull_slots` are wired correctly against the launch path on the shipped
scene, and W4's run of it produces no error attributed to `hud.gd`, `shipyard_panel.gd` or
`launch_panel.gd`.

## 8. Decisions the pin left open (each reported, none of them a new number)

1. **The slot-glyph stem table is stated in the panel.** 09 §1 names the shipped glyphs
   (`icon_slot_{engine,power,w,s,h,c,b,u}`) but the four visual facts a consumer needs
   (API key → stem, directory, template, suffix) are not a pinned const anywhere, and
   `ShipFit`/`ModuleCatalog` are other workers' files. `SLOT_GLYPHS` +
   `SLOT_GLYPH_DIR`/`SLOT_GLYPH_TEMPLATE` in the shipyard panel is that one literal; the suite
   carries its own copy (transcribed from 09 §1) and asserts every plate against the file on
   disk, so the panel's table cannot drift from the document unnoticed.
2. **The glyph inset is reused, not invented.** `slot_button.tscn` insets its icon 6 px
   inside the 48 px plate; the panel's `PLATE_ICON_INSET = 6.0` copies it and says so in a
   comment. No document states a panel-side inset.
3. **The HUD's `GROUPS_MAX` is a reference, not a second literal.**
   `const GROUPS_MAX: int = WeaponComponent.GROUPS_MAX` reads `game/weapons.gd:134` — the
   same 5 the input map's `weapon_1..5` binds — instead of restating the number the pin
   quotes.
4. **`columns` keeps the pin's `mini(count, 5)` and adds a `maxi(..., 1)` floor** for the one
   value a `GridContainer` rejects (`0`, an empty push). Every non-empty push is
   bit-identical to the pin's formula.
5. **`set_hull_slots` also enforces the selectability rule itself**
   (`index < GROUPS_MAX and cell.selectable`) rather than trusting the producer, so a 7-W
   capital's cells 5–6 are disabled even if a future caller marks them selectable. W4's
   producer already sends the same answer (`game.gd:1404`), so nothing changes today.
6. **`_hull_id` is recorded but unread.** The pin's signature takes the hull id and the empty
   cell's glyph is always `icon_slot_w` (a weapon row holds only W cells), so the HUD has no
   use for it; it is stored (and documented) so a probe can pair `hull_slots()` with the hull
   it came from. If R1 prefers zero unread state, deleting the two lines is behaviour-free.
7. **The caption's `HARDPOINT_CAPTION` const keeps its name** while its text is the pin's
   `SLOT LAYOUT · …`; the node it writes is `%HardpointCaption` and the pin's own var name
   `_hardpoint_caption` is untouched (D0's STATION_HUB amendment keeps both unique names).

## 9. What this pass did not touch, and the pins it kept

* `assets/**`: no file created, modified or renamed. The panel and the HUD only **reference**
  the eight slot glyphs (each asserted present on disk by the suite, so no load is
  environment-deferred) and `w_laser`'s catalogue icon.
* `ui/theme/vajb_theme.tres`, `tools/build_theme.gd`, `project.godot`, `addons/**`,
  `docs/**`: untouched — only theme **items** are read (`SlotButtonWeapon`'s four plate
  styleboxes, the `Tokens` roles), never written.
* `ui/hud/hud.tscn`, `ui/station/launch_panel.tscn`: untouched. The only scene edited is
  `shipyard_panel.tscn`, and only the one node the pin names.
* §7's HUD pins: `set_target`/`clear_target`/`set_prompt`/`set_warp_channel`/`set_pool`/
  `set_emergency`/`set_lock_progress`/`set_speedometer`/`hit_marker` and their read-backs are
  unchanged; `weapon_slot_selected` still emits the 0-based slot index, `weapon_changed`'s
  `weapon_id` is still a family id, and the ammo label path is the same code.
* §3's `ShipFit`/`ModuleCatalog` pins and W2's profile API are **read**, never re-derived:
  the panels and the HUD call `ShipFit.grid_cells`, `grid_size` and `grid_counts` and nothing
  else of `ShipFit` (the suite additionally walks `SLOT_GRIDS`' nine keys), and no fit, module
  row, count or cost is restated anywhere in the six files.
* No gameplay number was added: every count, label and caption string is quoted from 08 §3,
  09 §1/§8 or §11.

## 10. Staged, per brief §7 (nothing here was done)

1. Weapon muzzles / thruster anchors in flight (09 §8) — the feel lane's, and W4 already
   flipped `thruster_anchors()`.
2. The fitting panel, power meter, module shop and the UPGRADES retirement (P2-B).
3. `weapon_6`/`weapon_7` in the input map — an owner `project.godot` edit; the capital's
   cells 5–6 ship drawn, fitted and `disabled`.
4. NPC fits — an NPC hull has no matrix, so the panel draws no cells and clears its caption
   for one (`_set_layout_grid`'s empty branch), with no `push_error`.
