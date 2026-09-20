# 08 — Ship Classes: Roster, Slots, Progression

**Status:** Ready to code.
**Depends on:** 01 (price ladder, session income), `SHIPS_SPEC.md` + `ASSET_EXPANSION_SPEC.md` §3
(asset roster), `STATION_SPEC.md` §4.2/5.2 (frozen ship stats/prices).
**Consumed by:** 09 (slot rules and module catalogue), 10 (acquisition prices).

---

## 1. Design rules

1. **Every class is an asset we ship.** A class exists only if a hull sprite
   exists for it (§4 maps them all). No class is invented ahead of art.
2. **Eclipse-style modular grid.** Every hull is a frame with slots. Two
   slots are **mandatory and permanent**: the ENGINE and the POWER source
   (reactor). Everything else is player choice: weapons, shields, armour,
   computers, boosters, utility. 09 defines the slot rules and every module.
3. **Every stat is earned, none is free.** Speed, damage, shield, cargo —
   all come from hull base + installed modules. The hull itself grants only
   structure, base speed, power output, and slot counts.
4. **Tradeoffs are physical, not numeric tricks.** Armour plating slows the
   ship. Weapons and shields draw reactor power. Bigger reactors and engines
   are their own slots' worth of improvement. There is no fit that wins at
   everything; the class grid enforces it.
5. **Combat and economy hulls share one system.** A hauler is not a weaker
   fighter; it is a different frame spending its slots on cargo and hull
   instead of guns. One slot system covers both, so progression is a single
   ladder the player climbs in whatever direction they like.

## 2. Classes and progression guideline

Nine player classes, small to large. `List price` is the auction/buyout
baseline (10 §2); frozen prices marked ❄ are `STATION_SPEC.md` §5 law.

| Class | Ship (asset id) | List price | Hull | Shield* | Cargo | Weapons | Power out | Base speed | Role |
|-------|-----------------|-----------:|-----:|--------:|------:|--------:|----------:|-----------:|------|
| Fighter | Lancer (`ship_fighter`) ❄ | 9 000 | 700 | 400 | 25 | 3 | 6 | 100 % | cheap, fast, fragile |
| Cutter | Vanguard (`ship_vanguard`) ❄ | 18 000 | 1 000 | 600 | 40 | 4 | 8 | 95 % | starter all-rounder |
| Miner | Delver (`ship_miner`, Phase E gap — §4) | 16 000 | 1 100 | 500 | 55 | 2 | 10 | 75 % | mining specialist |
| Trader | Courier (`ship_trader`) | 21 000 | 950 | 550 | 60 | 1 | 8 | 85 % | exchange bonuses (10 §4) |
| Corvette | Spearhead (`ship_corvette`) | 27 000 | 1 300 | 700 | 35 | 3 | 9 | 110 % | fast hunter |
| Hauler | Mule (`ship_freighter`) | 24 000 | 1 600 | 500 | 120 | 1 | 9 | 65 % | bulk transport |
| Gunship | Bulwark (`ship_gunship`) ❄ | 36 000 | 1 400 | 650 | 50 | 5 | 11 | 80 % | fireplate brawler |
| Frigate | Warden (`ship_patrol`) | 54 000 | 1 800 | 800 | 60 | 4 | 12 | 85 % | line patrol, 2 computers |
| Destroyer | Obliterator (`ship_destroyer`) ❄ | 72 000 | 2 200 | 900 | 80 | 7 | 15 | 70 % | capital gun line |

\* Shield column is the hull's **base shield pool before any shield module**
(it is `STATION_SPEC` §5.2's shield stat, which already bundles a nominal
shield). Ships are bought without modules except the mandatory starter fit
(09 §7); `Shield*` shown at that default fit for continuity with the frozen
stats.

**Flight handling is a separate table.** For engine purposes the flight-stat
source is the **handling column of `docs/gameplay/18_engine_spec.md` §13**
(per class: max speed, accel time, coast time, turn rate, turn spin-up, and —
2026-09-20 — hull mass; the §13 speed table v2 replaces the ×450 anchor once
the owner ticks its △ interpolations). §13 is the single
source and this doc references it instead of restating the values; `Base
speed` above stays the progression column, and §13's max speeds are that
percentage × 450 u/s until the v2 tick lands.

### 2.1 How to read the progression

- **The credit ladder stays x1.5–x2 per step** (9 k → 16–24 k → 27 k → 36 k
  → 54 k → 72 k), matching 01 §5.4's milestone pace. New hulls slot between
  frozen rungs, never below the Lancer.
- **Power out is the class's real ceiling.** A Destroyer pays 15 power for
  seven weapons where a Cutter has 8 — size buys reactor headroom, and
  headroom buys fits.
- **Speed is the price of everything else.** The Delver and Mule earn their
  keep while being slow; the Spearhead pays hull and cargo for 110 %.
- **Branch, don't funnel.** After the Vanguard the player may go economic
  (Delver/Mule/Courier: earn faster per session) or martial (Spearhead →
  Bulwark → Warden → Obliterator). An economic hull pays for the martial
  one; 10 §3 makes selling traded goods on the Courier explicitly cheaper.
- **Non-combat classes are not safety modes.** They can fight badly — a
  Mule with its single weapon slot can still mount a cannon — but their
  grids make them lose that fight.

## 3. Slot grids

Slot counts per class (09 §1 defines each type; W counts weapon mounts and
equals the existing `hardpoints` stat):

| Class | Engine | Power | W | S (shield) | H (armour) | C (computer) | B (booster) | U (utility) |
|-------|:------:|:-----:|:-:|:--:|:--:|:-:|:-:|:-:|
| Fighter | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 0 |
| Cutter | 1 | 1 | 4 | 1 | 1 | 1 | 1 | 1 |
| Miner | 1 | 1 | 2 | 1 | 2 | 1 | 0 | 3 |
| Trader | 1 | 1 | 1 | 1 | 1 | 2 | 1 | 3 |
| Corvette | 1 | 1 | 3 | 2 | 1 | 1 | 1 | 1 |
| Hauler | 1 | 1 | 1 | 1 | 2 | 1 | 0 | 5 |
| Gunship | 1 | 1 | 5 | 2 | 1 | 1 | 0 | 1 |
| Frigate | 1 | 1 | 4 | 2 | 2 | 2 | 1 | 2 |
| Destroyer | 1 | 1 | 7 | 3 | 2 | 2 | 1 | 2 |

Grid sizes rise with class, but **the mandatory pair (Engine + Power) never
shrinks**: even a Destroyer spends 2 of its 19 slots just being flyable.
That is the Eclipse feel — capability is a build, not a purchase.

## 4. Asset mapping and gaps

Every class maps to a shipped sprite (base hulls; hostile liveries from
ASSET_EXPANSION_SPEC §4 are enemy skins and do not affect player hulls):

| Asset id | Player class | Notes |
|----------|--------------|-------|
| `ship_fighter` | Fighter (Lancer) | frozen catalog entry |
| `ship_vanguard` | Cutter (Vanguard) | frozen, starter |
| `ship_corvette` | Corvette (Spearhead) | Phase D hull 5 base hull; v1 enemies use the hostile livery |
| `ship_gunship` | Gunship (Bulwark) | frozen |
| `ship_patrol` | Frigate (Warden) | Phase D hull 12 |
| `ship_destroyer` | Destroyer (Obliterator) | frozen |
| `ship_freighter` | Hauler (Mule) | Phase D hull 5 |
| `ship_trader` | Trader (Courier) | Phase D hull 11 |
| **`ship_miner`** | Miner (Delver) | **asset gap** — one new Phase E hull: wide flat mining frame, ventral cutter bar, dorsal ore bin, twin side engines, same framing constant and palette as SHIPS_SPEC §1 |
| `ship_maw` | — | boss only, not player-ownable in v1 |
| `ship_interceptor`, `ship_bomber`, `ship_drone_swarm`, `ship_mine_layer`, `ship_turret_platform` | — | enemy-only in v1; class entries may be added later as amendments |

The `ship_miner` gap is the only art dependency of this document. It is
filed as an amendment candidate for `ASSET_EXPANSION_SPEC.md` §3 (hull 16)
and must be generated before the Miner class ships.

## 5. Player fleet

- Players own hulls, one **active** at a time — the existing
  `PlayerProfile.owned_ships` / `active_ship` contract, unchanged.
- The station SHIPYARD lists owned hulls with SET ACTIVE; switching is free
  and instant while docked.
- No NPC crew, no multi-ship sorties in v1. A second hull is a tool for a
  different job, not a wingman.

## 6. What each class must feel like (balance intents, for playtests)

| Class | Feel target | Kill check |
|-------|-------------|------------|
| Fighter | dies to two corvette volleys, outranges everything | DPS per credit highest |
| Cutter | never the best, never wrong | first 10 h are played in it |
| Delver | fills a hold faster than any combat hull | ore/highest tier per session ≈ +40 % vs Cutter |
| Courier | makes trading feel like printing money | commission paid per session ≈ −50 % vs other hulls |
| Spearhead | the duelist | wins 1v1 vs equal-price economic fit |
| Mule | one trip replaces two | credits per trip highest in safe sectors |
| Bulwark | refuses to die, slow | survives encounters the Spearhead cannot |
| Warden | brings two computers' worth of tricks | flex-fit platform, hardest to counter-build |
| Obliterator | the endgame wall | power-limited: cannot equip its full 7 W grid with top weapons — 09 §4's crunch is the point |
