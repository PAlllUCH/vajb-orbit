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
| Fighter | Lancer (`ship_fighter`) ❄ | 9 000 | 700 | 400 | 25 | 2 △ | 6 | 100 % | cheap, fast, fragile |
| Cutter | Vanguard (`ship_vanguard`) ❄ | 18 000 | 1 000 | 600 | 40 | 3 △ | 8 | 95 % | starter all-rounder |
| Miner | Delver (`ship_miner`) | 16 000 | 1 100 | 500 | 55 | 2 | 10 | 75 % | mining specialist |
| Trader | Courier (`ship_trader`) | 21 000 | 950 | 550 | 60 | 1 | 8 | 85 % | exchange bonuses (10 §4) |
| Corvette | Spearhead (`ship_corvette`) | 27 000 | 1 300 | 700 | 35 | 4 △ | 9 | 110 % | fast hunter |
| Hauler | Mule (`ship_freighter`) | 24 000 | 1 600 | 500 | 120 | 1 | 9 | 65 % | bulk transport |
| Gunship | Bulwark (`ship_gunship`) ❄ | 36 000 | 1 400 | 650 | 50 | 5 | 11 | 80 % | fireplate brawler |
| Frigate | Warden (`ship_patrol`) | 54 000 | 1 800 | 800 | 60 | 4 | 12 | 85 % | line patrol, 2 computers |
| Destroyer | Obliterator (`ship_destroyer`) ❄ | 72 000 | 2 200 | 900 | 80 | 7 | 15 | 70 % | capital gun line |

\* Shield column is the hull's **base shield pool before any shield module**
(it is `STATION_SPEC` §5.2's shield stat, which already bundles a nominal
shield). Ships are bought without modules except the mandatory starter fit
(09 §7); `Shield*` shown at that default fit for continuity with the frozen
stats.

△ **Weapons column, amendment 2026-09-21:** the Lancer carries 2 mounts (was 3),
the Vanguard 3 (was 4) and the Spearhead 4 (was 3) — the owner's ruling that a
fighter mounts "like two" weapons while a cruiser-class hull mounts more than a
fighter, in both guns and plate. §3's grid table is the authority; this column is
its weapons count restated for the progression read. Reversal: restore 3 / 4 / 3
in this column and in §3's grid, and delete §6's amendment note below plus 09
§6's Fighter and Spearhead ledger rows back to their 2026-09-20 text.
`Weapons` is the `hardpoints` stat the code has always read
(`StationCatalog.SHIPS`), so the two move together.

Engine, drive and plate counts are **not** in this table: they are per-class in
§3, because they are grid shape rather than a progression column.

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

**Amendment 2026-09-21 (owner request: every class gets its own slot count *and*
its own layout).** The engine count is now a class column, the weapons and armour
counts rise with hull size, and each class's grid is written as a **hull-plan
matrix** (§3.2) which is the single source of the counts in §3's table. The
original table (every class at `Engine 1`, `Power 1`, and the weapons column
3/4/2/1/3/1/5/4/7) is superseded. Rows this amendment moved are marked △ and are
the owner's tick list. Reversal: restore the original table, delete §3.1–§3.3,
and restore §2's weapons column, §6's amendment note and 09 §6's Fighter and
Spearhead ledger rows to their 2026-09-20 text; nothing outside this document
reads the matrices.

Slot counts per class (09 §1 defines each type; W counts weapon mounts and equals
the `hardpoints` stat the code reads):

| Class | Ship | Tier | E | P | W | S | H | C | B | U | Total |
|-------|------|------|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|------:|
| Fighter | Lancer | Light | 1 | 1 | 2 △ | 1 | 1 | 1 | 1 | 0 | 8 |
| Cutter | Vanguard | Light | 1 | 1 | 3 △ | 1 | 2 △ | 1 | 1 | 1 | 11 |
| Miner | Delver | Medium | 2 △ | 1 | 2 | 1 | 2 | 1 | 0 | 3 | 12 |
| Trader | Courier | Medium | 2 △ | 1 | 1 | 1 | 2 △ | 2 | 1 | 3 | 13 |
| Corvette | Spearhead | Light | 1 | 1 | 4 △ | 2 | 2 △ | 1 | 1 | 1 | 13 |
| Hauler | Mule | Heavy | 3 △ | 1 | 1 | 1 | 3 △ | 1 | 0 | 5 | 15 |
| Gunship | Bulwark | Medium | 2 △ | 1 | 5 | 2 | 2 △ | 1 | 0 | 1 | 14 |
| Frigate | Warden | Heavy | 2 △ | 1 | 4 | 2 | 3 △ | 2 | 1 | 2 | 17 |
| Destroyer | Obliterator | Capital | 3 △ | 1 | 7 | 3 | 4 △ | 2 | 1 | 2 | 23 |

`Tier` is the hull band §3.1 derives the engine count from. Grid sizes rise with
tier, but **the mandatory set never shrinks**: a Lancer spends 2 of its 8 cells
just being flyable, an Obliterator 4 of 23 — the bigger the hull, the better the
overhead ratio, which is what makes a capital feel like one. That is the Eclipse
feel: capability is a build, not a purchase.

### 3.1 Engine counts (new — E is a set, not a slot)

A hull has as many ENGINE slots as its mass band gives it, and **all of them must
be filled to launch** (09 §4.1). The rule is derivable, not arbitrary — it reads
`18_engine_spec.md` §13's `hull_mass` column, which is also what the inertia model
scales by:

| §13 hull mass | Engine slots | Classes |
|---------------|:------------:|---------|
| ≤ 110 t | 1 | Fighter (80), Corvette (90), Cutter (110) |
| 140–220 t | 2 | Miner (140), Trader (160), Gunship (190), Frigate (220) |
| ≥ 260 t | 3 | Hauler (260), Destroyer (300) |

Why this shape: mass is what thrusters move, the Delver's art brief already
specifies **twin side engines** (`SHIPS_SPEC.md`), and a capital hull reads as a
capital because it carries three drives. Engine modules stack by **sum of deltas,
never multiplication** (09 §3.7), so a three-engine hull is a smoother upgrade
curve, never a runaway multiplier.

Drives (`B`) and plate (`H`) keep their own columns: `B` is the burst drive
(afterburner, fold dash), `H` is armour plating, and both are unchanged in kind —
only their counts move with the class.

### 3.2 Slot layouts (new — the matrix is the authority)

Each hull's grid is one **hull-plan matrix**: rows top to bottom, cells left to
right, letters are 09 §1's slot types (`E` engine, `P` power, `W` weapon,
`S` shield, `H` armour, `C` computer, `B` booster/drive, `U` utility) and `.` is a
gap — the hull's own silhouette, not a slot. §3's counts are **derived from these
matrices**, never kept beside them, so a count and a layout cannot disagree.

The block below prints a row with cosmetic spaces for readability; a row's cells
are its characters, so the Cutter's first row is `.WW.` and its third is `HWU.`.
The code's `SLOT_GRIDS` carries exactly these rows with the spaces removed, and a
test parses this block and compares it with the constant, so the document and the
data cannot drift apart. A layout is not required to be symmetric — odd counts
(3 weapons, 5 utility cells) make symmetry impossible — it is a hull *plan*, read
like a silhouette.

```text
Fighter  (4 x 3)             E1 P1 W2 S1 H1 C1 B1 U0   = 8
. W W .
H S C B
. E P .

Cutter   (4 x 4)             E1 P1 W3 S1 H2 C1 B1 U1   = 11
. W W .
H S C B
H W U .
. E P .

Miner    (4 x 4)             E2 P1 W2 S1 H2 C1 B0 U3   = 12
W . . W
C H H S
U U U .
E E P .

Trader   (4 x 4)             E2 P1 W1 S1 H2 C2 B1 U3   = 13
. W . .
S C C H
H U U U
E E B P

Corvette (4 x 4)             E1 P1 W4 S2 H2 C1 B1 U1   = 13
. W W .
H S S H
W C B W
. E P U

Hauler   (4 x 5)             E3 P1 W1 S1 H3 C1 B0 U5   = 15
. W . .
H H H S
U U U U
C U . .
E E E P

Gunship  (4 x 5)             E2 P1 W5 S2 H2 C1 B0 U1   = 14
W W W W
. S S .
H C H .
W U . .
E E P .

Frigate  (4 x 5)             E2 P1 W4 S2 H3 C2 B1 U2   = 17
. W W .
H S S H
C W W C
H B U U
. E E P

Destroyer (5 x 6)            E3 P1 W7 S3 H4 C2 B1 U2   = 23
. W W W .
H S S S H
C W C W .
H . B H .
W W U U .
E E E P .
```

Read a matrix as the hull seen from above: weapons ride the outer edges, armour
and shields ring the middle, computers sit beside the hull, engines and the
reactor sit in the tail. Two layouts can share a count and still feel different
(the Corvette and the Trader are both 13 cells), which is the point of having a
layout at all.

### 3.3 What the layout governs (the code contract)

One matrix, three consumers — the fitting panel's arrangement, the station's
layout display and the in-flight mount geometry all read the same cells:

1. **Counts** — `ShipFit.grid_counts(hull_id)` is the derived per-type count; a
   test asserts it against this section's table for all nine hulls.
2. **Display** — the SHIPYARD's slot display is a `GridContainer` of one cell per
   non-gap matrix cell, `columns` = the matrix width, a gap drawn as an empty
   cell (never a slot).
3. **Mounts** — a cell's own row/column gives its hull-local anchor
   (`ShipFit.mount_offset`), so the layout *is* the hardpoint geometry: no second
   table to drift. Consumption in flight (weapons firing from their own mount) is
   staged into the feel wave, not this one.


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
| `ship_miner` | Miner (Delver) | shipped (`assets/ships/ship_miner_side.png`) — the 2026-09-18 gap is closed; twin side engines, matching §3.1's two engine slots |
| `ship_maw` | — | boss only, not player-ownable in v1 |
| `ship_interceptor`, `ship_bomber`, `ship_drone_swarm`, `ship_mine_layer`, `ship_turret_platform` | — | enemy-only in v1; class entries may be added later as amendments |

**Amendment 2026-09-21:** the `ship_miner` gap this section used to carry is
closed — `vajb-orbit/assets/ships/ship_miner_side.png` is on disk, so all nine
player classes have their base hull and the class ladder in §2 is fully
buildable. No class has an art dependency left. Reversal: none owed; the row is
a statement of what is on disk.

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

**Amendment 2026-09-21 — what the grid change does to these intents.** Three rows
move and none of them changes its target:

- **Fighter** drops to 2 mounts. Its "DPS per credit highest" now leans on
  handling (the Lancer keeps §13's best turn rate and shortest accel) and on the
  cheap Tier-I fit, not on a third gun; if playtest shows it lost the crown, the
  lever is the weapon tiers' costs, never this grid.
- **Cutter** drops to 3 mounts and gains a second plate cell: the starter hull
  trades a gun for survivability, which is what "never the best, never wrong"
  means in a brawl.
- **Spearhead** rises to 4 mounts and a second plate: "wins the 1v1 it initiates"
  is now backed by a grid that out-guns a Lancer, exactly the owner's ruling that
  a cruiser-class hull carries more than a fighter.
