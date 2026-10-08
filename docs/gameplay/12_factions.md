# 12 — Factions: Owners of Space

**Status:** Ready to code.
**Depends on:** 11 (sector map, ownership column), 01 (prices), 05
(exchange).
**Consumed by:** 13 (heat enforcement), 14 (station services differ per
faction), 15 (faction-exclusive modules).

---

## 1. The three powers

| Faction | Home | Identity | Technology |
|---------|------|----------|------------|
| **Concord of Iron** | Halcyon Reach (S1–S2) | Industrial authority. Order, subsidies, boring fair prices. | Mass production: cheapest standard modules, best armour/drive tech |
| **Meridian Free Ports** | Meridian Span (S3–S4) | Trade syndicate. Everything is for sale, few questions asked. | Logistics and information: exchange tech, storage, scanner/computer tech |
| **Ember Choir** | Cinder Verge (S5–S6) | Reactant cult. They mine the exotic belt and think the ore is holy. | Exotics: shield lattice tech, plasma, the only proton missile licence (15 §2) |

Sector 7 (Maw Belt) is unaligned: no station services, no law, the arena.
The Choir claims it and is wrong.

**Tone rule (STYLE_BIBLE voice):** no cute mascots. The Concord is a
bureaucracy with a navy, the Ports are a company town that never sleeps,
the Choir is what happens when people live too close to Emberite.

## 2. What faction ownership changes

Ownership is data on the sector registry (11 §4). Per-sector, the owner
defines:

1. **Station services menu** (14 §2): which services are offered and at what
   multiplier.
2. **Patrol behaviour** (13 §3): how aggressively heat is enforced.
3. **Exchange demand flavour** (§3 below): what the local economy wants.
4. **Auction shelf bias** (§4): which modules the rotation favours.

## 3. Per-faction economy flavour (the "slightly different economy")

Each faction's exchange demand bands are shifted; the 05 §2 system is
unchanged, the *starting demand* and drift bias differ:

| Faction | Demand bias | What this means in play |
|---------|-------------|--------------------------|
| Concord | +0.15 on T1–T2 ingots, −0.10 on components | sell your common ore here, sell your salvage elsewhere |
| Meridian | +0.20 on components, +0.10 on T3 ore, commission 1.5 % (vs 2 %) | the merchant's harbour: salvage and mid-tier pay best |
| Choir | +0.25 on T3–T4 ingots and exotic components, −0.15 on T1–T2 | exotics fetch glory; common ore is an insult |

A trader's route (buy nothing, haul smart) becomes real: run salvage to
Meridian, common ore to Concord, exotics to the Choir. The demand system
(05 §2) already re-rolls; these biases are just the per-sector *initial*
demand + drift weighting, one float per category in the sector registry.

## 4. Faction standings (the meta layer)

One standing value per faction per profile: **−100 (outlaw) … +100
(champion)**, persisted. Standing moves:

| Action | Standing change | Notes |
|--------|-----------------|-------|
| Kill a faction patrol or trader | −5 heat-tiered (see 13) | also raises heat |
| Kill a pirate in that faction's space | +1 | the honest work |
| Complete a faction contract (14 §5) | +2 (+5 for convoy escort) | |
| Sell > 2 000 CR of goods at their station in a session | +1, once per session | trading is citizenship |
| Complete a boss arena (14 §7) | +3 | |

### 4.1 What standing buys

| Band | Name | Effect |
|------|------|--------|
| −100…−51 | Outlaw | denied docking in faction space (13 §5), hunters — see the 2026-09-24 note below on the gate |
| −50…−11 | Shunned | station prices +10 %, no contracts offered |
| −10…+10 | Neutral | baseline |
| +11…+40 | Known | contracts pay +5 %, auction hot slot chance ×1.5 |
| +41…+70 | Trusted | station prices −5 %, one extra auction slot reserved for your tier band |
| +71…+100 | Champion | prices −10 %, insurance premium ×0.8 (14 §3), one standing-order contract always available |

Standing is per-faction: you can be a Champion of the Choir and an Outlaw
of the Concord. The map (11 §1) becomes a political chessboard: your
hunting grounds decide which stations love you.

**Amendment 2026-09-24 (wave S6):** the Outlaw band's **gate refusal** cell above
is superseded by the two-axis rule CONTRACTS §19/13 §7 pin: the **gate** reads
the **heat** tier (`NpcRegistry.heat_tier() == &"outlaw"`, 13 §3 / 11 §2.3) while
the **dock** reads this table's **standing** band (`standing() <= -51`). A
standing-Outlaw player with clean heat is therefore sold a gate ticket; the
docking refusal still follows this row. Reversal: make the gate read standing too
(one predicate).

## 5. Technology identity and 15's exclusives

Faction tech is expressed as **module availability + a per-faction exclusive
line** (15 §2 has the full list). Summary:

- Concord: armour and engines (their `h_composite` and `e_vector` cost −15 %
  at their stations; their exclusive is the `w_flak` line).
- Meridian: computers, boosters, storage (`c_nexus`, `b_fold` −15 %; their
  exclusive is the `u_vault` storage line).
- Choir: shields, plasma, proton missiles (`s_ion`, `w_plasma` −15 %; their
  exclusive is `w_proton` — buyable **only** in Choir stations, 15 §2).

The −15 % discounts stack with standing bands (Champion of the Choir buys a
proton missile launcher 25 % under list — this is the intended reward loop
for faction loyalty).

## 6. What this gives the coder

- `faction_registry`: three entries — name, home sectors, demand biases
  (per 05 category), tech discount families, exclusive module ids, patrol
  density multipliers.
- `PlayerProfile` gains a `standing` dictionary (`faction_id -> int`), new
  `profile_changed` key `&"standing"`.
- All standing changes funnel through one function
  (`apply_standing(faction, delta, reason)`) so the log (01 §7) records the
  political history of the profile.

## 2026-10-08 — S24: the standing mechanics (amends §2 item 4, §4.1, §5)

The station entity and the docked-station seam are `14_station_services.md`'s
2026-10-08 block; the per-sector band is `13_heat_bounty.md`'s; the clouds are
`11_galactic_map.md`'s. This block fixes the mechanism §4.1's band table and §5's
discount stack need, because neither states it. Every value is PROPOSED with its
reversal and a fresh tick (**V1–V7**, the S24 series) — **owner-ratified
2026-10-08: all seven stand as shipped**.

**V1 — "station prices" (§4.1's +10/−5/−10 %).** The band multiplier applies to
the station's own goods and services: the repair fee (`Repairs.fee`), the ammo
pack cost (`StationCatalog.AMMO_PACKS`), the hull list price
(`StationCatalog.SHIPS`) and the module list price (the armory, fitting and
auction listings). The **exchange keeps its own system** — §3's demand bands and
the commission are a market, not a shop, and no band multiplies them. One
accessor, `StationRegistry.price_multiplier(standing)` → **1.10** (Shunned,
≤ −11) / **1.00** (Neutral) / **0.95** (Trusted, ≥ +41) / **0.90** (Champion,
≥ +71). Reversal: the exchange's quotes take the multiplier too (one call site
in `game/exchange.gd`).

**V2 — the §5 stack is additive.** A Champion of the Choir buying a proton
missile launcher reads **0.75 × list** (−15 % faction tech + −10 % band = −25 %,
§5's own "25 % under list" arithmetic). Reversal: multiplicative
(0.85 × 0.90 = 0.765).

**V3 — `contracts_visible` (§4.1).** One predicate,
`StationRegistry.contracts_visible(standing)` → `standing > −11` (Shunned and
Outlaw false, Neutral and above true). Reversal: `standing >= 0`.

**V4 — Known's "auction hot slot chance ×1.5" (§4.1), read against
`10 §2.1`'s one hot slot per restock.** At Known and above the restock rolls one
guaranteed hot row **plus a 50 % chance of a second hot row** (two hot rows when
it lands, both at §2.1's −20 %, never stacked with anything else); the roll rides
the restock's own seeded RNG, so a probe seeds it. Reversal: one hot row always
(§4.1's row unimplemented).

**V5 — Trusted's "one extra auction slot reserved for your tier band" (§4.1).**
The shelf's **first rolled module slot is reserved**: it is rolled from the
docked sector's own tier band (`11 §1.1`'s mix, `SectorRegistry.sector_tier`)
instead of `10 §2.1`'s I/II/III weights. **The shelf's size is unchanged**
(6 hulls + 20 modules — the 2026-10-01 stock-shelf amendment). Reversal: the
reserved slot is an **added** 21st row (which is a `10 §2.1` shelf-size
amendment) instead of a forced draw.

**V6 — the shelf bias hook (§2 item 4).** The station's owner weights its own
tech families ×2 in the rolled-module draw — Concord armour + engines, Meridian
computers + boosters + storage, Choir shields + plasma + proton (§5's own
families, `15 §2`'s slot families). Reversal: uniform (the hook returns 1.0 for
every family).

**V7 — the insurance seam (§4.1's Champion ×0.8).** S24 ships the readable value
only — `StationRegistry.insurance_multiplier(standing)` → **0.8** at Champion,
**1.0** elsewhere; `14 §3`'s premium table and its consumer are S26's.
Reversal: the seam returns 1.0 (the row unimplemented).
