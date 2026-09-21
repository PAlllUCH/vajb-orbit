# 01 — Economy Core: Credits, Sources, Sinks, Balance

**Status:** Ready to code.
**Extends:** `docs/design/STATION_SPEC.md` (PlayerProfile), `docs/design/STATION_HUB.md`.
**Consumed by:** 02, 03, 04, 05, 06, 07.

---

## 1. Purpose and invariants

Credits (CR) are the single currency of Vajb Orbit. Everything the player
earns in space converts to credits, and everything the player buys costs
credits. There is no second currency, no gems, no tokens — one number the
player can always read in the station header.

Invariants every subsystem must obey:

1. **`PlayerProfile` is the single source of truth for the balance.** All
   credit movement goes through its existing `add_credits` / `spend` /
   `can_afford` API. No subsystem keeps its own wallet copy.
2. **Integers only.** Credits are a plain `int`. No floats, no rounding
   surprises. Prices are written in whole credits.
3. **Every earning path is data-driven.** Income values live in the catalogues
   defined by documents 02–06, never hardcoded in scripts. Tuning a reward is
   an edit to a data table, not a code change.
4. **Selling is never free money.** Any player-to-NPC sale pays out at the
   exchange sell price, which is strictly below the buy price (see 05 §5).
   There is no path that buys and sells an item at the same price.
5. **The balance cannot go negative.** Spending APIs already guard this; new
   code must keep it true.

## 2. The two loops

The economy serves two loops with different rhythms:

- **Session loop (3–12 minutes, in space):** mine asteroids → hold fills with
  ore → fight or avoid enemies → dock. At dock, the session loop *closes*:
  ore is refined (04), loot is dropped into the exchange (05), credits
  increase. Nothing in space pays credits directly.
- **Progression loop (10–40 hours, at the station):** credits buy the
  StationCatalog (ammo 120–320 CR, upgrades 3 000–6 800 CR, ships
  9 000–72 000 CR). This loop is unchanged by this design; the economy's job
  is to fund it at a controlled pace.

Closing the session loop at the station (not in space) is deliberate: it
gives docking a concrete payoff, makes the station the economic centre of the
game, and lets the exchange UI be a normal Control screen rather than an
in-flight overlay.

## 3. Credit sources (faucets)

| # | Source | Pays | Defined in |
|---|--------|------|------------|
| S1 | Selling refined ingots on the minerals exchange | ingot baseline × demand, minus commission | 05 §2–5 |
| S2 | Selling raw ore directly (bulk fallback) | ore baseline × demand, minus commission | 05 §2 |
| S3 | Selling salvage and components (Surplus Book, stock-capped) | 90 % of baseline, minus commission | 05 §4 |
| S4 | Enemy wreck drops that are pure credit caches (rare) | Flat amounts | 06 §5 |

There are no other faucets. In particular:

- **No mission bounties in v1.** Combat pays through loot (06), not through
  a kill-reward. A bounty system may be added later; if it is, it gets its
  own document and this table is amended.
- **Asteroids never drop credits.** They drop ore only (02 §7).
- **Nothing sells itself.** Salvage collected in space sits as cargo until
  the player sells it at the station.

## 4. Credit sinks (drains)

Ordered by the point at which a new player reaches them:

| # | Sink | Cost | Already specced |
|---|------|------|-----------------|
| K1 | Ammunition | 120–320 CR per pack, consumed every session | StationCatalog |
| K2 | Hull and shield repairs (new sink, this design) | see §6 | this doc |
| K3 | Refining fees (new sink) | 5 CR per ore unit refined | 04 §3 |
| K4 | Exchange commission (new sink) | 2 % of every sale, min 10 CR | 05 §5 |
| K5 | Upgrades | 3 000–6 800 CR, one-off per slot | StationCatalog |
| K6 | Ships | 9 000–72 000 CR, one-off | StationCatalog |
| K7 | Crafting (future) | components + credits | 07 |

Design intent: **K1–K4 are running costs that scale with play; K5–K6 are
one-off goals that consume accumulated wealth.** A player who never buys a
ship still bleeds credits through K1–K4, which keeps the exchange relevant
every session. A player who buys everything reaches the ship ladder's end
only after many sessions of trading well, not by grinding one asteroid field.

## 5. Income targets and balance math

All targets assume the baseline loop with the starting Vanguard (cargo 40).

### 5.1 What a session yields

| Source | Per good session | Notes |
|--------|------------------|-------|
| Ore sold as ingots (S1) | 1 300–1 900 CR | a full 40-unit hold ≈ 13 ingots of mixed tier-1/2 ore (02 §4, 04 §2) |
| Loot sold (S3) | 300–600 CR | 2–4 fighters killed, their salvage sold |
| Session gross | **1 900–2 600 CR** | |

### 5.2 What a session costs

| Sink | Per session | Notes |
|------|-------------|-------|
| Ammo (K1) | 240–500 CR | mostly Laser Cells, some Cannon Shells |
| Repairs (K2) | 100–350 CR | assume taking moderate damage |
| Refining fee (K3) | ≈ 195 CR | 13 conversions × 15 CR (04 §3) |
| Commission (K4) | 40–60 CR | 2 % of S1+S3 |
| Travel (11 §2) | 0–250 CR | gate fees; hand-flown corridors are free |
| Insurance (14 §3) | 200–300 CR | flat per-class premium, optional but recommended |
| Session net cost | **≈ 1 100–1 400 CR** | |

### 5.3 Net progression

- **Session net income: 750–1 450 CR** for a competent player in a
  tier-1/2 field with the starting ship. Call it **≈1 100 CR per
  10-minute session** as the design average (GPM ≈ 110).
- **First upgrade (3 000 CR):** 3–4 sessions.
- **First ship purchase (Lancer, 9 000 CR):** 9–11 sessions, or sooner if
  the player skips upgrades.
- **Full ladder (Vanguard→Obliterator, 135 000 CR total):** the long goal,
  roughly 70–100 sessions including upgrades. Faster with the higher-tier
  fields that better ships unlock (see 02 §5).
- **A player who only mines** (no combat) nets ≈750–1 150 CR per session:
  15–20 % less than a mixed player. Mining should never be strictly better
  than fighting + mining, but it must remain a valid low-risk choice.
- **A player who only fights** nets ≈500–800 CR per session in v1: combat
  alone funds ammo and repairs, not progression. This is intentional for the
  current build (loot tables are small); 06 §7 lists how combat income scales
  when richer tables ship.

### 5.4 Progression timeline check

Target pace, from a fresh profile (10 000 CR start):

| Milestone | Target sessions | Cumulative credits earned |
|-----------|-----------------|---------------------------|
| First upgrade (Cargo Expansion) | 3–4 | ≈ 13 000 |
| Lancer (9 000 CR) | 9–11 | ≈ 20 000 |
| Bulwark (36 000 CR) | 30–40 | ≈ 45 000 |
| Obliterator (72 000 CR) | 70–100 | ≈ 135 000 |

If playtesting shows the pace off by more than ±30 %, tune **income
levers first** (ore value per unit in 02 §4, drop weights in 06 §3), then
sink levers (repair rates in §6). Never touch StationCatalog prices; they
are a frozen contract.

### 5.5 Inflation control

The station stock is infinite, so credits always have somewhere to go: the
ship ladder absorbs up to 135 000 CR per profile, and upgrades absorb
27 600 CR. Inflation pressure therefore comes only from grinding pace, not
from saturation. The two rules that keep grinding honest:

1. **Diminishing local fields.** Asteroid fields respawn on a timer; a
   freshly cleared field yields at full value, a field mined within its
   respawn window yields at 70 % (02 §8). This makes "mine the same rock
   forever" a losing strategy without punishing normal play.
2. **The commission floor (K4).** Every sale costs something, so raw income
   always overstates real income.

## 6. Repairs — the new sink (K2)

The station gains a REPAIRS panel (new module rail entry in STATION_HUB
terms; a full UI spec is a follow-up amendment to STATION_HUB.md, not part
of this document). Mechanics:

- Hull and shield are restored to full for a fee.
- **Fee = 1 CR per 2 missing hull points + 1 CR per 3 missing shield points.**
  A Vanguard limping home at 20 % hull / 50 % shield pays
  (800/2) + (300/3) = **500 CR**. Full repair from near-death ≈ 700 CR.
- Repairs are optional: the player may launch damaged. Damaged ships keep
  their damaged stats in space (hull does not regenerate by itself in v1;
  the Repair Drone Bay upgrade remains the in-space answer). Risk/reward is
  the player's to choose, and the fee makes reckless play expensive without
  ever soft-locking a broke player (they can still launch at 1 % and mine a
  safe field).
- No repair fee is charged for shield alone at ≥ 90 %; trivial trips should
  not be taxed.

**Amendment 2026-09-20 (18_engine_spec §12 item 13):** the persisted vitals
record gains `fuel` beside `hull` and `shield` — Energy recomputes at launch,
Fuel persists across it — with the `profile_changed` key `&"fuel"` and the
save-schema bump per the P1 migration pattern (save v3). `set_vitals` grows the
field while its callers' contract is unchanged: the shield-alone exemption
above still governs the fee, so a shield-only docking report is not taxed.

## 7. Persistence and transaction integrity

- Credits, cargo and sell results persist through the existing
  `PlayerProfile` save (`user://profile.cfg`, debounced writes). No new save
  file is created for the economy.
- **Every economy mutation that the exchange or refinery performs must be
  paired and ordered:** verify → take goods → pay → emit. The refinery and
  exchange are implemented as plain functions on top of `PlayerProfile`
  (`add_cargo` / `remove_cargo` / `add_credits` / `spend`), not as separate
  state holders. A cancelled dialog commits nothing.
- **Keep a running transaction log** (`user://economy_log.txt`, append-only,
  one line per event: `timestamp, event, item, qty, credits_delta, balance`).
  This is a debugging tool for balancing sessions and is not shown in the UI.
- Cargo is capped by the ship's `cargo_max` (existing contract). The
  refinery and exchange never exceed it; overflow ore is left floating in
  space (02 §7).

## 8. Tuning levers (for the designer, after playtests)

Ranked from safest to most disruptive:

1. Ore base values per unit (02 §4 table) — scales all mining income.
2. Refine yield percentages (04 §2) — scales S1 specifically.
3. Loot table weights and quantities (06 §3) — scales combat income.
4. Repair fee rates (§6) — changes the cost of reckless play.
5. Commission percent (05 §5) — changes the gap between sell and walk away.
6. Asteroid respawn timers (02 §8) — changes farming pressure.
7. StationCatalog prices — **never.** Frozen contract.
