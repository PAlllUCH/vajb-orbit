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
   takes ≈ 7 asteroids in a T1 field. **Superseded by §5.1 (2026-09-25)** —
   true only while every size class rolls the tier base; reversal is that
   amendment's.

Sector assignments are data (a per-sector dictionary), so a later map system
can re-balance without touching the roll code.

### 5.1 Amendment 2026-09-25 — ore is a budget, and the rocks get bigger

Two owner asks from the same ruling: shooting rocks must stay possible but
never out-earn mining (`01 §5.6` carries the invariant and the measured why),
and **"asteroids could be bigger with more yield, in bigger clusters, maybe
even some asteroid fields?"**

**Rule A — no method mints ore.** A rock's ore is realised by extraction and by
nothing else. Guns still break rocks (`GUN_CHIP_RATE` 0.10, 18_engine_spec
§6/§17, untouched) but a gun-cracked rock *realises* at most
`GUN_BURST_SHARE` = **0.10** (owner-ticked 2026-09-25) of its **own original** yield, and only
through the Small-end burst. Cleaving **redistributes** and never re-rolls: a
fragment's ore comes from the parent's own budget, not from a fresh
`TIER_BASE_YIELD` roll, so `Σ` ore in a field is conserved.

The fragment's half of that budget is a real choice, because a rock that cracks
has already given up its extractable ore (mined out, or chipped out by guns) —
so a naive "fragments inherit what is left" hands them nothing:

- **`FRAGMENT_CORE_SHARE` 0.0 (not ticked):** fragments are physical
  debris — they collide, block shots, and can be shot — and carry no ore.
  Simplest rule; the owner's 2026-09-21 "they should explode, 2-5 fragments"
  is untouched, because that ruling is about the break, not about a payout.
- **`FRAGMENT_CORE_SHARE` 0.25 (OWNER-TICKED 2026-09-25 — the shipped rule):**
  a quarter of the
  parent's own yield is set aside at setup and never directly extractable, so
  the crack hands it to the fragments and the field's budget simply splits
  between "mine before the break" and "mine the pieces". Mining still realises
  100 % of a rock's `extractable` units (01 §5.6 holds); the reserve is what
  pays for the shatter, whichever route broke it.

Reversal: `GUN_BURST_SHARE` → 1.0, `FRAGMENT_CORE_SHARE` → "inherit the parent's
remaining yield, i.e. 0", and the fragment re-roll restored (`CONTRACTS.md` §5's
"yield re-rolled through the 02 §5 path", line 350; §14's fragment-burst bullet
is the deployment half and is not in question) — the state a fully worked T1
Large rock turns into ≈100 ore units from its own 6.

**Rule B — scale. DEFERRED 2026-09-25** (owner: mining yield is fine as-is; the
scale rows, the ⅓-of-hold guard and the T4 re-derivation return only with a
bigger-rock ask — nothing below is ticked or implemented). Direction, every
number **proposed** and reversible:

| Lever | Shipped | Proposed | Why |
|---|---|---|---|
| yield by size class | one flat tier base for every size (`TIER_BASE_YIELD` 6/5/4/3) | `SIZE_YIELD_MULT` S 1, M 2, L 4 **on top of** the tier base (T1: ≈6 / ≈12 / ≈24 units) | a Large becomes a prize worth flying to instead of a same-stat target |
| clustering | rocks scattered uniformly over the field | 2-4 **veins** of 3-9 rocks sharing one mineral and tier, placed as one formation | a field reads as geography; a vein is one sitting's work and lets a miner plan a run |
| field size | `FIELD_ROCKS_MAX` 12 rocks, uniform scatter | per-vein 3-9 × 2-4 veins = 6-36 rocks, a field budget of ≈40-860 units in T1 (average ≈200) | a field stops being a 70-unit puddle; 02 §8's respawn timer then guards something worth guarding. Careful: at 3-8 rocks per hold that is 1-12 holds per field (≈5 typical), so the field count, the hold ladder and §8's respawn/diminishing rules move together |
| where | one look row per rock | unchanged size roll and look; `asteroid.gd`'s "the size class is a look and never a stat" becomes **"a look and the yield class, never a throughput stat"** | §5's own rule is kept in the half that matters: a Small and a Large both mine one unit per `MINE_CYCLE` (1.2 s). Size gates *total* ore, never the rate |

**Guard rail, and the open question it leaves.** Size is the *spread*, the
field's nominal rock is the *scale*. Two rules, both derivable:

1. **A hold is 3-8 rocks** of the field's own tier and hull (01 §5.1's own
   "≈7 asteroids" is the small end of that). With `SIZE_YIELD_MULT` S 1 / M 2 /
   L 4 on T1's base 6, a Vanguard hold of 40 is 24 + 12 + 6 = 42 — three rocks
   if the player takes what it meets, ~7 if it works Smalls. Deep tiers carry
   the bigger holds (Delver 55, Mule 120) against bigger rocks.
2. **No single rock exceeds ~⅓ of the hold that carries it**, so a rock is
   never the whole trip.

The real open question is the tier curve, not the size spread: T4 ore pays
300-600 CR per unit, so even the small end (base 3) is 900-1 800 CR for a
*Small*. `TIER_BASE_YIELD` (6/5/4/3) was written when every rock was the same
size and only the ore's value per unit carried progression; once size spreads
the count, the base yields and 02 §2's ore values have to be re-derived
**together**, or the deep fields pay a session's income per rock. The cheap
variant, if the owner prefers it, is to gate the big sizes to the deeper tiers
instead of scaling every tier — T1/T2 keep today's yields (a fresh player still
works 6-9-unit rocks and a 40-unit hold is still ~7 rocks, which is exactly
01 §5.1's session), and the big rocks arrive with the hulls that can carry them.

**Co-design, not optional:** the numbers above are a *pack* — the size spread,
the field count, §8's respawn/diminishing rules and the hold ladder (08 §2) move
or fail together. A size spread shipped without the guard rail fills a hold from
one rock (today's cargo symptom, made worse); a field growth shipped without §8
turns one field into a multi-session farm.

Reversal: `SIZE_YIELD_MULT` all 1, one rock per vein (i.e. shipped scatter),
`FIELD_ROCKS_MAX` 12, 08 §2's holds unchanged, and this subsection's Rule A
reverted by its own reversal line.

Owner ticks: Rule A's `GUN_BURST_SHARE` and the fragment-core choice
(0.0 vs 0.25); the four Rule B rows, or the gating-the-deep-tiers variant
instead; the ⅓-of-hold rule; whether veins
are placed by the sector generator or authored per sector (11's map is the
natural owner); `18_engine_spec.md` §6/§13/§17's wording and `CONTRACTS.md`
§5's fragment-yield and gun-work sentences (lines 350 and 374), which this doc
cannot change.

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
  **Not** §5.1's veins: those are generated formations a player can see and fly
  to, with no scan mechanic and no hidden information.
- Asteroid combat (shooting rocks to break them faster) — the mining laser
  is the only extraction tool in v1. **Amended 2026-09-25 (§5.1 Rule A):**
  the "out of scope" half is retired — shooting rocks is **in scope** (it breaks
  them, and it stays useful: clearing a lane, breaking cover, stripping a rock
  under fire) — but it realises at most `GUN_BURST_SHARE` of a rock's own yield,
  so the mining laser remains the only *extraction* tool and mining is always
  the more profitable route. This bullet and 18_engine_spec §6/§17 ("regular
  weapons can also break rocks, at 10 % efficiency") disagreed; the owner's
  2026-09-25 ruling resolves it this way. Reversal: delete the "Amended"
  clause above (the bullet then reads as shipped again) and apply §5.1 Rule A's
  own reversal.
- Player-owned refineries or storage silos — the station refinery (04) is
  the only processing node.
- Buying minerals from the exchange in v1 — the exchange buys; crafting
  requirements (07) are met from the player's own hold. A buy mode is a
  05 amendment if crafting demand makes it necessary.
