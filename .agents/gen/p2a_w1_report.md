# P2-A — W1 report: the frame data (`ShipFit` grids + `ModuleCatalog`)

**Worker:** W1 (coder, the frame data). **Wave:** P2-A ship slot frames.
**Brief (law):** `.agents/gen/p2a_slot_frames_wave_task.md` §3 (the pin) + §4 row W1 + §6.
**File set (`VAJB_WORKER_FILES`):** `vajb-orbit/game/ship_fit.gd`,
`vajb-orbit/game/module_catalog.gd`, `vajb-orbit/tests/`. Two shipped files touched, one
created, one suite created; **no** `assets/**`, no theme, no `project.godot`, no
`addons/**`, no `docs/**`.
**Status:** complete. Gate green and grown; every pinned item of §3 is implemented
verbatim; no number invented.

---

## 1. Files changed

| File | Change |
|---|---|
| `vajb-orbit/game/ship_fit.gd` | +398 / −186. `SLOT_GRIDS` (nine matrices), `SLOT_TOKEN_KEYS`, `FIT_SLOT_KEYS`, `MANDATORY_SLOT_KEYS`, `ENGINE_MULT_CEILING`, `MOUNT_SPREAD`, `STANDARD_FITS`; the nine query/validator statics (`grid_rows`, `grid_size`, `grid_cells`, `grid_counts`, `slot_capacity`, `fit_legal`, `standard_fit`, `mount_offset`) plus three private helpers; `MODULES` becomes the alias of `ModuleCatalog.MODULES`; `STANDARD_FIT` becomes the alias of `STANDARD_FITS[&"ship_vanguard"]`; `HULLS`' three △ `weapons` rows move; `fitted_ids` reads the engine **set** first and tolerates the legacy singular `engine`; `_apply_speed` sums the engine deltas and clamps them once. |
| `vajb-orbit/game/module_catalog.gd` | **new** (`class_name ModuleCatalog extends RefCounted`). The 32 rows with `name`/`slot`/`draw`/`tier`/`cost`/`icon`/`effects`, plus `module`, `icon_path`, `slot_of`. |
| `vajb-orbit/tests/test_ship_grids.gd` | **new** suite, 27 tests (see §6). |

`.uid` sidecars for the two new files are written by the editor's filesystem watcher, as
for every other script in the project.

## 2. The per-hull derived counts (measured)

Read out of `ShipFit.grid_counts` by `tests/probe_w1_frames.gd` (a throwaway probe,
deleted after this table was captured; the same numbers are asserted cell by cell against
08 §3's own table by `test_document_counts_table_matches_grid_counts_cell_by_cell`).
`grid` is `grid_size`; `total` is the non-gap cell count, 08 §3's Total column.

| hull_id | class | grid | E | P | W | S | H | C | B | U | total | `HULLS[id].weapons` |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `ship_fighter` | Fighter (Lancer, Light) | 4x3 | 1 | 1 | 2 | 1 | 1 | 1 | 1 | 0 | **8** | 2 |
| `ship_vanguard` | Cutter (Vanguard, Light) | 4x4 | 1 | 1 | 3 | 1 | 2 | 1 | 1 | 1 | **11** | 3 |
| `ship_miner` | Miner (Delver, Medium) | 4x4 | 2 | 1 | 2 | 1 | 2 | 1 | 0 | 3 | **12** | 2 |
| `ship_trader` | Trader (Courier, Medium) | 4x4 | 2 | 1 | 1 | 1 | 2 | 2 | 1 | 3 | **13** | 1 |
| `ship_corvette` | Corvette (Spearhead, Light) | 4x4 | 1 | 1 | 4 | 2 | 2 | 1 | 1 | 1 | **13** | 4 |
| `ship_freighter` | Hauler (Mule, Heavy) | 4x5 | 3 | 1 | 1 | 1 | 3 | 1 | 0 | 5 | **15** | 1 |
| `ship_gunship` | Gunship (Bulwark, Medium) | 4x5 | 2 | 1 | 5 | 2 | 2 | 1 | 0 | 1 | **14** | 5 |
| `ship_patrol` | Frigate (Warden, Heavy) | 4x5 | 2 | 1 | 4 | 2 | 3 | 2 | 1 | 2 | **17** | 4 |
| `ship_destroyer` | Destroyer (Obliterator, Capital) | 5x6 | 3 | 1 | 7 | 3 | 4 | 2 | 1 | 2 | **23** | 7 |

Totals column reads **8 / 11 / 12 / 13 / 13 / 15 / 14 / 17 / 23**, the brief's list, and
each row's `HULLS[id].weapons` equals its W count (rule 5; that is what turned W3's
one red at the pre-change baseline green). `sum(grid_counts) == total` and
`grid_cells.size() == cols * rows` are both asserted, so a gap can never be counted as a
cell.

The three △ rows this worker moved, and only those: `ship_fighter` 3 → **2**,
`ship_vanguard` 4 → **3**, `ship_corvette` 3 → **4** (08 §3/§2's amendment, owner tick 1).

## 3. The engine-sum arithmetic, before and after

Before = the pre-amendment per-engine **product** (`_apply_speed`'s old loop). After =
09 §3.7's **sum of deltas**, the speed multiplier clamped to `ENGINE_MULT_CEILING` 1.40
and the turn multiplier unclamped. Both columns for "after" are measured: `resolve`'s own
`max_speed`/`turn_rate` divided by the `HANDLING` base of `ship_freighter`
(293.0 u/s, 0.75 rad/s). `before` is the product of the same shipped module rows.

| engine set | before speed | after speed (sum) | after speed (clamped) | before turn | after turn | legal |
|---|---|---|---|---|---|---|
| `[e_std]` | 1.0000 | 1.0000 | 1.0000 | 1.0000 | 1.0000 | yes |
| `[e_ion]` | 1.1500 | 1.1500 | 1.1500 | 1.0000 | 1.0000 | yes |
| `[e_vector]` | 1.2500 | 1.2500 | 1.2500 | 1.2000 | 1.2000 | yes |
| `[e_std, e_std]` | 1.0000 | 1.0000 | 1.0000 | 1.0000 | 1.0000 | yes |
| `[e_std, e_ion]` | 1.1500 | 1.1500 | 1.1500 | 1.0000 | 1.0000 | yes |
| `[e_std, e_vector]` | 1.2500 | 1.2500 | 1.2500 | 1.2000 | 1.2000 | yes |
| `[e_std, e_ion, e_vector]` | **1.4375** | 1.4000 | **1.4000** | 1.2000 | 1.2000 | yes |
| `[e_ion, e_vector]` | 1.4375 | 1.4000 | 1.4000 | 1.2000 | 1.2000 | yes |
| `[e_ion, e_ion]` | 1.3225 | 1.3000 | 1.3000 | 1.0000 | 1.0000 | **no** (duplicate) |
| `[e_vector, e_vector]` | 1.5625 | 1.5000 | 1.4000 | 1.4400 | 1.4000 | **no** (duplicate) |
| `[e_vector, e_vector, e_vector]` | 1.9531 | 1.7500 | 1.4000 | 1.7280 | 1.6000 | **no** (duplicate) |

Measured speeds on the Hauler's 293.0 base, same probe: `[e_std]` 293.0000, `[e_ion]`
336.9500, `[e_vector]` 366.2500, `[e_std, e_ion, e_vector]` 410.2000 (= 293 × 1.40, where
the old product would have given 421.24).

Three facts the table settles, all asserted in the suite:

1. **A single engine is unchanged.** Every one-engine row's `before` and `after` are
   identical, including `e_vector` (1.2500 speed, 1.2000 turn), which is 09 §3.7
   consequence 2. `STANDARD_FIT` carries exactly one `e_std`, so every shipped launch
   resolves byte-for-byte as before.
2. **The sum bites only where the product did.** `[e_ion, e_ion]` moves 1.3225 → 1.3000,
   `[e_std, e_ion, e_vector]` 1.4375 → 1.4000; every legal single-per-id set of one or
   two engines is arithmetically identical to the product it replaces, because
   `1 + (m1 − 1) + (m2 − 1)` equals `m1 × m2` when one of the two is `e_std` (m = 1).
3. **The ceiling is the speed multiplier's only.** Three vectors clamp to 1.4000 speed
   while their turn sum rides to 1.6000 (measured), and `_clamp` never touches
   `turn_rate`.

## 4. Which direction shipped for the one literal, and why

CONTRACTS §11 allows either direction; **the literal lives in
`game/module_catalog.gd` and `ShipFit.MODULES` is the alias**, the preferred direction:

```gdscript
const MODULES: Dictionary = ModuleCatalog.MODULES   # ship_fit.gd
```

The engine accepted the cross-file const reference (verified in a scratch
`--script` probe before the edit: `const M := ShipFit.MODULES` printed size 32), and this
direction keeps the dependency one-way (`ShipFit` → `ModuleCatalog`, never back), so
`ModuleCatalog` stays readable on its own and a future `ModuleCatalog` helper cannot
create a cycle with `class_name ShipFit`. `_row(id)` and `_warn_unknown` now read through
`ModuleCatalog.module(id)` / `ModuleCatalog.MODULES`, so the draw, the slot type and the
effects have exactly one literal.

The identity is provable, not merely equal-by-value: `test_module_catalog_is_the_one_literal_ship_fit_aliases`
asserts `ShipFit.MODULES[&"w_laser"].has(&"name")` and `.has(&"icon")`, keys the
pre-wave literal did not carry, so the two names demonstrably read one dictionary. All
four shipped consumers (`game/player_ship.gd:919`, `tests/test_engine_c3_flight_decay.gd`,
`tests/test_combat_repair_c5.gd`, `tests/test_flight_feel_g1.gd`, plus
`tests/probe_c3_flight_decay.gd`) keep indexing `ShipFit.MODULES[id][&"effects"]`
unchanged.

**One more alias, same reason:** `STANDARD_FIT` is now
`const STANDARD_FIT: Dictionary = STANDARD_FITS[&"ship_vanguard"]` rather than a second
literal. 09 §9 says it "stays as the one alias existing callers and tests already use" and
CONTRACTS §11 rule 2 says it must "resolve unchanged"; both hold. Its shape did change in
one respect a caller could see: the row now spells the engine key `engines` (an array of
one) instead of the legacy singular `engine`. `resolve`, `fitted_ids` and `power_budget`
accept both spellings, and
`test_legacy_singular_engine_key_resolves_identically` proves a legacy-shaped fit and the
shipped row produce the same `fitted_ids` list, the same snapshot fields and the same
budget. No test in the tree reads `STANDARD_FIT[&"engine"]` (checked by grep before the
change).

## 5. Decisions the pin left open (each reported, none of them a new number)

1. **`duplicates` holds slot keys, not module ids.** `{legal, overflow, missing,
   duplicates, power}` fixes a `duplicates: Array[StringName]` but not its currency. It is
   the slot keys whose fitted set repeats an id (`[&"engines"]`, `[&"computers"]`), the
   same currency as `missing`, so a panel can mark the cells it must clear with one lookup.
   Documented in `fit_legal`'s doc block and asserted by
   `test_duplicate_engines_are_refused_but_the_reference_engine_may_repeat`.
2. **`fit_legal` on a hull with no grid answers `legal: false`** (with the full shape and
   no error). The pin fixes the empty shapes only for `grid_rows`/`grid_cells`/
   `grid_counts`/`slot_capacity`/`standard_fit`; rule 6's "NPCs do not fit modules" is what
   makes `false` the honest answer, and `standard_fit` returning `{}` means there is
   nothing legal to fit anyway.
3. **Two supporting consts were added** so the duplicate rule names its own inputs instead
   of burying them in a loop: `DUPLICATE_GUARD_KEYS = [&"engines", &"computers"]`
   (09 §4 item 4) and `REFERENCE_ENGINE_ID = &"e_std"` (09 §3.7's by-hand exception:
   "`e_std` + `e_std` is legal ... but `e_vector` + `e_vector` is refused"). Both are
   additive public consts; neither carries a number 09 does not state.
4. **`_single_slot` (`power`) also accepts an `Array`**, taking its first non-empty entry.
   The pin only requires the legacy tolerance for `engine`, but W2's normaliser and the
   legacy `Array`-grown spelling both hand single-valued types over as arrays, and a
   tolerance that silently reads the first id is cheaper than a cross-worker integration
   break. The pinned one-id spelling is untouched.
5. **`SINGLE_SLOT_KEYS` stays published but is now unread** by this file (`fitted_ids`
   reads the engine set itself, rule 3). It keeps the pre-wave surface intact rather than
   deleting a public const mid-wave; a doc block above it says so. `LIST_SLOT_KEYS` is
   still `fitted_ids`' list order, which is what keeps weapons first.

## 6. The suite that moves the gate, and the raw output

`tests/test_ship_grids.gd`, 27 tests. **It parses the document**: `_document_grids()`
reads 08 §3.2's fenced block out of `res://../docs/gameplay/08_ship_classes.md` (verified
reachable from a project run: 15 352 chars), takes each hull's `(cols x rows)` header and
its following grid rows, and strips the cosmetic spaces exactly as `SLOT_GRIDS` does;
`_document_counts()` reads 08 §3's markdown table, takes the column letters from its own
header row, strips the `△` marks and returns `{cells: {letter: int}, total: int}`. Both
parsers assert their own shape (nine hulls, a 12-column header) so a failed parse cannot
pass vacuously.

What each test binds:

| Test | Assertion |
|---|---|
| `test_document_matrix_block_equals_slot_grids` | every hull's rows equal `SLOT_GRIDS`, row by row, spaces removed |
| `test_document_matrix_dimensions_match_grid_size` | `grid_size` == the block's `(cols x rows)` and == its own rows' shape |
| `test_document_counts_table_matches_grid_counts_cell_by_cell` | `grid_counts` == 08 §3's E/P/W/S/H/C/B/U columns, and the row sums to Total |
| `test_capacities_sum_to_the_documented_totals` | the nine totals 8/11/12/13/13/15/14/17/23; `slot_capacity` == the grid count; one cell per matrix position; gaps are not cells |
| `test_hull_weapons_equals_the_grid_count` | `HULLS[id].weapons` == `grid_counts(...)[weapons]` == `slot_capacity(...)`, all nine (rule 5) |
| `test_token_keys_cover_every_letter_used_and_nothing_else` | the eight letters map as pinned; no matrix carries an unmapped character |
| `test_fit_slot_keys_and_mandatory_keys_are_the_pinned_order` | `FIT_SLOT_KEYS` and `MANDATORY_SLOT_KEYS` in order |
| `test_engine_mult_ceiling_and_mount_spread_are_the_pinned_values` | 1.40 and (0.34, 0.22) |
| `test_grid_cells_are_row_major_with_gaps_included` | row-major, equal-length rows, `col`/`row`/`token`/`gap`, a gap has `""` type and index −1 |
| `test_grid_cells_indices_are_contiguous_per_type` | 09 §4.5's layout index: 0..n−1 row-major within each type, reaching capacity |
| `test_fitted_ids_keep_the_resolution_order` | weapons first, then shields/armour/computers/boosters/utility, then engines, then power (rule 3) |
| `test_unknown_and_npc_hulls_return_the_empty_shapes` | all ten NPC ids plus a bogus id: `[]`, `[]`, ZERO, 0, `{}`, `Vector2.ZERO`, eight 0-counts, `legal: false` |
| `test_standard_fits_are_the_nine_documented_rows` | `STANDARD_FITS` == 09 §9's nine rows, transcribed |
| `test_every_standard_fit_is_legal_on_its_own_hull` | `fit_legal` on its own hull: legal, nothing overflowing, missing, duplicated, and inside its power budget |
| `test_standard_fit_alias_stays_the_vanguard_row` | the alias carries `engines`, not `engine`, and equals both `STANDARD_FITS[vanguard]` and `standard_fit(vanguard)` |
| `test_missing_mandatory_cells_are_reported` | 09 §4.1: an empty fit misses `engines` + `power`; a 2-engine hull on one engine misses exactly `engines`; a 3-cell hull's mandatory set is complete |
| `test_duplicate_engines_are_refused_but_the_reference_engine_may_repeat` | `e_std`+`e_std` legal; `e_vector`+`e_vector` refused naming `engines`; `e_std`+`e_vector` legal; `c_target`+`c_target` refused naming `computers`; repeated plates/shields legal |
| `test_power_overflow_is_reported_per_slot` | `{weapons: 2}` on a 1-W hull, and `fit_legal`'s power block == `power_budget` |
| `test_a_single_engine_resolves_to_the_pre_amendment_figure` | all nine hulls: one `e_std` is exactly the base speed and turn; `e_vector` alone is 428.0 × 1.25 and × 1.20; `e_ion` alone × 1.15 |
| `test_the_engine_set_sums_its_deltas_and_clamps_at_the_ceiling` | `e_std`+`e_ion`+`e_vector` == 1.40 and legal on a 3-cell hull; the sum proves `e_std`+`e_ion` = 1.15; three vectors clamp speed to 1.40 while turn reaches 1.60 and the validator refuses the set |
| `test_legacy_singular_engine_key_resolves_identically` | the legacy singular key (id **and** `Array`) lists the same ids, resolves the same snapshot fields and the same budget as the array-shaped fit |
| `test_engines_key_wins_over_the_legacy_engine_key` | both keys present: `engines` wins, including an empty `engines` (presence decides, not length) |
| `test_mount_offset_is_the_documented_formula` | 09 §8's `((col + 0.5) / cols − 0.5, (row + 0.5) / rows − 0.5) × MOUNT_SPREAD` for **every** cell of every hull |
| `test_mount_offset_is_zero_where_there_is_no_cell` | index == capacity, an unknown slot type and a negative index all give ZERO, plus the Trader's worked example |
| `test_module_catalog_carries_the_pinned_rows` | 32 rows, each with exactly seven keys, name/tier/cost/draw/slot per 09 §3's tables and effects verbatim |
| `test_module_catalog_is_the_one_literal_ship_fit_aliases` | the alias sees the catalogue's `name`/`icon` keys; unknown id → `{}` / `&""` / `""` |
| `test_module_icon_rule_and_files_on_disk` | every id: `icon_path(id)` == the rule's path == the row's `icon`, and that file exists |

Raw output of the new suite (workspace run, project root `vajb-orbit/`):

```text
$ godot --headless --path . res://tests/headless_runner.tscn --quit-after 1200 -- --suite=test_ship_grids
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
[RUN] suites=test_ship_grids
[PASS] test_ship_grids.gd.test_a_single_engine_resolves_to_the_pre_amendment_figure
[PASS] test_ship_grids.gd.test_capacities_sum_to_the_documented_totals
[PASS] test_ship_grids.gd.test_document_counts_table_matches_grid_counts_cell_by_cell
[PASS] test_ship_grids.gd.test_document_matrix_block_equals_slot_grids
[PASS] test_ship_grids.gd.test_document_matrix_dimensions_match_grid_size
[PASS] test_ship_grids.gd.test_duplicate_engines_are_refused_but_the_reference_engine_may_repeat
[PASS] test_ship_grids.gd.test_engine_mult_ceiling_and_mount_spread_are_the_pinned_values
[PASS] test_ship_grids.gd.test_engines_key_wins_over_the_legacy_engine_key
[PASS] test_ship_grids.gd.test_every_standard_fit_is_legal_on_its_own_hull
[PASS] test_ship_grids.gd.test_fit_slot_keys_and_mandatory_keys_are_the_pinned_order
[PASS] test_ship_grids.gd.test_fitted_ids_keep_the_resolution_order
[PASS] test_ship_grids.gd.test_grid_cells_are_row_major_with_gaps_included
[PASS] test_ship_grids.gd.test_grid_cells_indices_are_contiguous_per_type
[PASS] test_ship_grids.gd.test_hull_weapons_equals_the_grid_count
[PASS] test_ship_grids.gd.test_legacy_singular_engine_key_resolves_identically
[PASS] test_ship_grids.gd.test_missing_mandatory_cells_are_reported
[PASS] test_ship_grids.gd.test_module_catalog_carries_the_pinned_rows
[PASS] test_ship_grids.gd.test_module_catalog_is_the_one_literal_ship_fit_aliases
[PASS] test_ship_grids.gd.test_module_icon_rule_and_files_on_disk
[PASS] test_ship_grids.gd.test_mount_offset_is_the_documented_formula
[PASS] test_ship_grids.gd.test_mount_offset_is_zero_where_there_is_no_cell
[PASS] test_ship_grids.gd.test_power_overflow_is_reported_per_slot
[PASS] test_ship_grids.gd.test_standard_fit_alias_stays_the_vanguard_row
[PASS] test_ship_grids.gd.test_standard_fits_are_the_nine_documented_rows
[PASS] test_ship_grids.gd.test_the_engine_set_sums_its_deltas_and_clamps_at_the_ceiling
[PASS] test_ship_grids.gd.test_token_keys_cover_every_letter_used_and_nothing_else
[PASS] test_ship_grids.gd.test_unknown_and_npc_hulls_return_the_empty_shapes
[SUMMARY] passed=27 failed=0
```

exit 0. No `SCRIPT ERROR`, no RID-leak line, no `WARNING` attributed to
`ship_fit.gd`, `module_catalog.gd` or `test_ship_grids.gd` under the §9 instrument
(`--headless --debug`; see §7).

## 7. Gate evidence

| Run | Result |
|---|---|
| Full gate, before my first edit (`/tmp/w1_gate_before.log`) | `passed=314 failed=1`, exit 1. The one red was **not** mine and **not** pre-existing: W3's `test_p2a_ship_roster.gd.test_hardpoints_match_the_hull_grid_count`, waiting on this worker's `HULLS.weapons` |
| Full gate, mid-pass (`/tmp/w1_gate_mid2.log`) | `passed=314 failed=1`, exit 1. W3's red closed by this change; the new red was W2's in-flight `SAVE_VERSION := 4` against the not-yet-updated `test_p1_profile.gd:204` |
| **Full gate, final (`/tmp/w1_gate_final.log`)** | **`passed=353 failed=0`, exit 0**, 29 suites, `test_ship_grids.gd` 27 of them |
| New suite alone | `passed=27 failed=0`, exit 0 |

The count arithmetic closes exactly: baseline 315 total (314 green + W3's 1 red) + this
worker's 27 + W2's `test_p2a_profile_fits.gd` 11 = **353**, all green. The count neither
shrank nor hid a failure; the one red of each intermediate run belongs to another worker's
file set and was cleared inside that set.

**Warning ledger (CONTRACTS §9's instrument).** `godot --headless --debug ... ` over the
whole gate: 43 `WARNING:` lines, grouped by attribution 8 `tests/test_engine2_cleaving.gd`,
7 `game/speed_fantasy.gd`, 4 `game/npc_ship.gd`, 4 `game/npc_brain.gd`, 3
`tests/test_p1_market.gd`, 3 `game/projectile.gd`, 3 `game/npc_registry.gd`, 3
`game/asteroid.gd`, 1 each `ui/hud/target_reticle.gd`, `ui/hud/minimap.gd`,
`tests/test_weapon_fx_f1.gd`, `tests/test_p2a_ship_roster.gd` (W3's `const ShipFit`
shadowing the global class), `tests/test_p1_repairs.gd`, `tests/test_engine2_npc.gd`.
**Zero** are attributed to `game/ship_fit.gd`, `game/module_catalog.gd` or
`tests/test_ship_grids.gd`. The first version of the new suite had one (a local named
`reference`, shadowing `RefCounted.reference`) and it was renamed before this run. The
ten NPC ids plus a bogus id are exercised in that same run and produce no warning and no
error, which is the "no `push_error`, no warning" half of rule 6 measured rather than
asserted.

**One environment note for the wave, not a finding.** A brand-new `class_name` script is
invisible to a headless run until the editor rewrites
`.godot/global_script_class_cache.cfg`: the first gate run after `module_catalog.gd`
appeared failed with `Parse Error: Identifier "ModuleCatalog" not declared` and
`Assigned value for constant "MODULES" isn't a constant expression`. A
`filesystem_manage(op="scan")` against the open editor registered it
(`global_class_count: 89`) and every run since is clean. This is the pre-existing
`class_name` bootstrap, not a defect of this change; the wave's close-out gate should run
after a scan/import for the same reason.

## 8. Tests that move, and the pins left alone

- **No existing test was edited** by this worker. The two files the brief sanctions as
  moving (`tests/test_ui_slot_layout.gd`, `tests/test_p1_profile.gd`) are W5's and W2's,
  and neither was touched here.
- `docs/**` untouched (D0's). `assets/**` untouched: no file there was created, modified
  or renamed, and `ui/theme/vajb_theme.tres`, `project.godot` and `addons/**` are
  untouched. `module_catalog.gd` only *references* icon paths that already exist, and the
  suite asserts each of those 32 paths resolves on disk, so no load is left
  environment-deferred by this pass.
- The §2/§3/§7 pins stand: `resolve`'s signature and its 09 §5 order, `fitted_ids`'
  weapon-first order, `power_budget`'s four keys, `HULLS`' other eight columns and all
  nine `HANDLING` rows, `STANDARD_FIT`'s resolution, the `MODULES[id][&"effects"]` index.
- 08 §3.2's nine matrices are **not** tidied and carry no gap the block does not print;
  no number moved outside 08 §3's △ rows (fighter/vanguard/corvette `weapons`).
- `docs/gameplay/18_engine_spec.md` untouched (owner-locked); no §13 row moved.

## 9. Staged, and read-but-not-edited

- **Mount-anchor consumption in flight** (09 §8, 08 §3.3): out of scope per brief §7
  item 1. `mount_offset` lands as data plus API; W4 flips
  `player_ship.thruster_anchors()` to one point per engine cell (brief §10 item 1) and the
  feel lane owns the weapon muzzles.
- **`MODULE_EFFECTS` in `ModuleCatalog`** stays effects-only: weapon damage, families and
  ammo are `weapons.gd`'s and `PlayerState`'s (docs 18 §4.1), and the fitting panel,
  module shop and UPGRADES retirement are P2-B (brief §7 item 2). `cost`/`tier` ship as
  data for that wave; nothing in this wave spends them.
- `game/player_state.gd`, `ui/hud/hud.gd`, the station panels, `game/player_ship.gd`,
  `autoload/player_profile.gd` and `game/station_catalog.gd` were **read** (to keep the
  four shipped `MODULES` consumers and W2's `fit_for` shape honest) and **not edited**.
- The throwaway `tests/probe_w1_frames.gd` (the probe behind §2/§3's measured tables) is
deleted; those numbers live in this report and in the suite's own assertions, so nothing
needs re-running to reproduce them.
