# P2-A — W4 report: the flight wiring (the launch's own fit, the live weapon slots, the HUD's W cells)

**Worker:** W4 (coder, flight wiring). **Wave:** P2-A ship slot frames.
**Brief (law):** `.agents/gen/p2a_slot_frames_wave_task.md` §3 (the pin) + §4 row W4 + §5 + §6 + §10 item 1.
**File set (`VAJB_WORKER_FILES`):** `vajb-orbit/game/game.gd`,
`vajb-orbit/game/player_ship.gd`, `vajb-orbit/game/player_state.gd`,
`vajb-orbit/tests/`.
**Status:** complete. The gate is green and grown (**353 → 370**, `failed=0`, exit 0);
every pinned item of §3 is implemented; **no** `assets/**`, no theme, no
`project.godot`, no `addons/**`, no `docs/**`.

---

## 1. Files changed

| File | Change |
|---|---|
| `vajb-orbit/game/game.gd` | +168 / −24. `ModuleCatalogScript` preload; `_launch_hull`/`_launch_fit`; `_resolve_stats` resolves the active hull's own fit through `_launch_fit_for` → `_profile_fit` → `_base_module_id`; `_launch_weapons`; `_ready` calls `_state.set_weapons` before `setup`; `_spawn_ship` uses `_launch_fit` + `set_hull_id`; `_ammo_seed` is per slot; `_seed_ammo`/`_file_ammo_report` read `_state.weapons`; `_push_hull_slots` + `_hull_slot_cells`, called from `_bind_hud`. |
| `vajb-orbit/game/player_state.gd` | `var weapons` (starts as `WEAPONS.duplicate()`); `set_weapons(ids)`; `_resize_ammo()`; `setup` and `set_ammo` read `weapons`. `const WEAPONS` is untouched. |
| `vajb-orbit/game/player_ship.gd` | `var _hull_id` + `set_hull_id(hull_id)` (additive seam, §4 below); `thruster_anchors()` returns one point per engine cell via `ShipFit.mount_offset`, with `_engine_anchor`/`_tail_anchor` helpers (brief §10 item 1). |
| `vajb-orbit/tests/test_p2a_launch_fit.gd` | **new** suite, **12** tests (§5). |
| `vajb-orbit/tests/probe_p2a_w4_launch.gd` + `.tscn` | **new** evidence probe (§3). |
| `vajb-orbit/tests/test_engine2_wiring.gd` | **2-line** update of one stale loop (§6, deviation 1). |
| `.agents/gen/p2a_w4_report.md`, `.agents/gen/p2a_w4_probe.txt`, `.agents/gen/p2a_w4_gate.txt`, `.agents/gen/p2a_w4_lint.txt` | this report and its raw captures. |

`.uid` sidecars for the two new test files are written by the editor's filesystem
watcher, as for every other script in the project.

## 2. What was built, item by item

| Brief §4 row W4 deliverable | Where | Measured |
|---|---|---|
| `_resolve_stats()` resolves the **active hull's own fit** | `game.gd:320` (`_resolve_stats`) → `:337` (`_launch_fit_for`) → `:351` (`_profile_fit`) → `:382` (`_base_module_id`) | probe rows 1–9; `fits={}` on the owner's own profile, so every one of them is the fallback path |
| profile → base ids → `ShipFit.resolve` | `_profile_fit` maps every entry through `PlayerProfile.base_module_id`, keeps `power` one id, keeps the hull's padded array shape | probe "a stored fit with an instance id": `mod_0007` → `w_cannon` |
| falls back to `ShipFit.standard_fit(hull_id)` | `_launch_fit_for` | probe rows 1–9; test `test_a_fit_that_holds_nothing_falls_back_to_the_standard_fit` |
| never writes the profile from the flight scene | nothing in the launch calls a profile writer | probe `store after launch unchanged=true`; test `test_the_launch_reads_the_profiles_fit_through_the_base_ids` |
| `PlayerState.set_weapons` from the fit's W ids **before** `setup` | `game.gd:235` then `:236` (`player_state.gd:126` is the method) | test `test_a_player_state_built_without_a_fit_keeps_the_five_family_default` |
| `_seed_ammo` / `_file_ammo_report` read `weapons` | `game.gd:1242` / `:1214` | probe rows 1–9; tests `test_the_ammo_packs_seed_per_fitted_family`, `test_two_slots_of_one_family_file_their_deltas_once` |
| `_push_hull_slots()` built from `ShipFit.grid_cells` + the fit + `ModuleCatalog` | `game.gd:1377`/`:1390`, called from `_bind_hud` behind `has_method` | probe `HUD cells=` rows; tests `test_the_hud_receives_the_hulls_own_weapon_cells`, `test_a_capitals_last_two_cells_display_without_a_key` |
| tests: Lancer 2-W / Vanguard 3-W / 3-engine sum / ammo per family / empty-fit fallback | `tests/test_p2a_launch_fit.gd` | 12/12 pass |
| brief §10 item 1: `thruster_anchors()` one point per engine cell | `player_ship.gd:360` | probe `anchors=` column; test `test_the_thruster_anchors_are_one_per_engine_cell` |

## 3. The resolved numbers, per hull (raw probe output)

Re-runnable with:

```text
~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_p2a_w4_launch.tscn
```

Raw capture: `.agents/gen/p2a_w4_probe.txt` (42 lines, verbatim below). The profile is
the shipped autoload, borrowed for the run: its `save_path` is repointed at
`user://probe_p2a_w4_launch.cfg`, the four fields a launch reads are snapshotted and
handed back, the store is flushed on the scratch path, and the scratch file is removed
(L17). Every row is the **fallback** path (`_fits = {}`), which is exactly the state the
owner's own `profile.cfg` is in (`fits={}`, `active_ship="ship_fighter"`).

```text
[w4] probe=p2a_w4_launch hulls=9
[w4] module->family w_laser->laser, w_cannon->cannon, w_rocket->rocket, w_mine->mine, w_plasma->plasma, w_mining->
[w4] GROUPS_MAX=5
[w4] --- the standard-fit fallback, hull by hull ---
[w4] ship_fighter    grid=4x3 E=1 W=2 | fit.weapons=[&"w_laser", &"w_laser"] | slots=[&"laser", &"laser"] ammo=[300, 300] | engines=[&"e_std"] | speed=427.5000 (base 450.0) turn=1.7000 | anchors=1
[w4]   HUD cells=2 selectable=2 payload=[{0:w_laser}, {1:w_laser}]
[w4] ship_vanguard   grid=4x4 E=1 W=3 | fit.weapons=[&"w_laser"] | slots=[&"laser"] ammo=[300] | engines=[&"e_std"] | speed=406.6000 (base 428.0) turn=1.5000 | anchors=1
[w4]   HUD cells=3 selectable=3 payload=[{0:w_laser}, {1:-}, {2:-}]
[w4] ship_miner      grid=4x4 E=2 W=2 | fit.weapons=[] | slots=[] ammo=[] | engines=[&"e_std", &"e_std"] | speed=338.0000 (base 338.0) turn=1.0000 | anchors=2
[w4]   HUD cells=2 selectable=2 payload=[{0:-}, {1:-}]
[w4] ship_trader     grid=4x4 E=2 W=1 | fit.weapons=[] | slots=[] ammo=[] | engines=[&"e_std", &"e_std"] | speed=383.0000 (base 383.0) turn=1.2000 | anchors=2
[w4]   HUD cells=1 selectable=1 payload=[{0:-}]
[w4] ship_corvette   grid=4x4 E=1 W=4 | fit.weapons=[] | slots=[] ammo=[] | engines=[&"e_std"] | speed=495.0000 (base 495.0) turn=1.6000 | anchors=1
[w4]   HUD cells=4 selectable=4 payload=[{0:-}, {1:-}, {2:-}, {3:-}]
[w4] ship_freighter  grid=4x5 E=3 W=1 | fit.weapons=[] | slots=[] ammo=[] | engines=[&"e_std", &"e_std", &"e_std"] | speed=293.0000 (base 293.0) turn=0.7500 | anchors=3
[w4]   HUD cells=1 selectable=1 payload=[{0:-}]
[w4] ship_gunship    grid=4x5 E=2 W=5 | fit.weapons=[] | slots=[] ammo=[] | engines=[&"e_std", &"e_std"] | speed=360.0000 (base 360.0) turn=0.9500 | anchors=2
[w4]   HUD cells=5 selectable=5 payload=[{0:-}, {1:-}, {2:-}, {3:-}, {4:-}]
[w4] ship_patrol     grid=4x5 E=2 W=4 | fit.weapons=[] | slots=[] ammo=[] | engines=[&"e_std", &"e_std"] | speed=383.0000 (base 383.0) turn=1.0500 | anchors=2
[w4]   HUD cells=4 selectable=4 payload=[{0:-}, {1:-}, {2:-}, {3:-}]
[w4] ship_destroyer  grid=5x6 E=3 W=7 | fit.weapons=[] | slots=[] ammo=[] | engines=[&"e_std", &"e_std", &"e_std"] | speed=315.0000 (base 315.0) turn=0.8000 | anchors=3
[w4]   HUD cells=7 selectable=5 payload=[{0:-}, {1:-}, {2:-}, {3:-}, {4:-}, {5:-!}, {6:-!}]
[w4] --- the engine set on ship_freighter (base speed 293.0, base turn 0.7500) ---
[w4] [&"e_std"]                         sum=1.0000 product=1.0000 | launched speed=293.0000 (x1.0000) turn=0.7500 (x1.0000) | legal=false
[w4] [&"e_std", &"e_ion"]               sum=1.1500 product=1.1500 | launched speed=336.9500 (x1.1500) turn=0.7500 (x1.0000) | legal=false
[w4] [&"e_std", &"e_ion", &"e_vector"]  sum=1.4000 product=1.4375 | launched speed=410.2000 (x1.4000) turn=0.9000 (x1.2000) | legal=true
[w4] [&"e_vector", &"e_vector"]         sum=1.5000 product=1.5625 | launched speed=410.2000 (x1.4000) turn=1.0500 (x1.4000) | legal=false
[w4] --- a stored fit with an instance id ---
[w4] stored fit    = { "ship_vanguard": { "engines": ["e_std"], "weapons": ["mod_0007", "w_laser", "w_rocket"], "shields": ["s_light"], "armour": ["", ""], "computers": [""], "boosters": [""], "utility": [""], "power": "p_std" } }
[w4] launched fit  = { &"engines": [&"e_std"], &"weapons": [&"w_cannon", &"w_laser", &"w_rocket"], &"shields": [&"s_light"], &"armour": [&"", &""], &"computers": [&""], &"boosters": [&""], &"utility": [&""], &"power": &"p_std" }
[w4] live slots    = [&"cannon", &"laser", &"rocket"] ammo=[300, 300, 300]
[w4] HUD payload   = [{0:w_cannon}, {1:w_laser}, {2:w_rocket}]
[w4] icon(w_laser)=res://assets/icons/weapon/icon_weapon_laser_48.png exists=true
[w4] store after launch unchanged=true (instance id still stored=mod_0007)
[w4] --- a W cell that is the mining tool ---
[w4] fit.weapons=[&"w_mining", &"w_laser"] live slots=[&"", &"laser"] ammo=[0, 300] mounts_laser=true
[w4] --- the owner gate's two symptoms ---
[w4] active hull=ship_fighter mounted=[&"laser", &"laser"] slots=2 total_rounds=600 (was five families / 1500)
[w4] scratch removed=true
```

Readings worth stating as numbers:

- **The Lancer (the owner's active hull) launches its own fit**: `fit.weapons =
  [w_laser, w_laser]`, live slots `[laser, laser]`, `ammo = [300, 300]` → **2 weapon
  slots / 600 rounds**, where the pre-wave launch resolved the Vanguard's row on a
  Fighter hull and reported the five fixed families / 1500 rounds.
- **The Cutter launches one weapon** on 09 §9's row (1 of its 3 W cells) and shows all
  **3 cells** in the HUD grid, two of them unfitted; a stored three-weapon fit launches
  **3** live slots.
- **Engine counts are the grid's**: anchors 1 / 1 / 2 / 2 / 1 / 3 / 2 / 2 / 3 for
  Fighter→Destroyer, equal to each hull's E count (08 §3).
- **The summed set**: on the Mule's 293.0 base, `[e_std, e_ion, e_vector]` resolves
  **410.2000** (×1.4000, the ceiling) where the pre-amendment product is 1.4375
  (×1.4375 = 421.2), and the turn multiplier rides to **0.9000** (×1.2000, unclamped).
  A single `e_std` is byte-identical to the shipped figure (293.0 / ×1.0000).
- **A 7-W capital** pushes 7 cells with **5 selectable** (`{5:-!}`, `{6:-!}`).
- **`grid_cells` drives the grid**: the cells' count per hull is 2 / 3 / 2 / 1 / 4 / 1
  / 5 / 4 / 7, exactly 08 §3's W column, read from `ShipFit`, never a literal.

## 4. Decisions the pin left open (each reported, none of them a new number)

1. **"the profile holds none" means "no fitted cell at all"**, not "no stored row".
   `PlayerProfile.fit_for` answers an all-empty shape at capacity for a known hull with
   nothing stored (W2 report §2 item 2), so `_profile_fit` returns `{}` when the mapped
   fit holds no non-empty entry, and `_launch_fit_for` then hands back
   `ShipFit.standard_fit(hull)`. Both the fresh-account case and the stored-but-empty
   row are therefore the fallback, and both are asserted. **An unknown hull id never
   reaches the fit lookup**: `_resolve_stats` already replaces anything outside
   `ShipFit.HULLS` with `HULL_ID_DEFAULT` (that guard is the pre-wave code, unchanged),
   so the fallback hull is always one of the nine and `standard_fit` can never answer
   `{}` on the launch path.
2. **The launched fit keeps the profile's padded array shape** (every list type at the
   hull's capacity, `power` one id). That is what `fit_for` hands out and what
   `ShipFit.resolve` already reads; re-compacting it would be a second normalisation
   with no reader. The probe shows the shape.
3. **`_launch_weapons` maps module ids to families and drops empty cells.** `weapons`
   is `PlayerState`'s slot list and `weapon_changed`'s payload must be a *family* id
   (CONTRACTS §11), while the fit stores module ids (`w_laser`) and the ammo packs are
   keyed by family (`laser`): `Weapons.weapon_id` is the one bridge, and an unfitted
   cell contributes nothing. A fitted cell whose module has **no** firing family
   (`w_mining`, the tool that shares the W column) keeps its slot with the empty family
   `Weapons.weapon_id` answers — measured: `[w_mining, w_laser]` → `["", "laser"]`,
   `ammo=[0, 300]`, `mounts_laser=true`. Reversal: drop the entry instead (then a hole
   in the fit misaligns the HUD's cell index from the slot index — see item 5).
4. **`player_ship.gd` gains one additive seam: `set_hull_id(hull_id)`.** The engine
   cells' mount anchors are hull-local geometry (`ShipFit.mount_offset` needs a hull
   id) and `ShipStats` carries no hull id, so `game.gd` hands the hull over beside
   `setup`. `setup`'s pinned signature is untouched; a hull that never receives one
   (`&""`) is the "no grid" case and keeps the shipped single tail anchor. Reversal:
   thread the id through a new defaulted `setup` parameter instead (a change to a
   pinned signature, which is why it was not done here).
5. **The thruster anchor's axis mapping.** `mount_offset` returns the cell's normalised
   position in the *matrix's* frame (col → x, row → y), and FX_SPEC §1.3 only says "the
   hull's engine cells". 08 §3.2 reads the matrix as the hull from above with "engines
   and the reactor sit in the tail", so the row fraction is taken as the hull's
   longitudinal axis: `x = -radius * TAIL_ANCHOR_FRACTION * (o.y / MOUNT_SPREAD.y + 0.5)`,
   `y = o.x * radius`. Both numbers are shipped constants (no new one), the recovery of
   the row fraction is exact, and the nozzle lands at 0.46–0.50 × the art-derived radius
   behind the centre — i.e. where the shipped single tail point (0.55 ×) was, now one
   point per cell. Reversal: use `mount_offset` verbatim as `(x, y)`; the feel wave's
   art measurement (owner tick 4) is where this gets settled either way.
6. **`_ammo_seed` became a per-slot `Array[int]`** (it was a family-keyed `Dictionary`).
   With two cells of one family the dictionary could hold only one seed, so the second
   cell's fired delta was silently lost; per slot, each cell files its own delta against
   the one pack its family owns and the pack pays their sum (asserted:
   `test_two_slots_of_one_family_file_their_deltas_once`). Reversal: key by family
   again, and lose the duplicate-family case.
7. **An open seam for P2-B, reported rather than fixed.** `PlayerState.weapons` is the
   *fitted* list, while the HUD's grid is one cell per W cell, so the two indices line
   up while the fit fills a **prefix** of the cells — which every standard fit and every
   auction fit does. A fit with a *hole* (unfitted cell before a fitted one), which only
   P2-B's fitting panel can create, would leave `game.gd:_select_weapon` addressing the
   wrong slot, and `Weapons.set_fitted`'s own de-duplication is a second, independent
   mismatch on the same path. Neither is reachable from the launch path this wave
   changes; `game/weapons.gd` is outside this worker's file set.

## 5. The suite that moves the gate

`tests/test_p2a_launch_fit.gd` — **12 tests**, all passing (`.agents/gen/p2a_w4_gate.txt`):

| Test | Assertion |
|---|---|
| `test_a_lancer_launches_its_two_weapon_fit` | the Fighter's grid carries 2 W cells, the Lancer's standard fit fills both, `weapons == [laser, laser]`, `ammo.size() == 2`, 2 HUD cells |
| `test_a_vanguard_launches_a_three_weapon_fit` | a stored `[w_laser, w_cannon, w_rocket]` fit → `[laser, cannon, rocket]`, 3 slots, 3 cells |
| `test_the_standard_fit_fills_only_the_cells_it_names` | the shipped Vanguard row fills 1 of 3 cells: `weapons == [laser]`, 3 cells, cell 0 fitted, 1–2 empty |
| `test_a_three_engine_hull_sums_its_engines_and_clamps_at_the_ceiling` | Mule: 3 E cells; `max_speed` == base × `ENGINE_MULT_CEILING` (±0.01), ≠ base × 1.4375, `turn_rate` == base × 1.20 |
| `test_a_fit_that_holds_nothing_falls_back_to_the_standard_fit` | no stored fit → `standard_fit(Lancer)` + 2 slots + `fits() == {}`; a stored-but-empty row → `standard_fit(Vanguard)` + 1 slot |
| `test_the_launch_reads_the_profiles_fit_through_the_base_ids` | `mod_0007` → `w_cannon` in the resolved fit, still `mod_0007` in the store, `fits()` unchanged, the live slot reads `cannon` |
| `test_the_ammo_packs_seed_per_fitted_family` | packs 111/222 → `ammo == [111, 222]`; a two-laser fit → `[111, 111]` from the one laser pack |
| `test_two_slots_of_one_family_file_their_deltas_once` | two laser slots fire 3 and 5 → the pack pays 8 once, and a repeat report is inert |
| `test_the_hud_receives_the_hulls_own_weapon_cells` | 3 cells, layout indices 0/1/2, `module`/`icon` per `ModuleCatalog.icon_path`, unfitted cell empty, HUD read-back behind `has_method` |
| `test_a_capitals_last_two_cells_display_without_a_key` | 7 cells, `selectable == (index < GROUPS_MAX)` for every one |
| `test_the_thruster_anchors_are_one_per_engine_cell` | Mule → 3 anchors (== the grid's E count), each behind the centre; an NPC hull → 1 tail point, `slot_capacity == 0` |
| `test_a_player_state_built_without_a_fit_keeps_the_five_family_default` | `weapons == WEAPONS`, `setup` → 5 packs, `set_weapons([laser, laser, cannon])` → 3 packs + one announcement per slot, `set_ammo` writes and announces the launched slot, `WEAPONS.size()` still 5 |

## 6. Deviations (each one stated, none hidden)

1. **`tests/test_engine2_wiring.gd:260-269` was updated (2 lines) — not named in §5.**
   Its loop read `_state.WEAPONS.size()` (5) and indexed `_state.ammo`, which is now
   sized to the launched fit: it produced a hard
   `SCRIPT ERROR: Invalid access of index '2' on a base object of type: 'Array[int]'`
   on every hull whose fit carries fewer than five weapons (measured on the owner's
   Lancer: `ammo.size() == 2`). The test's *intent* (every live pack follows the
   profile's store) is unchanged; the loop now reads `weapons` and asserts
   `ammo.size() == weapons.size()` first, which keeps it non-vacuous for a fit with no
   guns. Leaving it would have put a new `SCRIPT ERROR` in the gate log. This is the
   only test outside §5's list that moved, and it is the only way the gate stays green.
2. **`player_ship.gd:set_hull_id` is a new additive method** on a pinned class — see
   §4 item 4.
3. **`game.gd:_ammo_seed` changed type** (`Dictionary` → `Array[int]`) — see §4 item 6.
   No other file reads it (checked by grep; `test_engine2_dock.gd:6` mentions it in a
   comment only).
4. **`_resolve_stats` now stores the launch's hull and fit** in `_launch_hull`/
   `_launch_fit`, which `_spawn_ship`, `_launch_weapons` and `_push_hull_slots` read.
   Purely additive state on the scene; nothing else writes either.

## 7. The gate, the lint ledger, and the wave's own gate

```text
godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
```

- **Baseline measured by this worker before the first edit: `passed=353 failed=0`.**
- **After: `passed=370 failed=0`, exit 0** (`.agents/gen/p2a_w4_gate.txt`). The growth
  is this worker's **12** (`p2a_launch_fit`) plus the 5 W5 added to
  `test_ui_slot_layout` (7 → 12) as it landed in parallel.
- The log's **one** `SCRIPT ERROR` is the pre-existing
  `Cannot call method 'call' on a previously freed instance.` at
  `tests/test_weapon_fx_f4.gd:176` (`.agents/gen/LOW_BACKLOG.md` L61, owed to that
  file's next owner); the file is unmodified and the test passes. **No new
  `SCRIPT ERROR`**, and the two `GridContainer` errors a mid-flight W5 had produced are
  gone now that W5 finished.
- **Lint ledger** (`--headless --debug`, `.agents/gen/p2a_w4_lint.txt`): 43 warnings,
  **zero** attributed to `game.gd`, `player_state.gd`, `player_ship.gd`,
  `test_p2a_launch_fit.gd` or `probe_p2a_w4_launch.gd`; the attributed files are
  pre-existing (`speed_fantasy.gd`, `npc_ship.gd`, `npc_brain.gd`, `target_reticle.gd`,
  `minimap.gd` and older suites). `passed=370 failed=0` under `--debug` too.

## 8. The owner's launch-fit gate, measured

`WAVEBOARD.md` records the gate as *"the briefing reports five weapons / 1500 rounds
while the ship mounts `[w_laser]` and no mining laser — the measured root cause of
'shooting is not working' and 'cannot shoot asteroids'"*.

| Symptom | Before (this worker's own baseline read of the code) | After (probe, owner's own profile: `fits={}`, `active_ship="ship_fighter"`) |
|---|---|---|
| weapon count | five fixed families (`WEAPONS`), regardless of the hull | **2** — the Lancer's `[w_laser, w_laser]` |
| rounds | 5 × 300 = **1500** | **600** — `ammo == [300, 300]`, both drawn from the `laser` pack |
| the mount | `ShipFit.fitted_ids(ShipFit.STANDARD_FIT)` — the Vanguard's row on any hull | `ShipFit.fitted_ids(_launch_fit)` — the launched hull's own fit (`w_laser` ×2 on the Lancer) |

Both symptoms are **closed** for the launch side of the gate. The mining-laser half is
`_fit_ids`' own gate (09 §4.5) and is unchanged in shape: a fit that carries no
`w_mining` still mounts no laser, and the probe shows a fit that does carry it mounting
one (`mounts_laser=true`). The panels' half of the gate is W5's (the briefing's rows and
the shipyard's grid); the orchestrator's re-measure of the two symptoms end to end
belongs to the wave close-out.

## 9. What this worker did not touch

`assets/**`, `ui/theme/vajb_theme.tres`, `tools/build_theme.gd`, `project.godot`,
`addons/**`, `docs/**` and `docs/gameplay/18_engine_spec.md` are all untouched by this
worker. The working tree also carries the other P2-A workers' files (W1's
`ship_fit.gd`/`module_catalog.gd`, W2's `player_profile.gd`, W3's `station_catalog.gd`,
W5's `ui/**`, D0's `docs/**` and the designer lane's `WAVEBOARD.md`/
`dispatch_designer.md`) because W4 and W5 ran in parallel and the wave is not committed
yet; this worker's own set is exactly `game.gd`, `player_ship.gd`, `player_state.gd`,
`tests/test_p2a_launch_fit.gd`, `tests/probe_p2a_w4_launch.gd`/`.tscn`,
`tests/test_engine2_wiring.gd` and this report's captures. No gameplay
number was invented: every count, engine figure, anchor constant and icon path in this
report is quoted from 08 §3, 09 §3.7/§8/§9, CONTRACTS §11, FX_SPEC §1.3 or a shipped
constant.
