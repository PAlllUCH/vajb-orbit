# P2-B proper — W1 report: the profile's fitting transactions and the legacy retirement

**Role:** W1 (coder — profile & retirement). **Files changed:** `vajb-orbit/autoload/player_profile.gd`,
`vajb-orbit/game/station_catalog.gd`, `vajb-orbit/tests/` (four existing files, one new suite, one new lint
probe). **Nothing else touched:** no assets, no theme, no `project.godot`, no `addons/`, no `docs/`.
Everything below is measured on this host (Godot 4.7.2.stable, Linux), with the command and the raw line
it produced.

**Headline numbers.**

| Measure | Value |
|---|---|
| Gate before (sandboxed `user://`, this host) | `[SUMMARY] passed=389 failed=0`, exit 0 — reproduces CONTRACTS §9's figure |
| Gate after (same command) | `[SUMMARY] passed=402 failed=0`, exit 0 |
| Growth | **+13** (one new suite, `test_p2b_retirement`, 13 tests) |
| v4 file with all six upgrades → | 6 inventory modules (1 each), 0 upgrade records, file rewritten as v5, `retire_legacy_upgrades()` second call **0** |
| Real game boot on a seeded v4 profile | file ends v5, `upgrades` key count **0**, six module records, **0** `SCRIPT ERROR` lines, exit 0 |
| Lint ledger (the wave's files, CONTRACTS §9's instrument) | **0** warning rows in all 7 linted; positive control 3+, negative control 0 |
| **One blocker, in W2's file set** | `ui/screens/station.gd:465` and `:486` still call the retired `Catalog.upgrade()`, so station.gd cannot recompile → **4** extra `SCRIPT ERROR` lines in the gate log (2 parse errors, 1 compile error, 1 invalid `new`) on top of the **1** pre-existing row the before-log already carries. See §7. |

---

## 1. What landed (CONTRACTS §13, the brief's §3.1)

`autoload/player_profile.gd`:

| Pin item | Where | Notes |
|---|---|---|
| `SAVE_VERSION := 5` | `player_profile.gd:44` | `MIN_READABLE_VERSION` stays 1 |
| Load path calls the migration when the file's version is below 5 | `player_profile.gd:793` | `if version < 5: retire_legacy_upgrades()`, immediately after `_read_values()`, which is where the record was read |
| `LEGACY_UPGRADE_MODULES` (six rows) | `player_profile.gd:99-104` | verbatim from §3.1, including the row comments |
| `EVENT_FIT_MODULE := "FIT_MODULE"` | `player_profile.gd:93` | next to `EVENT_BUY_MODULE` |
| `fit_module_at(ship_id, slot_key, index, module_id) -> bool` | `player_profile.gd:501` | guards in the pin's order: hull ∈ the nine → slot key ∈ `FitData.FIT_SLOT_KEYS` → `0 .. slot_capacity-1` → `module_count == 0` → candidate `fit_legal` |
| `clear_fit_slot(ship_id, slot_key, index) -> bool` | `player_profile.gd:534` | same three cell guards, then `FitData.MANDATORY_SLOT_KEYS` |
| `retire_legacy_upgrades() -> int` | `player_profile.gd:561` | idempotent; erases the key from the loaded `_config` and marks dirty so the flag day reaches disk |

**The mandatory-key list is not re-declared.** There is no `FIT_MANDATORY_KEYS` anywhere in the tree
(`grep -rn FIT_MANDATORY_KEYS` → `docs/CONTRACTS.md:1516` and D0's report only): both guards read
`FitData.MANDATORY_SLOT_KEYS` (`game/ship_fit.gd:117`), exactly as `FitData.FIT_SLOT_KEYS` already was.
That is D0's drift note 1 confirmed from the code side.

**Ordering, exactly as pinned.** Every refusal precedes every write, and the displacement precedes the take:

```gdscript
	var stored := _fit_entry(ship_id)                                   # before the write
	var displaced := StringName(_cell_id(fit_for(ship_id), slot_key, index))
	if displaced != &"":                                                # 1. the displaced module returns
		add_module(displaced, 1)
	take_module(module_id, 1)                                           # 2. the incoming one is taken
	set_fit_slot(ship_id, slot_key, index, module_id)                    # 3. the cell is written
	_announce_fit(ship_id, stored)                                      # 4. &"fits" is never silent
	Log.append(EVENT_FIT_MODULE, module_id, 1, 0, _credits)             # 5. one line
```

`clear_fit_slot` writes `&""` in step 3 and returns the module in step 1, as §3.1 asks.

**Both keys always signal.** `set_fit_slot` is silent when a write changes nothing (the no-op contract
every setter here keeps), so `_announce_fit` (`player_profile.gd:1019`) emits `&"fits"` itself in that one
case; the normal path emits once, from `set_fit_slot`, and never twice. Measured in
`test_the_install_targets_the_cell_it_is_given`, where the emitted list is asserted index by index:
`[modules, modules, fits]` — displace, take, write — and every key seen is one of the two.

**Two judgement calls the pin left open, both documented and reversible:**

1. **`clear_fit_slot` refuses a cell that already holds nothing** (`player_profile.gd:540`). §3.1 lists
   the refusals; an empty cell is not one of them, but "the cell's module returns to the inventory … one
   log line" has no meaning for an empty cell, and honouring it literally would write a
   `FIT_MODULE, "", 1, +0` phantom line. A refusal is the only shape that keeps "one line per
   transaction" true. Reversal: delete the `module_id == &""` guard, and the transaction becomes a
   silent no-op (or a phantom line).
2. **`_legacy_upgrade_ids` reads the record as an Array *or* a Dictionary of flags**
   (`player_profile.gd:871-889`). The shipped v4 shape is the Array of ids `_write_profile` persisted
   (`_names_to_strings(_upgrades)`), and §3.1's prose ("every id whose value is true") also covers a
   dict of flags, so both spellings migrate. Reversal: keep the `elif raw is Array` branch only.

## 2. The legacy surface, retired completely

Removed — `grep` finds no live reference to any of them:

| Removed | Was at | Now |
|---|---|---|
| `StationCatalog.UPGRADES` (six rows) + `UPGRADE_SLOTS` | `station_catalog.gd:9-16, 167-222` | gone; the header comment records the retirement and its successor modules |
| `StationCatalog.upgrade(id)` / `upgrade_ids()` | `station_catalog.gd:268, 280` | gone (`_find`/`_ids` stay: the other accessors use them) |
| `PlayerProfile.has_upgrade` / `installed_upgrades` / `install_upgrade` | `player_profile.gd:238-257` | gone |
| `_upgrades`, `_known_upgrades`, `KEY_UPGRADES` | `player_profile.gd:44, 105, 109` | gone |
| the `upgrades` read, default, write and reset touch | `_apply_defaults`, `_read_values`, `_write_profile`, `reset_to_defaults`, `_load_catalog` | gone; `KEY_RETIRED_UPGRADES` survives only as the migration's key name |

No dead branch, no commented-out row, no unused constant is left in the two files — and
`test_the_retired_surface_is_gone_from_the_two_sources` is the standing guard (source tokens in both
files, plus `get_method_list()` on a live instance).

## 3. The migration, measured

Fixture written by the suite itself (`_write_fixture`): the retired record plus the keys every version
has carried, so nothing about the shape is invented.

| Case | Command (suite-scoped gate) | Result |
|---|---|---|
| v4, all six installed | `... --suite=test_p2b_retirement` → `test_a_v4_file_with_all_six_upgrades_loads_as_six_modules` | `modules().size() == 6`; each of `p_mk2, s_heavy, e_ion, c_scanner, u_cargo, u_drones` at count **1**; each of the six retired ids at count **0** |
| the same file on disk after the load | inside the same test | `save_version=5`, `has_section_key("upgrades") == false`, 6 module records |
| idempotence | same test | `retire_legacy_upgrades() == 0` and a **second load** reads 6 modules, not 12 |
| v1 file with `upgrades=["upgrade_engine"]` | `test_a_v1_file_with_a_record_migrates_too` | `e_ion` ×1, `modules().size() == 1`, credits read as they always were |
| v3 file with no record | `test_a_pre_v5_file_without_the_record_is_left_alone` | credits 1234 read, inventory empty, migration 0, and the on-disk file **stays v3** (nothing to migrate ⇒ no rewrite) |

**End to end, on a real boot** (`res://ui/screens/boot.tscn`, sandboxed `XDG_DATA_HOME`, bounded
`--quit-after 400`): a v4 profile seeded with all six upgrades and `credits=4321` came back as

```
save_version=5
credits=4321
modules={ c_scanner, e_ion, p_mk2, s_heavy, u_cargo, u_drones — "count": 1 each }
```

with zero occurrences of `upgrades` in the file, zero `SCRIPT ERROR` lines in the boot log and exit 0.
So the flag day is one-way, it writes itself, and the game boots through it.

**When the flag day reaches disk.** The migration's write rides the same 0.5 s debounced save as every
other write (`_mark_dirty` → `_save_timer`), so it lands within half a second of any real boot — measured
above. A *tests-only* headless run quits inside that window: a copy of the owner's own v4 profile
(sandboxed, `XDG_DATA_HOME`, `md5` of the original unchanged) still read `save_version=4` with
`upgrades=[]` after a full gate run, because no frame of the debounce elapsed and the record it dropped
was empty anyway. Flagged so nobody reads a v4 file after a test run as a failed migration; the game
itself is the instrument that persists it.

## 4. The transactions, measured

Fighter (`ship_fighter`), 09 §9's delivered fit: `e_std`, `p_std`, 2× `w_laser`, `s_light`,
`h_plate_light` — 4 of its 6 power.

| Test | Call | Result (fit / inventory / log) |
|---|---|---|
| `test_the_install_targets_the_cell_it_is_given` | `fit_module_at(fighter, weapons, 1, w_cannon)` | `weapons == ["w_laser", "w_cannon"]` (cell 0 untouched), `w_cannon` 0, `w_laser` 1 |
| `test_a_swap_hands_the_displaced_module_back` | cannon into cell 0, then `w_laser` into cell 0 | `w_laser` 2 → 1, `w_cannon` 0 → 1, `weapons == ["w_laser", "w_laser"]` |
| `test_clear_returns_the_module_and_empties_the_cell` | `clear_fit_slot(fighter, weapons, 0)` | cell `""`, `w_laser` 1; the second call **false**, no signal, no line |
| `test_a_mandatory_cell_is_never_emptied` | `clear_fit_slot(…, engines, 0)` / `(…, power, 0)` | both **false**; `engines == ["e_std"]`, `power == "p_std"`, inventory 0, log 0, signals 0 |
| the same test's allowed half | `fit_module_at(…, engines, 0, e_ion)` | `engines == ["e_ion"]`, `e_std` back in the inventory — swapped, never empty |
| `test_an_unowned_module_refuses` | `w_railgun` (count 0) and `&""` | both **false**; cells, inventory, log untouched, no signal |
| `test_the_cell_guards_refuse_before_any_write` | index = `slot_capacity`, index −1, `utility` on a hull with no U cell, `&"hulls"`, the NPC hull `ship_swarmer` | all **false**; nothing written, nothing taken, no line |
| `test_an_over_budget_candidate_refuses_before_any_write` | first `w_plasma` into cell 0 (legal, exactly 6/6), then a second one into cell 1 | first **true** (one line); `ShipFit.fit_legal` on the second candidate reads `out=6 draw=8 spare=-2 legal=false`; the call **false**, cell 1 keeps `w_laser`, plasma count stays 1, line count stays 1 |
| `test_one_fit_module_line_per_successful_transaction` | install + swap + remove | exactly **3** lines, each `FIT_MODULE`, qty `1`, delta `+0`, balance `10000`; a refused 4th call adds none |

Log line shape, verbatim from the raw run:
`<timestamp>, FIT_MODULE, w_cannon, 1, +0, 10000`.

## 5. Tests, and the ones that moved

**New:** `tests/test_p2b_retirement.gd` — 13 tests (list in §6.3's raw output). **New probes:**
`tests/probe_w1_lint.gd`/`.tscn` (the per-file warning ledger of §6.2) and
`tests/probe_w1_type_hole.gd`/`.tscn` (the guard hole of §6.4).

**Moved (sanctioned by the brief's §5, never an assertion whose subject stayed):**

| File | Change | Why |
|---|---|---|
| `tests/test_p1_profile.gd` | `installed_upgrades()` assertion deleted (defaults), the v1 fixture's `upgrades` key deleted, the `upgrade_engine` assertion deleted, `save_version` digit 4 → **5**, `install_upgrade` dropped from a comment, header note added | the whole retired surface: its three subjects (the default, the v1 read, the installed flag) now live in `test_p2b_retirement.gd` as the v5 migration |
| `tests/test_p2a_profile_fits.gd` | `test_a_v3_fit_loads_clean_and_the_first_write_persists_version_4` → `…_version_5`; `Profile.SAVE_VERSION` 4 → **5**; `save_version` on disk 4 → **5** | the wave's own bump; the test is the save-version canary, so the digit stays hard |
| `tests/probe_r1_migration.gd` | two `save_version == 4` checks → **5**, labels updated | a probe that measures the current writer must measure the current version |

**Left alone, deliberately:** `test_p1_profile.gd:160`'s module fixture still carries
`"base_id": "upgrade_generator"`. Its subject is the *modules round trip* (an instance id resolving to a
base id), not the catalogue, and the value is inert. Flagging it so R1 does not read it as a leftover
reference to the retired rows.

## 6. Evidence

### 6.1 The gate

```text
# sandboxed user:// (a scratch XDG_DATA_HOME), before any edit:
godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=389 failed=0                                # exit 0

# after:
[SUMMARY] passed=402 failed=0                                # exit 0
#   test_p2b_retirement 13 · test_p1_profile 11 · test_p2a_profile_fits 11 (unchanged counts elsewhere)
```

Logs: `.agents/gen/p2b_proper_w1_gate_before_sandbox.log`, `.agents/gen/p2b_proper_w1_gate_after.log`,
`.agents/gen/p2b_proper_w1_suite.log` (the new suite alone).

**Why the gate is run in a sandbox.** Against the owner's live `user://profile.cfg` the *same* unmodified
tree reads `passed=386 failed=3` (`.agents/gen/p2b_proper_w1_gate_before.log`): the three
`engine2_dock`/`engine2_fixes` ammo/dock tests fail because they *borrow the shipped autoload* and the
owner's profile now holds a real Vanguard fit (`fits.ship_vanguard.weapons = ["w_cannon","w_laser","w_laser"]`),
while `game.gd:_seed_ammo` reads `profile.ammo_of(<module id>)` against a store keyed by weapon *family*
(measured: with a fresh `user://` the same three pass — `[SUMMARY] passed=19 failed=0` for those two
suites). Pre-existing, data-dependent, unrelated to this pin, and not fixed here (it is `game.gd`'s and
the suites'); W1's own suites read 11/11 and 13/13 either way.

**The same measurement against a byte copy of the live profile** — the copy sandboxed, so the owner's file
is untouched (`md5` identical before and after), log
`.agents/gen/p2b_proper_w1_gate_after_liveprofile.log`: `[SUMMARY] passed=399 failed=3`, exit 1 — **+13
and the same three failures**, so this pass adds nothing to that set and loses nothing from it.

### 6.2 The lint ledger (CONTRACTS §9's instrument)

```text
godot --headless --debug --path vajb-orbit res://tests/probe_w1_lint.tscn --quit-after 600
[W1-LINT] debugger_active=true
player_profile.gd 0 · station_catalog.gd 0 · test_p2b_retirement.gd 0 ·
test_p1_profile.gd 0 · test_p2a_profile_fits.gd 0 · probe_r1_migration.gd 0 ·
probe_w1_type_hole.gd 0
POSITIVE-CONTROL weapons.gd: 3 WARNING rows   NEGATIVE-CONTROL world_clock.gd: 0
```

Log: `.agents/gen/p2b_proper_w1_lint.log`. `player_profile.gd` was already at zero in the UI-chrome
wave's D5 pass, so this pass adds no ledger row anywhere. The probe cannot lint itself: loading the
script that is currently executing with `CACHE_MODE_IGNORE` drops the debugger into its `debug>` prompt
and the run stops early (measured while the list still held it), so `probe_w1_lint.gd` is the one W1 file
this ledger does not name — it is 40 lines of `print` and `ResourceLoader.load` and it compiles clean in
every gate run.

### 6.3 The raw test output (new suite)

```text
godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200 -- --suite=test_p2b_retirement
[RUN] suites=test_p2b_retirement
[PASS] test_p2b_retirement.gd.test_a_mandatory_cell_is_never_emptied
[PASS] test_p2b_retirement.gd.test_a_pre_v5_file_without_the_record_is_left_alone
[PASS] test_p2b_retirement.gd.test_a_swap_hands_the_displaced_module_back
[PASS] test_p2b_retirement.gd.test_a_v1_file_with_a_record_migrates_too
[PASS] test_p2b_retirement.gd.test_a_v4_file_with_all_six_upgrades_loads_as_six_modules
[PASS] test_p2b_retirement.gd.test_an_over_budget_candidate_refuses_before_any_write
[PASS] test_p2b_retirement.gd.test_an_unowned_module_refuses
[PASS] test_p2b_retirement.gd.test_clear_returns_the_module_and_empties_the_cell
[PASS] test_p2b_retirement.gd.test_one_fit_module_line_per_successful_transaction
[PASS] test_p2b_retirement.gd.test_the_cell_guards_refuse_before_any_write
[PASS] test_p2b_retirement.gd.test_the_install_targets_the_cell_it_is_given
[PASS] test_p2b_retirement.gd.test_the_retired_surface_is_gone_from_the_two_sources
[PASS] test_p2b_retirement.gd.test_the_retirement_table_is_09s_lineage_rows
[SUMMARY] passed=13 failed=0
# exit 0, no SCRIPT ERROR, no warning attributed to the suite
```

### 6.4 The one guard the pin does not name (measured, reported, not fixed)

```text
$ godot --headless --path vajb-orbit res://tests/probe_w1_type_hole.tscn --quit-after 600
[W1-HOLE] e_std slot=engine, cell under test=weapons[0] slot=weapons
[W1-HOLE] before: weapons=["w_laser", "w_laser"] inventory={ "e_std": { "base_id": "e_std", "count": 1 } }
[W1-HOLE] fit_legal on the candidate: legal=true overflow={  } missing=[] duplicates=[]
           power={ &"out": 6, &"draw": 3, &"spare": 3, &"legal": true }
[W1-HOLE] fit_module_at(weapons, 0, e_std) -> true
[W1-HOLE] after:  weapons=["e_std", "w_laser"] inventory={ "w_laser": { "base_id": "w_laser", "count": 1 } }
[W1-HOLE] done
```

Log: `.agents/gen/p2b_proper_w1_type_hole.log` (exit 0). Neither `fit_module_at` nor
`ShipFit.fit_legal` compares the module's own `slot` with the cell's type, and the pin's refusal list is
exhaustive, so an engine can be fitted into a W cell through the API. The pane's ACTION gates that by the
module's own type (§3.2 / rule 6), which is why this is a note and not a change; closing it in the profile
would be one `ModuleCatalog.module(id)[&"slot"] == slot_key` comparison and would need the pin amended
first.

## 7. The one blocker, and it is W2's file

**Tier: HIGH — for W2, not for the wave's close-out.** Removing `StationCatalog.upgrade()` strands the
retired surface's last two call sites, and GDScript resolves a static call on a preloaded script constant
at **compile** time, not at run time (measured both ways: `--check-only` below, and a scratch probe whose
call to a nonexistent static was rejected with `Parse Error: Static function "does_not_exist()" not
found in base "StationCatalog"`).

```text
$ godot --headless --path vajb-orbit --check-only --script res://ui/screens/station.gd
SCRIPT ERROR: Parse Error: Static function "upgrade()" not found in base "StationCatalog".
          at: GDScript::reload (res://ui/screens/station.gd:465)
SCRIPT ERROR: Parse Error: Static function "upgrade()" not found in base "StationCatalog".
          at: GDScript::reload (res://ui/screens/station.gd:486)
ERROR: Failed to load script "res://ui/screens/station.gd" with error "Parse error".
```

and in the gate run itself (`.agents/gen/p2b_proper_w1_gate_after.log:305-333`): the two parse errors, a
`Compile Error: Failed to compile depended scripts` for `tests/test_p2b1_outfitting_panel.gd`, a
`Failed to load script` line, and — because the test still runs against a script that cannot
`new()` — `Invalid call. Nonexistent function 'new' in base 'GDScript'` at
`test_p2b1_outfitting_panel.gd:516`. That is the whole delta against the before-log, whose only
`SCRIPT ERROR` row is the pre-existing `Cannot call method 'call' on a previously freed instance.`
(`tests/test_weapon_fx_f4.gd`, LOW L61, present before this pass too). The **count stays green**
(`402/0`) precisely because that suite's nine tests report PASS anyway, which is why this is reported
rather than trusted.

`ui/screens/station.gd` is not in W1's file set (`VAJB_WORKER_FILES` is
`autoload/player_profile.gd, game/station_catalog.gd, tests/`, and the enforcement hook denies the edit),
so W1 cannot cure it. W2 owns the file and its prompt already covers the pane deletion; the whole fix is
four lines and is the same retirement's dead branches:

1. `station.gd:465-466` — `_owned_state_text`'s `if not Catalog.upgrade(id).is_empty(): return "ALREADY INSTALLED"`:
   drop both lines, so the fallback `return "ALREADY OWNED"` stands (the only caller it served was the
   retired pane).
2. `station.gd:486` — `_entry`'s `entry = Catalog.upgrade(id)` step: drop it (ammo → ship → module is the
   resolution order that remains), and update the doc line above it, which still says "the upgrades and
   the modules".

`ui/station/upgrades_panel.gd` carries the same kind of dead reference (`Catalog.UPGRADES` at `:133`,
`:167`, `:368`, `:369`, `install_upgrade`/`installed_upgrades`/`has_upgrade` through `profile.call` at
`:352`, `:367`, `:389`), and its deletion is already W2's deliverable, so nothing more is owed there.
`ui/screens/_mockup_station.gd:22` mentions `install_upgrade` in a doc comment only (it calls no profile
method at all) and the retired mockup is slated for deletion, so it is prose, not a caller.
Until those two edits land, the wave is green by count and red by log; after them, the four lines
disappear and the log returns to its one pre-existing row.

**New files carry their `.uid` sidecars** (`test_p2b_retirement.gd.uid`, `probe_w1_lint.gd.uid`,
`probe_w1_type_hole.gd.uid`, scaffolded by a bounded `--headless --editor --quit` pass, exit 0);
`project.godot` is byte-identical (`git status` shows it unmodified), so that pass touched nothing it
should not have.

## 8. Notes for R1 / the fixer

- **No other API or signal was reshaped.** `set_fit`, `set_fit_slot`, `clear_fit`, `fit_for`, `modules`,
  `module_count`, `add_module`, `take_module`, `buy_module`, `profile_changed`, `purchase_failed` and the
  save keys are byte-for-byte as P2-B1 left them; the only additions are §13's three constants and three
  functions (plus five private helpers).
- **A hole the pin does not close, measured, not fixed** — §6.4: an engine fits a W cell through
  `fit_module_at` today (`-> true`), because neither the guard list nor `fit_legal` compares the module's
  `slot` with the cell's type. The pin's list is exhaustive and rule 6 gates the *pane* by type, so W1
  implemented the list verbatim.
- **Probes:** `probe_w1_lint` and `probe_w1_type_hole` are W1's own and re-runnable byte-identically;
  every probe in `tests/` was grepped for the retired API (`has_upgrade`, `installed_upgrades`,
  `install_upgrade`, `Catalog.upgrade`, `Catalog.UPGRADES`) and none calls it (two of R1's own probes
  assert the save-version digit and were moved to 5, §5).
- **Reversal paths:** the mapping constant plus the catalogue rows restore the six-row surface; the label,
  rail entry and pane files restore UPGRADES (W2's side); a v5 file cannot be read by a v4 build
  (`version > SAVE_VERSION` → defaults), so the flag day is one-way on purpose, per §13 rule 2.
