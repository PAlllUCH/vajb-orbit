# 09 — Ship Slots and Modules: the Eclipse-Style Fit System

**Status:** Ready to code.
**Depends on:** 08 (class slot grids, power output), 01 (price ladder),
`STATION_SPEC.md` §5.3 (existing upgrade effects — their lineage).
**Consumed by:** 10 (module acquisition), 07 (crafted modules), fitting UI
spec (future amendment to STATION_HUB.md).

---

## 1. Slot types

Eight slot types. **ENGINE and POWER are mandatory, and the engine is a set, not
a single slot**: a hull has as many ENGINE cells as 08 §3.1 gives it (1–3) and
every one of them must be filled to launch (§4.1). POWER stays exactly one per
hull. Every other slot type is optional capacity — an empty slot costs nothing
but is wasted potential.

**Amendment 2026-09-21 (owner request: per-class counts and layouts).** The
`Count` column is new and is the class's own cell count, read from 08 §3's grid
matrix. The icon column now names the shipped **slot glyph** (the cell's face in
the layout display), because the slot art exists:
`vajb-orbit/assets/icons/slot/icon_slot_{engine,power,w,s,h,c,b,u}_{16,48,96,192}.png`.

| Type | Count | Slot glyph | Mandatory | What plugs in |
|------|-------|-----------|-----------|---------------|
| **ENGINE** | 1–3, per class (08 §3.1) | `icon_slot_engine` | all of them | sublight thrusters: speed/acceleration |
| **POWER** | 1 | `icon_slot_power` | yes | reactors: total power output |
| **W** (weapon) | 1–7, per class | `icon_slot_w` | no | hardpoint weapons (§4.1) |
| **S** (shield) | 1–3, per class | `icon_slot_s` | no | shield generators and amplifiers |
| **H** (armour) | 1–4, per class | `icon_slot_h` | no | armour plating: hull points at a speed cost |
| **C** (computer) | 1–2, per class | `icon_slot_c` | no | targeting, scanners, utility electronics |
| **B** (booster/drive) | 0–1, per class | `icon_slot_b` | no | burst drives: afterburner, fold dash |
| **U** (utility) | 0–5, per class | `icon_slot_u` | no | cargo, drones, salvage gear, mining tools |

**Vocabulary, so briefs and code agree:** *engines* are the ENGINE cells
(sublight thrusters, `e_std`/`e_ion`/`e_vector`); *drives* are the B cells
(one-shot burst systems, `b_afterburner`/`b_fold`); *hull* cells are the H cells
(armour plating, `h_plate_*`/`h_composite`). "Hull" as a stat (the `hull` number
of 08 §2) is base structure and is **not** an H cell.


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
  (an engine draws from itself, however many the hull carries). The choice
  "bigger reactor or bigger guns" is therefore a real slot-vs-slot trade: both
  sit in the same grid.
- **A hull's engine count never changes its budget.** A 3-engine Hauler pays the
  same power for its thrusters as a 1-engine Lancer — zero. What the count buys
  is granularity (§3.7) and the mass the hull already carries (08 §3.1).
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

### 3.7 ENGINES (mandatory set)

| Module | Tier | Draw | Effect | Cost |
|--------|------|:----:|--------|-----:|
| `e_std` | I | — | 100 % base speed (reference engine, standard fit) | 800 |
| `e_ion` | II | — | +15 % speed (the old Ion Drive, 3 800 CR, rebased) | 3 200 |
| `e_vector` | III | — | +25 % speed, +20 % turn rate | 6 200 |

Lineage: `upgrade_engine` (+15 % speed, 3 800 CR) maps 1:1 to `e_ion`.

**Amendment 2026-09-21 — how N engines stack (new rule).** A hull with E engine
cells fits one engine module per cell, and the resolved multipliers are the
**sum of the modules' deltas, never their product**:

```text
speed_mult = 1 + Σ (module.speed_mult - 1)
turn_mult  = 1 + Σ (module.turn_mult  - 1)
speed_mult is then clamped to ENGINE_MULT_CEILING = 1.40
```

Three consequences the coder and the balance ledger both rely on:

1. **No duplicate module id inside one hull.** `e_std` + `e_std` is legal (both
   are the reference engine), but `e_vector` + `e_vector` is refused by the fit
   validator — one of each engine per hull, exactly like the computers' stacking
   rule (§3.4). With three cells the best legal set is
   `e_std` + `e_ion` + `e_vector` = **1.40**, which is why the ceiling is 1.40.
2. **A single engine resolves exactly as it did before this amendment** —
   `e_vector` alone is `1 + 0.25` = 1.25, the same figure the multiplication
   gave. Nothing in the shipped Vanguard fit moves.
3. **Bigger hulls climb in steps, not in leaps.** A 3-engine Hauler can buy its
   1.40 in three purchases of ~3 200 CR; a 1-engine Lancer must buy the single
   best engine (6 200 CR) to reach 1.25. Same ceiling, different curve — that is
   what an engine *count* buys.

Reversal: multiply the modules' multipliers per engine again (the pre-amendment
behaviour) and delete the duplicate rule and the ceiling; the only fits that
resolve differently are those with two identical engines, which the rule above
forbids anyway.


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

1. **Mandatory set:** a fit without every ENGINE cell filled (08 §3.1) and
   exactly one POWER module cannot launch. The panel marks these slots with the
   ember accent when empty (danger semantics, ICONS_SPEC §1). In practice they
   are never empty: a hull is delivered with its mandatory set (§7).
2. **Power budget:** Σ module draws ≤ hull power output + power module
   output (§2).
3. **One module per slot, slots are typed:** a weapon never sits in an H
   slot. No dual-fitting, no adapters.
4. **No duplicate module id inside one hull** for the types whose effects stack
   from the same module (ENGINE §3.7, COMPUTER §3.4): `e_ion` twice is refused,
   `e_ion` + `e_vector` is not. Armour, shields, weapons and utility modules may
   repeat, because their rows are written to repeat (two heavy plates are an
   intended fit).
5. **Slots are addressed by the layout index (new).** A fit is
   `slot_type -> Array[module_id]`, index 0..n-1 in the order the type's cells
   appear in 08 §3.2's matrix (row-major, top-left first). An empty cell is `""`
   (or a missing tail), so a 3-engine hull's `engines` array is three long even
   when two are `e_std`. The layout display, the fitting panel and the saved
   profile all use that same index — there is no second ordering.
6. **The Obliterator crunch (08 §6):** with `p_std`, seven top weapons +
   shields do not fit the 15-power budget. The intended endgame fit chain is
   `p_std` → `p_mk2` → `p_core`, spending 3 600/7 000 CR to unlock the grid
   the hull advertises. This is the progression guideline in action.
7. **Mining laser rule (user decision):** the mining laser is a **weapon
   module** (`w_mining`, Tier I, draw 1, cost 600) that occupies a W slot.
   Any hull that gives up a gun for it can mine; the Delver mines *well*
   because its U slots carry `u_refine`/`u_tractor` and its power output
   (10) runs a mining laser plus shields without starving. The mining laser
   is also how the fighter can dabble in mining, exactly as the user specced:
   1 weapon slot buys the ability, at the price of one gun. **Its door (P2-B1
   close-out, 2026-09-22):** OUTFITTING's `MODULES` rows sell it — the row set is
   09 §3.1's six plus `w_mining` (CONTRACTS §12), so the swap is reachable in
   play; reversal: drop the id from `MODULE_ROWS`.
8. **Swapping is free at the station; modules are never destroyed by
   removing** — they go to the player's module inventory (10 §6).
   In-space refitting does not exist in v1. **Interim note 2026-09-22 (P2-B1,
   the weapon fit surface):** until the AUCTION module (10 §2) exists, the
   surface that buys the weapon modules into the inventory is **OUTFITTING**
   (`STATION_HUB.md` §5.1's amendment; the same note is in 10 §6), and those
   rows retire into AUCTION when it ships. The surface that then fits,
   swaps and removes those modules per cell is **FITTING** (`STATION_HUB.md`
   §5.3; items 9 to 13 below).
9. **Per-cell install is one composed transaction (`fit_module_at`).** The
   fitting surface's install and swap are the single call
   `PlayerProfile.fit_module_at(ship_id, slot_key, index, module_id)`
   (CONTRACTS §13). It refuses (false, no write) when the hull is not one of
   the nine; the slot key is not in `FitData.FIT_SLOT_KEYS`; the index is
   outside `0 .. slot_capacity-1`; `module_count(module_id) == 0`; or the
   candidate fit fails `ShipFit.fit_legal` (the candidate being
   `fit_for(ship_id)` with that one cell set to `module_id`). On success, in
   this order: the displaced module (when the cell was non-empty) returns
   with `add_module`; `take_module(module_id, 1)`;
   `set_fit_slot(ship_id, slot_key, index, module_id)`; one log line
   (`EVENT_FIT_MODULE`); and both `profile_changed(&"fits")` and
   `profile_changed(&"modules")`. Every refusal precedes every write, and
   the displacement happens before the take, so a swap can never lose the
   displaced module.
10. **Per-cell remove is composed too, and a mandatory cell is never
    emptied.** `PlayerProfile.clear_fit_slot(ship_id, slot_key, index)`
    takes the same guards as item 9, plus a key in
    `FitData.MANDATORY_SLOT_KEYS` (`[&"engines", &"power"]`, §4.1, the one
    source) is always refused, so the mandatory set is never empty from the
    panel. The cell's module returns to the inventory with `add_module`;
    the cell is written `&""`; one log line (`EVENT_FIT_MODULE` with the
    module id, qty 1, delta 0); both keys emit. `clear_fit` stays as it is,
    the whole-fit reset used by the seed and the tests (CONTRACTS §13).
11. **Legality is previewed once and re-checked once, both through the same
    function.** The fitting pane calls `ShipFit.fit_legal` on the candidate
    fit to colour the power meter and to gate its ACTION; `fit_module_at` /
    `clear_fit_slot` re-check on commit. Both read the same function, and
    nothing auto-removes on an illegal fit (§2).
12. **The pane never mutates directly.** Panels request, the profile
    mutates (STATION_HUB §12.4). The fitting surface may only call the two
    composed APIs, `fit_for`, `module_count`, `modules`, `ShipFit.*` and
    `Repairs.*` (CONTRACTS §13).
13. **The legacy six-row UPGRADES surface retires into the module
    inventory.** The six `StationCatalog.UPGRADES` rows, `upgrade()`,
    `upgrade_ids()`, `has_upgrade`, `installed_upgrades`, `install_upgrade`
    and the profile's `upgrades` record are removed; a v4 file with all six
    upgrades installed loads as six inventory modules (one each) and no
    upgrade records, and a v5 file has no `upgrades` record at all
    (`retire_legacy_upgrades`, idempotent, called from the load path when
    the file's version is below 5; CONTRACTS §13). The fitting surface
    itself is **FITTING** (`STATION_HUB.md` §5.3).

## 5. Stats resolution order

For the coder: how hull + modules become the live `PlayerState` stats.

1. Start from hull base (08 §2): structure, base speed, power out, cargo 0*.
2. Add flat module effects (shield pools, hull plates, cargo units, power
   output).
3. Apply multiplicative effects in this order: speed modifiers (armour, then
   the engine set's summed deltas §3.7 clamped to 1.40, then
   booster-on-activation) → damage modifiers (computers) → scanner (best value)
   → regen (best value).
4. Clamp: nothing may reduce speed below 40 % of hull base, or raise a
   pool above 3× hull base.

**Amendment 2026-09-21:** step 3's engine term is now the **sum of the engine
set's deltas applied once** (§3.7) instead of a per-engine multiplication. For a
single-engine hull the resolved number is identical; for a multi-engine hull the
sum is what stops three vector drives from tripling a hull's speed.

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
| Fighter | 2× `w_laser`, `s_light`, `h_plate_light`, `e_std`, `p_std` (≈ 9 k) | fastest TTK in Tier-I fights, dies to focus fire |
| Cutter | 2× `w_cannon`, `w_laser`, `s_light`, `h_plate_light`, `c_target` (≈ 12 k) | steady, flexible, no weakness to exploit |
| Delver | `w_mining`, 3× U (refine/tractor/cargo), `s_light` (≈ 11 k) | mining income +40 % vs Cutter fit; loses any fight |
| Courier | 3× U (cargo×2, salvage), `e_ion`, `c_scanner` (≈ 12 k) | trade bonuses (10 §4); can outrun most threats |
| Spearhead | 4× `w_cannon`, `s_heavy`, `b_afterburner` (≈ 16 k) | wins the 1v1 it initiates, struggles in prolonged brawls |
| Mule | `h_plate_heavy`×2, `s_light`, `w_cannon`, 4× U cargo (≈ 16 k) | 200+ effective cargo; escapes anything it cannot kill |
| Bulwark | 5× mixed W, `s_heavy`×2, `h_plate_heavy` (≈ 20 k) | stationary fort; DPS wall at close range |
| Warden | 4× W, 2× C (twin/nexus), `s_ion` (≈ 24 k) | counter-build platform; beats mirror-price fits it has scanned |
| Obliterator | 7× W (mixed), `p_core`, `s_ion`, 2× `h_composite` (≈ 40 k) | the wall; slow, nearly unkillable, power-starved until `p_core` |

## 7. What a hull arrives with (amendment 2026-09-21)

**Every hull is delivered with its mandatory set: one `e_std` per ENGINE cell
(08 §3.1) and one `p_std`.** It is included in the hull's price, it is never
empty (a fit that is missing any of it cannot launch, §4.1), and an engine or
reactor cell may be *replaced* by a better module — the removed `e_std`/`p_std`
returns to the module inventory — but never left empty. This is what keeps a bare
auction hull launchable and what makes a 3-engine capital's price honest.

On top of the mandatory set:

- The **Vanguard** (18 000 CR) keeps its full **standard fit**: `e_std`, `p_std`,
  1× `w_laser`, `s_light`, `h_plate_light`. This matches the frozen stats
  (1 000 hull + 250 plate ≈ the historical 1 000 / 600 shield feel) and gives the
  fitting panel something to show on day one.
- The **Lancer** (9 000 CR) keeps its lighter one: `e_std`, `p_std`,
  2× `w_laser`, `s_light`.
- **All other hulls are bought bare** (10 §2) apart from the mandatory set — the
  full fit is a starter courtesy, not a class rule.

**Note 2026-09-22 (P2-B proper — the fitting surface is FITTING).** The surface that fits, swaps and
removes this mandatory set per cell is **FITTING** (`STATION_HUB.md` §5.3; CONTRACTS §13). An engine or
reactor cell may be replaced there by a better module (the removed `e_std`/`p_std` returns to the module
inventory) but is never left empty: `clear_fit_slot` refuses any key of `FitData.MANDATORY_SLOT_KEYS`
(`[&"engines", &"power"]`, §4.1), so the delivered launchable fit stays launchable through the panel.

Reversal: return to "bare hulls launch on the v1 standard fit" by having the
launch path fall back to the hull's standard fit when the profile holds none
(§9); no data is lost either way.

## 8. Layouts (new — how the matrix is consumed)

08 §3.2's matrix is the single source of a hull's slot arrangement. Three
consumers, one ordering:

1. **Counts** — `ShipFit.grid_counts(hull_id)` derives per-type counts from the
   matrix (never a parallel table).
2. **Addressing** — §4.5's index: cells of one type are numbered row-major from
   the matrix's top-left. `engines[0]` is the topmost/leftmost E cell.
3. **Display** — the station's layout grid is one cell per matrix cell,
   `columns` = the matrix width, `.` drawn as an empty cell. Each cell's face is
   the slot glyph of its type (`assets/icons/slot/icon_slot_<type>_48.png`), and
   a fitted cell shows the module's own icon instead
   (`assets/icons/module/icon_module_<id>_48.png`, all 27 module icons ship).

**Mount anchors.** A cell's own row/column is also its hull-local mount point:
`ShipFit.mount_offset(hull_id, slot_type, index) -> Vector2` returns the cell's
normalised position, `((col + 0.5) / cols - 0.5, (row + 0.5) / rows - 0.5)`,
scaled by one documented constant pair `MOUNT_SPREAD` (the hull's half-extents
fraction the grid covers). No per-hull anchor table exists, so art changes and
layout edits cannot desynchronise the geometry. **Consumption in flight is
staged** (weapons firing from their own mount, engine FX at their own nozzle) and
belongs to the feel wave — this document pins the data and the API only.

## 9. Per-hull standard fits (new)

`ShipFit.STANDARD_FITS` is one fit per hull, built from §7: the mandatory set for
every hull, plus the full fit for the two starter hulls. It is the fallback a
launch uses when the profile holds no fit for the active hull, and the fit the
auction delivers with those two hulls.

| Hull | `engines` | `power` | `weapons` | `shields` | `armour` | other |
|------|-----------|---------|-----------|-----------|----------|-------|
| Lancer | `[e_std]` | `p_std` | `[w_laser, w_laser]` | `[s_light]` | `[h_plate_light]` | — |
| Vanguard | `[e_std]` | `p_std` | `[w_laser]` | `[s_light]` | `[h_plate_light]` | — |
| Delver | `[e_std, e_std]` | `p_std` | — | — | — | — |
| Courier | `[e_std, e_std]` | `p_std` | — | — | — | — |
| Spearhead | `[e_std]` | `p_std` | — | — | — | — |
| Mule | `[e_std, e_std, e_std]` | `p_std` | — | — | — | — |
| Bulwark | `[e_std, e_std]` | `p_std` | — | — | — | — |
| Warden | `[e_std, e_std]` | `p_std` | — | — | — | — |
| Obliterator | `[e_std, e_std, e_std]` | `p_std` | — | — | — | — |

`STANDARD_FIT` (the Vanguard row) stays as the one alias existing callers and
tests already use; the Lancer's two-laser fit is the second full fit the auction
delivers (10 §2.3).

## 10. Weapon batteries (amendment 2026-09-22, S4)

**Owner rulings, verbatim (2026-09-22):** "in outfitting there should be option
to group weapon systems. Like 3 lasers together, 3 bolters together etc. Its
pointless to have each weapon on separate slot." — and, asked directly how a
group sits in the mounts: **N barrels keep N W mounts** (the battery is one row
and one trigger; this document's W counts stay the barrel cap).

- A **battery** = the identical weapon instances fitted across W cells, grouped
  by `base_id`. Fit storage is unchanged: one instance per cell (§4.5's layout
  addressing stands), `fit_legal` and the power budget see every barrel.
- OUTFITTING's FITTED WEAPONS strip shows **one row per battery** —
  `3× LASER MKII · W1·W2·W3` with `FIT ALL` / `REMOVE ALL` / `SWAP ALL` (bulk
  actions loop §4's composed transactions per cell) and a per-barrel expander
  that keeps the existing single-cell actions. FITTING's cell grid (§8) is
  unchanged and remains the per-cell surface.
- One trigger discharges the whole battery: one round per barrel, per-barrel
  damage, `BATTERY_STRUM_MS := 40` random release offset (0–40 ms per barrel) so
  a volley reads as a salvo. **Reversal:** strum 0 = perfectly simultaneous.
- **Reversal of the whole section:** re-expand the strip to one row per cell —
  view and bulk-action code only; no fit or profile shape changes behind it.

**Amendment 2026-09-23 (the S4 docs pass — what H0 measured the section owed).**
Five readings this section needed and did not carry; every one is a reading of the
tree, none is a new balance number, and CONTRACTS §16 is the pin that enforces them.

- **Ammo is per family, not per barrel** (`game/weapons.gd:1519-1526` resolves the
  family's index in `PlayerState.WEAPONS`; `game/player_state.gd:84-89` and
  `game/game.gd:1247-1249` say so in words). "One round per barrel" therefore means
  a 3-barrel laser volley spends **three** rounds from the one `laser` pack per
  release; nothing about the packs, their sizes or their prices moves.
- **`BATTERY_STRUM_MS`'s home is `WeaponComponent`** (`game/weapons.gd`), beside
  the family table that owns every other firing number, and the offset is drawn per
  barrel per volley. An instant (beam) family has no single release, so its strum
  delays the barrel's **opening frame** and the beam then draws continuously while
  the trigger is held; a pool that cannot pay a barrel's frame makes that barrel dry
  for the frame while the ones before it keep drawing. No partial-volley abort state.
- **Barrel positions are not cell indices.** The component is handed
  `ShipFit.fitted_ids`' flat id list (`game/player_ship.gd:1205-1206`), which drops
  family-less modules (`w_mining` → `&""`), so a battery's component positions and
  the hull's W-cell indices diverge on the first `w_mining` cell. The strip's
  `W1·W2·W3` labels are cell indices read from the pane's own cell list
  (`OutfittingPanel._weapon_cells`); the component's `battery()` answers positions in
  `fitted()` (CONTRACTS §16 rule 3).
- **The strip shows the empty cells too.** A battery by definition holds instances,
  so a grouped strip alone would hide every unfilled W cell; the strip therefore
  draws one battery row per battery **and** one read-only `W<n> — EMPTY` line per
  empty W cell (no REMOVE, no bulk actions). Reversal: drop the empty lines and the
  cell-surgery view in FITTING (§8) is the only place an empty cell is addressed.
- **The strip's node set is fixed** (`ui/station/outfitting_panel.gd:591-596`
  pre-builds `_max_weapon_cells()` rows): rows are rewritten by text/visibility, never
  rebuilt, because the profile emits `profile_changed` from inside the handler that
  started the write. At most one battery row per W cell plus the empty lines stays
  inside that count.

**Ticked 2026-09-23 (S4 close-out):** built and review-verified — gate `493 → 508 → 521 → 524/0`
(the review's HIGH, a held trigger firing one salvo instead of a stream, cured by the fixer pass
and independently reproduced as 15 shots in a 3.0 s hold). The strip, the two bulk transactions,
the per-barrel volley and `BATTERY_STRUM_MS := 40` are shipped; see
`.agents/gen/_state/WAVEBOARD.md` §Closed and `docs/CONTRACTS.md` §16/§9.

## 11. Playtest amendments 2026-09-23 (wave S5 — batteries v2, hardpoints, tracking)

Owner rulings verbatim: "outfitting screen should be for weapons battery grouping, i
want to be able to drag and drop there different kinds of weapons, the rof will be
limited by the slowest weapon, so we can do mix n match of different weapons"; "i want
each ship to have mapped where he has back thrusters, front (for reverse) and side.
same for weapon slots. i want it all mapped on a ship so that it will fire from
different angles/positions etc"; "i want weapons to not turn as fast. weapons can have
different turn speeds and in one weapon battery they can have different turn speeds as
well".

- **Batteries v2 (supersedes §10's identical-only rule).** A battery is a
  **player-composed mixed group** of W cells — any weapon kinds together — persisted as
  `batteries: {ship_id: Array[Array[cell_ref]]}` (save v7; migration v6→v7 groups each
  hull's fitted weapons by `base_id`, cells ascending). Composed on `ARMORY`'s racks by
  drag and drop (STATION_HUB §5.11). **The salvo gate is the slowest member's cycle** —
  one trigger releases every armed barrel (strum `0..40` ms as §10) and the battery's
  next salvo waits for `max(members' cadence)`; dry/empty rules stay per barrel and
  never block the rest (§16 rule 4's carve-outs stand). `GROUPS_MAX` 5 → **7**, with
  `weapon_6`/`weapon_7` bound (digits 6/7, orchestrator-applied). **Reversal:** §10's
  identical-only grouping and the S4 per-barrel independent cadence.
- **Hardpoints per hull (supersedes §8's `MOUNT_SPREAD` no-table rule).** Each hull
  carries a map: `ShipFit.HARDPOINTS[ship_id] = {thrusters: {rear, front, left, right
  (each an array of local `Vector2`)}, weapon_mounts: [{pos, facing}…]}` with W cell `i`
  bound to `weapon_mounts[i]`. **Values are measured off the hull renders and recorded
  in the table below by the wave** (that measurement is its deliverable; a hull without
  a map falls back to §8's derivation). Flight FX read the map: thrust at rear anchors,
  brake/retro at front, strafe at the side's anchors. **Reversal:** delete
  `HARDPOINTS` (the fallback is today's behaviour).

| Hull | rear | front | left | right | weapon_mounts | measured |
|------|------|-------|------|-------|---------------|----------|
| (nine rows filled by S5-J4 from the renders; values in hull-local px) | | | | | | |

- **Weapon tracking.** A barrel tracks the aim at its own speed — a new §3.1 column
  **`track_dps`** (deg/s, owner-tick taste): `w_laser 180`, `w_mining 150`,
  `w_cannon 120`, `w_railgun 100`, `w_plasma 75`, `w_rocket 60`, `w_mine fixed` (no
  tracking). A released travelling shot flies along the barrel's **current facing** from
  its mount (tracking lag can miss — owner tick: hold-fire-until-aligned instead); a
  beam barrel sweeps onto the target and connects only within `TRACK_TOLERANCE := 5`°.
  **Reversal:** `TRACK_MULT := 0` = instant aim (today's behaviour).
