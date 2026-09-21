# G5 — fixer report: wave **flight feel & beam polish** (one pass)

Fixer: **G5**. Authority for every finding: `.agents/gen/flight_beam_g4_report.md` (G4, the
mandatory review). Wave law: `.agents/gen/flight_beam_wave_task.md`. Host Linux,
`~/.local/bin/godot` (`4.7.2.stable.official.ed1daf0bf`), project `vajb-orbit/`, every
command below re-runnable as written from `/home/kamil-paluszkiewicz/VajbOrbit`.

**Verdict: both of G4's MED findings are closed.** MED-1 is recorded in
`docs/CONTRACTS.md` (v1.3) to the shipped truth with G4's measured numbers and the four
spec-side leftovers carried as an owner tick instead of edited. MED-2's three shadowing
sites are renamed away and the ledger's count is proven with the `--debug` instrument
CONTRACTS §9 documents. The gate is **294 passed / 0 failed** before and after, exit 0,
with the one pre-existing `SCRIPT ERROR` G4 A/B-proved. **Nothing else was touched**: no
assets, no theme, no `project.godot`, no `addons/**`, and no doc other than
`docs/CONTRACTS.md`.

---

## 1. Constraint compliance

| Constraint | Evidence |
|---|---|
| only `docs/CONTRACTS.md` of the docs | `git diff --name-only` → `docs/CONTRACTS.md` is the **only** new entry against the wave's own working set (11 modified tracked files + 7 added files = 18); `docs/design/*.md` and `docs/gameplay/*.md` are byte-unmodified (`git status` shows no new entry). |
| no assets / theme / `project.godot` / `addons/**` | none in `git diff --name-only`; `project.godot` read only (`awk` over its `[input]` section), never written. |
| code files touched | exactly two, both inside the tabled `VAJB_WORKER_FILES` (`vajb-orbit/tests/`): `vajb-orbit/tests/test_flight_beam_g2.gd`, `vajb-orbit/tests/probe_g3_shadow.gd`. Three renames, no behaviour change. |
| gate ≥ 294 | `[SUMMARY] passed=294 failed=0`, exit 0 (§5). |
| report path | this file. |

One host note worth the orchestrator's attention: on this host the file-set hook denies
**absolute** paths (its normaliser only strips the Windows workspace root), exactly as
`AGENTS.md` warns. Every write in this pass used a workspace-relative path, which the hook
accepts; an absolute path is refused with a summary of the allowed set.

---

## 2. MED-1 — the four behaviours had no owning-doc record

### 2.1 Before (G4's own commands, reproduced)

```bash
grep -n "A/D turn" docs/gameplay/18_engine_spec.md          # 67:  **A/D** turn.
grep -n "WASD throttle/turn" docs/CONTRACTS.md              # 129: WASD throttle/turn ...
sed -n '231p' docs/design/IMPLEMENTATION_PLAN.md            # turn_left (A) · turn_right (D)
grep -n "weapon_ids\|retarget(decoy)\|feedback_row(name)\|spawn_sheet(parent: Node, name" docs/CONTRACTS.md
                                                            # 449 set_fitted(weapon_ids: ...)  [and 464, a method list]
```

Two refinements against G4 §10's list, both measured rather than argued:

* **`feedback_row(name)` and `spawn_sheet(parent: Node, name)` are not pinned in
  `docs/CONTRACTS.md` at all.** `grep -n "feedback\|spawn_sheet\|row_name\|fx_name"
  docs/CONTRACTS.md` → rc 1, no match. The code-side renames are real
  (`projectile.gd:1098 feedback_row(row_name)`, `:1109 spawn_sheet(parent, fx_name)`),
  but this file never carried those two names, so there was nothing to correct for them.
  The stale parameter pins that **do** exist are exactly two: §8.2's
  `set_fitted(weapon_ids)` (shipped `weapons.gd:339 set_fitted(ids)`) and `retarget(decoy)`
  (shipped `projectile.gd:456 retarget(lure)`).
* **`grep -n "A/D turn"` does not match `18_engine_spec.md:67`** — the line is
  `  **A/D** turn.` (markdown bold, no slash pair). `grep -n "A/D"` → `67:  **A/D** turn.`
  The finding is right, the pattern in the report is one token off.

### 2.2 What changed in `docs/CONTRACTS.md` (v1.3)

`git diff --stat -- docs/CONTRACTS.md` → **189 insertions, 17 deletions**, one file.

| section | change |
|---|---|
| status line | `v1.2` → **`v1.3`** (adds the flight-feel & beam wave). |
| §1 Input map | new row for **`strafe_left` / `strafe_right` = A / D** (keycodes 65 / 68), stating A and D no longer turn and `turn_left`/`turn_right` keep their actions and slots with `"events": []`; a new measured note: the map now holds **22 actions** (W8's 20 plus the two strafe actions added by commit `c37fbe3`), all four read behind `InputMap.has_action` guards, `turn_left`/`turn_right` still having exactly one reader each (`_manual_turn`, `player_ship.gd:429-432`, the only reader in the project). |
| §4 API block | additive seam pinned: `set_aim_point(point: Vector2)` / `clear_aim_point()` under a `# the flight-feel & beam wave (2026-09-21, v1.3)` comment. |
| §4 body paragraph | "**with one owner-sanctioned exception**" → "**with two owner-sanctioned exceptions, both owner rulings of 2026-09-21**": `coast_time` ×0.50 **and** `turn_rate` ×0.50. |
| §4 — **new turn-retune paragraph** | the nine-row before/after table (below), `turn_curve classes=9 mismatched=0 retune=x0.50`, the five byte-identical columns, the NPC reach-through, the moved C5 assertion, and the reversal path. Recorded the way the `coast_time` retune is recorded at §4:114-124. |
| §4 flight sentence | rewritten to the shipped truth: **W/S throttle, A/D strafe**; then three new paragraphs — the nose follows the cursor while `thrust_forward` is held / the heading holds otherwise, the strafe derived from §13's own two rows, and the autopilot/booster sentence updated to "any throttle, strafe **or** turn input cancels it". |
| §8.2 | `set_fitted(weapon_ids)` → **`set_fitted(ids)`**; `retarget(decoy)` → **`retarget(lure)`**. |
| §9 | expected gate `passed=236` → **`passed=294`** with the reason for the change; the per-suite list replaced with the 26 suites read off the log (below); the pre-existing `test_weapon_fx_f4.gd:176` `SCRIPT ERROR` **named instead of assumed away**; the warning ledger's before/after counts added. |
| §10 changelog | **v1.3** entry (the wave, its four behaviours, the two corrected pins, the gate/ledger records, "no pinned signature renamed or removed", the one moved pre-existing test assertion, evidence paths) plus the **owner tick list** (below). |

### 2.3 The measured numbers the record cites (G4's own instrument, re-run by me)

`~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_g1_flight_feel.tscn
--fixed-fps 60 --quit-after 20000` → `/tmp/g5_probe_g1_after.log`, **byte-identical to
G4's before/after and to G1's own log after normalising the one `wall_ms` stamp**.

**The `turn_rate` retune** (the table now in §4):

| hull | §13 class | before (= §13, = HEAD) | after | after °/s | ratio | `turn_spinup` |
|---|---|---:|---:|---:|---:|---:|
| ship_fighter | Fighter | 3.400 | 1.700 | 97.4 | 0.5000 | 0.40 |
| ship_vanguard | Cutter | 3.000 | 1.500 | 85.9 | 0.5000 | 0.50 |
| ship_miner | Miner | 2.000 | 1.000 | 57.3 | 0.5000 | 1.00 |
| ship_trader | Trader | 2.400 | 1.200 | 68.8 | 0.5000 | 0.70 |
| ship_corvette | Corvette | 3.200 | 1.600 | 91.7 | 0.5000 | 0.45 |
| ship_freighter | Hauler | 1.500 | 0.750 | 43.0 | 0.5000 | 1.40 |
| ship_gunship | Gunship | 1.900 | 0.950 | 54.4 | 0.5000 | 1.00 |
| ship_patrol | Frigate | 2.100 | 1.050 | 60.2 | 0.5000 | 0.90 |
| ship_destroyer | Destroyer | 1.600 | 0.800 | 45.8 | 0.5000 | 1.20 |

`[G1] turn_curve classes=9 mismatched=0 retune=x0.50`.

**Cursor steering / heading hold** (same probe):
`cursor_ship_vanguard … omega_peak=1.500 rate=1.500 ratio=1.000 arrived=true`,
`cursor_ship_fighter … 1.700/1.700 ratio=1.000`, `cursor_ship_freighter … 0.750/0.750
ratio=1.000`; `hold_ship_vanguard … t_omega_zero=0.150 spinup=0.525 heading_held=true`,
`hold_ship_freighter … t_omega_zero=1.467 spinup=1.470 heading_held=true`,
`hold_at_rest … heading_drift=0.00000000 speed=0.00000000 held=true`.

**The strafe** (same probe): `strafe_ship_vanguard t_90=2.283 … lateral_peak=368.414
lateral_ceiling=406.600 … s_lateral=417.536 s_forward=-0.000 heading_delta=0.00000000
right_is_right=true`; fighter `t_90=1.900 … 386.786/427.500`; freighter `t_90=5.683 …
251.104/278.350`; `strafe_with_thrust speed_peak=406.600 ceiling=406.600
sqrt2_ceiling=575.019 track_deg=45.03`. `grep -rn "STRAFE_FRACTION" vajb-orbit/` → empty,
so the one proposed constant was not added (recorded).

**The beam** (`res://tests/probe_g4_beam.tscn`, same command): `hit d=120 endpoint=100.000
resolved=100.000`, `d=250 → 230.000`, `d=480 → 460.000`, both misses unchanged
(`500.000` reach / `300.000`), the rock chip `cue=sfx_mining_chip_01 bursts=1 work=0.1500`,
`1.25 s held: bursts=5 work=3.7500`, `FLASH_SECONDS=0.2000 frames=4 fps=20.0`,
`held 2.00 s: flashes=10 at frames=[0,10,…,90] emissions=1`, `done failures=0`.

**The gate**, per suite, read off the log rather than carried forward (the previously
recorded per-suite list was missing the three `weapon_fx_*` suites, which is why §9 now
reads them off the run): `weapon_fx_f1 22 · weapon_fx_f2 13 · weapon_fx_f4 6 ·
combat_repair_c5 7 · engine2_cleaving 9 · engine2_damage 20 · engine2_dock 2 ·
engine2_fixes 17 · engine2_hud 19 · engine2_loot 13 · engine2_npc 28 · engine2_pools 16 ·
engine2_weapons 29 · engine2_wiring 13 · engine_c3_flight_decay 3 · flight_beam_g2 5 ·
flight_feel_g1 12 · p1_catalogues 11 · p1_clock_log 4 · p1_market 13 · p1_pricing 5 ·
p1_profile 9 · p1_refinery 6 · p1_repairs 5 · ui_slot_layout 7` — **294**, 26 suites.

### 2.4 The owner tick list recorded, not edited

Both files are owner-locked (`18_engine_spec.md` explicitly; the brief forbade `docs/**`
for every worker), so the leftovers are written into the v1.3 changelog as the owner's tick
list and **not** edited by this pass:

1. `docs/gameplay/18_engine_spec.md:67` — `  **A/D** turn.`
2. `docs/gameplay/18_engine_spec.md:389` — §11's "Everything else stays:
   thrust/turn/fire/boost/mine/cargo/weapon_1..5/Q" bullet.
3. `docs/gameplay/18_engine_spec.md` §13's handling table — the `turn_rate` column; noted
   that `coast_time` from the previous wave is the same outstanding tick, so one §13 pass
   closes both.
4. `docs/design/IMPLEMENTATION_PLAN.md:231` — the frozen `turn_left` (A) · `turn_right` (D)
   row, plus the note that the two strafe actions are entries 5 and 6 of
   `REBINDABLE_ACTIONS` (LOW-1 covers the misleading "Orders 18 and 19" comment).

---

## 3. MED-2 — the wave's own new files added three shadowing sites

### 3.1 Before, measured

```bash
~/.local/bin/godot --headless --debug --path vajb-orbit res://tests/probe_g4_lint.tscn --quit-after 900
```

**18 `WARNING:` rows / 16 unique `at:` sites.** The three named rows, verbatim:

```text
WARNING: The local function parameter "velocity" is shadowing an already-declared function at line 57 in the current class.
     at: GDScript::reload (res://tests/test_flight_beam_g2.gd:51)
WARNING: The local variable "owner" is shadowing an already-declared property in the base class "Node".
     at: GDScript::reload (res://tests/probe_g3_shadow.gd:134)
WARNING: The local variable "name" is shadowing an already-declared property in the base class "Node".
     at: GDScript::reload (res://tests/probe_g3_shadow.gd:139)
```

(18 raw vs 16 unique because a dependency compiles inside its dependent's block —
`npc_ship.gd:168` and `npc_brain.gd:104` each appear twice, G3's measured correction.)

### 3.2 The three edits

| file:line | construct | change |
|---|---|---|
| `tests/test_flight_beam_g2.gd:51` | `StubHull.apply_recoil(velocity, _mass)` shadowing the class's own `velocity()` at `:57` | parameter → **`recoil_velocity`**, body `recoil += recoil_velocity` (matches `player_ship.gd:318`'s `projectile_velocity`). |
| `tests/probe_g3_shadow.gd:134` | local `owner` shadowing `Node.owner` | → **`owner_script`** (3 uses, incl. the `as GDScript` cast). |
| `tests/probe_g3_shadow.gd:139` | local `name` shadowing `Node.name` | → **`constant_name`** (5 uses; the `%s` format strings are untouched). |

Three renames, one local each, no behaviour change: the renamed values are used only inside
the same block, GDScript has no named arguments, and both files still pass (§5).

### 3.3 After, measured

```bash
~/.local/bin/godot --headless --debug --path vajb-orbit res://tests/probe_g4_lint.tscn --quit-after 900
```

**15 `WARNING:` rows / 13 unique `at:` sites — the three sites read `0`.**

| group | before | after |
|---|---:|---:|
| the wave's 11 touched files | 37 | **0** |
| the wave's 7 new files | 3 | **0** |
| `game/asteroid.gd` (no owner) | 3 | 3 |
| `game/npc_brain.gd` (no owner) | 4 | 4 |
| `game/npc_registry.gd` (no owner) | 3 | 3 |
| `game/npc_ship.gd` (no owner) | 4 | 4 |
| `ui/hud/minimap.gd` (positive control) | 1 | 1 |

The three worker lint probes are unchanged and clean where they were clean:

| probe | rows | sites |
|---|---:|---|
| `probe_g1_lint.tscn` | 1 | `ui/hud/minimap.gd:82` (the control) |
| `probe_g2_lint.tscn` | 1 | `ui/hud/minimap.gd:82` (the control) |
| `probe_g3_lint.tscn` | 15 | none in G3's files |

**Whole-project check** as a second, independent instrument: `--headless --debug` on the
gate itself loads every `test_*.gd`, so it measures the `tests/` directory the probe's file
list never covered — **33 rows → 32**, of which `tests/` went **15 → 14**: the one row that
disappeared is `test_flight_beam_g2.gd:51`. `probe_g3_shadow.gd` is a `probe_*` file and is
not discovered by the runner, which is why its two sites are visible only in the ledger.

---

## 4. Re-measurement — every reviewer command, before and after

| command (as G4 wrote it, host-adapted) | before | after |
|---|---|---|
| `godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200` | `[SUMMARY] passed=294 failed=0`, exit 0 | `[SUMMARY] passed=294 failed=0`, exit 0 |
| `godot --headless --debug --path vajb-orbit res://tests/probe_g4_lint.tscn --quit-after 900` | 18 rows / 16 sites | **15 rows / 13 sites** |
| `godot --headless --debug --path vajb-orbit res://tests/probe_g1_lint.tscn --quit-after 600` | 1 row (control) | 1 row (control) |
| `godot --headless --debug --path vajb-orbit res://tests/probe_g2_lint.tscn --quit-after 600` | 1 row (control) | 1 row (control) |
| `godot --headless --debug --path vajb-orbit res://tests/probe_g3_lint.tscn --quit-after 600` | 15 rows, none in G3's files | 15 rows, none in G3's files |
| `godot --headless --path vajb-orbit res://tests/probe_g3_shadow.tscn --quit-after 600` | `[G3] passed=25 failed=0`, exit 0 | `[G3] passed=25 failed=0`, exit 0 |
| `godot --headless --path vajb-orbit res://tests/probe_g1_flight_feel.tscn --fixed-fps 60 --quit-after 20000` | `[G1] done failures=0`, exit 0 | `[G1] done failures=0`, exit 0 — **byte-identical**, `diff` clean after normalising `wall_ms` |
| `godot --headless --path vajb-orbit res://tests/probe_g4_beam.tscn --quit-after 600` | 26 `OK`, `done failures=0` | 26 `OK`, `done failures=0` |
| `… -- --suite=test_flight_beam_g2` | `passed=5 failed=0` | `passed=5 failed=0` |
| `… -- --suite=test_flight_feel_g1` | `passed=12 failed=0` | `passed=12 failed=0` |

The gate's one `SCRIPT ERROR` is present before **and** after and is the pre-existing
`tests/test_weapon_fx_f4.gd:176` one G4 A/B-proved: `Cannot call method 'call' on a
previously freed instance.` / `at: test_a_held_beam_reads_one_hit_per_contact_interval
(res://tests/test_weapon_fx_f4.gd:176)`, with `[PASS]` for that same test on the following
line and exit code 0. Not touched by this pass.

---

## 5. Findings this pass did **not** fix (measured, not fixed, by design)

1. **`tests/test_weapon_fx_f1.gd:54` carries the *identical* shadowing construct** to
   MED-2's own site — `StubHull.apply_recoil(velocity: Vector2, _mass: float)` alongside
   `velocity()` at `:60` — and the whole-project `--debug` ledger measures it:
   `WARNING: The local function parameter "velocity" is shadowing an already-declared
   function at line 60 in the current class. / at: GDScript::reload
   (res://tests/test_weapon_fx_f1.gd:54)`. It is **pre-existing** (wave F, not one of the
   wave's 18 files, and G4's ledger's file list could therefore not see it) and it is
   **outside MED-2's three named sites**, so it was left alone rather than swept into a
   bounded fixer pass. If the orchestrator wants the `tests/` directory literally clean, the
   cure is one rename (`velocity` → `recoil_velocity`) in a file whose next owner already
   has nine other rows listed below.
2. **The rest of the measured `tests/` rows (14 after this pass)**, all pre-existing and all
   outside any wave's file set: `test_engine2_cleaving.gd` 8 (`:103` a method shadow, `:129`
   /`:150`/`:165`/`:182`/`:216`/`:263` unused `field`, `:133` an integer division),
   `test_p1_market.gd` 3 (`seed` at `:99`/`:152`/`:167`), `test_engine2_npc.gd` 1
   (`SectorRegistry` at `:21`), `test_p1_repairs.gd` 1 (`Repairs` at `:11`),
   `test_weapon_fx_f1.gd` 1 (item 1). Recorded here because the gate run that reveals them
   is the §9 instrument and nothing else in the chain reads them.
3. **The beam probe's run-to-run jitter**, characterised over four runs rather than
   reported as a change: `spawns` reads 6 once and 5 three times, and the
   `ObjectDB instances were leaked at exit` line appears in 2 of 4 runs. Neither touches the
   load-bearing numbers (`max_live=1`, `last_live=0`, `done failures=0` every run), G4's own
   text already documents `spawns` as a lower bound ("a spawn in the same frame as a free is
   invisible to it"), and this pass edits neither `weapons.gd`, `projectile.gd` nor
   `probe_g4_beam.gd`. G4's published `spawns=5` is what the after-state reads.
4. **MED-2's precondition vs the reviewer's instrument**: the finding is described as the
   wave's "own new test and probe files", and all three sites were in files the wave added
   — but `probe_g3_shadow.gd` is a `probe_*` file, so the gate can never see its two rows;
   only the §9 ledger can. Worth keeping in mind before a "warnings are clean" claim is ever
   read off the gate alone (this is G4's LOW-3, re-confirmed here).

---

## 6. Evidence index

| path | what it is |
|---|---|
| `/tmp/g5_gate_before.log`, `/tmp/g5_gate_final.log` | the gate before this pass and after it — both `passed=294 failed=0`, exit 0 |
| `/tmp/g5_gate_debug_before.log`, `/tmp/g5_gate_debug_after.log` | the whole-project `--debug` ledger — 33 rows → 32, `tests/` 15 → 14 |
| `/tmp/g5_lint_before.log`, `/tmp/g5_lint_after.log` | G4's `probe_g4_lint` ledger — 18/16 → **15/13**, the three sites at 0 |
| `/tmp/g5_lint_g{1,2,3}_after.log` | the three worker lint probes re-run after the fix |
| `/tmp/g5_probe_g1.log`, `/tmp/g5_probe_g1_after.log` | the G1 flight probe before/after — byte-identical once `wall_ms` is normalised |
| `/tmp/g5_probe_beam.log`, `/tmp/g5_probe_beam_after.log`, `/tmp/g5_beam_rep{1,2}.log` | the beam probe, four runs (the jitter in §5 item 3) |
| `/tmp/g5_probe_g3_shadow_before.log`, `…_after.log` | `[G3] passed=25 failed=0` on both sides |
| `/tmp/g5_suite_g1_after.log`, `/tmp/g5_suite_g2_after.log` | the two wave suites — 12 / 5, both 0 failures |
| `docs/CONTRACTS.md` (v1.3) | the MED-1 record: §1, §4, §8.2, §9, §10 and the owner tick list |
| `vajb-orbit/tests/test_flight_beam_g2.gd`, `vajb-orbit/tests/probe_g3_shadow.gd` | the MED-2 renames |

Diff scope, final: `git diff --name-only` adds exactly one entry to the wave's own set —
`docs/CONTRACTS.md` (`189 insertions, 17 deletions`) — and both test-file edits are in
already-untracked files. No file outside this worker's declared set was written.
