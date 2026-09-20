# 02 — Minerals: the 20-Ore Catalogue

**Status:** Ready to code.
**Depends on:** 01 (income targets), `docs/design/STYLE_BIBLE.md` (names and
descriptions follow the grimdark vocabulary; no cutesy fantasy names).
**Consumed by:** 04 (refining), 05 (exchange), 07 (crafting requirements).

---

## 1. Design rules

1. **Two item states per mineral.** Each mineral exists as **raw ore**
   (mined, bulky, cheap) and **refined ingot** (processed, compact, worth
   more). Item ids are `mineral_<name>` and `ingot_<name>`. Refining is
   document 04's business; this document defines both ids because exchange
   pricing needs both.
2. **Cargo weight is the real constraint.** Every item has a `units` weight.
   The starting Vanguard holds 40 units. In v1 every mineral item — ore and
   ingot alike — weighs 1 unit; the refinery's **3:1 conversion** (04 §2)
   is what triples hold-value density, so a hold of ingots carries ~3× the
   credits of the same hold of raw ore. That density is the core decision of
   the loop: sell raw now, or spend a refining fee and a station visit to
   carry/sell far more later.
3. **Tiers gate progression.** Value per unit roughly doubles per tier. Higher
   tiers appear in more dangerous sectors, so better ships (bigger hold, more
   guns) earn more per trip. Tiers are properties of sectors; this document
   only tags each mineral.
4. **Twenty minerals, four tiers of five.** Five per tier keeps every tier's
   asteroid rolls interesting without a 20-row lookup for every rock.
5. **Sci-fi first, light fantasy allowed.** Two minerals (Voidglass, Emberite)
   are explicitly exotic. They obey the same numeric rules as the rest; their
   flavour differs, their math does not.

## 2. The catalogue

Values are **credits per unit at base exchange demand** (see 05 §4 for how
demand moves these). `ore/ingot value` columns are the *sell* baselines;
buy prices derive from them in 05 §5. All numbers are integers.

### Tier 1 — Common (sectors 1–2)

| # | Mineral | Ore id | Ingot id | Ore value | Ingot value | Character |
|---|---------|--------|----------|-----------|-------------|-----------|
| 1 | Iron | `mineral_iron` | `ingot_iron` | 18 | 65 | The everything metal. Structural plate, cheap barrels. |
| 2 | Copper | `mineral_copper` | `ingot_copper` | 22 | 80 | Wiring, coils, cheap capacitors. |
| 3 | Chromium | `mineral_chromium` | `ingot_chromium` | 25 | 90 | Plating alloy, armour weave. |
| 4 | Silicon | `mineral_silicon` | `ingot_silicon` | 28 | 100 | Wafers and lenses; feeds the component chain. |
| 5 | Aluminium | `mineral_aluminium` | `ingot_aluminium` | 20 | 72 | Light frames, engine cowlings. |

### Tier 2 — Uncommon (sectors 2–4)

| # | Mineral | Ore id | Ingot id | Ore value | Ingot value | Character |
|---|---------|--------|----------|-----------|-------------|-----------|
| 6 | Titanium | `mineral_titanium` | `ingot_titanium` | 45 | 162 | Backbone of serious hulls. |
| 7 | Nickel | `mineral_nickel` | `ingot_nickel` | 50 | 180 | Superalloys, heat exchangers. |
| 8 | Cobalt | `mineral_cobalt` | `ingot_cobalt` | 55 | 200 | Magnetics, shield emitter cores. |
| 9 | Tungsten | `mineral_tungsten` | `ingot_tungsten` | 65 | 235 | Mass drivers, penetrators, extreme heat. |
| 10 | Silver | `mineral_silver` | `ingot_silver` | 70 | 252 | Conductors and coatings; prettier than it is rare. |

### Tier 3 — Rare (sectors 4–6)

| # | Mineral | Ore id | Ingot id | Ore value | Ingot value | Character |
|---|---------|--------|----------|-----------|-------------|-----------|
| 11 | Gold | `mineral_gold` | `ingot_gold` | 110 | 395 | Circuitry plating. Worth mining, not wearing. |
| 12 | Platinum | `mineral_platinum` | `ingot_platinum` | 130 | 470 | Catalysts, fuel-cell membranes. |
| 13 | Neodymium | `mineral_neodymium` | `ingot_neodymium` | 150 | 540 | The magnet king. Drive coils, railgun rails. |
| 14 | Iridium | `mineral_iridium` | `ingot_iridium` | 170 | 610 | Near-indestructible contact points. |
| 15 | Osmium | `mineral_osmium` | `ingot_osmium` | 190 | 685 | Densest of the stable metals. Counterweights, penetrator tips. |

### Tier 4 — Exotic (sectors 6+, guarded fields)

| # | Mineral | Ore id | Ingot id | Ore value | Ingot value | Character |
|---|---------|--------|----------|-----------|-------------|-----------|
| 16 | Palladium | `mineral_palladium` | `ingot_palladium` | 300 | 1 080 | Exotic catalysts; half-way to the strange stuff. |
| 17 | Cerulite | `mineral_cerulite` | `ingot_cerulite` | 350 | 1 260 | Blue-veined crystal ore. Shield lattice feedstock. |
| 18 | Emberite | `mineral_emberite` | `ingot_emberite` | 400 | 1 440 | Warm to the touch. Reactor and weapon cores. Fantasy-adjacent. |
| 19 | Voidglass | `mineral_voidglass` | `ingot_voidglass` | 480 | 1 730 | Shards of something older than the colonies. Sensor optics and stranger things. Fantasy-adjacent. |
| 20 | Krillum | `mineral_krilium` | `ingot_krilium` | 600 | 2 160 | The apex ore. Trade name, not chemistry; no two refineries agree what is in it. |

### 2.1 Value curve at a glance

Ore value by tier: 18–28 → 45–70 → 110–190 → 300–600. Ingot value =
`round(3.6 × ore value)` to pretty integers — that is the 3:1 refinery
conversion at a +20 % bonus (04 §2). The doubling per tier is what makes
sector access worth ships; the 3.6× refine multiple is what makes the
refinery worth the fee (04 §2).

## 3. Data representation

The catalogue is one static data table (a `const` array of dictionaries in a
`game/mineral_catalog.gd`, mirroring `station_catalog.gd`'s style: data, no
logic). Per-entry keys:

- `&"id"`, `&"name"`, `&"tier"` (1–4),
- `&"ore_value"`, `&"ingot_value"` (int, credits, baseline),
- `&"ore_units"` (1), `&"ingot_units"` (1),
- `&"description"` (one line, STYLE_BIBLE voice),
- `&"icon_ore"`, `&"icon_ingot"` (res:// paths, Phase E asset work —
  provisional mapping in §6).

The ore/ingot pair for one mineral is one entry, not two; code that needs
ingot data reads the same row.

## 4. Value semantics (read before touching the numbers)

- `ore_value` / `ingot_value` are **baselines**, not fixed prices. The
  exchange applies its demand multiplier and commission on top (05 §2–5).
  Only 05 may compute a price from these numbers.
- **Refining pays +20 % in credits before the fee, and always triples hold
  density** (3 ore units → 1 ingot): 3 Iron ore sell raw for 54 CR
  baseline; 1 Iron ingot sells for 65 before the 15 CR fee — a wash at
  Tier I. Gold: 3 ore = 330 raw vs 1 ingot = 395 − 15 fee = **380, +15 %**.
  So low-tier ore is a sell-raw-or-bank decision, and higher tiers refine
  for real. The fee is what keeps the wash from becoming a no-brainer
  (04 §2 fixes the exact conversion).
- All values are whole credits. No item ever sells below 1 CR.

## 5. Asteroid generation (which rocks hold what)

Asteroids are gameplay objects that own a mineral and a yield. Generation is
per-sector with a tier table:

| Sector range | Tier mix (weights) | Notes |
|--------------|--------------------|-------|
| 1–2 | T1 100 % | home space; safe, thin pickings |
| 2–4 | T1 55 %, T2 45 % | the bread-and-butter belt |
| 4–6 | T2 40 %, T3 60 % | contested; enemies patrol |
| 6+ | T3 55 %, T4 45 % | guarded fields; exotics behind real resistance |

Within a tier, the five minerals are equally weighted (20 % each). Two rolls
per asteroid:

1. **Mineral roll** — tier, then uniform pick within tier.
2. **Yield roll** — `yield = base × variance`, where `base` is the tier's
   standard richness (v1: 6 ore units for T1 rocks, 5 for T2, 4 for T3,
   3 for T4) and `variance` is uniform 0.5–1.5. An average T1 asteroid
   thus carries 6 ore; a rich one 7–9. A full Cutter hold (40 units)
   takes ≈ 7 asteroids in a T1 field.

Sector assignments are data (a per-sector dictionary), so a later map system
can re-balance without touching the roll code.

## 6. Icons

The shipped icon set covers generic cargo glyphs (`icon_cargo_ore_48.png`
etc.), not 20 distinct minerals. Plan:

- **v1 (this phase):** every ore uses `icon_cargo_ore_48.png` tinted per
  tier (four tints), every ingot uses `icon_cargo_container_48.png` tinted
  per tier. The tint palette follows `docs/design/ICONS_SPEC.md` §1: neutral
  tiers use steel/gunmetal tones; the ember accent is reserved for danger
  states, so exotic tints use desaturated ember-adjacent ochres, never
  `#C8461B` itself.
- **Phase E (assets, not code):** a generated 5×4 mineral sheet in the
  ICONS_SPEC style, cut into `icon_mineral_<name>_{16,48}.png` and
  `icon_ingot_<name>_{16,48}.png`. The catalogue's `icon_ore`/`icon_ingot`
  keys make that swap a data edit.

## 7. Mining flow (what the miner does)

1. The player targets an asteroid with the mining laser (existing `mine`
   action). Each completed extraction cycle pops 1 ore unit worth of the
   asteroid's mineral, spawns a floating cargo pickup.
2. **Tractoring** is the existing pickup behaviour; a pickup that is not
   collected despawns after 60 s (data: `ORE_PICKUP_LIFETIME`).
3. **Hold full** → further pickups are not collected and stay drifting
   (bounded by pickup lifetime). No auto-sell, no auto-jettison.
4. When an asteroid's yield reaches 0 it cracks and despawns (existing
   mining FX spec covers the visual).
5. **Cargo identity, not homogenised sludge.** Ore is tracked per mineral in
   the `PlayerProfile` cargo manifest (`add_cargo(mineral_id, n)`), which the
   existing contract already supports (free-form ids, quantity stack).

## 8. Field respawn

Asteroid fields respawn on a timer per field:

- Full respawn: 20 minutes after a field is fully depleted.
- **Diminishing window:** any asteroid mined in a field within 5 minutes of
  its last respawn rolls yield at ×0.7 (01 §5.5). Implementation note: track
  per-field `last_depleted_time` and `last_respawn_time`; the ×0.7 applies
  when `Time.get_ticks_msec() - last_respawn_time < 300_000`.
- Respawn re-rolls minerals and yields with the same generation rules (§5);
  a respawned field is a fresh roll, which slowly averages out lucky/unlucky
  first visits.

## 9. Explicitly out of scope

- Prospecting/scan mini-game for hidden veins (later phase, new document).
- Asteroid combat (shooting rocks to break them faster) — the mining laser
  is the only extraction tool in v1.
- Player-owned refineries or storage silos — the station refinery (04) is
  the only processing node.
- Buying minerals from the exchange in v1 — the exchange buys; crafting
  requirements (07) are met from the player's own hold. A buy mode is a
  05 amendment if crafting demand makes it necessary.
