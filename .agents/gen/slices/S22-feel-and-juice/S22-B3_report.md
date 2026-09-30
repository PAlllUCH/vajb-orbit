---
slice: S22
worker: S22-B3
model: deepseek/deepseek-flash (reasoning-effort max)
status: actionable
gate: "941/0 → 971/0 (971 = 941 + B1's 11 + B2's 7 + this suite's 12; S19's byte-seal row is GREEN again — B3 re-pinned it)"
---

# S22-B3 report

## Result
A9–A11 land: the seeker fuze's two doors (80 u / 6 s), the NPC midline-drag twin, the
repair transaction on `ShipFit.resolve`'s pair and the proportional spill. The new suite
carries **12 green rows**; the gate ran twice on fresh scratch stores, identical:
`[SUMMARY] passed=971 failed=0`. `damage.gd` byte-identical; S19's seal re-pinned from
the finished tree (Evidence). **Owner rulings implemented:** 18 (feedback is cosmetic, no
feel row moved a gameplay number), T-feel-1/1b, T-feel-2, T-feel-3 (verified), §22's T3
strike (verified), R-S22-1 (M4), R-S22-2 (M5).
## Acceptance list answers
- **A9 — DONE.** `SEEKER_FUSE := 80.0` / `SEEKER_FUSE_S := 6.0`
  (`projectile.gd:82-83`); `_step_seeker_fuze` (`:675`) answers before the range fizzle
  (`:660`): the 80 u proxy (`:686`) and the exact-6.0 s expiry (`:683`) both land the
  warhead on the lock. The NPC twin `_step_lateral_drag` (`npc_ship.gd:559`) runs every
  flying frame (`:487`); measured NPC skid `t_10` = **0.900 s** = the player's own
  lateral release (`test_s22_balance.gd:175`) — the disclosure's binding clause.
  T-feel-3/§22-T3 verified, never re-edited: the ramp (`player_ship.gd:1067`,`:1407`)
  measured axial == lateral `t_10` 2.367 s (`test_s22_balance.gd:205`; CONTRACTS
  `:3105,3242`), the strike at CONTRACTS `:3074,3101`; 18 §13 `:541`.
- **A10 — DONE.** `Repairs._maxima` (`repairs.gd:97`) resolves the profile's fit through
  the pane's own guarded path; `fee`/`repair` (`:66`,`:138`) and `is_repairable` (`:239`)
  read it. The standard Vanguard fit prints/charges/restores **1250 hull / 800 shield**,
  fee 692 = (1050/2)+(500/3) (`test_s22_balance.gd:235`) — one figure with
  `repairs_panel.gd:_pool_maxima` (`:382`), asserted equal in the same row.
- **A11 — DONE.** `_charge_quadrant` (`player_state.gd:348`) re-offers the remainder
  proportional to remaining capacity until landed or all pools empty: 400 on
  `[200,100,0,0]` lands **300 and kills**, `hull == sum(pools)` exact
  (`test_s22_balance.gd:283`); a 3:1 vector takes 3:1 (`:307`). R-S22-3/R-S22-4 are
  **dispositions, tabled, no code** (table).

## Feel values as shipped (against `S22_BRIEF.md` §11's ticks)
| Row (tick) | Ticked value | As shipped | Reversal |
|---|---|---|---|
| T-feel-1 (L25) | `SEEKER_FUSE := 80.0 u` | 80.0, `projectile.gd:82`; row `test_s22_balance.gd:85` | 0.0 — no fuze, the orbit blessed |
| T-feel-1b (L25) | `SEEKER_FUSE_S := 6.0 s` | 6.0, `projectile.gd:83`; row `test_s22_balance.gd:136` | 0.0 — no flight fuze |
| T-feel-2 (L103) | mirror the midline drag | `npc_ship.gd:559` on the class coast rate; row `:175` | drop the `_apply_intent` call; the body damp owns sideways again |
| T-feel-2 (L39) | the disclosure fix | CONTRACTS §14 `:1936-1946` (at the open), `ship_fit.gd:401` | restore the sentence |
| T-feel-3 (L182) | keep the ramp | shipped, verified: axial == lateral, row `:205` | restore the damp-shaped release |
| §22 T3 | strike | CONTRACTS `:3074,3101` (at the open) | re-propose the ×1.333 row |
| M4 (R-S22-1) | resolve's pair | `Repairs._maxima`; fee 692 on 1250/800, row `:235` | the catalogue pair |
| M5 (R-S22-2) | proportional spill | `player_state.gd:348`; rows `:283,307,329` | the even-split clamp |
| M6 (R-S22-3) | S19's initials stand | disposition — nothing coded, S19 untouched | — (T1–T4/T6–T7 re-tick at playtest 2) |
| M7 (R-S22-4) | keep the per-cell magazine | disposition — `game.gd:_seed_ammo` untouched | the family-pack model |

## Deviations from SLICE.md
1. **The fuze's delivery has no distance gate** — both doors land the warhead on the lock
   the shot names ("orbiting not blessed"; the §13 row names the lock, not a radius);
   the clock belongs to the lock, so a dumb-fired shot or one whose lock died keeps the
   plain range fizzle. Reversal: `_detonate(global_position)` on the expiry, clock from
   launch.
2. **Measured interaction, no value moved** — the shipped rocket's `range` 900 fizzles at
   900 u of path (1 s flat), so a straight chase ends at the range before the 6 s fuze;
   the fuze is the orbit backstop the sheet names. My rows isolate both doors with
   `range: 0`.
3. **`is_repairable` also reads the resolved pair** (A10 names `fee`/`repair`): the pane's
   button reads it while printing the resolved rows, so a plated hull at the catalogue
   ceiling would show a fee with a dead button. Reversal: the catalogue pair.
4. **NPC drag semantics (the sheet's "~2×" is a full-speed estimate).** The twin is the
   uncommanded sideways component chasing zero at `_coast_rate()` (the
   `PlayerShip._step_release` law on the sideways axis), every flying frame. Measured:
   pre-tick body-damp `t_10` = ln(10)·coast_time = **4.835 s**; shipped **0.900 s** at
   v0 = 200 (5.37×) and **1.900 s** at v0 = max_speed 427.5 (2.54×) — the ratio is
   fixture-dependent because the new law is a ramp, the old one an exponential; the
   "settles at the player's rate" clause holds exactly at every speed.
5. **A new observability seam in `npc_ship.gd`** — `applied_force()`/`applied_torque()`
   (the `player_ship.gd:311` twin) and `_apply_force`/`_apply_torque` as the single call
   sites: the runner never awaits a frame, so the drag is otherwise unprovable. No force
   changes. Reversal: inline the two `_body.apply_*` calls.6. **§8's move list was under-counted for s19** — the conserved spill also moves
   `test_the_hull_stays_the_sum_of_the_pools_through_hits_and_heals` (the pre-tick clamp
   left 100 hull standing after its 4-hit fixture; the conserved spill kills); its heal
   half now runs on an exact-emptying fixture, and
   `..._spills_its_remainder_evenly` is renamed `..._spills_proportionally` + the L242
   vector. Row count unchanged.
7. **`test_p1_repairs`'s four rows carry the resolved figures** (same count): a fresh
   profile's standard Vanguard fit resolves 1250/800, so its home fee is 692, not 500 —
   R-S22-1's own consequence; the fee *rates* are untouched.

## Evidence
- Gate, twice, fresh stores, identical: `XDG_DATA_HOME=/tmp/s22b3_gate{A,B}/xdg
  "$GODOT_CONSOLE" --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn
  --quit-after 1200` → both `[SUMMARY] passed=971 failed=0`, exit 0.
- Suite lines (both gate logs): `[S22B3] A9 fuse proxy=80.0 u flight=6.0 s`;
  `A9 skid npc t_10=0.900 s player t_10=0.900 s (coast_time=2.100, damp=0.4762)`;
  `A9 release ramp axial=2.367 s lateral=2.367 s`; `A10 figure hull=1250 shield=800
  fee=692`; `A11 spill 400 on [200,100,0,0]: pools=[0,0,0,0] hull=0.000000`;
  `A11 proportional: stern=150.000 port=50.000 hull=200.000`.- **S19 byte-seal re-pin (amendment 6, the S21 rule) — `sha256sum game/*.gd` on the
  finished tree:**
  `5cabf3d9302fe942aff2ad97b4f3dc85c298e7e204fffb0e86f89e444cbf6269  game/damage.gd`
  `12ab0ae2aeef61d2638387dfe65ee3901c8f1a26433f380442d45e480a242db3  game/npc_ship.gd`
  `e39440bf410b535c50f924208290e54dc8085eea52731890b778a4ad3fbe5d22  game/npc_brain.gd`
  `6f95a9c2f0c2039f5c369f68bf50ee2baaed6875257ddfcdc77b2833400ca4a1  game/weapons.gd`
  `tests/test_s19_quadrants.gd:104,110` carry the new pins with their wave comments; the
  seal row is green; `damage.gd`/`npc_brain.gd` are unmoved from the S19 wave start.
- `--forbidden`: `git diff --stat HEAD -- vajb-orbit/project.godot vajb-orbit/game/
  damage.gd docs/CONTRACTS.md vajb-orbit/addons/` → empty.
- 12 rows in `test_s22_balance.gd` (A9 ×7: 5 fuze/verify + skid + ramp, A10 ×2, A11 ×3);
  the spill/heal rows re-run green in `test_s19_quadrants.gd`/`test_p1_repairs.gd`.
## Files touched
- `game/projectile.gd` — the two fuse consts, `_flight_clock`, `_step_seeker_fuze`
- `game/npc_ship.gd` — the `_step_lateral_drag` twin + the force/torque observability seam
- `game/repairs.gd` — `_maxima`; fee/repair/is_repairable on resolve's pair
- `game/player_state.gd` — the proportional spill (`SPILL_PASSES`)
- `tests/test_s22_balance.gd` — new suite, 12 rows
- `tests/test_s19_quadrants.gd` — the seal re-pin, the spill row, the hull-sum row
- `tests/test_p1_repairs.gd` — the resolved figures of four rows

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| The fuze expiry's no-distance-gate delivery — R1/owner confirm the reading | LOW | `game/projectile.gd:683` |
| `test_s22_balance.gd.uid` lands with the close-out's editor import | housekeeping | `tests/` |
