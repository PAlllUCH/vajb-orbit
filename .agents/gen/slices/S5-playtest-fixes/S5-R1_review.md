---
slice: S5
worker: S5-R1
model: "deepseek/deepseek-v4-flash"
status: med            # 2 MED findings (one display, one dead test half); no HIGH
gate: "passed=577 failed=0, three runs on three scratch stores; live profile md5 unchanged"
---

# S5-R1 review — playtest fixes (commerce, consumables, batteries v2, hardpoints)

Reviewer `S5-R1`, wave `S5`, slice `S5-playtest-fixes`, 2026-09-24.
Brief: `.agents/gen/slices/S5-playtest-fixes/S5_BRIEF.md`. **Findings are diffed against the
pins, never against the brief**: `docs/CONTRACTS.md` §17/§13/§16/§9/§10,
`docs/design/STATION_HUB.md` §5.11 (+ §5.1/§5.2/§5.8/§5.10),
`docs/gameplay/10_ship_acquisition.md` §6.1, `docs/gameplay/09_ship_slots_modules.md` §11
(+ §3.1/§8/§10). Every number below was re-measured by the reviewer; the builders' suites
are cited as corroboration, never as proof.

## Verdict

**No HIGH.** Two **MED**, eleven **LOW** (backlog rows `L130`–`L140`). Every pinned
acceptance measures as pinned; no frozen file moved and no balance number moved. The wave
is fit to close after the two MED findings are dispositioned — neither is blocking (both are
display/test-side; the sim is correct), so a fixer pass is the orchestrator's call.

| Tier | Count | Where |
|---|---|---|
| HIGH | 0 | — |
| MED | 2 | `R1-MED-1` the HUD's ammo/label readout; `R1-MED-2` a dead test half |
| LOW | 11 | `L130`–`L140` in `.agents/gen/_state/LOW_BACKLOG.md` |

## Method (what the reviewer ran itself)

- **Gate, three times, three scratch stores** (`XDG_DATA_HOME=/tmp/s5r1_xdg{A,B,C}`), the
  canonical command:
  `$GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200`
  → **`[SUMMARY] passed=577 failed=0`**, exit 0, all three runs, identical counts; **577 PASS
  rows over 49 suites**. The live `~/.local/share/godot/app_userdata/Vajb Orbit/profile.cfg`
  md5 is `539de5b7af59c77b6bffc477413161da` before and after (the runner's own `_gate_scratch`
  sandbox, CONTRACTS §14). The error lines are the pre-existing ones: L61's
  `SCRIPT ERROR: … previously freed instance` at `tests/test_weapon_fx_f4.gd:178`,
  `ERROR: Parameter "data.tree" is null.` from the detached-hull plasma path (§9), and
  `test_p1_clock_log.gd`'s own `GDScript backtrace … economy_log.gd:28` from
  `test_unwritable_log_path_is_survivable` (it deliberately logs to an unwritable path; the
  row is green in every run). No new `SCRIPT ERROR`, no new failure.
- **`staging/verify_wave.py verify --baseline s5_start --forbidden vajb-orbit/project.godot
  docs/gameplay/18_engine_spec.md`** → `"problems": []`. Neither forbidden file is in
  `modified`/`added`/`deleted`; `vajb-orbit/project.godot`, `docs/gameplay/18_engine_spec.md`,
  `docs/gameplay/08_ship_slots_modules.md`, `assets/`, `addons/` and the theme are all
  untouched (the theme is absent from the modified list; `Ui_theme/vajb_theme.tres` is not
  named). `docs/design/STATION_HUB.md`'s S5 amendment was landed at `HEAD` before the
  builders ran and is not a wave edit.
- **The hardpoint table re-derived from the renders with the reviewer's own tool** (Pillow,
  independent of `tests/probe_s5_hardpoints.gd`): all nine hulls' `rear` arrays are
  **byte-identical** to `ShipFit.HARDPOINTS` (`fighter (-391.5,-71.2)·(-392.5,37.3)` …
  `destroyer` 4 anchors), and `left`/`right` match element-for-element modulo the round-half
  convention (Godot `round()` away-from-zero vs Python banker's; e.g. trader's 25 % column
  reads `-236.0` in the literal and `-237.0` in the banker's-round it; the difference is the
  rounding mode, not a moved value). `gunship`'s merged middle nozzle reads `-125.9` (literal)
  vs `-125.8` (recomputed) — one float in the merge mean. **`front` is derived differently**
  by the probe (the bow band's two ink extremes on the max-x column, so both anchors share an
  x); the reviewer's naive min/max-y reading differs there, which is a method difference, not
  a drift. Nozzle counts are the art's own (Mule 2, Gunship 3, Destroyer 4 — J4's disclosure
  1).
- **An independent probe suite** (written by the reviewer, run under `--suite`, then deleted;
  it exercised the same seams with the reviewer's own assertions):
  - the **mixed cannon+rocket rack** streams at `max(cadence)`: cannon salvos at frames
    `[0, 73, 145]` (gaps `73`, `72` at 1/60) against the rocket's 1.2 s = 72 frames, and the
    S4 per-barrel rule (36 frames) is excluded by a wide margin;
  - **per-barrel tracking**: after a 90° aim swing + 0.5 s, laser `1.571 rad (90.0°)`,
    rocket `0.524 rad (30.0°)` — the table's 180/60 ratio exactly;
  - the **beam cone**: `TRACK_TOLERANCE` 5.0, aligned while settled, `false` one frame after
    a 90° swing, `true` again after the barrel's own swing;
  - the **six ammo unit figures**: laser 4/2, cannon 6/4, rocket 40/24, mine 50/30, plasma
    64/38, railgun 24/14 (list/sale), and `fuel_cell` non-sellable and priced 0;
  - the **auto-load**: 30 laser units → 300 rounds, hold 0, a second call draws nothing;
    12 cannon units → 120;
  - the **v7 migration from a hand-built v6 `ConfigFile`**: after load `batteries()` =
    `{ship_vanguard: [[0, 2], [1]]}`, a second `migrate_batteries()` answers 0, the file is
    **still v6 with no `batteries` key** (memory-only), and one real write persists v7 with
    the racks on disk.

## MED findings

### R1-MED-1 — the HUD's ammo/label readout indexes a per-slot array with a rack ordinal

`ui/hud/hud.gd` resolves a selected **battery ordinal** into `PlayerState.ammo`, which is
indexed by **barrel position**, so on a rack whose ordinal is not its barrel's position the
readout shows another family's pack (or 0/0).

- `ui/hud/hud.gd:1122` `_active_slot = battery - 1` (in `select_battery`), then
  `:1128` `_ammo = _ammo_of(_active_slot)` / `_ammo_max = _ammo_max_of(_active_slot)`;
  `_ammo_of` (`:518-521`) reads `_state.ammo[slot]`.
- `game/player_state.gd:99` `var ammo: Array[int]` is one entry per **slot** (barrel), seeded
  by `game.gd:_seed_ammo` over `_state.weapons.size()`; while a rack is a list of
  **barrel positions** (`game.gd:_launch_batteries` → `_weapon_barrel_positions`).
- **Measured (reviewer probe, shipped `game.tscn`)**: a Vanguard fit W1 `w_laser`, W2
  `w_cannon`, W3 `w_rocket` with the record `[[1, 2], [0]]` mounts the component's racks
  `[[1, 2], [0]]` (rack 1 = cannon + rocket) and pushes the HUD cells
  `W1 battery=2`, `W2 battery=1`, `W3 battery=1`. With `state.ammo` set to
  `[111, 222, 333]` (laser/cannon/rocket), `hud.select_battery(1)` reads
  **`ammo=111`, `weapon=laser`** — the laser pack, while rack 1 fires the cannon and rocket.
  `WEAPON_IDS[0]` is also `&"laser"`, so the keyboard `weapon_1` path **names the wrong
  family** too.
- The cell-press path (`_on_weapon_slot_pressed`) overrides the **label** with the pressed
  cell's module, but not `_ammo`/`_ammo_max` (they were already set by `select_battery`), so
  even the cell path shows a mixed reading: a cannon label beside the laser's round count.
- A family-less W cell makes it worse: `w_mining`+`w_laser` on a Vanguard collapses the
  component's racks to `[[], [0]]`, so `weapon_2` re-reads `_state.ammo[1]`, which is past
  the one-element array → `0/0`.
- **Tier MED** because it is a wrong reading on the shipped surface for exactly the mixed
  batteries the owner asked for, and nothing in the wave tests it (`grep` for
  `select_battery`/`_ammo_of`/`_cell_battery` across `tests/` returns no hits). It is not a
  pin violation: §17 pins the W-slot buttons to battery ordinals and says nothing about the
  readout, so this is a decision inside the pinned acceptance (bucket 1) that reads wrong.
- Cure (the fixer's, one route): carry the pressed/selected barrel's **position** into the
  HUD (the `_hull_slot_cells` payload can carry it beside `battery`) and read
  `_state.ammo[position]`, or have `select_battery` take the rack's representative barrel.
  Reversal of the report: none needed if the owner accepts a rack-level readout — but then
  the label must not claim the cell's module.

### R1-MED-2 — `test_s5_batteries_v2.gd`'s HUD half never runs

`vajb-orbit/tests/test_s5_batteries_v2.gd:45` declares `const HUD_NODE: StringName = &"HUD"`,
and `:844` looks it up with that name. The HUD scene's root is **`Hud`**
(`vajb-orbit/ui/hud/hud.tscn:25`), and every other suite uses the right spelling
(`test_p2a_launch_fit.gd:28` `&"Hud"`, `test_engine2_wiring.gd:61` `NodePath("Hud")`). Godot
node paths are case-sensitive, so the lookup returns `null` and the guard at `:845`
(`if hud != null and hud.has_method(&"hull_slots")`) skips the four assertions at
**`:847-851`** — the only place the wave claims to measure that the HUD's pushed cells carry
the rack ordinal. **Measured**: the reviewer's probe mounted the same scene and printed the
node tree (`Game children […, Hud:<Control#…>, …]`); with `NodePath(&"HUD")` the lookup is
null, with `NodePath(&"Hud")` it answers and the cells read `battery` 1/2/0 exactly as the
test intends. So the test's `test_the_launch_hands_the_mounted_component_the_recorded_racks`
is **half dead**: its component-rack half (`:840-843`) runs, its HUD half does not, and the
gate is green either way.

- **Tier MED** because it is a claimed acceptance measurement that silently did not run —
  the false confidence is the whole reason this review exists.
- Cure: `HUD_NODE` → `&"Hud"` (one character). The fixer owns it; the reviewer does not fix.

## AC-by-AC (against the pins)

- **AC1 (auction family tabs, S3 arithmetic byte-identical).** `game/auction.gd` is
  untouched (`git log -1` = the S3 commit); the panel's diff is a tab strip plus one
  visibility pass (`auction_panel.gd:_apply_family`) that never re-prices, re-draws or drops
  a row, and `_rebuild` re-applies the tab after building. The ten tabs and their slot keys
  match §5.11, and `DRIVES` keys on the catalogue's own `engine` key (measured: the
  catalogue's module rows carry `engine` ×3, `weapons` 12, `shields` 5, `armour` 4, `power` 4,
  `computers` 7, `boosters` 3, `utility` 8 — so no tab renders empty), which is J0's F9 and
  the owner's disposition. `slot` is S3's own `Auction.listing_rows` key. **Holds.**
- **AC2 (shipyard = hangar; select previews; SET ACTIVE commits).** `_preview_row`
  (`shipyard_panel.gd:998-1003`) touches only the pane's own selection/readers and emits the
  shell hint; `_act` (`:1010-1023`) is the single `set_active_ship` call. `_build_rows`
  reads `_owned_roster` only; the buy path, price block and `FOR SALE`/`LOCKED` states are
  gone (J1's suite measures credits/owned/active/fits/modules/auction unchanged and **0**
  `profile_changed` on a select, and exactly one on the footer). **Holds.**
- **AC3 (ARMORY mixed batteries, slowest-cycle salvo, v7, no-write refusals).** The
  component-level rule is measured by the reviewer's own probe (see Method) and matches
  J3's. `battery_groups`/`set_battery_groups`/`fit_into_rack`/`clear_rack_cell`/
  `move_rack_cell` refuse before any write and roll the fit+bag+record back on a late
  failure (`player_profile.gd` batteries block); `migrate_batteries` is idempotent,
  memory-only at load and persisted by the next write (reviewer probe F). **Holds** — with
  the AC's "0.6 + 1.5 s" number underivable and recorded as **L132** (J3's own bucket-2
  finding, not a code defect), and R1-MED-1's readout caveat.
- **AC4 (ammo as cargo, auto-load once at launch, EXCHANGE 60 %, fuel-cell delist).** Six
  cargo ids + `ROUNDS_PER_CARGO_UNIT` 10 (`station_catalog.gd`), the railgun pack at the
  owner's 150/360/150, `AMMO_MAX` + railgun, `buy_ammo` → hold units, `load_ammo_from_hold`
  once per family at launch only (`game.gd:245` `_seed_ammo`, the sole production caller of
  `load_ammo_from_hold`), the third exchange book at 60 % with no demand/stock/queue movement,
  and no sale surface carrying `fuel_cell` (the only `fuel_cell` refs are `PlayerState`'s
  in-flight burn). All six figures and the auto-load re-measured by the reviewer's probe.
  **Holds** (the 10 CR commission floor and the last-unit overshoot are `L130`/`L131`).
- **AC5/AC6 (hardpoints measured, FX anchors, tracking, beam tolerance).** The nine rows
  re-derived byte-identically for `rear` (see Method); `thruster_anchors`/`thruster_frame`
  resolve to the map at the sprite's own scale with the §8 derivation kept intact as the
  fallback (`player_ship.gd:408-479,1392-1419`); tracking and the 5° cone re-measured by the
  reviewer's probe. **Holds**, with `L137` (the in-flight sprite is one texture) as the
  disclosed pre-existing limitation.
- **AC7 (gate green).** `passed=577 failed=0` ×3. **Holds.**

## No frozen file, no balance number

`vajb-orbit/project.godot` and `docs/gameplay/18_engine_spec.md` untouched (`verify_wave`
`problems: []`); likewise `08_ship_slots_modules.md`, `assets/`, `addons/`, the theme. No
`max_speed`/`accel_time`/`coast_time`/`turn_rate`/`turn_spinup`/`hull_mass`/damage/price line
moved (`git diff` on `ship_fit.gd`'s HANDLING and `weapons.gd`'s `FAMILIES` shows only the new
`track_dps` rows; `module_catalog.gd` untouched; `station_catalog.gd`'s only catalogue change
is the railgun pack row). `track_dps` is the pin's new column (owner tick owed, unchanged).

## J0 dispositions — resolved in the tree

- **F0 (the file-set hook denied absolute Linux paths): cured.** The untracked
  `.crush/hooks/enforce_worker_files.py` now strips the Linux workspace root
  (`ws = _WORKSPACE…; if p.startswith(ws)`), and the reviewer verified an absolute
  `/home/.../docs/CONTRACTS.md` target is allowed. Not a wave worker's change (no set
  contains `.crush/`), so it is recorded here rather than as a finding.
- **F9 (`DRIVES` keyed on a family name): resolved** — the tab keys on `engine`, the
  catalogue's slot word (measured 3 module rows).
- **F1/F2/F3/F4/F5/F6/F7/F8:** the owner's dispositions are implemented as §17's J0 block
  reads (batteries answer cell refs through the profile; `GROUPS_MAX` grew its consumers;
  the `ARMORY` label lives in `station.gd`; the ammo arithmetic lives in `exchange.gd`; the
  rows stay in ARMORY; the shipyard row carries no icon; §5.2 is superseded by §5.11;
  the railgun pack has its own numbers). §16 rule 3 carries the developer's supersession
  pointer to §17.
- The reviewer's `docs/CONTRACTS.md` edits: §9's expected count now leads with the measured
  **577** and the S5 per-suite arithmetic; §10 gains **v0.11** (this pass's findings, the
  independent measurements and the J0 closures). No pinned signature changed.

## LOW rows written (next free ids)

`L130` the ammo 10 CR commission floor (a 1-unit sale pays 0); `L131` the auto-load's
last-unit overshoot; `L132` AC3's underivable 1.5 s; `L133` the dead `_weapon_index`;
`L134` the eight stale `outfitting_panel` probes; `L135` FITTING's "BUY THEM IN OUTFITTING";
`L136` LAUNCH's pack-store ordnance summary; `L137` the one in-flight sprite vs per-hull
hardpoints; `L138` `test_p2a_launch_fit.gd:347`'s stale premise; `L139` the untracked
`.crush/shell-output/` + D6 folder in the verify added list; `L140` the ARMORY pane's second
label literal.

## Owner ticks owed (unchanged from the brief)

The brief's five stand. The wave adds no new number of its own: the railgun pack (150/360/150)
is the owner's, `ROUNDS_PER_CARGO_UNIT 10`, the `track_dps` taste table and
fire-along-facing-vs-hold-until-aligned remain the brief's ticks. R1-MED-1's readout fix is a
behaviour decision only if the owner wants a **rack-level** readout instead of a per-barrel
one — the review's expectation is per-barrel, since the label already is.

## Evidence appendix

```bash
# the gate, three scratch stores (identical) - logs kept at /tmp/s5r1_gate{1,2,3}.log
XDG_DATA_HOME=/tmp/s5r1_xdg{A,B,C} $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
  res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=577 failed=0            # x3, exit 0
grep -c '^\[PASS\]' /tmp/s5r1_gate3.log  # 577

# the baseline check (problems: [])
python3 staging/verify_wave.py verify --baseline s5_start \
  --forbidden vajb-orbit/project.godot docs/gameplay/18_engine_spec.md

# the reviewer's independent hardpoint re-derivation (Pillow, nine renders):
python3 /tmp/s5r1_hp.py
#   rear arrays byte-identical to ShipFit.HARDPOINTS for all nine hulls

# the reviewer's independent probe suite (deleted after the run):
XDG_DATA_HOME=/tmp/s5r1_probe $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
  res://tests/headless_runner.tscn --quit-after 900 -- --suite=test_s5r1_probe
[s5r1] A cannon marks [0, 73, 145] gaps ["73", "72"] (cycle 1.2 s = 72 frames)
[s5r1] B after a 90 deg swing + 0.5 s: laser 1.571 rad (90.0 deg), rocket 0.524 rad (30.0 deg)
[s5r1] C beam aligned settled=true off_swing=false back=true
[s5r1] D ammo_laser list=4 sale=2 ... ammo_railgun list=24 sale=14
[s5r1] E loaded=300 pack=300 hold=0
[s5r1] F after v6 load: { "ship_vanguard": [[0, 2], [1]] }
[s5r1] G component racks [[1, 2], [0]]
[s5r1] G select_battery(1) shows ammo=111 weapon=laser; rack 1 = cannon+rocket   # R1-MED-1
[SUMMARY] passed=6 failed=1              # the one red is R1-MED-1's own assertion

# the live account, before and after every run:
md5sum "$HOME/.local/share/godot/app_userdata/Vajb Orbit/profile.cfg"
539de5b7af59c77b6bffc477413161da
```

Per-suite counts in the closing gate (49 suites): `test_s5_commerce` 7, `test_s5_ammo_cargo`
14, `test_s5_batteries_v2` 12, `test_s5_hardpoints` 11; `test_engine2_weapons` 48,
`test_s4_batteries` 19, `test_p2b1_outfitting_panel` 13, `test_p2b_services` 14; every other
suite holds its S4 count.
