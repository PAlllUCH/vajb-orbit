---
slice: S3
worker: S3-K1
model: ""             # the orchestrator fills what actually ran
status: actionable    # the Follow-ups table is LOW only; K4 tickets it (T-93+)
gate: "450/7 → 471/0 (exit 0 both runs; live profile md5 unchanged)"
---

# S3-K1 report — the instance core's residual, and the two instance suites

## Result

The §15 instance core the previous K1 dispatch landed now passes its own gate:
the two save-v6 defects it carried are fixed (below), the seven suites the
orchestrator measured red are green, and the brief's two new suites exist and
pass. Measured by the house gate, this machine, twice:

```
$GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=471 failed=0          (exit 0, run 1 and run 2)
```

Before: `passed=450 failed=7`, exit 1 (the orchestrator's run, reproduced here).
The delta is exactly arithmetic: **+7** tests that were failing now pass and
**+14** are the two new suites, so `450 + 7 + 14 = 471`. Isolating it: with the
two new files moved aside the gate reads `passed=457 failed=0` — the brief's own
pre-wave figure — which is the measurement that the seven dispositions below are
the whole of the fix. Per suite, after: `test_p1_profile` 11, `test_p2a_profile_fits`
11, `test_p2b1_outfitting_panel` 9, `test_p2b_retirement` 16, `test_ship_grids` 27
(`--suite=` runs: 74/0), `test_s3_instances` **9**, `test_s3_migration` **5**.

The five AC1/AC2 items the brief names for this worker are now guarded:
15 §2/§3/§4's tables and pools row by row, the seeded outcomes, roll-at-creation
with no re-roll, the `count` 1/0 round trip with `instances_of`/`sell_instance`
invisibility, REMOVE/SWAP handing back the same instance, two same-base instances
distinguishable, the base-id translation keeping `fit_legal`'s draw and its
duplicate guard honest, and the v5→v6 migration with its second call answering 0.
Nothing is applied to a flight stat (15 §9.3), no price, weight or 09 §3.1 stat
moved, and no file outside the declared set was touched.

## The two code defects (one root cause, two failures)

`_normalise_instance` read `rarity` through the `String()` **constructor**:
`String(raw.get(KEY_RARITY, ...))`. GDScript's `String` has no `int` overload, so
a fixture whose `rarity` is a bare number (every pre-instance one, `rarity: 2`)
aborted the whole normalise with `Invalid call 'String' constructor: <arg>` and
left an **empty record** in the bag. Measured directly (scratch probe, since
deleted):

```
SCRIPT ERROR: Invalid call 'String' constructor: s_heavy
          at: _normalise_instance (res://autoload/player_profile.gd:1464)
modules={ "mod_0007": {  }, "mod_0008": { ... the canonical six keys ... } }
base_module_id(mod_0007)=mod_0007          # the empty record answered its own key
before={ "mod_0001": {  } }                # the write persisted the empty record
```

One `str(...)` in `player_profile.gd:1467` fixes both `:383`'s "an instance
resolves to its base" and the p1 round trip: the record normalises, `base_id`
survives and the file round trips. Reversal: restore `String(...)` and both
fixtures go red again.

## The seven failures' dispositions

| # | Suite (`test method`) | Failure message | Cause | Disposition |
|---|---|---|---|---|
| 1 | `test_p1_profile.gd:191` (`test_v2_round_trip_for_every_key`) | `modules round trip` | the `String()` crash above: the in-memory record was `{}` and that empty record was what the file got | code fixed; the fixture also moves to the pinned six-key record (rarity `rare`, two `{id, value}` prefixes, two suffix ids, `count` 3) |
| 2 | `test_p2a_profile_fits.gd:264` | `writes persist save v5` | the pin is v6 (CONTRACTS §15) | `Profile.SAVE_VERSION` pin reads **6**, `..._persists_version_6`; the method renamed to match |
| 3 | `test_p2a_profile_fits.gd:396` | `an instance resolves to its base` | the `String()` crash | code fixed; the fixture's bare numeric `rarity` stays as the regression guard for the tolerance |
| 4 | `test_p2a_profile_fits.gd:448` (`test_module_counts_add_and_take`) | `no affix roll is invented here` | `add_module` now writes the v6 six-key record, so `record.has("rarity")` is true | the assertion moves to the pinned shape: rarity `common`, both affix lists empty, six keys exactly |
| 5 | `test_p2b1_outfitting_panel.gd:490` | `one row per catalogue weapon id` | 15 §9.1's two exclusive weapons are weapon-slot catalogue ids this pane does **not** sell (they are the AUCTION's F lot), so 7 rows ≠ 9 ids | the guard's catalogue side excludes 15 §5's exclusives; its docstring and method name now say "this surface sells"; the `"the AUCTION is future"` comment goes |
| 6 | `test_p2b_retirement.gd:110` | `writes always persist v5` | the digit is 6 | on-disk digit **6** plus the two prose lines around it |
| 7 | `test_ship_grids.gd:785` | `32 rows (09 section 3)` | the catalogue carries 15 §9.1's three rows | the local table grows to **35** with them, `u_vault`'s `{vault_add: 20}` effect joins `MODULE_EFFECTS`, the icon rule reads `ICON_REUSE` first, and the message reads `35 rows (09 section 3 + 15 section 9.1)` |

Two further assertions were **masked** behind their suite's first failure (the
framework stops asserting once `_failed` is set) and were fixed in the same
edits: `test_p1_profile.gd:213` (`"writes always persist v5"`, now 6 — the
brief's own `:213` note) and `test_p2a_profile_fits.gd:290`
(`"a write persists save v5"`, now 6). No other red surfaced once the seven
cleared, which is the evidence that nothing else was hidden.

## What the two new suites pin

`tests/test_s3_instances.gd` (9 methods, all seeded where a roll is involved):

| Method | What it measures |
|---|---|
| `test_add_instance_mints_the_pinned_six_key_record` | the six keys and nothing else, `instance_id` = the key, the mint order, both refusals writing nothing and spending no number |
| `test_the_roll_reads_the_source_table_and_the_family_pools` | every source × every family shape: the rarity is legal for the source's row, the prefixes come from the module's own family at its tier's band value, the suffixes from the faction pool, no row repeats; then 15 §5's floor over all three exclusives × all seven sources; then both refusals |
| `test_the_seeded_outcomes_are_pinned` | five measured outcomes for seed 20260922: an auction Common, a derelict Magic `surefire 0.05` + `leeches`, the F lot's own row (`deep_hold 12.0`), an exclusive floored to Magic by a 100 %-Common source with its faction suffix (`choir`), an arena Magic `spry −0.25` |
| `test_a_roll_is_seeded_and_never_re_rolled` | the same seed twice, a second read, and the file: the outcome is a stored value |
| `test_the_bag_and_fitted_count_round_trip` | 1 → 0 → 1, `instances_of` and `sell_instance` invisibility at 0, the record surviving with its affixes, no duplicate restore, the round trip through the file |
| `test_remove_and_swap_hand_back_the_same_instance` | L80: SWAP banks the displaced instance as itself, REMOVE the same, two records throughout |
| `test_two_instances_of_one_base_stay_distinguishable` | two ids, one base, different rarities and affix rows, one fitted while the other stays in the bag, both surviving a save |
| `test_a_fit_is_judged_on_base_ids_not_instance_ids` | the translation (`base_fit`), the honest power draw and over-budget reading, the composed install refusing the over-budget cell without writing, and the duplicate guard seeing two `e_ion` instances as one duplicate |
| `test_sell_instance_pays_the_base_times_the_rarity_share` | `base × rarity × 60 %` per rarity, the record erased, both refusals paying nothing, and a base-keyed entry selling one unit at a time |

`tests/test_s3_migration.gd` (5 methods): a v5 stacked record of 3 becomes three
Common instances minted 1..3 with the key gone and the file rewritten as v6; a
second call answers 0 and a second load does not double; an empty bag and a v6
bag have nothing to migrate; a mixed file converts only the short records
(the six-key one keeps its mint and affixes, a bare `{count: n}` reads with its
own key as the base id); and the mint continues from the file's own counter
(7 → `mod_0008`, `mod_0009`, then `mod_0010`).

## Deviations from SLICE.md / the brief

1. **`_normalise_instance`'s `str()`** — a bug fix inside a pinned acceptance
   (bucket 1): the pin (a record whose `rarity` is one of three ids) cannot be
   met while the normalise aborts on any other shape. Reversal: the constructor
   call, and both fixtures go red.
2. **`test_s3_instances` does not measure the *untranslated* judgement.** The
   first draft fed the raw instance-id fit to `power_budget`/`fit_legal` to show
   the K0 H6 defect from both sides; that pushes a `ShipFit: unknown module id`
   warning per cell (5 measured) and the gate's warning ledger is part of
   CONTRACTS §9. The suite now reads only the judgement the transaction itself
   composes (the same ids, translated) plus the refusal, which can only hold with
   the translation in place. Reversal: re-add the two raw calls at the cost of
   five warnings.
3. **`test_p2b1_outfitting_panel.gd`'s guard narrowed and renamed** (bucket 1:
   test mechanics). 15 §5/§9.1 + CONTRACTS §12's seven rows say OUTFITTING is not
   the door for `w_proton`/`w_flak`, so "every catalogue weapon id" is no longer
   the right predicate. Reversal: drop the `EXCLUSIVES` filter (K2 retires the
   whole MODULES row set anyway).
4. **Test/pin renames** (bucket 1, names only):
   `test_a_v3_fit_loads_clean_and_the_first_write_persists_version_5` →
   `..._version_6`, and
   `test_every_catalogue_weapon_has_a_pressable_row` →
   `test_every_weapon_id_this_surface_sells_has_a_pressable_row`. Same test
   counts (11 and 9).
5. **The seeded literals are engine-RNG-specific.** Seed 20260922's outcomes are
   pinned on purpose (they are what makes a drifted draw order or a re-roll
   visible), so they are re-measured on an engine upgrade, not relaxed.
6. **No docs were edited.** CONTRACTS §9's figure and §10's note are K4's; the
   number to write is the measured **471**.

## Evidence

```bash
# before (the orchestrator's figure, reproduced)
... headless_runner.tscn -> [SUMMARY] passed=450 failed=7   (exit 1)

# after, twice
... headless_runner.tscn -> [SUMMARY] passed=471 failed=0   (exit 0)
... headless_runner.tscn -> [SUMMARY] passed=471 failed=0   (exit 0)

# the fix set isolated: the two new suites moved aside
... headless_runner.tscn -> [SUMMARY] passed=457 failed=0   # the brief's pre-wave figure

# the touched suites and the two new ones, by full basename
... -- --suite=test_p1_profile --suite=test_p2a_profile_fits --suite=test_p2b1_outfitting_panel \
      --suite=test_p2b_retirement --suite=test_ship_grids   -> passed=74 failed=0
... -- --suite=test_s3_instances  -> passed=9 failed=0
... -- --suite=test_s3_migration  -> passed=5 failed=0

# the live account is untouched
md5(user://profile.cfg) before 596b88947fc65a3cecde803b7f2f92bd
md5(user://profile.cfg) after  596b88947fc65a3cecde803b7f2f92bd     # two full gate runs

# the warning ledger is unchanged: the gate's only warnings are the pre-existing
# EconomyLog one plus the exit-time ObjectDB/resource report, and the exit-time one
# is not this worker's -- with the two new suites removed it still reports
# "38 ObjectDB instances were leaked at exit" and "18 resources still in use".
```

## Files touched

- `vajb-orbit/autoload/player_profile.gd` — one line and one comment at
  `_normalise_instance` (`str()` in place of the `String()` constructor); the
  rest of the file's §15 work is the previous dispatch's, unchanged by this pass
- `vajb-orbit/tests/test_p1_profile.gd` — the v6 record fixture, the save-version
  digit, a save-v6 docstring note
- `vajb-orbit/tests/test_p2a_profile_fits.gd` — the save-version pin and the
  on-disk digit, the `add_module` record's shape assertions, the method rename, a
  save-v6 docstring note
- `vajb-orbit/tests/test_p2b1_outfitting_panel.gd` — the door guard's predicate,
  docstring and method name
- `vajb-orbit/tests/test_p2b_retirement.gd` — the on-disk digit and the two prose
  lines around it
- `vajb-orbit/tests/test_ship_grids.gd` — 15 §9.1's three rows in the local table,
  `u_vault`'s effect, the icon-reuse branch, the 35-row message
- `vajb-orbit/tests/test_s3_instances.gd` — **new**, 9 tests
- `vajb-orbit/tests/test_s3_migration.gd` — **new**, 5 tests

## Follow-ups

LOW only; the brief gives K4 the LOW rows (next free `T-93`).

| Item | Kind | Where |
|---|---|---|
| A stale probe still asserts the catalogue's old size: `"ModuleCatalog.MODULES carries 32 rows"` (now 35), so a re-run of R1's frame probe reports a false failure | LOW (stale evidence) | `vajb-orbit/tests/probe_r1_frames.gd:548` |
| `module_count(base_id)` does not aggregate instances: after the migration, `module_count(&"w_laser")` measures **0** while `instances_of(&"w_laser")` holds three ids. K3's `OWNED ×<n>` aggregate must read `instances_of` (or §15's accessor gains a base-id sum, which would be bucket 2) | LOW / for K3+ | `vajb-orbit/autoload/player_profile.gd:368` |
| `base_fit` returns plain Arrays while `fit_for`/the catalogue hand out typed ones, so `==` between them is false even when the content matches; K3's panels must compare element-wise or go through `fit_legal` (measured while writing `test_s3_instances`) | LOW (API note) | `vajb-orbit/autoload/player_profile.gd:634` |
| `outfitting_panel.gd`'s `MODULE_ROWS` comment still claims "every weapon-slot id the catalogue ships has a row here", which 15 §9.1's two exclusives make false; K2's retirement removes the table, so this is comment drift until then (a file outside this worker's set) | LOW (comment drift) | `vajb-orbit/ui/station/outfitting_panel.gd:92-95` |
