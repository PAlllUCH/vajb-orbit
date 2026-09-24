---
slice: D7
worker: D7-C4
model: "deepseek-v4-flash (crush run, per D7_prompts.md), Godot 4.7.2-stable headless"
status: actionable
gate: "711/0 (pre-change baseline) -> 711/0, four runs, identical, on scratch stores"
---

# D7-C4 report — §3.1b pool bars removed (the cluster's FUEL/ENRG dials are the pool readouts)

## Result

UI_SPEC §3.1b's 2026-09-24 amendment is applied: the two `ProgressBar` blocks (`EnergyBlock`,
`FuelBlock`) and their labels are off the flight HUD — measured `retired_pool_blocks()` returns
both, `is_visible_in_tree() == false` for each. The `EMERGENCY FLIGHT` banner stays in the
TopLeft column (`CanvasLayer/TopLeft/Blocks`) where the blocks were, `accent_danger_bright`
(`Color(0.9098, 0.3843, 0.1647, 1.0)`), hidden until `set_emergency(true)`. `set_pool` and
`set_emergency` keep their §7 signatures; the pool feed now drives the cluster's FUEL/ENRG value
dials alone — measured: fuel 12/200 reads **6 %** (`danger=true`), energy 40/100 reads **40 %**
(`danger=false`). **Gate 711/0 on four identical runs** (pre-change baseline 711/0).

## Test rows touched (every row, and why)

Exactly the rows that asserted the two blocks' widgets. Every other row is byte-green; there are
no other edits to `test_engine2_hud.gd` besides the section header comment below.

| # | file / row | disposition |
|---|---|---|
| 1 | `test_engine2_hud.gd::test_the_bars_are_the_two_blocks_section_three_asks_for` | **renamed** `test_the_pool_blocks_retire_to_the_cluster_dials`. It asserted the removed widgets (`_pool_bars` + the 260×14 `ProgressBar`); now asserts the two blocks are retired and the dials carry the feed (percent 40 / 6, fuel danger). |
| 2 | `test_engine2_hud.gd` §3.1b section header comment (line 60) | comment only, no assertion: "the two pool bars" -> "the pool feed (the cluster's FUEL/ENRG dials)". |
| 3 | `test_d7_cockpit.gd::test_the_old_hud_column_is_gone_from_the_flight_hud` — trailing sub-assertion (was lines 404–410) | the only part of the row that asserted the blocks' widgets (it asserted `_pool_bars` survives). Re-aimed: the two blocks are retired + hidden, and the dials carry the feed. The row's other five assertions (the retired column, HULL/SHLD/AMMO cluster rows) are unchanged. |

**Not touched** (they assert values/flags, not the blocks' widgets, so they stay byte-green):
`test_pool_bars_hold_the_values_they_were_pushed` (`_pool_current`/`_pool_maximum` bookkeeping —
kept, that is the frozen API's held reading and what the dials are handed),
`test_the_emergency_flag_flips_the_banner_and_the_energy_fill` (the flag + the banner, both kept),
`test_an_unknown_pool_kind_is_ignored_rather_than_fatal` (the kind guard — kept).

The row count is unchanged (711 before and after): row 1 renamed, not added or removed.

## What shipped, as measured

### `ui/hud/hud.gd`

- `_retire_pool_blocks()` (new): hides the two block `VBoxContainer`s at the end of
  `_build_pool_blocks()` (the banner is moved to column index 0 before them and stays).
- `retired_pool_blocks() -> Array[Control]` (new): `[EnergyBlock, FuelBlock]` in `POOL_KIND_*`
  order. Deliberately **not** merged into `retired_widgets()` — that list is §3.7's separate
  old-column retirement, and `test_d7_cockpit.gd`'s count row (5) stays green.
- `_pool_blocks: Dictionary` (new): the block registry the accessor reads; `_register_pool`
  fills it beside `_pool_bars`.
- `set_pool(kind, value, maximum)`: signature unchanged; drops the two removed lines
  (`_refresh_pool(kind)` and the now-stale comment) and hands the held reading to
  `_cockpit.set_pool` only.
- `set_emergency(active)`: signature unchanged; drops `_refresh_pool(POOL_KIND_ENERGY)`
  (the Energy fill it used to tint is gone; an empty tank already dangers the FUEL dial through
  the pool feed). It drives `_apply_emergency()` — the banner — alone.
- `_apply_emergency()` / `_register_pool()` comments updated to the retired state.

The blocks stay **in the scene, hidden** (not deleted): the frozen §7 API keeps a widget behind
it, `_pool_bars` survives as the kind guard, and the amendment's own reversal is an unhide. The
theme-change pass (`_notification` -> `_refresh_pools()`) still runs so a reversal is a pure
unhide; the live pool feed no longer touches the bars.

### Measured (scratch probe, `XDG_DATA_HOME=/tmp/d7c4_probe`, deleted after the run)

```
PROBE_RETIRED count=2 names=["EnergyBlock", "FuelBlock"] visible=["false", "false"]
PROBE_BANNER name=EmergencyBanner parent=Blocks visible=false text=EMERGENCY FLIGHT
PROBE_DIAL fuel={ "value": 12.0, "maximum": 200.0, "percent": 6, "danger": true }
           enrg={ "value": 40.0, "maximum": 100.0, "percent": 40, "danger": false }
PROBE_BANNER_ON visible=true colour=(0.9098, 0.3843, 0.1647, 1.0)
PROBE_BAR_REGISTRY keys=[&"energy", &"fuel"]
PROBE_READOUTS { "spd": 0, "hull": 0, "shield": 0, "ammo": 0 }
```

`colour=(0.9098, 0.3843, 0.1647, 1.0)` is `accent_danger_bright`; `parent=Blocks` is
`CanvasLayer/TopLeft/Blocks` — the TopLeft column where the blocks were.

## Deviations from the brief / docs (bucket-tagged, each reversible)

1. **(bucket 1) Hidden, not deleted.** Mirrors §3.7's "hidden/no-op widgets where nothing
   remains to drive" and the amendment's own reversal ("restore the two blocks"). Reversal:
   drop the `_register_pool` calls (or the `_retire_pool_blocks()` call).
2. **(bucket 1) A separate accessor, not `retired_widgets()`.** Merging would have moved the
   §3.7 old-column count row, which does not assert the pool blocks — outside this worker's
   permission. Reversal: merge the two lists.
3. **(bucket 1) The theme-change pass still refreshes the hidden bars.** So a reversal is an
   unhide with no other edit; the live feed (`set_pool`/`set_emergency`) no longer drives them,
   which is what the task pins. Reversal: remove the `_refresh_pools()` call in `_notification`.
4. **(bucket 1) `_pool_current`/`_pool_maximum` stay.** They are the frozen API's held reading
   (and what the dials are handed), not bar state — dropping them would have moved two rows that
   assert no widget. Reversal: inline the clamp into the `_cockpit.set_pool` call.

## Evidence

Gate (pre-change baseline, then four identical post-change runs; scratch stores; the only
`SCRIPT ERROR` is the pre-existing benign one in `test_weapon_fx_f4.gd:178`, present on the 711
baseline too). The first pair (`g1`/`g2`, 12:06) ran while D7-A1b was still writing the seg
re-cut and its `.import` sidecars, so the final pair (`g3`/`g4`, 12:08+) was run again on the
settled tree and is the authoritative one:

```
XDG_DATA_HOME=/tmp/d7c4_base godot --headless --path "$VAJB_PROJ" \
        res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=711 failed=0

XDG_DATA_HOME=/tmp/d7c4_g1 ...   [SUMMARY] passed=711 failed=0  (exit=0)
XDG_DATA_HOME=/tmp/d7c4_g2 ...   [SUMMARY] passed=711 failed=0  (exit=0)
XDG_DATA_HOME=/tmp/d7c4_g3 ...   [SUMMARY] passed=711 failed=0  (exit=0)   <- settled tree
XDG_DATA_HOME=/tmp/d7c4_g4 ...   [SUMMARY] passed=711 failed=0  (exit=0)   <- settled tree
```

Each scratch store holds only `_gate_scratch/` + `logs/`. The live store is untouched by every
run (before and after: `profile.cfg` md5 `b6dfd89df04bcf1923e8b31f3f58b66c`, `economy_log.txt`
md5 `4182a16526c5afef556b21922f29768d`, `profile.cfg` mtime `2026-09-24 11:55:25`).

The two changed rows pass in the full gate:

```
[PASS] test_engine2_hud.gd.test_the_pool_blocks_retire_to_the_cluster_dials
[PASS] test_engine2_hud.gd.test_the_old_hud_column_is_gone_from_the_flight_hud
```

Frozen-file check for this worker:

```
git diff --name-only -- vajb-orbit/  ->
  vajb-orbit/tests/test_d7_cockpit.gd
  vajb-orbit/tests/test_engine2_hud.gd
  vajb-orbit/ui/hud/hud.gd
  (+ the five assets/ui/*.png.import sidecars and staging/phase_g/* — D7-A1b's parallel ship
     step, not this worker)
git diff --name-only -- vajb-orbit/project.godot vajb-orbit/ui/theme \
        docs/gameplay/18_engine_spec.md docs/gameplay/08_ship_slots_modules.md \
        docs/CONTRACTS.md vajb-orbit/game vajb-orbit/autoload vajb-orbit/addons  -> (empty)
```

## Files touched

- `vajb-orbit/ui/hud/hud.gd` — the two blocks retired + `retired_pool_blocks()`, `set_pool` /
  `set_emergency` no longer touch the bars, comments
- `vajb-orbit/tests/test_engine2_hud.gd` — one row re-aimed (renamed) + the section header
- `vajb-orbit/tests/test_d7_cockpit.gd` — one row's trailing sub-assertion re-aimed

## Follow-ups

None. The hidden bars' theme-change refresh (Deviation 3) is deliberate and awaits the
amendment's reversal, not a defect.
