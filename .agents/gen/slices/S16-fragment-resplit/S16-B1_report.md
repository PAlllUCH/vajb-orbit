---
slice: S16
worker: S16-B1
model: "deepseek-v4.1-flash"
status: informational
gate: "859/0 -> 866/0"
---

# S16-B1 report

## Result
Shot debris now re-splits: `AsteroidField._cleave` marks every rock it builds
(`fragment.call(&"mark_cleave_child")`, `asteroid_field.gd:460`), and
`Asteroid.cleaves()` is `_bore_ore > 0.0 or _cleave_child`
(`asteroid.gd:419`). Originals are never marked, so ruling 17's yield-0 law is
unchanged for them. New suite `tests/test_s16_resplits.gd` (7 rows, AC1-AC6)
lands green; gate `[SUMMARY] passed=866 failed=0` twice on fresh scratch stores
(was 859/0).

## Deviations from SLICE.md / S16_BRIEF
1. **Brief §2 rule 5's "marking them changes no observable number" is
   inaccurate for the mining route's printed diagnostics.** Marking the
   direct mining children is indeed inert (they already cleaved), but the
   mining route also builds **0-bore descendants** (an XL's reserve 8 split
   across up to 12 children leaves some at 0 units), and those now split too.
   Consequence, measured: `test_s14_splits.gd`'s AC3 line moved from
   `family_realised=32 steps=42 rocks_spawned=17` to `... steps=48 rocks_spawned=23`.
   **The asserted quantity is byte-identical** (`family_realised=32`), so S14's
   AC3 row stays green and no gate row moves; only its printed path count grows.
   This is bucket-1 (inside a pinned acceptance: the rule says fragments split
   whatever their bore, so the behaviour is correct and the prose is loose).
   Reversal if the owner disagrees: none needed, no number changed.
2. **Doc-comment amendments** in the two game files (the stale "a yield-0 rock
   cleaves into nothing" lines now say *original*). No code or number changed.
3. No answer to §2 rule 2's "report it, do not fix" triggered: a 0-bore
   fragment cannot reach a burst with `owed > 0` (see Evidence).

## Pre-grep: candidate rows and their route (before any edit)
Every gate suite that touches a rock, its route, verdict. "unchanged" = the row
reads originals only, or re-cracks nothing, so marking cannot move it.

| Row (`file:line`) | Route | Verdict |
|---|---|---|
| `test_engine2_cleaving.gd:627` yield-0 bare | original via field, asserts `cleaves()` false | unchanged, green |
| `test_engine2_cleaving.gd:370/431/453/488/536` cleave shape | original deplete, children inspected | unchanged |
| `test_engine2_cleaving.gd:342` split table | const table | unchanged |
| `test_engine2_cleaving.gd:254/284/305/320` body/work | no cleave | unchanged |
| `test_engine2_cleaving.gd:551/581/605/658` fx/cue/small burst | original parent only | unchanged |
| `test_s13_caps.gd:190` gun leg (`_run_gun_leg`) | whole-field gun, counts pickups | unchanged (fragments pay 0) |
| `test_s13_caps.gd:147/169/220` capped share / no-ore child / single rock | original only | unchanged |
| `test_s13_caps.gd:201` mined family + respawn `:212-217` | whole-field mining, realised + credit 0 | unchanged (`bore` sum, credit 0) |
| `test_s13_caps.gd:133` Small reserve | original Small | unchanged |
| `test_s13_caps.gd:52/73/99/114` tuning/helpers | constants | unchanged |
| `test_s13_mining_batteries.gd:34/66/83/104` | bare `Asteroid.new()` + `setup`, no field | unchanged |
| `test_s14_splits.gd:215` AC3 mined family | whole-family mining | row green; **printed steps 42->48, rocks 17->23** (dev. 1) |
| `test_s14_splits.gd:82/155/172/188` split shape | originals, children not re-cracked | unchanged |
| `test_s14_splits.gd:257/288/333/356` mix/look/overlay | tuning + RNG | unchanged |
| `test_s2_6_burst.gd:88/114/167/223` burst shape | original L, fragments inspected | unchanged |
| `test_s8_qa_fixes.gd:140`, `test_combat_repair_c5.gd:158` | single rock, no field chain | unchanged |
| other suites (s2_6_beam, s6_heat, s13_devmenu, engine2_fixes, weapon_fx_f2, c1_stub_rock) | no whole-field loop, no fragment re-crack | unchanged |

## Per-AC measured numbers (`tests/test_s16_resplits.gd`, gate line refs)
- **AC1** (gate:562): `shatters=18 passes=3 children_of_root=7`; root is XL, its
  mixed set carries L+M+S, every child strictly smaller, S leaves no rock.
- **AC2** (gate:564): `root_paid=1 fragment_shatters=18 total_paid=1`; each of the
  18 fragment shatters had `bore_ore == 0.0` and left `_pickup_units` at 1.
- **AC3-gun** (gate:568): `root_bore=32.0 bound=4.200 realised=1 steps=19` <= cap.
- **AC3-mine** (gate:566): `root_bore=32.0 family_realised=32 steps=76
  rocks_spawned=53` (S14's own fixture copy; within 32+-1, no mint).
- **AC4** (gate:570): `bare_cleaves=false marked_cleaves=true`.
- **AC5** (gate:572): `passes=4 family_rocks=19 live_after=0` (<= XL->L/M/S->M/S->S).
- **AC6** (gate:574): `gun_share=0.10 core_share=0.25 mix_pinned=true
  marker_runtime_only=true`.

## Evidence
- Baseline gate: `XDG_DATA_HOME=$(mktemp -d) $GODOT_CONSOLE --headless --path
  "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200`
  -> `[SUMMARY] passed=859 failed=0`; `[S14] AC3 ... steps=42 rocks_spawned=17`.
- After: same command (fresh scratch), twice -> `[SUMMARY] passed=866 failed=0`
  both times; `[S16]` lines above at log lines 562-574.
- Rule 2's finding check: a 0-bore fragment has `_bore_ore = 0.0` and
  `reserve = maxf(bore - yield_units, 0) = 0` (`asteroid.gd:287-288`), so the gun
  owed `minf(0, 0.10*0) = 0` and the mining owed `= reserve = 0`; `_pay_burst`
  returns on `owed <= 0.0` (`asteroid_field.gd:506`). No path reaches owed > 0.
- Only `_cleave` marks: `rg -n 'mark_cleave_child' vajb-orbit/` -> the definition
  (`asteroid.gd:409`) and the one call site (`asteroid_field.gd:460`).
- `git status`: only `game/asteroid.gd`, `game/asteroid_field.gd`,
  `tests/test_s16_resplits.gd` (plus the pre-existing `crushrc`).

## Files touched
- `game/asteroid.gd` — `_cleave_child` field, `mark_cleave_child()`, `cleaves()`
  gains `or _cleave_child`; doc comments amended.
- `game/asteroid_field.gd` — one `mark_cleave_child` call after `_new_rock` in
  `_cleave`; doc comment amended.
- `tests/test_s16_resplits.gd` — new suite, AC1-AC6 (7 rows).

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| S14 AC3's printed `steps`/`rocks_spawned` drift upward under S16 (row stays green) | LOW | `test_s14_splits.gd:215` |
