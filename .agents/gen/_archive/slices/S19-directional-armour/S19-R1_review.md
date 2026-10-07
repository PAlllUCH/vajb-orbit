---
slice: S19
reviewer: S19-R1
verdict: blocked (1 HIGH remains, bucket 2: the §3 existing-rows list, no code revert)
gate: "895/0 (replayed baseline) → 913/1 (wave)"
---

# S19-R1 review — directional armour & breach malfunctions

Diffed against `docs/gameplay/09_ship_slots_modules.md` §3.3's **2026-09-26 amendment**
(P1–P8 with reversals) and `01_economy_core.md` §6's of the same date, never against the
brief. Re-measured by `vajb-orbit/tests/probe_s19r1_review.gd` (+`.tscn`), 33 checks, all
green, headless, self-quitting, `XDG_DATA_HOME=$(mktemp -d)` (L229/T-93); every number
below is that probe's own print, not the builder's.

## Findings
| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| S19-B1/F1 | **HIGH** (bucket 2) | `tests/test_engine2_damage.gd:136-144`; `S19_BRIEF.md` §3 | The gate's only moved row is **off §3's existing-rows list**. That row builds a real astern `ctx.direction` (`-PI`), so P3's ×1.6 drops its 600 shield by **144**, not 90 — route per the amendment, stale number per the list. The implementer correctly left it untouched. Per-suite diff, baseline replayed vs the wave: `test_engine2_damage.gd` 20/0 → 19/1, every other suite identical (895/0 → 913/1 = +19 new suite rows, −1 moved). Remedy is the developer/designer session's list edit (or P3's named hull-side reversal), never a revert; recorded as **L240**. | Developer/designer session |
| S19-B1/F2 | LOW | `ui/hud/ship_status_screen.gd:843`; feed site `ui/hud/hud.gd:835-840` | The four pool rows have **no production feed**: `set_quadrants` has zero callers outside the suite/probe and `hud.gd` is outside the wave's file set, so in the live game the rows always print the hull figure's even split (measured: hull 812 → `PROW 203 / 250`) and would read `250 / 250` on a breached prow. Disclosed by B1 (deviation 3); the one-line cure is the existing `_push_status()`. The panel's four lines carry the same caveat and cannot be cured (flight state, disclosed as deviation 2). **L241**, owner tick T7. | owner / next HUD wave |
| S19-B1/F3 | LOW | `game/player_state.gd` `_charge_quadrant` | The even-split spill's capacity clamp **under-lands** when the neighbours are part-empty: a 400 hit on `[200,100,0,0]` (hull 300) ends at `[0,33.333,0,0]`, hull **33.333** — landed 266.667 of 400 — because the clamped third is not re-offered to a pool with room (P6's proportional reversal would land 300 and kill). Invariants hold; balance consequence only. **L242**, owner tick T5. | owner tick T5 |
| S19-B1/F4 | LOW | `game/player_state.gd` `CTX_DIRECTION`; `game/damage.gd:56` | The item-5 `direction` key is now spelled in two files with **nothing asserting they agree**; a drift would make every real hit read 0.0 (prow, ×1.0) with the gate staying green. One line in the AC6 row cures it. **L243**. | next `player_state.gd` owner |
| S19-B1/F5 | LOW (pre-existing) | `ui/station/repairs_panel.gd` `_refresh_all` vs `game/repairs.gd` `fee` | The panel's `MISSING` row and its `FEE` row read two shield figures (resolved fit vs catalogue): the measured fixture prints `SHIELD 300 / 800`, `MISSING 800 HULL · 500 SHIELD` and `FEE 500 CR` (a 300-shortfall fee). Present at HEAD (`_pool_maxima` + `Repairs.fee` both pre-date S19); the wave's four new lines now split the resolved hull figure one row above it. **L244**. | next repairs owner |
| S19-B1/F6 | LOW (harness) | `staging/verify_wave.py:144` | Directory entries in `--forbidden` are **inert** (exact string membership), so the close-out's `docs/`, `vajb-orbit/addons/` and `vajb-orbit/autoload/` protect nothing. Measured on this tree: `--forbidden docs/CONTRACTS.md vajb-orbit/tests/test_s19_quadrants.gd` reports both; `--forbidden docs/ vajb-orbit/tests/` reports `"problems": []`. The exact-path seals work. S19 unaffected (this review's CONTRACTS write is mandated), a future `autoload/` edit would pass unflagged. **L245**. | next tooling owner |

## AC-by-AC re-measurement (probe prints)
- **AC1** `quadrant_for` over **1441 bearings** (`-π…+π`): **0 mismatches** against a
  hand-derived arc map; 13 named boundaries end-to-end through `damage`: `0/±π/4 → prow
  (40)`, `π/4+ε, π/2, 3π/4−ε → starboard (40/40/64)`, `±3π/4, ±π → stern (64)`,
  `−3π/4+ε, −π/2, −π/4−ε → port`; `{}`, `0.0`, `null`, `&"stern"` all read prow ×1.0
  (hull −100, shield −100).
- **AC2** inside the 160° arc (`5π/9`, `±π`, `±3π/4`) shield `600 → 440`; outside
  (`5π/9−0.001`, `π/4`, `0`, `−π/4`, `−π/2`) `600 → 500`; **before** the absorb proven
  by `62.5 @ −π` emptying a 100 shield whole (hull untouched); a 40-point shield loses a
  100-point rear hit's overshoot with no pool movement (no carry-over).
- **AC3** fresh pools `4 × 250`; `400 @ 0` → `[0,200,200,200]` hull 600; then `300 @ 0` →
  `[0,100,100,100]` hull 300; `5000 @ 0` → hull 0 / pools 0; `sum(pools) == hull` after
  every step of a **40-hit seeded mixed sequence**; overkill: `died` **1 then 1**,
  `hull_changed` **1 then 2**; a shield-absorbed hit emits nothing on the hull channel.
- **AC4** fresh hull: 16 frames → torque `0`, 60 thrust ticks → 0 force-dead, 0 ignored.
  Stern breach, seeded 20260926: drifts `[-21214.285714, -21214.285714, +21214.285714]` at
  frames 8/16/24 (the 2.0 s cadence, **0 off-cadence**), magnitude = **15 % of
  141428.571429**, each sign replayed by a twin RNG;
  `armour_stern = 62.5` → 16 frames of `0` (derived clear, no flag), and the clock resets
  (7 quiet frames then the drift at 2.0 s). Prow breach: `31 of 200` seeded thrust ticks
  swallowed, idle stick rolls nothing, 60 strafe ticks swallow 11 (the strafe is thrust).
  Flank clip exactly **×0.5 towards** the breached side, class rate away; a stern breach
  leaves both turns at the healthy `±141428.5714`. `setup()` clears both effects.
- **AC5** fee: the doc's own example `(800/2)+(300/3) = 500 CR`, shield-alone ≥90 % exempt
  (measured 0 CR at 93 %); `repair()` restores `1000/600`, spends exactly 500, reports
  `pools = [250 ×4]`; `Repairs.fee` and the panel's `REPORT_ROWS` are **textually identical /
  append-only** against the HEAD copy. Panel: rows `9` in the shipped order with
  `hull 200 / 1000`, `shield 300 / 800`, `missing 800 HULL · 500 SHIELD`, `fee 500 CR`, four
  lines `50 / 250`. Status screen: `pool_rows()` 4 entries in the pinned order, fed
  `PROW 100 / 250 … STBD 140 / 250`, unfed the even split `PROW 203 / 250`; fit rows
  `4 → 4` and the footer identical across the new push.
- **AC6** the nine P1–P8 consts read at the amendment's values; the four forbidden files
  re-hashed **at runtime** unchanged (`5cabf3d9…6269`, `de8596b1…81be`, `e39440bf…5d22`,
  `fcdc549f…8279`, also identical to `git show HEAD:`).

## Docs written (reviewer set)
`docs/CONTRACTS.md` **§8.1** (the S19 block: pools + the sum invariant, P1–P3/P6 consts,
`quadrant_for`/`pool_of`/`breached`, `set_hull`'s redistribution, `PlayerShip`'s four
breach consts and both test seams, `Repairs.pools` + the `&"pools"` key; the stale
"no-op until slice 3" line updated), **§18** (the four append-only status rows and their
unfed caveat), **§9** (the S19 expected-count paragraph: 895/0 baseline → 913/1, the one
unlisted row, the forbidden hashes) and **§10** (v0.34). LOW rows **L240–L245** read and
written at the next free ids; the next free ticket stays **T-94**.

## Gate
- Baseline, **byte-identical replay** in a reconstructed HEAD tree (`/tmp/s19base_proj`:
  live binaries, HEAD texts of the five changed files, the new suite removed):
  **`passed=895 failed=0`**, exit 0, 77 suites.
- Wave, fresh scratch store: **`passed=913 failed=1`**, exit 1; the only red is F1's row.
- No silent aborts: `test_s19_quadrants.gd` has 19 `func test_`, the gate prints 19
  `[PASS]`/0 `[FAIL]` for it, and its 40-line log window carries zero `SCRIPT ERROR`
  markers (the S18-F1/L230 class checked, `test_weapon_fx_f4.gd`'s known dead guard is
  L237's).
- `verify_wave.py verify --baseline s19_start` reports `"problems": []` with the four
  forbidden code files given as exact paths (F6/L245 records that the command's directory
  entries are inert). Its file list is not all S19's: the concurrent D14 design lane's
  slice folder and `dispatch_designer.md` (committed in `cfd5bed`, the review's baseline
  commit) and `staging/compare/**` (untracked) appear too; nothing in them was touched by
  this review.
