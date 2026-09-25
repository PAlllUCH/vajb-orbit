---
slice: S13
reviewer: S13-R1
verdict: passed-with-followups
gate: "812/0 → 834/0"
---

# S13-R1 review

Diff targets: `01_economy_core.md` §5.6, `02_minerals.md` §5.1 Rule A,
`CONTRACTS.md` §5. Every AC was re-measured on the shipped worktree; nothing is
taken from the builders' reports. No HIGH. **3 MED** (S13-B1/F1 the field credit
surviving a respawn, S13-B2/F1 the overlay mounted by nothing, S13-B2/F2 the suite
deleting the live `user://dev_tuning.cfg`), **4 LOW** (L198–L201).

## Findings

| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| S13-B1/F1 | MED | `game/asteroid_field.gd:125,143,174` | `_ore_credit` survives `setup()` and `respawn()`; the only writers are `:440,449,454`, so a respawned field pays a previous cycle's leftover credit and one family can realise more than its own `_bore_ore` (AC2's own ±1 yardstick). Total ore over the two cycles is still conserved, so it is a delivery-timing gap, not a mint. | F1 — reset it in `setup`/`respawn` (one line) |
| S13-B2/F1 | MED | `ui/dev/dev_tuning_menu.tscn` | Nothing in the shipped tree mounts the overlay: `rg dev_tuning_menu` reaches only its own suite and the scene, so `KEY_F1` does nothing in game. AC4's letter is met by the suite; its user-visible behaviour is unreachable. Bucket 2 (B2's `VAJB_WORKER_FILES` barred a shipped-UI/autoload edit). | developer / next wave — add the mount point; not F1 |
| S13-B2/F2 | MED | `tests/test_s13_devmenu.gd:17,46,58` | The suite writes and **deletes the live** `user://dev_tuning.cfg` (`config_path` defaults to the pinned path), while the runner sandboxes only `profile.cfg`/`economy_log.txt` (`headless_runner.gd:22-24`). Measured: a pre-existing `dev_tuning.cfg` placed in a gate store was gone after the gate. A `verify_wave.py --tests` run inherits the shell's `XDG_DATA_HOME`, so it reaches the owner's account. | F1 — point `config_path` at `user://_gate_scratch/…` and assert the pinned default separately |
| S13-B1/F2 | LOW | `tests/probe_s12_rock_rate.gd:277-279` | The gun-cap row hardcodes `0.10` instead of reading `OreTuningScript.gun_burst_share` (the sibling probe does read it); hard rule 4's "no re-declared numbers". A looser/live bound, so it cannot hide a regression, but it mirrors a tunable. | → `L198` |
| S13-B1/F3 | LOW | `game/player_ship.gd:1317-1320` | The comment claims "a fit change retunes the battery with no new node", but `_fit_ids` is assigned only in `setup()` (`:298`) and never mutated; the count changes only on a re-setup. Comment accuracy only. | → `L199` |
| S13-B1/F4 | LOW | `docs/gameplay/01_economy_core.md:181,192-200` | §5.6's measured prose is stale against the shipped tree: laser **0.657** u/s, GUN3 **0.645** u/s, GUNMAX **1.505** u/s (was 0.833 / 1.689 / 3.941), so "Shooting is the fast, lossy route" now holds only for a full rack. The ticked rule (§5.6 amendment) is untouched. | → `L200` |
| S13-B2/F3 | LOW | `tests/test_s13_devmenu.gd:190-206` | AC4's strongest claim ("gate byte-identical with the file present on the store") is proven on a store where the run itself deletes the file; no shipped boot path reads it, so the claim holds trivially and the file's survival is unasserted. | → `L201` |

## AC re-measurement (all on the shipped worktree)

- **AC1 gun cap.** T1 field: GUN3 **4 of 42 = 0.0952**, GUNMAX 4 of 42, T3 GUN3/GUNMAX **3 of 30 = 0.1000** (S12: 0.595 / 0.833). Single-rock: GUN3_FAMILY/GUNMAX_FAMILY **0 units / bore 7.0 = 0.000×** (S12's 0.714 row moved, far under the 0.10 line). Both ≤ `0.10 × Σ bore + 1`.
- **AC2 conservation.** LASER_FAMILY **7 units / bore 7.0 = 1.000×** (S12: 4.000×); LASER_OWN 5 = its extractable. T1/T3 LASER out/in **0.976 / 1.000**. `_rolled_yield` has exactly one caller, `asteroid_field.gd:227` inside `_spawn_rock` (setup-side); `_cleave` (`:370`) calls none, and `poi.gd:587` rolls at setup. So no fresh roll exists in a cleave.
- **AC3 N-scaling.** Own bounded replay `tools/r1_s13_ac3_replay.gd`: **1.0000 / 2.0000 / 3.0000** units per cycle and **0.8333 / 1.6667 / 2.5000** u/s for N = 1/2/3 (0 % off N×); removed == delivered (30/60/90), never above the 90-unit budget. Suite 4/4.
- **AC4 overlay.** Raw `KEY_F1` via `_unhandled_key_input`/`physical_keycode`; no InputMap action. `git diff -- vajb-orbit/project.godot` empty. `load_from_disk()`'s only caller is `open()` (`:192`). Gate on a store carrying a divergent `dev_tuning.cfg`: **834/0**, sorted PASS set **byte-identical** to the clean-store run.
- **AC5 ring.** `sector.gd:75` = `175.0`; the one constant is read at `:190` (spawn), `:236` (dock trigger), `:556` (ring draw). `test_d11_station` rows 175/174/176 green.
- **AC6 anti-drift.** `test_s13_caps.gd:52-70` asserts every `OreTuning` default against its owner const; green in both gate runs.
- **AC7 gate.** `[SUMMARY] passed=834 failed=0` **twice** on fresh scratch stores (`/tmp/s13_r1_gate1`, `_gate2`) plus the carry store; baseline 812 → **+22** = caps 10 + batteries 4 + devmenu 8, no moved row added a row. `verify --baseline s13_start --forbidden … --tests --expect-reports …` → `"problems": []` once this file exists.

## Moved-row audit (SLICE.md §3)

`git diff` touches exactly: `test_engine2_cleaving.gd` (its Large-cleaves row),
`test_d11_station.gd` (the radius row), `probe_rock_cleave_a2.gd` (the re-roll
band rows), `probe_s12_field_budget.gd:176-199`, `probe_s12_rock_rate.gd` cascade
rows, and the three new suites. **No row outside §3's list changed.** The
"not moved" set (`engine2_cleaving.gd:302,332-338`, `test_combat_repair_c5.gd`,
`test_s2_6_burst.gd`, `test_p1_catalogues.gd`, `test_s6_poi_loot.gd`) is
byte-untouched. `test_d11_station.gd:90-92` moved with the radius row (both old
points sit inside a 175 ring) — B1 disclosed it; it is the same DockZone radius
row, not a new one.

## Proposed wording — owner-locked `18_engine_spec.md` (R1 may not edit)

`18_engine_spec.md` has **no §17** (it ends at §16), so the owner's "§6/§13/§17"
reference is partly unresolvable; §6 and §13 carry the contradicted sentences.

- §6, line 276-279 — old: *"weapons apply work at **10 %** of their DPS-equivalent
  rate toward rock *depletion* only — they chip, crack and can cleave a depleted
  rock, but **never extract an ore unit**"*. Proposed: *"…apply work at **10 %**
  toward depletion, but a gun-attributed shatter realises at most `GUN_BURST_SHARE`
  (10 %, owner tick 2026-09-25) of the rock's own original yield through the
  Small-end burst — the reserve beyond the cap burns, and the gun's fragments
  carry no ore"*.
- §6, line 284-287 — old: *"a Small bursts into 1–2 resource pickups of its
  mineral (02 §5 mineral per fragment — the children inherit a re-rolled tier)"*.
  Proposed: *"a mining shatter hands the children the parent's reserve
  (`FRAGMENT_CORE_SHARE` of its own yield), whole units split across
  `FRAGMENT_SPLIT`, no fresh roll; a Small pays the reserve as pickups"* (the
  "re-rolled tier" clause is already not representable — a mineral fixes its tier).
- §13, line 441 — old: *"gun chip rate 10 % (depletion only, ruling 17)"*.
  Proposed: *"gun chip rate 10 %; a gun-attributed shatter pays at most
  `GUN_BURST_SHARE` 0.10 of the rock's own yield (S13, owner tick 2026-09-25)"*.
- §13, line 497 — old: *"Fragment mineral | parent's mineral, re-rolled yield
  (02 §5 path)"*. Proposed: *"parent's mineral; yield is the parent's reserve,
  redistributed, never re-rolled"*.
- §13, line 495 — old: *"S → 1–2 pickups"*. Proposed: *"S → the reserve as
  pickups (float credit, whole units)"*.

## Gate

`[SUMMARY] passed=834 failed=0` — fresh store `/tmp/s13_r1_gate1`, fresh store
`/tmp/s13_r1_gate2`, and carry store `/tmp/s13_r1_carry` (divergent config at
boot, sorted PASS set identical). Baseline `812/0` per SLICE.md.
**0 HIGH / 3 MED / 4 LOW (L198–L201).** The two `SCRIPT ERROR` lines
(`test_weapon_fx_f4.gd:178`, `economy_log.gd:28`) are the pre-existing pair
CONTRACTS §9 records.
