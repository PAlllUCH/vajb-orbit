# C7 report — the combat/collision repair wave's one-pass fixer (MED-2 only)

**Worker C7** (one-pass fixer; brief `.agents/gen/combat_repair_wave_task.md` worker-table
row C7's authority: "A fixer pass (C7) follows only if C6 leaves HIGH or MED").
`VAJB_WORKER_FILES=docs/CONTRACTS.md` — exactly the file MED-2 names, and the only file
this pass wrote. **Owned finding: MED-2 only.** MED-1 (C5's file set exceeded) is
explicitly *not* mine and is untouched; see §5.6.

**Headline: `docs/CONTRACTS.md`'s four contradictions with the shipped code are
corrected, each with its measured evidence cited inline, and the v1.2 changelog entry
records the wave, the retune and the four corrections. No code, test, asset, theme,
spec or other doc was touched. `git status` proves it (§4.4).**

Source of the finding: `.agents/gen/combat_repair_c6_report.md` §0's tier table (MED-2
row), §7's pin table and §9's MED-2 block. C6's cure line: "One pass: the four
corrections + a v1.2 changelog entry (L37 already tracks the changelog)."

## 0. The four corrections, and where each one is

| # | § | Was | Now | Measured evidence cited in the doc |
|---|---|---|---|---|
| 1 | §5 rock body pin | "layer 1 / mask 0 (so rocks do not collide with each other)" | **layer 1 / mask 2** (the hull layer); `mask 2 & layer 1 == 0` is what keeps two rocks apart | C1's ram: pre-fix `v_peak 0.000 u/s`, `pos_delta 0.000 u`; shipped `72.821 / 20.323`; a `mask 1` control still reads `0.000` |
| 2 | §9 expected gate | `passed=226 failed=0` | the measured **236**, with the wave's 10 tests broken out and the 20-suite ledger | C6's `gate_c6.log`: `[SUMMARY] passed=236 failed=0`, exit 0 |
| 3 | §4 body pin | "all derived from §13, nothing retuned" | the `coast_time` ×0.50 retune recorded, with the before/after and §13's tick still pending | C3's probe: `t10 1.890 → 0.945 s`, carry `430.32 → 216.85 u`, accelerate legs identical |
| 4 | §8.2 `NpcShip` list | no `shield_up()` | `shield_up() -> bool` added (already pinned on `PlayerShip`) | the wave's plasma row: `87.500` on live shields before, the family's `70.000` after |

Plus one **record edit**, disclosed in §2: the file's own status line still said v1.1
while a v1.2 entry was being appended — the same class of defect as L37, so the header
was moved with the entry.

## 1. The four corrections, each with the raw before/after and the raw evidence

### 1.1 §5 — the rock body pin (the one that encoded the bug)

`docs/CONTRACTS.md:170-181` now reads (raw `view` re-read, §4.2 below): `**layer 1 /
mask 2**. The mask names the *hull* layer, never the rock's own: Godot pairs two bodies
from both sides, and `mask 2 & layer 1 == 0` is what keeps two rocks apart while the
rock's mass now enters a ship contact. **The pre-wave `mask 0` was the defect, not the
guarantee:** …`

Raw evidence, the shipped constants:

```sh
$ grep -n "COLLISION_MASK\|collision_layer\|collision_mask" vajb-orbit/game/asteroid.gd
56:## whether this body's mass enters the solve. With the shipped `collision_mask` 0 the
64:const COLLISION_MASK := 2
206:	collision_layer = COLLISION_LAYER
207:	collision_mask = COLLISION_MASK
```

Raw evidence, C6's pin probe (`.agents/gen/c6/c6_pins_probe.log`), cited above:

```text
[C6-PIN] scene player_ship.tscn HullBody layer=2 mask=1
[C6-PIN] class Asteroid.COLLISION_LAYER=1 COLLISION_MASK=2
[C6-PIN] shipped rock after setup: layer=1 mask=2 units=100
[C6-PIN] mask=0 old_pin(mask==0)=true new_pin(mask==2)=false rocks_apart=true rock_in_solve=false hull_in_solve=true
[C6-PIN] mask=1 old_pin(mask==0)=false new_pin(mask==2)=false rocks_apart=true rock_in_solve=false hull_in_solve=true
[C6-PIN] mask=2 old_pin(mask==0)=false new_pin(mask==2)=true rocks_apart=true rock_in_solve=true hull_in_solve=true
```

Raw evidence, C6's re-run of C1's ram (`.agents/gen/c6/c1_probe_c6.log`):

```text
[C1-RAM] S1 SHIPPED rock: v_at_contact=(0.000, 0.000) v_peak=72.821 v_final=(0.037, 0.000) pos_delta=(20.323, 0.000) |d|=20.323
[C1-RAM] S2b MASK1 rock: v_at_contact=(0.000, 0.000) v_peak=0.000 v_final=(0.000, 0.000) pos_delta=(0.000, 0.000) |d|=0.000
[C1-RAM] C1 CONTROL rock: v_at_contact=(0.000, 0.000) v_peak=0.000 v_final=(0.000, 0.000) pos_delta=(0.000, 0.000) |d|=0.000
```

The pre-fix `0.000 / 0.000` reading the doc cites is C6 §3.1's table (C1's pre-fix log
against C6's re-run), i.e. the same probe on the two trees. **This is the correction that
matters behaviourally**: a lane coding `§5`'s old text would re-introduce the mask
defect, which is exactly why C6 tiered it MED rather than LOW.

### 1.2 §9 — the expected gate

`docs/CONTRACTS.md:659` now reads the measured **236**, and the suite arithmetic at
`:667-671` plus a per-suite measured paragraph at `:686-694` were added. Raw evidence,
C6's gate log:

```sh
$ tail -2 .agents/gen/c6/gate_c6.log
[SUMMARY] passed=236 failed=0
EXIT=0

$ grep -o "^\[PASS\] test_[a-z0-9_]*\.gd" .agents/gen/c6/gate_c6.log | sed 's/\[PASS\] //; s/\.gd//' | sort | uniq -c | sort -k2
      7 test_combat_repair_c5
      9 test_engine2_cleaving
     20 test_engine2_damage
      2 test_engine2_dock
     17 test_engine2_fixes
     19 test_engine2_hud
     13 test_engine2_loot
     28 test_engine2_npc
     16 test_engine2_pools
     29 test_engine2_weapons
     13 test_engine2_wiring
      3 test_engine_c3_flight_decay
     11 test_p1_catalogues
      4 test_p1_clock_log
     13 test_p1_market
      5 test_p1_pricing
      9 test_p1_profile
      6 test_p1_refinery
      5 test_p1_repairs
      7 test_ui_slot_layout
```

That ledger sums to 236 and is the doc's new per-suite line, suite for suite. The wave's
own 10 are C3's `test_engine_c3_flight_decay` (3) and C5's `test_combat_repair_c5` (7);
C6's arithmetic `236 = 226 + 3 + 7` is reproduced above (the 18 pre-existing suites
total 226).

### 1.3 §4 — "nothing retuned"

`docs/CONTRACTS.md:114-124` now records the one exception rather than denying it. Raw
evidence for both halves of the number:

```sh
$ grep -n "result case=shipped_base\|result case=fighter_base" .agents/gen/combat_repair_c3_probe.txt
57:[C3] result case=shipped_base v_release=406.600 t10=1.890 dist10=425.62 t_stop=2.100 dist_stop=430.32 samples=22 monotone=true
101:[C3] result case=fighter_base v_release=427.500 t10=1.512 dist10=358.58 t_stop=1.700 dist_stop=362.67 samples=18 monotone=true

$ sed -n '46,48p' .agents/gen/c6/c3_probe_c6.log
[C3] curve case=shipped_base t=1.100 speed=0.000 along=0.000 s=216.853 drift=0.000
[C3] result case=shipped_base v_release=406.600 t10=0.945 dist10=213.90 t_stop=1.100 dist_stop=216.85 samples=12 monotone=true
[C3] derived case=shipped_base ideal_t10=0.945 ideal_t_stop=1.050 ideal_dist=213.47

$ grep -n "coast_time" vajb-orbit/game/ship_fit.gd | head -14
142:## **The `coast_time` column is retuned (owner ruling, 2026-09-21): all nine rows are
144:## second" is this column: `coast_time` is the only free number in the release path, and
145:## it sets both the release brake (`max_speed / coast_time`) and the body's damp
146:## (`1 / coast_time`), so halving it halves the carry and the lateral settle together and
157:		&"coast_time": 0.8,
165:		&"coast_time": 1.0,
173:		&"coast_time": 1.7,
181:		&"coast_time": 1.3,
189:		&"coast_time": 0.9,
197:		&"coast_time": 2.6,
205:		&"coast_time": 1.9,
213:		&"coast_time": 1.7,
221:		&"coast_time": 2.8,
```

Nine rows, `0.8 / 1.0 / 1.7 / 1.3 / 0.9 / 2.6 / 1.9 / 1.7 / 2.8` — the ×0.50 column C6
§8 lists as the wave's whole delta. The doc names the reversal (×2.0 and re-run) and the
NPC-side consequence C6 measured (the same column reaches every NPC hull through
`ShipStats`; `.agents/gen/LOW_BACKLOG.md` L39), so the corrected pin is not narrower than
the shipped behaviour.

### 1.4 §8.2 — `NpcShip.shield_up()`

`docs/CONTRACTS.md:535-536` adds the line to the pinned class's method list. Raw
evidence — the method exists on both hulls, and only the player's was pinned:

```sh
$ grep -n "func shield_up" vajb-orbit/game/npc_ship.gd vajb-orbit/game/player_ship.gd
vajb-orbit/game/npc_ship.gd:787:func shield_up() -> bool:
vajb-orbit/game/player_ship.gd:258:func shield_up() -> bool:

$ grep -n "shield_up" docs/CONTRACTS.md
535:shield_up() -> bool                        # §4.1's shield reads; added 2026-09-21,
590:shield_up() -> bool                                                     # §4.1's shield reads
                              (line 590 is the pre-existing PlayerShip pin in §8.2)
```

Raw evidence for the fix it carries (C6 §4.1, `.agents/gen/c6/c2_probe_c6.log`):

```text
[C2] CASE target=npc shield=up weapon=plasma frames=60 … shield=600.000->530.000 (d=-70.000 of 600.000)
[C2] CASE target=npc shield=down weapon=plasma frames=60 … hull=950.000->862.500 (d=-87.500 of 950.000)
[C2] SEAM weapons._shield_up(npc)=true _shield_up(shield_reader)=true (the plasma bonus gate)
```

The `-70.000` on live shields is the family's own row (C2-F1's fix); the `-87.500` on the
shields-down variant is where `70 × 1.25` belongs. The doc's comment names
`player_ship.gd:258` as the mirror it copies, which is verifiable above.

## 2. The disclosed fifth edit — the status header

`docs/CONTRACTS.md:3` read `**Status: v1.1 (engine wave 1 + engine slices 0 and 2,
re-reviewed 2026-09-21).**` and now reads `**Status: v1.2 (engine wave 1 + engine slices
0 and 2 + the combat/collision repair wave, re-reviewed 2026-09-21).**`

Not one of the four, and disclosed as such: appending a v1.2 entry while the file's own
status line still claims v1.1 would leave the exact defect L37 tracks (a changelog that
does not describe the file it heads). Every previous entry in this file moved the header
with it (v0.1, v0.1.1, v1, v1.1), so this is the file's existing convention, not a new
one. Reversal if the close-out prefers v1.1: one line, and `git diff docs/CONTRACTS.md`
shows it as an isolated hunk.

## 3. The v1.2 changelog entry

Appended at `docs/CONTRACTS.md:821-854` (the file's end), in the style of v0.1.1/v1/v1.1.
It records, as required:

- **the wave** — the rock's collision half, the rock's `apply_collision_damage` sink,
  the shot/ram chip through `WeaponComponent.GUN_CHIP_RATE` 0.10 (the single owner; the
  owner's re-scope rejected a second damage→work constant), the `NpcShip.shield_up()`
  reader, and the "no pinned signature was renamed, retyped, reordered or removed"
  statement with the four added definitions C6 §7 enumerated;
- **the retune** — `coast_time` ×0.50, nine rows, with the measured before/after, the
  §13-not-ticked status, the NPC-side consequence, and ruling 3's 2×-low "≈ 108 u"
  correction (measured 216.85 u);
- **the four corrections** — each named with what it said and what it says now.

It also cites its evidence (`.agents/gen/combat_repair_c6_report.md`, C1/C2/C3/C5's
reports, the logs under `.agents/gen/c6/`) and closes backlog **L37** in substance.

## 4. Verification — raw output of the re-read

### 4.1 The whole diff against `HEAD` (the before/after for every edited line)

```sh
$ git diff -U0 -- docs/CONTRACTS.md
```

```diff
diff --git a/docs/CONTRACTS.md b/docs/CONTRACTS.md
index 045aac9..5209a43 100644
--- a/docs/CONTRACTS.md
+++ b/docs/CONTRACTS.md
@@ -3 +3 @@
-**Status: v1.1 (engine wave 1 + engine slices 0 and 2, re-reviewed 2026-09-21).** This file is the single source of pinned interfaces
+**Status: v1.2 (engine wave 1 + engine slices 0 and 2 + the combat/collision repair wave, re-reviewed 2026-09-21).** This file is the single source of pinned interfaces
@@ -114 +114,11 @@ laser stay with the hull. Thrust is `mass × the class acceleration`
-`angular_damp = 1 / turn_spinup` — all derived from §13, nothing retuned.
+`angular_damp = 1 / turn_spinup` — all derived from §13 **with one owner-sanctioned
+exception: `coast_time` is retuned ×0.50** (all nine `ShipFit.HANDLING` rows, owner
+ruling of 2026-09-21; §13 itself is not ticked and still carries the pre-retune
+column). Measured by the C3 flight-decay probe on the shipped launch, whose resolved
+row is `§13 × 1.05` (the launched `h_plate_light` penalty), so `coast_time` is
+1.050 s: time to 10 % of the release speed `1.890 → 0.945 s`, carried distance
+`430.32 → 216.85 u`, and both accelerate legs unchanged (`t_accel_total` 2.533 / 2.100
+/ 4.050 / 4.050). The same column also halves every NPC hull's coast and doubles its
+damp (it reaches them through `ShipStats`), which is ruling 3's own "all nine rows",
+not drift. Reversal: multiply the nine rows by 2.0 and re-run the probe. Nothing else
+from §13 moved.
@@ -160,4 +170,12 @@ signal cracked                   # bare, unchanged: the field binds the rock its
-The body (slice 0, ruling 8): mass = `ROCK_MASS_MULT` 4 × the §13 `hull_mass` of
-`ROCK_MASS_REFERENCE` `ship_miner` = 560 t, `linear_damp` 3.71 with REPLACE mode,
-`gravity_scale` 0, `can_sleep = false`, layer 1 / mask 0 (so rocks do not collide
-with each other). The size class is a look *and* the cleaving class:
+The body (slice 0, ruling 8; the mask corrected by the combat/collision repair wave,
+2026-09-21): mass = `ROCK_MASS_MULT` 4 × the §13 `hull_mass` of `ROCK_MASS_REFERENCE`
+`ship_miner` = 560 t, `linear_damp` 3.71 with REPLACE mode, `gravity_scale` 0,
+`can_sleep = false`, **layer 1 / mask 2**. The mask names the *hull* layer, never the
+rock's own: Godot pairs two bodies from both sides, and `mask 2 & layer 1 == 0` is what
+keeps two rocks apart while the rock's mass now enters a ship contact. **The pre-wave
+`mask 0` was the defect, not the guarantee:** with it the rock's inverse mass was
+forced to 0 by the solver, so the ship's half landed while the rock's was dropped — C1
+measured `v_peak = 0.000 u/s`, `pos_delta = 0.000 u`, both pools unchanged, and the
+same ram on the shipped tree reads `v_peak 72.821` / `pos_delta 20.323` (C6's re-run);
+a `mask 1` control still reads `0.000`, so the bit must be the hull's layer. The size
+class is a look *and* the cleaving class:
@@ -516,0 +535,2 @@ hull() / hull_max() / shield() / shield_max() / hull_fraction() / is_alive()
+shield_up() -> bool                        # §4.1's shield reads; added 2026-09-21,
+                                           # already pinned on PlayerShip (player_ship.gd:258)
@@ -639 +659 @@ actually fired.
-Expected: `[SUMMARY] passed=226 failed=0` (re-measured on this host 2026-09-21),
+Expected: `[SUMMARY] passed=236 failed=0` (re-measured on this host 2026-09-21),
@@ -647,3 +667,5 @@ pass added `tests/test_engine2_fixes.gd` (**17**) and the slice-2 close added
-`tests/test_engine2_dock.gd` (**2**), and the UI-chrome wave added
-`tests/test_ui_slot_layout.gd` (**7**), so the total is **226** (the 219 measured
-before that wave, plus this suite's 7) and the count
+`tests/test_engine2_dock.gd` (**2**), the UI-chrome wave added
+`tests/test_ui_slot_layout.gd` (**7**), and the combat/collision repair wave added
+`tests/test_engine_c3_flight_decay.gd` (**3**) and `tests/test_combat_repair_c5.gd`
+(**7**), so the total is **236** (the 226 measured before the repair wave, plus its
+10) and the count
@@ -664 +686,9 @@ p1_catalogues 11 · p1_clock_log 4 · p1_market 13 · p1_pricing 5 · p1_profile
-p1_refinery 6 · p1_repairs 5`. **Known trap:**
+p1_refinery 6 · p1_repairs 5`. **Measured 2026-09-21 (combat/collision repair
+wave review — C6): `passed=236 failed=0`, exit 0, no `SCRIPT ERROR`**, per suite
+`combat_repair_c5 7 · engine2_cleaving 9 · engine2_damage 20 · engine2_dock 2 ·
+engine2_fixes 17 · engine2_hud 19 · engine2_loot 13 · engine2_npc 28 ·
+engine2_pools 16 · engine2_weapons 29 · engine2_wiring 13 · engine_c3_flight_decay
+3 · p1_catalogues 11 · p1_clock_log 4 · p1_market 13 · p1_pricing 5 · p1_profile 9 ·
+p1_refinery 6 · p1_repairs 5 · ui_slot_layout 7` — the 18 pre-existing suites are
+unchanged and the wave's 10 are C3's `tests/test_engine_c3_flight_decay.gd` (**3**)
+and C5's `tests/test_combat_repair_c5.gd` (**7**). **Known trap:**
@@ -790,0 +821,34 @@ ledger exists.
+- **v1.2 (2026-09-21, combat/collision repair wave — C7, this wave's only CONTRACTS
+  writer)** — records the wave, its one retune and the four contradictions the C6
+  review found in this file (`.agents/gen/combat_repair_c6_report.md` §9, finding
+  MED-2; the changelog itself was backlog **L37**). **The wave** (brief
+  `.agents/gen/combat_repair_wave_task.md`; owner rulings of 2026-09-21, both rounds):
+  a rock is now damageable. `Asteroid` carries **layer 1 / mask 2** (the mask names the
+  *hull* layer, so the rock's mass enters a ship contact while `mask & layer == 0`
+  still keeps two rocks apart — the pre-wave `mask 0` was C1's measured defect, not a
+  guarantee), and it implements `apply_collision_damage(amount)` (the §4 ram name,
+  now reachable: C1 measures the rock's half at `v_peak 72.821`, `pos_delta 20.323`
+  against `0.000 / 0.000` before). A shot or a ram chips a rock through
+  `WeaponComponent.GUN_CHIP_RATE` 0.10, the single owner; the owner's second-round
+  re-scope rejected a second damage→work constant, so **no new feel number was
+  invented** and the only constant the game-side diff adds is the layer bit. `NpcShip`
+  gains the `shield_up() -> bool` reader the weapon side already consumed, which fixes
+  plasma landing its +25 % on live shields (measured `87.500` on a 600-shield hull
+  before, the family's own `70.000` after). **No pinned signature was renamed,
+  retyped, reordered or removed** — the whole `vajb-orbit/game/` diff adds four
+  definitions (`COLLISION_MASK := 2`, the `weapons.gd` preload, `apply_collision_damage`,
+  `shield_up`). **The one retune:** `coast_time` ×0.50 on all nine `ShipFit.HANDLING`
+  rows (owner ruling; second-round ruling 3 specifies it), measured on the shipped
+  launch as `t10 1.890 → 0.945 s` and carry `430.32 → 216.85 u` with both accelerate
+  legs unchanged; it also halves every NPC hull's coast and doubles its damp through
+  `ShipStats` (inside the ruling's "all nine rows"), and ruling 3's "≈ 108 u" carry is
+  2× low — measured 216.85 u. **§13 is not ticked:** the spec still carries the
+  pre-retune column, and both its tick and the new chaff/kinetic feel numbers remain
+  the owner's. **The four corrections** the C6 review required, all in this entry's
+  wave: §4's body pin said "nothing retuned" and now records the exception with its
+  evidence; §5's rock body pin said "layer 1 / mask 0" and now reads **layer 1 /
+  mask 2**; §8.2's `NpcShip` list was missing `shield_up() -> bool`; §9's expected
+  gate said `passed=226` and now reads the measured **236** with the wave's 10 tests
+  broken out. Evidence: `.agents/gen/combat_repair_c6_report.md` (the review) and
+  `.agents/gen/combat_repair_c{1,2,3,5}_report.md`, with every raw log under
+  `.agents/gen/c6/`; the wave's LOW block is `.agents/gen/LOW_BACKLOG.md` L38–L47.
```

```sh
$ git diff --stat -- docs/CONTRACTS.md
 docs/CONTRACTS.md | 86 ++++++++++++++++++++++++++++++++++++++++++++++++-------
 1 file changed, 75 insertions(+), 11 deletions(-)
```

### 4.2 Re-reading each edited line (raw `view` output)

Header, `docs/CONTRACTS.md:3`:

```text
     3|**Status: v1.2 (engine wave 1 + engine slices 0 and 2 + the combat/collision repair wave, re-reviewed 2026-09-21).** This file is the single source of pinned interfaces
     4|between workers. Every worker brief says "code against CONTRACTS.md §n" instead of
     5|re-pasting signatures; every review/fix wave owns updating it (additions and
```

§4, `:110-127`:

```text
   110|laser stay with the hull. Thrust is `mass × the class acceleration`
   111|(`max_speed / accel_time`), the brake is `BRAKE_MULT ×` that, the coast is
   112|`max_speed / coast_time` with `linear_damp = 1 / coast_time`, and torque is
   113|`inertia × (alpha + angular_damp × omega)` with `inertia = m·r²/2` and
   114|`angular_damp = 1 / turn_spinup` — all derived from §13 **with one owner-sanctioned
   115|exception: `coast_time` is retuned ×0.50** (all nine `ShipFit.HANDLING` rows, owner
   116|ruling of 2026-09-21; §13 itself is not ticked and still carries the pre-retune
   117|column). Measured by the C3 flight-decay probe on the shipped launch, whose resolved
   118|row is `§13 × 1.05` (the launched `h_plate_light` penalty), so `coast_time` is
   119|1.050 s: time to 10 % of the release speed `1.890 → 0.945 s`, carried distance
   120|`430.32 → 216.85 u`, and both accelerate legs unchanged (`t_accel_total` 2.533 / 2.100
   121|/ 4.050 / 4.050). The same column also halves every NPC hull's coast and doubles its
   122|damp (it reaches them through `ShipStats`), which is ruling 3's own "all nine rows",
   123|not drift. Reversal: multiply the nine rows by 2.0 and re-run the probe. Nothing else
   124|from §13 moved.
   125|Body-body contacts past `COLLISION_MIN_DV` charge `Impact.collision_damage(ship
   126|mass, peer mass, closing speed)` to the player through `PlayerState.damage`, and
   127|offer the peer's half to `apply_collision_damage(amount)` when the peer has it.
```

§5, `:170-181`:

```text
   170|The body (slice 0, ruling 8; the mask corrected by the combat/collision repair wave,
   171|2026-09-21): mass = `ROCK_MASS_MULT` 4 × the §13 `hull_mass` of `ROCK_MASS_REFERENCE`
   172|`ship_miner` = 560 t, `linear_damp` 3.71 with REPLACE mode, `gravity_scale` 0,
   173|`can_sleep = false`, **layer 1 / mask 2**. The mask names the *hull* layer, never the
   174|rock's own: Godot pairs two bodies from both sides, and `mask 2 & layer 1 == 0` is what
   175|keeps two rocks apart while the rock's mass now enters a ship contact. **The pre-wave
   176|`mask 0` was the defect, not the guarantee:** with it the rock's inverse mass was
   177|forced to 0 by the solver, so the ship's half landed while the rock's was dropped — C1
   178|measured `v_peak = 0.000 u/s`, `pos_delta = 0.000 u`, both pools unchanged, and the
   179|same ram on the shipped tree reads `v_peak 72.821` / `pos_delta 20.323` (C6's re-run);
   180|a `mask 1` control still reads `0.000`, so the bit must be the hull's layer. The size
   181|class is a look *and* the cleaving class:
```

§8.2, `:534-537`:

```text
   534|hull() / hull_max() / shield() / shield_max() / hull_fraction() / is_alive()
   535|shield_up() -> bool                        # §4.1's shield reads; added 2026-09-21,
   536|                                           # already pinned on PlayerShip (player_ship.gd:258)
   537|state_name() / target() / heat_on_kill() / standing_on_kill() / art_ready()
```

§9, `:659-671`:

```text
   659|Expected: `[SUMMARY] passed=236 failed=0` (re-measured on this host 2026-09-21),
   660|exit 0, no `SCRIPT ERROR`. A wave is
   661|done = gate green + the worker added tests for their slice. The suite held **53**
   662|tests through engine wave 1; engine slice 0 added `tests/test_engine2_pools.gd`
   663|(**16**) and `tests/test_engine2_cleaving.gd` (**9**), engine slice 2 added six
   664|`tests/test_engine2_*.gd` suites — `weapons` (**29**), `npc` (**28**), `damage`
   665|(**20**), `hud` (**19**), `loot` (**13**) and `wiring` (**13**) — the slice-2 fixer
   666|pass added `tests/test_engine2_fixes.gd` (**17**) and the slice-2 close added
   667|`tests/test_engine2_dock.gd` (**2**), the UI-chrome wave added
   668|`tests/test_ui_slot_layout.gd` (**7**), and the combat/collision repair wave added
   669|`tests/test_engine_c3_flight_decay.gd` (**3**) and `tests/test_combat_repair_c5.gd`
   670|(**7**), so the total is **236** (the 226 measured before the repair wave, plus its
   671|10) and the count
```

§9's measured paragraph, `:686-694`:

```text
   686|p1_refinery 6 · p1_repairs 5`. **Measured 2026-09-21 (combat/collision repair
   687|wave review — C6): `passed=236 failed=0`, exit 0, no `SCRIPT ERROR`**, per suite
   688|`combat_repair_c5 7 · engine2_cleaving 9 · engine2_damage 20 · engine2_dock 2 ·
   689|engine2_fixes 17 · engine2_hud 19 · engine2_loot 13 · engine2_npc 28 ·
   690|engine2_pools 16 · engine2_weapons 29 · engine2_wiring 13 · engine_c3_flight_decay
   691|3 · p1_catalogues 11 · p1_clock_log 4 · p1_market 13 · p1_pricing 5 · p1_profile 9 ·
   692|p1_refinery 6 · p1_repairs 5 · ui_slot_layout 7` — the 18 pre-existing suites are
   693|unchanged and the wave's 10 are C3's `tests/test_engine_c3_flight_decay.gd` (**3**)
   694|and C5's `tests/test_combat_repair_c5.gd` (**7**). **Known trap:**
```

Changelog entry, `:820-855`:

```text
   820|  the fixer's own record is `.agents/gen/slice2_w7_report.md`.
   821|- **v1.2 (2026-09-21, combat/collision repair wave — C7, this wave's only CONTRACTS
   822|  writer)** — records the wave, its one retune and the four contradictions the C6
   823|  review found in this file (`.agents/gen/combat_repair_c6_report.md` §9, finding
   824|  MED-2; the changelog itself was backlog **L37**). **The wave** (brief
   825|  `.agents/gen/combat_repair_wave_task.md`; owner rulings of 2026-09-21, both rounds):
   826|  a rock is now damageable. `Asteroid` carries **layer 1 / mask 2** (the mask names the
   827|  *hull* layer, so the rock's mass enters a ship contact while `mask & layer == 0`
   828|  still keeps two rocks apart — the pre-wave `mask 0` was C1's measured defect, not a
   829|  guarantee), and it implements `apply_collision_damage(amount)` (the §4 ram name,
   830|  now reachable: C1 measures the rock's half at `v_peak 72.821`, `pos_delta 20.323`
   831|  against `0.000 / 0.000` before). A shot or a ram chips a rock through
   832|  `WeaponComponent.GUN_CHIP_RATE` 0.10, the single owner; the owner's second-round
   833|  re-scope rejected a second damage→work constant, so **no new feel number was
   834|  invented** and the only constant the game-side diff adds is the layer bit. `NpcShip`
   835|  gains the `shield_up() -> bool` reader the weapon side already consumed, which fixes
   836|  plasma landing its +25 % on live shields (measured `87.500` on a 600-shield hull
   837|  before, the family's own `70.000` after). **No pinned signature was renamed,
   838|  retyped, reordered or removed** — the whole `vajb-orbit/game/` diff adds four
   839|  definitions (`COLLISION_MASK := 2`, the `weapons.gd` preload, `apply_collision_damage`,
   840|  `shield_up`). **The one retune:** `coast_time` ×0.50 on all nine `ShipFit.HANDLING`
   841|  rows (owner ruling; second-round ruling 3 specifies it), measured on the shipped
   842|  launch as `t10 1.890 → 0.945 s` and carry `430.32 → 216.85 u` with both accelerate
   843|  legs unchanged; it also halves every NPC hull's coast and doubles its damp through
   844|  `ShipStats` (inside the ruling's "all nine rows"), and ruling 3's "≈ 108 u" carry is
   845|  2× low — measured 216.85 u. **§13 is not ticked:** the spec still carries the
   846|  pre-retune column, and both its tick and the new chaff/kinetic feel numbers remain
   847|  the owner's. **The four corrections** the C6 review required, all in this entry's
   848|  wave: §4's body pin said "nothing retuned" and now records the exception with its
   849|  evidence; §5's rock body pin said "layer 1 / mask 0" and now reads **layer 1 /
   850|  mask 2**; §8.2's `NpcShip` list was missing `shield_up() -> bool`; §9's expected
   851|  gate said `passed=226` and now reads the measured **236** with the wave's 10 tests
   852|  broken out. Evidence: `.agents/gen/combat_repair_c6_report.md` (the review) and
   853|  `.agents/gen/combat_repair_c{1,2,3,5}_report.md`, with every raw log under
   854|  `.agents/gen/c6/`; the wave's LOW block is `.agents/gen/LOW_BACKLOG.md` L38–L47.
   855|
```

### 4.3 No stale reading survives except the ones the new prose names

```sh
$ grep -n "passed=226\|passed=236" docs/CONTRACTS.md
659:Expected: `[SUMMARY] passed=236 failed=0` (re-measured on this host 2026-09-21),
687:wave review — C6): `passed=236 failed=0`, exit 0, no `SCRIPT ERROR`**, per suite
851:  gate said `passed=226` and now reads the measured **236** with the wave's 10 tests

$ grep -n "mask 0" docs/CONTRACTS.md
176:`mask 0` was the defect, not the guarantee:** with it the rock's inverse mass was
828:  still keeps two rocks apart — the pre-wave `mask 0` was C1's measured defect, not a
849:  evidence; §5's rock body pin said "layer 1 / mask 0" and now reads **layer 1 /

$ grep -n "nothing retuned" docs/CONTRACTS.md
848:  wave: §4's body pin said "nothing retuned" and now records the exception with its

$ grep -n "shield_up" docs/CONTRACTS.md
535:shield_up() -> bool                        # §4.1's shield reads; added 2026-09-21,
590:shield_up() -> bool                                                     # §4.1's shield reads
636:plasma's `+25 %` reads the **ship's** `shield_up()` rather than the body's silence (70
835:  gains the `shield_up() -> bool` reader the weapon side already consumed, which fixes
840:  `shield_up`). **The one retune:** `coast_time` ×0.50 on all nine `ShipFit.HANDLING`
850|  mask 2**; §8.2's `NpcShip` list was missing `shield_up() -> bool`; §9's expected
```

(Line 590 is §8.2's pre-existing `PlayerShip` pin and line 636 is §7's plasma note —
both pre-date this pass and are the pins C6 §7 declared correct; 535, 835, 840 and 850
are this pass.)

Every remaining hit of a stale string is inside the new prose that names it as stale
(`:176` the defect, `:828` the changelog, `:848-851` the correction record). The pinned
statement at `:659` and the record at `:687` both read 236; no line still *asserts*
`mask 0`, `226` or "nothing retuned".

### 4.4 The file set was respected

```sh
$ git status --short -- docs/
 M docs/CONTRACTS.md

$ git diff --stat -- vajb-orbit/game/
 vajb-orbit/game/asteroid.gd | 38 ++++++++++++++++++++++++++++++++------
 vajb-orbit/game/npc_ship.gd | 12 ++++++++++++
 vajb-orbit/game/ship_fit.gd | 30 +++++++++++++++++++++---------
 vajb-orbit/game/weapons.gd  | 13 +++++++++++--
 4 files changed, 76 insertions(+), 17 deletions(-)
```

One doc file, and it is the owned one. No game file, test, asset, theme,
`project.godot`, `addons/**` or other doc is in this pass's diff; the wave's own
`vajb-orbit/game/` diff is byte-identical to what C6 measured (same four files, same
76/17 line counts), because this pass did not touch it.

## 5. Boundaries — what this pass did and did not verify

1. **I did not re-run the gate.** The 236 is C6's measurement, taken from
   `.agents/gen/c6/gate_c6.log`; I re-read that log's summary and re-derived its
   per-suite ledger (both pasted above, summing to 236) rather than running Godot. A doc
   correction does not change a test count, and this pass changed no test.
2. **The doc's 236 is a measurement on the tree as C6 ran it.** C6 §2 records that the
   theme lane edited `tools/build_theme.gd` and `ui/theme/vajb_theme.tres` *after* C5's
   run, which changes two `ui_slot_layout` print lines and no count. If a later wave
   changes the count, §9's own sentence applies: the count to read is the measured one,
   never a stale total.
3. **§13 is untouched, deliberately.** The coast column's tick, and the chaff/kinetic
   feel numbers, remain the owner's; nothing in this pass ticks or pre-empts them. The
   §4 correction says so explicitly, so the next reader does not read the shipped
   column as spec-blessed.
4. **The retune's "≈ 108 u" correction is recorded, not acted on.** Measured 216.85 u;
   the wrong figure came from the owner's ruling, and correcting the ruling itself is
   the owner's/§13's pass, not this one.
5. **No `--debug` lint ledger was run for this pass** — the only file changed is a
   markdown doc, so CONTRACTS §9's fifth form does not apply (and L45 already records
   that `lsp_diagnostics` silence is not evidence on this host).
6. **MED-1 is not mine and is untouched**, per the brief and the reviewer's own
   ownership split. It remains as C6 left it: C5's `npc_ship.gd`/`ship_fit.gd` edits are
   correct and ruling-required but are not in the brief's C5 row. This report does not
   amend the brief or the prompts file.
7. **Backlog L37 is closed in substance by §3's entry**; I did not edit
   `.agents/gen/LOW_BACKLOG.md` (not in my set) — the close-out can mark it done with a
   pointer to the v1.2 entry.

## 6. Files this pass created or modified

- `docs/CONTRACTS.md` — the four corrections, the status header (disclosed, §2) and the
  v1.2 changelog entry. 75 insertions, 11 deletions, all against `HEAD`.
- `.agents/gen/combat_repair_c7_report.md` — this report.

Nothing else. No code, no test, no asset, no theme, no spec.
