# 09 — Ship Slots and Modules: the Eclipse-Style Fit System

**Status:** Ready to code.
**Depends on:** 08 (class slot grids, power output), 01 (price ladder),
`STATION_SPEC.md` §5.3 (existing upgrade effects — their lineage).
**Consumed by:** 10 (module acquisition), 07 (crafted modules), fitting UI
spec (future amendment to STATION_HUB.md).

---

## 1. Slot types

Nine slot types. ENGINE and POWER are mandatory and exactly one per hull
(08 §3). Every other slot type is optional capacity — an empty slot costs
nothing but is wasted potential.

| Type | Icon family | Mandatory | What plugs in |
|------|-------------|-----------|---------------|
| **ENGINE** | engine | 1, always | sublight drives: speed/acceleration |
| **POWER** | generator | 1, always | reactors: total power output |
| **W** (weapon) | weapons | no | hardpoint weapons (§4.1) |
| **S** (shield) | shield | no | shield generators and amplifiers |
| **H** (armour) | hull | no | armour plating: hull points at a speed cost |
| **C** (computer) | module | no | targeting, scanners, utility electronics |
| **B** (booster) | engine | no | one-shot burst systems: boost, afterburner |
| **U** (utility) | extra | no | cargo, drones, salvage gear, mining tools |

Note: **H armour is a slot, not a hull stat.** The hull's `hull` number
(08 §2) is base structure; every point beyond it is bought as plating that
masses something. This is the "more hull armour = slower" rule the system is
built on.

## 2. The power economy

Every non-ENGINE module has a **power draw**. A hull's fit is legal only
while `Σ draws ≤ power output` (08 §2's Power out column).

| Slot type | Typical draw |
|-----------|--------------|
| W weapon | 1–3 (by weapon, §4.1) |
| S shield gen | 2 (light), 3 (heavy) |
| H armour plate | 0 |
| C computer | 1 |
| B booster | 2 |
| U utility | 0–1 |

- **POWER modules raise the ceiling; ENGINE modules are free of the budget**
  (an engine draws from itself). The choice "bigger reactor or bigger guns"
  is therefore a real slot-vs-slot trade: both sit in the same grid.
- Draws and outputs are small integers on purpose: a player must be able to
  do the arithmetic in their head while fitting.
- Illegal fits are refused at the fitting panel with the overload shown
  (`13 / 11 PWR — OVER BY 2`); nothing auto-removes. The player chooses what
  to unplug.

## 3. Module catalogue

All modules are data (a `const` array in `game/module_catalog.gd`, same
contract style as 02 §3). `Tier` is I–III; acquisition per tier in 10 §3.
`Cost` is the credits baseline for the auction book (10 §2).

### 3.1 WEAPONS (W slots)

| Module | Tier | Draw | Family | Shield rule | Effect | Cost |
|--------|------|:----:|--------|-------------|--------|-----:|
| `w_laser` | I | 1 | energy | shields first; no hull damage while shield > 0 | laser hardpoint, 30 DPS, uses Laser Cells | 900 |
| `w_cannon` | I | 1 | kinetic | bypasses shields → hull | kinetic hardpoint, 45 DPS burst, Cannon Shells | 1 200 |
| `w_rocket` | II | 2 | missile | bypasses shields → hull | rocket pod, high alpha, Rocket rounds | 2 400 |
| `w_mine` | II | 1 | deployable | bypasses shields → hull | mine layer, area denial, Mine Rack | 1 800 |
| `w_plasma` | III | 3 | energy | shields first | plasma lance, 70 DPS, melts armour, Plasma Cells | 4 800 |
| `w_railgun` | III | 3 | kinetic | bypasses shields → hull | railgun, 60 DPS | 5 200 |

The `Family` and `Shield rule` columns are ENGINE_SPEC §4.1's amendment to
this table (families: energy / kinetic / missile / deployable / tool; the
shield rule is shields-first vs bypass). The mining laser (`w_mining`, §4
item 5) is family **tool** with shield rule **rocks only** — the same §4.1
table.

Existing five weapon ids (`laser`, `cannon`, `rocket`, `mine`, `plasma` in
`PlayerState.WEAPONS` and StationCatalog ammo packs) are the v1 subset; the
railgun is new and shares the cannon's ammo family in v1 or gets its own
pack in the ammo amendment — coder's choice, documented in the ammo table
when implemented.

The railgun's earlier "ignores 50 % of armour" effect is **retired**
(ENGINE_SPEC §4.1): armour plating is hull points, so there is nothing for a
weapon to ignore. Its 60 DPS and ammo situation are unchanged.

**Amendment 2026-09-20 (energy draw, 18_engine_spec §4.1/§4.4):** the weapon
families split by *what they consume while firing* — energy weapons (`w_laser`,
`w_plasma`) and the mining laser drain the **Energy pool** per second of fire
(rates 6/10/5 E/s in the §13 table, playtest-tunable), while kinetics spend
Cannon Shells, rockets Rocket rounds and mines Mine Rack — ammo as before,
no Energy. §2's small-integer power budget is the *fitting* budget and is
unchanged; the firing drain is the new in-flight resource, and a dry Energy
pool means an energy weapon that cannot fire while the pack-fed ones can.

### 3.2 SHIELDS (S slots)

| Module | Tier | Draw | Effect | Cost |
|--------|------|:----:|--------|-----:|
| `s_light` | I | 2 | +200 shield pool, regen 4/s | 1 400 |
| `s_heavy` | II | 3 | +400 pool, regen 5/s | 3 200 |
| `s_ion` | III | 3 | +350 pool, regen 9/s | 5 600 |

**Base shield regen is 2/s** with no shield module fitted (ENGINE_SPEC
§4.2) — the module regen above is added to that base, so the no-module case
still regenerates. Regen resumes 4 s after the last incoming damage.

Lineage: the existing `upgrade_shield` (+20 % shield max, 5 200 CR) is the
Cutter-era fit already priced above `s_heavy`; the crafted `Shield Lattice`
(07 §3) supersedes it in the crafting phase.

### 3.3 ARMOUR (H slots)

| Module | Tier | Draw | Effect | Cost |
|--------|------|:----:|--------|-----:|
| `h_plate_light` | I | 0 | +250 hull, −5 % speed | 1 100 |
| `h_plate_heavy` | II | 0 | +600 hull, −12 % speed | 2 900 |
| `h_composite` | III | 0 | +1 000 hull, −10 % speed, +10 % mass (boost weaker) | 5 800 |

Armour never draws power and never slows to a cliff: percentages are
multiplicative on the hull's base speed, and two heavy plates stack to
−24 % — survivable, but the Mule stays the slow king.

### 3.4 COMPUTERS (C slots)

| Module | Tier | Draw | Effect | Cost |
|--------|------|:----:|--------|-----:|
| `c_target` | I | 1 | targeting: +15 % weapon damage | 1 600 |
| `c_scanner` | I | 1 | +25 % scanner range | 1 500 |
| `c_twin` | II | 1 | second targeting stack: +15 % (stacks with `c_target`) | 3 400 |
| `c_ewar` | II | 1 | enemy targeting slowed 25 % while you are in their scan | 3 800 |
| `c_nexus` | III | 1 | +15 % weapon damage **and** +25 % scanner range and boosts `c_ewar` to 35 % | 6 400 |

Computers are the Frigate's speciality (2 C slots, 08 §3) and the only
slot type with explicit stacking rules: damage computers stack additively
(+30 % with both), scanner range uses the best single value.

### 3.5 BOOSTERS (B slots)

| Module | Tier | Draw | Effect | Cost |
|--------|------|:----:|--------|-----:|
| `b_afterburner` | I | 2 | +60 % speed for 3 s, 8 s cooldown, burns BOOST_FUEL 3.0/s while active (2026-09-20) | 1 900 |
| `b_fold` | III | 2 | Hyperdrive Dash: 400 units, 20 s cooldown, burns DASH_FUEL 25/burst, 0.8 s invulnerability (2026-09-20 rename) | 6 800 |

No Tier II booster: the jump from "go faster" to "teleport" is the
progression beat. Boosters interact with armour mass (§3.3).

### 3.6 UTILITY (U slots)

| Module | Tier | Draw | Effect | Cost |
|--------|------|:----:|--------|-----:|
| `u_cargo` | I | 0 | +15 cargo units | 1 200 |
| `u_salvage` | I | 0 | wreck pickups tractored at 2× range/speed | 1 000 |
| `u_refine` | II | 1 | 1 U slot on the hull: refinery fee −50 % for its ore | 2 600 |
| `u_drones` | II | 1 | repair drone bay: hull regen 2/s in space | 3 000 |
| `u_tractor` | II | 1 | +1 pickup stream (collect 2 drifting pickups at once) | 2 200 |
| `u_holds` | III | 0 | +40 cargo units | 4 500 |

Lineage: `upgrade_extra_cargo` (+25 % cargo, 3 000 CR) and
`upgrade_drone` (+50 % repair rate, 6 800 CR) are the existing catalog's
U-slot ancestors; `u_refine`/`u_tractor` are the Delver's reason to exist.

### 3.7 ENGINES (mandatory)

| Module | Tier | Draw | Effect | Cost |
|--------|------|:----:|--------|-----:|
| `e_std` | I | — | 100 % base speed (reference engine, standard fit) | 800 |
| `e_ion` | II | — | +15 % speed (the old Ion Drive, 3 800 CR, rebased) | 3 200 |
| `e_vector` | III | — | +25 % speed, +20 % turn rate | 6 200 |

Lineage: `upgrade_engine` (+15 % speed, 3 800 CR) maps 1:1 to `e_ion`.

### 3.8 POWER (mandatory)

| Module | Tier | Draw | Effect | Cost |
|--------|------|:----:|--------|-----:|
| `p_std` | I | — | hull's Power out column (reference reactor) | 900 |
| `p_mk2` | II | — | +2 power output (the old Reactor Mk2, rebased) | 3 600 |
| `p_core` | III | — | +4 power output | 7 000 |

Lineage: `upgrade_generator` (+30/+20 % regen) does **not** carry over as a
power module — regen moves to shield modules (§3.2) where it belongs; the
existing upgrade retires into the auction book as a legacy entry (10 §5).

## 4. Fit rules (the actual constraints)

1. **Mandatory pair:** a fit without exactly one ENGINE and one POWER
   module cannot launch. The panel marks these slots with the ember accent
   when empty (danger semantics, ICONS_SPEC §1).
2. **Power budget:** Σ module draws ≤ hull power output + power module
   output (§2).
3. **One module per slot, slots are typed:** a weapon never sits in an H
   slot. No dual-fitting, no adapters.
4. **The Obliterator crunch (08 §6):** with `p_std`, seven top weapons +
   shields do not fit the 15-power budget. The intended endgame fit chain is
   `p_std` → `p_mk2` → `p_core`, spending 3 600/7 000 CR to unlock the grid
   the hull advertises. This is the progression guideline in action.
5. **Mining laser rule (user decision):** the mining laser is a **weapon
   module** (`w_mining`, Tier I, draw 1, cost 600) that occupies a W slot.
   Any hull that gives up a gun for it can mine; the Delver mines *well*
   because its U slots carry `u_refine`/`u_tractor` and its power output
   (10) runs a mining laser plus shields without starving. The mining laser
   is also how the fighter can dabble in mining, exactly as the user specced:
   1 weapon slot buys the ability, at the price of one gun.
6. **Swapping is free at the station; modules are never destroyed by
   removing** — they go to the player's module inventory (10 §6).
   In-space refitting does not exist in v1.

## 5. Stats resolution order

For the coder: how hull + modules become the live `PlayerState` stats.

1. Start from hull base (08 §2): structure, base speed, power out, cargo 0*.
2. Add flat module effects (shield pools, hull plates, cargo units, power
   output).
3. Apply multiplicative effects in this order: speed modifiers (armour, then
   engine, then booster-on-activation) → damage modifiers (computers) →
   scanner (best value) → regen (best value).
4. Clamp: nothing may reduce speed below 40 % of hull base, or raise a
   pool above 3× hull base.

\* `cargo_max` in the frozen stats (25–80) is re-expressed as the class's
**base hold** (structural space), and `u_cargo`/`u_holds` add on top. The
frozen numbers remain reachable: Cutter base 40 with no U module equals the
old Vanguard stat; the +25 % Cargo Expansion's value lives on as `u_cargo`'s
design space. **The frozen catalog entries themselves are untouched** — this
is a stats *interpretation* for the slot system, not a rebalance of
STATION_SPEC §5.2.

## 6. Balance ledger (per-class reference fits, for playtests)

Target: at equal credits spent, no class's best fit is dominant outside its
role. The coder implements the tables; the ledger is what playtests check.

| Class | Reference fit (≈ cost) | Expected performance |
|-------|------------------------|----------------------|
| Fighter | 3× `w_laser`, `s_light`, `h_plate_light`, `e_std`, `p_std` (≈ 9 k) | fastest TTK in Tier-I fights, dies to focus fire |
| Cutter | 2× `w_cannon`, `w_laser`, `s_light`, `h_plate_light`, `c_target` (≈ 12 k) | steady, flexible, no weakness to exploit |
| Delver | `w_mining`, 3× U (refine/tractor/cargo), `s_light` (≈ 11 k) | mining income +40 % vs Cutter fit; loses any fight |
| Courier | 3× U (cargo×2, salvage), `e_ion`, `c_scanner` (≈ 12 k) | trade bonuses (10 §4); can outrun most threats |
| Spearhead | 3× `w_cannon`, `s_heavy`, `b_afterburner` (≈ 15 k) | wins the 1v1 it initiates, struggles in prolonged brawls |
| Mule | `h_plate_heavy`×2, `s_light`, `w_cannon`, 4× U cargo (≈ 16 k) | 200+ effective cargo; escapes anything it cannot kill |
| Bulwark | 5× mixed W, `s_heavy`×2, `h_plate_heavy` (≈ 20 k) | stationary fort; DPS wall at close range |
| Warden | 4× W, 2× C (twin/nexus), `s_ion` (≈ 24 k) | counter-build platform; beats mirror-price fits it has scanned |
| Obliterator | 7× W (mixed), `p_core`, `s_ion`, 2× `h_composite` (≈ 40 k) | the wall; slow, nearly unkillable, power-starved until `p_core` |

## 7. Starter fit (what a new player owns)

The Vanguard starts with the **standard fit, included in its 18 000 CR
price**: `e_std`, `p_std`, 1× `w_laser`, `s_light`, `h_plate_light`. This
matches the frozen stats (1 000 hull + 250 plate ≈ the historical 1 000 /
600 shield feel) and gives the fitting panel something to show on day one.
The Lancer's frozen price likewise includes a lighter standard fit
(2× `w_laser`, `s_light`). All other hulls are bought **bare** (10 §2) —
the standard fit is a starter courtesy, not a class rule.
