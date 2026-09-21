# Wave Flight feel & beam polish — task brief

Law, in order: `AGENTS.md`, `docs/CONTRACTS.md` (v1.2), `docs/gameplay/18_engine_spec.md`
(§4.3 the flight controls, §3.2 the inertia semantics, §4.1 the instant families, §13 the
handling table), `docs/design/FX_SPEC.md` (§1.6 the engine-drawn beam and its chip sparks),
`docs/design/ASSET_WIRING_HANDOFF.md` §1.1/§1.2, this brief, `.agents/gen/WAVEBOARD.md`.
Evidence: `.agents/gen/owner_playtest_findings_20260921.md` (third round).

## Owner rulings this wave executes (2026-09-21, third round)

1. **The nose follows the cursor while `thrust_forward` is held**, and the heading holds
   when it is not. The autopilot already turns toward a fly-to point (`_order_turn`), so the
   mechanism exists; `turn_rate` / `turn_spinup` still govern how fast the nose can move.
2. **A/D strafe sideways.** `strafe_left` / `strafe_right` are **already in the input map**
   (the orchestrator added them: A and D; `turn_left` / `turn_right` now carry no key).
   The strafe's strength is **derived from §13's own rows** — the class's `accel_time` /
   `max_speed` — and **no new balance number may be invented**; if a derived constant is
   unavoidable it is one named value, proposed in the report with its reversal path.
3. **Turn rate: all nine `ship_fit.gd` `turn_rate` rows × 0.50** (Vanguard 3.0 → 1.5 rad/s,
   172°/s → 86°/s). §13's table is the owner's to tick, exactly like `coast_time`.
4. **Three beam fixes:** the shaft stops at the resolved hit point (today it is drawn to the
   aim point *before* the target is resolved, so it passes through); a laser chipping a rock
   gets a cue **and** the chip-sparks burst (`fx_mining_beam.png`, FX_SPEC line 138); and a
   held beam's fire feedback **loops** instead of one flash per release.

## Measured before the wave (do not re-litigate)

- `weapons.gd:517-521` — `reach := minf(offset.length(), range)` then `to := from + dir*reach`,
  drawn before `_beam_target()` is called.
- `weapons.gd` `_apply_beam`'s rock branch calls `apply_work` and `return`s: no cue, no FX.
- The muzzle flash plays on `shot_fired`, which the instant families emit once per hold
  (`_beam_started` guards on `_beam_live`).
- `ship_fit.gd` `turn_rate`: fighter 3.4, vanguard 3.0, corvette 3.2, miner 2.0, trader 2.4,
  freighter 1.5, gunship 1.9, patrol 2.1 (rad/s).
- No strafe exists anywhere in the flight model; `settings_manager.gd`'s
  `REBINDABLE_ACTIONS` (17 entries) does not list the two new actions.

## Also in scope: the warning sweep the owner sees in his console

The editor log carries ~30 `SHADOWED_VARIABLE` / `SHADOWED_VARIABLE_BASE_CLASS` /
`SHADOWED_GLOBAL_IDENTIFIER` rows, all the same mechanical class (a parameter or local
shadowing a function, a base-class property or a global class). They are **pre-existing**,
not a regression from the FX wave — the wave touched those files, so their reload emits them
now. The reviewer's LOW-4/L30 list names some; this wave finishes the sweep in the files it
already owns. Verification is the `--headless --debug` ledger CONTRACTS §9 documents.

## Worker table

| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| **G1** | coder — flight feel | `vajb-orbit/game/player_ship.gd,vajb-orbit/game/ship_fit.gd,vajb-orbit/autoload/settings_manager.gd,vajb-orbit/tests/` | Cursor-steering while `thrust_forward` is held (heading holds otherwise, autopilot untouched); A/D strafe with its strength derived from the class's own rows; the nine `turn_rate` rows × 0.50; the two strafe actions added to `REBINDABLE_ACTIONS` so the Controls tab lists them. Tests: the nose reaches the cursor bearing within the class rate, the heading holds with no thrust, strafe moves the hull laterally and not forward, and no other handling number moved. |
| **G2** | coder — beam polish + weapons lint | `vajb-orbit/game/weapons.gd,vajb-orbit/game/projectile.gd,vajb-orbit/tests/` | The shaft stops at the hit point (the miss case keeps the reach); a rock chip spawns the chip-sparks burst and plays the chip cue on the same rate guard the hull branch uses; a held beam's fire feedback loops for as long as the trigger is held. Plus the shadowing warnings in these two files. Tests per behaviour. |
| **G3** | coder — warning sweep | `vajb-orbit/ui/station/exchange_panel.gd,vajb-orbit/ui/station/shipyard_panel.gd,vajb-orbit/ui/station/launch_panel.gd,vajb-orbit/ui/components/slot_button.gd,vajb-orbit/game/sector.gd,vajb-orbit/tests/` | Clear every shadowing warning in these files (the editor log's `exchange_panel.gd:24,25` global-class pair, the `size` parameters at `shipyard_panel.gd:321` / `launch_panel.gd:246`, `slot_button.gd:95,96`, `sector.gd:125,309`). Behaviour byte-identical; prove it with the `--debug` ledger before and after. |
| **G4** | coder — reviewer (**mandatory**) | `vajb-orbit/tests/,vajb-orbit/tools/` | Re-runs every probe byte-identically; measures the turn curve before/after per class, the strafe's lateral response and its derivation, the beam's endpoint against a target at several distances, the rock-chip cue and burst, the held-beam loop, and the warning ledger's before/after count. Diffs against CONTRACTS §4.3/§3.2/§4.1 and §13. Tiers HIGH/MED/LOW; LOW → `.agents/gen/LOW_BACKLOG.md`. |
| **G5** | coder — fixer | per G4's per-finding sets | Only if G4 leaves HIGH or MED. One pass, then G4's probe re-run. |

Run order: **G1 · G2 · G3 in parallel** (file-disjoint), then **G4**, then **G5** if needed.

## Hard rules

- `VAJB_WORKER_FILES` exactly as tabled; the hook denies writes outside it (and denies
  absolute paths on this host — use workspace-relative paths).
- **No worker edits `project.godot`** — the two strafe actions are already registered by the
  orchestrator through the editor's own input-map API. If an action is missing, say so.
- No `assets/**`, no theme, no `addons/**`, no `docs/**` (`18_engine_spec.md` is
  owner-locked; the §4.3/§13 amendments are the owner's).
- No damage, cadence, range, Energy or ammo value may move, and the only handling number this
  wave may change is the `turn_rate` column (× 0.50, owner-ruled).
- Bounded Godot runs only (`--quit-after N`, stdout to a log the worker reads).
- The gate is `godot --headless --path vajb-orbit res://tests/headless_runner.tscn
  --quit-after 1200`, measured at **passed=277 failed=0** before this wave. Grow the count;
  never shrink it, never edit a test to hide a failure.

## Close-out (orchestrator)

Gate re-run; `python3 staging/verify_wave.py verify --baseline flight_beam_start --forbidden
project.godot --expect-reports <the wave's reports> --tests`; WAVEBOARD updated; wave-boundary
commit; report to the owner with the turn curve, the strafe derivation and the warning count.
