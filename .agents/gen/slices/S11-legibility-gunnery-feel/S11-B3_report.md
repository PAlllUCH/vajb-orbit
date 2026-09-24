---
slice: S11
worker: S11-B3
model: "deepseek/deepseek-flash (DeepSeek API direct), reasoning-effort high"
status: actionable
gate: "788/3 (brief baseline 775/0 at S10 close 396b8f3; 13 other rows belong to B1/B4, which landed first)"
---

# S11-B3 report

## Result

- `game/weapons.gd:73` adds `const NEAR_INFINITE_RANGE := 30000.0` beside `FAMILIES`, applied
  as `&"range"` of **laser** (`:104`), **plasma** (`:111`), **cannon** (`:126`) and **railgun**
  (`:138`). `rocket` stays `900.0` and `mine` stays `0.0`; every other family key is
  byte-identical (`git diff` touches exactly the const plus those four literals).
- Headless read of the shipped table: `const=30000.0 laser=30000.0 plasma=30000.0
  cannon=30000.0 railgun=30000.0 rocket=900.0 mine=0.0`.
- `projectile.gd`'s `max_range` contract (`:441,503,635`) and `game.gd`'s range readout are
  untouched; the fizzle stays finite, so a travelling shot still despawns.

## Deviations

1. **BLOCKED — the §23.4 test row could not be re-derived (escalation bucket 2).** The
   dispatch's `VAJB_WORKER_FILES` (`.agents/gen/slices/S11-legibility-gunnery-feel/S11_prompts.md`,
   B3 block) is `vajb-orbit/game/weapons.gd,.agents/…/S11-B3_report.md` — it excludes
   `vajb-orbit/tests/`. The file-set hook denied the edit to
   `tests/test_engine2_weapons.gd:141-145`; the prompt text and the brief's worker table
   (`S11_BRIEF.md` §Workers: `vajb-orbit/game/weapons.gd,vajb-orbit/tests/`) both grant
   `tests/`, so the dispatch contradicts itself. The hook is the authority for my grant, so
   the row is reported, not edited. D11-C1 holds `vajb-orbit/tests/` directory-wide at the
   moment of this dispatch, which is why the narrowing exists.
   Required change, one row, no bound weakened — `tests/test_engine2_weapons.gd:141-144`
   becomes `assert_eq(WeaponScript.range_of(&"laser"), 30000.0, …)` for laser/plasma/cannon/
   railgun (add `assert_eq(WeaponScript.NEAR_INFINITE_RANGE, 30000.0, …)`), `:145` `rocket`
   unchanged at `900.0`. Reversal: the four literals back to `500.0 / 450.0 / 600.0 / 800.0`.
2. **Not mine — `tests/test_s7_affixes.gd` is red on B4's constant.** Two rows fail on
   `coast_time` `2.0 → 2.5` (`test_lightened_flips_its_own_plate_and_never_crosses_into_a_bonus`
   and `test_resolve_without_a_summary_is_the_pre_s7_fixture`). B4's file set names none of
   `tests/test_s7_affixes.gd`, so that suite is unowned by both S11 builders the same way the
   range row is. Routed with this report, not edited.

## Evidence

Commands (each on a fresh scratch store, live profile never written):

```
XDG_DATA_HOME=$(mktemp -d) timeout 900 "$GODOT_CONSOLE" --headless --path "$VAJB_PROJ" \
  res://tests/headless_runner.tscn --quit-after 1200
```

- Gate pass 1: `[SUMMARY] passed=788 failed=3`
- Gate pass 2: `[SUMMARY] passed=788 failed=3`
- `[FAIL] test_engine2_weapons.gd.test_ranges_are_the_section_13_row: laser 500` — the §23.4
  row the prompt asked me to move, blocked by the file set above.
- `[FAIL] test_s7_affixes.gd.… : coast too (got 2.500000, want 2.000000)` — B4's, deviation 2.
- Headless table read: `[B3] const=30000.0 laser=30000.0 plasma=30000.0 cannon=30000.0
  railgun=30000.0 rocket=900.0 mine=0.0`.

## Files touched

- `vajb-orbit/game/weapons.gd` — the const and the four `&"range"` rows only.

## Reversals

- Delete `const NEAR_INFINITE_RANGE` (`weapons.gd:73`) and restore the four rows to
  `500.0 / 450.0 / 600.0 / 800.0`; the in-file comment at `weapons.gd:69-72` carries the same
  reversal.
- Nothing else to reverse: no test, no probe, no `projectile.gd`/`game.gd` change landed.

## Follow-ups

| Item | Kind | Where |
|---|---|---|
| Re-derive the four §23.4 range asserts to `30000.0` (and pin the const) | test row, blocked | `tests/test_engine2_weapons.gd:141-145` |
| Re-derive the two `coast_time` rows to T1 `2.5` (B4's constant) | test row, blocked | `tests/test_s7_affixes.gd` |
| Widen/narrow `VAJB_WORKER_FILES` per lane before dispatch: B3's set and the brief disagree | dispatch law | `S11_prompts.md` B3 block vs `S11_BRIEF.md` §Workers |
