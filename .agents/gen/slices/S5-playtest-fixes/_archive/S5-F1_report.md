---
slice: S5
worker: S5-F1
model: "deepseek-v4-flash"
status: informational   # both MED findings closed; no HIGH existed; nothing owed a decision
gate: "577/0 (R1's measured gate) → 578/0, twice, on two fresh scratch stores; live profile md5 unchanged"
---

# S5-F1 report — the two R1 MED findings (HUD readout, dead test half)

Review fixed: `.agents/gen/slices/S5-playtest-fixes/S5-R1_review.md` (`R1-MED-1`, `R1-MED-2`;
no HIGH). Brief: `S5_BRIEF.md`. **Scope held**: HIGH/MED only, no LOW row touched, no
refactor, no balance or price or cadence number, no frozen file (`project.godot`,
`docs/gameplay/18_engine_spec.md`, `08_ship_slots_modules.md`, `assets/`, `addons/`, the
theme), and no `docs/` text (bucket 2 — see *Deviations*).

## Result

The HUD's ammo/label readout now resolves the **barrel** a selection names instead of
indexing `PlayerState.ammo` with the rack ordinal, and `test_s5_batteries_v2.gd`'s HUD half
actually runs (its four assertions were skipped by a case-sensitive node path). Measured on
the shipped `game.tscn` at a mixed rack (B1 = cannon+rocket, B2 = laser, packs 111/222/133):
the launch's own selection **names the cannon** (its push resolves the ordinal against the
grid instead of the empty-grid fallback), `select_battery(1)` reads **cannon / 222**, a
press on W3 reads **rocket / 133**, a press on W1 reads **laser / 111** — the wrong-entry
read the review measured (`select_battery(1)` → laser / 111) is gone.

Gate, this machine, twice on two fresh scratch stores, live `user://` untouched:

```
XDG_DATA_HOME=/tmp/s5f1_xdg{E,F} $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
  res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=578 failed=0          # both runs, exit 0, identical counts
grep -c '^\[PASS\]' /tmp/s5f1_gate{3,4}.log   # 578, 578
md5sum "$HOME/.local/share/godot/app_userdata/Vajb Orbit/profile.cfg"
539de5b7af59c77b6bffc477413161da       # before and after every run
```

The error lines are exactly the three pre-existing ones R1 listed (`test_weapon_fx_f4.gd:178`
`previously freed instance`, the detached-hull `Parameter "data.tree" is null.` from
`weapons.gd:2050`, and `test_p1_clock_log.gd`'s own unwritable-path `EconomyLog` warning). No
new `SCRIPT ERROR`, no new failure.

## Finding-by-finding disposition

### R1-MED-1 — the readout indexed a per-slot array with a rack ordinal → **FIXED** (bucket 1)

`ui/hud/hud.gd` now keeps the **rack ordinal** (`_active_slot`, what the highlight and the
`weapon_N` signal use) and the **barrel slot** (`_active_barrel`, what `_ammo_of` reads)
apart, and resolves the second from the pushed cell:

- `game/game.gd:_hull_slot_cells` adds `position` to the payload — the cell's own index in
  `PlayerState.weapons`/`ammo`, `-1` for an empty cell. It is counted in the same walk and
  order as `_launch_weapons()` (the same rule `_seed_ammo` sizes the array by), so the two
  cannot drift.
- `ui/hud/hud.gd`: `_cell_position` (the new field, with the cell-index fallback an older
  payload gets), `_barrel_of_battery` (a rack ordinal → its **first cell in layout order**;
  `battery - 1` when no pushed cell claims the rack, the pre-S5 mapping an empty grid has),
  `_battery_family` (the same first cell's firing family), `_set_barrel`.
- `select_battery(ordinal)` — the keyboard `weapon_N` path — now sets the barrel, the label
  **and** the pack from the rack's own first cell, so rack 1 of a cannon+rocket rack names
  the cannon: the review's measured `weapon_1` → `WEAPON_IDS[0]`'s laser is gone.
- `_on_weapon_slot_pressed(index)` narrows the same selection to the **pressed cell's** own
  barrel and module, so a mixed rack reads the cell the player clicked. The
  `weapon_slot_selected` emit moved **before** that narrowing on purpose: the flight scene
  answers the signal with `select_battery` again (`game.gd:_select_weapon`), and emitting
  first lets the rack-level round trip happen while the press keeps the per-cell reading
  on top. The signal still carries the **rack ordinal** (its pinned payload), the highlight
  still lights every cell of the rack, and `_guns.select_group` still runs.
- `set_hull_slots` re-resolves the current selection after the grid is built, so the launch
  itself reads the rack's own barrel rather than the empty-grid fallback it was pulled with
  (`_pull_state` runs at `bind`, before the cells are pushed).
- Both fallbacks preserve the pre-S5 reading exactly: an empty grid and a producer that
  pushes no `battery`/`position` fields answer `ordinal - 1 == cell index`, i.e.
  `ammo[ordinal - 1]`, as before.

Covered by a new test (see R1-MED-2's file): `test_the_readout_follows_the_selected_barrels_own_pack`.

### R1-MED-2 — `test_s5_batteries_v2.gd`'s HUD half never ran → **FIXED** (bucket 1)

`tests/test_s5_batteries_v2.gd:45` `HUD_NODE` `&"HUD"` → `&"Hud"` (the scene root is `Hud`,
`ui/hud/hud.tscn:25`; every other suite already spelled it that way). The lookup at `:844`
now answers, so the four assertions at `:847-851` (the pushed cells' `battery` 1/2/0 and
`selectable`) really run — verified by the suite's own green row and by the launch-time
`_active_slot`/`_weapon_id` assertions the new test adds. The row count of that test is
unchanged (it was green either way, which was the finding); what changed is that it now
measures.

## Deviations / judgment calls

1. **`position` is the barrel slot, not `_weapon_barrel_positions()`' entry.** The two are
   the same number for every fit that fills its W cells with firing families (every standard
   and auction fit, and the review's measured case). They differ only where §16 rule 3's
   divergence bites: a family-less `w_mining` cell is a **slot with no pack** in
   `PlayerState.weapons` (`_launch_weapons` keeps it) but is **dropped** from the component's
   barrel list (`WeaponsComponent.set_fitted`), so a cell after it shifts by one in one space
   and not the other. The readout reads `_state.ammo`, whose index is `_seed_ammo`'s own
   (the launched slot), so the slot is the correct index for it. Reversal: read
   `_weapon_barrel_positions()`' entry instead — one line in `_hull_slot_cells`.
2. **The additive payload field is reported, not written into `docs/`.** `position` widens
   the `set_hull_slots` `cells` shape that §13/§11 pins (`{slot, index, module, icon,
   fitted, selectable}`), exactly as `battery` did under §17's J0 dispositions; the review's
   own cure names the route ("the `_hull_slots` payload can carry it beside `battery`"), so
   it is a bucket-1 decision inside the pinned acceptance. `docs/CONTRACTS.md` is **not**
   touched: docs text is the developer's bucket-2 call. **Owed:** one additive line beside
   §17's `battery` bullet, with the reversal above.
3. **`set_hull_slots` re-resolves the selection** (R1-MED-1's same defect at launch time: the
   `bind`-time pull cannot know the racks). Side effect is limited to the readout's own
   fields; no signal is emitted, so no fit/selection write can follow from a push.
4. **The test writes the packs straight onto `state.ammo`** rather than through `set_ammo`:
   `set_ammo` re-announces the slot, which moves the HUD's selection through
   `_on_weapon_changed` and would hide which path set the reading. The figures stay under the
   slot's own `AMMO_DEFAULT` ceiling, which `set_ammo` clamps to (measured: 333 arrived as 300).
5. **No LOW row was touched**: `L130`–`L140` and the pre-existing `_consume_ammo` /
   `ammo_slot` family-index spend (`weapons.gd:2201`, which is the `set_ammo` channel's own
   pre-S5 space and is outside this review's finding) are left exactly as R1 found them.

## Evidence

```bash
# the gate, twice, two fresh scratch stores - logs /tmp/s5f1_gate{3,4}.log
XDG_DATA_HOME=/tmp/s5f1_xdgE $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
  res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=578 failed=0
XDG_DATA_HOME=/tmp/s5f1_xdgF ... [SUMMARY] passed=578 failed=0

# the R1-MED-2 half, now live: the suite alone, green with its HUD assertions in
XDG_DATA_HOME=/tmp/s5f1_xdgbg $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
  res://tests/headless_runner.tscn --quit-after 1200 -- --suite=test_s5_batteries_v2
[SUMMARY] passed=13 failed=0

# per-suite rows, final run vs R1's closing list (only the new test moves the total)
test_engine2_weapons 48, test_s4_batteries 19, test_p2b1_outfitting_panel 13,
test_p2b_services 14, test_s5_commerce 7, test_s5_ammo_cargo 14, test_s5_hardpoints 11
- all as R1 recorded; test_s5_batteries_v2 12 -> 13 (the new readout test) = 577 -> 578
```

Arithmetic: R1's closing gate was `577/0`; this pass adds **one** row
(`test_the_readout_follows_the_selected_barrels_own_pack` — 20 assertions over the payload,
the launch reading, the keyboard path and two presses, in the same suite's fixture idiom) →
`578/0`, twice, identical. No other suite's count moved.

## Files touched

- `vajb-orbit/game/game.gd` — `_hull_slot_cells` carries the cell's own barrel slot as `position`.
- `vajb-orbit/ui/hud/hud.gd` — `_active_barrel` beside `_active_slot`; `_cell_position`,
  `_barrel_of_battery`, `_battery_family`, `_set_barrel`; `select_battery`,
  `_on_weapon_slot_pressed` and `set_hull_slots` resolve the readout from the pushed cells.
- `vajb-orbit/tests/test_s5_batteries_v2.gd` — `HUD_NODE` `&"Hud"` (R1-MED-2); the new
  readout test (R1-MED-1).

Those three files are this pass's whole write set (no new file, no new `class_name`, so no
sidecar). `project.godot`, `docs/gameplay/18_engine_spec.md`, `docs/gameplay/08_ship_slots_modules.md`,
`assets/`, `addons/` and the theme carry no change from this pass; the working tree's other
modifications are the wave's (J1–J4 and R1's `docs/CONTRACTS.md` §9/§10 notes) and pre-date it.

## Follow-ups

| Item | Kind | Where |
|---|---|---|
| Record `position` beside §17's `battery` bullet (additive payload field) | docs, bucket 2 | `docs/CONTRACTS.md` §13/§11/§17 (developer) |
| The `_hull_slots` slot space and the component's barrel space diverge on a `w_mining` fit | LOW (pre-existing §16 rule 3) | `game/weapons.gd:512`, `game/game.gd:_launch_batteries` |

Nothing else is owed: no HIGH existed, both MED findings are closed, and no acceptance
number moved.
