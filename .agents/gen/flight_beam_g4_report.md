# G4 — reviewer report: wave **flight feel & beam polish**

Reviewer: **G4** (mandatory). Wave law: `.agents/gen/flight_beam_wave_task.md`; evidence
round: `.agents/gen/owner_playtest_findings_20260921.md` (third round, W2/W3/W4/W5/W6).
Reports reviewed: `flight_beam_g1_report.md`, `flight_beam_g2_report.md`,
`flight_beam_g3_report.md`.

**Verdict.** The wave is **accepted with two MED and five LOW**. No HIGH. Every behaviour
the wave claims I re-measured from outside the workers' own suites, on both sides of the
change (the wave's 11 modified files stashed back to `HEAD` for the A/B), and every claim
held. The gate is **294 passed / 0 failed**, measured twice by me; the `SCRIPT ERROR` the
owner's console shows in that green run is **pre-existing** (`tests/test_weapon_fx_f4.gd:176`,
byte-identical on both sides) and tiers LOW. The one thing I cannot clear is documentation:
the wave's four behaviours have no owning-doc record and three shipped docs now contradict
the code (MED-1).

Nothing was fixed by this pass. Every command below is re-runnable as written from
`/home/kamil-paluszkiewicz/VajbOrbit`.

---

## 1. Method, and the byte-identical re-runs

Host Linux, `~/.local/bin/godot` (4.7.2.stable.official.ed1daf0bf), project `vajb-orbit/`.
The wave's own probes were re-run unmodified; each is compared against the worker's
evidence log:

| Probe (command) | My result | vs the worker's log |
|---|---|---|
| `godot --headless --path vajb-orbit res://tests/probe_g1_flight_feel.tscn --fixed-fps 60 --quit-after 20000` | `[G1] done failures=0`, exit 0 | **byte-identical** to `.agents/gen/_g1/probe_after.log` after normalising the one `wall_ms` stamp (`diff` clean) |
| `godot --headless --debug --path vajb-orbit res://tests/probe_g1_lint.tscn --quit-after 600` | 1 `WARNING:` row, the minimap positive control | rows identical to `.agents/gen/_g1/lint_g1_after.log` |
| `godot --headless --debug --path vajb-orbit res://tests/probe_g2_lint.tscn --quit-after 600` | 1 `WARNING:` row (the control) | **byte-identical** to `.agents/gen/g2/lint_after.log` |
| `godot --headless --debug --path vajb-orbit res://tests/probe_g3_lint.tscn --quit-after 600` | 15 rows, none in G3's files | rows identical to `/tmp/g3_check.log` |
| `godot --headless --path vajb-orbit res://tests/probe_g3_shadow.tscn --quit-after 600` | `[G3] passed=25 failed=0`, exit 0 | identical to `/tmp/g3_static_final.log` |
| the two new suites: `…headless_runner.tscn --quit-after 600 -- --suite=test_flight_feel_g1` / `--suite=test_flight_beam_g2` | `passed=12 failed=0` / `passed=5 failed=0` | matches (12 + 5 = the wave's 17 tests) |

Two probes are mine (reviewer tooling, `tests/` is G4's file set), and both re-run
deterministically: `res://tests/probe_g4_lint.tscn` (the ledger over **every** file the
wave touched, §9) and `res://tests/probe_g4_beam.tscn` + `res://tests/probe_g4_beam_head.tscn`
(the beam measurements, §6–§8; the `_head` one deliberately reads only APIs that exist on
both sides so it is the A/B instrument).

**A/B harness.** For every "before" number below the wave's 11 modified tracked files were
stashed (`git stash push -m g4-head-abN -- <the 11 paths>`) and the tree restored with
`git stash pop`; the tree's integrity was verified by hashing the diff each time
(`git diff | md5sum` → `9c98d5c863d593478127aa9493198a9e` before and after every window,
`git stash list` empty at the end). No file was edited by this pass outside
`vajb-orbit/tests/` and `.agents/`.

---

## 2. The gate — the count I measured myself

```bash
godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
```

| run | result | raw |
|---|---|---|
| current tree, run 1 | `[SUMMARY] passed=294 failed=0`, `PASS=294 FAIL=0 SKIP=0`, exit 0 | `/tmp/g4_gate.log` |
| current tree, run 2 (repeat) | same, `12` of them `test_flight_feel_g1`, `5` of them `test_flight_beam_g2`, exit 0 | `/tmp/g4_gate2.log` |
| **HEAD A/B** (11 files stashed, the 2 new test suites moved aside) | **`[SUMMARY] passed=277 failed=0`**, exit 0 | `/tmp/g4_gate_head.log` |

The brief's baseline (`passed=277 failed=0`) is exact, and 277 + 12 + 5 = 294: the whole
growth is the wave's two new suites, nothing else moved, no test was weakened to hide a
failure. `git diff \| md5sum` after the gate runs is unchanged, so every run in this report
is a clean read.

---

## 3. The `SCRIPT ERROR` in the green gate — traced, A/B'd, tiered

**Where it comes from.** `tests/test_weapon_fx_f4.gd:176`, inside
`test_a_held_beam_reads_one_hit_per_contact_interval`, on a **live** tree and alone:

```bash
godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 600 -- --suite=test_weapon_fx_f4
```

```text
SCRIPT ERROR: Cannot call method 'call' on a previously freed instance.
          at: test_a_held_beam_reads_one_hit_per_contact_interval (res://tests/test_weapon_fx_f4.gd:176)
[SUMMARY] passed=6 failed=0
```

**The exact cause, at the exact line.** Line 175 calls `_clear()`, which frees **every**
child of the fixture root (`test_weapon_fx_f4.gd:474-476`: `for child in _root.get_children()` →
`child.free()`). The rig's `guns` node is a child of the stub hull, which is a child of
`_root`, so `guns` is freed there; line 176 then calls `guns.call(&"_hide_beam")` on the
freed instance. Nothing in the product is involved: the receiver is freed by the test's own
helper, and `_hide_beam` never runs.

**Pre-existing, proven by A/B** (not by trusting G1/G2/G3, who all claimed it):

```bash
git stash push -m g4-head-ab -- <the wave's 11 files>
godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200 > /tmp/g4_gate_head.log
git stash pop
```

* HEAD: `passed=277 failed=0` **and** the identical block:
  `SCRIPT ERROR: Cannot call method 'call' on a previously freed instance.` /
  `at: test_a_held_beam_reads_one_hit_per_contact_interval (res://tests/test_weapon_fx_f4.gd:176)`.
* The file itself is unmodified: `git diff HEAD -- vajb-orbit/tests/test_weapon_fx_f4.gd | wc -l` → `0`.

**Tier LOW** (logged as L61). It is loud but harmless: the test still passes and the exit
code is 0. Fix (one line, for whoever owns the file): move `guns.call(&"_hide_beam")` above
the `_clear()` on line 175 — or fetch the beam from the rig dictionary after `_clear()` is
made to spare the rig.

---

## 4. The turn curve, per class, before and after ×0.50, against §13

The probe re-derives all nine rows against the section 13 column quoted as a const. My
re-run (`/tmp/g4_probe_g1.log`, byte-identical to G1's):

```text
[G1] turn retune=x0.50 classes=9
[G1] turn hull=ship_fighter   before=3.400 after=1.700 after_deg_s=97.4 ratio=0.5000 spinup=0.40 t_90_pure=0.924
[G1] turn hull=ship_vanguard  before=3.000 after=1.500 after_deg_s=85.9 ratio=0.5000 spinup=0.50 t_90_pure=1.047
[G1] turn hull=ship_miner     before=2.000 after=1.000 after_deg_s=57.3 ratio=0.5000 spinup=1.00 t_90_pure=1.571
[G1] turn hull=ship_trader    before=2.400 after=1.200 after_deg_s=68.8 ratio=0.5000 spinup=0.70 t_90_pure=1.309
[G1] turn hull=ship_corvette  before=3.200 after=1.600 after_deg_s=91.7 ratio=0.5000 spinup=0.45 t_90_pure=0.982
[G1] turn hull=ship_freighter before=1.500 after=0.750 after_deg_s=43.0 ratio=0.5000 spinup=1.40 t_90_pure=2.094
[G1] turn hull=ship_gunship   before=1.900 after=0.950 after_deg_s=54.4 ratio=0.5000 spinup=1.00 t_90_pure=1.653
[G1] turn hull=ship_patrol    before=2.100 after=1.050 after_deg_s=60.2 ratio=0.5000 spinup=0.90 t_90_pure=1.496
[G1] turn hull=ship_destroyer before=1.600 after=0.800 after_deg_s=45.8 ratio=0.5000 spinup=1.20 t_90_pure=1.963
[G1] turn_curve classes=9 mismatched=0 retune=x0.50
```

I verified the "before" column is not a copy of the shipped value but **is** §13: I parsed
§13's handling table out of `docs/gameplay/18_engine_spec.md` and diffed it against
`HEAD`'s `ShipFit.HANDLING` and the shipped table, all six columns, all nine rows:

| hull | §13 class | max_speed | accel_time | coast_time | turn_rate | turn_spinup |
|---|---|---|---|---|---|---|
| ship_fighter | Fighter | 450 = 450 = 450 | 2.0 = 2.0 | 1.6 → 0.8 (×0.50, C wave) | **3.4 → 1.7** (×0.50) | 0.4 = 0.4 |
| ship_vanguard | Cutter | 428 = 428 | 2.4 = 2.4 | 2.0 → 1.0 | **3.0 → 1.5** | 0.5 = 0.5 |
| ship_miner | Miner | 338 = 338 | 4.0 = 4.0 | 3.4 → 1.7 | **2.0 → 1.0** | 1.0 = 1.0 |
| ship_trader | Trader | 383 = 383 | 3.0 = 3.0 | 2.6 → 1.3 | **2.4 → 1.2** | 0.7 = 0.7 |
| ship_corvette | Corvette | 495 = 495 | 2.2 = 2.2 | 1.8 → 0.9 | **3.2 → 1.6** | 0.45 = 0.45 |
| ship_freighter | Hauler | 293 = 293 | 6.0 = 6.0 | 5.2 → 2.6 | **1.5 → 0.75** | 1.4 = 1.4 |
| ship_gunship | Gunship | 360 = 360 | 4.4 = 4.4 | 3.8 → 1.9 | **1.9 → 0.95** | 1.0 = 1.0 |
| ship_patrol | Frigate | 383 = 383 | 4.0 = 4.0 | 3.4 → 1.7 | **2.1 → 1.05** | 0.9 = 0.9 |
| ship_destroyer | Destroyer | 315 = 315 | 6.4 = 6.4 | 5.6 → 2.8 | **1.6 → 0.8** | 1.2 = 1.2 |

`turn_rate` is the **only** column this wave moved, exactly ×0.50 on exactly the nine rows,
and `HEAD`'s value equals §13's in every row (the "before" column is the doc's own).
`docs/gameplay/18_engine_spec.md` is **not** in `git status` — the owner-locked §13 table is
untouched, so the owner's tick is still owed (MED-1).

Flight behaviour, from the same probe:
`[G1] result case=cursor_ship_vanguard t_reach=3.217 t_class_min=1.034 omega_peak=1.500 rate=1.500 ratio=1.000 arrived=true rate_ok=true bound_ok=true`
and the equal cases for the fighter (`omega_peak=1.700 rate=1.700 ratio=1.000`) and the
freighter (`0.750/0.750 ratio=1.000`) — the peak turn rate is the class rate to three
decimals, the class rate is a ceiling rather than an arrival time (the last degrees are
proportional, as §3.2 describes). Heading hold:
`[G1] result case=hold_ship_vanguard release_omega=0.414 t_omega_zero=0.150 spinup=0.525 heading_held=true spun_down=true error_at_stop=0.2417 stopped_short=true`,
`hold_ship_freighter … t_omega_zero=1.467 spinup=1.470 heading_held=true`,
`[G1] result case=hold_at_rest thrust_held=false cursor_off_bow=90.0deg heading_drift=0.00000000 speed=0.00000000 held=true`
→ released, nothing commands a turn and the nose stops dead (drift `0.0000000`).

---

## 5. The strafe — lateral response, and its derivation

**Derivation, read off the shipped code** (`game/player_ship.gd`):
`_command_velocity(throttle, lateral)` caps the stick vector at unit magnitude and scales it
by `_max_speed()` (`= _stats.max_speed × boost`); `_step_strafe` chases the lateral
component through the **same** `_thrust_axis` law the nose already used, at `_accel_rate()`
(`= _stats.max_speed / _stats.accel_time`, pre-existing, `player_ship.gd:710-713`). Both are
§13 rows reached through `ShipStats`; the axis is `_strafe_axis() = RIGHT.rotated(heading + PI/2)`.
`grep -rn "STRAFE_FRACTION" vajb-orbit/` → **no hits**: the one named value G1 proposed was
**not** added, as the brief requires.

Measured (probe, `--fixed-fps 60`; ceilings are the resolved rows — the launched
`h_plate_light` costs 5 % of speed and 5 % of the accel time):

| class | ceiling = `max_speed` | accel = `max_speed/accel_time` | derived t_90 (0.9 × accel_time) | measured t_90 | lateral peak | sideways travel | forward peak | forward travel | heading drift |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Vanguard | 406.600 | 161.349 | 2.268 s | **2.283 s** | 368.414 | 417.536 u | 0.000 | −0.000 u | 0.00000000 |
| Fighter | 427.500 | 203.571 | 1.890 s | **1.900 s** | 386.786 | 364.223 u | 0.000 | −0.000 u | 0.00000000 |
| Hauler | 278.350 | 44.183 | 5.670 s | **5.683 s** | 251.104 | 711.462 u | 0.000 | −0.000 u | 0.00000000 |

`right_is_right=true` in all three; the travel is 100 % lateral. W+D:
`[G1] result case=strafe_with_thrust speed_peak=406.600 ceiling=406.600 sqrt2_ceiling=575.019 speed_ok=true track_deg=45.03 track_ok=true heading_delta=0.000771 heading_ok=true`
— the diagonal is the class ceiling, not √2× it, so §3.4's `|v|/v_max` onset never leaves 1.0.
The strafe is thrust, so ruling 14's Emergency lock covers it
(`player_ship.gd:367-371`: `lateral := 0.0 if _thrust_locked() else strafe`) while the
cursor turn stays live; the code says so in the same block.

Also verified: `turn_left`/`turn_right` still have their reader
(`player_ship.gd:429-432`, the only reader in the project) and a deflected turn action wins
over the cursor (`_manual_desired_turn`), so a pad or a Controls-tab re-bind still turns.
`REBINDABLE_ACTIONS` 17 → 19 with **nothing dropped** (order note: LOW-1).

---

## 6. The beam's endpoint — several distances, plus a miss, on both sides

`probe_g4_beam_head.tscn` fires the public trigger (`set_firing` + `tick`) at a real
`StaticBody2D` rock on the rock layer, after two physics frames, so the whole `_fire_beam`
path runs (ray → resolution → draw). Aim 10 000 u, laser range 500 u.

| case | BEFORE (HEAD) | AFTER (wave) |
|---|---:|---:|
| rock at 480 u (r = 20) — shaft endpoint | **500.000** (through the rock) | **460.000** |
| what `_beam_target` resolves | 460.000 | 460.000 |
| miss, aim 300 u | 300.000 | 300.000 |

Raw, both sides:

```text
=== BEFORE (HEAD) ===
[G4-AB] rock d=480 r=20 shaft_endpoint=500.000 resolved_hit=460.000
[G4-AB] miss aim=300 shaft_endpoint=300.000
=== AFTER (wave in place) ===
[G4-AB] rock d=480 r=20 shaft_endpoint=460.000 resolved_hit=460.000
[G4-AB] miss aim=300 shaft_endpoint=300.000
```

So the shaft now stops on exactly the point its own ray resolved — the drawn line and the
damage site are one value — and the miss path is unchanged (`to = from + offset.normalized()
* reach`, with `reach = min(|offset|, range)`; those two lines are not in the diff).
`probe_g4_beam.tscn`, which adds two more distances, prints the same shape:

```text
[G4-BEAM] OK   hit d=120 endpoint=100.000 expected=100.000 resolved=100.000
[G4-BEAM] OK   hit d=250 endpoint=230.000 expected=230.000 resolved=230.000
[G4-BEAM] OK   hit d=480 endpoint=460.000 expected=460.000 resolved=460.000
[G4-BEAM] OK   miss (aim 10000) endpoint=500.000 reach=500.0
[G4-BEAM] OK   miss inside the range (aim 300) endpoint=300.000
```

(The stop is `d − r` because the ray meets the shape's surface, and a 120 u shot no longer
reaches past a rock that is only 120 u away: the old code drew 500 u through it.)

---

## 7. A rock chip — the cue and the burst, measured on both sides

Same instrument, rock at 200 u, one frame of held fire (0.05 s):

```text
=== BEFORE (HEAD) ===
[G4-AB] rock chip first frame: last_sfx=sfx_weapon_laser_03 fx_nodes_on_rock=0
=== AFTER (wave in place) ===
[G4-AB] rock chip first frame: last_sfx=sfx_mining_chip_01 fx_nodes_on_rock=1
```

* **Cue**: `AudioManager.last_sfx()` is S8's `sfx_mining_chip_01` — the same take
  `mining_laser.gd:47` names (asserted equal), and `cue_path()` resolves it (the file is on
  disk, 8 729 B; the `_04` variant really is the outlier at 213 931 B, confirming the
  documented "21 s" reason for not round-robining).
* **Burst**: one `AnimatedSprite2D` read from `fx_mining_beam.png`, 4 frames, 20 FPS,
  additive — FX_SPEC §1.6's read exactly.
* **The work is unchanged**: first frame `work=0.1500` = `30 dps × 0.05 s × 0.10`;
  over 1.25 s of held fire `work=3.7500` = `30 × 1.25 × 0.10`.
* **The cadence is the hull branch's own**: 1 read on contact, then one per
  `BEAM_HIT_INTERVAL` 0.25 s → `bursts=5` over 1.25 s (`1 + ⌊1.20/0.25⌋`).
* **Energy is the row's own**: 0.3000 per 0.05 s frame = the laser's 6 E/s.
* The chip block runs on the **shared guard** (`_beam_read_due`), so the hull read and the
  rock read cannot drift apart in cadence — F4's landed-shot assertion
  (`30 dps × 0.05 s = 1.5`) still passes in the gate.

**The sheet's four regions, re-derived independently** (Pillow, not the worker's log):
the master is 2048×2048 RGB; all four 500×500 boxes are inside it (the fourth ends exactly
at x = 2048); ink share per frame is **5.22 % / 2.43 % / 0.62 % / 0.06 %** — burst →
dissipating → fainter → nearly empty, i.e. the read order G2 claims, and the reason the
asset library's object detector records 3 objects rather than 4 (L52). The last frame being
almost empty is inherent to the sheet, not a wiring defect; it is the 0.05 s of the 0.2 s
burst that reads as a pop.

---

## 8. A held beam's fire feedback — cadence, signal, lifetime, no leak

```text
=== BEFORE (HEAD) ===
[G4-AB] held 1.00 s: flashes=1 spawns=1 first_spawn_frame=0 emissions=1
[G4-AB] released: flashes=1 emissions=1
=== AFTER (wave in place) ===
[G4-AB] held 1.00 s: flashes=6 spawns=6 first_spawn_frame=0 emissions=1
[G4-AB] released: flashes=6 emissions=1
```

```text
[G4-BEAM] flash cycle declared FLASH_SECONDS=0.2000 frames=4 fps=20.0
[G4-BEAM] held 2.00 s: flashes=10 at frames=[0, 10, 20, 30, 40, 50, 60, 70, 80, 90] emissions=1
[G4-BEAM] expected flashes=10 (1 opening + 9 replays in 1.98 s)
[G4-BEAM] OK   shot_fired stays one emission per hold
[G4-BEAM] OK   each replay lands one cycle later (frames=[0, 10, 20, 30, 40, 50, 60, 70, 80, 90])
[G4-BEAM] OK   a released trigger stops the feedback
[G4-BEAM] and emits nothing more
```

* The cycle is the flash sheet's own `4 / 20 = 0.2 s` (`FLASH_SECONDS` is asserted equal to
  `FLASH_FRAMES.size() / FLASH_FPS`, so it cannot drift into an invented number).
* The replay starts one full cycle after the opening flash and keeps pace for the whole hold
  (frames 0, 10, 20 … at 0.02 s steps = 0, 0.2, 0.4 …); release stops it dead.
* **`shot_fired` stays one emission per hold** — CONTRACTS §4's pinned signal is intact; only
  the look and the sound repeat. (This is the shape the brief asked for and FX_SPEC §1.2's
  "one-shot, no loop" leaves open; a genuine animation loop would contradict the spec.)

**Lifetime under the engine's own frames** (the leak a "loop" invites):

```text
[G4-BEAM] real frames 1.20 s held: spawns=5 max_live=1 last_live=0
[G4-BEAM] 0.67 s after release: live_flashes=0 beam_visible=false
```

With real physics frames the flash is freed by its own animation (FX_SPEC §7.3's
`animation_finished → queue_free`), so at most **one** flash is alive at a time and nothing
survives the release: the loop's lifetime is the trigger's, and it leaks nothing.
(`spawns` is a lower bound — it counts increases in the live count, so a spawn in the same
frame as a free is invisible to it; `max_live=1` and `live=0` afterwards are the load-bearing
numbers.)

---

## 9. The debug lint ledger — before and after, every file the wave touched

Instrument: `godot --headless --debug --path vajb-orbit res://tests/probe_g4_lint.tscn
--quit-after 900` (mine; every touched file plus the seven new ones in one run). Attribution
is by the engine's own `at: GDScript::reload (res://file:line)` column, not by marker block —
G3's correction is real and I reproduced its cause (a dependency compiles inside its
dependent's block: the before-run's raw count is 60 against 54 unique sites). Both runs are
healthy: **0 `Parser Error`, 0 `SCRIPT ERROR`**, the positive control fires (minimap 1) and
the negative control is silent (`world_clock`).

| file | before (HEAD) | after | group |
|---|---:|---:|---|
| `game/weapons.gd` | 23 | **0** | touched (G2) |
| `game/projectile.gd` | 6 | **0** | touched (G2) |
| `game/sector.gd` | 2 | **0** | touched (G3) |
| `ui/components/slot_button.gd` | 2 | **0** | touched (G3) |
| `ui/station/exchange_panel.gd` | 2 | **0** | touched (G3) |
| `ui/station/launch_panel.gd` | 1 | **0** | touched (G3) |
| `ui/station/shipyard_panel.gd` | 1 | **0** | touched (G3) |
| `game/player_ship.gd`, `game/ship_fit.gd`, `autoload/settings_manager.gd`, `tests/test_combat_repair_c5.gd` | 0 | 0 | touched (clean before and after) |
| `tests/probe_g3_shadow.gd` | 0 (did not exist) | **2** | **wave-new — added** |
| `tests/test_flight_beam_g2.gd` | 0 (did not exist) | **1** | **wave-new — added** |
| `game/asteroid.gd` | 3 | 3 | untouched, no owner |
| `game/npc_brain.gd` | 4 | 4 | untouched, no owner |
| `game/npc_registry.gd` | 3 | 3 | untouched, no owner |
| `game/npc_ship.gd` | 4 | 4 | untouched, no owner |
| `ui/hud/minimap.gd` (positive control) | 1 | 1 | control |
| **total unique sites** | **54** | **18** | |
| **total raw rows** | 60 | 18 | before's raw is inflated by dependency double-compiles |

Touched files: **37 sites → 0**. Untouched files: 15 → 15 (no worker owned them; §10 of G3's
report is right, and it is a scoping gap for the orchestrator). But the wave **added three
new sites of its own** in its new files:

```text
WARNING: The local function parameter "velocity" is shadowing an already-declared function at line 57 in the current class.
     at: GDScript::reload (res://tests/test_flight_beam_g2.gd:51)
WARNING: The local variable "owner" is shadowing an already-declared property in the base class "Node".
     at: GDScript::reload (res://tests/probe_g3_shadow.gd:134)
WARNING: The local variable "name" is shadowing an already-declared property in the base class "Node".
     at: GDScript::reload (res://tests/probe_g3_shadow.gd:139)
```

Reproduce: the command above, then group the `WARNING:` rows by their `at:` line.
`test_flight_beam_g2.gd:51` is `StubHull.apply_recoil(velocity, _mass)`, whose parameter
shadows the class's own `velocity()` at line 57; `probe_g3_shadow.gd:134/139` are the locals
`owner` and `name`. **Tier MED-2** (three mechanical renames, in files the wave owns, against
the sweep's own stated goal). They are invisible to the gate — see LOW-3.

---

## 10. Contract and balance diff

**The files the wave touched.** `git diff --name-only` gives exactly 10 product scripts plus
`tests/test_combat_repair_c5.gd` — the union of the three worker sets, no stray file: no
`assets/**`, no theme, no `addons/**`, and **`project.godot` is untouched** (it is not in
`git status`; the two strafe actions were already bound by the pre-wave commit
`c37fbe3 "Bind A and D to strafing before the flight changes land"` — measured in place:
`strafe_left` keycode 65 (A), `strafe_right` keycode 68 (D), `turn_left`/`turn_right` with
`"events": []`). The two modified docs in the tree (`docs/design/AUDIO_SPEC.md`,
`docs/design/FX_SPEC.md`) are the parallel feel lane's thruster/§4–§6 amendments, not a
worker's write.

**No value moved.** Structural, HEAD vs now:

* `WeaponScript.FAMILIES` — **byte-identical** (sha1 `f8d85cd5068f0d6946ebddcd24fd76a5c24237b2`
  on both sides). Ranges, dps, Energy draw, cadence/interval, burst cycle, speed, homing
  rate, arm/trigger and the shield rules are untouched. So are `FIRE_CUES` and
  `SHARED_PACK` (`IDENTICAL`), and every scalar: `GUN_CHIP_RATE 0.10`,
  `SHOT_MASS 1.0`, `KINETIC_INTERVAL 0.6`, `BEAM_HIT_INTERVAL 0.25`,
  `TARGET_MASK`, `BEAM_BED_CUE` — unchanged. The only new constants are `CHIP_CUE` (an
  existing shipped cue name) and `FLASH_SECONDS` (the flash sheet's own 4/20).
* `projectile.gd` — 24 constants, **none** moved; `IMPACT_CUES` identical; the `FEEDBACK`
  table gained exactly one row (`chip`), every pre-existing row byte-identical; its `world
  40.0`/`fps 20.0` match the existing `arc` row's own read (LOW-5).
* `ShipFit.HANDLING` — `turn_rate` is the only column that moved (§4 table); `max_speed`,
  `accel_time`, `coast_time`, `turn_spinup`, `hull_mass` and the key set are identical.
* `player_ship.gd` (12 consts), `settings_manager.gd` (16), `ship_fit.gd` (11), `sector.gd`
  (15), `launch_panel.gd` (35), `shipyard_panel.gd` (37) — **no constant moved**;
  `exchange_panel.gd` (62) moved only its two `preload` const names
  (`MineralCatalog`/`ComponentCatalog` → `…Script`), which still resolve to the same files
  (G3's probe re-run: `[G3] passed=25 failed=0`).
* **No symbol was renamed or removed anywhere**: a signature-set diff per file shows only
  additions — `weapons.gd` +3 (`_advance_fire_feedback`, `_beam_read_due`, `_play_chip_cue`),
  `projectile.gd` +1 (`spawn_chip_sparks`), `player_ship.gd` +11 (`_aim_point`, `_aim_turn`,
  `clear_aim_point`, `_command_velocity`, `_manual_desired_turn`, `_manual_strafe`,
  `set_aim_point`, `_step_strafe`, `_strafe_axis`, `_thrust_axis`, `_turn_toward`), and the
  other eight files identical. The pinned signals keep their parameter names
  (`shot_fired(weapon_id)`, `dry_fired(weapon_id)` — unchanged).
* `REBINDABLE_ACTIONS` 17 → 19, nothing dropped; the Controls tab iterates the list
  (`ui/screens/settings.gd:176,281`), so it renders the two new rows with no UI change, and
  the new actions' A/D defaults are captured/saved/reset by the existing
  `_capture_default_events`/`save_inputs`/`reset_all_inputs` loops (they iterate the same
  list), so a "reset inputs" cannot drop the strafe keys.
* `tests/test_combat_repair_c5.gd:288` — the one pre-existing assertion the ruling moved:
  `turn_rate` 3.0 → 1.5, with the ruling named inline. Every other column of the same test
  is still pinned, so the C-wave guard keeps its teeth.

**CONTRACTS §3.2 / §4.1 / §4.3 and §13.** `docs/CONTRACTS.md` has no numbered sub-sections
§3.2/§4.1/§4.3 (its §3 is ShipFit, §4 is PlayerShip, and the slice pins live in §8.1/§8.2),
so I read the brief's citation as *CONTRACTS §3/§4 (+ §8.2's pinned interfaces) crossed with
`18_engine_spec.md` §3.2 (inertia), §4.1 (families) and §4.3 (ammo)*. Against those:

* §3.2's inertia semantics are unchanged and still sourced from §13 through `ShipStats`
  (`_accel_rate`, `_coast_rate`, `_spin_rate`, `_angular_damp` untouched); the turn retune
  scales one table column the doc already routes through the class.
* §4/§4.1's family semantics, instant-family resolution, shield rules, ammo packs and the
  `shot_fired`/`dry_fired` signals: untouched (FAMILIES identical, signals unchanged).
* §4.3's ammo rule — only `_consume_ammo`'s parameter name moved; the slot resolution and
  `PlayerState.set_ammo` call are identical.
* §13 is **not** amended in the doc (owner-locked; MED-1) and `HEAD`'s code equals it
  exactly, so the retune is the only delta.
* The stale doc *text*: CONTRACTS §4 still pins `set_fitted(weapon_ids)` and §8.2 still pins
  `retarget(decoy)`, `feedback_row(name)`, `spawn_sheet(name)` — all four became parameters
  named `ids`, `lure`, `row_name`, `fx_name` during the warning sweep. GDScript has no named
  arguments, every caller is positional and the behaviour is unchanged, so this is stale
  prose, not a broken contract (MED-1 carries the fix).

---

## 11. Findings

### HIGH — none

Nothing in the wave blocks it: the gate is green and grown, every claimed behaviour
reproduces on my own instrument, and the balance freeze is byte-proven.

### MED-1 — the wave's four behaviours have no owning-doc record, and three docs now contradict the code

The wave changed the shipped control scheme (A/D strafe), the nose's steering law, the
`turn_rate` column and three beam behaviours, and the only records are code comments and the
workers' reports. The project's own rule is docs → code → tests, and its own review-wave
charter assigns `docs/CONTRACTS.md` to the review pass — but this brief forbade `docs/**` and
my file set (`vajb-orbit/tests/,vajb-orbit/tools/`) denies it, so the pass has **no owner**.

```bash
grep -n "A/D turn" docs/gameplay/18_engine_spec.md            # :67  — still says A/D turn
grep -n "WASD throttle/turn" docs/CONTRACTS.md               # :129 — still says WASD throttle/turn
sed -n '231p' docs/design/IMPLEMENTATION_PLAN.md             # `turn_left` (A) · `turn_right` (D)
grep -n "weapon_ids\|retarget(decoy)\|feedback_row(name)\|spawn_sheet(parent: Node, name" docs/CONTRACTS.md
```

The concrete deltas owed: `IMPLEMENTATION_PLAN.md:231`'s frozen input-map row
(`turn_left`(A)/`turn_right`(D) → `strafe_left`(A)/`strafe_right`(D)); `18_engine_spec.md:67`
and §11's "everything else stays" bullet; §13's turn column (the owner's tick — the
before/after table is §4 above); CONTRACTS §4's flight sentence and its four stale parameter
names; and one line in CONTRACTS §4 recording the ×0.50 turn retune the way the `coast_time`
retune is recorded (`CONTRACTS.md:114-124`).

**Disposition:** one fixer pass with `docs/CONTRACTS.md` (and, at the owner's discretion,
`IMPLEMENTATION_PLAN.md`) in its set; `18_engine_spec.md` §13/§3.1 stay the owner's tick.
If the owner prefers the tick path for all of it, demote this to the backlog — but then say
so explicitly, because as it stands no one owns it.

### MED-2 — the wave's own new files add three shadowing sites

`tests/test_flight_beam_g2.gd:51`, `tests/probe_g3_shadow.gd:134`, `tests/probe_g3_shadow.gd:139`
(§9). One rename each: `velocity` → `recoil_velocity`, `owner` → `owner_script`,
`name` → `constant_name`. Repro: `godot --headless --debug --path vajb-orbit
res://tests/probe_g4_lint.tscn --quit-after 900` and group by the `at:` lines.
The wave's whole point was to finish the sweep in the files it owns (`tests/` is in every
worker's set), so this is an unfinished corner rather than a new class of problem.
If the owner considers test-file warnings noise, demote to LOW-6 and move on.

### LOW (also appended to `.agents/gen/LOW_BACKLOG.md`)

| # | finding | repro | disposition |
|---|---|---|---|
| LOW-1 | `settings_manager.gd:34-36` says the two strafe actions are "Orders 18 and 19"; they are entries **5 and 6** of `REBINDABLE_ACTIONS` (inserted after `turn_left`/`turn_right`), so every later row shifts one place down the Controls tab. No functional impact (the UI iterates the list; rebind/save/reset all iterate the same list). | `python3 -c "print(open('vajb-orbit/autoload/settings_manager.gd').read().index('&\"strafe_left\"'))"`; `sed -n '34,44p' vajb-orbit/autoload/settings_manager.gd` | Comment/order only; either reword to "entries 5 and 6" or append the two entries at the end. |
| LOW-2 | `tests/test_weapon_fx_f4.gd:176` — `SCRIPT ERROR: Cannot call method 'call' on a previously freed instance` in the green gate: line 175's `_clear()` frees `guns`, line 176 calls it. **Pre-existing**, proven by the HEAD A/B (§3); the test still passes. | `godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 600 -- --suite=test_weapon_fx_f4` | Fix in the file's next owner: call `_hide_beam` before `_clear()`. |
| LOW-3 | G2 §4's "the gate (which treats GDScript warnings as errors)" is not true: the gate passes 294/0 while a loaded suite carries a shadowing warning, and warnings print only under `--debug`. Method claim only. | `grep -c "shadow" /tmp/g4_gate.log` → 0; the ledger run prints 18 rows | Reword: the ledger is the warning gate, the runner is not. |
| LOW-4 | The brief's and G2's "FX_SPEC line 138" anchor no longer resolves (the parallel FX_SPEC amendment inserted 19 lines above it). The sheet is named at **line 157**, inside **§1.6 "Mining beam"**, whose Timing row (line 116) is the text G2 quotes correctly. | `grep -n "fx_mining_beam" docs/design/FX_SPEC.md` → `157`; `sed -n '138p'` → blank | Cite §1.6/line 157 in future briefs; nothing to change in code. |
| LOW-5 | FX_SPEC §1.6 states no world size for the chip burst; the row's `world: 40.0` is the wiring's own, chosen to match the existing `arc` row's own 40 (both 4-frame, 20 FPS). Recorded in the row's doc comment. | `sed -n '245,262p' vajb-orbit/game/projectile.gd` | Fold into the next FX_SPEC pass with the other unstated rates (L59's list). |
| LOW-6 | FX_SPEC §1.6's chip-sparks burst is now wired for the **gun** beam only; `mining_laser.gd:166-174` (`_apply_cycle`) still plays S8's cue and draws nothing, so L52's other half stays open and the owner's "mining beam contact feedback" is half-complete. Out of this wave's scope (the owner's W3 named `weapons.gd`). | `grep -n "spawn_chip_sparks" vajb-orbit/game/*.gd` → `weapons.gd` only | One call beside `_play_chip()` when a mining-laser owner exists. |

### Owner decisions carried, not findings

1. **§13's turn tick** — the table still reads 3.4/3.0/… and the code reads half of it; §4's
   table is the before/after the amendment needs.
2. **`STRAFE_FRACTION`** — G1 proposed (and did not add) one named value to weaken the
   strafe, since a full-deflection strafe reaches the class ceiling, exactly like full
   throttle. Reversal path is documented in G1 §4 and the suite's `_command_velocity(0,1)`
   pin is the one assertion that would move with it.
3. **The strafe is locked in Emergency Flight Mode** (it is thrust, ruling 14); the cursor
   turn stays live. Worth a one-line confirmation in the owner's next pass.
4. **NPC hulls turn at half rate too** (the column reaches them through `ShipStats`) — the
   same shape the retuned `coast_time` already has.
5. **The chip cue is S8's `_01` transient, not `sfx_impact_rock`** — one constant if the
   owner wants a gun-on-rock to read as a rock impact.

---

## 12. Evidence index (all under `/tmp`, re-creatable from §1's commands)

| file | what it is |
|---|---|
| `/tmp/g4_gate.log`, `/tmp/g4_gate2.log` | my two gate runs — `passed=294 failed=0`, the `SCRIPT ERROR` block |
| `/tmp/g4_gate_head.log` | the HEAD A/B gate — `passed=277 failed=0`, same block |
| `/tmp/g4_f4_alone.log` | the F4 suite alone — the error isolated, 6/0 |
| `/tmp/g4_probe_g1.log` | the G1 probe re-run (byte-identical to `.agents/gen/_g1/probe_after.log`) |
| `/tmp/g4_lint_head.log`, `/tmp/g4_lint_after.log` | the G4 ledger, before/after (the §9 table) |
| `/tmp/g4_lint_g1.log`, `/tmp/g4_lint_g2.log`, `/tmp/g4_lint_g3.log` | the workers' own lint probes re-run |
| `/tmp/g4_g3_shadow.log` | `[G3] passed=25 failed=0` re-run |
| `/tmp/g4_probe_beam.log` | `probe_g4_beam.tscn` — endpoints, chip, loop, real-frame lifetime |
| `vajb-orbit/tests/probe_g4_lint.gd`, `probe_g4_beam.gd`, `probe_g4_beam_head.gd` (+ `.tscn`) | the three reviewer instruments (none is discovered by the gate: `headless_runner.gd` selects `test_*` only) |

Diff hashes: the wave's uncommitted diff hashed `9c98d5c863d593478127aa9493198a9e` before the
first A/B and after the last one, so every "after" measurement in this report is of the same
tree the workers left. The only tracked change made on top of that tree by this review pass is
the append to `.agents/gen/LOW_BACKLOG.md` (this report's LOW list, as the brief directs); the
wave's own 16 files are byte-identical to the reviewed state, which is why the final gate
re-run still reads `[SUMMARY] passed=294 failed=0` with exactly one `SCRIPT ERROR`.
