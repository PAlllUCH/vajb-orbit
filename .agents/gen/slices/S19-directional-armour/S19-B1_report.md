---
slice: S19
worker: S19-B1
model: "deepseek-flash (deepseek)"   # the session model that ran this worker
status: actionable                   # one bucket-2 pause below; the wave cannot close green without it
gate: "895/0 → 913/1 (fresh XDG scratch; the 1 is the bucket-2 row this report pauses on)"
---

# S19-B1 report — directional armour & breach malfunctions

## Result
All five seams implemented to 09 §3.3's 2026-09-26 pin (P1-P8): four `hull_max/4`
pools with `hull == sum(pools)` (proportional `set_hull`), P2 routing + P3's ×1.6
before the shield-first absorb + P6's even spill in `damage()`, `player_ship.gd`'s
three derived malfunctions (P4 drift/flicker, P5 turn clip), `repairs.gd`'s
`pools(hull_max)` restore with the fee law untouched, and the four per-quadrant rows
in both panes. `tests/test_s19_quadrants.gd` adds 19 rows, all green in isolation.
After-gate **913 passed / 1 failed**; the one failure is a pre-existing row the pin
moves (bucket-2 pause, below) — no other suite's count moved.

## Pre-grep (before any edit) — every candidate row, its route, its measured verdict
| Row (`file:line`) | Route | Verdict |
|---|---|---|
| `test_engine2_damage.gd:136-144` | real ctx, direction `±PI` (astern), shielded `PlayerState` | **MOVES (bucket 2).** P3 multiplies before the absorb: the shield drops 144, not 90. Left untouched. |
| `test_engine2_damage.gd:112-159, 305-316, 333-377` | sink arities, direction-less absorb, regen | unchanged — every hit is `{}`/0.0 → prow ×1.0 |
| `test_engine2_pools.gd:249-259` | `damage(10/25, …, {direction: &"stern"})` | unchanged — a string is not a bearing, reads 0.0 |
| `test_engine_c3_flight_decay.gd`, `test_flight_feel_g1.gd`, `test_s2_6_flight.gd` | flight law, fresh fixtures | unchanged — no breach, so the turn scale is 1.0 and no roll consumes the RNG |
| `test_p1_repairs.gd:48-147` | fee/repair rows | unchanged — fee law untouched; the success dict gains one key |
| `test_combat_repair_c5.gd` | "in-flight repair" (brief's label) | no such row exists there (grep: no repair); the Embers rows are NPC-sink rows in `test_s7_weapon_affixes.gd` → unchanged |
| `test_d6_status.gd:330-458, 670-694` | `module_rows()`/grid/footer | unchanged — pool rows are new nodes; `_rows` still reads 7/6/0 as pinned |
| `probe_c2_weapons.gd:118` | 3-arg sink stub | probe-only, never in the gate; unchanged |
| `test_engine2_fixes.gd:300-407`, `test_engine2_wiring.gd:369` | `_deliver`/`_hit_body`/`_detonate`, NPC hit marker | unchanged — every call passes the target's own position → direction 0.0 |
| `test_s6_travel.gd:424-459`, `test_s7_suffixes.gd:151-183` | `set_hull` seeds, Leech heals | unchanged — `hull` stays the clamped request; pools scale proportionally |
| `test_s8_launch_ammo.gd:461-487` | repairs-panel rows by key | unchanged — new keys only |

## Per-AC measured values (suite evidence prints, fresh scratch store)
- **AC1** 13 routing cases: `d=0 → prow 150/250 hull 900`; `±π/4 → prow`; `π/4+0.01` and
  `π/2 → starboard 150`; `3π/4−0.01 → starboard 90` (landed 160); `3π/4, π, −π, −3π/4 →
  stern 90`; `−3π/4+0.01, −π/2, −π/4−0.01 → port`. Missing/zero/string → prow, shield −100.
- **AC2** inside the rear arc (`5π/9`, `π`, `−π`) shield `600 → 440`; just outside
  (`5π/9−0.001`, `π/4`, `0`) `600 → 500`; `62.5 @ −π` empties a 100 shield, hull untouched.
- **AC3** `400 @ 0` → `prow 0.000, others 200.000, hull 600.000`; direction-less `300`
  → others `233.333`; sum invariant re-asserted after every step of a 4-hit + heal
  sequence; a heal cannot lift a breached pool; overkill → hull 0, `died` once,
  `hull_changed` once per landed hit.
- **AC4** drift seed 20260926: `−21214.285714` at frames 8 and 16 = 15 % of the fixture's
  `141428.571429` peak, sign −1 replayed by the twin RNG; flicker seed 20260926:
  `31 of 200` thrust ticks swallowed, 0 on a full hull and 0 on an idle stick; turn clip
  exactly ×0.5 toward the breached flank; `state.setup()` ends both effects.
- **AC5** repair: fee 500, credits 9500, `pools = [250.0 ×4]`; a state reseeded from the
  repaired sum carries four even pools. Panel lines `prow/stern/port/starboard 50 / 250`
  with the five shipped rows identical; status rows `PROW 100 / 250, STERN 120 / 250,
  PORT 130 / 250, STBD 140 / 250` with the fit rows unmoved.
- **AC6** consts asserted against the amendment; the four forbidden files' SHA-256s
  unchanged (`5cabf3d9…6269`, `de8596b1…81be`, `e39440bf…5d22`, `fcdc549f…8279`).

## P1-P8 const table (value → one-line reversal; no other tunable added)
| Pin | Const (`file`) | Value | Reversal |
|---|---|---|---|
| P1 | `PlayerState.QUADRANT_COUNT` | 4 (pools of `hull_max/4`) | plating-only pools |
| P2 | `PlayerState.PROW_ARC` / `REAR_ARC` | `π/4` (45°) / `3π/4` (135°) | any other arc map |
| P3 | `PlayerState.STERN_VULN_ARC` / `STERN_DAMAGE_MULT` | `5π/9` (100° = the 160° arc) / `1.6` | `2π/3` / `1.0` (hull-side only) |
| P4 | `PlayerShip.BREACH_DRIFT_FRACTION` / `BREACH_DRIFT_INTERVAL` | `0.15` / `2.0 s` | any fraction / any interval |
| P4-prow | `PlayerShip.BREACH_FLICKER_CHANCE` | `0.15` | any fraction |
| P4-seed | `PlayerShip.BREACH_SEED` | `20260926` (determinism seam, not a spec number) | draw from the global RNG |
| P5 | `PlayerShip.BREACH_TURN_CLIP` | `0.5` | any fraction |
| P6 | (no const; divisor `QUADRANT_COUNT − 1`) | remainder / 3, clamped | proportional-to-capacity, or drop at the breach |
| P7 | (no const; `NpcShip` untouched) | player-side only | mirror the routing into `NpcShip` |
| P8 | `Repairs.pools`, `QUADRANT_ROWS`/`QUADRANT_ROW_FORMAT` (screen), `QUADRANT_KEYS` (panel) | four rows/lines at `hull_max/4` | drop the rows/lines |

Non-tunable names added: `QUADRANT_PROWS/STERN/PORT/STARBOARD`, `QUADRANTS`,
`PlayerState.CTX_DIRECTION`, `Repairs.State` (preload only).

## Deviations from SLICE.md / the brief
1. **Bucket-2 pause — `test_engine2_damage.gd:136-144` must move.** Under P3 its astern
   90-hit drops the shield by 144, so `SHIELD_MAX - 90.0` is stale; the brief §3 says
   "unchanged". Reported, not edited. The developer/designer session owns the fix: move
   the row onto the tests-that-moves list and update its number (or re-pin the ×1.6 to
   hull-side, P3's own named reversal). Until then the gate's one red is this row.
2. **`repair()` and the pools** — pools are flight state, so the station's half of
   "restores all four pools" is the reported `pools(hull_max)` plus the full sum the next
   launch seeds evenly. Reversal: persist pools (save-schema wave).
3. **Status-screen feed** — `hud.gd` is frozen/out of my file set, so `set_quadrants`
   has no production caller; unfed rows read the hull figure's even split (P1's seed).
   Reversal: the HUD push line when that contract opens.
4. **Non-numeric directions read 0.0** (the pin says "missing or zero"): a string/null is
   read the same way, the only reading that neither scatters nor moves that row.
5. **`quadrant_for` is static** (a pure map), reachable without a state.
6. **Baseline 887/0 in the brief is stale** — measured fresh-scratch baseline is 895/0.

## Evidence
- Pre-grep + hashes captured before editing (`/tmp/s19_pregrep.txt`); forbidden SHA-256s
  above, still identical after the wave.
- Gate before / after (fresh `XDG_DATA_HOME`, `--quit-after 1200`):
  `[SUMMARY] passed=895 failed=0` → `[SUMMARY] passed=913 failed=1` (the bucket-2 row);
  895 + 19 new − 1 moved = 914 accounted. Logs `/tmp/s19_gate_before.log`,
  `/tmp/s19_gate_after2.log`.
- A first after-run read `912/2`: my suite recaptured its profile snapshot per install,
  so its teardown re-installed a stored fit and `test_s2_6_gate_hygiene` read it at
  launch. Fixed inside the suite (capture once); the scoped re-run
  `--suite=test_s19_quadrants --suite=test_s2_6_gate_hygiene` is 22/0.
- Suite evidence prints (scoped run): route table, rear-arc shields, spill arithmetic,
  `flicker seed=20260926: swallowed=31 of 200`, `drift torque=−21214.285714
  peak=141428.571429`, repair `fee=500 pools=[250.0 ×4]`, both readout line sets.

## Files touched
- `game/player_state.gd` — pools, P1-P3/P6 routing + spill, sum invariant, readers
- `game/player_ship.gd` — P4 drift/flicker, P5 clip, breach read-backs, seed seam
- `game/repairs.gd` — `pools()` restore vector beside the fee law
- `ui/station/repairs_panel.gd` — four per-quadrant report lines
- `ui/hud/ship_status_screen.gd` — four append-only pool rows + `set_quadrants`/`pool_rows`
- `tests/test_s19_quadrants.gd` — new, 19 rows, AC1-AC6

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| Astern-shield row re-pinned (144 not 90) | bucket-2, developer session | `tests/test_engine2_damage.gd:136-144`; brief §3 list |
