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
