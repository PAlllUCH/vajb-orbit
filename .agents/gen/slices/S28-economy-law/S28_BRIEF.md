---
slice: S28
wave: S28
workers: [S28-C1, S28-C2, S28-R1, S28-F1]
status: ready
models: builders `hyper/deepseek-v4.1-flash` @ xhigh · review `hyper/glm-5.3-flash` @ max (the standing roster)
---

# S28 — The universal cost law (wave brief)

## 1. The law to read, in order
1. `slices/S28-economy-law/SLICE.md` — the scope, the out-of-scope list and
   your file-set row (the ID note explains the C letters)
2. The six 2026-10-08 **S28 blocks**, in this order — they are the law:
   `docs/gameplay/01_economy_core.md` (the law + SC table) →
   `02_minerals.md` (the value table) → `04_refinery.md` §8 (the fee) →
   `05_exchange.md` §10 (the restated pricing examples) →
   `11_galactic_map.md` (the bloom cap) → `14_station_services.md` (the payouts)
3. The superseded law they amend — context only, never authority: `01` §5,
   `02` §2/§4, `04` §2–§3, `05` §3, `11` §3.2, `14` §2/§7
4. `docs/CONTRACTS.md` — **by range only** (`rg -n '^## §'`, then
   `view --offset … --limit …`); R1 writes its new section
5. `docs/CODE_MAP.md` — by range

## 2. The owner's request (verbatim)
"You are going to do full evaluation of the game. Start with asteroids and
their real value output after refinement. Then check prices of all items. We
need to generate a universal costs law so that game doesnt feel too easy.
Analise current elements. Coder is doing S24 so dont change files but feel
free to explore, suggest, brainstorm, when you finish we will add slices" —
then: "Okay lets make it S28, prepare briefs etc".

## 3. What is already measured (file:line)
Everything below is read off the shipped tables; the evaluation that derived
the break is the arithmetic on these rows.

- **Values:** `game/mineral_catalog.gd:30-258` — 20 rows; tier ore means
  22.6 / 57.2 / 150 / 426, ingot means 81.4 / 205.8 / 540 / 1 534; the
  ingot/ore ratio is ≈3.6 throughout (04 §2's "+20 % before the fee").
- **Mining:** `game/ore_tuning.gd:36` (`mine_cycle` 1.2 s), `:42`
  (`tier_base_yield` 6/5/4/3), `game/mining_laser.gd:237` (one cycle delivers
  `work_per_unit × _bank`), `game/player_ship.gd:1761` (N fitted `w_mining` =
  N work channels).
- **Fee:** `game/refinery.gd:27-31` (5 CR/ore-unit = 15 CR/conversion, flat),
  `:53` (`u_refine` ×0.5), `:44-46` (R1 durations read the ingot value).
- **Bloom:** `game/poi.gd:91-93` (`ORE_BLOOM_ROCKS` 10, `ORE_BLOOM_YIELD_MULT`
  2, T+1 tier bonus).
- **Prices:** `game/station_catalog.gd:105-205` (9 000–72 000, the four ❄
  hulls frozen by STATION_SPEC §5), `game/module_catalog.gd:266-630`
  (600–12 000), `:82/:89/:91` (rarity ×1.0/1.6/2.6, sell-back 60 %, hot −20 %).
- **Sinks:** `game/repairs.gd:44-45` (1 CR/2 hull + 1 CR/3 shield),
  `game/sector_registry.gd:55-56` (gate 150 + 100/sector),
  `game/exchange.gd:51-52` (2 % commission, 10 CR floor),
  `game/station_catalog.gd:31-99` (ammo packs 120–400, tier-stepped).
- **The measured break:** a T4 hold pays ≈19 400 CR gross (13 × 1 488 net) —
  the Obliterator costs 2–5 S7 sessions against the design's 70–100; the
  refine fee is 0.7 % of a Krillum ingot; one ore-bloom event ≈30 000 CR; a
  7-laser battery mines at 5.8 u/s.

## 4. Pinned interface (verbatim) + rules

```gdscript
# game/mineral_catalog.gd — the 20 MINERALS rows carry exactly 02's
# 2026-10-08 table (§5 of this brief); T1's ten value cells are byte-identical
# to the shipped rows; only &"ore_value"/&"ingot_value" move.

# game/refinery.gd — the fee law replaces the flat FEE_PER_UNIT arithmetic
const FEE_FLOOR := 15              ## CR per conversion — the historical flat (T1 keeps it)
const FEE_VALUE_PERMILLE := 80     ## 8 % of the ingot the conversion produces
static func conversion_fee(mineral_id: StringName) -> int
    ## max(FEE_FLOOR, ingot_value × 80 / 1000), integer truncation
static func fee_for(mineral_id: StringName, conversions: int, mult: float = 1.0) -> int
    ## int(conversions × conversion_fee(mineral_id) × mult) — the whole-credit
    ## truncation and the u_refine multiplier behave exactly as shipped
```

```gdscript
# game/ore_tuning.gd — the battery law (S13's "N channels" pin becomes gain-based)
const BATTERY_GAIN := 0.4          ## mining_laser.gd's declared constant (the S13 pattern)
static var battery_gain: float = 0.4   ## live value; 1.0 is the reversal (linear N)
## reset_to_defaults / to_dict / from_dict carry the field like every other
## ore constant (the S13 anti-drift pattern; test_s13_caps asserts it)

# game/mining_laser.gd — extract_cycle's work line becomes
#     work := work_per_unit * (1.0 + battery_gain * float(_bank - 1))
# `battery()` keeps reporting the fitted count; only the work arithmetic moves.

# game/poi.gd — the bloom cap
const ORE_BLOOM_ROCKS := 6         ## was 10
const ORE_BLOOM_YIELD_MULT := 1.5  ## was 2 (int → float; the roll rounds as roll_yield does)
```

Rules that fix every ambiguity:
- **T1 is untouchable.** Iron/copper/chromium/silicon/aluminium keep their ten
  value cells byte-for-byte; every worked example that cites them stands.
- **Only 05 prices.** The exchange reads the new baselines through its one
  pricing family (`05` §8); the demand model, the commission and the surplus
  book are untouched.
- **The fee's floor is per conversion**, applied before the multiplier, and
  `u_refine`'s half is truncated after (iron: 15 → 7, "not 7.5").
- **Durations derive, never restated:** `resource_seconds` keeps R1's formula;
  the new ingot values shorten T3/T4 jobs (gold 26 s, krilium 60 s ceiling).
- **`battery()` semantics unchanged** — the fitted count, not the effective
  channels; a fit without `w_mining` still mounts no laser.
- **The bloom keeps its trigger and tier bonus** (`ORE_BLOOM_TIER_BONUS` 1);
  only the rock count and the yield multiplier move.
- Docs are read-only for every worker; `docs/CONTRACTS.md` is R1's alone.

## 5. Spec extract (verbatim, cited)
The binding numbers, quoted from the 2026-10-08 blocks (source cites above
each block; the prose lives in the docs — these extracts are what the
acceptance list grades).

**02's 2026-10-08 block — the value table (A1/A2):** tier-mean ore =
`22.6 × 2.0^(t−1)`; within-tier multipliers `{0.80, 0.88, 0.97, 1.11, 1.24}`
(T1's own shape, ascending rank); `ingot = round(ore × 3.6)` for T2–T4;
tier means 22.6 / 45.2 / 90.4 / 180.8 ore and 81.4 / 163 / 326 / 652 ingot;
the board monotone (silver 56/202 < gold 72/259; osmium 112/403 < palladium
145/522); krilium's apex 224/806. Full rows: titanium 36/130 · nickel 40/144 ·
cobalt 44/158 · tungsten 50/180 · silver 56/202 · gold 72/259 · platinum
80/288 · neodymium 88/317 · iridium 100/360 · osmium 112/403 · palladium
145/522 · cerulite 159/572 · emberite 175/630 · voidglass 201/724 · krilium
224/806 (T1 unchanged).

**04 §8 — the fee (A3/A4):** `max(15, ingot × 80 / 1000)` per conversion —
T1 15 across, T2 15/15/15/15/16, T3 20/23/25/28/32, T4 41/45/50/57/64; the
refine-vs-raw ramp −7 % (iron) → +1 % (silicon) → +6…+11 % (T2) → +11 % capped
(T3–T4); `fee_for(mineral_id, conversions, mult)`; four panel call sites.

**05 §10 — the restated pricing examples (A2's exchange rows):** Iron 65 →
64/38/102 (byte-unchanged) · Titanium 130 → 127/76/204 · Gold 259 → 254/152/406
· Krillum 806 → 790/474/1 264 (at demand 1.0/0.6/1.6); raw iron 18 × 0.98 = 18.

**11's 2026-10-08 block — the bloom (A6):** 6 rocks × 1.5 yield, T+1, the same
200 u trigger; one event ≈ 0.85 × SC(4).

**14's 2026-10-08 block — the payouts (docs-only, staged):** Boneyard 6 000 +
magic roll, Pyre 12 000 + guaranteed rare (≈2 × SC of the arena's tier);
contract flats scale ×SC(t)/SC(1) by 11 §1's sector tier — Hunt
800/1 100/2 200/4 400, Escort 1 200/1 600/3 300/6 500 — landing with S25/S26.

**01's 2026-10-08 block — the SC table (A5's model band):** SC(t) =
1 100 / 1 500 / 3 000 / 6 000, ±25 %; the belt reads ≈1 800 gross against
§5.1's 1 900 floor; a T4 hold ≈8 000 gross; the 135 000 CR ladder ≈60–75
sessions against the 70–100 target.

## 6. Acceptance list
The reports answer every item with a cite (`§…` / `file:line`) or mark it
`NOT DONE`; R1 grades this list first.

- **A1 (C1)** — the 20 rows land exactly as 02's table; T1's ten cells
  byte-identical (`git diff` shows no T1 value change); the board monotone.
- **A2 (C1)** — `round(ore × 3.6)` holds for all 15 T2–T4 ingot cells; the
  exchange's restated 05 §10 rows come out of the live catalogue arithmetic
  (`exchange_price`, `sale_quote`), never from literals.
- **A3 (C1)** — `conversion_fee` returns the 04 §8 column for all 20 minerals;
  iron's 15/30/45 CR rows pass unchanged; `u_refine`'s truncation matches
  ("7, not 7.5"; krilium 64 → 32).
- **A4 (C1)** — `fee_for(mineral_id, conversions, mult)` is the only fee door;
  the four `refinery_panel.gd` call sites re-point and the panel still
  hardcodes no number (grep proves it).
- **A5 (C1)** — `test_s28_econ.gd` asserts the derivation (tier means ±1 %,
  the ×3.6 law, the fee column, the monotone board) and the SC model rows
  (belt hold ≈1 330 ±10 %, T4 hold ≈8 000 ±10 %) computed from the live
  catalogue, never from literals.
- **A6 (C2)** — the battery: 1/2/3/7 fitted `w_mining` deliver 1/1.4/1.8/3.4
  work units per cycle; `battery()` still reports the fitted count; the floor
  is one channel; `battery_gain` rides `reset_to_defaults`/`to_dict`/`from_dict`
  and the F1 overlay.
- **A7 (C2)** — the bloom: 6 rocks × 1.5 yield at T+1, same trigger and tier
  bonus; `test_s6_poi_loot.gd`'s rows restate.
- **A8 (C2)** — `test_s28_events.gd` asserts the battery law and the bloom cap
  from the live surfaces.
- **A9 (R1)** — the gate ×2 on fresh scratch stores; before/after `[SUMMARY]`
  recorded; every moved test row accounted for; the sealed
  `test_p1_refinery.gd:192` row untouched.
- **A10 (R1)** — CONTRACTS gains the wave's section (the fee door, the battery
  law, the bloom constants, the value-table pointer) at the next free section,
  plus §9's measured block and §10's changelog row.
- **A11 (both)** — each report tables every moved value with its reversal and
  its M-tick, and names the escalation bucket of anything it flagged.

## 7. Worker table
| ID | Role | VAJB_WORKER_FILES | Deliverable |
|---|---|---|---|
| S28-C1 | coder | `game/mineral_catalog.gd, game/refinery.gd, ui/station/refinery_panel.gd, tests/test_p1_catalogues.gd, tests/test_p1_pricing.gd, tests/test_p1_refinery.gd, tests/test_s34_refinery_queue.gd, tests/probe_s34_review.gd, tests/test_s28_econ.gd` (+ its report) | A1–A5: the value table, the fee law, the re-pointed call sites, the moved rows, the econ suite |
| S28-C2 | coder | `game/ore_tuning.gd, game/mining_laser.gd, ui/dev/dev_tuning_menu.gd, game/poi.gd, tests/test_s13_caps.gd, tests/test_s13_mining_batteries.gd, tests/test_s13_devmenu.gd, tests/test_s6_poi_loot.gd, tests/test_s28_events.gd` (+ its report) | A6–A8: the battery law, the bloom cap, the overlay field, the moved rows, the events suite |
| S28-R1 | reviewer | `tests/, tools/, docs/CONTRACTS.md` (+ its review) | A9–A10: the re-measured grade, the CONTRACTS pin, the findings |
| S28-F1 | fixer | the union (SLICE's row) | the HIGH/MED fixes only |

## 8. Run order + the tests that move
**C1 → C2 → R1 → (F1 only on HIGH/MED).** C1 and C2 are file-disjoint but run
in order — one live session, and the gate is global.

Tests that move, and why:
- `test_p1_catalogues.gd` — the T2–T4 value rows (the table moved) — **C1**
- `test_p1_pricing.gd` — gold/krilium demand rows (`:24-25`), `sale_quote`
  395→212 (`:74`), `exchange_price(gold, 1.2)` 465→249 (`:131`),
  `unit_gross` 474→254 (`:78`) — **C1**
- `test_s34_refinery_queue.gd` — duration rows: gold 40 → **26**; krilium
  stays 60 (the ceiling); iron/copper stay 10; the 15/30/45 fee rows survive —
  **C1**
- `test_p1_refinery.gd` — expected **green untouched** (the floor keeps iron
  at 15); the sealed `:192` row must not move — **C1** (verify-only)
- `probe_s34_review.gd` — its fee/duration figures re-derive — **C1**
- `test_s13_mining_batteries.gd` — the N=2/3 work rows under `1+0.4×(N−1)` —
  **C2**
- `test_s13_caps.gd` — additive: the `battery_gain` const/default row — **C2**
- `test_s13_devmenu.gd` — additive: the overlay field row + the Save/Load key —
  **C2**
- `test_s6_poi_loot.gd` — the bloom rows 10×2 → 6×1.5 — **C2**
- Not moving: `test_s7_affixes.gd` (its 2160 is shield math, not ore),
  `test_s14_splits`/`test_s16_resplits`/`test_s22_*` (yields, splits and
  toughness untouched).

## 9. Hard rules
- File set: exactly your SLICE row (dispatch sets `VAJB_WORKER_FILES`); do not
  touch docs, other workers' files, `addons/`
- Shell edits are forbidden (hook gap) — edit tools only
- Every Godot run bounded (`--quit-after`), probes self-quit, no background
  commands left running
- The gate runs twice on fresh scratch `XDG_DATA_HOME` stores; both
  `[SUMMARY]` lines recorded
- A number you believe is wrong is reported with its bucket and left in place
  — the brief is law
- Worker reports ≤120 lines (REPORT template), the review ≤150 (REVIEW)

## 10. Staged / deferred
- **S25/S26 brief extracts re-cut** against `14`'s S28 block before their
  dispatch (the queue rows carry it) — the payouts land with their waves
- **S27** prices its new modules/affix rows from L2's bands (module 1–2 SC(t),
  consumable 0.1–0.4 SC(1))
- **Work-per-unit tier scaling is dropped** from the law: sessions are
  hold-limited (01 §2 — the hold ends the mining phase), so per-unit work
  changes feel, not income; staged for the probe's evidence
- **Insurance (M14)** stays docs-only; S26 implements the premiums
- The CONTRACTS bloom sentence (`10 rocks, 2× yield`) is R1's to restate

## 11. Owner tick list (all seven rows owner-ratified green 2026-10-08 — every row ships as tabled)
| Tick | Row | Shipped as | Reverse by |
|---|---|---|---|
| M8 | the value-ladder factor | ×2.0/tier (T2 −21 %, T4 −58 %; belt ≈200 CR light of §5.1's floor; ≈60–75 sessions) | 02's block: ×1.8 (stricter) or the T1+T2-legacy hybrid |
| M9 | the refine fee | `max(15, 8 % of ingot)` per conversion | 04 §8: flat 15 |
| M10 | the boss caches | 6 000 / 12 000 (lands with S26) | 14's block: 15 000 / 40 000 |
| M11 | contract flat bases | T1 values; sectors scale ×SC(t)/SC(1) (lands with S25) | 14's block: flat at every sector |
| M12 | the mining battery | `1 + 0.4×(N−1)` work channels | `ore_tuning.gd`: gain 1.0 (linear) |
| M13 | the ore bloom | 6 rocks × 1.5 yield | `poi.gd`: 10 × 2 |
| M14 | insurance premiums | the per-class flats (200–700) | 14's block: 1.5 % of hull list |

## 12. Close-out (the orchestrator)
1. Gate re-run ×2 hermetic on fresh scratch stores
2. `python3 staging/verify_wave.py verify --baseline s28_start`
3. `python3 staging/build_code_map.py` — the map must describe the shipped tree
   (deterministic; a no-change re-run diffs nothing).
4. R1's CONTRACTS section + §9 measured block + §10 changelog row
5. WAVEBOARD §Queued row closed + TICKS refresh (the M-rows leave as ruled)
6. MASTER_REPORT §6 recap; wave-boundary commit
7. Then the S25/S26 brief re-cuts against `14`'s S28 block (queue items 31/32)
