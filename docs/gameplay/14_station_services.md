# 14 — Station Services: Contracts, Insurance, Storage, Boss Arenas, Escorts

**Status:** Ready to code.
**Depends on:** 01 (ledger/sinks), 05 (exchange), 08–10 (ships), 11 (map),
12 (factions), 13 (heat).
**Consumed by:** station UI amendments; game-scene spawns (convoy, arena).

---

## 1. The station as a service deck

The station gains a **SERVICES** rail entry beside the existing modules.
Every service below is a panel under it; availability and price multipliers
come from the owning faction (12 §2). One station per faction is the
"capital" offering the full menu; outposts offer a subset (§8).

| Service | Concord capital | Meridian capital | Choir capital |
|---------|-----------------|------------------|---------------|
| Contracts board | ✔ | ✔ (best rates) | ✔ |
| Refuel / recharge | ✔ | ✔ | ✔ (2026-09-20: every station; CR rate per 18_engine_spec §13) |
| Insurance | ✔ (cheapest) | ✔ | ✖ (the Choir does not believe in accidents) |
| Storage rental | ✔ | ✔ (largest vaults) | ✔ |
| Boss arena contract | ✖ | ✔ (expedition desk) | ✔ (rite of the Choir) |
| Bounty payment (13 §2) | ✔ | ✔ | ✔ |

## 2. Contracts board

Data-driven job list; new jobs roll on the 20-minute station clock.

| Type | Example | Reward shape |
|------|---------|--------------|
| **Haul** | "40× `ingot_titanium` to S4 outpost" | spot value ×1.25 + 300 CR, faction standing +2 |
| **Hunt** | "Destroy 5 pirates in S2" | 800 CR + loot as normal, +1 standing per kill extra |
| **Gather** | "20× `mineral_cobalt` ore (raw)" | ×1.4 ore value, +2 standing |
| **Escort** (§6) | "Protect convoy 7 to S4 gate" | 1 200 CR, +5 standing |
| **Expedition** (§7) | arena contract | arena payout, +3 standing |

Rules:

- **Faction-tied:** every contract belongs to a faction; rewards use that
  faction's demand biases so hauling to Meridian pays differently than to
  the Choir (12 §3).
- **No instant-fail timers in v1** except escort (its timer is the convoy's
  hull). Haul/gather contracts have no deadline; they occupy **cargo or
  standing slots** (max 3 active contracts) instead.
- Materials delivered for a contract come from the hold as normal; the
  board pays *over* the exchange's buy price (that's the point) but locks
  the goods at accept-time (escrow: quantity reserved from the manifest,
  removable by cancelling for a 100 CR fee).
- Standing gates (12 §4.1): Shunned players see no contracts; Outlaws see
  none either. Redemption must precede employment.

## 3. Insurance

Death in space is now expensive — but opt-in expensive.

- **Premium:** flat per class, charged at launch, covers **one** hull loss
  (ship + installed modules at full value):

| Hull class | Premium per launch |
|------------|-------------------:|
| Fighter | 200 |
| Cutter | 250 |
| Delver / Trader / Corvette | 300 |
| Hauler / Gunship | 400 |
| Frigate | 500 |
| Destroyer | 700 |

  A Cutter's premium is ≈1.4 % of its list price — a real line item, never
  a punishment. Champion standing multiplies the premium ×0.8 (12 §4.1).
  The Choir sells no insurance at all (their stations bet on you dying).
- **Uninsured loss:** hull and **all installed modules** are gone. The
  standard fit courtesy (09 §7) does not apply to replacements.
- **One-death rule:** the payout covers one loss; the policy does not renew
  mid-flight. A Destroyer run with a 700 CR premium is a real decision.
- **Payout flow:** on death you respawn docked at the last station visited
  in a *base* hull of your class tier's cheapest ship, minus anything
  uninsured. Insurance pays the hull+fit back into your dock. (The starter
  Lancer is never fully losable: if you have no other hull, the Concord
  reissues a bare Fighter — mercy clause, once per profile.)
- Heat (13) is unaffected by death — no crime laundering.

## 4. Storage rental

- Stations rent hold space: **one vault per station, 20 units base,
  +20 per upgrade tier** (tiers 1–3: 500 / 1 200 / 2 400 CR one-off per
  station).
- **Meridian's `u_vault` tech (15 §2):** their stations rent 40-unit vaults
  and the rental tiers cost 25 % more (they know what a vault is worth).
- The vault holds any cargo type (ore, ingots, components); deposits and
  withdrawals are free; **contents persist per-station** (the vault is
  furniture, not a pocket — hauling your own hoard between stations is a
  hauler-fleet gameplay loop).
- Vault contents do **not** count against cargo on launch.
- Purpose: enables bulk trading runs (buy low across sessions), hoarding
  exotic ore for crafting (07), and a permanent credit/material sink. It is
  the quiet hero of the economy.

## 5. Boss arenas (visible, contracted, repeatable)

- Each arena is a **physical place**: a marked, barricaded zone in its
  sector (S3: "The Boneyard" — Meridian arena; S6: "The Pyre" — Choir
  arena), visible from any distance as a lit ring of nav pylons. No hidden
  bosses.
- **Contracts, not buttons:** the arena run is a contract type (§2) taken at
  the faction's expedition desk: accept → arena opens (a 60 s window to fly
  there) → boss fight → payout on return-to-station, win or lose.
- Two bosses: **Boneyard Behemoth** (S3, gunship-tier fit, 15 k CR + magic
  module roll) and **The Pyre Hierophant** (S6, frigate-tier fit, 40 k CR +
  guaranteed rare-module roll, 15 §5). The Maw (S7) remains the roaming
  endgame boss with its 06 §3.4 table — three difficulty beats, all visible
  from across the sector.
- Arena cooldown: one run per boss per 20-minute clock (per profile).
- Kill credit requires **you** landing the last hit — escorts and drones
  don't steal your glory.

## 6. Escort contracts

- Spawn point: the accepting station. A **trade convoy** (1 hauler-class AI
  hull + 1–2 fighter escorts) flies a fixed route to a target sector's gate
  at freighter speed.
- Win: convoy hull survives to the gate → payout at destination station.
- Lose: convoy destroyed → no payout, −5 standing, and the pirates who did
  it keep the loot (which you can... recover. Aggressively).
- Pirates ambush at the corridor midpoint (11 §2.2) — the contract literally
  routes through the dangerous part.
- Convoy hulls use the Hauler stats (08 §2) with 50 % of hold filled with
  visible cargo pods; a *pirate player* (13) can hunt convoys as income —
  same system, both directions.

## 7. Bounty payment window

- Any faction station with heat > 0 shows a **PAY BOUNTY** strip in the
  services deck (13 §2 fine math). Paying is a single confirm; the log
  records it like any transaction.

## 8. Outpost subset

Secondary stations (S2 outpost, S4 outpost, S5 shrine) offer: contracts
(their faction's), bounty payment, and vault tier 1. No insurance (fly to a
capital), no arenas. This makes capitals worth the trip and gives outposts
a reason to exist without diluting the service deck.

## 9. What this gives the coder

- `contract_registry`: 5 types × parameterized tables; contracts are
  Resource-style dictionaries like everything else.
- `PlayerProfile` new persisted state: `active_contracts` (max 3),
  `vaults` (`station_id -> {tier, contents}`), `insured: bool`,
  `mercy_used: bool`.
- One 20-minute station clock drives: exchange bands (05), auction rotation
  (10), contract re-roll, arena cooldowns, sector respawn (11) — one timer,
  five consumers.
