# S27 — Catalog breadth & the shipyard (wave brief)

**Wave:** S27 (code lane, item 33 of `dispatch_coder.md`)
**Slice folder:** `.agents/gen/slices/S27-catalog-breadth/`
**Baseline:** the gate after S26's close (record it in the report);
`python3 staging/verify_wave.py snapshot --name s27_start` before the first dispatch.
**Owner go (2026-09-27):** pillar C ("catalog breadth") ticked within the
no-art constraint: "more modules, weapon variants, NPC archetypes, loot lines
… needs art for hulls/NPCs" — the data-only half is this wave. **No new AI art.**
**Re-cut 2026-10-08** against the shipped tree (post-S28): the pricing law
re-pointed to 01's L2 bands (S28's "nothing restates a price"), the T-153
tier-4 rider folded in, every cite re-measured.

## 1. The law to read, in order
1. `slices/S27-catalog-breadth/SLICE.md` — scope, file sets.
2. The **2026-09-27 P3 blocks** (15: R-S27-2/3; 09: R-S27-1) + the pinned
   format law `15_module_affixes.md` §1/§3/§4 and `10_ship_acquisition.md` §3.
3. `docs/gameplay/01_economy_core.md` **2026-10-08 S28 block** — L2's price
   bands (module ≈ 1–2 × SC(t); hull ≈ 8–18 × SC(band); consumable ≈
   0.1–0.4 × SC(1); one-off service ≈ 2–3 × SC(1)) and the one-pricing-family
   law; `docs/gameplay/02_minerals.md` 2026-10-08 block (the value table the
   recipes derive from).
4. `docs/gameplay/06_loot_drops.md` §3 (line format) + `03_components.md` §3.
5. `docs/design/UI_SPEC.md` §12–§15 and `docs/design/STATION_HUB.md` §19–§21
   (by range) — shell v2; the SHIPYARD panel's new views join the shell.
6. `docs/CODE_MAP.md` — what lies where (by range).
7. The §5 spec extract.

## 2. The owner's request (verbatim)
> "right now the fundamentals are there, it needs a bit of playtesting and a lot
> of new content as right now there isnt much … i want to focus on content,
> bugfixes, playability and feel" (2026-09-27). Affixes measured at "22 words";
> the shipyard measured at "designed; build queue not built".

## 3. What is already measured (file:line, re-measured 2026-10-08)
| Fact | Site |
|---|---|
| 12 prefixes + 10 suffixes exist with their bands | `game/module_catalog.gd:135 (PREFIXES)`, `:227 (SUFFIXES)` |
| perks are "displayed, never applied" except Embers/Leeches/Cartograph | `game/module_catalog.gd:701` (the `of the Ledger` note); the launch flags at `game/game.gd:708` |
| the aggregation law is pinned | `docs/CONTRACTS.md` §20 |
| one variant precedent exists (`p_mk2`) | `game/module_catalog.gd` power rows |
| 10 §3.2's build-shape rule is pinned ("the shape rule is the contract so the coder cannot invent prices") | `docs/gameplay/10_ship_acquisition.md` §3.2 |
| `shipyard.gd` does not exist; `shipyard_panel.gd` is the hangar only | `vajb-orbit/game/` has no such file; `ui/station/shipyard_panel.gd` |
| the new enemy archetypes have no loot tables | `game/loot_tables.gd:103 (TABLES)` (fighter/swarmer/freighter/corvette/maw only) |
| the reserved slot clamps at tier 3 (T-153) | `game/auction.gd:421`; `tier_pool(4)` is empty |
| S28's one-pricing-family law | `01`'s 2026-10-08 block (L2); `game/mineral_catalog.gd` value table |

## 4. Pinned interface (verbatim) + rules
```gdscript
# game/module_catalog.gd — the tables this wave extends (re-measured 2026-10-08)
const PREFIXES: Dictionary = {    # :135
const SUFFIXES: Dictionary = {    # :227
const MODULES: Dictionary = {     # :260
# game/loot_tables.gd:103 — the kind table that gains archetypes
const TABLES: Dictionary = {
# game/affixes.gd — the §20 aggregation seam the perks wire into
# game/auction.gd:421 — the tier clamp T-153 relaxes
```

Rules:
1. **Formats are law** (15 §3 prefixes = stat modifiers in tier bands; §4
   suffixes = binary boons; family bands — "a shield never rolls +cargo"); the
   new rows are exactly R-S27-2's seven, values inside their family's existing
   band shape (state each band in the report).
2. **Perks fire at the §20 seam** and are once-per-perk flags; a perk with no
   consumer is a defect (that is A2's point).
3. **Variants price by 10 §3.2's shape rule** (R-S27-1: +15 % headline stat per
   step) — and every CR figure derives from the live catalogue arithmetic:
   **01's L2 bands are the price law** (module ≈ 1–2 × SC(t); hull ≈
   8–18 × SC(band); consumable ≈ 0.1–0.4 × SC(1); one-off service ≈
   2–3 × SC(1)). **Nothing restates a price** (S28's A2): a new row's price
   comes from the ladder, never a hand-picked flat.
4. **Shipyard rows derive** (10 §3 verbatim): materials ≈ 20–30 % of list,
   labour = 35 % of list; the module shape rule (2× tier component family +
   12× matching-tier ore + 20 % labour) generates module recipes mechanically
   so a table cannot drift — **the mix is the contract; the CR totals re-derive
   from the live ore/component values** (02's 2026-10-08 table), never from
   the pre-S28 figures.
5. **The queue is play-gated, not time-gated** (§3.3: "real-world time is never
   the gate, play is") and everything commits/refunds exactly per §3.3.
6. **The tier-4 rider (T-153)**: add a tier-4 catalogue row so `tier_pool(4)`
   is non-empty, and relax `auction.gd:421`'s clamp accordingly — the reserved
   slot at a tier-4 sector reserves tier 4. Reversal: drop the clamp and skip
   the slot at tier 4.

## 5. Spec extract (verbatim, cited)
`15_module_affixes.md` §3:
> "Roll values within a band by tier: T1 modules roll low, T3 roll high (values shown as T1/T2/T3). Exactly 1 (Magic) or 2 (Rare) prefixes; the two prefixes of a Rare must be **different properties**."

`15_module_affixes.md` §4:
> "One line each, always the same perk for the same name. 1 (Magic) or 2 (Rare); a Rare's two suffixes must differ. Suffixes are **binary boons**, never numbers — they are the memorable part of a drop."

`15_module_affixes.md` §1:
> "| **Common** | 0 prefix / 0 suffix | Light Shield — plain catalogue stats | … | **Rare** | 2 prefixes / 2 suffixes | Vigilant Keen Light Shield of the Choir of Vigilance |"
> "**Prefixes = stat modifiers** (§3); **suffixes = identity/named perks** (§4). Both roll from the module's own family so a shield never rolls "+cargo"."

`10_ship_acquisition.md` §3/§3.1/§3.2/§3.3:
> "Building costs **materials + a credit labour fee**. Labour ≈ 35 % of list price … so building saves ~65 % of the credits vs buying."
> "**Rule: materials ≈ 20–30 % of list value, labour = 35 % of list, so a build totals ≈ 55–70 % of the auction list (§4).**"
> "Every module is buildable: **2× its tier's component family + 12× a matching-tier ore + 20 % of list as labour.** Family mapping follows 03 §3's "Used for" column … the shape rule is the contract so the coder cannot invent prices."
> "One build at a time; a build takes **one in-space session** ("ready when you return from your next flight") — real-world time is never the gate, play is."
> "Materials and labour are **committed at queue time** … and **refunded in full on cancel** before completion. After completion the hull/module is delivered to the station — no refunds."
> "**Scrap path:** an owned hull can be broken down at the shipyard for 50 % of its recipe materials (round down)."

**2026-09-27 P3 blocks:** R-S27-1 (variants, +15 %/step, tick K1), R-S27-2 (+4
prefixes, +3 suffixes, tick K2), R-S27-3 (perks go live, tick K3).

`01_economy_core.md`, 2026-10-08 S28 block (the price law this wave prices by):
> "**L2 — prices (checked, not changed).** S28 ships zero price edits: the frozen
> hull ladder and the module medians already read as sessions of their tier —
> module ≈ **1–2 × SC(t)** (medians 1.09 / 2.00 / 1.93), hull ≈
> **8–18 × SC(band)** rising along the ladder (Lancer 8.2 → Obliterator 12.0),
> consumable ≈ **0.1–0.4 × SC(1)**, one-off service ≈ **2–3 × SC(1)** (the
> refinery slot's 3 000 = 2.7). **S25–S27's new rows price from these bands.**"

## 6. Acceptance list (numbered; the report answers each with a cite)
- **A1 (affix rows):** the seven R-S27-2 rows roll under the §1 rarity contract
  (family bands respected — a shield never rolls a damage prefix), values in
  their family's tier bands; seeded roll probe over 5k instances.
- **A2 (perks live):** every §4 suffix perk (old + new) names and exercises its
  consumer at the §20 seam — `of Echoes` refunds every 5th shot's ammo,
  `of the Long Watch` holds locks +2 s, `of the Pyre` detonates its 50-damage
  ring on a below-25 %-hull kill; the "displayed, never applied" note is gone.
- **A3 (variants):** `<base>_mk2` rows price by 10 §3.2's shape rule at +1 tier
  and carry +15 % on the family headline stat; their CR prices sit in 01's L2
  band for their tier (1–2 × SC(t)); they appear in sale/roll pools one tier up
  (R-S27-1).
- **A4 (loot):** `interceptor`, `turret`, `sibelon` and boss archetypes roll
  their own 06 §3-format tables (seeded EV measured over 20k rolls and
  reported); `TABLES` carries the new kinds.
- **A5 (shipyard):** 10 §3 verbatim — hull recipes per §3.1's derived rows
  (report the full recipe table), module builds generated by §3.2's rule with
  CR totals re-derived from the live ore/component values, the §3.3 queue (one
  at a time; completes after one in-space session; commit at queue; full refund
  on cancel; persists across restart) and §3.3's scrap path (50 % round down).
  The SHIPYARD panel gains build/queue/scrap views beside the hangar in the
  shell-v2 idiom (UI_SPEC §12–§15).
- **A6 (tier-4 rider, T-153):** a tier-4 catalogue row lands (priced in 01's L2
  band, 1–2 × SC(4) = 6 000–12 000 CR) and `auction.gd:421`'s clamp reads it —
  a tier-4 sector's reserved slot reserves tier 4.
- **A7 (summary):** every new value tabled with reversal + tick id (K1–K3
  named); no gate row outside §8's list moved.

## 7. Worker table
| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| S27-B1 | coder (builder) | `vajb-orbit/game/module_catalog.gd, vajb-orbit/game/loot_tables.gd, vajb-orbit/game/affixes.gd, vajb-orbit/game/shipyard.gd, vajb-orbit/game/shipyard.gd.uid, vajb-orbit/game/auction.gd, vajb-orbit/autoload/player_profile.gd, vajb-orbit/ui/station/shipyard_panel.gd, vajb-orbit/ui/station/shipyard_panel.tscn, vajb-orbit/tests/test_s27_catalog.gd, .agents/gen/slices/S27-catalog-breadth/S27-B1_report.md` | A1–A7 + `S27-B1_report.md` |
| S27-R1 | reviewer | `vajb-orbit/tests/, docs/CONTRACTS.md, .agents/gen/slices/S27-catalog-breadth/S27-R1_review.md` | `S27-R1_review.md` + CONTRACTS §20 + §9/§10 + LOW rows |
| S27-F1 | fixer (only on HIGH/MED) | B1's set + `vajb-orbit/tests/, docs/CONTRACTS.md, .agents/gen/slices/S27-catalog-breadth/` | `S27-F1_report.md` |

Read-only throughout: `game/exchange.gd`, `game/mineral_catalog.gd`,
`game/sector_registry.gd`, `game/station_registry.gd`, `docs/`.

## 8. Run order + the tests that move
**B1 → R1 → F1 only on HIGH/MED.** Expected gate growth: **+
`test_s27_catalog.gd` rows (one per AC)** only. Candidates:

| Suite | Why | Verdict |
|---|---|---|
| `test_s7_affixes.gd`, `test_s7_suffixes.gd`, `test_s7r1_*` | A1/A2's rows + live perks | unchanged counts (new rows are additive; existing perk rows now *pass harder*) |
| `test_p1_catalogues.gd`, `test_p1_pricing.gd` | A3's variants | unchanged (variant rows are additive) |
| `test_engine2_loot.gd`, `test_s6_poi_loot.gd` | A4's tables | unchanged |
| `test_p2b_services.gd`, `test_d7_armory.gd` | A5's shipyard views | unchanged (additive panel) |
| `test_s28_econ.gd`, `test_s25_contracts.gd`, `test_s26_endgame.gd` | S28's law; the seam and endgame rows this wave builds beside | unchanged |

Any other count moving is a bucket-2 pause: report it, leave it, stop.

## 9. Hard rules
- Docs read-only. `--forbidden` at verify: `docs/`,
  `vajb-orbit/project.godot`, `vajb-orbit/addons/`.
- No art (owner 2026-09-27); variant rows reuse their base module's icon.
  Bounded runs, scratch `XDG_DATA_HOME` (L229), no shell edits; Layer Cake.
  Prices derive from 01's L2 bands and the live catalogue — never a hand-picked
  flat, never a pre-S28 figure.

## 10. Staged / deferred
- Signature unique drops (06 §7 → a 07 amendment), crafting (07: "NOT for
  coding"), new faction exclusives (wait for the vendor story).

## 11. Owner tick list (unticked ⇒ the PROPOSED value ships)
| Tick | Row | PROPOSED |
|---|---|---|
| K1 | R-S27-1 | variants at +15 %/step, 10 §3.2 pricing |
| K2 | R-S27-2 | the seven affix rows as written |
| K3 | R-S27-3 | all suffix perks go live |

(T-153 closes with A6; its reversal is the clamp-drop alternative.)

## 12. Close-out (the orchestrator)
1. Gate twice on fresh scratch stores (identical counts).
2. `python3 staging/verify_wave.py verify --baseline s27_start --forbidden
   vajb-orbit/project.godot docs/ vajb-orbit/addons/
   --tests --expect-reports .agents/gen/slices/S27-catalog-breadth/S27-B1_report.md
   .agents/gen/slices/S27-catalog-breadth/S27-R1_review.md`
3. `python3 staging/build_code_map.py` — the map must describe the shipped tree
   (deterministic; a no-change re-run diffs nothing).
4. WAVEBOARD + `dispatch_coder.md` one-liners; `MASTER_REPORT.md` §6 recap;
   wave-boundary commit. Then the phase exit criteria (playtest build 2).
