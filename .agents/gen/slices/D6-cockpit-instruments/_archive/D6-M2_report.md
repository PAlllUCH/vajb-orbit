---
slice: D6
worker: D6-M2
model: "deepseek/deepseek-v4-flash (crush run, per D6_prompts.md)"
status: actionable
gate: "607/0 (full gate, four runs, identical — `--debug` ledger run included) — of which 15 are test_d6_status.gd's own methods; M1 measured 592, so the wave grew 578 → 607 (+14 M1, +15 M2)"
---

# D6-M2 report — ship status screen

## Result

UI_SPEC §3.8's screen ships as `ui/hud/ship_status_screen.gd`
(`class_name ShipStatusScreen extends Control`, new file) and `hud.gd` builds it in
the §7 inner-widget idiom — **`hud.tscn` is byte-untouched**, no new feed is
introduced, and the screen reads the profile without writing a byte of it.

* **Box**: 720×520 centred modal (measured `modal_size()` and
  `body.custom_minimum_size`), `ui_cockpit_frame` nine-slice over the whole body
  (the §3.7 recipe: 192×192 master, 64 px patch margins, node at 2× scaled 0.5 →
  32 px logical band), hidden by default, in flight only.
* **Left**: the hull's side render drawn 320 px wide, swapping through
  `repairs_panel.gd`'s own rule, with code-drawn hardpoint markers over it.
* **Right**: the shipyard's slot-grid recipe cell for cell (48 px
  `SlotButtonWeapon` plate, glyph inset 6 px, gaps as empty Controls, `columns` =
  the matrix width) plus one row per fitted module — its layout cell ref and its
  `ModuleCatalog` name.
* **Footer**: `HULL`/`SHLD` `cur / max` as 18 px `HudReadout`s and `PWR draw /
  capacity` from the fitting panel's own arithmetic.
* **Toggle**: the `ship_status` action behind `InputMap.has_action`, or the
  `icon_close` button; Esc is untouched (nothing in the wave reads it).

Measured: full gate **`[SUMMARY] passed=607 failed=0`**, exit 0, four runs
(including the `--debug` ledger run), identical; the
new suite `test_d6_status.gd` = **15 tests, 0 failures** (measured five times, alone
and in the gate). The live account is untouched: `profile.cfg` md5
`95ea422a5c55dee5a28e1690cd4351cf` and `economy_log.txt` md5
`6e3ecd945110bac3b11a980a6459390f` identical before and after every run (the
runner sandboxes itself, CONTRACTS §14), and the suite additionally repoints
`save_path` at its own scratch file for the no-write proof.

## The reused expressions (cited, never restated)

| UI_SPEC §3.8 requirement | Reused source | Where |
|---|---|---|
| the `_damaged_side.png` suffix swap, intact when no cut exists | `repairs_panel.gd`'s static `hull_render(ship_id, missing_hull)` (`ui/station/repairs_panel.gd:289-296`; `SIDE_SUFFIX`/`DAMAGED_SIDE_SUFFIX` at `:39`) | `ship_status_screen.gd::_refresh_render` calls `RepairsPanelScript.hull_render(hull, missing)`; `missing = round(max(hull_max - hull_current, 0))` |
| POWER draw / capacity | the fitting panel's `_power_of`: `ShipFit.fit_legal(hull, _base_fit(profile, fit))[&"power"]` (`ui/station/fitting_panel.gd:1239-1240`); `_base_fit` is `PlayerProfile.base_fit` (`fitting_panel.gd:1318-1324`) | `ship_status_screen.gd::_power_of` is that expression verbatim, through the same `base_fit` bridge; the line's wording is the panel's own `METER_IDLE` (`fitting_panel.gd:143`), `PWR %d / %d` |
| the slot grid, cell for cell | `shipyard_panel.gd:462-515` (grid build, `PLATE_VARIATION`/`PLATE_SIZE`/`PLATE_SEPARATION`/`PLATE_ICON_INSET` at `:54-62`, `SLOT_GLYPHS` at `:64-75`) and the FITTING precedent `fitting_panel.gd:496-549` | `ship_status_screen.gd::_refresh_grid` / `_make_slot_cell` / `_apply_plate_textures`, byte-equivalent (the two panes already duplicate it) |
| module names and glyphs | `ModuleCatalog.module(base).get(&"name", …)` (the shipyard's own read, `shipyard_panel.gd:586`) and `ModuleCatalog.icon_path(base)` (`module_catalog.gd:591-601`) | `ship_status_screen.gd::_collect_rows` |
| the fit the launch would fly, base-id translated | `PlayerProfile.resolved_fit` (§13) and `PlayerProfile.base_fit`/`base_module_id` (§15), the same bridge the panes use | `_resolved_fit` / `_base_fit` / `_base_id` |
| hardpoint markers | `ShipFit.HARDPOINTS`, guarded by `ShipFit.is_mapped(hull)` (its own `has()`, `ship_fit.gd:836-838`), anchors via `thruster_points` / `weapon_mounts` (`:844-880`) | `_refresh_markers` / `_collect_markers`; the table is read-only and the screen works with no row |

No formula is invented anywhere: the only arithmetic in the file is
`round(max(hull_max - hull_current, 0))` (the damage the repairs pane itself
takes), the percent-free point/point footer, and `centre + anchor * (320 / native
width)` for the markers.

## Measured numbers

**The box and its chrome** — `modal_size()` `(720, 520)`; body minimum
`(720, 520)`; frame texture `res://assets/ui/ui_cockpit_frame.png`, patch margins
64, node scale 0.5 (808×432 → 404×216 is §3.7's own measured pairing; here
1440×1040 → 720×520); close button `res://assets/icons/hud/icon_close.svg`,
16×16, `focus_mode = NONE`; `visible == false` at build with `is_open() == false`.

**The toggle** — with the row absent: `_unhandled_input` with an
`InputEventAction` for `ship_status` leaves `is_open() == false` (and the method
returns before reading the event). With a runtime-seeded row: one press opens,
the second closes, and the `icon_close` `pressed` signal closes it too. The test
removes the row only when it created it, and restores a pre-existing row (events
+ deadzone) exactly, so the guard's absent branch stays provable **after** the
orchestrator applies the `project.godot` row at close-out. Docked:
`set_docked(true)` → `set_open(true)` refused, the action refused; undocked it
opens again.

**The grid (a seeded scratch profile)** — vanguard: `columns` 4 = the matrix
width; 16 children = 11 slots + 5 gaps; 09 §9's standard fit fills 5; the seeded
fit (3 weapons, 1 shield, 1 plate, 1 engine, 1 power) fills 7 and leaves 4.
Module rows, in the grid's own row-major order: refs `W1, W2, H1, S1, W3, E1,
P1` with names `Laser MkII, Cannon MkI, Light Plate, Light Shield, Mining Laser,
Standard Drive, Standard Reactor`. Fitted cells carry `ModuleCatalog.icon_path(base)`,
empty ones their type's slot glyph (`icon_slot_<stem>.svg` of the pin's own
`SLOT_GLYPHS` table). A pushed W cell (`set_hull_slots`, `battery: 3`) adds its
rack: the row reads `W2 · B3 · Cannon MkI` and takes the pushed module, not the
fit's. A hull outside the nine (`ship_swarmer`): no grid, no rows, no markers, no
render path.

**The damaged-side swap, both branches** — vanguard at 500/1000 →
`res://assets/ships/ship_vanguard_damaged_side.png` (the only damaged cut on
disk; measured `RepairsPanelScript.hull_render(vanguard, 500)` equality and the
`TextureRect.texture.resource_path`); vanguard at 1000/1000 →
`ship_vanguard_side.png`; fighter at 500/1000 → `ship_fighter_side.png` with
`ResourceLoader.exists("res://assets/ships/ship_fighter_damaged_side.png")` measured
`false`, so that branch really is the no-cut one.

**The markers** — vanguard: **11 markers** = 8 thrusters (09 §11's four modes ×
2 anchors) + 3 mounts; the anchor space is the drawn cut's own scale, so the
damaged branch re-derives it (measured on the damaged cut, 1023×997 → scale
`320/1023 = 0.312806`: the first rear anchor lands at `(43.949, 121.087)`, the
first mount at `(125.279, 103.226)` with `facing -0.124`, i.e. sprite centre +
`HARDPOINTS` px × scale). `ship_swarmer`: 0 markers, no error.

**The footer** — pushed pools 812/1000 and 240/300 read `HULL 812 / 1000` and
`SHLD 240 / 300`; the seeded fit reads **`PWR 5 / 8`** — draw 5 (w_laser 1 +
w_cannon 1 + w_mining 1 + s_light 2; the engine and power modules, and the 0-draw
plate, contribute nothing) against out 8 (the vanguard's own 8 + p_std's
`power_add` 0), and the test asserts the numbers against
`ShipFit.fit_legal(vanguard, base_fit(seeded_fit))[power]` cell for cell rather
than a literal. The label is a `HudReadout` (18 px).

**The no-write proof** — scratch `user://test_d6_status.cfg`: bytes read before,
the whole screen lifecycle after (open, `module_rows`, `grid_cells`,
`footer_lines`, `hull_render_path`, `hardpoint_markers`, two `toggle`s, `close`),
bytes identical (`==` and equal size), `_dirty` false, and `fit_for`, `modules`
and `credits` unchanged.

## Route choices inside the pinned acceptance (bucket 1)

1. **The screen's state is a full-rect `Control` whose 720×520 body is the only
   pointer target** (`mouse_filter = STOP` on the body, `IGNORE` on the screen and
   on every child except the close button). A hidden screen therefore cannot eat a
   HUD click, and the modal's own body stops a click from reaching the world.
2. **The HUD reads the action, the screen owns the docked rule.**
   `hud.gd::_unhandled_input` is the only new input handler (the HUD had none); it
   returns early when `_status == null` or `InputMap.has_action` is false, marks a
   consumed event handled, and `set_docked(active)` delegates to the screen. The
   docked refusal lives in one place (`set_open`), so no path can draw a dead
   modal.
3. **`set_docked`/`docked()` are new, additive, and unused in production today** —
   the dock route replaces the game scene, so nothing in `game/` calls them. They
   exist because §3.8 pins "hidden while docked like §3.7" and the section 3.7
   dial's own hiding is a caller-side convention; the seam makes the rule
   expressible and testable. **Reversal: delete the latch, its two guards and the
   suite's docked test.**
4. **The screen is preloaded by path in `hud.gd`, not reached through its global
   class name** (`const ShipStatusScreenScript := preload(...)`,
   `var _status: Control`). The class name still ships as the pin requires; the
   preload keeps the HUD parsing in a headless gate that has not re-scanned the
   project. A headless editor pass was run once to register the class
   (`godot --headless --editor --path "$VAJB_PROJ" --quit`, the M1 precedent).
5. **How "glyph + cell ref" is split between the two surfaces.** The grid stays the
   shipyard's recipe cell for cell (a bare 48 px plate carrying the module's glyph;
   wrapping each cell in a ref label would depart from the recipe), so the cell
   ref and the `ModuleCatalog` name live on the one row per fitted module —
   `<TOKEN><n> · <NAME>`, `· B<rack>` for a weapon cell the launch pushed. The two
   surfaces are one grid: a plate and its row share the cell's token + layout
   index in their node names (`SlotW00` / `RowW00`, the shipyard's own naming),
   which the suite asserts. The ref grammar is the fitting panel's own
   `SELECTION_FORMAT` prefix (`fitting_panel.gd:116`) and the rack is the
   `set_hull_slots` payload's `battery` (§17: "the 1-based rack ordinal the HUD's
   W-slot buttons address"). The row order is the grid's own
   (`ShipFit.grid_cells`, row-major), so a row and its plate cannot disagree. A
   catalogue id with no name falls back to its id string (the shipyard's own
   `get(&"name", String(id))` reading).
6. **Marker tokens**: thrusters `text_dim`, mounts `metal_light` (§3.8 names both
   tokens without splitting them). **Reversal: both `text_dim`.** Marker geometry
   (1 px outline, 5 px triangles, 3 px circles, 6 px facing ticks) is code-drawn on
   a child `Control`, never baked (§3.2's palette-neutral precedent).
7. **The render box follows the drawn cut's aspect** (320 px wide, height =
   `320 × native.y / native.x`), which is what makes the marker space exact; the
   intact and damaged vanguard cuts differ in aspect (960×521 vs 1023×997), so the
   left column is taller on the damaged branch. Honest to the art §3.8 names; the
   reversal is a fixed 320×H box if the owner wants no reflow.

## Findings (reported, not fixed)

1. **(bucket 2 — docs)** `ship_vanguard_damaged_side.png` is 1023×997 while every
   intact side render is ~2:1 (vanguard 960×521, fighter 897×415). §3.8's
   "320 px wide" therefore means two different boxes per damage state, and the
   damaged cut is not a same-framing variant of the intact one. The repairs pane
   is immune (contain-fit), this screen is not. A docs/asset decision, not a
   worker's: the owner could pin the render's *height* instead of its width, or
   ask for a same-frame damaged cut.
2. **(bucket 2 — wave ledger)** M1's `ui/hud/cockpit_cluster.gd` contributes **6
   rows** to the `--debug` warning ledger (`:195`, `:325`, `:332` ×2, `:345`,
   `:425` — local/iterator/param shadowing and two narrowing conversions). They are
   new vs the 578 baseline and outside this worker's deliverable, so they are named
   for R1 rather than edited here. **This worker's own three files contribute 0
   rows**: measured `grep -cE "at: GDScript::reload \(res://(ui/hud/ship_status_screen\.gd|tests/test_d6_status\.gd|ui/hud/hud\.gd)"` on a `--headless --debug` run → **0**.
3. **(bucket 1 — observed, untouched)** the wave's brief projected "≈22" new
   assertions for both suites; measured **29** (M1 14 + M2 15), so the gate's own
   figure is 578 → 607. The gate's two pre-existing error lines are unchanged
   (`test_weapon_fx_f4.gd:178`'s freed-instance `call`, the detached-hull
   `data.tree` line, both already recorded at CONTRACTS §9).

## Evidence

```
XDG_DATA_HOME not needed: the runner sandboxes itself (CONTRACTS §14). Commands, from $VAJB_WORKSPACE:
godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200 -- --suite=test_d6_status
godot --headless --debug --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200 -- --suite=test_d6_status
godot --headless --editor --path vajb-orbit --quit        # register the new class_name (no editor was open; M1's precedent)
godot --headless --path vajb-orbit res://game/game.tscn --quit-after 300   # HUD smoke, scratch XDG_DATA_HOME
```

```
[SUMMARY] passed=607 failed=0        # full gate, four runs, identical; 50 suites
[SUMMARY] passed=15 failed=0         # test_d6_status.gd alone (6 runs)
0                                    # --debug ledger rows attributed to ship_status_screen.gd / test_d6_status.gd / hud.gd
exit=0                               # every run
md5 profile.cfg 95ea422a5c55dee5a28e1690cd4351cf   (before == after, all runs)
md5 economy_log.txt 6e3ecd945110bac3b11a980a6459390f (before == after, all runs)
```

The headless game-scene smoke run (300 frames, scratch `XDG_DATA_HOME`) printed
no error and no warning of its own, so the HUD builds the screen in a real launch.

## Files touched

- `vajb-orbit/ui/hud/ship_status_screen.gd` — **new** (`class_name
  ShipStatusScreen`, 833 lines): the modal, the frame, the render + marker layer,
  the grid and module rows, the footer, the toggle/docked rules and the read-backs
  (`modal_size`, `body`, `frame`, `hull_render`, `hull_render_path`, `slot_grid`,
  `module_rows`, `grid_cells`, `hardpoint_markers`, `footer_lines`,
  `close_button`, `is_open`, `toggle`, `set_open`/`open`/`close`, `docked`,
  `set_docked`, `set_hull`, `set_hull_slots`, `set_pools`, `apply_theme`).
- `vajb-orbit/ui/hud/ship_status_screen.gd.uid` — new sidecar.
- `vajb-orbit/ui/hud/hud.gd` — additive only: the `ShipStatusScreenScript`
  preload, `SHIP_STATUS_SCREEN`/`SHIP_STATUS_ACTION`, `_status`/`_docked`,
  `_build_status_screen`, `_push_status`, `set_docked`, `docked`,
  `status_screen`, `_unhandled_input`, the two `_push_status` calls in the
  hull/shield handlers, the `set_hull_slots` push, and the theme refresh (≈115 new
  lines with their comments; no existing method's body changed shape and the
  frozen §7 API is untouched). The file's remaining uncommitted diff is M1's
  cluster rewiring, which this pass did not touch.
- `vajb-orbit/tests/test_d6_status.gd` — **new**, 618 lines, 15 test methods (the
  only new test file; `test_d6_cluster.gd` was not touched).
- `vajb-orbit/tests/test_d6_status.gd.uid` — new sidecar.
- `vajb-orbit/.godot/global_script_class_cache.cfg` — local, gitignored; the
  headless editor pass registered `ShipStatusScreen` (the M1 precedent).

Untouched, as the brief requires: `vajb-orbit/project.godot` (the `ship_status`
row is the orchestrator's close-out), `ui/theme/vajb_theme.tres`, all of `game/`
and `autoload/`, `addons/`, `docs/CONTRACTS.md`, `docs/gameplay/18_engine_spec.md`
and `docs/gameplay/08_ship_slots_modules.md`. The only `docs/` edits in the tree
(`CONTRACTS.md` §19, the four gameplay docs) are the parallel S6 lane's, not this
worker's — `git diff --stat` over this worker's set is `ui/hud/hud.gd` plus the
four new files.

## Follow-ups

| Item | Kind | Where |
|---|---|---|
| The damaged cut's aspect (1023×997) differs from every intact side render (~2:1), so §3.8's "320 px wide" yields two different left-column heights across the damage states; pin the height, or ask for a same-framing damaged cut | docs/asset decision (bucket 2) | `docs/design/UI_SPEC.md` §3.8; `vajb-orbit/assets/ships/` |
| Per-module damage is still not in the sim, so the screen lists modules and their fitted/powered presence only | staged, already in the brief | `docs/gameplay/18_engine_spec.md` (owner-locked) |
| 6 `--debug` ledger rows in `ui/hud/cockpit_cluster.gd` (M1's file, new this wave) | review candidate | `ui/hud/cockpit_cluster.gd:195,325,332,345,425` |
| The `ship_status` row's key (`U` proposed) is the orchestrator's `project.godot` pass; until then the guard's absent branch is the shipped state and the suite covers both | close-out, orchestrator | `vajb-orbit/project.godot` |
