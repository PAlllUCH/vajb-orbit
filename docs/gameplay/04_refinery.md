# 04 — Refinery: Ore Processing at the Station

**Status:** Ready to code.
**Depends on:** 01 (sink K3), 02 (mineral catalogue, units).
**Consumed by:** 05 (ingot supply), 07 (ingot recipes).

---

## 1. What refining is for

Raw ore is bulky; ingots triple its value density. The refinery is the
station machine that converts 3 ore into 1 ingot, and it exists to create a
**decision, not a chore**:

- **Refine everything** → maximum value per hold unit, costs a fee and a
  little time, best when the trip continues into better sectors.
- **Sell raw** → instant credits with no fee, 40 % baseline (01 §3, S2),
  best when the player is broke, in a hurry, or carrying worthless-tier ore.

The math below is tuned so that neither answer is always right (02 §4).

## 2. The conversion rule

**3 units of one ore → 1 ingot of that mineral.**

- Input: 3 ore units of `mineral_X` (3 cargo units).
- Output: 1 `ingot_X` (1 cargo unit).
- Fee: **5 CR per ore unit consumed**, i.e. **15 CR per conversion**
  (01 §3, K3).
- Output value: `ingot_value` from 02 §2 (= 3.6 × ore baseline). Examples:
  - Iron: 3 ore = 54 CR baseline raw; 1 ingot = 65 CR − 15 fee = **50 CR**.
    Refining Tier-I ore for sale alone is a wash (as designed — 02 §4):
    common ore is worth selling raw or banking for crafting.
  - Gold: 3 ore = 330 raw; 1 ingot = 395 − 15 fee = **380 CR, +15 %**.
    And the hold effect is universal: 3 units of hold space become 1, so a
    full 40-unit hold sells as 13 ingots where raw ore would have needed
    three trips. **The refinery's true product is hold-space, secondarily
    the +20 % refine bonus at tier II+.**
- Partial stacks: the refinery converts in whole conversions only; leftover
  ore (1–3 units) stays in the hold untouched.
- **Batch operation.** The player picks a mineral and a quantity of
  conversions ("refine 6× Iron ore"); the fee is charged once for the whole
  batch. Nothing is partial-failure: either the whole batch runs (verified
  → charge → convert) or nothing does (01 §7).

## 3. Fee schedule and yield

| Rule | Value |
|------|-------|
| Fee per ore unit | 5 CR |
| Fee per conversion (3 ore) | 15 CR |
| Yield | 1 ingot per conversion, always (no randomness) |
| Failure chance | none in v1 |

Refining is deterministic on purpose: the refinery is a fee-for-service
machine, not a gamble. RNG belongs in asteroid yields (02 §5) and drops
(06), where it creates moments; a failed refine would only create resentment
at the station. (If later design wants risk, it belongs in *sector access*,
not in the refinery.)

## 4. What refining is *not*

- **It is not a quest gate.** Refining is available immediately, from the
  moment the station screen exists.
- **It is not the only consumer of ore.** 07's crafting recipes consume ore
  directly for some early items, so low-tier ore has a use beyond sale.
- **It is not instant in-fiction, but it is instant in-play.** No timers, no
  waiting. Time costs are a mobile/free-to-play pattern, not this game's.

## 5. Interaction contract (for the coder and the UI amendment)

The refinery panel is a **new station module** (rail entry between
OUTFITTING and SHIPYARD; the full pixel spec is an amendment to
`STATION_HUB.md` written when the panel is designed for real). Contract:

- Left: the player's current ore stacks (mineral name, ore count, per-unit
  ingot value, tier tint). Rows exist only for minerals with ≥ 3 ore.
- Right: selected mineral → conversion count stepper (min 1, max
  `floor(ore_qty / 3)`) → running totals (ore in, ingots out, fee) →
  REFINERY ALL / REFINE N / CANCEL.
- **REFINERY ALL** converts every convertible stack in one confirmed action.
- On confirm: verify fee (`spend(fee)`), then `remove_cargo(mineral_id, 4n)`
  then `add_cargo(ingot_id, n)` — in that order, all-or-nothing (01 §7).
- The panel emits the existing `profile_changed(&"cargo")` /
  `(&"credits")` flows; no new signals.
- Numbers shown come only from the mineral catalogue (02 §3) plus the fee
  constant; the panel hardcodes no prices.

## 6. Balance reference

With the 01 §5 session shape (a full 40-unit hold of mixed T1/T2 ore):

- Convertible conversions ≈ 13 → 13 ingots, ≈195 CR fees, hold empties
  into ~13 ingots with 1 unit free.
- The fee is ≈10 % of gross mining income — enough to notice, small enough
  to never feel like a tax on progress.
- Tuning lever order if the refinery is too weak/strong: ore value (02 §4),
  then conversion ratio (4→1), then fee. Change one at a time and re-check
  the 01 §5.3 net-income targets.

---

## 7. 2026-10-05 amendment — refining takes time: jobs, slots, inventory (owner request; wave S34)

Owner request verbatim: "refinery needs to take time to refine, different per
resource. maybe make it so that it has slots (upgradable) and inventory (for
output and input)".

This **supersedes §4's "instant in-play" bullet** — the owner's own request
supersedes it (escalation bucket 3 discharged at the request) — and amends
§2's batch rule and §5's action rows. §1's decision framing, §2's 3:1 rule,
and §3 in full (fee schedule, deterministic no-failure) stand: refining now
costs *time*, never RNG.

### 7.1 The model

- **Job.** A confirmed batch becomes one job `{mineral_id, conversions}` on
  one slot; wall duration = `conversions × RESOURCE_SECONDS(mineral)`. A job
  never fails and never yields differently (§3 stands).
- **RESOURCE_SECONDS (R1).** `clamp(round(ingot_value_cr / 10), 10, 60)`
  seconds per conversion, read from 02 §2's ingot value — every resource
  differs by its own value (Iron ≈ 10 s, Gold ≈ 40 s per conversion).
- **Slots (R3/R4).** `refinery_slots` jobs run in parallel: **2** base,
  bought +1 at the panel for **3,000 CR flat**, hardcap **5**. The upgrade
  persists on the profile.
- **Inventory (R5).** Input ore lives in `refinery_input` (cap **60** ore
  units), output ingots in `refinery_output` (cap **60** ingot units). `LOAD`
  transfers hold → input; `COLLECT ALL` transfers output → hold, space
  permitting (overflow stays, R8). Transfers move no credits; 01 §7's
  verify → take → pay → emit order governs the fee and the conversions.
- **Queue (R7).** `QUEUE N` (was `REFINE N`) starts a job on a free slot or
  appends to the FIFO pending queue; `QUEUE ALL` (was `REFINERY ALL`) queues
  one job per convertible mineral. `CANCEL` drops a pending or running job,
  refunds its fee and returns its ore to input.
- **Time (R6).** Jobs carry `ready_at` (unix seconds,
  `Time.get_unix_time_from_system`); the profile settles finished jobs
  (conversions → `refinery_output`) on load, on pane refresh, and on a 1 Hz
  tick while the pane is open. Jobs run station-side: they complete while the
  player is docked elsewhere or away.

### 7.2 Values — PROPOSED, tick **T-133** (unticked rows implement at their PROPOSED value)

| # | Value | Reversal |
|---|---|---|
| R1 | `RESOURCE_SECONDS = clamp(round(ingot_value/10), 10, 60)` per conversion | per-tier ladder: T1 20 s / T2 40 s / T3 60 s |
| R2 | fee 5 CR/ore-unit charged at queue time (verify → spend → load ore into the job) | fee charged at collection |
| R3 | 2 slots base, +1 per purchase, hardcap 5 | 1 base / hardcap 3 — or slots granted by fitted `u_refine` modules instead of purchases |
| R4 | slot upgrade 3,000 CR flat per +1 | 2,000 CR × slots already owned |
| R5 | caps: input 60 ore units, output 60 ingot units | 40 / 40 (one hold-load each) |
| R6 | wall-clock `ready_at`, settled on load / refresh / 1 Hz | process-time only while the pane is open |
| R7 | `QUEUE ALL` = one job per mineral, FIFO pending beyond free slots | queue only into free slots and leave the rest |
| R8 | `COLLECT ALL` fills the hold, overflow stays in output | per-mineral collect only |

Ordering note (S34-R1/F4's reconciliation of 01 §7's wording): the queue
spends the fee **before** taking the ore and restores symmetrically on any
failure — 01 §7's pairing law (verify → take → pay → emit, all-or-nothing)
holds with the middle two steps swapped; measured leak-free at S34 close.

### 7.3 Panel contract (supersedes §5's action rows; pixel law STATION_HUB §21.3)

`REFINE N` → `QUEUE N`, `REFINERY ALL` → `QUEUE ALL` (the old QA wording tick
dies with this rename — `REFINERY ALL` was docs-pinned; this amendment is the
docs change that moves it), `CANCEL` stands; the totals row gains `TIME` (the
job's wall duration). New controls: `SLOTS n/5 · UPGRADE (3,000 CR)`, `LOAD`,
`COLLECT ALL`. Left = hold ore stacks + `refinery_input` (rows tagged
`LOADED`); centre = stepper + totals (`ORE IN · INGOTS OUT · FEE · TIME`) +
actions; right = the job list (running rows with a countdown, pending rows,
done rows awaiting collection). Numbers still come only from 02 §3, the fee
and R1's formula — the panel hardcodes no prices and no durations.

§6's balance reference stands (fees unchanged); the tuning lever order gains
R1's divisor last. Test rows that pinned instant conversion restate as queue
rows (disclosed in the S34 report); `test_p1_refinery.gd:192` (the
hide-sub-convertible-stacks row — the sealed row) **must not move**.

## 8. 2026-10-08 — S28: the fee stops vanishing (amends §3)

*(S28's block; 01's 2026-10-08 block owns the law. Tick M9 owner-ratified
green 2026-10-08.)*

§3's flat fee was tuned for T1-era holds and vanishes at the top: 15 CR is
23 % of an Iron ingot but **0.7 % of a Krillum ingot**. The fee becomes
value-relative with the historical flat as its floor:

- **Fee per conversion = `max(15, ingot_value × 80 / 1000)` CR** (integer
  truncation, the codebase's whole-credit law). Reversal: the flat 15 (**M9**).
- The fee column on 02's 2026-10-08 table: T1 **15** across (the floor holds —
  §2's worked examples stand unchanged), T2 **15 / 15 / 15 / 15 / 16**, T3
  **20 / 23 / 25 / 28 / 32**, T4 **41 / 45 / 50 / 57 / 64**.
- The refine-vs-raw ramp (02's block): −7 % at iron → **+11 % capped at
  T3–T4** (the flat 15 let T4 refine at +19 % for free).
- `u_refine` halves as shipped — the multiplier applies to the computed fee,
  floored ("one discounted conversion is 7 CR, not 7.5").
- **Interface:** `fee_for(conversions, mult)` gains the mineral —
  `fee_for(mineral_id, conversions, mult)`; the panel's four call sites
  re-point and keep hardcoding nothing.
- R1's duration formula is untouched; on the new ingot values the jobs read
  Iron 10 s (unchanged) · Gold **26 s** (was 40) · Krillum **60 s** (the
  ceiling holds). `test_s34_refinery_queue.gd`'s duration rows move with the
  values; its 15/30/45 CR fee rows survive (T1 keeps the floor).
