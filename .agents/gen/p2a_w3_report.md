# Wave P2-A — W3 report: the nine-hull roster

Worker: **W3** (coder, the nine-hull roster). Brief:
`.agents/gen/p2a_slot_frames_wave_task.md` §4's W3 row. Declared file set:
`vajb-orbit/game/station_catalog.gd,vajb-orbit/tests/`.

Verdict: **done, gate green and grown.** `StationCatalog.SHIPS` is nine rows in
08 §2's ladder order with that table's frozen values, `preview` per hull, and a
one-line description in the existing catalogue voice; a new suite proves the
count, the order, the on-disk previews and the `hardpoints` ↔
`ShipFit.HULLS[id].weapons` equality.

Files changed (exactly two, both inside the declared set):

| File | Nature | md5 |
|---|---|---|
| `vajb-orbit/game/station_catalog.gd` | `SHIPS` 4 rows → 9, plus a 4-line comment naming the source of every number | `f228aef47079f3f15d140e94d691c33c` |
| `vajb-orbit/tests/test_p2a_ship_roster.gd` | new suite, 4 tests | `43691a874dd69862cbc9ba6181b882bb` |

`git diff --stat -- vajb-orbit/game/station_catalog.gd` → `1 file changed, 61
insertions(+), 2 deletions(-)`. No other file, asset, theme, `project.godot`,
`addons/**` or doc was touched by this worker.

## 1. The nine rows as implemented

Numbers are 08 §2's frozen table (cost/hull/shield/cargo and the Weapons
column); the ladder order is the brief's and `STATION_SPEC.md` §4.2's. The four
rows §5.2 lists keep their frozen §5.2 costs byte for byte (9000 / 18000 /
36000 / 72000), and the four existing descriptions are unchanged.

| # | `id` | `name` | `cost` | `hull` | `shield` | `cargo` | `hardpoints` | `preview` |
|--:|---|---|---:|---:|---:|---:|---:|---|
| 1 | `ship_fighter` | Lancer | 9000 | 700 | 400 | 25 | 2 | `res://assets/ships/ship_fighter_side.png` |
| 2 | `ship_vanguard` | Vanguard | 18000 | 1000 | 600 | 40 | 3 | `res://assets/ships/ship_vanguard_side.png` |
| 3 | `ship_miner` | Delver | 16000 | 1100 | 500 | 55 | 2 | `res://assets/ships/ship_miner_side.png` |
| 4 | `ship_trader` | Courier | 21000 | 950 | 550 | 60 | 1 | `res://assets/ships/ship_trader_side.png` |
| 5 | `ship_corvette` | Spearhead | 27000 | 1300 | 700 | 35 | 4 | `res://assets/ships/ship_corvette_side.png` |
| 6 | `ship_freighter` | Mule | 24000 | 1600 | 500 | 120 | 1 | `res://assets/ships/ship_freighter_side.png` |
| 7 | `ship_gunship` | Bulwark | 36000 | 1400 | 650 | 50 | 5 | `res://assets/ships/ship_gunship_side.png` |
| 8 | `ship_patrol` | Warden | 54000 | 1800 | 800 | 60 | 4 | `res://assets/ships/ship_patrol_side.png` |
| 9 | `ship_destroyer` | Obliterator | 72000 | 2200 | 900 | 80 | 7 | `res://assets/ships/ship_destroyer_side.png` |

Descriptions (new rows; existing rows untouched):

- `ship_miner` — "Mining specialist. Slow, deep holds, and a hull that shrugs off rock."
- `ship_trader` — "Trade hull. Better exchange rates and a hold built for volume."
- `ship_corvette` — "Fast hunter. The quickest hull in the yard, and it pays for it in plate."
- `ship_freighter` — "Bulk hauler. The biggest hold in the yard, and the least interest in a fight."
- `ship_patrol` — "Line patrol. Two computers, four mounts, and the plate to hold a lane."

No price was invented: every figure is quoted from 08 §2, and the five new rows
reuse that table's own class names (Delver, Courier, Spearhead, Mule, Warden)
and its role column.

## 2. The test (`vajb-orbit/tests/test_p2a_ship_roster.gd`)

A `const LADDER` table transcribes 08 §2 verbatim (id, name, cost, hull, shield,
cargo, Weapons), and four tests read the shipped catalogue against it:

1. `test_roster_is_the_nine_hull_ladder` — nine rows, nine unique `ship_ids()`,
   id and name in ladder order at every index.
2. `test_frozen_cost_hull_shield_cargo` — cost/hull/shield/cargo equal the table.
3. `test_previews_are_the_hull_side_renders_on_disk` — each row's `preview` is
   exactly `res://assets/ships/ship_<id stem>_side.png`, and both
   `ResourceLoader.exists` (imported) and `FileAccess.file_exists` (on disk)
   hold for all nine.
4. `test_hardpoints_match_the_hull_grid_count` — each row's `hardpoints` equals
   08 §2's Weapons column **and** `ShipFit.HULLS[id].weapons`, with a guard that
   the id is a real `ShipFit` hull.

## 3. Raw output

### 3.1 The suite alone

```
$ godot --headless --path vajb-orbit res://tests/headless_runner.tscn \
    --quit-after 1200 -- --suite=test_p2a_ship_roster
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
[RUN] suites=test_p2a_ship_roster
[PASS] test_p2a_ship_roster.gd.test_frozen_cost_hull_shield_cargo
[PASS] test_p2a_ship_roster.gd.test_hardpoints_match_the_hull_grid_count
[PASS] test_p2a_ship_roster.gd.test_previews_are_the_hull_side_renders_on_disk
[PASS] test_p2a_ship_roster.gd.test_roster_is_the_nine_hull_ladder
[SUMMARY] passed=4 failed=0
```
(exit 0; log `/tmp/p2a_w3_suite.log`)

### 3.2 The wave gate

```
$ godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
...
[PASS] test_p2a_ship_roster.gd.test_frozen_cost_hull_shield_cargo          (line 268)
[PASS] test_p2a_ship_roster.gd.test_hardpoints_match_the_hull_grid_count   (line 269)
[PASS] test_p2a_ship_roster.gd.test_previews_are_the_hull_side_renders_on_disk (line 270)
[PASS] test_p2a_ship_roster.gd.test_roster_is_the_nine_hull_ladder         (line 271)
[SUMMARY] passed=315 failed=0
```
(exit 0, no `[FAIL]`, no `[SKIP]`; log `/tmp/p2a_w3_gate.log`)

**Gate count: 315 passed / 0 failed, up 4 from this worker's suite** (the brief
quotes 307 as the pre-wave figure; W1/W2's own tests and a feel-pass fixer landed
between). The count did not shrink: nothing was deleted or disabled.

## 4. One transient to record (no action owed)

The `ShipFit.HULLS[id].weapons` half of test 4 is coupled by design to W1's
parallel `HULLS` amendment (CONTRACTS §11 rule 5, `weapons` 3/4/3 → 2/3/4 on the
fighter/vanguard/corvette). W1 landed ~4 minutes after this worker's first pass,
so the **first** full-gate run in this window read:

```
[FAIL] test_p2a_ship_roster.gd.test_hardpoints_match_the_hull_grid_count: ship_fighter hardpoints equal the hull's grid weapons count
[SUMMARY] passed=314 failed=1
```

and the same gate re-run once W1's `ship_fit.gd` was on disk reads
`passed=315 failed=0`. Both runs are in the log chain (`/tmp/p2a_w3_gate_1.log`,
`/tmp/p2a_w3_gate.log`); the assertion was never weakened, and the independent
08 §2 half of the same test passed in both runs.

## 5. Deviations, and what W3 did not do

- **No deviation from the brief.** The only friction was mechanical: the
  PreToolUse hook denies absolute paths on this host, so the first edit attempt
  with `/home/.../station_catalog.gd` was refused and the retry used the
  workspace-relative path (brief §6, "use workspace-relative paths"). Nothing was
  written outside the declared set.
- Deliberately **not** done here (other workers own them): `ShipFit`'s grids and
  `weapons` (W1), the profile fits (W2), the launch fit resolution (W4), the
  shipyard/launch panel rows and the layout grid (W5). The catalogue change is
  additive to those: `SHIPS` gained rows, and no existing row, field name or
  consumer contract moved. `StationCatalog.ship()` / `ship_ids()` / the ammo,
  upgrade and service consts are untouched, so `player_profile.gd:475`
  (`_load_catalog`, now validating nine ids instead of four) and
  `shipyard_panel.gd:154` (`SUBTITLE % SHIPS.size()` → 9) read the new roster
  with no code change of their own.
- Owner ticks: none of §8's six items is touched by this worker; all six are
  recorded resolved in the brief.
