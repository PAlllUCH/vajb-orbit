# Slice 0 — owner rulings log (orchestrator record, 2026-09-21)

Every ruling the owner made while the wave ran, with the action taken. Kept so the
wave report and the next wave can cite one place instead of four conversations.

| # | Question raised | Ruling | Action taken |
|---|---|---|---|
| R1 | `14_station_services.md` and the brief's pinned item 7 both price refuel as "CR per fuel point per §13", but §13 carries no such row, so M3 could not implement `refuel()` without inventing a number (M0 discrepancy D3) | **Strike the pointer: refuel and recharge are FREE instant services** | M0b dispatched: `14_station_services.md` §1 row rewritten to "free and instant, no CR charged; owner ruling 2026-09-21"; `IMPLEMENTATION_PLAN.md` §9.9 gained the ruling paragraph that also closes D3. M3 shipped `fee 0` everywhere. No CR rate exists anywhere. |
| R2 | The graphics lane's naming re-layout emptied the flat `assets/icons/` and `assets/env/` trees mid-wave, leaving 133 unresolvable `res://assets/...` references in 24 files, which made the universal gate red (52/1) and stopped `game.gd` and `hud.gd` compiling | **Defer — the graphics lane owns the asset tree** | Workers record asset-path failures as *environment-deferred*, touch no asset and no file outside their set. The icon half healed during the wave (that lane's `refile_icon_paths.py`); the env half is listed file by file in `.agents/gen/asset_path_fallout.md` for that lane. |
| R3 | F5's `consume_fuel_cell` had no binding; applying §11's C made it collide with the P1 `cargo_toggle` = C, a contradiction inside the owner's own spec | **Keep `cargo_toggle` = C; the new action takes a free key** | Orchestrator rebound `consume_fuel_cell` to **R** through godot-ai (`remove_action` + `ensure_binding`). `18_engine_spec.md` §11's "C" is therefore superseded by the ruling and is a spec-edit item, not a code one. Verified on disk: 18 actions, `cargo_toggle` = C, `consume_fuel_cell` = R. |
| R4 | `18_engine_spec.md` (owner-locked) still sells fuel for CR in three places — §2.1 ruling 13, §4.4, §12 item 8 — contradicting R1 (M4 finding F7) | **The owner strikes those three lines in their own spec pass** | Nothing edited. Recorded as an open owner item in the wave report and WAVEBOARD. The mitigation already shipped (M0b's docs + M4's CONTRACTS §8/§8.1 and changelog). |

## Still open, owner-gated

- **§13 speed table v2 (ruling 26):** the △ interpolations (Cutter 700 / Miner 380
  / Frigate 450, with their turn rates) are unticked, so the wave used the shipped
  §13 class columns as law and derived every force from them (M1 §3). The tick is
  required before any test bakes the v2 numbers.
- **R4** above.
- **R3's spec consequence:** `18_engine_spec.md` §11 still says C.

## Orchestrator-applied project settings (this wave)

Applied through the editor via godot-ai, never by hand, and verified on disk:

| Action | Key | Note |
|---|---|---|
| `consume_fuel_cell` | **R** | new this wave; §11 says C, superseded by ruling R3 |
| `interact` | F | engine wave 1, unchanged |
| `warp` | H | engine wave 1, unchanged |
