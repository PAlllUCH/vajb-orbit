# P1e report — refinery module (docs 04, 01 §7, 17 §5/§6)

Deliverable: **`vajb-orbit/game/refinery.gd`** (new, the only file left behind).
Probe `tools/_probe_p1e.gd` + `tools/_probe_p1e.tscn` were created, run twice,
then deleted; no `.uid` sidecars. The probe's own `user://p1e_probe.cfg` and
`user://p1e_probe_log.txt` are deleted by the probe (verified: the Godot user dir
now holds only `profile.cfg` / `settings.cfg`, and `profile.cfg`'s mtime
`18.09.2026 11:00:08` predates both runs — the real profile was loaded, never
written).

## Module (192 lines)

`class_name Refinery extends RefCounted`. Header cites 04 (§2 ratio, §3 fees,
§5 panel contract), 01 §7 (log + order) and 17 §5 (transaction law) and records
the 3n ratio decision and the logging choice.

- `const FEE_PER_UNIT := 5`, `ORE_PER_INGOT := 3`,
  `FEE_PER_CONVERSION := FEE_PER_UNIT * ORE_PER_INGOT` (derived, so §2/§3 cannot
  drift). Reasons: `unknown_mineral`, `invalid_count`, `insufficient_ore`,
  `insufficient_credits`, `nothing_to_refine`.
- `fee_for(n)` — 0 for `n <= 0`; `convertible(profile, id)` — integer division of
  `cargo_qty(ore_id)` by 3, 0 for unknown minerals; `stacks(profile) ->
  Array[Dictionary]` — catalogue-order rows for minerals with `>= 1` conversion:
  `{mineral_id, entry, ore_qty, conversions, fee}`, read-only.
- `refine(profile, id, n)` — verify -> take -> pay -> give -> log; if the
  defensive `spend` fails it `add_cargo`s the ore back before refusing.
- `refine_all(profile)` — one confirmed batch (take all -> pay once -> give all)
  with an explicit `taken` list, so a defensive failure restores exactly what was
  removed; `minerals` is catalogue-ordered.

Review notes: the profile is `Node`-typed and reached through `call()`/`int()`
(the module must not name the PlayerProfile autoload, and the house UI code calls
the profile the same way); no RNG, no floats, no `print`, no private state, tabs,
integers only.

## 04 §5 conflict (flagged, not silently resolved)

04 §5 writes `remove_cargo(mineral_id, 4n)`. 04 §2 (3 ore -> 1 ingot), 04 §3
(5 CR per ore unit = 15 per conversion) and the 17 §6 test ("3 Iron ore + 15 CR
fee -> 1 Iron ingot") all fix the ratio at 3. This module takes **3n**; the 4n
line is a doc typo for whoever owns 04 §5. Called out in the module header.

## Logging choice (documented in the header)

`refine` writes one line per call: `..., REFINE, mineral_iron, 3, -15, 985`.
`refine_all` writes **one combined line**: `..., REFINE, all, 9, -45, 955`
(item `all`, qty = total ore taken, delta = -total fee) instead of one line per
mineral, so a batch replays as one confirmed action.

## Command and observed output

    "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tools/_probe_p1e.tscn --quit-after 300

Run 1: `EXIT=0`, `[P1e] all 57 checks passed`, `PROBE OK`, 0 `FAIL`, 0
`SCRIPT ERROR` — but 20 ObjectDB leaks + 1 resource at exit from the off-tree
profiles never being freed. Fix: the probe tracks every profile and `free()`s it
before quitting.

Run 2 (final): `EXIT=0`, `[P1e] all 57 checks passed`, `PROBE OK`, 0 `FAIL`,
0 `SCRIPT ERROR`, and the exit-time leak warnings are gone. Quoted evidence:
```
[P1e] PASS fee_for(1) == 15 -> 15
[P1e] PASS log line is ... 2026-09-18T09:24:22, REFINE, mineral_iron, 3, -15, 985
[P1e] PASS combined line is ... 2026-09-18T09:24:23, REFINE, all, 9, -45, 955
[P1e] all 57 checks passed
PROBE OK
```

## Assertions (57, all PASS)

- **Step 1, fees (5):** `fee_for(0)==0`; `(1)==15`; `(3)==45`; `(-4)==0`; `FEE_PER_UNIT==5` + `ORE_PER_INGOT==3` + `FEE_PER_CONVERSION==15`.
- **Step 2, 3 Iron + 15 CR -> 1 ingot (9):** ok; reason empty; `ore_taken==3`; `ingots==1`; `fee==15`; hold is exactly `{ingot_iron: 1}` (no `mineral_iron`); credits `985`; exactly one new REFINE line, reading `..., REFINE, mineral_iron, 3, -15, 985`.
- **Step 3, partial stacks (8):** `convertible(gold)==2`; `convertible(unknown)==0`; ok; `ore_taken==6`; `ingots==2`; `fee==30`; 8 gold -> 2 ore + 2 ingots left; credits `970`; `convertible(gold)==0` afterwards.
- **Step 4, refusals (8):** 2 ore -> `insufficient_ore`, nothing moved; credits 10 -> `insufficient_credits`, nothing moved; unknown mineral -> `unknown_mineral`; `0` and `-3` conversions -> `invalid_count`; cargo and credits untouched in all three cases.
- **Step 5, `refine_all` (13):** two stacks -> ok, reason empty, `conversions==3`, `ingots==3`, `fee==45` (one total fee), `minerals==[iron, copper]`, hold `{ingot_iron: 1, ingot_copper: 2}`, credits `955`, exactly one new log line reading `..., REFINE, all, 9, -45, 955`; 2 ore only -> `nothing_to_refine` with empty `minerals`, nothing moved; 20 CR vs 30 CR total -> `insufficient_credits`, credits and both ore stacks untouched.
- **Step 6, `stacks` (14):** 3 convertible minerals; catalogue order `[iron, aluminium, gold]` (copper at 2 ore and `ingot_iron` excluded); iron row `3/1/15 CR` with its catalogue entry (`name == "Iron"`); aluminium row `5/1/15`; gold row `8/2/30`; copper not listed; ingot not listed; `convertible(copper)==0`; `convertible(aluminium)==1`; `stacks` mutated nothing (credits 1000, cargo 8 gold + 4 ingots).

## Reviewer notes

1. On refusal `refine` reports `fee: 0` (nothing was charged); `refine_all` reports the batch's `conversions` but `ingots: 0`, `fee: 0`. A panel that wants to show the price should call `fee_for()` / read `stacks()`; say so if refusals should instead echo the requested fee.
2. `refine_all` refuses a zero total fee with `nothing_to_refine` (04 §5 lists only REFINERY ALL / REFINE N / CANCEL, so the panel can also hide the button).
3. The probe exercises the real `PlayerProfile` script but never the autoload, so `profile_changed` emission is inherited and out of scope here. 04 §5's `4n` typo is the only doc inconsistency found in this pass.
