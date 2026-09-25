# S12 — Ore budget: the two K0 probes (wave brief)

**Wave:** S12 (code lane, item 19 of `dispatch_coder.md`)
**Slice folder:** `.agents/gen/slices/S12-ore-budget/`
**Baseline:** gate **807/0**; `python3 staging/verify_wave.py snapshot --name s12_start` before the first dispatch.
**Deliverable:** two measured number tables — not a behaviour change.

**Errata 2026-09-25 (close-out; R1's S12-K0/F1 + S12-K1/F1, both bucket 2):**
the 807/0 baseline pin above predates D11's `test_d11_station.gd` — the measured
close-out gate is **812/0** (the +5 attributed to the parallel D11 lane; this
wave moved no row), and §4's `shot_damage(&"w_cannon")`/`interval_of(&"w_cannon")`
spelling is not callable as written (`row_of` keys `FAMILIES` by family id,
`weapons.gd:2325`); the callable route is `WeaponsScript.weapon_id(&"w_cannon")`
→ `&"cannon"`, which is what both probes print.

## 1. The law to read in order

1. `slices/S12-ore-budget/SLICE.md` — goal, scope, AC1–AC5, worker file sets.
2. `docs/gameplay/01_economy_core.md` §5.6 — the owner's rule and the amendment
   this wave produces the numbers for.
3. `docs/gameplay/02_minerals.md` §5 and §5.1 — the yield rolls and Rule A/Rule B.
4. `docs/CONTRACTS.md` **§5 lines 345-375 only** (the cleaving and gun-work pins
   the probes measure) and **§9** (the universal gate). Never read CONTRACTS
   whole — locate with `rg -n '^## §' docs/CONTRACTS.md`, then read the range.
5. `vajb-orbit/tests/probe_s2_6_burst.gd` — the house probe shape: `extends
   SceneTree`, a `[TAG]` line per row, `done failures=N` last, fixed seeds, no
   frame awaited, nothing simulated.

## 2. The owner's request, verbatim

> "I want it to be able to shoot asteroids but mining should always be more
> profitable. also make a note that asteroids could be bigger with more yield,
> in bigger clusters, maybe even some asteroid fields?"

Ruled into the docs as `01 §5.6` (the invariant) and `02 §5.1` (Rule A: no method
mints ore; Rule B: the scale rows). Every number in both is **proposed** and
owner-tick-gated. **This wave does not implement them.** It measures the shipped
tree so the ticks can be made against evidence — the flag should not be reasoned
about twice.

## 3. What is already measured (do not re-derive by argument)

- `GUN_CHIP_RATE := 0.10` (`game/weapons.gd:216`), applied per bolt as
  `apply_work(damage * chip * damage_mult)` (`game/projectile.gd:769-773`) and
  per frame on the beam path (`game/weapons.gd:1275`).
- The bolt's damage is `shot_damage(&"w_cannon") = dps × interval` = 45 × 0.6
  = **27** (`game/weapons.gd:2414-2422`), cadence `interval_of` = `burst_on +
  burst_off` = 0.6 s for the cannon (`:127-128`, `:2395-2410`).
- `WORK_PER_UNIT := 1.0` (`game/asteroid.gd:56`); a rock converts work to whole
  ore units and emits `cracked` synchronously (`:248-259`, `:315-320`).
- `cleaves()` returns `_bore_ore` — **whether the rock was rolled with ore at
  setup**, not what it still holds (`game/asteroid.gd:237`, `:293-294`).
- A cleave gives every fragment `_rolled_yield(tier)` — a **fresh** 02 §5 roll
  (`game/asteroid_field.gd:224-229`, `:365-373`); a Small's crack instead bursts
  `PICKUP_BURST` (1-2) pickups of 1 unit each (`game/asteroid.gd:107-112`,
  `game/asteroid_field.gd:400-420`).
- `TIER_BASE_YIELD` 6/5/4/3 with `YIELD_VARIANCE` 0.5-1.5
  (`game/mineral_catalog.gd:281-289`), read through `roll_yield`
  (`:378-380`).
- `MINE_CYCLE := 1.2` (`game/mining_laser.gd:34`); one cycle = `WORK_PER_UNIT`
  in, one pickup per returned unit (`:195-202`).
- Live-fire observation (5 fps session, therefore suggestive only):
  `.agents/gen/session_2026-09-25_findings.md` §2 F6 — 78 projectile nodes at
  once, no ore counted.
- Arithmetic in the docs, **to be confirmed or refuted by these probes**:
  3 cannons ≈ 13.5 ore-units/s of depletion against the laser's 0.83 units/s of
  extraction; one fully worked T1 Large rock ≈ 16.75 rocks and ≈100 ore units
  realised against its own 6.

## 4. The pinned measurement contract (both probes; this fixes every ambiguity)

Neither probe may re-declare a number. Read each from its owner:

| Need | Read from |
|---|---|
| chip rate | `WeaponsScript.GUN_CHIP_RATE` |
| bolt damage, cadence, burst | `WeaponsScript.shot_damage(&"w_cannon")`, `interval_of(&"w_cannon")`, `row_of(&"w_cannon")[&"burst_on"]` / `[&"burst_off"]` |
| work per unit | `AsteroidScript.WORK_PER_UNIT` |
| mine cycle | `MiningLaserScript.MINE_CYCLE` |
| tier base yield, variance | `MineralCatalogScript.TIER_BASE_YIELD`, `YIELD_VARIANCE_MIN` / `MAX` |
| fragment split, pickup burst | `AsteroidScript.FRAGMENT_SPLIT`, `PICKUP_BURST` |
| ore id | `MineralCatalogScript.ore_id(mineral_id)` |
| pickup group / fields | `FieldScript.PICKUP_GROUP`, `Pickup.item_id`, `Pickup.amount` |
| a hold | `ShipFit.HULLS[&"ship_vanguard"][&"cargo"]` (and the max over `HULLS`) |
| W cells in one rack | `ShipFit.HULLS[hull][&"weapons"]`, maxed over `HULLS` — 7 for `ship_destroyer`, which is also `WeaponsScript.GROUPS_MAX`'s rack ceiling; read both and print them, do not assume they agree |
| rocket/mine left alone | `WeaponsScript.interval_of` reads 1.2 / 0.0 — print them, do not model them |

Pinned field (identical in both probes, and in R1's replay):

```gdscript
const FIELD_SEED := 12061
const FIELD_ROCKS := 6          # the field's own minimum (FIELD_ROCKS_MIN), so
                                # the cleave cascade is the only variable
const FIELD_CONFIG := {
    &"tier_weights": {1: 100},  # a T1 field: the owner's case and 02 §5.1's
    &"rocks": FIELD_ROCKS,
    &"seed": FIELD_SEED,
}
```

Pinned work loop (one rock at a time, in `field.rocks()` order; re-read
`rocks()` after every call because a crack frees the rock and adds fragments):

```gdscript
# LASER LEG — mirrors game/mining_laser.gd:195-202 line for line:
#   apply WORK_PER_UNIT, one pickup per returned unit.
var units := int(rock.call(&"apply_work", AsteroidScript.WORK_PER_UNIT))
delivered_units += units          # 1 pickup per unit; do not spawn nodes
elapsed_seconds += MiningLaserScript.MINE_CYCLE

# GUN LEG — mirrors game/projectile.gd:769-773 for the depletion and
# game/asteroid_field.gd:400-420 for the delivery:
#   a chip's returns are DISCARDED; only a Small's crack pays.
rock.call(&"apply_work", WeaponsScript.shot_damage(&"w_cannon") * WeaponsScript.GUN_CHIP_RATE)
# A rack of `barrels` same-family cannon releases its whole volley once per
# `interval_of`, so one shot's share of the wall clock is interval / barrels —
# i.e. `barrels / interval_of` shots per second.
elapsed_seconds += WeaponsScript.interval_of(&"w_cannon") / float(barrels)
# delivered ore = the field's own burst pickups, summed:
for child in field.get_children():
    if child.is_in_group(FieldScript.PICKUP_GROUP):
        delivered_units += int(child.get(&"amount"))
```

Shots-per-second rule (pin it, print it): **`barrels / interval_of(&"w_cannon")`**
— for the cannon the burst window is neutral because
`interval == burst_on + burst_off`; print all three so the reviewer can check the
claim rather than trust it.

Legs to measure, in both probes (the field is re-seeded per leg so each leg
starts from the same rocks):

| Leg | Barrels | Meaning |
|---|---|---|
| `LASER` | 1 | the mining laser, `MINE_CYCLE` per unit |
| `GUN3` | 3 | the owner's reported case: one rack, three cannons |
| `GUNMAX` | the max W cells over `ShipFit.HULLS` (7, `ship_destroyer`) | firepower's ceiling; print the barrel count actually used |

Delivered ore, definitionally:

- `LASER` realises **the sum of `apply_work`'s returns** (one pickup per unit,
  `mining_laser.gd:199-201`).
- `GUN*` realises **the sum of `amount` over the field's `pickup` children**,
  because a chip's returns are discarded (`projectile.gd:767-768`) and the
  Small-end burst is the only delivery.

Bounds: `MAX_STEPS := 200000` per leg and `MAX_SECONDS := 100000.0`; hitting
either is a **failure row**, never a silent truncation.

## 5. Worker table

| ID | role | `VAJB_WORKER_FILES` | deliverable |
|---|---|---|---|
| S12-K0 | coder/probe | `vajb-orbit/tests/probe_s12_field_budget.gd` | `S12-K0_report.md` — the budget table: Σ spawn yield, Σ delivered units, out/in factor, rocks spawned and steps taken, per leg and per tier (T1 and T3) |
| S12-K1 | coder/probe | `vajb-orbit/tests/probe_s12_rock_rate.gd` | `S12-K1_report.md` — the rate table: delivered units/s, delivered units/rock, depletion seconds, the mining:gunning ratio per leg, plus one rock's units-in vs units-out |
| S12-R1 | reviewer | `vajb-orbit/tests/probe_s12_r1_constants.gd`, its review path | `S12-R1_review.md` — byte-identical replay of both probes at the baseline commit, every printed constant re-read from its owner, the AC4 grep, findings by tier |

The reviewer may add `probe_s12_r1_constants.gd` **only** to re-read the
constants independently; if it does not need it, it says so in the review and
creates nothing.

## 6. Run order

`S12-K0 ∥ S12-K1` (disjoint files) → `S12-R1`. Then a fixer pass only if the
review leaves HIGH or MED — and a fixer for a *probe* is limited to the probe
file, never a production file.

## 7. Tests that move

**None.** Both probes are standalone `--script` drivers outside the gate
(`res://tests/headless_runner.tscn` runs the `test_*.gd` suites only), so the
gate reads **807/0** before and after. A wave that moves a gate row has left the
brief. If Godot mints `.uid` sidecars for the new probes, they belong in the
wave-boundary commit (L177/L179 precedent).

## 8. Hard rules

- **No production file.** `game/*.gd`, `ui/**`, `docs/**` and `addons/**` are
  forbidden to every worker in this wave; `verify_wave.py verify` runs with
  `--forbidden` on `vajb-orbit/game/asteroid.gd`, `game/asteroid_field.gd`,
  `game/weapons.gd`, `game/projectile.gd`, `game/mineral_catalog.gd`,
  `game/mining_laser.gd`.
- **No re-declared numbers** (AC4). A hardcoded 0.10, 1.2, 6/5/4/3, 45, 0.6 or
  40 is a failure even if it agrees with the tree today.
- **Read-only.** Never write the profile, never touch a live `user://`; run
  every Godot command with its own `XDG_DATA_HOME` scratch store.
- **Deterministic.** Fixed seeds, no `randf()` outside the field's own RNG, no
  frame awaited, prints byte-identical across runs. Probes that consult the
  wall clock or the physics world are out.
- **Bounded.** Every Godot run carries `--quit-after` or is a self-quitting
  `--script`; never leave a command in the background.
- **Report what the tree does**, never what `18_engine_spec.md` says it should
  do. A disagreement between the two is a report row, not an edit.
- Every claim in a report carries `file:line` or a printed line; reports ≤120
  lines, reviews ≤150.

## 9. Staged / deferred

- The caps and the fragment-share rule (`FRAGMENT_CORE_SHARE`, `GUN_BURST_SHARE`)
  — a later wave, after the ticks.
- Rule B's scale rows (size spread, veins, field count, hold ladder) — later,
  and the T4 tier-curve question (§5.1) is explicitly *not* resolved by these
  probes.
- The live-fire confirmation (a real `project_run` session measuring a hold fill
  end to end) — the orchestrator's, not a worker's, and only if the owner wants
  a second source.

## 10. Owner tick list (the decisions these numbers exist to inform)

- [ ] `GUN_BURST_SHARE` — the share of a rock's own yield a gun-cracked rock may
      realise (`01 §5.6`, proposed 0.10).
- [ ] `FRAGMENT_CORE_SHARE` — 0.0 (fragments are debris) or 0.25 (the crack hands
      the pieces a quarter) (`02 §5.1` Rule A).
- [ ] Rule B's scale rows — size spread, veins, field count — or the
      gating-the-deep-tiers variant (`02 §5.1` Rule B).
- [ ] The ⅓-of-hold rule and the `18_engine_spec.md` §6/§13/§17 wording (the last
      is owner-locked and cannot be ticked by any worker or by this doc).

## 11. Close-out

1. Gate twice on fresh scratch stores — **807/0**, hermetic, both times.
2. `staging/verify_wave.py verify --baseline s12_start` with the `--forbidden`
   list above and `--expect-reports` for the three reports; every touched file
   must be a probe or a report.
3. Both probes re-run by hand, byte-identical output pasted (trimmed) into R1's
   review.
4. Append the wave's one-line outcome + the number tables to
   `.agents/gen/MASTER_REPORT.md` §6; leave S12 as a queue line in
   `dispatch_coder.md` (status DONE) and one clause in the WAVEBOARD header.
5. Wave-boundary commit, then hand the number tables to the owner with the
   §10 ticks. **Do not implement the ticked numbers in this wave.**
