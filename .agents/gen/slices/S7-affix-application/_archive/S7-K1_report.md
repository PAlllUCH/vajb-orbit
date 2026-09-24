---
slice: S7
worker: S7-K1
model: opencode-go/deepseek-v4.1-flash
status: actionable
gate: "726/0 -> 726/0 (twice, scratch stores; my suite contributes 15 of the 726)"
---

# S7-K1 report — the summary bridge and the ship-stat side

## Result

The affix bridge and the ship-stat half of CONTRACTS section 20 are landed and
measured. `game/affixes.gd` (new, `class_name Affixes`) builds the summary from
`resolved_fit`'s cells: per-prefix magnitudes with the stored signs, one suffix
flag per perk, and one `instances` row per fitted instance in `FIT_SLOT_KEYS` then
cell order; `PlayerProfile.affix_summary` delegates. `ShipFit.resolve` gained the
one optional `affixes: Dictionary = {}` and applies Sturdy, Vigilant, Wideband,
Surefire, Tempered, Lightened, Deep-hold and the Whale flag inside the existing
steps, every value before `_clamp`; `ShipStats.booster_cooldown_mult` is Spry's
aggregate. Overflowing applies nothing. The gate reads **726/0 twice** on scratch
stores (15 of the 726 are `tests/test_s7_affixes.gd`; the tree carried 711 rows
before it, all green — D7's in-flight lane owns the 674 -> 711 growth), and the
pre-S7 Vanguard fixture resolves byte-identically with `{}` and with no third
argument.

## What was built (file:line)

- `game/affixes.gd:1-168` — `summary(profile, ship_id)` (`:59`) and
  `has_suffix(summary, id)` (`:88`), statics only. The walk is `ShipFit.FIT_SLOT_KEYS`
  (`:104`) then cell order, each non-empty cell through `profile.instance()`
  (a fitted `count`-0 record answers, CONTRACTS section 15); the row shape is
  `{slot, index, base_id, prefixes: [{id, value}], suffixes}`. Ids are converted
  to `StringName` explicitly (K0 F16's precedent, `Auction.rolled_name:648`).
  `{}` for no fit at all (an NPC hull, a null profile).
- `autoload/player_profile.gd:900-906` — `affix_summary(ship_id)` delegates to
  `Affixes.summary(self, ship_id)`.
- `game/ship_stats.gd:47-51` — `booster_cooldown_mult: float = 1.0`.
- `game/ship_fit.gd:598` — `resolve(hull_id, fit, affixes := {})`; `:632-641` the
  call block; `:943-961` `_apply_flat` (Sturdy per instance, Deep-hold's units,
  Whale +50); `:964-1018` `_apply_speed` (Lightened's clamped sign-flip on the
  speed **and** mass terms, Tempered's `(own - 1) x (1 + sum)` inside the summed
  engine delta); `:1021-1049` `_apply_computers` (Surefire sums, Wideband best);
  `:1052-1073` `_apply_shields` (Vigilant best); `:1085-1098` `_apply_boosters`
  (Spry's ship-level multiplier); `:1101-1228` the S7 helpers
  (`_align_affixes`, `_affix_magnitude`, `_has_suffix`, `_sturdy_pool`, the row
  readers). Nothing else in the resolver moved: with `{}` every helper is a no-op
  and the arithmetic is the pre-S7 arithmetic line for line.
- `tests/test_s7_affixes.gd:1-598` — 15 tests: the summary shape/signs/flags/rows,
  the empty-fit summary, the inert stored `0.0`, the full pre-S7 fixture A/B'd
  three ways, one worked row per applied prefix (Sturdy's counter-example,
  Vigilant/Wideband best, Surefire's sum, Tempered's ceiling, Lightened's clamp,
  Deep-hold's units, Spry's field, Whale's flat), both pool clamps on an
  over-capacity fixture, and the staged Overflowing no-op.

## Deviations from SLICE.md / the brief

Every item below is inside the pin's own text (bucket 1) unless named otherwise;
nothing was changed in `docs/`.

| # | Judgment call | Why | Reversal |
|---|---|---|---|
| D1 | **Sturdy reads `instances`, not the aggregate.** `_sturdy_pool` sums `own shield_add x own stored value` per row. | Section 20's aggregation-law bullet lists Sturdy among the rules that "may read the aggregate keys", but the **same bullet's counter-example** (and the K1 prompt) pin the per-instance sum: `s_light` 200 Sturdy 0.10 beside `s_heavy` 400 Sturdy 0.15 is +80, not `0.25 x 600 = +150`. The two sentences contradict; the measured counter-example is the load-bearing one and the suite asserts both numbers. | One helper body (`_sturdy_pool`) if the aggregate reading is ever wanted; the suite's `assert_ne(1450)` would then flip. |
| D2 | **Deep-hold and Spry read the aggregate; the other five per-instance rules read the rows.** | Both collapse to one scalar over the fit (section 20's own split). Spry's aggregate is over fitted booster instances by construction — `ModuleCatalog.prefix_pool:690` keys off `fit_slot_of`, so `spry` only rolls on boosters — which is exactly the pin's "over fitted booster instances". | Move either to the row walk (`_row_prefix_value`) with no contract change. |
| D3 | **`_align_affixes` keys the summary's rows to `fitted_ids` by `base_id`, consuming duplicates in order.** | A module belongs to exactly one slot and within one slot both walks are cell order, so the alignment is exact; `resolve`'s contract is a base-id fit (the launch maps through `base_module_id`), which is what the rows name. | Align by `(slot, index)` instead — needs a second fit walk, so it was not taken. |
| D4 | **A cell whose id `instance()` answers is a fitted instance whatever its `count`.** | The pin says "An instance answers while fitted (`count` 0, section 15)" about the record surviving; a real fit always has `count` 0, and filtering would break a fixture that fits via `set_fit_slot` without `take_instance` (K2/K3's likely shape). A base-keyed record with no affixes contributes nothing either way. | Add a `count == 0` guard in `summary`. |
| D5 | **`has_suffix(summary: Dictionary, id)` keeps the pin's parameter name** and therefore emits one new GDScript warning: `SHADOWED_VARIABLE` (the parameter shadows the class's own `summary` function). | The signature is pinned verbatim and GDScript has no named arguments, so the name is part of the pin text. **Bucket 2** if R1 wants the tree warning-free. | Rename the parameter (`data`) — one word, no caller changes; the pinned call shape is untouched. |
| D6 | **`game/affixes.gd` depends on `ShipFit.FIT_SLOT_KEYS` one way only**; `ship_fit.gd` keeps its own six summary-key literals (`AFFIX_INSTANCES` etc., `:124-137`). | A mutual `Affixes`/`ShipFit` global-class reference risks a GDScript cyclic-reference error; `Affixes.has_suffix` is duplicated as a private `_has_suffix` for the same reason. | Reference `Affixes.KEY_*` from `ship_fit.gd` once the cycle is proven safe. |
| D7 | **The two pool-clamp rows use a hand-built summary** (six max-band `s_ion`, five `h_composite` + Whale) in `tests/test_s7_affixes.gd`. | No legal fit reaches 09 section 5's 3x ceilings: the best three-cell hull is 900 + 3 x 350 x 1.20 = 2160 against a 2700 ceiling, and 2200 + 4 x 1000 + 50 = 6250 against 6600. The over-capacity fixture is the only way to prove the clamp lands **after** the affixes; the suite says so in its comment. | Drop the two rows if the reviewer prefers clamp coverage only where a legal fit reaches it. |

No existing test row moved (K0's flip list held: no gate suite fits a computer, and
the one Ledger assertion is K3's). No `ui/`, `assets/`, `staging/` or `docs/` write.

## Evidence

```bash
# full gate, twice, each on its own scratch store (XDG_DATA_HOME=$(mktemp -d))
godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
# [SUMMARY] passed=726 failed=0   (exit 0, both runs)
# the same tree before my suite: 711 test_* methods; 726 total now, 15 of them mine
grep -h "^func test_" vajb-orbit/tests/test_*.gd | wc -l   # 726

# scoped run, for the suite's own lines
... --quit-after 1200 -- --suite=test_s7_affixes
# [SUMMARY] passed=15 failed=0

# parse + warning ledger of the touched files
godot --headless --debug --path vajb-orbit --check-only --script res://game/ship_fit.gd
# no warnings attributable to ship_fit.gd (only module_catalog.gd's pre-existing 3)
# affixes.gd: only the D5 SHADOWED_VARIABLE; ship_stats.gd: clean

# the G1 lint probe (ship_fit.gd is one of its three files)
godot --headless --debug --path vajb-orbit res://tests/probe_g1_lint.tscn --quit-after 600
# [G1-LINT] BEGIN G1 res://game/ship_fit.gd / END ... loaded=true with no warning between

# live store, untouched by these runs (scratch XDG); timestamps predate the first gate
md5sum "$HOME/.local/share/godot/app_userdata/Vajb Orbit/profile.cfg"        # d59a9e428c09ff33675a4c448da2853c  (12:18)
md5sum "$HOME/.local/share/godot/app_userdata/Vajb Orbit/economy_log.txt"    # bd27929cd7b075e913d07e50a017bbcf  (12:18)
```

Decisive suite lines: `test_sturdy_scales_its_own_instance_pool_not_the_summed_magnitude`
(1370.0, not 1450.0), `test_resolve_without_a_summary_is_the_pre_s7_fixture`
(the full 21-field fixture), `test_a_fitted_overflowing_instance_changes_nothing`,
`test_sturdy_at_its_band_maximum_is_still_bounded_by_the_pool_ceiling` (2700).

## Files touched

- `vajb-orbit/game/affixes.gd` — new: `summary` + `has_suffix` (168 lines).
- `vajb-orbit/game/affixes.gd.uid` — Godot's generated UID sidecar (tracked convention).
- `vajb-orbit/autoload/player_profile.gd` — +9: `affix_summary` delegate.
- `vajb-orbit/game/ship_stats.gd` — +6: `booster_cooldown_mult`.
- `vajb-orbit/game/ship_fit.gd` — +238/-21: the optional parameter, the eight
  applications, the S7 helpers and the summary-key constants.
- `vajb-orbit/tests/test_s7_affixes.gd` — new suite, 15 tests (598 lines) + `.uid`.

## Follow-ups

| Item | Kind | Where |
|---|---|---|
| D5 — the pinned `has_suffix(summary, ...)` parameter name costs one `SHADOWED_VARIABLE` warning; rename the parameter to clear it | WARN / BUCKET 2 | `game/affixes.gd:88` |
| D1 — section 20's aggregation-law bullet lists Sturdy among the aggregate-readable rules while its own counter-example (and the K1 prompt) pin the per-instance sum; the implementation and the suite follow the counter-example | DOC CONTRADICTION / BUCKET 2 | `docs/CONTRACTS.md` §20 `:2077-2085` |
| D7 — the two pool-clamp rows ride a hand-built over-capacity summary (no legal fit reaches 3x); named so R1 can tier it | TEST DESIGN / BUCKET 1 | `tests/test_s7_affixes.gd:254-268, 414-428` |
| K2 must pass the **base-id** fit (`_launch_fit`) beside the summary: the alignment is by `base_id`, so a raw instance-id fit aligns nothing (and its base math already warns) | HANDOFF | `game/ship_fit.gd:1112-1138` |
