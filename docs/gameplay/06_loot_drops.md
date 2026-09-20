# 06 — Loot: Enemy Drops and Wreck Yields

**Status:** Ready to code.
**Depends on:** 01 (faucet S3/S4), 03 (component catalogue), 05 §4 (surplus
stock quotas).
**Consumed by:** enemy spawn/wreck code; 07 (component supply).

---

## 1. Design rules

1. **Loot is physical.** Every drop spawns as a floating cargo pickup with
   the same tractor/lifetime behaviour as ore (02 §7). A kill pays nothing
   until the player picks the wreck clean — combat and cargo compete for the
   same hold, which is the tension the game is built on.
2. **Data-driven tables only.** Drop tables are data dictionaries next to
   the component catalogue. Changing drop rates is an edit to a table, never
   to a script (01 §3, economy-skill rule).
3. **Small tables, readable odds.** Each hull rolls 1–3 line items. No
   12-line tables, no pity systems in v1.
4. **Grade follows hull.** A hull's table can only contain component grades
   at or below its own band (§3). The Maw is the only Grade III source.

## 2. The drop-roll procedure

On hull destruction, one roll per line of the hull's table, in order:

1. Roll `chance` (0–1). Fail → nothing from this line.
2. Pass → amount = `randi_range(min, max)` units of the item.
3. Each unit becomes one floating pickup (or one pickup per stack of the
   same item; implementer's choice — pick one and keep it consistent).
4. **Credit caches** (§5) roll last and always spawn as a single
   distinct pickup (so a credit gain is visible as a moment, not merged
   into scrap).

Odds are **independent per line** (not normalised weights): two lines can
both pay, and empty kills happen. Empty-kill rate per hull is a design
number below and is checked in §6.

## 3. Drop tables

### 3.1 Fighter (hull band: Grade I)

| Line | Item | Chance | Amount |
|------|------|--------|--------|
| 1 | `comp_scrap_1` (Torn Plating) | 0.55 | 1–2 |
| 2 | `comp_weap_1` (Barrel Assembly) | 0.30 | 1 |
| 3 | `comp_pow_1` (Fuel Cell) | 0.35 | 1–2 |
| 4 | `comp_elec_1` (Circuit Stack) | 0.20 | 1 |
| 5 | `cm_chaff` (Chaff Dispenser) | 0.15 | 1 |
| 6 | `cm_flare` (Flare Pack) | 0.15 | 1 |

Expected haul per fighter: ≈ 1.1 items, ≈ 20 CR baseline value.
Empty-kill probability ≈ 17 %.

**Amendment 2026-09-20 (18_engine_spec §4.6):** lines 5–6 add the slice-2
countermeasures — `cm_chaff` breaks locks with 3 ghost signatures for 3 s,
`cm_flare` lures seeker rockets within 450 u. Each enters the fighter table
at 0.15 chance and may enter the swarmers' table (slice-2 W3) at the same
weight; the freighter/corvette/dreadnought tables are untouched. Expected
haul figures above predate the amendment and are re-checked in the wave
report, not by hand here.

### 3.2 Freighter (Grade I, cargo-flavoured)

| Line | Item | Chance | Amount |
|------|------|--------|--------|
| 1 | `comp_scrap_1` (Torn Plating) | 0.60 | 2–3 |
| 2 | `comp_mech_1` (Drive Coupling) | 0.35 | 1 |
| 3 | `comp_ore_1` (Purged Ore) | 0.30 | 1–2 |
| 4 | Credit cache (§5, small) | 0.15 | 40–80 CR |

Expected haul per freighter: ≈ 1.6 items + occasional cache, ≈ 40 CR.
Freighters are the "profit target": slow, fat, rewarding, defended.

### 3.3 Corvette (Grade II, elite variant of the v1 roster)

| Line | Item | Chance | Amount |
|------|------|--------|--------|
| 1 | `comp_scrap_2` (Wreck Alloy) | 0.50 | 1–2 |
| 2 | `comp_weap_2` (Emitter Housing) | 0.30 | 1 |
| 3 | `comp_mech_2` (Generator Block) | 0.25 | 1 |
| 4 | `comp_elec_2` (Logic Array) | 0.20 | 1 |
| 5 | Credit cache (§5, medium) | 0.10 | 120–250 CR |

Expected haul per corvette: ≈ 1.3 items, ≈ 60 CR + caches. Corvettes are
rarer in v1 spawns; the table is written now so the v1 roster needs no
amendment when they enter the rotation.

### 3.4 Maw dreadnought (boss; only Grade III source)

| Line | Item | Chance | Amount |
|------|------|--------|--------|
| 1 | `comp_scrap_3` (Dreadnought Slag) | 1.00 | 3–5 |
| 2 | `comp_mech_3` (Titan Drive Core) | 0.75 | 1–2 |
| 3 | `comp_weap_3` (Maw Cannon Chamber) | 0.60 | 1 |
| 4 | `comp_elec_3` (Neural Core) | 0.40 | 1 |
| 5 | `comp_ore_3` (Voidshard) | 0.25 | 1 |
| 6 | Credit cache (§5, large) | 1.00 | 800–1 200 CR |

Guaranteed minimum: line 1 + line 6 always pay. A Maw kill is a
progression event: **≈ 500–900 CR minimum, up to ≈ 1 300+ with all lines**,
plus the only Voidshard source in v1.

## 4. Wreck persistence

- A destroyed hull leaves a **wreck site** (non-hostile, visible on the
  minimap as a distinct blip) holding its uncollected pickups for 90 s
  (`WRECK_PICKUP_LIFETIME`), after which pickups despawn.
- The player may disengage and return to collect within the window;
  the window is the only persistence. No wreck saving across sessions in v1.
- Wreck pickups use the same hold-full rule as ore (02 §7.3).

## 5. Credit caches

A credit cache is a pickup that, on collection, calls
`PlayerProfile.add_credits(amount)` directly (faucet S4, 01 §3). Rules:

- Always a distinct visual pickup (the existing salvage glyph, tinted
  bright) with a one-line HUD feed line: `+120 CR SALVAGE`.
- Only the amounts in §3's tables exist. No other system may mint credits
  (01 §3).
- Caches bypass cargo entirely: they are money, not goods.

## 6. Balance checks (verify against 01 §5.3)

Per 10-minute mixed session (1 §5.3): 2–4 fighter kills + maybe 1 freighter
≈ 80–160 CR baseline loot value, rising to 200–500 with luck and caches —
matching S3's target band. Two invariant checks the coder's tests should
assert:

1. **Expected value per hull class** equals the sums above (±5 %, because
   `randi_range` bounds are inclusive).
2. **Grade caps:** no table references a component grade above its hull
   band; this is assertable directly against the 03 catalogue at load time.

If combat income needs tuning later, change `chance` and `amount` bounds in
these tables only (01 §8 lever 3). Grade III amounts are the strongest lever
because the Maw is rare.

## 7. Growth path (documented, not built in v1)

- **Richer tables** for new hull classes (Phase D roster expansion, 15
  classes) follow the same format; a hull gets a band, a band gets a table.
- **Sector-scaled caches:** if the exchange economy needs a combat-income
  bump after playtest, multiply cache ranges by sector tier (×1 T1–T2,
  ×1.5 T3, ×2 T4) rather than touching component odds.
- **Rare "signature" drops** (named unique components) are a 07 amendment
  when crafting ships, not a loot change.
