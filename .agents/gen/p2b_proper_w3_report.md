# P2-B proper — W3 report: the shipyard's hover line and LAUNCH's two service rows

**Role:** W3 (coder — shipyard hover & LAUNCH services). **Files changed:** `vajb-orbit/ui/station/shipyard_panel.gd`
and `vajb-orbit/ui/station/launch_panel.gd`; new under `vajb-orbit/tests/`: `test_p2b_services.gd` (+`.gd.uid`),
`probe_w3_services.gd`/`.tscn` (+`.gd.uid`), `probe_w3_services_lint.gd`/`.tscn` (+`.gd.uid`). **Nothing else
touched:** `git status --short` shows no change to `assets/**`, the theme, a `.tscn`, `project.godot`,
`addons/**` or `docs/**`; the only two tracked files this pass modifies are the two panels. Every number below
is measured on this host (Godot 4.7.2.stable, Linux), with the command and the raw line it produced.

**Headline numbers.**

| Measure | Value |
|---|---|
| Gate before (sandboxed `user://`, this host) | `[SUMMARY] passed=420 failed=0`, exit 0 — reproduces W2's figure |
| Gate after (same command) | `[SUMMARY] passed=431 failed=0`, exit 0 |
| Growth | **+11** (one new suite, `test_p2b_services`, 11 tests) |
| `SCRIPT ERROR` rows in the gate log | **1 → 1** (the pre-existing freed-instance row, `tests/test_weapon_fx_f4.gd`, LOW L61) |
| Lint ledger, the four files this pass owns | **0 warning rows**; positive control `game/weapons.gd` **3**, negative control `autoload/world_clock.gd` **0** |
| Shipyard hover line, fitted cell | `W1 · LASER MKII · OWNED ×3` (W1 holds `w_laser`, the account owns 3) |
| Shipyard hover line, empty cell | `W2 · EMPTY · OWNED ×0` |
| Shipyard hover line, a hull the account does not own | every cell `W1 · EMPTY · OWNED ×0` (the whole 8-cell Lancer/Fighter grid) |
| A real pushed pointer over the plate | `entered=1 exited=0`, strip `W1 · LASER MKII · OWNED ×3`; on leaving, strip back to the row hint `ENTER SELECT · VANGUARD · 18 000 CREDITS` |
| Plate geometry before → after the hover | **identical** (48 px, `SlotButtonWeapon`, 4 px separation, the same four theme textures, `SLOT LAYOUT · 11 CELLS · 1 ENGINES`) |
| `Repairs.refuel` result / pane report | `{ok true, ship_id ship_vanguard, fee 0, fuel_max 200}` → strip `FUEL_MAX 200`, fuel `0 → 200`, credits `18000 → 18000` |
| `Repairs.recharge` result / pane report | `{ok true, ship_id ship_vanguard, fee 0, energy_max 100}` → strip `ENERGY_MAX 100`, fuel `200 → 200` (nothing filed), credits unchanged |
| Full-tank refusal | `{ok false, reason fuel_full}` → strip `FUEL_FULL` in `accent_danger` `(0.7843, 0.2784, 0.1216, 1.0)`, credits and fuel unchanged, button still pressable |
| No-report refusal | `{ok false, reason no_damage_report}` → strip `NO_DAMAGE_REPORT` in `accent_danger` |
| Live station, one real mouse motion (owner's own profile) | plate `SlotW00` → shell status strip `W1 · CANNON MKI · OWNED ×0` (the live Vanguard fit holds `w_cannon`); the same plate on an unfit hull read `W1 · EMPTY · OWNED ×0` |

---

## 1. What landed

### 1.1 The shipyard's plates (STATION_HUB §5.2's 2026-09-22 amendment, owner request 1)

`shipyard_panel.gd`'s slot plates gain the fitting surface's own line on hover. The module is read from the
**selected hull's own `fit_for` entry** (the hull the grid and the caption are already drawn for) and the count
from `module_count`, exactly as the brief and the owner's instruction pin:

```text
[W3-SHIPYARD] line W1=W1 · LASER MKII · OWNED ×3
[W3-SHIPYARD] line W2=W2 · EMPTY · OWNED ×0
[W3-SHIPYARD] line P1=P1 · STANDARD REACTOR · OWNED ×0
[W3-SHIPYARD] line E1=E1 · STANDARD DRIVE · OWNED ×0
```

`hover_line(cell)` is public so a test can read the string for a cell without a pointer; the plates call it
through `mouse_entered` / `mouse_exited` and publish the result on the channel every other hint in this pane
already uses (`status_requested`, §12.4). Leaving a plate puts the selected hull's own row hint back, so the
shell's strip never keeps a line for a cell the pointer has left (measured above).

**The line costs the grid nothing** — the owner's own condition (size, glyph, separation, caption):

```text
[W3-SHIPYARD] hull=ship_vanguard grid columns=4 cells=16 h_sep=4 v_sep=4 caption=SLOT LAYOUT · 11 CELLS · 1 ENGINES
[W3-SHIPYARD] plate W00 size=(48.0, 48.0) disabled=true focus_mode=0 (FOCUS_NONE) mouse_filter=0 (MOUSE_FILTER_STOP) variation=SlotButtonWeapon art=res://assets/ui/ui_slot_weapon_normal.png inset=6.0 glyph=res://assets/icons/slot/icon_slot_w_48.png
```

The one thing that had to move is the plate's `mouse_filter`: `_make_plate` left it at `MOUSE_FILTER_IGNORE`,
and a control that ignores the mouse never reports a hover. It is now `MOUSE_FILTER_STOP` on the slot cells
alone (a gap stays a bare `Control`), measured as `mouse_filter=0 (MOUSE_FILTER_STOP)`. The plate stays a
display: still `disabled`, still `FOCUS_NONE`, still no focus ring, and it mutates nothing. The suite asserts
the filter is no longer `IGNORE` and that the same four theme textures, the columns, the separation and the
caption are byte-identical across a hover.

**The grid itself did not move; only what a plate says when the pointer is on it.** Nothing in the resolution path is a
literal: the cell's token (`W`, `P`, …) comes from `ShipFit.grid_cells`, the name from `ModuleCatalog.module`,
the count from `module_count`, `EMPTY` from the pin, and the type's single-id shape for `POWER` is handled
(`P1 · STANDARD REACTOR · OWNED ×0` — `power` is one id, not a cell array, CONTRACTS §11 rule 1). An instance id
goes through the profile's own `base_module_id` bridge, the way the FITTING pane names its modules (15 §6).

### 1.2 LAUNCH's service rows (STATION_HUB §5.4's 2026-09-22 amendment, owner request 4)

DECK CONTROL gains a `REFUEL` / `RECHARGE` row above the LAUNCH button. Live on the station, at 1920×1080:

```text
0:ActionCaption, 1:HullFrame, 2:ServiceRow, 3:LaunchButton, 4:ConfirmStrip
RefuelButton   text=REFUEL   174x56 at (1484,751)
RechargeButton text=RECHARGE 174x56 at (1670,751)
LaunchButton   text=LAUNCH   360x88 at (1484,819)      # LAUNCH stays the last, lowest control
```

- The **labels are the catalogue's own**: `StationCatalog.SERVICE_REFUEL`/`SERVICE_RECHARGE` rows' `name`
  (`REFUEL` / `RECHARGE`, `free=true`, `instant=true`). A renamed service moves the button; no literal exists.
- The **calls are `Repairs`' own** and the **report is the service's own result**: the result key and its
  figure on success, the service's own reason (upper-cased, the pane's own casing) on a refusal. No price is
  printed anywhere and no credits move (measured `18000 → 18000` across every call).
- The report lands in **the pane's status line** (`%ConfirmStrip`, the LAUNCH pane's only status line, §4's node
  tree) **and** goes up to the shell's strip through `status_requested`, which is how every panel in this screen
  publishes a line (§12.4; the REPAIRS pane's own shape). A refusal is rendered in `accent_danger` — equal to
  `Tokens/accent_danger` — never hidden, and the button stays pressable (§3.3).
- One writer now owns that line. `_set_confirm(text, danger)` is used by the arming beat (`_ready`, `disarm`,
  `_arm`, `_fire`, `_on_arm_timeout`) and by `_render_service`, so a refusal's danger colour cannot outlive the
  line it described when the arming copy returns.

Measured refusals (both the service's own reasons, both rendered):

```text
[W3-LAUNCH] full tank pane strip=FUEL_FULL danger=true credits=18000 fuel=200 button_disabled=false
[W3-LAUNCH] no report  pane strip=NO_DAMAGE_REPORT danger=true
```

## 2. The three judgement calls the pin left open

Each is one constant or one branch, with its reversal.

1. **Where the service row is built.** W3's declared file set is the two `.gd` files and `tests/` — no `.tscn` —
   so the row is created programmatically in `_build_service_rows()` and inserted immediately before
   `%LaunchButton` inside DECK CONTROL's own box. **Reversal:** add the `ServiceRow` + two buttons to
   `launch_panel.tscn` and drop the builder (the node names and geometry are already the scene's own).
   This is also why W3's prompt said not to touch the scene file; the panel's script is the whole surface.
2. **The row's height is 56 px**, the EXCHANGE pane's own secondary-button height (`SellAllButton` /
   `CancelButton` 360 × 56), rather than inventing a third button size or reusing LAUNCH's 88. **Reversal:** one
   constant, `SERVICE_ROW_HEIGHT`.
3. **The report's wording.** The pin deliberately declines to print a price and names only the service's own
   result fields, so the strip renders the service's own key upper-cased with its figure (`FUEL_MAX 200`,
   `ENERGY_MAX 100`) and, on a refusal, the service's own reason upper-cased (`FUEL_FULL`,
   `NO_DAMAGE_REPORT`). Nothing is prefixed, nothing is priced, no word is invented. **Reversal:** one
   constant, `SERVICE_REPORT`, plus the two sentence-shaped strings in one branch if the owner wants prose
   (`REFUELLED · …`), which would be a new pinned wording for D0 to land first.

Two smaller calls: the strip's danger colour is the theme's `accent_danger` (every other pane's refusal colour),
and `_run_service` binds the two calls by service id explicitly (`if service_id == SERVICE_REFUEL`) rather than
dispatching on the catalogue's id, so the id is not silently coupled to a function name.

## 3. Tests (11, all new; the brief's file is `tests/test_p2b_services.gd`)

The suite mounts both shipped panes with the shipped theme and drives them through the shell's own wiring (the
pane's `status_requested`, the profile's `profile_changed` → `refresh_profile`), borrowing the shipped autoload
with `save_path` repointed at a scratch file and handing every borrowed field back in `suite_teardown`
(including `_vitals`, which this pass needs and W2's suite did not) — L17 hygiene.

| Test | Subject |
|---|---|
| `test_the_hover_line_reads_a_fitted_cell` | W1 = `W1 · LASER MKII · OWNED ×3` (fit id from `fit_for`, count from `module_count`), and P1 = the single-id `power` shape |
| `test_the_hover_line_reads_an_empty_cell` | W2 = `W2 · EMPTY · OWNED ×0` |
| `test_the_hover_line_reads_a_hull_the_account_does_not_own` | the row is focused, the selection moves, and every non-gap cell of that hull reads `EMPTY`/`×0`; a gap reads no line at all |
| `test_hovering_a_plate_publishes_its_line_and_costs_the_plate_nothing` | 48 px, disabled, `FOCUS_NONE`, the plate art, the 4 px separations, the 6 px glyph inset, the glyph file and the caption **before and after** the hover; the line up the strip; the row hint back on exit |
| `test_the_shipyard_reads_the_fit_without_ever_writing_it` | the source calls `fit_for` / `module_count` and no profile writer (the §12.4 discipline, read off the file) |
| `test_refuel_fills_the_tank_and_reports_the_figures_own_key` | the tank filed, `FUEL_MAX <pool>`, credits unchanged, no danger, no `CR` in the line |
| `test_recharge_reports_the_energy_figure_and_files_nothing` | `ENERGY_MAX <pool>`, fuel untouched, credits unchanged |
| `test_the_full_tank_refusal_is_rendered` | the pinned refusal path: the service's own reason, danger colour, credits and tank unmoved, button pressable |
| `test_an_unfiled_hull_refuses_with_the_services_own_reason` | `NO_DAMAGE_REPORT`, danger colour |
| `test_the_service_actions_are_deck_controls_own_catalogued_names` | labels = the catalogue's names, `StationButton`, 56 px, both in one row inside DECK CONTROL, LAUNCH last |
| `test_the_launch_pane_only_asks_the_service_and_never_touches_credits` | the source reaches `RepairsService.refuel`/`recharge` and no credits/vitals/cargo writer |

Expectations are derived, never invented: the pool figures come from `ShipFit.resolve(hull, STANDARD_FIT)` —
the same derivation `Repairs._pool_max` uses (18 §13) — the names from `ModuleCatalog`, the labels from
`StationCatalog`, the reasons from `Repairs.REASON_*`. The two transcribed literals are the pin's own wordings
(`<TYPE><n> · <MODULE NAME or EMPTY> · OWNED ×<n>`, `%s %d`) and the secondary height, all held in the suite's
constants so a drift in either direction is red.

No existing assertion was deleted or edited: this pass adds a suite and touches no other test.

## 4. Evidence

```text
# sandboxed user:// (a scratch XDG_DATA_HOME), before any edit:
godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=420 failed=0                                # exit 0

# after:
[SUMMARY] passed=431 failed=0                                # exit 0, 1 SCRIPT ERROR row (pre-existing)
#   test_p2b_services 11 · every other suite unchanged

# the suite alone:
godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200 -- --suite=test_p2b_services
[SUMMARY] passed=11 failed=0                                 # exit 0

# both panes measured in memory, including a real pushed pointer:
godot --headless --path vajb-orbit res://tests/probe_w3_services.tscn --quit-after 600
[W3-SERVICES] done                                           # exit 0, 36 measurement lines

# the warning ledger:
godot --headless --debug --path vajb-orbit res://tests/probe_w3_services_lint.tscn --quit-after 600
[W3-SERVICES-LINT] debugger_active=true
shipyard_panel.gd 0 · launch_panel.gd 0 · test_p2b_services.gd 0 · probe_w3_services.gd 0
POSITIVE-CONTROL weapons.gd: 3 WARNING rows   NEGATIVE-CONTROL world_clock.gd: 0
```

Logs: `.agents/gen/p2b_proper_w3_gate_before.log`, `p2b_proper_w3_gate_after.log`,
`p2b_proper_w3_suite.log`, `p2b_proper_w3_probe.log`, `p2b_proper_w3_lint.log`.

Raw suite output (`.agents/gen/p2b_proper_w3_suite.log`, the complete file):

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
[RUN] suites=test_p2b_services
[PASS] test_p2b_services.gd.test_an_unfiled_hull_refuses_with_the_services_own_reason
[PASS] test_p2b_services.gd.test_hovering_a_plate_publishes_its_line_and_costs_the_plate_nothing
[PASS] test_p2b_services.gd.test_recharge_reports_the_energy_figure_and_files_nothing
[PASS] test_p2b_services.gd.test_refuel_fills_the_tank_and_reports_the_figures_own_key
[PASS] test_p2b_services.gd.test_the_full_tank_refusal_is_rendered
[PASS] test_p2b_services.gd.test_the_hover_line_reads_a_fitted_cell
[PASS] test_p2b_services.gd.test_the_hover_line_reads_a_hull_the_account_does_not_own
[PASS] test_p2b_services.gd.test_the_hover_line_reads_an_empty_cell
[PASS] test_p2b_services.gd.test_the_launch_pane_only_asks_the_service_and_never_touches_credits
[PASS] test_p2b_services.gd.test_the_service_actions_are_deck_controls_own_catalogued_names
[PASS] test_p2b_services.gd.test_the_shipyard_reads_the_fit_without_ever_writing_it
[SUMMARY] passed=11 failed=0
```

Raw hover and service measurements (`.agents/gen/p2b_proper_w3_probe.log`, the `[W3-…]` lines):

```text
[W3-SHIPYARD] hull=ship_vanguard grid columns=4 cells=16 h_sep=4 v_sep=4 caption=SLOT LAYOUT · 11 CELLS · 1 ENGINES
[W3-SHIPYARD] plate W00 size=(48.0, 48.0) disabled=true focus_mode=0 (FOCUS_NONE) mouse_filter=0 (MOUSE_FILTER_STOP) variation=SlotButtonWeapon art=res://assets/ui/ui_slot_weapon_normal.png inset=6.0 glyph=res://assets/icons/slot/icon_slot_w_48.png
[W3-SHIPYARD] plate P00 size=(48.0, 48.0) disabled=true focus_mode=0 (FOCUS_NONE) mouse_filter=0 (MOUSE_FILTER_STOP) variation=SlotButtonWeapon art=res://assets/ui/ui_slot_weapon_normal.png inset=6.0 glyph=res://assets/icons/slot/icon_slot_power_48.png
[W3-SHIPYARD] plate E00 size=(48.0, 48.0) disabled=true focus_mode=0 (FOCUS_NONE) mouse_filter=0 (MOUSE_FILTER_STOP) variation=SlotButtonWeapon art=res://assets/ui/ui_slot_weapon_normal.png inset=6.0 glyph=res://assets/icons/slot/icon_slot_engine_48.png
[W3-SHIPYARD] line W1=W1 · LASER MKII · OWNED ×3
[W3-SHIPYARD] line W2=W2 · EMPTY · OWNED ×0
[W3-SHIPYARD] line P1=P1 · STANDARD REACTOR · OWNED ×0
[W3-SHIPYARD] line E1=E1 · STANDARD DRIVE · OWNED ×0
[W3-SHIPYARD] owned: LASER MKII x3, STANDARD REACTOR x0 (module_count)
[W3-SHIPYARD] pushed pointer at (1024.0, 317.0): entered=1 exited=0 status=W1 · LASER MKII · OWNED ×3
[W3-SHIPYARD] pushed pointer at (4.0, 4.0): entered=1 exited=1 status=ENTER SELECT · VANGUARD · 18 000 CREDITS
[W3-SHIPYARD] owns ship_fighter: [&"ship_vanguard"]
[W3-SHIPYARD] after focusing ship_fighter: selected=ship_fighter fit_for={ &"engines": [""], &"weapons": ["", ""], &"shields": [""], &"armour": [""], &"computers": [""], &"boosters": [""], &"utility": [], &"power": "" }
[W3-SHIPYARD] unowned hull line W1=W1 · EMPTY · OWNED ×0 (gap=)
[W3-SHIPYARD] back on ship_vanguard: line W1=W1 · LASER MKII · OWNED ×3
[W3-LAUNCH] deck control children: 0:ActionCaption, 1:HullFrame, 2:ServiceRow, 3:LaunchButton, 4:ConfirmStrip
[W3-LAUNCH] catalogue service refuel = REFUEL (free=true instant=true)
[W3-LAUNCH] catalogue service recharge = RECHARGE (free=true instant=true)
[W3-LAUNCH] button RefuelButton text=REFUEL min=(0.0, 56.0) variation=StationButton focus=2 parent=ServiceRow
[W3-LAUNCH] button RechargeButton text=RECHARGE min=(0.0, 56.0) variation=StationButton focus=2 parent=ServiceRow
[W3-LAUNCH] idle strip=PRESS LAUNCH TO ARM · A SECOND PRESS CONFIRMS WITHIN 3 s
[W3-LAUNCH] FREE_FEE=0 hull max=1000 fuel pool=200 energy pool=100
[W3-LAUNCH] refuel direct result={ &"ok": true, &"ship_id": &"ship_vanguard", &"fee": 0, &"fuel_max": 200 } credits 18000 -> 18000 fuel -> 200
[W3-LAUNCH] refuel pane strip=FUEL_MAX 200 danger=false credits=18000 fuel=200
[W3-LAUNCH] refuel signal: FUEL_MAX 200 danger=false
[W3-LAUNCH] recharge direct result={ &"ok": true, &"ship_id": &"ship_vanguard", &"fee": 0, &"energy_max": 100 } credits 18000 -> 18000 fuel 200 -> 200
[W3-LAUNCH] recharge pane strip=ENERGY_MAX 100 danger=false credits=18000 fuel=200
[W3-LAUNCH] full tank direct result={ &"ok": false, &"reason": &"fuel_full" }
[W3-LAUNCH] full tank pane strip=FUEL_FULL danger=true credits=18000 fuel=200 button_disabled=false
[W3-LAUNCH] full tank signal danger=true
[W3-LAUNCH] credits across every call: 18000 -> 18000
[W3-LAUNCH] no report direct result={ &"ok": false, &"reason": &"no_damage_report" }
[W3-LAUNCH] no report pane strip=NO_DAMAGE_REPORT danger=true
[W3-SERVICES] danger colour on the strip: (0.7843, 0.2784, 0.1216, 1.0)
[W3-SERVICES] Tokens/accent_danger = (0.7843, 0.2784, 0.1216, 1.0)
[W3-SERVICES] done
```

### 4.1 The hover, measured with a real pointer (not a hand-emitted signal)

The probe pushes an `InputEventMouseMotion` through the viewport at the plate's own centre and then away from
it, which is the measurement that proves a `disabled` plate with the filter at `STOP` really reports a hover:

```text
[W3-SHIPYARD] pushed pointer at (1024.0, 317.0): entered=1 exited=0 status=W1 · LASER MKII · OWNED ×3
[W3-SHIPYARD] pushed pointer at (4.0, 4.0):     entered=1 exited=1 status=ENTER SELECT · VANGUARD · 18 000 CREDITS
```

### 4.2 The live station (godot-ai, the owner's own profile)

`scene_open(res://ui/screens/station.tscn)` → `project_run(mode="current")`, then **read-only** input
(PageDown/Tab/Up to change the pane and the selected hull) and one real mouse motion over a plate. No
`ui_accept` and no service press was sent, so no writer on this surface was reachable and the owner's profile
was not written (`md5` of `~/.local/share/godot/app_userdata/Vajb Orbit/profile.cfg` after the pass:
`9a04bea68fbe90c4d017e66245ceee7e`). Measured in the frames:

- the shipyard's grid on the **Lancer** (8 cells, unfit): hovering `SlotW00` put `W1 · EMPTY · OWNED ×0` in the
  shell's strip (`/Station/Layout/Page/Footer/StatusLabel`);
- after focusing the Vanguard row (its 11-cell grid, the live fit holding `w_cannon`): the same hover put
  `W1 · CANNON MKI · OWNED ×0` there — the fitted path, with the account's own `module_count` for that id;
- the LAUNCH pane's DECK CONTROL read `ServiceRow` → `RefuelButton` (`REFUEL`, 174 × 56) and `RechargeButton`
  (`RECHARGE`, 174 × 56) above `LaunchButton` (360 × 88), with the pane's strip still on the arming copy and no
  price anywhere in the column;
- the grid cells' live rects are 48 × 48 with a 36 × 36 glyph inset 6, unchanged by the hover.

## 5. Notes for R1 / the fixer

- **Re-run byte-identically:** the four logs in §4, in order. `probe_w3_services` is read-only apart from
  borrowing the autoload the same way the suite does (it flushes and restores in `_return`, and deletes its
  scratch file). The live pass takes **no** press — do not send `ui_accept` or click a service button, or the
  owner's live profile takes a refuel.
- **Drift checks worth making:** §5.2's amendment against the shipyard's source (the line, the `fit_for`
  source, the move-only claim); §5.4's amendment against `PanelScript.SERVICE_*` and the strip writers; the
  catalogue's two service `name`s against the two button labels; `Repairs.REASON_*` against the rendered
  refusals; `ShipFit.FIT_SLOT_KEYS` / `ShipFit.STANDARD_FIT` against the suite's own derivations.
- **Two things left alone deliberately, both outside W3's file set.** (1) `launch_panel.gd`'s
  `refresh_profile` ignores `&"fuel"` — `Repairs.refuel` emits it, but nothing the LAUNCH pane draws depends on
  the tank (the brief rows are hull/shield/cargo/ammo and the preview is the intact cut), so no refresh is
  registered; if a later wave shows the tank on this pane, one key is the whole change. (2) The shipyard's
  `refresh_profile` still reacts to `&"credits"`/`&"ships"` only: the hover line is computed at hover time and
  reads `fit_for` live, so a fit written in FITTING is already reflected the next time a plate is hovered
  without the pane being told.
- **The one asymmetry a reviewer may read as a hole:** `hover_line` reads `fit_for` literally, as the brief and
  the owner pin it, so a hull the account holds **no** fit for shows `EMPTY` in every cell even though the
  launch would fly `ShipFit.standard_fit`. That is W2's own measured finding (§6 of its report: the composed
  install and the pane's preview disagree on an unfit hull) and it is the pin's, not this pass's; the FITTING
  pane resolves the fallback (`_resolved_fit`) while this display does not. **If the owner wants the shipyard to
  show the standard fit on an unfit hull, the fix is one call:** `fit_for` → `_resolved_fit`'s shape in
  `hover_line`, i.e. `ShipFit.standard_fit(hull)` when the stored fit holds no module. Not done here because
  both the brief (`fit_for`) and §5.2's amendment name the stored entry, and because it would make the
  shipyard promise a fit the profile does not yet hold.
- **`tests/probe_w3_lint.*` was already taken** by the UI-chrome wave's own W3 (defect D5), so this pass's
  ledger is `tests/probe_w3_services_lint.*`. Nothing was overwritten: `probe_w3_lint.gd` is untouched.

## 6. Reversal paths

- **The hover line:** delete `HOVER_FORMAT`/`HOVER_EMPTY`/`POWER_SLOT`, `hover_line`, `_fit_cell_module`,
  `_base_id`, `_module_name`, `_on_plate_hovered`, `_on_plate_unhovered`, `_payload`, and the three lines in
  `_make_slot_cell` that set `mouse_filter` and connect the two signals. The grid then renders exactly as it did
  at P2-A (the plates were `MOUSE_FILTER_IGNORE` and carried no hover).
- **The service rows:** delete `_build_service_rows`, `_make_service_button`, `refuel_button`,
  `recharge_button`, `_on_service_focused`, `_on_service_pressed`, `_run_service`, `_render_service`, the
  service constants and the `RepairsService` preload. Keep `_set_confirm` (the arming copy is unchanged either
  way; reverting it means putting the four `_confirm_strip.text = …` assignments back).
- **Each judgement call:** §2's three reversals.
