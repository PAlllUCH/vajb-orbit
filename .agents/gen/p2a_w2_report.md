# W2 — the profile's fit storage (wave P2-A, save v4) — report

**Status:** complete. The pinned API of `docs/CONTRACTS.md` §11 is implemented,
the gate is green with the count grown, and the v1–v3 migration read is measured
end to end.

**Files in this worker's set**

| File | Change |
|---|---|
| `vajb-orbit/autoload/player_profile.gd` | the pinned fit API + inventory helpers, `SAVE_VERSION` 3 → 4, `MIN_READABLE_VERSION` stays 1 |
| `vajb-orbit/tests/test_p2a_profile_fits.gd` | **new**, 11 tests |
| `vajb-orbit/tests/probe_p2a_fits_migration.gd` | **new**, the re-runnable migration evidence probe |
| `vajb-orbit/tests/test_p1_profile.gd:204` | the sanctioned one-line pin: `save_version` 3 → 4 |
| `.agents/gen/p2a_w2_report.md`, `.agents/gen/p2a_w2_probe.txt` | this report and its raw capture |

Nothing else was touched: no `assets/**`, no theme, no `project.godot`, no
`addons/**`, no `docs/**`, no other worker's file (`git status --short` lists my
files and no others).

---

## 1. What was built

`autoload/player_profile.gd` — the §11 block, verbatim in name and signature:

| API | Line | Behaviour |
|---|---:|---|
| `const FitData := preload("res://game/ship_fit.gd")` | 27 | capacity, `FIT_SLOT_KEYS`, the nine player hulls |
| `const SAVE_VERSION := 4` / `MIN_READABLE_VERSION := 1` | 31 / 32 | writes persist v4, v1–v3 still load |
| `fit_for(ship_id) -> Dictionary` | 386 | the hull's fit at capacity, `Array[String]` values, `FIT_SLOT_KEYS` keys; `{}` only for an unknown hull |
| `set_fit(ship_id, fit) -> bool` | 402 | normalise to the hull's shape, persist the array shape |
| `set_fit_slot(ship_id, slot_key, index, module_id) -> bool` | 423 | one cell by the 09 §4.5 layout index, refused out of range |
| `clear_fit(ship_id) -> void` | 449 | drop the hull's fit, silent when there is none |
| `base_module_id(entry) -> StringName` | 296 | instance id → `_modules[..].base_id`; the entry itself when unknown |
| `module_count(module_id) -> int` | 310 | the record's `count`, 0 for an id the inventory lacks |
| `add_module(module_id, count := 1) -> void` | 324 | create-or-add, `&"modules"` |
| `take_module(module_id, count := 1) -> bool` | 341 | refuse short, erase at zero, `&"modules"` |

Existing signals, behaviour and shape: `profile_changed(&"fits")` on a fit write
and `&"modules"` on an inventory write (the two keys §11 names, both pre-existing
and non-negotiable), no new persisted key, and `fits()` (`:358`), `set_fits()`
and every other public method are byte-for-byte as they were. §11's normalisation
rule is `_normalise_fit()` (`:866`): a v1–v3 single id is read as a one-element
array padded to capacity, the file is never written at load, and every write
persists the array shape.

## 2. Interpretations the pin left open

Each is a decision, not a discovery; nothing in §11 is contradicted.

1. **`power` is one module id, not a one-element array** (`fit_for`'s return, and
   what a write persists). §11's rule 1 says "power is one module id", while
   `fit_for`'s comment says "every type at its hull capacity" — for POWER those
   two readings differ. Rule 1 wins because a fit is consumed by
   `ShipFit.resolve()`, whose `_single_slot()` accepts a `String`/`StringName`
   only, and because W1's `STANDARD_FITS` (09 §9's table) carries `&"power":
   &"p_std"` as a scalar: a scalar power is the only shape that passes from
   `fit_for` into `resolve` unchanged. A stored *array* for power is still read
   (its first non-empty id), so the tolerance runs one way. Reversal: read the
   array in `fit_for` and let the caller unbox it.
2. **A known hull with no stored fit answers the all-empty shape at capacity**,
   not the standard fit ("{} only for an unknown hull id", §11; 09 §9 keeps
   `ShipFit.standard_fit` as the *launch's* fallback). W4 therefore decides the
   fallback, and can also read `fits().has(String(hull))` to tell "nothing
   stored" from "stored empty".
3. **`set_fit` cuts a too-long tail at capacity and does not check legality.**
   The store's shape is the hull's shape (§11 rule 1 + 09 §4.5's index), and
   09 §4's capacity/power/duplicate rules are `ShipFit.fit_legal`'s, with P2-B
   owning the refusal. Reversal: refuse an over-capacity fit instead of cutting
   it, which is a one-line guard.
4. **The legacy singular `engine` is read as `engines`** (§11 rule 2's tolerance,
   applied on the read side: `_slot_value`, `:909`). Writes accept only the eight
   canonical `FIT_SLOT_KEYS`, so a write cannot reintroduce the singular.
5. **`fit_for` returns `StringName` keys; a write mirrors the file's spelling**
   (§11: "write the same spelling the file already used"). String and
   StringName are interchangeable as Dictionary keys on 4.7.2 — measured:
   `{&"a": 1}.has("a") == true`, `{"a": 1}.has(&"a") == true`, and
   `{"a": 1} == {&"a": 1}` — so both the `fit[&"weapons"]` lookup and a
   `for key: StringName in fit` enumeration work. A brand-new fit is written with
   `String` keys, the shape a `ConfigFile` loads and the one `_fits` is keyed by.
   `_key_for()` (`:945`) matches the key *itself* rather than looking it up,
   because a lookup cannot tell the two spellings apart; without that the write
   below re-spelled half the file's keys `&"..."` (measured and fixed).
6. **`add_module` writes `count` (and a `base_id`) only.** 15 §6 rolls affixes at
   *creation* and never re-rolls, and this helper is the inventory's count half,
   not that roll, so a record created here carries no `rarity`/`prefixes`/
   `suffixes` to invent an ordinal for, and an existing record keeps its own.
   Reversal: let the P2-B inventory create records and make `add_module` refuse
   an unknown id instead of creating one.
7. **"Unknown hull" means "not one of the nine in `ShipFit.HULLS`"**, which is
   exactly the NPC set (verified: that table carries the nine player hulls only),
   so an NPC hull answers `{}` / `false` / 0 with no warning and no `push_error`
   (§11 rule 6). Using `ShipFit` rather than the station catalogue also keeps
   `fit_for` stable across W3's roster growth.

## 3. Migration evidence: the persisted shapes, before and after

Raw capture: `.agents/gen/p2a_w2_probe.txt`; re-runnable with

```text
~/.local/bin/godot --headless --path vajb-orbit --script res://tests/probe_p2a_fits_migration.gd
```

The fixture is a **save v2** file (a single id per slot type, the pre-v4 shape,
with the singular `engine` key) and the only mutation is one engine cell:

**Before — v2 on disk** (`fits` = one string per type, `save_version=2`):

```ini
[profile]
save_version=2
credits=4321
fits={
"ship_vanguard": {
"engine": "e_std",
"power": "p_std",
"shields": "s_light",
"weapons": "w_laser"
}
}
```

**The read** (no write happened; the file above is byte-identical afterwards,
`save_version` still 2):

```text
[probe] before:        save_version=2 fits={ "ship_vanguard": { "engine": "e_std", "power": "p_std", "shields": "s_light", "weapons": "w_laser" } }
[probe] fit_for(vanguard) = { &"engines": ["e_std"], &"weapons": ["w_laser", "", ""], &"shields": ["s_light"], &"armour": ["", ""], &"computers": [""], &"boosters": [""], &"utility": [""], &"power": "p_std" }
[probe] after the read: save_version=2 fits={ "ship_vanguard": { "engine": "e_std", "power": "p_std", "shields": "s_light", "weapons": "w_laser" } }
```

One string became a one-element array, padded to the *Cutter's* capacities
(08 §3: E1 P1 **W3** S1 H2 C1 B1 U1) — `w_laser` is `["w_laser", "", ""]`
because the Cutter carries three W cells; the singular `engine` resolved as
`engines[0]`; a type the file never wrote answers its capacity in `""`. No data
lost, no warning, and the file was not rewritten at load.

**After — one write** (`set_fit_slot(ship_vanguard, engines, 0, e_ion)` returns
`true`, then `save()`):

```ini
[profile]
save_version=4
credits=4321
fits={
"ship_vanguard": {
"armour": ["", ""],
"boosters": [""],
"computers": [""],
"engines": ["e_ion"],
"power": "p_std",
"shields": ["s_light"],
"utility": [""],
"weapons": ["w_laser", "", ""]
}
}
```

The shape is the array shape for all seven list types, `power` stays one id
(`"p_std"`, carried over from the v2 entry), every other type's v2 value is
carried over at its own index instead of being dropped, and the version is 4.
The keys kept the file's own `String` spelling (the earlier draft re-spelled
three of them `&"..."` — that is the bug fix recorded in §2 item 5). Reloading a
fresh instance returns exactly the fit above, cell for cell.

`MIN_READABLE_VERSION` is 1 and `SAVE_VERSION` is 4 (asserted in the suite), so
v1/v2/v3 files load clean and silently default the keys they never wrote.

## 4. Capacities the padding is measured against

Measured from the shipped `ShipFit` at report time, in `FIT_SLOT_KEYS` order
(E/W/S/H/C/B/U/P) — the same table 08 §3 gives, and the value every padded array
is built from:

```text
[probe]   ship_fighter     [1, 2, 1, 1, 1, 1, 0, 1]  fit_for(engines)=[""]
[probe]   ship_vanguard    [1, 3, 1, 2, 1, 1, 1, 1]  fit_for(engines)=["e_ion"]
[probe]   ship_miner       [2, 2, 1, 2, 1, 0, 3, 1]  fit_for(engines)=["", ""]
[probe]   ship_trader      [2, 1, 1, 2, 2, 1, 3, 1]  fit_for(engines)=["", ""]
[probe]   ship_corvette    [1, 4, 2, 2, 1, 1, 1, 1]  fit_for(engines)=[""]
[probe]   ship_freighter   [3, 1, 1, 3, 1, 0, 5, 1]  fit_for(engines)=["", "", ""]
[probe]   ship_gunship     [2, 5, 2, 2, 1, 0, 1, 1]  fit_for(engines)=["", ""]
[probe]   ship_patrol      [2, 4, 2, 3, 2, 1, 2, 1]  fit_for(engines)=["", ""]
[probe]   ship_destroyer   [3, 7, 3, 4, 2, 1, 2, 1]  fit_for(engines)=["", "", ""]
```

The three-engine hulls (Mule, Obliterator) answer `["", "", ""]`, the two-engine
hulls `["", ""]` — the normalisation rule as the brief states it.

## 5. The tests

**New suite `tests/test_p2a_profile_fits.gd` — 11 tests, all passing** (raw
output in `.agents/gen/p2a_w2_probe.txt`):

```text
[RUN] suites=test_p2a_profile_fits
[PASS] test_p2a_profile_fits.gd.test_a_three_engine_hull_pads_its_engines_to_three_cells
[PASS] test_p2a_profile_fits.gd.test_a_v1_file_without_a_fits_key_answers_the_empty_shape
[PASS] test_p2a_profile_fits.gd.test_a_v2_single_string_fit_reads_as_a_padded_array
[PASS] test_p2a_profile_fits.gd.test_a_v3_fit_loads_clean_and_the_first_write_persists_version_4
[PASS] test_p2a_profile_fits.gd.test_an_npc_or_unknown_hull_fits_nothing_and_says_so
[PASS] test_p2a_profile_fits.gd.test_base_module_id_resolves_instances_and_passes_base_ids_through
[PASS] test_p2a_profile_fits.gd.test_fit_for_answers_every_type_at_the_hulls_capacity
[PASS] test_p2a_profile_fits.gd.test_fit_writes_emit_the_fits_key_and_no_ops_do_not
[PASS] test_p2a_profile_fits.gd.test_module_counts_add_and_take
[PASS] test_p2a_profile_fits.gd.test_set_fit_normalises_to_the_hulls_shape_and_the_array_shape_persists
[PASS] test_p2a_profile_fits.gd.test_set_fit_slot_refuses_an_index_the_hull_has_no_cell_for
[SUMMARY] passed=11 failed=0
```

What each covers, in the brief's own checklist terms:

| Brief item | Test |
|---|---|
| the round trip | `test_set_fit_normalises_to_the_hulls_shape_and_the_array_shape_persists` (fit_for → save → reload is deep-equal, and the on-disk entry is an array, not a string; `power` persists as one id) |
| the v2 migration | `test_a_v2_single_string_fit_reads_as_a_padded_array` (also asserts the file is unchanged: version still 2, `weapons` still `"w_laser"`, and `fits()` still reads the file's own shape) |
| the v3 migration | `test_a_v3_fit_loads_clean_and_the_first_write_persists_version_4` (the v3 fuel key survives, the write persists v4, `MIN_READABLE_VERSION == 1`) |
| v1 (no `fits` key) | `test_a_v1_file_without_a_fits_key_answers_the_empty_shape` |
| capacity padding on a three-engine hull | `test_a_three_engine_hull_pads_its_engines_to_three_cells` (3 empty cells, `e_std` at index 2, index 3 refused, survives a save) |
| the index addressing rule | `test_set_fit_slot_refuses_an_index_the_hull_has_no_cell_for` (0/1 in range, 2 and −1 refused, a type with capacity 0 refused, POWER index 1 refused, a non-slot key refused, emptying a cell, both hull-id/key spellings) |
| `base_module_id` | `test_base_module_id_resolves_instances_and_passes_base_ids_through` (instance → `s_heavy`, base id unchanged, no-`base_id` record and unknown id → itself, `&""` → `&""`, and it survives a save) |
| shape/signal/property coverage | `test_fit_for_answers_every_type_at_the_hulls_capacity` (all nine hulls, all eight types, capacity-long, copy isolation), `test_fit_writes_emit_the_fits_key_and_no_ops_do_not`, `test_an_npc_or_unknown_hull_fits_nothing_and_says_so`, `test_module_counts_add_and_take` |

`tests/test_p1_profile.gd` was changed at exactly the pinned line (`:204`, the
version digit is now 4) and its `test_v2_round_trip_for_every_key` **passes**
with the new digit and with `set_fits`/`fits` untouched:

```text
[RUN] suites=test_p1_profile
[SUMMARY] passed=9 failed=0
```

The new tests use the same throwaway-instance harness as the P1 suites (no tree,
so no debounce Timer), and the probe flushes both instances before its scratch
file is deleted (hard rule L17) — the probe never touches `user://profile.cfg`.

## 6. The gate

```text
~/.local/bin/godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=353 failed=0
```

- **Measured on this worker's tree before any of my edits: 311 passed, 0
  failed.** After my edits: **353 passed, 0 failed, exit code 0** — the count
  grew and nothing regressed. (353 includes W1's `test_ship_grids.gd` and W3's
  `test_p2a_ship_roster.gd`, which landed in the same parallel group while I
  worked; my own delta is +11.)
- One `SCRIPT ERROR: Cannot call method 'call' on a previously freed instance.`
  line appears in the log **both before and after** my change (a weapon-FX suite
  tearing down against a freed node). It fails no test and is outside this
  worker's file set — pre-existing, not introduced.
- A later full-gate re-read is the orchestrator's; W1's report was still absent
  when this report was written (`ship_fit.gd` and `test_ship_grids.gd` were
  present and green at the measurement above).

## 7. §2's cites at read time (the addendum's item 2)

| Brief's §2 cite | Holds | At report time |
|---|---|---|
| `autoload/player_profile.gd:36` `KEY_FITS` | yes | `:43` (my constants above it) |
| `autoload/player_profile.gd:264` `modules()` | yes | `:279` |
| `autoload/player_profile.gd:24` `SAVE_VERSION` is 3 | yes | `:31`, now **4** |
| `tests/test_p1_profile.gd:204` pins `save_version == 3` | yes | `:204`, now 4 |

## 8. Notes for W4 / W5 / R1

- **W4:** `fit_for()` answers the all-empty shape for a hull with no stored fit,
  so the launch's fallback to `ShipFit.standard_fit(hull)` is yours to apply
  (§2 item 2 above); map every entry through `base_module_id()` before
  `ShipFit.resolve()`, and pass `power` through as the one id it already is.
  A three-engine hull's `engines` is three entries with `""` for an empty cell,
  so `resolve` sees only the fitted ids.
- **R1:** the two things worth re-measuring by hand are the migration itself
  (`probe_p2a_fits_migration.gd`, one command) and the spelling rule
  (`_key_for`, `player_profile.gd:945` — a file's keys keep their `String` vs
  `StringName` form across a rewrite). Nothing in this file set reads `assets/`,
  the theme, `project.godot` or `docs/`.
