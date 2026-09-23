---
slice: S5
worker: S5-J3
model: "deepseek/deepseek-v4-flash"
status: actionable    # three findings are owed a decision (one bucket-2 number, one foreign-file string, the stale probes)
gate: "544/1 (my start) → 566/0, twice, on two scratch stores; live profile md5 unchanged"
---

# S5-J3 report — batteries v2: the ARMORY rename, composed racks, the slowest-cycle salvo

## Result

`OUTFITTING` is `ARMORY` (rail label, pane files, pane title), and the pane is a
drag-and-drop battery composer: a left inventory list of owned weapon ids, racks `B1..B7`
as drop zones, drags that install into a rack's next free W cell through the profile's
composed transactions, within/between-rack drags that re-order and swap, and a `✕` that
returns a barrel to the inventory. A battery is a player-composed **mixed** group persisted
as `batteries: {ship_id: Array[Array[cell_ref]]}` at `SAVE_VERSION := 7` (v6 files group
their fitted weapons by `base_id`, cells ascending, in memory at load, idempotently), the
ammunition rows stay and buy **cargo units** through J2's hold API, and the component's
salvo gate is `max(members' cadence)` with the strum and the per-barrel dry rules intact.
`GROUPS_MAX` is 7 across its four consumers (weapons.gd, the HUD's three tables, the new
`weapon_6`/`weapon_7` readers in game.gd, and the pane's rack count).

Gate, this machine, twice on two fresh scratch stores (`XDG_DATA_HOME=/tmp/s5j3_final{A,B}`),
live `user://` untouched (md5 identical before and after every run):

```
$GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=566 failed=0        (both runs, byte-identical counts; four more repeats green)
```

Arithmetic of the count, per suite (the runner's own `[PASS]` rows, counted with
`grep -c "^func test_"` at HEAD and per suite in the final run): my start was
`544 passed + 1 failed = 545` rows, in which `test_p2b1_outfitting_panel` ran its 11 rows
(J2's one red among them). The final run's 566 = 545 **+ 21**: `test_s5_batteries_v2`
**+12** (new), `test_p2b1_outfitting_panel` 11 → **13** (the pane's own rows, rewritten for
ARMORY), `test_s4_batteries` 16 → **19** (rewritten as the profile-transaction suite), and
`test_engine2_weapons` 44 → **48** (the S5 rack seam). `test_ui_slot_layout` and the four
save-version suites kept their row counts, with assertions re-pointed.

## The pin, and the nine decisions taken inside it

Every item below is inside the pinned acceptance (escalation bucket 1) and names its
one-line reversal. The three items that are **not** bucket 1 are in "Reported, not
changed" below.

1. **`battery_groups()` derives coverage; the record is the identity.** The read answers
   the stored racks in order, each restricted to cells the fit really holds, then a
   trailing rack for every fitted cell no rack mentions - so a fitted weapon always fires
   from exactly one rack (never unfireable), and a cell the FITTING pane fills joins a rack
   the moment it is read, with no write (17 section 3's "never rewritten at load").
   `set_battery_groups` normalises (in-range, no cell twice, trailing empties dropped) and
   keeps an interior empty rack, because a rack the player emptied keeps its ordinal.
   *Reversal:* refuse an uncovered fitted cell instead of deriving a rack for it.
2. **A write materialises the derived coverage.** `fit_into_rack` writes the derived
   groups, so a hull that had no record ends up with `[[0],[1]]` rather than a derived
   `[[0,1]]` (measured in `test_fit_into_rack_installs_and_records_the_cell`). *Reversal:*
   write only the changed rack.
3. **`set_battery_groups` accepts a stale cell reference** (in range, unique, but the fit
   holds nothing there) and the **read** drops it, rather than refusing the write: the
   record is the player's composition and the fit is the truth about what is in a cell.
   *Reversal:* refuse a reference the fit does not hold.
4. **`fit_into_rack` requires the cell to be empty.** A drag onto a barrel is a move
   (`move_rack_cell`), not a swap, so the install refuses a taken cell before any write.
   *Reversal:* let the same call swap.
5. **The rack ceiling is `WeaponComponent.GROUPS_MAX`**, read through a preload in the
   profile and through the pane's `RACK_COUNT` - one number, three consumers, no second 7.
   *Reversal:* a local constant.
6. **`migrate_batteries` is memory-only.** The v7 flag day groups a v6 file's fitted
   weapons in memory and does **not** `_mark_dirty()`, so a v6 file is not rewritten at
   load (the v4 fitting arrays' own rule); the next real write persists v7 with the record
   (measured in `test_a_v6_file_migrates_its_racks_and_the_next_write_persists_them`).
   *Reversal:* `_mark_dirty()` when it migrated a hull (the v5/v6 flag days' shape).
7. **The component's index space is barrel positions, the record's is cell refs.**
   `game.gd:_launch_batteries` resolves the profile's cell refs into `fitted()` positions
   (section 16 rule 3's divergence), so the component needs no cell table and the persisted
   record keeps the pin's cell refs. `battery(base_id)` stays the family-keyed read it was
   (the ammo readout's shape). *Reversal:* hand the component cells plus `fitted_ids`.
8. **The battery's clock starts at the arm.** `_battery_timer = battery_cycle()` is set
   when the salvo is armed, so a held rack's period is the slowest member's cycle (measured
   `1, 38` frames for a 0.6 s rack and `0, 73, 146` for a 1.2 s rack at 1/60). *Reversal:*
   start it when the last barrel of the salvo releases.
9. **The mine's carve-out is per barrel.** A new `_released` flag per barrel gives an
   `edge` row one release per pull, so a rack may hold a mine beside a held family without
   dropping a mine per salvo (`_salvo_spent` no longer needs the old whole-battery edge
   test). *Reversal:* the per-battery guard S4 had.
10. **The pane rebuilds its racks; it does not keep a fixed node set.** CONTRACTS section
    16 rule 10 pinned that for the S4 **strip**, whose shape was fixed; a rack's shape is
    player-composed (a drag adds a chip, the `✕` removes one), so the rack box and the
    inventory list are redrawn with `remove_child` + `queue_free` - the plate whose
    `_drop_data` started the write is alive for the rest of the frame, and the drop tests
    exercise exactly that path. *Reversal:* a fixed 7-rack node set with per-rack
    show/hide, which cannot express a rack of more than one barrel without a pre-built
    maximum.
11. **The ammunition row's `MAX` is the unit equivalent of `ammo_max`**
    (`ceil(ammo_max / ROUNDS_PER_CARGO_UNIT)`: 30/30/10/10/10/15), the same rounding the
    purchase's own unit arithmetic uses (`PlayerProfile._ammo_units_for`). No doc states a
    cap on the hold's units; this is derived from two pinned numbers. *Reversal:* a literal
    column or a hidden MAX.
12. **The HUD's family readout keeps the pressed cell's module.** Clicking a
    laser cell of a mixed rack still reads `LASER MKII` while the signal and the highlight
    carry the rack ordinal (section 17's addressing). *Reversal:* the rack's first member.

### A latent S4 bug this wave exposed, found and fixed

`_release_battery`'s countdown subtracted `delta` **without clamping at zero**, and its
"is this barrel unarmed?" test was `_armed[position] < 0.0` - so a barrel whose release was
waiting on its own cadence (or the cannon's burst window) went to e.g. `-0.0019`, read as
*unarmed* on the next frame, and silently lost its shot. Measured on a 3-cannon rack before
the cure: **13-14 shots in a 3.0 s hold** with a barrel frozen at `_armed = -0.0019`
(traced frame by frame), and the S4 stream test's "5 windows × 3 barrels = 15" flaking.
After the cure (`maxf(_armed[position] - step, 0.0)`, the `-1.0` sentinel now unambiguous):
**15 shots**, and the same trace shows every barrel releasing. This is inside my file set
and inside the pin's own "the next salvo waits for the slowest member's cycle" reading
(a barrel must be able to retry).

## AC3, measured — and the one number I could not derive

The acceptance asks for "a salvo of a laser+cannon battery fires both barrels and the next
salvo waits for the slowest member's cycle (measured: a 0.6 s + 1.5 s pair cycles at 1.5 s)".
What the shipped family table states (`WeaponComponent.interval_of`):

| member | cycle | source |
|---|---|---|
| `w_cannon` | **0.6 s** | its own burst cycle, 0.35 on + 0.25 off |
| `w_rocket` | 1.2 s | the spec's interval |
| `w_railgun` | 0.6 s | `KINETIC_INTERVAL` (borrowed, reported in code since C2) |
| `w_laser`, `w_plasma` | **0.0 s** | instant families have no shot cadence (`test_combat_repair_c5.gd:254` asserts this) |
| `w_mine` | 0.0 s | `edge`, a drop rather than a held family |

**No family states 1.5 s**, so a "0.6 s + 1.5 s pair" cannot be built out of the table, and
I did not invent one (the brief's hard rule). What is measured instead, on the shipped
component, is the rule itself:

- **laser + cannon (the AC's own pair), one rack** - both barrels leave in the pull's own
  salvo (1 cannon shot and 1 beam open inside 5 frames), no second salvo inside the window,
  the second at frame **38-40** against the 0.6 s / 36-frame window, the beam opens **once**
  for the whole hold, and the pack spends 2 rounds. The two-to-four extra frames are the
  pin's own slack: the strum's `[0, 40] ms` draw (2.4 frames) and the cannon's burst window,
  which can hold a barrel until its next on-window. Four runs:
  `[s5-batteries] mixed laser+cannon rack: cycle 0.600 s, cannon salvos at [2, 39] frames` /
  `[1, 39]` / `[1, 38]` / `[1, 40]`; the same rack in `test_engine2_weapons` over a 3.0 s
  hold: `[s5-racks] mixed cannon+laser rack: cycle 0.600 s, cannon salvos at [0, 37, 73, 109, 145], beam opens 1` (and `[0, 38, 74, 110, 146]` on other runs).
- **cannon + rocket, one rack** - the same rule over two **non-zero** cycles, which is the
  AC's arithmetic with the numbers the table has, and the **decisive** reading: the S4
  per-barrel rule would put the cannon on its own 0.6 s / 36 frames, and the measured gaps
  are 73 and 72 frames ≈ 1.2 s across every run.
  `[s5-batteries] cannon+rocket rack: cycle 1.2 s, cannon salvos at [0, 73, 145] (gaps ["73", "72"] frames)`

`battery_cycle()` is asserted to equal `maxf(interval_of(member)...)` (never a literal) and
the rule is also covered by `test_the_salvo_gate_is_the_slowest_members_cycle` and
`test_a_held_mixed_rack_streams_at_its_slowest_members_cycle` in `test_engine2_weapons`.

**This is a bucket-2 finding: the AC's "1.5 s" is a pinned number that cannot be derived
from any doc or table.** Decision owed by the developer/owner session.

## The other AC3 halves, measured

- **The v7 migration.** A hand-built **v6** `ConfigFile` fixture whose Vanguard fit is
  `[w_laser, w_cannon, w_laser]` loads as racks `[[0, 2], [1]]` (grouped by `base_id`,
  cells ascending), `migrate_batteries()` answers **0** on a second call (idempotent), the
  file is **still v6** with no `batteries` key after the load (memory-only), and after one
  real write (a bag write) it is **v7** with `[[0, 2], [1]]` on disk.
- **The drag refusals write nothing.** Fit, bag, rack record and credits are byte-compared
  around each refusal: a drop from an inventory list that cannot start (an unowned base -
  the drag payload is `{}`), a drop onto a barrel, a rack past `B7`, a battery with no free
  W cell (`W SLOTS FULL — SWAP OR REMOVE FIRST`), and an over-budget candidate
  (`9 / 8 PWR — OVER BY 1` on a Cutter whose budget is 8 and whose delivered fit spends 3).
- **The drags themselves.** A drop installs into the rack's next free cell (W2, W3 in
  order) and records the rack; a within-rack drag re-orders (`[[0,1,2]]` → `[[2,0,1]]`); a
  between-rack drag onto an occupied place swaps (`[[0],[2]]` → `[[2],[0]]`); a body drop
  appends to the **target** rack (`[[0],[1]]` → `[[],[1,0]]`) with `can_drop` and `drop`
  agreeing on the address; the `✕` empties the cell, returns the instance and drops the
  reference. No fit cell ever moved in any of them.
- **The pane's read-backs.** `rack_rows()` (7 racks, `B1..B7`, each with its `SALVO`/`READY`
  line and its `W<cell> <NAME>` chips) and `inventory_rows()`/`inventory_view_rows()`
  (catalogue order, `OWNED ×n` = `instances_of`, non-weapons never listed).
- **The rails.** `MODULE_LABELS[0] == "ARMORY"`, `MODULE_FILES[0] == "armory"`,
  `armory_panel.{gd,tscn}` ship and the two `outfitting_panel.*` files are gone;
  `GROUPS_MAX == 7 == RACK_COUNT`; `WEAPON_ACTIONS`/`WEAPON_IDS`/`WEAPON_LABELS`/
  `WEAPON_ICONS` all 7, with `icon_module_w_railgun.svg` and `icon_module_w_mining.svg`.
- **The launch.** A launched game scene whose Vanguard holds `[[0],[1]]` mounts a component
  whose `racks()` reads `[[0],[1]]`; the HUD's pushed cells carry `battery` 1, 2 and 0 (the
  empty cell selects nothing).

## Tests that move (all in my set)

| Suite | Move | Why |
|---|---|---|
| `test_s4_batteries.gd` | **rewritten** (20 → 19 rows) | the S4 strip is gone: its surface rows became the profile-level record tests (§17) and its bulk-action rows became `fit_battery`/`clear_battery`/`fit_into_rack`/`clear_rack_cell`/`move_rack_cell` |
| `test_p2b1_outfitting_panel.gd` | rewritten surface half (12 → 13 rows) | the pane is ARMORY and its strip is racks; the ammo rows' HELD/MAX now read the **hold's units** and the purchase delivers units (J2's red `:437` is gone) |
| `test_engine2_weapons.gd` | +4 rows, one renamed | `GROUPS_MAX` clamp 5 → 7, and the S5 rack seam (`set_batteries`, `racks()`, `battery_cycle`, the stream at the slowest cycle) |
| `test_ui_slot_layout.gd` | wrap case adapted | the widest hull has 7 W cells and the map has 7 keys, so the "more cells than keys" push appends one synthetic cell; `_pushed_cells` now carries the rack ordinal |
| `test_p1_profile.gd`, `test_p2a_profile_fits.gd`, `test_p2b_retirement.gd`, `test_s3_migration.gd` | 6 assertions re-pointed | `SAVE_VERSION` 6 → 7 (each now reads `Profile.SAVE_VERSION`, so the next bump moves one place) |

## Reported, not changed (bucket 2/3)

- **`ui/station/fitting_panel.gd:108`** still reads
  `"NO MODULES OWNED · BUY THEM IN OUTFITTING"`. The pane it names is ARMORY now, and the
  file is in **no S5 worker's set** (it was P2-B proper's). It is a one-word text change in
  a foreign file: **bucket 2** (a `docs/`-adjacent string owned by another wave), so it is
  reported rather than patched. Reversal of the report: J3 gains the file and changes the
  word to `ARMORY`.
- **8 stale probes preload the retired pane** (`probe_p2b1_panel_fit.gd`,
  `probe_r1_p2b1_{edge,edge2,edge3,fit,layout,persist,review}.gd`). They were **already
  broken** before this wave (they read `OutfittingScroll/OutfittingBody/ModulesMargin/
  ModulesBox`, retired by the S3 amendment), so the deleted scene only changes *which* line
  fails. They are not gate members (`test_*.gd` only) and I did not delete them - retiring
  them is the reviewer's or a later wave's call.
- **`ui/station/{auction,shipyard}_panel.gd` comments** mention "the OUTFITTING pane".
  Comments only, foreign files.
- **`test_p2a_launch_fit.gd:347`** ("a capital's last two cells display without a key") is
  still green but its premise is gone: the map now reaches all seven of the Obliterator's
  cells. Its assertion still holds (`index < GROUPS_MAX` for 7 cells), so I left it.

## Deviations from the brief, and what the reviewer should check hardest

- The brief's tests-that-move line names `test_s4_batteries`' rows as "grouping becomes
  mixed + the salvo gate becomes the slowest cycle". The strip's *surface* could not move
  that way (the strip is gone), so the mixed-grouping and the gate are measured in
  `test_engine2_weapons` (component) and `test_s5_batteries_v2` (flight), and
  `test_s4_batteries` became the profile-transaction suite.
- **`WeaponComponent.battery_ids()` still answers the fit's distinct families** (section 16
  rule 2's shape) while `racks()` is what `weapon_1..7` addresses. §17's disposition
  supersedes rules 2/3 to cell refs; the component has no cells (its handoff is a flat id
  list), so the **record** is the cell-ref authority and the component answers positions.
  If the reviewer reads the supersession as requiring `battery()` to answer cell refs, that
  needs `set_fitted` to take the hull's cell array - a J4-adjacent change.
- The pane's own `PaneTitle` (`armory_panel.tscn`) is a second `ARMORY` literal beside
  `station.gd`'s rail label, exactly as `OUTFITTING` was before (the pane cannot read the
  rail's own label). Both are asserted; drift would need a third writer.

## Follow-ups

| Item | Kind | Where |
|---|---|---|
| AC3's "0.6 s + 1.5 s pair cycles at 1.5 s" is not derivable from the family table (no 1.5 s cadence exists) | bucket 2, owner/dev decision | `S5_BRIEF.md` tests §AC3, 09 §11's salvo rule |
| FITTING's empty-state line still says `BUY THEM IN OUTFITTING` | bucket 2, one word | `ui/station/fitting_panel.gd:108` |
| 8 stale probes preload the retired `outfitting_panel.tscn` | LOW, retire or re-point | `vajb-orbit/tests/probe_*p2b1*.gd` |
| `armory_panel.gd.uid` and `test_s5_batteries_v2.gd.uid` are not written yet (headless runs do not mint UID sidecars) | LOW, the editor's next scan mints them | `ui/station/`, `tests/` |
| The HUD's slot press now emits a **battery ordinal**, not a cell index (a signal-payload semantic change) | note for the wiring/LOW readers | `ui/hud/hud.gd:_on_weapon_slot_pressed`, `game.gd:_select_weapon` |

## Evidence

```bash
cd "$VAJB_WORKSPACE"
# the gate, twice, on two fresh scratch stores, live profile untouched:
XDG_DATA_HOME=/tmp/s5j3_final{A,B} $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
  res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=566 failed=0        # both runs
md5sum "$HOME/.local/share/godot/app_userdata/Vajb Orbit/profile.cfg"
539de5b7af59c77b6bffc477413161da     # identical before the first run and after the last

# the suite-level counts (12, 19, 13, 48 tests):
XDG_DATA_HOME=/tmp/s5j3_finalC $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
  res://tests/headless_runner.tscn --quit-after 1200 -- --suite=test_s5_batteries_v2
[s5-batteries] mixed laser+cannon rack: cycle 0.600 s, cannon salvos at [1, 38] frames
[s5-batteries] cannon+rocket rack: cycle 1.2 s, cannon salvos at [0, 73, 146] (gaps ["73", "73"] frames)
[SUMMARY] passed=12 failed=0

XDG_DATA_HOME=/tmp/s5j3_finalC $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
  res://tests/headless_runner.tscn --quit-after 1200 -- --suite=test_engine2_weapons
[s5-racks] mixed cannon+laser rack: cycle 0.600 s, cannon salvos at [1, 38], beam opens 1
[SUMMARY] passed=48 failed=0

# the S4 latent bug, before and after the clamp (one 3-cannon rack, 180 frames at 1/60,
# traced frame by frame with a temporary debug hook - the hook is removed again):
[dbg] cadence blocks 2 timer=0.01666666666667
[trace] f145 shots=13 armed=[-1.0, -0.00190589117507, -1.0] ...   # a barrel frozen at -0.0019
[trace] total shots=13 releases=[0, 37, 73, 74, 109, 110, 145]     # before
[trace] total shots=15 releases=[0, 37, 38, 73, 74, 109, 110, 145, 146]  # after

# the per-file GDScript-warning ledger (the W1/W2 probe pattern), run for the three
# modified shipped scripts and the four suites - a scratch probe, deleted again:
$GODOT_CONSOLE --headless --debug --path "$VAJB_PROJ" res://tests/probe_s5j3_lint.tscn --quit-after 600
# armory_panel.gd, player_profile.gd, hud.gd, test_s4_batteries.gd, test_engine2_weapons.gd
# and test_s5_batteries_v2.gd: 0 warnings of their own (the nine `position` shadow warnings
# the first pass found in the new pane were renamed to `slot`; the lone "Integer division"
# the s4 suite's group reports comes from its preload of game/module_catalog.gd:636/651,
# measured pre-existing). game/weapons.gd (20) and game/game.gd (26) are unchanged
# pre-existing ledgers.

# parse checks on every shipped file this worker touched (the two "Identifier not found"
# lines are --check-only not resolving autoloads and are pre-existing):
$GODOT_CONSOLE --headless --path "$VAJB_PROJ" --check-only --script res://game/weapons.gd
$GODOT_CONSOLE --headless --path "$VAJB_PROJ" --check-only --script res://autoload/player_profile.gd
$GODOT_CONSOLE --headless --path "$VAJB_PROJ" --check-only --script res://ui/station/armory_panel.gd
```

## Files touched

- `vajb-orbit/ui/station/armory_panel.gd` — **new**: the ARMORY pane (racks `B1..B7`, the
  inventory, the drag interface, the ammo rows on cargo units).
- `vajb-orbit/ui/station/armory_panel.tscn` — **new**: the same node tree renamed, with the
  racks and inventory sections.
- `vajb-orbit/ui/station/outfitting_panel.gd` (+`.uid`), `.tscn` — **deleted** (the rename).
- `vajb-orbit/autoload/player_profile.gd` — `SAVE_VERSION 7`, the `batteries` record and its
  five readers/writers, `battery_groups`, `free_weapon_cell`, `fit_into_rack`,
  `clear_rack_cell`, `move_rack_cell`, `migrate_batteries`.
- `vajb-orbit/game/weapons.gd` — `GROUPS_MAX 7`, `set_batteries`/`racks`/`selected_rack`/
  `battery_cycle`, the per-rack volley with the battery timer, the per-barrel `edge`
  carve-out, the clamped arm countdown.
- `vajb-orbit/game/game.gd` — `WEAPON_ACTIONS` to 7 (guarded), `_select_weapon(battery)`,
  `_launch_batteries`/`_weapon_barrel_positions`, `_hull_slot_cells`' `battery` field.
- `vajb-orbit/ui/hud/hud.gd` — the three tables to 7, `select_battery`, the press emitting
  the rack ordinal, the per-rack highlight, `_cell_battery`.
- `vajb-orbit/ui/screens/station.gd` — `MODULE_FILES[0]`/`MODULE_LABELS[0]` renamed.
- `vajb-orbit/tests/test_s5_batteries_v2.gd` — **new**, 12 rows (AC3).
- `vajb-orbit/tests/test_s4_batteries.gd` — rewritten, 19 rows.
- `vajb-orbit/tests/test_p2b1_outfitting_panel.gd` — re-pointed at ARMORY, 13 rows.
- `vajb-orbit/tests/test_engine2_weapons.gd`, `test_ui_slot_layout.gd`,
  `test_p1_profile.gd`, `test_p2a_profile_fits.gd`, `test_p2b_retirement.gd`,
  `test_s3_migration.gd` — the moves in the table above.
