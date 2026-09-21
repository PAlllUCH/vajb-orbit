# Wave P2-A — Ship slot frames (per-class counts, engine sets, layouts) — task brief

Law, in order: `AGENTS.md`, `docs/CONTRACTS.md` (§2 ShipStats, §3 ShipFit, §7 HUD,
§9 gate, and the **§11 pin this wave lands**, §3 of this brief), the gameplay docs
this wave codes against — `docs/gameplay/08_ship_classes.md` §2/§3/§3.1/§3.2/§3.3/§6,
`docs/gameplay/09_ship_slots_modules.md` §1/§2/§3.7/§4/§5/§7/§8/§9,
`docs/gameplay/10_ship_acquisition.md` §2.3 — then this brief, then
`.agents/gen/WAVEBOARD.md`. **The docs are the numbers. No worker re-derives,
re-balances or invents one; every figure below is quoted from those sections.**

Owner request this wave executes (2026-09-21, verbatim intent): *"i want different
ships to have different amount of slots with different layouts. so cruiser have more
slots for weapons/hull while fighters for example can have like 2 weapons. ship
classes should have different amount of engines/drives/hull."*

**This wave also closes the owner's open launch-fit gate.** `WAVEBOARD.md`'s
current state records it as one of two open owner gates: *"the briefing reports
five weapons / 1500 rounds while the ship mounts `[w_laser]` and no mining laser —
the measured root cause of 'shooting is not working' and 'cannot shoot
asteroids'"*. The root cause is exactly §2's `game.gd:276` line (the launch
resolves one global `STANDARD_FIT` for every hull and seeds ammo for five fixed
families) plus the panels' fixed five-cell strips. W4 resolves the active hull's
own fit and seeds ammo per **fitted** weapon; W5 makes the panels read the hull's
grid. The orchestrator must re-measure that gate's two symptoms after W4/W5 land
and report them as closed (or as still open, with the numbers) — it is a
deliverable of this wave, not a side effect.

## 1. What that means, in the docs already amended

The design landed in the docs before this brief was written (docs-first, AGENTS.md):

- **Every class has its own count per slot type** — 08 §3's table, derived from
  08 §3.2's hull-plan matrix, which is the single source of the counts.
- **The engine is a set, not a slot** — 08 §3.1: 1 engine cell at ≤ 110 t, 2 at
  140–220 t, 3 at ≥ 260 t, all of them mandatory (09 §4.1). Drives (`B`, burst
  systems) and hull plates (`H`, armour) keep their own columns and their counts
  move with the class too.
- **Weapons follow hull size** — the Lancer mounts 2 (was 3), the Spearhead 4
  (was 3), the Vanguard 3 (was 4); the Destroyer keeps 7 (08 §2's △ note).
- **Every class has a layout** — 08 §3.2's matrix is both the fitting arrangement
  and the mount geometry (08 §3.3), so two classes with the same cell count still
  read and fly differently.

Restated for quick reference (08 §3, law):

| Class | Ship | Tier | E | P | W | S | H | C | B | U | Total |
|-------|------|------|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|------:|
| Fighter | Lancer | Light | 1 | 1 | 2 | 1 | 1 | 1 | 1 | 0 | 8 |
| Cutter | Vanguard | Light | 1 | 1 | 3 | 1 | 2 | 1 | 1 | 1 | 11 |
| Miner | Delver | Medium | 2 | 1 | 2 | 1 | 2 | 1 | 0 | 3 | 12 |
| Trader | Courier | Medium | 2 | 1 | 1 | 1 | 2 | 2 | 1 | 3 | 13 |
| Corvette | Spearhead | Light | 1 | 1 | 4 | 2 | 2 | 1 | 1 | 1 | 13 |
| Hauler | Mule | Heavy | 3 | 1 | 1 | 1 | 3 | 1 | 0 | 5 | 15 |
| Gunship | Bulwark | Medium | 2 | 1 | 5 | 2 | 2 | 1 | 0 | 1 | 14 |
| Frigate | Warden | Heavy | 2 | 1 | 4 | 2 | 3 | 2 | 1 | 2 | 17 |
| Destroyer | Obliterator | Capital | 3 | 1 | 7 | 3 | 4 | 2 | 1 | 2 | 23 |

## 2. What is measured about today's code (do not re-discover, do not trust it to stay)

Every line below was read on 2026-09-21 before this brief was written. It is the
starting state, not a finding list — a worker who needs to change one of these is
changing a **pinned** thing and must say so in their report.

- `game/ship_fit.gd:45` — `SINGLE_SLOT_KEYS = [&"engine", &"power"]`: engine and
  power are exactly one, by construction. `:46` — `LIST_SLOT_KEYS` has no
  `engines` key. `:55` — `HULLS` carries `weapons` (the hardpoints read) and **no
  other slot count**: the 08 §3 grid has never existed in code. `:232` —
  `MODULES` is the 32-row module table, effects/draws only, no tier/cost/name/icon.
  `:397` — `STANDARD_FIT` is one fit (the Vanguard's) for every hull. `:504` —
  `_apply_speed` multiplies each engine in a loop. `:579` — `_clamp` floors speed
  and ceilings pools, with no engine ceiling.
- `game/game.gd:276` — `_resolve_stats()` reads `active_ship` for the hull id and
  then resolves **`ShipFit.STANDARD_FIT` regardless of the hull**; the profile's
  `fits` are never read at launch. `:1116` — `_seed_ammo()` and `:1090`
  `_file_ammo_report()` iterate `_state.WEAPONS` (the five fixed families).
- `game/player_state.gd:32` — `WEAPONS` is a const of five families; `ammo` /
  `ammo_max` are sized to it; `set_ammo` reads `WEAPONS[slot]`.
- `game/station_catalog.gd:61` — `SHIPS` has **four** hulls (fighter, vanguard,
  gunship, destroyer), not nine. `hardpoints` is a literal per row.
- `ui/station/shipyard_panel.gd:37` — `HARDPOINT_PLATES := 7` plates built once in
  an `HBoxContainer` (`%HardpointSlots`), `disabled` beyond `hardpoints`; `:44`
  `STAT_ROWS` = hull/shield/cargo/hardpoints; `:165` meta reads `hardpoints`.
- `ui/station/launch_panel.gd:76` — `BRIEF_ROWS` = destination/hull_name/hull/
  shield/hardpoints/cargo/ammo; the cargo strip is 5 fixed plates.
- `ui/hud/hud.gd:44` — `WEAPON_IDS`/`WEAPON_LABELS`/`WEAPON_ICONS` are five fixed
  families; `:605` `_build_weapon_slots()` builds exactly `WEAPON_IDS.size()`
  cells; `%WeaponGrid` is a `GridContainer` whose `columns` is a scene value;
  `_ensure_cargo_cells(count)` is already dynamic (cargo follows `cargo_max`).
- `autoload/player_profile.gd:36` — `KEY_FITS` holds `ship_id -> {slot_type:
  module_instance_id}` (one string per type, 17 §3); `:264` `modules()` is the
  instance dict; `SAVE_VERSION` is 3 (`:24`).
- `tests/test_ui_slot_layout.gd` pins `HARDPOINT_CELLS := 7` (`:36`), the HUD's
  five weapon cells (`:308`) and the strip/panel minima derived from them.
- `tests/test_p1_profile.gd:204` pins `save_version == 3`.
- Art is **not** a dependency: all nine player side renders exist
  (`vajb-orbit/assets/ships/ship_<hull>_side.png`, `ship_miner_side.png` included),
  the eight slot glyphs exist
  (`assets/icons/slot/icon_slot_{engine,power,w,s,h,c,b,u}_48.png`) and all 27
  module icons plus the five weapon-family icons exist
  (`assets/icons/module/icon_module_<id>_48.png`,
  `assets/icons/weapon/icon_weapon_<family>_48.png`). No worker touches
  `assets/**`.

## 3. The pinned interface this wave lands (CONTRACTS §11, verbatim)

D0 writes this section into `docs/CONTRACTS.md` as **§11 — P2 ship frames
(2026-09-21)** before any code worker starts, so five parallel workers agree.
Additive only: every §2/§3/§7 pin above stays valid.

```gdscript
## game/ship_fit.gd — additive beyond §3's pin.
const SLOT_GRIDS: Dictionary          # hull_id -> Array[String], 08 §3.2's rows, equal length
const SLOT_TOKEN_KEYS: Dictionary     # "E" -> &"engines", "P" -> &"power", "W" -> &"weapons",
                                      # "S" -> &"shields", "H" -> &"armour", "C" -> &"computers",
                                      # "B" -> &"boosters", "U" -> &"utility"; "." is a gap
const FIT_SLOT_KEYS: Array[StringName]      # [engines, weapons, shields, armour, computers, boosters, utility, power]
                                            # — the iteration/display order (rule 3 keeps `fitted_ids`' own order)
const MANDATORY_SLOT_KEYS: Array[StringName]  # [engines, power] — 09 §4.1
const ENGINE_MULT_CEILING := 1.40            # 09 §3.7
const MOUNT_SPREAD := Vector2(0.34, 0.22)    # 09 §8, hull half-extent fraction
const STANDARD_FITS: Dictionary              # hull_id -> 09 §9's fit

static func grid_rows(hull_id: StringName) -> Array           # [] for an unknown hull
static func grid_size(hull_id: StringName) -> Vector2i        # (cols, rows); ZERO when unknown
static func grid_cells(hull_id: StringName) -> Array          # row-major, gaps included:
    # [{type: StringName ("" for a gap), token: String, index: int (-1 for a gap),
    #   col: int, row: int, gap: bool}]
static func grid_counts(hull_id: StringName) -> Dictionary    # all 8 FIT_SLOT_KEYS present, 0 when absent
static func slot_capacity(hull_id: StringName, slot_key: StringName) -> int
static func fit_legal(hull_id: StringName, fit: Dictionary) -> Dictionary
    # {legal: bool, overflow: {slot_key: int}, missing: Array[StringName],
    #  duplicates: Array[StringName], power: {out, draw, spare, legal}}
static func standard_fit(hull_id: StringName) -> Dictionary   # {} for an unknown hull
static func mount_offset(hull_id: StringName, slot_key: StringName, index: int) -> Vector2
    # the cell's normalised hull-local anchor, Vector2.ZERO when the cell does not exist
```

Rules the pin fixes, so no worker has to choose:

0. **`SLOT_GRIDS` is 08 §3.2's block with the cosmetic spaces removed** (the
   Cutter's rows are `.WW.`, `HSCB`, `HWU.`, `.EP.`), and W1's suite parses that
   fenced block out of `docs/gameplay/08_ship_classes.md` and compares it with the
   constant, so the document and the data cannot drift apart. Nine hulls, rows of
   equal length, tokens from `SLOT_TOKEN_KEYS` plus `.`.

1. **Fit shape.** `engines`, `weapons`, `shields`, `armour`, `computers`,
   `boosters`, `utility` are `Array` of module id (`""` = empty cell); `power` is
   one module id. Index = 09 §4.5's layout index (row-major within the type).
2. **Legacy compatibility.** `resolve(hull_id, fit)` accepts the old singular
   `engine` key (a `StringName` **or** an `Array`) and `STANDARD_FIT` resolves
   unchanged; when both `engines` and `engine` are present, `engines` wins.
3. **Resolution order** (`fitted_ids`) stays: `weapons, shields, armour,
   computers, boosters, utility` — then `engines`, then `power`. Weapon-group
   order must not move.
4. **Engine math** (09 §3.7): `speed_mult = min(1 + Σ(m − 1), ENGINE_MULT_CEILING)`,
   `turn_mult = 1 + Σ(m − 1)` (no ceiling). Applied once, after armour, before
   booster-on-activation. A single engine resolves to exactly today's number.
5. **`HULLS[hull][&"weapons"]` must equal `grid_counts(hull)[&"weapons"]`** for all
   nine player hulls — one value, two readers (`game.gd:_target_name`, the panels).
6. **NPC hulls are not in `SLOT_GRIDS`** (`ship_swarmer`, `ship_sibur`,
   `ship_turret_platform`, `ship_boss_maw`, `ship_sibelon`, `ship_apex`,
   `ship_interceptor`, `ship_bomber`, `ship_drone_swarm`, `ship_mine_layer`):
   `grid_rows`/`grid_cells` return empty, `grid_counts` returns the 8 keys at 0,
   `slot_capacity` 0, `standard_fit` `{}` — **no `push_error`, no warning**. NPCs
   do not fit modules and `game.gd:944` reads `HULLS` for them.

```gdscript
## game/module_catalog.gd — new file, class_name ModuleCatalog extends RefCounted.
const MODULES: Dictionary   # id -> {name, slot, draw, tier, cost, icon, effects}
static func module(id: StringName) -> Dictionary     # {} for an unknown id
static func icon_path(id: StringName) -> String
static func slot_of(id: StringName) -> StringName     # &"" for an unknown id
```

`MODULES` copies each row's `slot`/`draw`/`effects` **verbatim** from
`ShipFit.MODULES` (no number is invented) and adds `name`, `tier`, `cost` from
09 §3's tables plus `icon` per the rule below. `ShipFit` reads effects and draws
through `ModuleCatalog` and keeps `ShipFit.MODULES` indexable exactly as it is
today (`ShipFit.MODULES[id][&"effects"]`, read by `game/player_ship.gd:672`,
`tests/test_engine_c3_flight_decay.gd:57`, `tests/test_combat_repair_c5.gd:294`
and `tests/probe_c3_flight_decay.gd:398`). The catalogue is the one literal; the
alias is a `const` referencing it. If the engine refuses that const reference,
keep the literal in `ShipFit.MODULES` and have `ModuleCatalog.MODULES` reference
*it* instead — either direction is fine as long as **exactly one literal exists**,
and W1's report states which direction shipped and why.

Icon rule: `assets/icons/module/icon_module_<id>_48.png` for every id except the
five base weapons, which use `assets/icons/weapon/icon_weapon_<family>_48.png`
(`w_laser`→`laser`, `w_cannon`→`cannon`, `w_rocket`→`rocket`, `w_mine`→`mine`,
`w_plasma`→`plasma`).

Name table (pin it in the catalogue; the six lineage rows keep doc 09's own words):

| id | name | id | name | id | name |
|---|---|---|---|---|---|
| `w_laser` | Laser MkII | `s_light` | Light Shield | `b_afterburner` | Afterburner |
| `w_cannon` | Cannon MkI | `s_heavy` | Heavy Shield | `b_fold` | Fold Drive |
| `w_rocket` | Rocket Pod | `s_ion` | Ion Shield | `u_cargo` | Cargo Expansion |
| `w_mine` | Mine Layer | `h_plate_light` | Light Plate | `u_salvage` | Salvage Tractor |
| `w_plasma` | Plasma Coil | `h_plate_heavy` | Heavy Plate | `u_refine` | Refinery Module |
| `w_railgun` | Railgun | `h_composite` | Composite Plate | `u_drones` | Repair Drone Bay |
| `w_mining` | Mining Laser | `c_target` | Targeting Computer | `u_tractor` | Tractor Array |
| `e_std` | Standard Drive | `c_scanner` | Deep Scanner | `u_holds` | Cargo Holds |
| `e_ion` | Ion Drive | `c_twin` | Twin Targeting | `p_std` | Standard Reactor |
| `e_vector` | Vector Drive | `c_ewar` | EWAR Suite | `p_mk2` | Reactor Mk2 |
| | | `c_nexus` | Nexus Computer | `p_core` | Reactor Core |

```gdscript
## autoload/player_profile.gd — additive beyond §8's pins.
func fit_for(ship_id: StringName) -> Dictionary   # slot_key -> Array[String] ("" = empty),
    # every type at its hull capacity, tail padded; {} only for an unknown hull id
func set_fit(ship_id: StringName, fit: Dictionary) -> bool
func set_fit_slot(ship_id: StringName, slot_key: StringName, index: int, module_id: StringName) -> bool
func clear_fit(ship_id: StringName) -> void
func base_module_id(entry: StringName) -> StringName   # instance id -> base id; the entry itself when unknown
func module_count(module_id: StringName) -> int
func add_module(module_id: StringName, count: int = 1) -> void
func take_module(module_id: StringName, count: int = 1) -> bool
```

- **Normalisation:** a v1–v3 file stores one string per slot type; `fit_for`
  returns it as a one-element array (padded to capacity) and never rewrites the
  file at load. Writes always persist the array shape. `SAVE_VERSION` 3 → 4,
  `MIN_READABLE_VERSION` stays 1, v1–v3 load clean.
- **Keys:** `_fits` is keyed by `String(ship_id)` in the shipped shape and its
  per-slot keys may be `String` or `StringName` (a loaded `ConfigFile` gives
  `String`). `fit_for`/`set_fit`/`set_fit_slot`/`clear_fit` accept a `StringName`
  hull id and a `StringName` slot key, read both spellings, and write the same
  spelling the file already used — `ShipFit._list_slot`'s tolerance is the model.
- **Signals:** `profile_changed(&"fits")` on a fit write, `&"modules"` on an
  inventory write. Both keys already exist.
- `base_module_id` resolves through the existing `_modules` dict (15 §6 instance
  shape) and returns its argument when the dict has no such instance — today's
  tests and fixtures store base ids directly and must keep working.

```gdscript
## game/player_state.gd — additive beyond §8's pin.
var weapons: Array[StringName]                  # the launched fit's weapon ids, W-slot order
func set_weapons(ids: Array[StringName]) -> void  # sizes ammo/ammo_max to ids, emits weapon_changed per slot
```

`const WEAPONS` stays (the five-family default a `PlayerState` built without a fit
still runs on) and `weapons` starts as its copy. `setup()`, `set_ammo` and
`game.gd:_seed_ammo`/`_file_ammo_report` read `weapons`, never `WEAPONS`. Ammo
stays **per family**: two fitted lasers draw both slots from the `laser` pack.

```gdscript
## ui/hud/hud.gd — additive beyond §7's pins.
func set_hull_slots(hull_id: StringName, cells: Array) -> void
    # cells: [{slot: &"weapons", index: int, module: StringName, icon: String,
    #          fitted: bool, selectable: bool}] — one per W cell, layout order
func hull_slots() -> Array          # read-back for probes
```

The weapon grid is rebuilt from `cells`: `columns = mini(cells.size(), 5)` (a
7-cell capital wraps to two rows), a cell whose `module` is empty draws the slot
glyph `icon_slot_w` dimmed, a fitted cell draws the module icon, `selectable` is
false for indices ≥ `GROUPS_MAX` (5, the input map's `weapon_1..5`). `bind`,
`_on_weapon_changed` and the ammo label path are unchanged: `weapon_changed`'s
`weapon_id` is still a family id.

```gdscript
## ui/components/slot_button.gd — additive.
func configure_cell(variation: StringName, icon: Texture2D, cell: Vector2,
                    icon_token: StringName = TOKEN_INACTIVE) -> void
```

`configure`'s signature and behaviour do not change; `configure_cell` sets an
explicit cell size, `ignore_texture_size = true`, no number.

Panel contracts (station):

- `ui/station/shipyard_panel.gd`/`.tscn`: `%HardpointSlots` becomes a
  **`GridContainer`** (`columns` = `ShipFit.grid_size(hull).x`), rebuilt per
  selection from `ShipFit.grid_cells(hull)`: a gap is an empty 48×48 `Control`
  with no plate; a slot cell is a 48 px `SlotButtonWeapon` plate carrying the
  slot glyph, `disabled` (it is a display). Caption
  `SLOT LAYOUT · %d CELLS · %d ENGINES` (`_hardpoint_caption`; `CELLS` = the
  hull's slot count, 08 §3's Total — gaps are not cells). `STAT_ROWS`
  becomes `hull, shield, cargo, engines, slots` (labels `HULL`, `SHIELD`,
  `CARGO`, `ENGINES`, `SLOT CELLS`), and the list-row meta
  (`META_FORMAT`, `:165`) becomes `"%d HULL · %d SLOTS"`.
- `ui/station/launch_panel.gd`: `BRIEF_ROWS` becomes
  `destination, hull_name, hull, shield, engines, hardpoints, slots, cargo, ammo`
  (labels `ENGINES`, `HARDPOINTS`, `SLOT CELLS`); the cargo plate strip and its
  five plates do not change.

## 4. Worker table

| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| **D0** | docs — land the pin | `docs/` | `docs/CONTRACTS.md` gains §11 **verbatim** from §3 of this brief (plus a `§10 Changelog` v0.2 line naming this wave). `docs/design/STATION_HUB.md`: **grep the file for every seven-plate / `hardpoints` reference** — §5.2's hardpoint-strip row and its `meta` row, §3.1's measurement note, §7.1's art-map row, §12's plate table and §13's verification note — and replace each with the layout-grid construct (a `GridContainer`, one cell per matrix cell, `columns` = the matrix width, gaps drawn empty) and the new stat/brief rows. `docs/design/STATION_SPEC.md` §4.2's "Four ships: fighter, vanguard, gunship, destroyer." becomes the nine-hull ladder; §4.1's ordering note keeps `PlayerState.WEAPONS` as the default list and adds that the live list is the launched fit's (`weapons`). `docs/design/IMPLEMENTATION_PLAN.md` gains **§9.10** (P2-A amendments, the house pattern of §9.7/§9.9): the §3.9/§3.10 amendments, the new files, and the pinned tests that move. `docs/gameplay/17_coder_handoff.md` §2 gains `game/module_catalog.gd` as built and §3's `fits` shape becomes `slot_type -> Array[module_instance_id]`. **No code, no gameplay numbers** — transcribe, never design. |
| **W1** | coder — the frame data | `vajb-orbit/game/ship_fit.gd,vajb-orbit/game/module_catalog.gd,vajb-orbit/tests/` | §3's `ShipFit` additions (grids, cells, counts, capacity, legality, standard fits, mount offsets, engine sum + ceiling, legacy `engine` acceptance) and the new `ModuleCatalog` (32 rows + the name table + the icon rule), with `ShipFit.MODULES` kept as the alias. New `tests/test_ship_grids.gd`: 08 §3.2's fenced block is parsed **out of the document** and equals `SLOT_GRIDS` hull by hull and row by row (spaces removed); counts equal 08 §3's table for all nine hulls (cell by cell); `HULLS[hull].weapons == grid_counts(...).weapons`; capacities sum to the totals 8/11/12/13/13/15/14/17/23; every `STANDARD_FITS` row is `fit_legal` on its own hull; a single engine resolves exactly as before; `e_vector`+`e_vector` is refused while `e_std`+`e_ion`+`e_vector` resolves to 1.40; unknown/NPC hulls return the empty shapes with no error. |
| **W2** | coder — profile fits | `vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/` | §3's profile API, the normalisation rule, `base_module_id`, the inventory helpers, save **v4** with v1–v3 loading clean, `profile_changed` keys. Update `tests/test_p1_profile.gd:204` (the version digit is now 4) and add fit round-trip / migration / addressing tests (a 3-engine hull's `engines` is three long, a v2 fixture's single-string fit normalises to one element and pads to capacity, a write persists the array shape). |
| **W3** | coder — the nine-hull roster | `vajb-orbit/game/station_catalog.gd,vajb-orbit/tests/` | `SHIPS` grows to all nine player hulls in 08 §2's ladder order (fighter, vanguard, miner, trader, corvette, freighter, gunship, patrol, destroyer) with the frozen cost/hull/shield/cargo, `hardpoints` = 08 §2's weapons column (2/3/2/1/4/1/5/4/7), `preview` = `res://assets/ships/ship_<hull>_side.png`, and a description in the existing voice. A test asserts nine rows, the ladder order, every preview path exists on disk, and `hardpoints` equals `ShipFit.HULLS[id].weapons`. |
| **W4** | coder — flight wiring | `vajb-orbit/game/game.gd,vajb-orbit/game/player_ship.gd,vajb-orbit/game/player_state.gd,vajb-orbit/tests/` | `_resolve_stats()` resolves the **active hull's own fit** (profile → base ids → `ShipFit.resolve`, falling back to `ShipFit.standard_fit(hull)`); `PlayerState.set_weapons` from the fit's W ids before `setup`; `_seed_ammo`/`_file_ammo_report` read `weapons`; a `_push_hull_slots()` that hands the HUD §3's `cells` array (built from `ShipFit.grid_cells` + the fit + `ModuleCatalog`). Tests: a Lancer's 2-W fit launches 2 weapon slots and a Vanguard's 3-W fit 3; a 3-engine hull's resolved speed is the summed set, not a product; ammo seeds per fitted family; the fallback fit path is exercised with an empty profile fit. |
| **W5** | coder — the layout consumers | `vajb-orbit/ui/station/shipyard_panel.gd,vajb-orbit/ui/station/shipyard_panel.tscn,vajb-orbit/ui/station/launch_panel.gd,vajb-orbit/ui/components/slot_button.gd,vajb-orbit/ui/hud/hud.gd,vajb-orbit/tests/test_ui_slot_layout.gd` | §3's shipyard layout grid, stat rows and meta; the launch brief rows; `SlotButton.configure_cell`; the HUD's `set_hull_slots` + `hull_slots`. Rewrite `tests/test_ui_slot_layout.gd`'s three pinned sections to the new numbers (the strip is the selected hull's grid with `columns` = its matrix width and one cell per non-gap cell; the HUD builds one cell per W cell of the hull, read from `ShipFit`, never a literal), keeping every D3 guard property intact: `ignore_texture_size` at every plate site, 48 px weapon / 40 px cargo cells, and **a 4096 px plate cannot grow a panel or the grid**. |
| **R1** | coder — reviewer (**mandatory**) | `vajb-orbit/tests/,vajb-orbit/tools/` | Verify, never trust. Re-derive every count from 08 §3.2's matrices independently and compare with W1's `grid_counts` and 08 §3's table; re-run the gate and report the count it measured itself; re-measure each consumer (shipyard grid cells/columns per hull, HUD cells per hull, launch rows) from the shipped scenes; prove the engine sum/ceiling with its own probe and that a single engine matches the pre-wave figure; drive a v2 and a v3 fixture through the new profile and confirm no data loss and no warning; grep the §2/§3/§7 pins plus §11 across every changed file. Check explicitly that no 08 §3.2 matrix was "tidied", no number moved outside 08 §3's △ rows, and that `assets/**`, the theme, `project.godot` and `docs/**` are untouched by code workers. Tier HIGH/MED/LOW with a reproducing command and raw output each. LOW → `.agents/gen/LOW_BACKLOG.md`. |
| **F1** | coder — fixer | per-finding sets from R1's report | Only R1's HIGH/MED findings, one pass, each re-measured before and after with R1's own command. |

Run order: **D0 first** (the pin must exist before anyone codes against it) →
**W1 · W2 · W3 in parallel** → **W4 · W5 in parallel** → **R1** → **F1** only if R1
leaves HIGH or MED.

## 5. Tests that move (named, sanctioned, and only these)

- `tests/test_ui_slot_layout.gd` — the three pinned sections in §4's W5 row.
  `HARDPOINT_CELLS := 7` is no longer a constant of the panel: the grid's cell
  count and `columns` come from the selected hull's matrix, so the test reads
  them from `ShipFit` instead of a literal.
- `tests/test_p1_profile.gd:204` — `save_version` 3 → 4.
- Nothing else moves. A test is never edited to hide a failure; the gate count
  **grows** (the last recorded figure is **236**, measured after the
  combat-repair wave — measure yours, never assume).

## 6. Hard rules

- `VAJB_WORKER_FILES` exactly as tabled; the PreToolUse hook denies writes outside
  it (and denies absolute paths on this host — use workspace-relative paths).
- Bounded Godot runs only (`--quit-after N`, stdout to a log the worker reads).
  Probe hygiene (L17): a probe that repoints `PlayerProfile.save_path` must
  stop/flush the 0.5 s debounce before restoring it.
- The gate is `godot --headless --path vajb-orbit res://tests/headless_runner.tscn
  --quit-after 1200`. It must be green after every worker, and its count must
  never shrink.
- No `assets/**`, no theme (`ui/theme/vajb_theme.tres`, `tools/build_theme.gd`),
  no `project.godot`, no `addons/**`; `docs/**` belongs to D0 only.
  `docs/gameplay/18_engine_spec.md` is owner-locked — nobody edits it, and this
  wave changes no §13 row.
- A load failing only on a missing sprite/texture path is *environment-deferred*,
  not a finding.
- **Do not add gameplay numbers.** Every count, cost, draw, effect and ceiling in
  this wave is already written in 08 §3/§3.1/§3.2, 09 §1–§9 or this brief. A
  worker who believes a number is wrong says so in the report and leaves it.

## 7. Staged, not in this wave (so nobody "helpfully" does it here)

1. **Mount-anchor consumption in flight** (09 §8, 08 §3.3). The data and
   `ShipFit.mount_offset` land now; the consumption is the feel wave's, because
   that wave already owns weapon firing geometry. Its spec, to execute verbatim
   when it lands: `game/weapons.gd` takes a muzzle anchor per W index from
   `ShipFit.mount_offset(hull_id, &"weapons", i)` scaled by the hull sprite's
   half-extents and rotated by the hull's rotation, fires from that point instead
   of `global_position`, and falls back to the ship centre when the hull has no
   grid (an NPC) — with a probe proving the same fit lands the same damage from
   either origin.
2. **The fitting panel (wave P2-B).** Installing/removing modules from the
   inventory, the power meter and the overload refusal, the module shop, and the
   legacy UPGRADES retirement flag day (10 §5) are P2-B's, briefed after this
   wave's review. This wave only makes the frames, the fits, the catalogue and
   the displays real.
3. **`weapon_6`/`weapon_7` in the input map.** A 7-W hull's last two cells are
   fitted but not selectable while `GROUPS_MAX` is 5 and the input map offers
   `weapon_1..5`. Extending the map is a `project.godot` change and therefore the
   owner's (see §8); wave A draws those cells `selectable: false` and says so.
4. **NPC fits.** NPC hulls stay outside `SLOT_GRIDS`; an NPC never fits a module
   in v1.

## 8. Owner ticks (block nothing in this wave; each is a one-line decision)

1. **The △ rows** of 08 §3/§2: engine counts 1/2/3 by mass band, the armour
   counts (1–4), and the three weapons moves (Lancer 3→2, Vanguard 4→3,
   Spearhead 3→4). Reversal path is in 08 §3's amendment note.
2. **09 §7's mandatory-set delivery** (every hull arrives with `e_std` × E and
   `p_std`): the alternative is an auto-fit on launch, which would write the
   profile from the flight scene.
3. **`ENGINE_MULT_CEILING` 1.40** and the no-duplicate-engine rule (09 §3.7).
4. **`MOUNT_SPREAD` `(0.34, 0.22)`** — the fraction of the hull's half-extents the
   grid covers, one constant for all nine hulls (09 §8).
5. **The input map's five weapon groups** vs a 7-W capital (§7 item 3).
6. **The layout displays' wording** (`SLOT LAYOUT · n CELLS · m ENGINES`,
   `SLOT CELLS`) — cosmetic, and the panels' spec is D0's.

**Resolution record (2026-09-21): all six kept as designed.** Each item was
re-proved against the amended docs before ticking (the nine matrices parsed and
compared with §3's table; §13's masses mapped onto §3.1's bands; the §3.7
arithmetic; §8's formula read against its one constant; `project.godot`'s
`weapon_1..5` against `weapons.gd:134`'s `GROUPS_MAX`):

1. **The △ rows — kept.** All nine engine counts derive exactly from the §13
   mass bands (80/90/110 → 1, 140/160/190/220 → 2, 260/300 → 3; no hull in a
   gap), armour spans 1–4, and the three weapons moves are the owner's request
   restated. Reversal remains 08 §3's amendment note.
2. **Mandatory-set delivery — kept** (09 §7). The alternative (auto-fit on
   launch) would write the profile from the flight scene; §9's `STANDARD_FITS`
   already covers the fitless fallback with the mandatory set.
3. **`ENGINE_MULT_CEILING` 1.40 + no-duplicate rule — kept.** The arithmetic is
   exact: `e_std`+`e_ion`+`e_vector` = 1.40, a single engine resolves to the
   pre-amendment figure, and `turn_mult` stays unclamped.
4. **`MOUNT_SPREAD` (0.34, 0.22) — kept** as the one constant for all nine
   hulls; it is normalised, so the feel wave can re-tune it with no data change,
   and that wave's same-origin probe is where the anchors get measured against
   the art.
5. **Five weapon groups vs the 7-W capital — kept for this wave.** Cells 6–7
   fit and display but ship `selectable: false`; extending the input map
   (`weapon_6`/`weapon_7`) is an owner `project.godot` edit, queued as a
   follow-up — the capital's last two guns stay display-only until it lands.
6. **Layout captions — kept as specced, count pinned:** `SLOT LAYOUT ·
   n CELLS · m ENGINES` with `n` = the hull's slot count (08 §3's Total,
   non-gap cells) and `m` its E count; `SLOT CELLS` is the same `n`.

## 9. Close-out (orchestrator)

Gate re-run (record the measured count); `python3 staging/verify_wave.py verify
--baseline p2a_start --forbidden project.godot --expect-reports
<the wave's reports> --tests`; `.agents/gen/WAVEBOARD.md` updated (this wave Done
with its report paths, P2-B queued behind it, the owner ticks recorded as resolved);
wave-boundary commit; report to the owner with the measured gate count, the
per-hull grid table as implemented, the tests that moved, and R1's findings by
tier. **Snapshot + commit before the first dispatch**, per the standing wave rule.
