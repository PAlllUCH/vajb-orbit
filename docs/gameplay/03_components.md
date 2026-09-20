# 03 — Components: the Loot-and-Crafting Catalogue

**Status:** Ready to code.
**Depends on:** 01 (sink/faucet rules), 02 §2 (value scale reference).
**Consumed by:** 06 (drop tables), 07 (crafting recipes), 05 (selling).

---

## 1. What components are

Components are manufactured parts: the things enemies are *made of* and the
things future gear is *made from*. Unlike minerals, they are not mined; they
are **looted from wrecks** (06) and **crafted from ingots** (07). Components
are never raw materials of each other — crafting consumes components and
ingots, never components-into-components.

They serve three purposes:

1. **Combat income.** Selling salvage/components at the station is the
   fighter's credit stream (01 §3, S3).
2. **Crafting feedstock.** 07's recipes consume them to build gear better
   than StationCatalog stock.
3. **Loot identity.** Different enemies dropping recognisable parts makes
   combat feel material: a wrecked Freighter yields cargo machinery, a
   Corvette yields weapon systems.

## 2. Design rules

1. **Value tracks tier, and tier tracks the hulls that drop them.** The
   value column is the sell baseline in credits; it shares 02's tier ladder
   so a fighter's parts are worth roughly a tier-2 ingot.
2. **Components are light.** 1 cargo unit each (same as ingots). Fighting
   should never feel punishing on the hold.
3. **Six families, readable at a glance.** Each family maps to a future
   crafting slot and to the six shipped cargo glyphs (§4.1), so no new icon
   work is needed in v1.
4. **Not everything is worth selling.** Some components are cheap; their
   real purpose is crafting feedstock. The exchange's per-item stock limits
   (05 §6) keep players from dumping infinite salvage for credits.

## 3. The catalogue

18 components, six families × three grades. Grade I parts drop from
fighters/freighters, Grade II from corvettes, Grade III from the Maw and
elite wrecks (06 §3 fixes the tables).

### Family: Salvage (hull scrap) — icon `icon_cargo_salvage`

| Id | Name | Grade | Value (CR) | Used for (07) |
|----|------|-------|------------|----------------|
| `comp_scrap_1` | Torn Plating | I | 12 | basic hull refits |
| `comp_scrap_2` | Wreck Alloy | II | 30 | hull upgrades, repair drones |
| `comp_scrap_3` | Dreadnought Slag | III | 75 | capital-grade armour |

### Family: Machinery (drives and generators) — icon `icon_cargo_crate`

| Id | Name | Grade | Value (CR) | Used for (07) |
|----|------|-------|------------|----------------|
| `comp_mech_1` | Drive Coupling | I | 18 | engine refits |
| `comp_mech_2` | Generator Block | II | 45 | reactors, shield generators |
| `comp_mech_3` | Titan Drive Core | III | 110 | capital engines, reactor Mk3+ |

### Family: Electronics (computers and sensors) — icon `icon_cargo_data_core`

| Id | Name | Grade | Value (CR) | Used for (07) |
|----|------|-------|------------|----------------|
| `comp_elec_1` | Circuit Stack | I | 20 | targeting computers |
| `comp_elec_2` | Logic Array | II | 50 | scanners, guidance systems |
| `comp_elec_3` | Neural Core | III | 120 | fire-control AIs, advanced sensors |

### Family: Weapons (gun parts) — icon `icon_cargo_container`

| Id | Name | Grade | Value (CR) | Used for (07) |
|----|------|-------|------------|----------------|
| `comp_weap_1` | Barrel Assembly | I | 22 | kinetic weapons |
| `comp_weap_2` | Emitter Housing | II | 55 | lasers, plasma weapons |
| `comp_weap_3` | Maw Cannon Chamber | III | 130 | heavy weapons, rockets |

### Family: Power (energy storage) — icon `icon_cargo_fuel_cell`

| Id | Name | Grade | Value (CR) | Used for (07) |
|----|------|-------|------------|----------------|
| `comp_pow_1` | Fuel Cell | I | 15 | capacitors, boost systems |
| `comp_pow_2` | Capacitor Bank | II | 40 | shield capacitors, plasma feed |
| `comp_pow_3` | Ember Cell | III | 100 | exotic power systems |

### Family: Ore-Grade (refined exotic matter) — icon `icon_cargo_ore`

| Id | Name | Grade | Value (CR) | Used for (07) |
|----|------|-------|------------|----------------|
| `comp_ore_1` | Purged Ore | I | 25 | low-tier crafting catalyst |
| `comp_ore_2` | Lattice Seed | II | 60 | shield lattice crafting |
| `comp_ore_3` | Voidshard | III | 140 | exotic component crafting |

### 3.1 Value notes

- Grade averages: I ≈ 19 CR, II ≈ 47 CR, III ≈ 113 CR. These share the
  02 tier ladder (T2 ingots are 38–60, T4 ingots 260–520), so a fighter's
  haul and a tier-2 mining run pay in the same ballpark — by design (01
  §5.3: mining-only ≈ 15–20 % above combat-only).
- All component prices are **sell baselines** consumed by 05; like minerals,
  nothing else may price from them.

## 4. Data representation

One static table in `game/component_catalog.gd` (same style contract as 02
§3 — data, no logic). Per-entry keys:

- `&"id"`, `&"name"`, `&"family"` (`&"salvage"` | `&"mech"` | `&"elec"` |
  `&"weap"` | `&"pow"` | `&"ore_grade"`), `&"grade"` (1–3),
- `&"value"` (int, credits, baseline),
- `&"units"` (1),
- `&"description"`,
- `&"icon"` (res:// path, tinted per grade — see §4.1).

### 4.1 Icons

Components reuse the six shipped cargo glyphs (one per family, as tabled
above), tinted by grade: Grade I steel, Grade II gunmetal-bright, Grade III
ochre (`#8A6A50`), never the ember danger accent. This matches the 02 §6
tint plan and needs no new assets in v1. Phase E may add grade-styled
variants; the `&"icon"` key makes it a data edit.

## 5. Holding and selling

- Components stack in the `PlayerProfile` cargo manifest by id, 1 unit each
  (existing contract handles this unchanged).
- They sell at the station exchange panel alongside minerals (05 §6), with
  **per-item stock limits** (the station buys only so many of each grade per
  respawn cycle) so combat farming has a soft ceiling.
- Components are **not** consumed by refining (04) and are **not** traded on
  the dynamic mineral market — their prices are flat baselines plus the fixed
  commission. Simple, predictable, and distinct from mineral trading.

## 6. Explicitly out of scope

- Buying components from the station in v1 (they arrive only via loot and,
  later, crafting). 07's recipes are the first consumer; if crafting demand
  exceeds loot supply at playtest, a station "surplus parts" vendor becomes
  a 05 amendment.
- Component degradation or quality rolls. Grade is the only quality axis.
- Enemy crafting — enemies do not build anything in v1.
