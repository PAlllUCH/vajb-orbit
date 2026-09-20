# 05 — Minerals Exchange: Pricing, Spreads, Trading UI

**Status:** Ready to code.
**Depends on:** 01 (commission K4), 02 (mineral baselines), 03 (component
baselines), 04 (ingots).
**Consumed by:** station UI amendment (panel spec), 06 (sell values), 07.

---

## 1. What the exchange is

One station module — the **minerals exchange** — where the player converts
hold contents into credits. It is the economic payoff of every session (01
§2) and the single place raw ore, ingots, salvage and components become
money. It *buys* only, in v1 (02 §9): the station is an insatiable industrial
customer, and the player is a supplier.

It has two books:

| Book | Items | Pricing |
|------|-------|---------|
| **Minerals book** | all 20 ores + all 20 ingots | dynamic: baseline × demand, per mineral |
| **Surplus book** | 18 components (03 §3) | flat baseline, minus commission, with stock limits |

## 2. Session price model (the "demand" system)

Prices must move, or trading is a price list. They must move *slowly and
legibly*, or trading is a slot machine. The model: one **demand index** per
mineral, drifting between 0.6 and 1.6, re-rolled in bands.

- `price = round(baseline × demand × (1 - commission))` for the minerals
  book; the commission is displayed separately, not baked into the quoted
  price (§5).
- **Band re-roll:** every 20 minutes of real playtime, each demand index
  drifts by a random step of ±0.15, clamped to [0.6, 1.6]. Within a session
  the player sees a stable, readable market that still differs between
  visits.
- **Trade response (the interesting part):** selling `n` units of a mineral
  in one session pushes that mineral's demand down:
  `demand -= 0.01 × n`, floored at 0.6. Selling 20 units of one mineral
  halves no market but visibly cools it. Demand recovers at the next
  band re-roll (+0.15 max). Net effect: **diversified trips pay better than
  monoculture farming**, with no punishing cliff.
- **Start state:** every demand index starts at 1.0 and is persisted in the
  profile save (`market` section, per-mineral float + timestamp of last
  band re-roll).
- The UI always shows the **current** price next to the baseline ("GOLD —
  95 CR × 1.2 demand = 114"). No hidden numbers, no price prediction UI.

## 3. Pricing examples (verify the coder's implementation against these)

Baseline values from 02 §2. Commission 2 % (§5). Demand 1.0:

| Mineral (ingot) | Baseline | At demand 1.0 | At demand 0.6 (floor) | At demand 1.6 (ceiling) |
|-----------------|----------|----------------|------------------------|--------------------------|
| Iron | 65 | 64 | 38 | 102 |
| Titanium | 162 | 159 | 95 | 254 |
| Gold | 395 | 387 | 232 | 619 |
| Krillum | 2 160 | 2 117 | 1 270 | 3 387 |

Raw ore uses the same formula on `ore_value` (e.g. Iron ore at demand 1.0:
18 × 0.98 = 17 CR). There is no special raw-sale discount: raw selling is
cheap because three ore units buy one ingot — the 3:1 conversion (04 §2)
is the whole discount, which keeps 01 §3 S2 honest without a second rule.

## 4. The Surplus Book (components)

- Price: `round(baseline × 0.9)` (a flat 10 % house discount, then
  commission — see §5's combined example).
- **Stock limits:** the station restocks a per-item quota every 20 minutes
  (same clock as the band re-roll):

| Grade | Quota per cycle |
|-------|-----------------|
| I | 40 units |
| II | 15 units |
| III | 4 units |

  Quota is per item id, not per family. Selling into a full quota queues
  the rest for the next cycle ("STOCK FULL — 12 units queued"). This is the
  combat-farming ceiling from 03 §5.
- Quotas and remaining stock persist in the profile save alongside demand.

## 5. Commission (sink K4)

- **2 % of each sale, minimum 10 CR per transaction**, rounded up.
- Worked example — selling 10 Gold ingots at demand 1.2:
  gross = 10 × 395 × 1.2 = 4 740; commission = 95 (2 % ≥ 10); **paid =
  4 645 CR**.
- Worked example — selling 1 Torn Plating (12 CR baseline, surplus 10.8 →
  11): commission = 10 (minimum); **paid = 1 CR.** The minimum makes tiny
  dumps pointless, which is the intended pressure toward batching sales.
- The quoted sale UI always shows **gross, commission, and paid** before the
  player confirms. No sale is ever silent about the haircut.

## 6. The trading flow

1. Player opens the EXCHANGE rail entry at the station.
2. **Left pane — your hold:** every sellable stack (ore, ingots,
   components) with quantity, current unit price, and stack total.
3. **Right pane — market board:** all 20 minerals with today's price and a
   demand trend glyph (▼ cooled / — steady / ▲ hot, from the last band
   re-roll), plus the Surplus Book list with stock bars.
4. Player selects a stack → quantity stepper (default: all) → **SELL**
   shows the confirm strip: `SELL 10 INGOT_GOLD — GROSS 1 140 · FEE 23 ·
   YOU GET 1 117`.
5. Confirm → verify → `remove_cargo` → `add_credits` → demand/stock
   updates → transaction log line (01 §7). All-or-nothing per confirmed
   transaction.
6. **SELL ALL RAW** shortcut converts every ore stack (raw sale, no
   refinery) and every surplus-book component within quota in one confirmed
   action, for players who do not care to optimise.

## 7. What the exchange deliberately is not

- **Not a player-market or auction house.** No listing, no other players.
- **Not a buy shop.** 02 §9 and 03 §6 hold: the player supplies, the
  station consumes. Crafting requirements are met from the hold. If 07
  playtests show recipes starving, the amendment path is a "materials
  counter" that sells Tier-1 ore at `baseline × 1.5` — expensive enough
  that mining your own is always better.
- **Not a casino.** No price events, no rumours, no flash sales in v1. The
  demand drift (§2) is the entire dynamic layer until playtest says more.

## 8. Implementation notes

- One `MarketState` resource owned by an autoload (or by `PlayerProfile`'s
  save section — coder's choice, but **one** owner, persisted, documented).
  Contents: `demand: Dictionary[mineral_id, float]`, `stock:
  Dictionary[component_id, int]`, `last_band_time: int`.
- Band re-roll and stock restock run on one 20-minute accumulator checked
  at station entry and at each sale (not on a live Timer in menus).
- All price computation lives in one static function
  (`exchange_price(id, is_ingot, is_component) → int`); no UI code may
  recompute prices from baselines.
- Transaction log lines: `SELL, ingot_gold, 10, +1117, balance`.
