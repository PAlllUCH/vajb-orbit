# Engine slice 0 — Physics & Fuel: wave report (orchestrator, 2026-09-21)

The coding orchestrator's close-out for the wave `.agents/gen/dispatch_coder.md`
queued first. Executed end to end: M0 → M1–M3 → M4 → M5 → M6, with two
orchestrator-owned interventions (owner rulings, input map) and one
environment blocker carried as deferred.

**Verdict: closed.** The hull flies on a real rigid body, the ship runs on the
energy/fuel reactor chain, rocks cleave, stations refuel for free, and the save
schema is v3. The universal gate reads **78 tests, zero failures, exit 0**, and
`staging/verify_wave.py verify --baseline slice0_start` returns
`problems: []`. Two items stay owner-gated and neither blocks slice 2.

---

## 1. What the wave delivered

| File | Bytes | md5 | Nature |
|---|---:|---|---|
| `vajb-orbit/game/impact.gd` | 6 636 | `4deb92417496` | **new** `Impact` RefCounted: reduced-mass collision damage, recoil, knockback, `I(d)` shockwave; the §13 constants' single owner |
| `vajb-orbit/game/player_ship.gd` | 30 880 | `3c40642034d6` | hull migrated to forces and torque on a `RigidBody2D`; contact damage; emergency thrust gate; boost fuel burn; reactor tick; fuel-cell caller (15 166 B before the wave) |
| `vajb-orbit/game/player_ship.tscn` | 835 | `3b7cd0023f0f` | `HullBody` `CharacterBody2D` → `RigidBody2D` (contact monitor, 4 contacts, never sleeps, gravity 0, REPLACE damps) |
| `vajb-orbit/game/ship_stats.gd` | 1 858 | `d081081f1c77` | `hull_mass`, `energy_max`, `energy_regen`, `fuel_max` in §9's field order |
| `vajb-orbit/game/ship_fit.gd` | 17 979 | `4f0f19662ecd` | `hull_mass` joins the §13 `HANDLING` column; pools; `mass_add` armour pass |
| `vajb-orbit/game/player_state.gd` | 10 753 | `187fc58df09f` | pools, `try_spend_energy`/`try_spend_fuel`, `emergency_mode`, `consume_fuel_cell`, `tick`, `ctx` on `damage` (additions only) |
| `vajb-orbit/game/asteroid.gd` | 13 543 | `094153ebe602` | `StaticBody2D` → `RigidBody2D`, 560 t, damp 3.71; cleaving consts; `size_class` seam |
| `vajb-orbit/game/asteroid_field.gd` | 16 329 | `0026cec9cc1b` | ruling-17 cleaving wiring: L→2–3 M, M→2 S, S→1–2 pickups, fragments as field members |
| `vajb-orbit/game/repairs.gd` | 9 919 | `d70f9b3a69c0` | `refuel()` / `recharge()`, both `fee 0` |
| `vajb-orbit/game/station_catalog.gd` | 6 904 | `239a92a6adaa` | `SERVICES` rows, no price field |
| `vajb-orbit/autoload/player_profile.gd` | 20 576 | `f744d0ea0acc` | vitals gain `fuel`; `profile_changed &"fuel"`; **save v3** |
| `vajb-orbit/ui/hud/hud.gd` | 31 649 | `f72eedaac0d7` | `set_pool`, `set_emergency`, two bars + the EMERGENCY FLIGHT banner (21 142 B before) |
| `vajb-orbit/game/game.gd` | 21 652 | `4fbcac310b25` | pool maxima from the launch snapshot, filed tank on dock, `_push_pools()` |
| `vajb-orbit/tests/test_engine2_pools.gd` | 12 000 | `6aad5afe6c0a` | **new**, +16 tests |
| `vajb-orbit/tests/test_engine2_cleaving.gd` | 11 632 | `007a3cdcfb6a` | **new**, +9 tests |
| `vajb-orbit/tests/test_p1_profile.gd` | 14 440 | `6a9e4fa06977` | one line: the v2 assertion becomes v3 (F1) |
| `vajb-orbit/project.godot` | 7 448 | `ef90504085f6` | **orchestrator-applied** via godot-ai only: `consume_fuel_cell` = R |
| `docs/CONTRACTS.md` | 24 813 | `565bfff342ea` | M4/M6: slice-0 pins, the two owner rulings, the grown gate, the changelog |
| `docs/gameplay/01_economy_core.md` | 10 677 | `3089a3d44551` | §6: the vitals record gains `fuel` (M0) |
| `docs/gameplay/14_station_services.md` | 7 408 | `f8e1c12ec4b4` | §1: refuel/recharge free, the dangling §13 pointer struck (M0b) |
| `docs/design/IMPLEMENTATION_PLAN.md` | 47 607 | `7be8ae201f44` | §9.9: the slice-0 line + the owner ruling that closes M0's D3 |

Numbers checked end to end: **no invented constant**. Every value traces to a
§13 row or a §4.2/§4.4 ruling; the three derived numbers (rock `LINEAR_DAMP`
3.71, the `1/coast_time` and `1/turn_spinup` damps, the `m·r²/2` inertia) carry
their derivations in-file. M4's §13 probe compares the code against a hand
transcription of the spec, not against the reports: 36/36.

## 2. Acceptance, as measurements

| Requirement | Measured |
|---|---|
| Rigid-body flight reproduces the §13 feel | max 450.0 u/s at 1.983 s (accel 2.0 s); coast, brake 253.76 u vs coast 362.97 u; turn 3.4 rad/s at 0.400 s; autopilot 39.92 u |
| §16 worked example | 450 u/s flat-wall hit → hull 700 → 538 = **162.0** (formula 162); recoil −12.37 u/s on 80 t |
| Reactor chain | 10 Energy → 1 Fuel; boost **3.0000/s**; dash 25; fuel 0 → thrust **0.0 u/s**, reactor refill 3.5 (= 5 × 0.7); fuel cell 40 + 10 s cooldown |
| Reactor refills in-game | 90.0 → 94.9999999999997 in 1 s (4.99999/s, spec 5.0) |
| Cleaving | L → `[3,3,…,2,2]` over 11 rocks; M → 2 S; eject ×1.2 within 14.38°; yield-0 despawns bare; chip arithmetic untouched |
| Rock body | 560 t, damp 3.71 REPLACE, 409 → 8.88 u/s drift |
| Station | `refuel` ok/fee 0 → tank to `fuel_max` 200, credits 4321 → 4321; `recharge` fee 0 |
| Persistence | save v3 round-trips; a v2 fixture loads, keeps its credits, refuels without moving hull |
| HUD | Energy/Fuel bars 260×14, fuel danger at exactly 15 % (fill + readout), EMERGENCY FLIGHT banner, `PlayerState` signal alone raises it |
| Boot gates | `game` / `menu` / `settings` / `station` all exit 0 (the `game` one carries the asset-path errors of §5) |
| Universal gate | **`passed=78 failed=0`**, exit 0 — measured by M5, M6 (three runs) and the orchestrator's `verify_wave.py --tests` |

## 3. Findings: M4 → M5 → M6

| # | Tier | Finding | Disposition |
|---|---|---|---|
| F1 | **HIGH** | gate red: `tests/test_p1_profile.gd:204` still asserted save v2, which this wave's mandated v3 falsified (77/1) | **fixed** (M5, one line) → 78/0; M6 verified the diff is exactly that line |
| F2 | MED | fuel 0 did not ignore thrust — measured 203.57 u/s of acceleration | **fixed**: throttle and autopilot commanded speed gated; thrust 0.0 u/s, wheels still 3.4 rad/s |
| F3 | MED | the afterburner burned no fuel and armed on an empty tank; `BOOST_FUEL`/`DASH_FUEL` had no code owner | **fixed**: 0.0 → 3.0 fuel/s, empty-tank arm 2.517 s → 0.0; single owner in the hull |
| F4 | MED | `PlayerState.tick` had no caller, so the reactor never refilled in the shipped game | **fixed**: the hull's physics step calls it |
| F5 | MED | `consume_fuel_cell` was unreachable (no binding, no caller) | **fixed**: binding applied by the orchestrator (ruling R3), caller added, action-guarded |
| F6 | MED | the probe-in-`tools/` hook gap defeated the enforcement layer for every worker | **closed in-dispatch**: `vajb-orbit/tools/` added to the M5/M6 file sets; M6 wrote its probes with `write`, no shell fallback |
| F7 | MED | the owner-locked spec still sells fuel for CR in three places | **open, owner** (ruling R4) |
| LOW ×18 | LOW | doc form/placement, unit readings, the fragment-tier ruling, the mining-laser drain's missing owner, the station boot gate's write to the dev profile, the environment asset list | `.agents/gen/LOW_BACKLOG.md`, riding with slice 2 |

M4 also found, by measurement, what no worker report claimed: the half-wired
reactor chain (F2–F5). That is the review layer paying for itself — M1/M2/M3 each
implemented their slice correctly and each one left the *seam between them*
unwired.

## 4. Owner rulings made during the wave

Full table with the action taken: `.agents/gen/slice0_owner_rulings.md`.

1. **Refuel and recharge are free instant services** (the §13 CR rate does not
   exist). Applied by M0b to `14_station_services.md` and `IMPLEMENTATION_PLAN.md`
   §9.9; M3 shipped `fee 0`; M6 measured credits unchanged.
2. **The asset tree belongs to the graphics lane** — asset-path failures are
   environment-deferred, not findings. The icon half healed mid-wave; the `env/`
   half is listed file by file in `.agents/gen/asset_path_fallout.md`.
3. **`cargo_toggle` keeps C; the new action moves to a free key.** The
   orchestrator rebound `consume_fuel_cell` to **R** through godot-ai. Verified on
   disk (keycode 82) and functionally (an R press spends exactly one cell, C
   spends none).
4. **The owner strikes the superseded refuel wording in their own spec pass.**
   Nothing edited in the owner-locked spec.

## 5. Environment: the graphics lane's parallel re-layout

The wave ran while `assets/` was being re-laid into per-family containers. At its
worst M1 measured **133 unresolvable `res://assets/...` references across 24
files**, and because several are parse-time preloads the fallout was not cosmetic:
`game.gd` failed to compile transitively through `sector.gd`, `hud.gd` failed on
the tint set, `pickup.gd` and `asteroid.gd` failed on their moved sprites, and the
gate was red (52/1) before a single slice-0 edit.

Dispositions taken: no worker touched `assets/**` or any file outside its set; the
icon families were swept by that lane during the wave (the gate's red healed
unaided); the remaining `env/` list was handed over in
`.agents/gen/asset_path_fallout.md`. **Consequence carried forward:** the
`game.tscn` boot gate cannot compile `game.gd` until the sweep lands (M3 measured
the file through one stubbed preload to keep its evidence honest), and a depleted
**Small** rock's pickup burst stays unproven end to end. Neither is a code defect.

## 6. Files the wave did not change but slice 2 must pick up

- `ui/station/repairs_panel.gd|.tscn` — the free refuel/recharge rows (the data
  and the two service functions already exist).
- `ui/hud/hud.tscn` — the pool blocks are built in `hud.gd` today because the
  scene was outside M3's set; moving them is one builder's retirement.
- `game/pickup.gd` — one stale preload (`env/pickup/`), owned by the graphics
  lane's sweep per ruling R2.

## 7. Evidence index

| Artifact | Path |
|---|---|
| Worker reports (the chain) | `.agents/gen/slice0_m0_report.md` … `slice0_m6_report.md` |
| Owner rulings log | `.agents/gen/slice0_owner_rulings.md` |
| Asset-path handover | `.agents/gen/asset_path_fallout.md` |
| LOW backlog | `.agents/gen/LOW_BACKLOG.md` |
| Final gate + wave diff | `.agents/gen/_slice0_verify.log` (gate 78/0, `problems: []`) |
| Dispatch scripts and logs | `.agents/gen/_dispatch/slice0_m*_ruled.sh`, `slice0_m*.log` |
| Probe evidence | `.agents/gen/slice0_m{1..6}_probe*.txt`, `_testgate*.txt`, `_boot_*.txt` |
| Re-runnable probe sources | `.agents/gen/slice0_m*_probe*.gd|.tscn` |

## 8. Open items, ranked

1. **Owner:** strike the superseded refuel wording in `18_engine_spec.md`
   (§2.1 ruling 13, §4.4, §12 item 8) and correct §11's `consume_fuel_cell` = C to
   R. Also still open from before this wave: the §13 **speed table v2** △ tick —
   the wave derived every force from the shipped class columns, so nothing is
   baked against the unticked rows.
2. **Graphics lane:** the `env/` path sweep in `.agents/gen/asset_path_fallout.md`.
3. **Slice 2:** wire `_enemy_engaged()`, and note that `PlayerState.tick` now has
   exactly one caller (the hull) — slice 2's weapons should spend through
   `try_spend_energy`, not re-tick the reactor.
4. **Next lane:** the free-service rows in the REPAIRS panel and the HUD pool
   blocks into `hud.tscn` when those files next have an owner.
