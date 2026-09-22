# 10 — Ship and Module Acquisition: Auction House and Shipyard Build

**Status:** Ready to code.
**Depends on:** 01 (credit ladder), 02/03/05 (materials and exchange), 08
(class prices), 09 (module catalogue, standard fits).
**Consumed by:** station UI amendments (AUCTION and SHIPYARD panels).

---

## 1. The two doors, one question

**How do I get a hull or a module?** Two paths, deliberately priced against
each other:

| Path | Pays with | Speed | Cost profile | Best when |
|------|-----------|-------|--------------|-----------|
| **Auction House** (buy finished) | credits only | now | list price (≈ materials × 1.3 + labour) | you are rich in credits and poor in time/materials |
| **Shipyard build** (build it yourself) | materials + credits (labour only, ≈ half the auction premium) | a build queue | cheap in credits, hungry in ingots/components | you mine and fight, and credits are the scarce resource |

Design intent (user decision): the auction house is the **credit sink for
the impatient**; the shipyard is the **material sink for the invested**. A
player who only trades can buy anything eventually; a player who mines and
fights gets the same hull for materially fewer credits. Both paths end at
the same hull — no exclusive items either way, so neither path is a trap.

## 2. The Auction House

A station module (rail entry; UI spec amends STATION_HUB.md when designed).
It is **not** a player-market: prices are fixed by the data tables. It is a
house broker with a rotating shelf.

### 2.1 The rotation

- The auction lists **6 hulls + 10 modules** at a time.
- **Restock every 20 minutes** (same station clock as 05 §2/§4): 6 hulls
  drawn from the class ladder (§2.2) and 10 modules drawn from the 09
  catalogue with tier weights I 50 % / II 35 % / III 15 %.
- One **"hot slot"** per restock: a random listed item at −20 % (shown as
  the auction's only discount, never stacked with anything).
- Rotation state persists in the profile save (same section family as the
  exchange's market state).

### 2.2 Hull availability weights

Class list price is 08 §2's column. Availability is weighted so the ladder
reads as progression:

| Class | In rotation chance |
|-------|--------------------|
| Fighter, Cutter | always listed (the two starter hulls never leave the shelf) |
| Miner (Delver), Trader (Courier), Hauler (Mule) | 60 % |
| Corvette, Gunship | 45 % |
| Frigate | 30 % |
| Destroyer | 20 % (the wall should feel rare without being grind-gated) |

*(Naming corrected 2026-09-22, S3 docs pass: the 60 % row read "Delver, Trader, Hauler",
a ship name where every other row is a class. The shelf keys off 08 §2's **asset ids**
(`ship_fighter`, `ship_vanguard`, `ship_miner`, `ship_trader`, `ship_corvette`,
`ship_freighter`, `ship_gunship`, `ship_patrol`, `ship_destroyer`), carried in that order
by `StationCatalog.SHIPS`; the class name is the shelf's display column only. Reversal:
restore the old row.)*

### 2.3 Buying rules

- Buyout price = **list price** (08 §2). A hull bought at auction arrives
  **bare** (no modules) except its **mandatory set** (09 §7: one `e_std` per
  ENGINE cell plus one `p_std`, included in the price and never empty) and the
  two frozen starter hulls, which include their full standard fits (09 §7/§9) —
  those two are also the only hulls whose frozen prices (9 000 / 18 000) already
  bundle a fit.
- **Selling back** to the auction: 60 % of list, any condition, no questions
  (the garage-sale rule; prevents ship-flipping arbitrage because 60 % < the
  130 % premium you paid, 01 §4 invariant 4).
- Modules bought at auction arrive in the player's **module inventory** (§6).

### 2.4 The surface ships (amendment 2026-09-22, S3)

The AUCTION module of §2 is now designed and built; `STATION_HUB.md` §5.10 is the
screen spec and CONTRACTS §15 is the pin.

- The rail gains **AUCTION** in the trade cluster, directly after EXCHANGE; no
  other entry moves (owner tick: rail position).
- The shelf lists **6 hulls + 10 modules** per §2.1; module rows show the
  **rolled instance** (15 §7 name, rarity tint) and its rarity-multiplied price
  (15 §1), the hot slot's −20 % applying after. Hull rows are §2.2's weights;
  §2.3's buyout rules are unchanged.
- Faction lots: 15 §8's interim (one tagged F lot per shelf until 12 §5's
  faction stations exist).
- Selling back: §2.3's 60 % of list, made rarity-aware per 15 §6/§8.
- OUTFITTING's seven weapon rows retire into this shelf (§5's flag-day rule and
  §6's interim note), and OUTFITTING returns to ammunition.

**Ticked 2026-09-22 (S3 docs pass, answering K0's findings).** Three things the first
draft of this amendment left open, now pinned where they belong:

- **The shelf's home is a top-level `auction` key** with `{last_band, hulls, modules,
  hot}`, not a `market` sub-key: `PlayerProfile._normalise_market` rebuilds that
  dictionary from `MARKET_KEYS` and would drop a stranger on load (CONTRACTS §15).
  The `mod_%04d` counter is its own top-level `instance_counter`.
- **The F lot's split is 15 §9.2's 85 % Magic / 15 % Rare**, and the three exclusives'
  catalogue rows — which existed nowhere in the tree — are 15 §9.1.
- **Hull rows reuse each hull's `preview`** as their icon: no class-icon asset ships
  and `assets/` is frozen this wave (STATION_HUB §5.10).

The restock footer's `m:ss` is a **reading taken at pane entry**, not a countdown — the
shared clock has no remaining-time accessor and forbids per-consumer Timers
(STATION_HUB §5.10, 05 §8).

## 3. The Shipyard build path

A second station module. Building costs **materials + a credit labour fee**.
Labour ≈ 35 % of list price (the auction's ≈ 30 % premium over materials is
replaced by 35 % labour, so building saves ~65 % of the credits vs buying —
checked in §4's worked example).

### 3.1 Hull recipes

Materials come from the 02 ore catalogue (raw ore — the shipyard buys from
miners, not refiners) and 03 components. One recipe per class. **Rule:
materials ≈ 20–30 % of list value, labour = 35 % of list, so a build totals
≈ 55–70 % of the auction list (§4).**

| Class | Materials | Labour (CR) | vs list 08 §2 |
|-------|-----------|------------:|--------------:|
| Fighter | 45× `mineral_iron`, 25× `mineral_chromium`, 2× `comp_scrap_1` | 3 150 | 9 000 |
| Cutter | 55× `mineral_titanium`, 30× `mineral_aluminium`, 3× `comp_mech_1` | 6 300 | 18 000 |
| Delver | 50× `mineral_titanium`, 35× `mineral_silver`, 4× `comp_mech_1` | 5 600 | 16 000 |
| Trader | 55× `mineral_titanium`, 30× `mineral_copper`, 3× `comp_mech_1` | 7 350 | 21 000 |
| Corvette | 60× `mineral_tungsten`, 35× `mineral_cobalt`, 4× `comp_scrap_2` | 9 450 | 27 000 |
| Hauler | 70× `mineral_titanium`, 50× `mineral_iron`, 5× `comp_scrap_2` | 8 400 | 24 000 |
| Gunship | 70× `mineral_tungsten`, 35× `mineral_neodymium`, 6× `comp_weap_1` | 12 600 | 36 000 |
| Frigate | 45× `mineral_iridium`, 25× `mineral_platinum`, 8× `comp_mech_2` | 18 900 | 54 000 |
| Destroyer | 70× `mineral_osmium`, 40× `mineral_gold`, 12× `comp_scrap_3` | 25 200 | 72 000 |

### 3.2 Module recipes (shape only)

Every module is buildable: **2× its tier's component family + 12× a
matching-tier ore + 20 % of list as labour.** Family mapping follows 03
§3's "Used for" column (weapons → `comp_weap_*`, shields → `comp_ore_*`,
etc.). Exact per-module tables are written with the module catalogue
implementation; the shape rule is the contract so the coder cannot invent
prices.

### 3.3 Build queue mechanics

- One build at a time; a build takes **one in-space session** ("ready when
  you return from your next flight") — real-world time is never the gate,
  play is.
- Materials and labour are **committed at queue time** (removed from hold,
  credits charged) and **refunded in full on cancel** before completion.
  After completion the hull/module is delivered to the station — no refunds.
- The queue state persists in the profile save.
- **Scrap path:** an owned hull can be broken down at the shipyard for
  50 % of its recipe materials (round down). This is how an obsolete hull
  funds the next one, and pairs with the auction's 60 % sell-back (§2.3) as
  the slow-vs-fast choice.

## 4. Worked example (verify the coder's math against this)

Building a **Corvette** vs buying it:

- Materials market value (ore + components at baselines):
  60×65 + 35×55 + 4×30 = 3 900 + 1 925 + 120 = **5 945 CR**
- Labour: **9 500 CR** (35 % of 27 000, rounded)
- Build total: **15 445 CR** vs auction list **27 000 CR** — the builder pays
  ≈57 % of the buyer's price, most of it in goods they gathered, not
  credits. This is the intended gap; if playtest shows buying dominates, the
  lever is labour %, never list prices (frozen).

## 5. Legacy upgrade retirement

The six StationCatalog upgrades (STATION_SPEC §5.3) map onto the module
system:

| Old upgrade | Fate |
|-------------|------|
| Reactor Mk2 | superseded by `p_mk2` (09 §3.8) |
| Ion Drive | superseded by `e_ion` |
| Shield Amplifier | superseded by `s_heavy` + `s_ion` lineage |
| Deep Scanner | superseded by `c_scanner` |
| Cargo Expansion | superseded by `u_cargo` |
| Repair Drone Bay | superseded by `u_drones` |

**They remain purchasable in OUTFITTING until the fitting panel ships** (the
frozen contract is not broken mid-phase). The moment the new system goes
live, the OUTFITTING upgrade rows are removed by a documented amendment to
STATION_HUB/STATION_SPEC — one flag day, no dual economy.

## 6. Module inventory

- Modules not installed live in the profile's new `modules` dictionary
  (`module_id -> count`), persisted like cargo. A new `profile_changed`
  key `&"modules"` follows the existing signal pattern.
- Install/remove happens at the station fitting panel (09 §4.6); the
  inventory is its source of truth, alongside owned hulls' current fits
  (persisted per hull as `fit: Dictionary[ship_id, Dictionary[slot_type,
  module_id]]`).
- Selling modules back to the auction: 60 % of list, same rule as hulls.

**Interim note 2026-09-22 (P2-B1 — the weapon fit surface).** Until the AUCTION
module of §2 exists, **OUTFITTING sells the seven weapon modules** into this
inventory (`ModuleCatalog` and `buy_module`, CONTRACTS §12; the rows, states,
refusal wordings and focus order are `STATION_HUB.md` §5.1's amendment) — 09
§3.1's six plus `w_mining`, so the mining laser of 09 §4 item 7 has a door. This is
§5's precedent for the legacy upgrade rows — a documented interim surface, never
a second economy. When AUCTION ships, those rows retire into it and OUTFITTING
returns to ammunition. Reversal: none owed while §2 is unbuilt; if AUCTION is
dropped, the OUTFITTING rows become the permanent home and this note becomes the
rule. **The install surface beside it (2026-09-22, P2-B proper):** the modules
this inventory holds are fitted, swapped and emptied per cell on the **FITTING**
surface (`STATION_HUB.md` §5.3), which requests the composed transactions
`PlayerProfile.fit_module_at` / `PlayerProfile.clear_fit_slot` (CONTRACTS §13)
and never mutates the profile directly. OUTFITTING's rows buy modules into this
inventory; FITTING is what installs, swaps and removes them.

**Closed 2026-09-22 (S3):** this interim retires exactly as it promised — the
rows move to the AUCTION shelf (§2.4) when it ships, and OUTFITTING returns to
ammunition-only.

## 7. Acquisition pacing (check against 01 §5.4)

The double path keeps the 01 milestone pace intact:

- **Buyer pace:** unchanged — auction list prices are the 08 §2 ladder the
  01 §5.4 timeline was computed from.
- **Builder pace:** strictly faster in credits, slower in calendar (needs
  targeted mining/fighting for exact materials, plus one session in the
  queue). A builder reaches the Corvette ≈ 4–5 sessions earlier in credits
  but must *want* the specific materials — the recipe, not the price, is the
  gate.
- **Anti-snowball:** the build queue's one-at-a-time limit means credits
  (auction) remain the only way to acquire two things at once, so wealth
  still converts to fleet strength linearly, not exponentially.
