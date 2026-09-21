# C6 report — the combat/collision repair wave, verified

**Worker C6** (mandatory reviewer; brief `.agents/gen/combat_repair_wave_task.md`
worker-table row C6, dispatch `.agents/gen/combat_repair_wave_prompts.md` §C6).
`VAJB_WORKER_FILES=vajb-orbit/tests/,vajb-orbit/tools/`. I re-measured rather than
read: every probe re-run, every published number re-derived, the pinned signatures
diffed against `docs/CONTRACTS.md` §4/§8.2 (not against the brief), §13 audited row
by row, and the three disclosed test-side edits judged one at a time. **Nothing was
fixed.**

**Headline: the wave's four fixes and its retune are real, reproducible and correctly
pinned. No HIGH. Two MED (both record/doc, neither behavioural). Ten LOW, all in
`.agents/gen/LOW_BACKLOG.md` as L38–L47. Gate measured by me: `passed=236 failed=0`,
exit 0.**

## 0. The tiers, first

| Tier | Finding | Where | Cure |
|---|---|---|---|
| **HIGH** | *none* | – | – |
| **MED-1** | **C5 wrote two files outside its tabled `VAJB_WORKER_FILES` set** (`game/npc_ship.gd`, `game/ship_fit.gd`) and no record of a widened set exists anywhere in the wave's brief or prompts file — the dispatch protocol says "never widen a set beyond the brief's table" and the hook denies outside writes. Both edits are **correct, owner-directed, disclosed and test-pinned**; only the ownership record is wrong. | brief `.agents/gen/combat_repair_wave_task.md:57` vs `git diff --stat`; prompts `.agents/gen/combat_repair_wave_prompts.md:44` | One pass: amend the brief's C5 row and the C5 dispatch block with the two files plus the ruling that required them (second-round rulings 3 and 4), or record the widened env if that is what ran. §9's `verify_wave` already lists every touched file, so the close-out must not read these two as unexplained. |
| **MED-2** | **`docs/CONTRACTS.md` contradicted the shipped code in four places** at review start (§5's asteroid pin, §9's expected gate, §4's "nothing retuned", §8.2's `NpcShip` method list). §5 as written was the *bug* — a lane coding against it re-builds the mask defect. **A C7 CONTRACTS pass landed in parallel while I wrote this** and addresses all four (§9's list checked against my own gate log: 20 suites, 236, no mismatch); the residual is a completion verification, not a code fix. | `docs/CONTRACTS.md:162`, `:639`, `:114`, `:516` (then); `:170-179`, `:659`, `:683`, `:534` (now) | Close-out: verify the in-flight pass is complete (it was still being written at 15:47); no code fixer pass needed. |
| **LOW ×10** | L38–L47: three stale comments (two in code, one spec prose), a probe scenario that now measures nothing, five evidence-accuracy nits in the C1/C2/C3/C5 reports, and one dispatch-process item. None changes a conclusion. | – | `.agents/gen/LOW_BACKLOG.md` L38–L47. |

**INFO (no action):** the retune also halves every *NPC* hull's coast and doubles its
damp (`npc_ship.gd:695-709` reads the same column through `ShipStats`) — inside ruling
3's own wording ("all nine rows × 0.50"), undisclosed in C5 §3, worth one line in the
owner's playtest. And ruling 3's "carry 430.32 u → ≈ 108 u" is **2× low**: the ramp is
linear, so half the coast time is half the carry — measured **216.85 u** (C5 §3 already
flags this; I re-derived it, §5.3 below).

## 1. What I re-ran, and whether it reproduced

All commands on this host (`godot` = `~/.local/bin/godot` → 4.7.2-stable), logs sidecar
to this report under `.agents/gen/c6/`.

| Probe | Command (byte-identical form) | My log | vs the published log |
|---|---|---|---|
| C1 ram | `godot --headless --path vajb-orbit res://tests/probe_c1_ram.tscn --quit-after 100000` | `c1_probe_c6.log` (185 `[C1-RAM]` lines, exit 0) | **byte-identical** to C5's `combat_repair_c5_c1_after.log`; a second run (`c1_probe_c6_run2.log`) is byte-identical to the first |
| C2 weapons | `godot --headless --fixed-fps 60 --path vajb-orbit res://tests/probe_c2_weapons.tscn --quit-after 12000` | `c2_probe_c6.log` (85 `[C2]` lines, exit 0) | **byte-identical** to C5's `combat_repair_c5_c2_after.log` |
| C2 weapons (paced) | `godot --headless --path vajb-orbit res://tests/probe_c2_weapons.tscn --quit-after 12000` (~82 s, `stepped_frames=4920`) | `c2_probe_paced_c6.log` | `[C2]` payload identical to the fixed-fps run; C2's two kept logs are also byte-identical to each other — **C2's determinism claim holds** |
| C3 decay | `godot --headless --path vajb-orbit res://tests/probe_c3_flight_decay.tscn --fixed-fps 60 --quit-after 6000` | `c3_probe_c6.log` (209 `[C3]` lines, `done cases=4 failures=0`) | byte-identical to `combat_repair_c5_c3_after.log` **except** `clock … wall_ms=350` vs `360`, exactly as C3/C5 disclosed |
| Gate | `godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200` | `gate_c6.log` → `[SUMMARY] passed=236 failed=0`, `EXIT=0`; re-run with the C6 probe in the tree → `gate_c6_after_probe.log`, identical | count identical to C5's; **2 lines differ** (§2) |
| Warning ledgers | `… --debug …` on the C1 and C3 probes | `c1_probe_c6_debug.log`, `c3_probe_c6_debug.log` | C1: 25 warnings, **0 attributed to the two new files** (19 `weapons.gd`, 3 `projectile.gd`, 3 `asteroid.gd`); C3: 22 (19 + 3). 0 `SCRIPT ERROR` in either |
| C6 pin probe | `godot --headless --path vajb-orbit res://tests/probe_c6_pins.tscn --quit-after 600` | `c6_pins_probe.log` | new, mine (§6.1) |

Reproduce the byte-identity claims:

```sh
export PATH="$HOME/.local/bin:$PATH"
godot --headless --path vajb-orbit res://tests/probe_c1_ram.tscn --quit-after 100000 > /tmp/c1.log 2>&1
diff .agents/gen/combat_repair_c5_c1_after.log /tmp/c1.log && echo IDENTICAL
```

**Nothing about the probes' method is unverifiable.** The C1 probe drives a fixed
`linear_velocity` on the shipped `HullBody` from a parent `_physics_process` (tree order:
parents first) and stops the driver on the first contact; the C2 probe uses
`set_firing`/`set_aim_point` (never `Input`, never the cursor); the C3 probe is a *scene*
run driving the real `Input.action_press(&"thrust_forward")` — which is a measured
counter-example to CONTRACTS §9's fourth harness limit, as C3 claims. L17 (save-path
hygiene) is not engaged: no probe in the wave repoints `PlayerProfile.save_path`
(`grep -n save_path` over all six new test-side files → no hit).

## 2. The gate I measured

```
$ godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=236 failed=0          (EXIT=0)
$ grep -c "SCRIPT ERROR" .agents/gen/c6/gate_c6.log     -> 0
$ grep -c "^\[PASS\]"    .agents/gen/c6/gate_c6.log     -> 236
```

`236 = 226 (the brief's baseline) + 3 (C3's `test_engine_c3_flight_decay.gd`) + 7
(`test_combat_repair_c5.gd`)`. Per-suite counts are **identical to C5's run for all 20
suites** (`test_combat_repair_c5 7`, `test_engine_c3_flight_decay 3`, and the 18
pre-existing suites unchanged — `test_engine2_cleaving` still **9**, its edited test
still present). Verified the baseline arithmetic two ways: the pre-fix log
`.agents/gen/c2_gate_after.log` (15:20, before C5's 15:23+ edits) reads `passed=229
failed=0` with the **old** cleaving assertion passing, and `236 − 7 = 229`.

Re-measured a second time **with my own probe files in the tree**
(`.agents/gen/c6/gate_c6_after_probe.log`): still `passed=236 failed=0`, exit 0, and the
log is identical to `gate_c6.log` line for line (the only difference between the two files
is the `EXIT=0` line I append). The probe contributes **0** gate tests on purpose — it is
not named `test_*.gd`, so `headless_runner.gd`'s discovery cannot pick it up.

The only diff against C5's log is two `ui_slot_layout` print lines
(`panel minimum (1308.0, 1372.0)` in C5's run vs `(1308.0, 1788.0)` in mine), both
**PASS**. Cause: the theme lane touched `tools/build_theme.gd` (`PANEL_FRAME_MARGIN 8 →
32`, mtime 15:30:51) and `ui/theme/vajb_theme.tres` (15:32:07) **across** C5's gate run
(its log is 15:31) and before mine (15:33:10) — the tree was not frozen
by the time I ran. Not a wave finding; recorded so the two logs' difference is not later
misread as drift.

## 3. C1's ram, re-measured

### 3.1 The shipped configuration, before and after the fix

| Reading (S1 SHIPPED) | C1's log (pre-fix tree) | mine (shipped tree) |
|---|---|---|
| rock layer/mask | 1 / **0** | 1 / **2** |
| hull body damp | 0.476 | **0.952** (the retune) |
| contact | `frame=45 gap=64.93 closing=450.00` | `frame=45 gap=67.35 closing=450.00` |
| rock `v_peak` / `pos_delta` | **0.000 / 0.000** | **72.821 / 20.323** |
| rock `v_final` | (0.000, 0.000) | (0.037, 0.000) |
| rock pools | `yield 8 -> 8, work 0.0 -> 0.0` | `yield 100 -> 82, work 0.0 -> 0.6179104477612` |
| ship pools | `hull 1250→1250 (+0.000), shield 800→613.821 (−186.179)` | **identical to the digit** |

Both sides' pool deltas are re-measured: the ship pays `−186.179` shield (`hull
+0.000`, shield-first) and the rock gains `18 × WORK_PER_UNIT + 0.6179104477612 =
18.6179104477612 = 186.179104477612 × 0.10`, exactly (`python3`: the two sides agree to
1e-13).

### 3.2 The controls that must stay inert — they do

```text
[C1-RAM] S2  MASK2   rock: v_peak=72.821 pos_delta=20.323   (== S1: the shipped mask is the corrected one)
[C1-RAM] S2b MASK1   rock: v_peak=0.000  pos_delta=0.000    (non-zero is not enough; the mask must name layer 2)
[C1-RAM] C1 CONTROL  rock: v_peak=0.000  pos_delta=0.000    (a bare RigidBody2D, mask 0, no script at all)
```

So the mask is the cause and it must be the hull's layer bit — C1's diagnosis survives
the fix unchanged, and the bare-body control still proves the harness can observe a
solved contact (S1/S2/S3/S6 all move the rock now).

### 3.3 Where C5's after-numbers came from (the one number C1 and C5 disagree on)

C1's S6 read `73.351 / 21.056`; C5's re-run reads `72.821 / 20.323`. C5 attributes the
shift to the retune. **I confirmed the attribution exactly, not by argument**: the
solver produces the inelastic common velocity, so
`v_peak = 110 × v_hull_at_contact / 670`.

| Run | `v_hull_at_contact` | `110·v/670` | printed `v_peak` |
|---|---|---|---|
| pre-retune (C1's log) | 446.77 (= 450 − 3.23/frame) | 73.3503 | **73.351** |
| shipped (my run) | 443.55 (= 450 − 6.45/frame) | 72.8216 | **72.821** |

and the per-frame loss the driver cannot prevent is the release brake itself:
`3.23 → 6.45 u/s` = `193.619 → 387.238 u/s²` = `max_speed/coast_time` at 2.1 s → 1.05 s
(halved). The contact frame also reads further out (`gap 64.93 → 67.35`) because the same
60 Hz step now advances less (`443.55/60 = 7.39 u` vs `446.77/60 = 7.44 u` per frame), so
the first overlapping step is quantised differently. The mask changed *who is solved*; the
retune changed *how fast the hull arrives*. Both are in these numbers, as C5's §2 says.

### 3.4 The floor sweep and the engine-source claim

`39.900 → 0.000000`, `40.000 → 1.471045` (my log, C1's floor-sweep lines) — the §13
floor is exact and neither measured ram is near it. C1's `§5` quote of the engine rule is
**verbatim accurate against the 4.7 branch**: I fetched
`modules/godot_physics_2d/godot_collision_object_2d.h` and
`godot_body_pair_2d.cpp` and the `collides_with` / `interacts_with` pair, the
`collide_A/collide_B` assignment, the `report_contacts_only` branch and the
`inv_mass_A/B = collide_A ? … : 0.0` lines all read as C1 printed them. The one
transcription slip: `collides_with` takes a non-const pointer in the header.

### 3.5 S5 COAST no longer contacts — disclosed, and it *is* the retune's own measurement

```text
[C1-RAM] S5 COAST NO CONTACT in 300 frames: min gap=143.06 ship_v=(0.00, 0.00) rock moved=0.000
[C1-RAM] S5 COAST ship body end: pos=(-143.064, 0.000) travelled=256.936 v=(0.000, 0.000)
```

C1's log had it contacting at `frame=55 closing=272.17` with shield `−68.107`. The
undriven ram at 450 u/s over a 400 u gap can no longer reach the rock
(`450²/(2 × 387.238) ≈ 261 u` of carry, min gap 143 u) — arithmetic I reproduced. It is a
coverage loss (L41), not a contract gap: S1 still measures the driven pair end to end.

## 4. C2's weapons, re-measured

### 4.1 Per-family damage on an NPC hull (950 hull / 600 shield, `ship_fighter`)

| family | shots | hull Δ | shield Δ | row expectation | verdict |
|---|---|---|---|---|---|
| laser | 1 hold / 60 f | +0.000 | **−30.000** | 30 dps × 1 s | exact |
| plasma | 1 hold / 60 f | +0.000 | **−70.000** | 70 dps × 1 s | **exact after C5's fix** (was −87.500) |
| cannon | 5 / 180 f | −135.000 | +0.000 | 5 × 27 | exact |
| railgun | 5 / 180 f | −180.000 | +0.000 | 5 × 36 | exact |
| rocket | 5 released / 4 landed | −720.000 | +0.000 | 4 × 180 | exact |
| mine | 1 / 150 f | −180.000 | +0.000 | alpha 180 | exact |

`bypass_shield` follows the family rows (energy → shield first; kinetic/missile/deployable
→ hull with the shield pool untouched) and the shields-down variant still reads the §4.1
bonus: **laser −30.000 hull, plasma −87.500 hull** (`70 × 1.25`) — i.e. the multiplier
still exists and is now on the right pool. This is the fix for C2-F1, confirmed by
`_shield_up(npc) false → true` on the same probe line the fixer quoted.

### 4.2 The rock rows and the exact no-op path

| family | units extracted | work credited | §6 expectation (10 % of the hit) |
|---|---|---|---|
| laser | 3 | 3.000 | 3.000 |
| plasma | 7 | 7.000 | 7.000 |
| cannon | 13 | 13.500 | 13.500 |
| railgun | 18 | 18.000 | 18.000 |
| rocket | 90 | 90.000 | 90.000 |
| mine | 0 | **0.000** | — (the one remaining rock no-op) |

A 5-unit rock still goes `5 -> 0`, `cracked=true` (laser and cannon), and the real
`player_ship.tscn` mount with the five-weapon fit still destroys it
(`MOUNT-FIRE … rock_units=5->0 rock_freed=true`). The **no-op path is unchanged by the
fix and still silent**: `Damage.apply(rock, 100)` and
`weapons._deliver(rock, 100, false, kinetic)` both read `work 0.000, units 100->100`,
because the rock's new sink is named `apply_collision_damage` (the CONTRACTS §4 ram
name), not `take_damage`. That is exactly the state the owner's second-round ruling 2
sanctioned (C2-F2 measured that no shipped beam/projectile path reaches that seam — both
branch on the `asteroid` group first), and the **mine** remains the only family that
touches no rock, which §8.2's mine row (`triggers on a hull … never on its own source`)
requires. INFO, not a finding.

### 4.3 The launch fit and the dry matrix

`LAUNCH-PANEL … total=1500` (5 packs × 300), `LAUNCH-FIT … fitted_after_filter=[&"laser"]`,
groups 2–5 `dry_reason="none"`, `MOUNT … mining_laser_mounted=false`. C2-F3 (the panel
promises five weapons, the launch installs one, and no mining laser is mounted) is
**untouched by instruction** (second-round ruling 1: "C5 must not change the fit") and
stays the owner's open gate. The mine's row after C5's fix 4:
`DRY weapon=mine drained=ammo slot=3 dry_reason="ammo"` — byte-identical to C2's pre-fix
line, so the fixture edit is a no-op measurement (§6.2).

## 5. C3's decay, re-measured

### 5.1 The two retune numbers

| case | v_release | t10 before → after | carry before → after |
|---|---|---|---|
| `shipped_base` (Vanguard, the launch fit) | 406.600 | **1.890 → 0.945 s** | **430.32 → 216.85 u** (`dist10` 213.90) |
| `fighter_base` | 427.500 | 1.512 → 0.756 | 362.67 → 183.13 |
| `shipped_afterburner` | 650.560 | 3.024 → 1.512 | 1098.36 → 551.90 |
| `shipped_afterburner_burn_lit` (control) | 650.560 | 3.024 → 1.512 | 1098.36 → 551.90 (identical, sample for sample) |

`t10` is exactly `0.9 × coast_time` in both directions (`1.050 × 0.9 = 0.945`), and the
resolved coast time is `§13 row × 1.05` (the launched `h_plate_light` penalty):
`[C3] config … coast_time=1.050 damp_1_over_coast=0.952381 coast_rate=387.238`. The
burn-held control being identical to the burn case confirms C3's mechanism claim (at zero
throttle `desired_speed = 0` whatever `_max_speed()` is) — verified in the same run.

### 5.2 Nothing else moved

C3's published curve table (§3) is **line for line its own log** — I diffed the 22
`curve case=shipped_base` samples C3 printed against
`.agents/gen/combat_repair_c3_probe.txt` and they match exactly (406.600 / 387.238 /
… / 0.000, step `19.3618 u/s per 0.1 s`), as do the 35-line afterburner curve's sampled
points. `diff` of the two C3 logs differs **only** in `config` (8), `curve` (160),
`derived` (8), `result` (8) and `accel` (104) lines — every one explained by the halved
coast column. The `legacy` lines (`no_DRAG_no_ACCELERATION_in_tree=true`) are unchanged, and I confirmed
independently that `DRAG`/`ACCELERATION` exist nowhere in `vajb-orbit/` (`grep -rn` finds
only the historical `IMPLEMENTATION_PLAN.md:410` line and the probe's own prose) — so the
brief's premise for ruling 2 was stale and C3 was right to refute it.

### 5.3 The seven derived rows, and the 108 u discrepancy

I re-derived every class row from §13 myself, with `resolved = row × 1.05`,
`v_release = max_speed × 0.95`, `t10 = 0.9 × resolved` and
`carry = 0.5 × v_release × resolved`: Miner 3.213→1.607 / 573.16→286.58, Trader
2.457→1.229 / 496.66→248.33, Corvette 1.701→0.851 / 444.39→222.19, Hauler 4.914→2.457 /
759.90→379.95, Gunship 3.591→1.795 / 682.29→341.14, Frigate 3.213→1.607 / 649.47→324.74,
Destroyer 5.292→2.646 / 879.79→439.90 — **all of C5's §3 table is arithmetically sound**,
and the two probe-flown rows are the probe's own measurements. The carry ratio is
`216.85/430.32 = 0.5039` rather than 0.5 because the *absolute* residual over the run's own
`derived` ideal is the same in both runs (`430.32 − 426.93 = 3.39 u` before,
`216.85 − 213.47 = 3.38 u` after), so the percentage doubles as the base halves; each run's
`derived` line confirms the ideal halving. Ruling 3's "≈ 108 u" was a ×0.25 reading;
measured 216.85 u. **No tuning was bent toward the wrong number** — the ×0.50 ruling is
what shipped.

### 5.4 The accelerate legs

`[C3] phase` lines (`t_accel_total`) are **identical** pre/post (2.533 / 2.100 / 4.050 /
4.050) and the derived rates are identical (161.349 / 203.571), so the owner's complaint
("released and it still goes forward") moved without lengthening the spin-up. Done:
104 `accel` samples differ by at most **0.002 u/s** (L44 — C5's "the same to 1 ulp"
overstates it; the conclusion stands).

## 6. The three test-side updates, judged

### 6.1 `tests/test_engine2_cleaving.gd:113` — the pin that encoded the bug

**Before** (HEAD, `git show HEAD:vajb-orbit/tests/test_engine2_cleaving.gd`) the suite
asserted, inside `test_rock_is_a_heavy_damped_rigid_body`:

```gdscript
assert_eq(body.collision_mask, 0, "rocks mask nothing (the ship masks them)")
```

and it **passed on the pre-fix tree** (`.agents/gen/c2_gate_after.log`, 15:20,
`passed=229 failed=0`, `[PASS] test_engine2_cleaving.gd.test_rock_is_a_heavy_damped_rigid_body`).
What it measured was the literal `0`, with a rationale that stated half the engine rule
("the ship masks them" is true — `HullBody` is layer 2/mask 1) as if it were the whole
rule. C1's measurement shows the other half is what the bug was: with mask 0 the pair is
**detected** (`contact=YES`, `contact_count=1`) but **never solved** with the rock's mass
(`inv_mass_rock` forced to 0), so the rock keeps `0.000 u/s` while the ship's shield still
pays. The old pin therefore froze the defect as contract — and it is the same line that
`git diff` shows going red the moment the owner ruled the mask to the hull layer.

**After** it asserts the contract instead:

```gdscript
assert_eq(body.collision_mask, AsteroidScript.COLLISION_MASK, "the rock masks the hull layer")
assert_eq(AsteroidScript.COLLISION_MASK & AsteroidScript.COLLISION_LAYER, 0,
    "and nothing else: two rocks are both layer 1, so rocks do not collide with rocks")
```

**Why this is a correction and not a hidden failure — four independent checks.**

1. **The failure was created by the sanctioned fix, and there was no other.** The 15:20
   log is green at 229 with the old pin; after C5's edits that one assertion is the only
   red C5 saw. Nothing else was edited to accommodate anything (I diffed the whole
   `vajb-orbit/tests/` tree: **one file changed**, `test_engine2_cleaving.gd`, +11/−1).
2. **The new pin has teeth against the old value.** My probe
   (`godot --headless --path vajb-orbit res://tests/probe_c6_pins.tscn --quit-after 600`)
   prints the discriminating table:

   ```text
   [C6-PIN] scene player_ship.tscn HullBody layer=2 mask=1
   [C6-PIN] class Asteroid.COLLISION_LAYER=1 COLLISION_MASK=2
   [C6-PIN] shipped rock after setup: layer=1 mask=2 units=100
   [C6-PIN] mask=0 old_pin(mask==0)=true  new_pin(mask==2)=false rocks_apart=true rock_in_solve=false hull_in_solve=true
   [C6-PIN] mask=1 old_pin(mask==0)=false new_pin(mask==2)=false rocks_apart=true rock_in_solve=false hull_in_solve=true
   [C6-PIN] mask=2 old_pin(mask==0)=false new_pin(mask==2)=true  rocks_apart=true rock_in_solve=true  hull_in_solve=true
   ```

   `mask=0` (the pre-fix value) **fails** the new assertion while the rock's mass stays out
   of the solve; `mask=1` (a non-zero wrong layer) fails both; only `mask=2` passes and
   opens the pair. A regression to mask 0 goes red.
3. **Nothing the old message protected was dropped.** `rocks_apart=true` for all three
   candidates, and the suite now asserts it explicitly
   (`COLLISION_MASK & COLLISION_LAYER == 0`), so "rocks do not collide with each other"
   is still pinned — as a property rather than as the value `0`.
4. **The contract authority is CONTRACTS §4**, not the brief: the hull's call site
   `player_ship.gd:478-479` "offer[s] the peer's half to `apply_collision_damage(amount)`
   when the peer has it", and §4 pins the hull body at layer 2/mask 1 with mass-scaled
   physics. A peer whose mass cannot enter the solve cannot honour that pin. The stronger
   version of the same pin lives in the new gate suite
   (`test_combat_repair_c5.gd:101-139`), which reads `HullBody`'s layer **off the scene**
   and asserts `COLLISION_MASK == hull_layer`, both directions of `collides_with`, and the
   rocks-apart property — i.e. the value 2 cannot drift from `player_ship.tscn`.

**Verdict: a legitimate correction of a pin that encoded the bug.** Recorded, not silently
relaxed: the replacement carries a comment naming C1, and the wave's report discloses it
(C5 §6 item 3).

### 6.2 `tests/probe_c1_ram.gd:278-284` — the fixture's 8 → 100 units

Legitimate. `Asteroid.setup` uses `units` for `yield_units`, `work` and `_bore_ore` only —
never for mass, look, damp or radius (the logs show the rock at `mass=560.0 damp=3.710
radius=42.00` both before and after), so the change cannot move any motion number. It is
also **necessary**: with the new sink, a 450 u/s ram credits 18.618 work, and
`Asteroid._crack()` emits `cracked` then `queue_free()`s, so an 8-unit fixture would
delete the very rock the post-contact trace measures. The crack path did not lose
coverage — it moved to a gate test (`test_a_ram_reaches_the_crack_path_the_guns_use`,
8-unit rock, `yield 0`, `cracked` once). Side effect disclosed and visible in the logs:
the pool line reads `yield 100 -> 82` where C1's read `8 -> 8`.

### 6.3 `tests/probe_c2_weapons.gd:738` — the dry matrix keyed on the row's `instant` flag

Legitimate, and the new key is the *real* selector, not a convenient proxy: `weapons.gd:380`
is `if bool(row.get(&"instant", false)): _fire_beam(…)` else `_fire_projectile(…)`, so the
flag is exactly what decides which resource a family spends. The old key
(`interval_of(id) <= 0.0`) agreed with it for the five v1 families until fix 4, and would
then have emptied the mine's **Energy** (which it does not spend) — a fixture bug, not a
weakening. **Measured effect: none.** The mine's dry lines are byte-identical pre/post
(`DRY weapon=mine drained=ammo slot=3 dry_reason="ammo"`), and my full-log diff against
C2's own log shows exactly the six lines C5 declared: the mine's `interval`, the NPC's
`shield_up`, the rock's `mask`, the shields-up plasma CASE, the SEAM line and the
launch-fit plasma row.

## 7. Pinned signatures vs CONTRACTS §4 and §8.2

Method: diff the *definitions* the wave touched, not the prose. The complete set of removed
lines across the wave's game diff is:

```sh
git diff -U0 -- vajb-orbit/game/ | grep -E "^-" | grep -vE "^---"
```

→ six comment lines, `collision_mask = 0`, nine `&"coast_time": …` rows, `return
KINETIC_INTERVAL` (17 removed lines in total). The complete set of added definitions:

```text
+const COLLISION_MASK := 2
+const WeaponsScript := preload("res://game/weapons.gd")
+func apply_collision_damage(amount: float) -> void
+func shield_up() -> bool
```

**No pinned signature was renamed, retyped, reordered or removed.**

| Pin | Status |
|---|---|
| §4 `PlayerShip` (root, group, `setup`/`set_move_target`/`cancel_orders`/`warp_available`/`damage_taken` + the four additive seams) | `player_ship.gd`/`.tscn` are **not in the wave's diff at all** — untouched |
| §4 body pin: layer 2 / mask 1 hull, mass-scaled thrust/brake/coast, `linear_damp = 1/coast_time` | holds; the rock's new mask makes the `collides_with` half of §4's two-way contact reachable |
| §4 "offer the peer's half to `apply_collision_damage(amount)` when the peer has it" | **now satisfied by the rock** (`asteroid.gd:238`, same name/arity as `NpcShip.apply_collision_damage` at `npc_ship.gd:338`); the player's own half unchanged (`−186.179`, measured) |
| §4 "…all derived from §13, nothing retuned" | **drift (MED-2)**: the coast column *is* retuned, by owner ruling, pending §13's tick |
| §5 `Asteroid` API (`setup`, `apply_work`, `size_class`, `cleaves`, `eject_velocity`, `world_radius`, `signal cracked`) | unchanged; `apply_collision_damage` is additive |
| §5 body pin "layer 1 / mask 0 (so rocks do not collide with each other)" | **drift (MED-2)**: shipped is `layer 1 / mask 2`, with `mask & layer == 0` still keeping rocks apart |
| §8.2 `WeaponComponent` statics incl. `static func interval_of(weapon_id: StringName) -> float` | signature unchanged; `KINETIC_INTERVAL` still `0.6`; `GUN_CHIP_RATE` still `0.10` |
| §8.2 unpinned values (`SHOT_MASS`, `HIT_RADIUS`, `KINETIC_INTERVAL` 0.6, mine alpha 180) | all unchanged; no later wave flagged one |
| §8.2 standing ruling R6 (the mine's alpha and the *kinetics'* 0.6 cadence are the spec's own) | **honoured**: the change gates the fallback on `family_of == &"kinetic"`, so the kinetics keep 0.6 and the deployable stops borrowing it — the code now matches R6's wording |
| §8.2 `NpcShip` method list | `shield_up()` is an **addition** to a pinned class (mirrors `player_ship.gd:258`, which §8.2 already pins); the list needs the line (MED-2). No other method moved |
| §8.2 `Projectile` / `Damage` pins | untouched (`projectile.gd`, `damage.gd`, `impact.gd` are not in the diff) |

## 8. §13: what moved, what did not, and the constants

**The doc is untouched** (`git diff --stat -- docs/` → empty), so §13 still carries the
pre-retune coast column — deliberate, owner-locked.

**The one §13-sourced column that moved:** `coast_time`, all nine rows, exactly ×0.50
(`1.6→0.8`, `2.0→1.0`, `3.4→1.7`, `2.6→1.3`, `1.8→0.9`, `5.2→2.6`, `3.8→1.9`, `3.4→1.7`,
`5.6→2.8`). This is deviation 1, sanctioned by ruling 2 (brief §"Owner rulings this wave
executes") and specified by second-round ruling 3 — and it is the *whole* of what moved.

**The second deviation the brief sanctioned — the damage→work constant — does not exist,
by the owner's own re-scope.** Verified:

```sh
$ grep -rn "GUN_CHIP_RATE" vajb-orbit/ --include=*.gd | grep -v tests/
vajb-orbit/game/weapons.gd:137:const GUN_CHIP_RATE := 0.10
vajb-orbit/game/weapons.gd:479:		&"chip": GUN_CHIP_RATE,
vajb-orbit/game/weapons.gd:499:			hull_body.call(&"apply_work", amount * GUN_CHIP_RATE)
vajb-orbit/game/asteroid.gd:73:## read from its single owner `WeaponComponent.GUN_CHIP_RATE` rather than re-declared:
vajb-orbit/game/asteroid.gd:239:	apply_work(amount * WeaponsScript.GUN_CHIP_RATE)
```

One definition (`weapons.gd:137`), three consumers (`:479` into `Projectile.configure`,
`:499` the beam, `asteroid.gd:239` the new ram), two of them pre-existing. `git diff` over
`vajb-orbit/game/` adds exactly **one** numeric constant — `COLLISION_MASK := 2`, a layer
bit, not a feel number, and asserted equal to the hull's layer read off the scene. The
ram's chain is therefore `damage × GUN_CHIP_RATE → work`, `work / WORK_PER_UNIT → units`,
each conversion single-owner and pre-existing.

**Every other §13 row I could find in code reads its spec value and is unchanged**
(grepped, and the diff proves nothing in those files moved): `COLLISION_FACTOR 2.0e-5`,
`COLLISION_MIN_DV 40.0`, `KNOCKBACK_FRACTION 0.40`, `EXPLOSION_P0 4000`, `EXPLOSION_WINDOW
0.2`, `MINE_CYCLE 1.2`, `MINE_LASER_RANGE 220.0`, `BRAKE_MULT 1.8`, `SLOW_DOWN_RADIUS 240`,
`ARRIVE_RADIUS 40`, `BOOST_FUEL 3.0`, `DASH_FUEL 25.0`, `LOCK_CHANNEL 1.2`,
`PASSIVE_RADIUS 1500`, `CHAFF_WINDOW 3.0`, `CHAFF_GHOSTS 3`, `FLARE_LURE 450`,
`AGGRO_COOLDOWN 5.0`, `WARP_CHANNEL 3.0`, `FUEL_PER_ENERGY 0.10`, `FUEL_CELL_UNITS 40`,
`REGEN_QUIET 4.0`, `WORK_PER_UNIT 1.0`, `ROCK_MASS_MULT 4.0`, `LINEAR_DAMP 3.71`
(`asteroid.gd:45,110,123`, `damage.gd:39`, `game.gd:93,98,99`, `impact.gd:25,26,31,32,33`,
`mining_laser.gd:29,30`, `npc_brain.gd:50`, `player_ship.gd:91,92,93,102,103`,
`player_state.gd:52,61`, `weapons.gd:137,143,154,155,156`).

**Blast radius of the mask change, closed:** the only bodies on layer 2 are
`player_ship.tscn`'s `HullBody` and NPC hulls built at runtime (`npc_ship.gd:204`); the
station is an `Area2D` dock zone (`sector.gd:419`), projectiles are layer 4. So the rock's
new mask can only pair with ships — no station, pickup or shot behaviour changes.
(Unmeasured corollary, INFO: an NPC-vs-rock ram now pushes the rock and chips it through
the same method; identical call site, not probe-measured.)

## 9. Findings

### MED-1 — C5's file set was exceeded, and no record of the widening exists

Evidence:

```sh
$ grep -c "npc_ship\|ship_fit" .agents/gen/combat_repair_wave_prompts.md
0
$ git diff --stat -- vajb-orbit/game/
 vajb-orbit/game/asteroid.gd | 38 ++++++++++++++++++++++++++++++++------
 vajb-orbit/game/npc_ship.gd | 12 ++++++++++++
 vajb-orbit/game/ship_fit.gd | 30 +++++++++++++++++++++---------
 vajb-orbit/game/weapons.gd  | 13 +++++++++++--
 4 files changed, 76 insertions(+), 17 deletions(-)
$ grep -n "VAJB_WORKER_FILES" .agents/gen/combat_repair_wave_task.md | cut -c1-110
51:| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
65:- `VAJB_WORKER_FILES` exactly as tabled; the PreToolUse hook denies writes outside it
   (the C5 row itself, line 57, names asteroid.gd, weapons.gd, projectile.gd,
    player_ship.gd, impact.gd and tests/ -- neither npc_ship.gd nor ship_fit.gd)
$ ls --time-style=+%H:%M:%S vajb-orbit/game/{asteroid,npc_ship,ship_fit,weapons}.gd
15:23:53 asteroid.gd   15:24:46 npc_ship.gd   15:24:54 weapons.gd   15:30:21 ship_fit.gd
```

`npc_ship.gd` and `ship_fit.gd` are both **outside** the tabled and dispatched set and
both are in the shipped diff; their mtimes sit inside C5's single session window, so this
is not another lane's edit. I also searched the whole workspace for a recorded dispatch
with a wider set (`grep -rln "VAJB_WORKER_FILES" --include="*.md" --include="*.sh" …`):
this wave has **no** `_dispatch/<wave>_<id>.sh` script of the kind the slice waves used
(`ls .agents/gen/_archive/_dispatch/ | grep -i "combat\|repair\|c5"` → nothing), so the
prompts file is the only dispatch record and it names the narrow set.

Both files are required by the owner's **second-round rulings**, which postdate the brief
(14:56) and the prompts file (14:57) — ruling 4 names "plasma's shield bonus (C2-F1)" and
ruling 3 names the `ship_fit.gd` coast rows. C5's report discloses both edits (§4's
reversal table and §7's file list), and their content is correct and test-pinned. What is
missing is the **record**: `.agents/gen/dispatch_coder.md` says "never widen a set beyond
the brief's table", and the hook denies outside writes, so either a widened env was used
for the ruling-time re-dispatch and never written down, or the guard did not fire for that
session. Cure (one pass, owned by C7 or the close-out): add the two files to C5's row in
the brief and to the C5 dispatch block with the ruling that required them, or record the
widened env; either way the close-out must read those two touched files as ruling-scoped,
not unexplained.

### MED-2 — `docs/CONTRACTS.md` contradicted the shipped code in four places — **remediated in flight, residual is a verification**

**State at the start of this review** (measured: `git diff --stat -- docs/` → empty at
15:43): the contract was stale in four places.

| Doc (then) | Read | Should read |
|---|---|---|
| `§5:162` | "layer 1 / mask 0 (so rocks do not collide with each other)" | "layer 1 **/ mask 2 = the hull layer**"; `mask & layer == 0` is what keeps rocks apart |
| `§9:639` | "Expected: `[SUMMARY] passed=226 failed=0`" | the measured **236** with the wave's two suites broken out |
| `§4:114` | "…all derived from §13, **nothing retuned**" | the owner's 2026-09-21 `coast_time` ×0.50 retune, §13's tick pending |
| `§8.2:516` | `NpcShip` method list without `shield_up()` | add `shield_up() -> bool  # §4.1's shield reads` |

```sh
$ grep -n "mask 0\|passed=226\|nothing retuned" docs/CONTRACTS.md     # at 15:43
114:`angular_damp = 1 / turn_spinup` — all derived from §13, nothing retuned.
162:`gravity_scale` 0, `can_sleep = false`, layer 1 / mask 0 (so rocks do not collide
639:Expected: `[SUMMARY] passed=226 failed=0` (re-measured on this host 2026-09-21),
```

**State while this report was being written** (15:46–15:47): a CONTRACTS pass landed
**in parallel** — its v1.2 changelog entry credits worker **C7** — and it addresses all
four items: §4 now carries the retune exception with the probe's before/after numbers and
"the same column also halves every NPC hull's coast" (i.e. L39's disclosure), §5 now reads
**layer 1 / mask 2** with C1's measured defect and *C6's re-run* figures, §8.2's `NpcShip`
block gains `shield_up()`, and §9 reads **236** with a per-suite list attributed to this
review. I cross-checked that list against my own gate log, normalised for the `test_`
prefix: **20 suites, sum 236, no per-suite mismatch** (`combat_repair_c5 7`,
`engine_c3_flight_decay 3`, and all 18 pre-existing counts, including `p1_clock_log 4` —
which also clears C3's stale "5", L42).

**Residual for the close-out (no code fixer pass needed for this item):** confirm the pass
is complete and self-consistent (it was still being written at 15:47 — mtimestamps
15:46:48 → 15:47:03), and that no *other* §4/§5/§9/§8.2 line went stale in the same edit.
Tiered MED because at review start a lane coding against §5's text would have rebuilt the
defect C1 measured; if the pass is complete when the wave closes, this item is closed by
verification alone.

### LOW — all ten appended to `.agents/gen/LOW_BACKLOG.md` as L38–L47

| Tier | Item | Repro / raw output |
|---|---|---|
| LOW | **L38** `game/asteroid.gd:236-237`'s new doc quotes C1's *pre-retune* `73.351 u/s / 21.056 u`; the same scenario on the shipped tree reads `72.821 / 20.323` | `grep -n "73.351" vajb-orbit/game/asteroid.gd`; `grep "S1 SHIPPED rock:" .agents/gen/c6/c1_probe_c6.log` |
| LOW | **L39** `game/ship_fit.gd:151`'s "no other file reads this column" is false as written: `coast_time` reaches **every hull** through `ShipStats` (`npc_ship.gd:695-709`, `player_ship.gd:562-583`), so the retune also halves NPC coast and doubles NPC damp — a playtest-visible consequence C5 §3 does not disclose | `grep -rn "coast_time" vajb-orbit/game/*.gd` |
| LOW | **L40** `game/asteroid.gd:112-121`'s `LINEAR_DAMP` derivation still uses the **elastic** hand-off (`2·m·v/(m+m) ≈ 409 u/s`); measured, the solver gives the inelastic common velocity (`73.351`, now `72.821`) — the constant stays conservative, the prose does not | `grep "S6 FIXED rock:" .agents/gen/combat_repair_c5_c1_after.log`; C1 report §6.1 |
| LOW | **L41** `tests/probe_c1_ram.gd` S5 COAST now prints `NO CONTACT in 300 frames` — the *undriven* ram (C1's "the owner's own ram") measures nothing on the shipped tree. One fixture line (approach gap 400 → ~200 u) restores it; the driven S1 still covers the contract and the probe's teeth are intact | `grep "S5 COAST" .agents/gen/c6/c1_probe_c6.log` |
| LOW | **L42** C3 report §8's per-suite table lists `p1_clock_log` **5** (the suite has 4) and omits its own new suite's 3; the table sums to 227 against the stated 229 | `grep -c "^func test_" vajb-orbit/tests/test_p1_clock_log.gd` → 4; `grep -c "p1_clock_log" .agents/gen/c6/gate_c6.log` |
| LOW | **L43** C3 report §2/§7 quote the Vanguard's accelerate leg as **2.550 s**; its own log reads `t_accel_total=2.533` | `grep "phase case=shipped_base" .agents/gen/combat_repair_c3_probe.txt` |
| LOW | **L44** C5 §3's "the `accel` samples are the same to **1 ulp**" overstates it: 104 samples differ by up to **0.002 u/s** (`t_accel_total` and the derived rates are identical, so the conclusion holds) | `diff <(grep "accel case=" .agents/gen/combat_repair_c3_probe.txt) <(grep "accel case=" .agents/gen/c6/c3_probe_c6.log)` |
| LOW | **L45** C5 §5's "LSP diagnostics are clean" is **not verifiable in this session**: `lsp_diagnostics` returns zero findings for every file, including `weapons.gd`, which the `--debug` ledger shows carries 19 warnings — so silence here is not evidence. The reliable ledger (CONTRACTS §9, fifth form) attributes no warning to any file this wave added or edited | `lsp_diagnostics vajb-orbit/game/weapons.gd` → empty; `grep -c "weapons.gd" .agents/gen/c6/c1_probe_c6_debug.log` → 19 |

Also appended in the same block, below the table above: **L46** (C1's "201 MB peak RSS"
does not reproduce — `/usr/bin/time -v` measures 144 364 kB and 22.7 s for the same
command) and **L47** (the wave's dispatch blocks cite CONTRACTS sections but inline none of
§4/§8.2, so enforcement layer 1 "injection, not reading" was not exercised; my §7 audit
had to stand in for it).

### Observations that are not findings

- **C2-F3 (the launch fit) is still open by instruction** — the panel promises five weapons
  and 1500 rounds, the launch installs `[w_laser]` and mounts no mining laser. Second-round
  ruling 1 keeps it as the owner's playtest gate. Nothing in this wave touched it.
- **The `Damage.apply(rock, …)` / `_deliver(rock, …)` seam is still a silent no-op** — by
  design (second-round ruling 2's re-scope) and unreachable from any shipped beam or
  projectile path (C2-F2, re-measured). The mine remains the one family that does nothing
  to a rock, which §8.2's mine row requires.
- **The profile was written during my session** (`~/.local/share/godot/app_userdata/Vajb
  Orbit/profile.cfg`, mtime 15:34:36, `market.last_band` restamped and `demand`/`trend`
  populated) — that is backlog **L18**'s known station-boot-gate write reproducing under
  the gate, not a probe leak: no wave probe repoints `save_path` (L17 check passes).
- **The editor is open and the tree was not frozen** during my review (the theme lane's
  `build_theme.gd`/`vajb_theme.tres` edit landed after C5's gate run), which is why two
  `ui_slot_layout` print lines differ between the two gate logs while the count and both
  PASS rows agree.

## 10. What I could not verify (boundaries)

- **The pre-fix gate at 226**: the brief's baseline is quoted, and I verified the arithmetic
  from the 229 log C1/C2 measured after C3's suite landed (`236 − 7 = 229`, and the 15:20
  log is green), but I did not rebuild the pre-C3 tree.
- **C5's own session environment**: whether its `VAJB_WORKER_FILES` was widened at
  re-dispatch cannot be read out of the workspace; only the missing record is provable
  (MED-1).
- **The NPC-vs-rock ram** now pushes and chips the rock through the same method; the call
  site is identical (`npc_ship.gd:523-524`) but no probe measures it, and C5 says so.
- **Live feel**: nothing here says the retuned 216.85 u carry *feels* right; that is the
  owner's playtest, and the §13 tick plus the "≈108 u" correction are theirs.
- **The CONTRACTS pass is moving under this report.** MED-2's corrections landed at
  15:46–15:47 (a C7 v1.2 entry), i.e. *after* I measured the stale lines and *while* I was
  writing; I quoted both states rather than one. Anything a reader finds in
  `docs/CONTRACTS.md` now should be checked against the §7 table above (the code side of
  the contract audit is stable; only the prose moved).

## 11. Files this review created

- `vajb-orbit/tests/probe_c6_pins.gd`, `vajb-orbit/tests/probe_c6_pins.tscn` — the pin
  probe (§6.1), read-only, self-quitting, no game file touched.
- `.agents/gen/c6/` — `gate_c6.log`, `gate_c6_after_probe.log` (the same run re-measured
  with the probe in the tree), `c1_probe_c6.log`, `c1_probe_c6_run2.log`,
  `c1_probe_c6_debug.log`, `c1_rss.log`, `c2_probe_c6.log`, `c2_probe_paced_c6.log`,
  `c3_probe_c6.log`, `c3_probe_c6_debug.log`, `c6_pins_probe.log`.
- `.agents/gen/LOW_BACKLOG.md` — L38–L47 appended (this wave's LOW block).

**Nothing was fixed.** No shipping file, doc, scene, asset, theme or `project.godot` was
edited by this worker; the only writes are the two probe files above, the logs, the
backlog block and this report.
