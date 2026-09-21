# Slice 2 — W4 report: `LootTables` (2026-09-21)

Worker: W4 of engine slice 2 (Fight). Dispatch file set:
`vajb-orbit/game/loot_tables.gd` (new) + `vajb-orbit/tests/` + `vajb-orbit/tools/`.
Read first, in order: `AGENTS.md`, the dispatch, `.agents/gen/slice2_task.md`
(Global rules + pinned interface 8 + the 2026-09-20 amendments),
`docs/gameplay/06_loot_drops.md` in full including its 2026-09-20 amendment block,
`docs/gameplay/18_engine_spec.md` §2.1/§4.6/§6/§7/§13/§15, `docs/CONTRACTS.md`
§2/§4/§5/§8/§8.1/§9, `.agents/gen/slice2_w0_report.md`, `docs/gameplay/03_components.md`
§3, `docs/gameplay/13_heat_bounty.md` §3–§5, `.agents/gen/slice0_owner_rulings.md`.

Everything in this pass was written with the `write` / `edit` tools, never through
the shell (`va-jb` file hook respected, no shell redirection into the project). No
asset was read, moved or swept (addendum ruling two); no number was invented
(ruling four): every value in the code is a transcription of 06 §3, and the two
values the docs do not give are reported below instead of guessed.

## 1. Files changed

| File | Bytes | Status |
|---|---:|---|
| `vajb-orbit/game/loot_tables.gd` | 10 121 | new, shipped |
| `vajb-orbit/tests/test_engine2_loot.gd` | 18 599 | new, 13 tests |
| `vajb-orbit/tools/_probe_s2w4_loot.gd` | 8 823 | new, **deleted** with the probe pass (no `.uid` was generated: a headless run does not import, so there was no sidecar to remove) |
| `.agents/gen/slice2_w4_report.md` | this file | new |

`vajb-orbit/tools/` ends holding `build_theme.gd` (+ `.uid`) and
`derive_icon_tints.gd` (+ `.uid`) only, as the Global rules require. No other
project-side file was written by W4. W2's files (`game/damage.gd`,
`tests/test_engine2_damage.gd`, `tools/_probe_s2w2_smoke.gd`) landed in the tree
while this pass was running; see §3.2 for what that did to a later gate re-run.

## 2. What `loot_tables.gd` is

`class_name LootTables extends RefCounted`, pure data + API: no scene tree, no
`PlayerProfile`, no `economy_log`, no nodes, no autoloads. Pinned interface 8's
signature is honoured exactly; one additive defaulted parameter follows the
project's own precedent (`Sector.populate(row, random_seed := 0)`):

```gdscript
static func roll(kind: StringName, tier: int, random_seed: int = 0) -> Array[Dictionary]
static func has(kind: StringName) -> bool                 # the wiring's gate
static func cap_violations() -> Array[String]             # 06 §6 check 2
static func uncatalogued_items() -> Array[StringName]     # the 03 catalogue gap
const TABLES: Dictionary            # kind -> {band, lines}   (public data)
const FIGHTER_LINES / FREIGHTER_LINES / CORVETTE_LINES / MAW_LINES: Array[Dictionary]
const CREDIT_ITEM: StringName = &"credits"
const KEY_ITEM / KEY_AMOUNT / KEY_CACHE
```

- **Tables** are 06 §3.1/§3.2/§3.3/§3.4 transcribed line for line: item, `chance`,
  `min`, `max`, in the doc's order, with each table's band from its §3 heading
  (fighter I, freighter I, corvette II, Maw III).
- **The amendment is in**: `cm_chaff` and `cm_flare` are fighter lines 5 and 6 at
  `0.15` each, 1 unit (06 §3.1 lines 50–51). `&"swarmer"` (ruling 24) is a second
  kind keyed to the *same* `FIGHTER_LINES` array — one owner, so the pirate and
  alien weights cannot drift (06 §3.1's amendment: the swarmers "may enter …
  at the same weight").
- **Odds** are 06 §2.3's independent per-line rolls, never normalised, so a table's
  chance column sums to more than 1.0 and an empty payload is a legal result.
- **Payload** = one dictionary per paying line, keys exactly `Pickup.setup`'s
  arguments (`item_id`, `amount`, `is_credit_cache`; CONTRACTS §5), a line's units
  shipping as one stack (06 §2.3's implementer's choice) and the cache its own entry
  (06 §2.4). `CREDIT_ITEM` is `&"credits"`: 06 §5 names the cache's glyph and its
  payment call but no item id, and `Pickup` only reads that id for the 01 §7 log key.
- **Rock/mineral rolls are untouched**: nothing here reads `MineralCatalog`,
  `AsteroidField` or 02 §5.

## 3. Exact commands and output

### 3.1 The acceptance probe (bounded, stdout to a log; log read, not trusted)

```text
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path
"G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --script
res://tools/_probe_s2w4_loot.gd --quit-after 1200   > s2w4_probe.log 2>&1
exit=0
```

Tables and their arithmetic (no rolls involved — straight out of the doc's numbers):

| kind | band | lines | chance sum | empty-kill rate | expected units | expected CR |
|---|---:|---:|---:|---:|---:|---:|
| fighter | 1 | 6 | 1.7000 | 0.1183 | 2.1500 | 28.375 |
| swarmer | 1 | 6 | 1.7000 | 0.1183 | 2.1500 | 28.375 |
| freighter | 1 | 4 | 1.4000 | 0.1547 | 2.3000 | 44.550 |
| corvette | 2 | 5 | 1.3500 | 0.1890 | 1.5000 | 78.750 |
| maw | 3 | 6 | 4.0000 | 0.0000 | 6.3750 | 1584.750 |

Measured over 20 000 seeded rolls per kind (`random_seed` = 20 260 921 + index,
fixed, so every number below reproduces):

| kind | units/kill | CR/kill | empty-kill | lines/kill | EV drift (units / CR) |
|---|---:|---:|---:|---:|---|
| fighter | 2.1429 | 28.305 | 0.1194 | 1.6969 | −0.33 % / −0.25 % |
| swarmer | 2.1429 | 28.305 | 0.1194 | 1.6969 | −0.33 % / −0.25 % |
| freighter | 2.3049 | 44.762 | 0.1543 | 1.4067 | +0.22 % / +0.48 % |
| corvette | 1.4903 | 78.511 | 0.1911 | 1.3442 | −0.65 % / −0.30 % |
| maw | 6.3496 | 1581.608 | 0.0000 | 3.9884 | −0.40 % / −0.20 % |

06 §6 check 1 (±5 % on the expected value) therefore holds for all four hull
classes, measured, against the tables' own arithmetic.

Other probe lines (verbatim):

```text
[loot] samples (seed 20260921)
[loot]   fighter   roll 1 -> comp_scrap_1 x1 (cargo), comp_weap_1 x1 (cargo), comp_pow_1 x2 (cargo)
[loot]   fighter   roll 2 -> comp_scrap_1 x2 (cargo)
[loot]   freighter roll 3 -> comp_mech_1 x1 (cargo), comp_ore_1 x2 (cargo)
[loot]   corvette  roll 3 -> comp_weap_2 x1 (cargo), comp_mech_2 x1 (cargo), credits x177 (CR cache)
[loot]   maw       roll 1 -> comp_scrap_3 x4 (cargo), comp_mech_3 x2 (cargo), credits x944 (CR cache)
[loot]   maw       roll 2 -> comp_scrap_3 x5 (cargo), comp_mech_3 x2 (cargo), comp_ore_3 x1 (cargo), credits x1175 (CR cache)
[loot] maw guarantees (06 §3.4: line 1 + line 6 always pay)
[loot]   guaranteed minimum 1025 CR, maximum 2185 CR, arithmetic mean 1584.750 CR
[loot] tier invariance (06 §7's sector scaling is documented, not built in v1)
[loot]   fighter/swarmer/freighter/corvette/maw  tiers 1/2/3/4/7 identical: true
[loot] 06 §6 check 2 against the 03 catalogue
[loot]   cap violations: []
[loot]   uncatalogued items: [&"cm_chaff", &"cm_flare"]
[loot]   cm_chaff appears in: fighter, swarmer
[loot]   cm_flare appears in: fighter, swarmer
[loot] unknown kind refusal (the next lines are the expected error + warning)
ERROR: LootTables.roll: no table for kind boss (have: corvette, fighter, freighter, maw, swarmer)
[loot]   roll(&"boss", 1) -> [] (empty: true)
WARNING: LootTables.roll: tier 0 is not a band; rolling fighter unchanged
[loot]   roll(&"fighter", 0) -> 3 pickups, unchanged by the bandless tier
[loot] done
```

The two engine lines are the *expected* output of the two refusal paths on
purpose (mislabelled kind, bandless tier); `exit=0` still holds because a probe's
exit code is its own `quit()`.

### 3.2 The universal test gate (the wave's real gate)

```text
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path
"G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tests/headless_runner.tscn
--quit-after 1200   > s2w4_gate.log 2>&1
exit=0
[SUMMARY] passed=91 failed=0
```

13 of those 91 are this pass's (`test_engine2_loot.gd`, all PASS). The total is the
one measured at that moment; nothing was compared against a stale figure.

| test | what it measures |
|---|---|
| `test_every_shipped_table_matches_its_doc_06_transcription` | all four tables + bands vs a second, independent 06 §3 transcription inside the suite |
| `test_swarmer_reuses_the_fighter_weights` | the swarmer shares the one fighter line array and the same seeded payload |
| `test_countermeasure_rows_entered_the_fighter_table_only` | `cm_chaff`/`cm_flare` at lines 5–6, 0.15, 1 unit; the other three tables carry none |
| `test_chance_totals_are_the_tables_own_sums_not_one` | chance sums 1.70/1.40/1.35/4.00 and measured lines/kill = the same totals |
| `test_lines_are_independent_and_an_empty_kill_is_legal` | two-line kills and empty kills both occur; empty rate tracks Π(1−chance) |
| `test_expected_value_per_hull_class_is_within_five_percent` | 06 §6 check 1, ±5 %, units and CR |
| `test_maw_guarantees_its_scrap_line_and_its_credit_cache` | 2 000 rolls: every Maw kill pays Dreadnought Slag (3–5) and an 800–1 200 CR cache |
| `test_cache_lines_are_last_and_flagged_as_credit` | cache line counts per table (0/1/1/1) and the cache is the last payload entry |
| `test_payloads_are_pickup_setup_arguments_within_their_ranges` | exactly the three `Pickup.setup` keys, amounts inside `randi_range` |
| `test_grade_caps_hold_against_the_03_catalogue` | `cap_violations()` empty; every catalogue id inside its band |
| `test_the_only_uncatalogued_items_are_the_two_countermeasures` | the 03 catalogue gap is exactly the two countermeasures |
| `test_unknown_kinds_are_not_tables` | `boss`, `hunter`, `patrol`, `turret`, `sibelon`, `apex`, `""` are not tables |
| `test_tier_does_not_change_the_roll_in_v1` | same seed, tiers 1/2/3/4/7: identical payloads |

Re-run after W2's files appeared mid-pass, for completeness (same command, fresh
log): `[SUMMARY] passed=108 failed=2`, and **all 13 `engine2_loot` tests PASS in
that run too**. Both reds are in W2's own in-flight suite and are untouched here
(the brief: a worker does not fix another worker's failing tests):

```text
[FAIL] test_engine2_damage.gd.test_apply_delivers_an_item5_context_to_a_hull_sink:
  an attacker on +Y is +PI/2 off a heading of 0, got -1.57079637050629
[FAIL] test_engine2_damage.gd.test_apply_reaches_a_player_state_through_its_own_method:
  the context's direction is recorded (a hit from astern), got -3.14159256616701
[SUMMARY] passed=108 failed=2
```

## 4. Decisions W5/W3 must read (interfaces this pass had to define)

1. **`kind` is the 06 table's hull-band name**, not the 18 §5 archetype name:
   `&"fighter"`, `&"swarmer"`, `&"freighter"`, `&"corvette"`, `&"maw"`. The spec's
   archetype vocabulary (`pirate`, `patrol`, `trader`, `hunter`, `turret`, `boss`)
   is a different axis: 18 §5's death column itself maps a hull to a table **by
   band** ("Hunters drop loot like pirates of their band", 13 §3), and the boss
   archetype pays through 14 §5, not through 06. The file header carries the
   mapping table; `has()` is the wiring's gate, and an unknown kind is refused
   loudly (probe line above) rather than silently paying nothing.
2. **`tier` is inert in v1, on purpose.** 06 §7's only tier rule is the
   sector-scaled cache multiplier (×1 T1–T2, ×1.5 T3, ×2 T4), and 06 §7 itself
   marks that "documented, not built in v1" — so no odds are read from `tier`, and
   the probe measures that (identical yields at tiers 1/2/3/4/7). A tier below 1 is
   warned about (a band is 1-based) but deliberately cannot cost a hull its loot.
3. **`random_seed: int = 0`** is the additive parameter (0 = randomize, non-zero =
   reproducible), the same contract `Sector.populate` already carries. The pinned
   two-argument call `roll(kind, tier)` still resolves.
4. **One pickup per paying line** (06 §2.3's "implementer's choice"), with the
   line's units as the stack, and the cache its own distinct entry (06 §2.4).

## 5. Findings (reported, not fixed — all of them are outside this file set)

- **F1 — MED, doc arithmetic.** 06 §3's prose hauls are stale against 06 §3's own
  tables, so 06 §6 check 1 as literally written ("expected value per hull class
  equals **the sums above**") cannot pass. Measured, from the doc's numbers alone:

  | hull | 06 §3 prose | tables' arithmetic |
  |---|---|---|
  | fighter | "≈ 1.1 items, ≈ 20 CR", "empty ≈ 17 %" | 2.15 units, 28.375 CR, empty 11.83 % (the four-line, pre-amendment table was 1.85 units / 16.4 % empty, so the amendment is what moved the figures; W0's independent count in `slice2_w0_report.md` gives the same 2.15 / 11.8 %) |
  | freighter | "≈ 1.6 items + occasional cache, ≈ 40 CR" | 2.30 units, 44.55 CR (35.55 components + 9.00 cache) |
  | corvette | "≈ 1.3 items, ≈ 60 CR + caches" | 1.50 units, 60.25 component CR (the prose's 60 CR is exact) + 18.50 cache CR = 78.75 |
  | maw | "≈ 500–900 CR minimum, up to ≈ 1300+" | guaranteed floor 1025 CR (3 × 75 + 800), ceiling 2185 CR, mean 1584.75 CR |

  06 §3.1's amendment block already declares its own figures stale and defers the
  re-check to the wave report, which is where these numbers belong. Nothing in 06
  was re-worded (docs are outside this file set).
- **F2 — MED, doc gap.** `cm_chaff` and `cm_flare` have **no 03 §3 catalogue row**,
  so 06 §6 check 2 ("no table references a component grade above its hull band …
  assertable directly against the 03 catalogue") cannot be proved for the two
  countermeasure lines, and neither has a CR value (03 §3.1 gives values for
  catalogue items only — F4). `uncatalogued_items()` reports exactly those two ids,
  the suite pins that list, and the grade cap is asserted for every *catalogued*
  line. The P2/station-shop pass that adds the countermeasures to the shops is the
  natural place for the 03 rows (18 §4.6: "the station shops in a later P pass").
- **F3 — MED, cross-worker interface.** The pin does not define the `kind` axis and
  two of 18 §5's death rows have no numbers behind them: the hunter's "06 band +
  `comp_elec`-weighted extras (13 §3)" has no table anywhere (hunters are a slice-4
  seam per 18 §5), and the boss pays 14 §5. Consequence for W5: the corpse's
  *band* must be mapped to a `kind` before calling `roll`; `has()` exists so the
  wiring can fail loudly at integration instead of shipping a silent empty drop.
  No plausible-but-invented kind aliases were added (ruling four).
- **F4 — LOW.** The two countermeasures' CR value is undefined in 03/06, so all EV
  arithmetic here counts them 0. The tables' *unit* expectations are unaffected
  (they are counted as units); the CR figures above are therefore floors for the
  fighter/swarmer rows.
- **F5 — MED, spec vs shipped tree, no owner in this wave.** 06 §5 requires a
  credit cache to be "always a distinct visual pickup (the existing salvage glyph,
  tinted bright)". `game/pickup.gd:_build_look()` draws `env_pickup_ore_pod.png`
  with no cache tint or variant, so a slice-2 cache is visually identical to an ore
  pod. `pickup.gd` is in no slice-2 file set, and `assets/**` belongs to the
  graphics lane (addendum ruling two: no asset path was swept to check whether the
  salvage glyph exists). Pointer only — the orchestrator decides who owns it.

- **F6 — cross-worker observation.** The gate re-run in §3.2 (after W2's files
  appeared) carries W2's two `test_engine2_damage.gd` reds. They are W2's to close
  and nothing in this pass touches them; they are recorded here only so the
  orchestrator does not read a red wave gate as a W4 regression.

## 6. Deviations from the brief


- None in behaviour: the tables are 06 verbatim, the amendment rows are in, the
  rock/mineral paths are untouched, and the pinned signature stands.
- Two documented *additions* beyond the pin, both named in §4: an additive
  defaulted `random_seed` (the project's own test-seed precedent) and the two
  read-only helpers `cap_violations()` / `uncatalogued_items()`, which implement
  06 §6 check 2 and ruling four's report-don't-guess rule.
- The suite applies 06 §6 check 1 to the tables' arithmetic rather than to §3's
  stale prose; the reason and the measured drift are in F1 and in the suite header.
- `tier`'s semantics are this pass's definition (the pin names the parameter and no
  doc defines it); the file header and §4.2 state it, and it is measurable
  (tier invariance in the probe and in the suite) so a reviewer can re-run it.
