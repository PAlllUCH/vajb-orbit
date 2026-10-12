# 07 — Crafting (Design Preview — NOT for Coding)

**Status:** Design only. Nothing in this document may be implemented until a
later phase is approved; its numbers exist so that 02, 03 and 06 can be
designed around a known destination. **The README marks this document
"not for coding" — a coder who implements anything from it has skipped an
approval gate.**

---

## 1. Why crafting exists

The station catalog (StationCatalog) sells a fixed ladder: five upgrade
items, four ships. Crafting is the answer to "what is tier two of the
upgrade system?" It converts banked components (03) and ingots (02) into
gear **at or above the best station stock**, making mining and fighting pay
long after the station's shelves are bought out.

## 2. Core shape (agreed direction)

- **Where:** a new station module, FOUNDRY, next to the EXCHANGE.
- **Inputs:** components by id and grade, ingots by mineral, and a credit
  labour fee. No timers, no failure rolls (same philosophy as 04 §3).
- **Outputs:** crafted versions of existing upgrade *slots* with better
  effect values, plus a small set of unique crafted-only modules.
- **Recipes are data:** one static table, same contract style as 02/03.
  Recipe ids, input lists, credit fees — all data, never code.

## 3. Recipe economy sketch

Illustrative, not final. Prices in credits (labour fee) + inputs:

| Recipe | Inputs | Fee | Output effect (vs StationCatalog best) |
|--------|--------|-----|------------------------------------------|
| Reactor Mk3 | 2× `comp_mech_2`, 1× `comp_pow_2`, 6× `ingot_cobalt` | 2 500 | +45 % regen (vs Mk2's +30/+20 %) |
| Shield Lattice | 1× `comp_ore_2`, 3× `ingot_cerulite`, 2× `comp_elec_2` | 3 000 | +35 % shield max (vs Amplifier's +20 %) |
| Rail Refit | 2× `comp_weap_2`, 4× `ingot_tungsten` | 2 800 | kinetic damage +25 % (unique, no station equivalent) |
| Deep Scanner Array | 1× `comp_elec_3`, 5× `ingot_voidglass` | 4 000 | scanner range +45 % (vs +25 %) |

Supply math: a crafted item should cost roughly 3–6 sessions of targeted
looting/mining *beyond* the credits it fees, i.e. it is the long-game sink
for components that would otherwise saturate the Surplus Book quotas (05 §4).
Component grade III (Maw-sourced, 06 §3.4) appears only in end-tier recipes.

## 4. Open questions for the later design pass

1. **Quality tiers:** are crafted Mk3 items direct upgrades, or do they
   trade a stat down somewhere? (Direct upgrades are simpler; tradeoffs are
   more interesting. Undecided.)
2. **Reverse crafting / dismantling:** can the player scrap crafted gear
   back into components? (Probably yes at 50 %; decides whether crafting is
   reversible.)
3. **Materials counter:** does the exchange start selling Tier-1 ore
   (05 §7) when recipes prove too grind-hungry?
4. **Unique modules:** how many crafted-only items, and do any gate content?
5. **UI:** a FOUNDRY panel spec amends STATION_HUB.md, as the refinery and
   exchange panels will have done by then.

## 5. What must hold true when this is specced for real

- Every recipe input is obtainable in v1 volumes (02 yields, 06 tables).
- Crafted outputs stay below the Obliterator's stat band unless a new ship
  tier is designed first.
- The credit fee per recipe is ≥ 2 000 CR so crafting is a sink (01 §4 K7),
  never a conversion loophole.

## 6. 2026-10-12 — D24: specced for real (owner request; wave D24 — the CRAFT tab)

**Status change:** design specced for real; implementation still gates on the
owner's tick sheet (STATION_HUB §23.10) and the S42+ waves — the header's "NOT
for Coding" and the README's mark stand until the ticks land. §1–§5 stand; §3's
"Illustrative, not final" header is superseded by the table below (every
number derived or PROPOSED with its reversal). The owner's ask verbatim
(STATION_HUB §22): "also in refinery another tab for crafting items and
components not only refining ores."

### 6.1 The pins (C1–C10; PROPOSED with reversal, unticked rows implement at the PROPOSED value)

| # | Value | Reversal |
|---|---|---|
| **C1** | **Where:** the REFINERY pane's **CRAFT tab** (STATION_HUB §23.6 P52 — the `REFINE`/`CRAFT` mode pair). §2's "a new station module, FOUNDRY, next to the EXCHANGE" **dies** — superseded by the owner's own tab ask (STATION_HUB §22; escalation bucket 3 discharged at the request). Inputs stay §2's: components by id and grade, ingots by mineral, a credit labour fee; **no timers, no failure rolls** (§2/§3 stand) | the FOUNDRY module; timers; failure rolls |
| **C2** | **Recipes are data:** one static table `game/crafting_catalog.gd`, same style contract as 02 §3 / 03 §4 (a `const` array of dictionaries: `id`, `name`, `inputs` (id→count), `fee`, `output` (module id + effect), `description`). No price, fee or effect is ever computed in panel code | logic in the panel |
| **C3** | **The recipe table** (fees and outputs derived — C4/C6; inputs verbatim from §3): see §6.2 | §3's sketch as-is (unlabeled) |
| **C4** | **The fee law:** `fee = ceil(0.35 × output list value)` — the labour rate 10 §3.1 already pins for builds (35 % of list), rounded up to the nearest 100; every fee ≥ **2 000 CR** (§5's K7 sink law, 01 §4). The four fees land at 2 500 / 3 000 / 2 800 / 4 000 | §3's unlabeled fees; any fee < 2 000 |
| **C5** | **Materials derive from the baselines** (03 §3's values, 02's 2026-10-08 S28 table) — see §6.3's derivation column; the panel displays inputs as counts, never as CR | pricing materials at the exchange's live quote |
| **C6** | **Outputs** are modules in 09's families (effects in 09 §3's own language; the output rows land in 09 §3.x at the implementation wave, 07 owns the recipe law): REACTOR MK3 `+4 power output` (power, draw —) · SHIELD LATTICE `+500 pool · regen 10/s` (shield, draw 3) · RAIL REFIT `kinetic weapons +25 % damage` (computer, draw 1 — unique) · DEEP SCANNER ARRAY `+45 % scanner range` (computer, draw 1). §5's Obliterator-band must: power caps at the stock best (`p_core` +4, 09 §3.8 — flagged: the crafted reactor's value is paying in goods, not a stat above stock); shield +500 < the Obliterator fit's 750 combined pool; each item ≤ 7.7 k against the ≈ 40 k reference fit | effects above the band; legacy upgrade language (§3's "+45 % regen" wording) |
| **C7** | §4 Q1: **direct upgrades** (no stat tradeoffs) — the simpler answer, and the only one derivable from 09's ladder without new mechanics | tradeoff variants |
| **C8** | §4 Q2: **reverse crafting at 50 % of recipe materials (round down)** — 10 §3.3's scrap law verbatim, so crafting is reversible exactly as hull-building is | no scrap path; 100 % |
| **C9** | §4 Q4: **four crafted-only items in v1, none gate content** (§3's four; the Deep Scanner's +45 % is a convenience above c_nexus, not a gate — 11 §3's wreck fields need any C-slot scanner) | more items; a gating item |
| **C10** | **The doors:** the `CRAFT` commit routes through UI_SPEC §17's confirm door (A4's list, A6's wording — `…CRAFT <NAME> FOR <BILL> + <FEE> CR LABOUR?`); the per-row availability chip (`READY` / `MISSING <n>× <input>`) reads `cargo_qty` — read-only seam; refusal path STATION_HUB §5.6. §4 Q3 stands: no Tier-1 ore vendor in v1 (re-present at the playtest if recipes read grind-hungry) | commit on press; a vendor |

### 6.2 The recipe table (C3; every row PROPOSED with its reversal — the reversal for the set: §3's sketch unlabeled)

| Recipe | Inputs (03 §3 / 02 S28 ids) | Fee (C4) | Output (C6) | List value | Total cost / % of list |
|---|---|---:|---|---:|---|
| REACTOR MK3 | 2× `comp_mech_2`, 1× `comp_pow_2`, 6× `ingot_cobalt` | 2 500 | `+4 power output` (power III) | 7 000 (= `p_core`, 09 §3.8) | 3 578 = 51.1 % |
| SHIELD LATTICE | 1× `comp_ore_2`, 3× `ingot_cerulite`, 2× `comp_elec_2` | 3 000 | `+500 pool · regen 10/s` (shield IV) | 8 500 (PROPOSED — 1.42 × SC(4) at the row's own labelled tier IV (01's SC(t) ladder), inside S28 L2's 1–2 × band — no deviation) | 4 876 = 57.4 % |
| RAIL REFIT | 2× `comp_weap_2`, 4× `ingot_tungsten` | 2 800 | `kinetic weapons +25 % damage` (computer, unique) | 8 000 (PROPOSED unique band — no SC(t) multiple derivable: the output carries no tier label) | 3 630 = 45.4 % ⚠ under the 47.7 % floor — lever: +2 ingot (→ 49.9 %) |
| DEEP SCANNER ARRAY | 1× `comp_elec_3`, 5× `ingot_voidglass` | 4 000 | `+45 % scanner range` (computer) | 11 400 (PROPOSED exotic — the N5 Hyperdrive precedent 01's block; no SC(t) multiple derivable: the output carries no tier label) | 7 740 = 67.9 % ⚠ over the 59.1 % ceiling — flagged |

The %-of-list column is 10 §3.1's own build-band check, read against the standing
live band **47.7–59.1 %** (T-178) only — the sketch band 55–70 % is §3's own
arithmetic, not the check: **two rows inside** (REACTOR 51.1 %, SHIELD 57.4 %) and
two outside — RAIL REFIT 45.4 % below the floor (flagged in-row with its lever) and
**DEEP SCANNER 67.9 % outside above, flagged on that axis**.
Supply-math re-check (flagged, not re-derived): §3's "3–6 sessions" sketch
predates S28's value halving — re-measure at the playtest.

### 6.3 The materials derivation (C5; S28 baselines: 03 §3's CR, 02's 2026-10-08 table)

| Recipe | Arithmetic (units × baseline) | Materials value |
|---|---|---:|
| REACTOR MK3 | 2×45 (`comp_mech_2`) + 1×40 (`comp_pow_2`) + 6×158 (`ingot_cobalt`) | 1 078 CR |
| SHIELD LATTICE | 1×60 (`comp_ore_2`) + 3×572 (`ingot_cerulite`) + 2×50 (`comp_elec_2`) | 1 876 CR |
| RAIL REFIT | 2×55 (`comp_weap_2`) + 4×180 (`ingot_tungsten`) | 830 CR |
| DEEP SCANNER ARRAY | 1×120 (`comp_elec_3`) + 5×724 (`ingot_voidglass`) | 3 740 CR |

Inputs are obtainable in v1 volumes (§5's must): grade-II components drop
from corvettes (06 §3), `comp_elec_3` is Maw-sourced end-tier (06 §3.4, §3's
own note), ingots come from 04 §7's jobs. Reversal per row: the input counts
(§3's sketch, unlabeled).
