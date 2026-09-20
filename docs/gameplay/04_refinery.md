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
