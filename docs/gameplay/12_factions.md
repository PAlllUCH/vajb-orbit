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
| −100…−51 | Outlaw | denied docking in faction space (13 §5), gate refusal, hunters |
| −50…−11 | Shunned | station prices +10 %, no contracts offered |
| −10…+10 | Neutral | baseline |
| +11…+40 | Known | contracts pay +5 %, auction hot slot chance ×1.5 |
| +41…+70 | Trusted | station prices −5 %, one extra auction slot reserved for your tier band |
| +71…+100 | Champion | prices −10 %, insurance premium ×0.8 (14 §3), one standing-order contract always available |

Standing is per-faction: you can be a Champion of the Choir and an Outlaw
of the Concord. The map (11 §1) becomes a political chessboard: your
hunting grounds decide which stations love you.

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
