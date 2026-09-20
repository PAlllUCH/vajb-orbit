# P1d report — minerals exchange module (docs 05, 01 §7, 03 §3, 17 §5)

## Deliverable

`vajb-orbit/game/exchange.gd` — 513 lines, one new file, nothing else touched
(no `project.godot`, `addons/`, docs, editor, MCP tools, no other script).
`class_name Exchange extends RefCounted`; helpers preloaded by path
(`MineralCatalog`, `ComponentCatalog`, `Clock`, `Log`); no autoload name used as
a bare identifier. No `.uid` sidecar was produced (headless run, no import step).

Probe `tools/_probe_p1d.gd` + `_probe_p1d.tscn` were created, run, then deleted
with the run log; no `.uid` sidecars appeared for them either. `user://` holds
no `p1d_probe*` file (the probe deleted both and asserted so).
`user://profile.cfg` was never written — mtime `1789722008`, size `199`, identical
before and after every run (the probe asserts this itself).

## Command and observed output

    "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tools/_probe_p1d.tscn --quit-after 300

Final run: `EXIT=0`, `[P1d] 153 checks, 0 failures`, `PROBE OK` on stdout,
0 `SCRIPT ERROR`, 0 `ERROR`, 0 `WARNING` lines (only the engine version line and
the godot_ai banner). `--check-only --script` was not used. The first run failed
loudly and by design: `PROBE FAIL`, `EXIT=1` (`Cannot infer the type of "state"`
at exchange.gd:178/229/252/257/281, then a run whose 6 failures are deviation 1
plus two bugs in the probe itself, deviation 3).

## Contract surface (tabs, typed, house header)

| Lines | What |
|---|---|
| 1-43 | Header: cites 05 §2-§6/§8, 01 §7, 17 §4/§5, STATION_HUB §5.8; records both rounding bases and the 05 §2 aside |
| 45-72 | Preloads; `COMMISSION`, `COMMISSION_MIN`, `DEMAND_MIN/MAX/STEP`, `TRADE_IMPACT`, `SURPLUS_DISCOUNT`, `STOCK_QUOTA`; reasons/events |
| 82-162 | `unit_net`, `unit_gross`, `commission_for`, `sale_quote`, `component_unit_price`, `baseline_of`, `exchange_price`, `is_component`, `is_sellable`, `demand_of`, `quota_for`, `trend_word` |
| 187-300 | `evaluate_market` (init stamp; ≤0 bands; per band drift → restock → queue flush), `quote`, `sell`, `sell_all`, `_bulk_ids` |
| 308-513 | `_quote_from`, `_apply_trade`, `_log_sale`, `_drift_demand`, `_step`, `_restock_missing`, `_restock`, `_flush_queue`, `_blank_quote`, `_refuse`, `_demand_from`, `_set_*`, `_bucket`, `_lookup`, `_integer`, `_number` |

Profile state is read/written only through its public API (`market`/`set_market`/
`cargo_qty`/`cargo_items`/`remove_cargo`/`add_credits`/`credits`); credits are
ints, only demand is a float; no `print()` (and no `push_warning` needed).

## Probe assertions (153 checks, all pass)

1. **05 §3 table** — `baseline_of` 65/162/395/2160 and `unit_net` at 1.0/0.6/1.6
   → 64/38/102, 159/95/254, 387/232/619, 2117/1270/3387, each also through
   `exchange_price`; Iron ore @1.0 = 18 (not the aside's 17);
   `component_unit_price(12)=11`, `(140)=126`; `unit_gross(395,1.2)=474`;
   `commission_for(4740)=95`, `(1)=10`, `(1005)=21`, `(0)=0`; `quota_for`
   40/15/4, unknown 0; `trend_word` COOLING/STEADY/HOT; unknown item and the bare
   id `&"iron"` priced 0; sellable/component predicates.
2. **05 §5 quotes** — `sale_quote(395,1.2,10)` → 4740/95/4645;
   `sale_quote(component_unit_price(12)=11,1.0,1)` → 11/10/1; never negative.
3. **Bands** — first call returns 0 and stamps `last_band`; stock filled 40/15/4
   for all 18 (trend still empty); +1200 s returns 1, stamp advances, all 20
   demands in [0.6,1.6], trend ∈ {-1,0,1}; the table equals an independent replay
   of the seeded draws; +3600 s returns 3 with the 3-band replay; a
   no-elapsed-band call returns 0 and changes nothing; demand 1.6 with a positive
   first step stays 1.6, 0.6 with a negative step stays 0.6.
4. **Seeded RNG** — same seed → identical band count, demand and trend tables
   (seed 11: iron 1.097986, copper 0.972896, krilium 1.135204); a different seed
   differs; `rng = null` uses the global RNG and stays in band.
5. **Mineral sale** — quote 10 `mineral_iron` @1.0 → unit 18, gross 180, fee 10,
   paid 170, sellable 10/queued 0/stock 0, mutates nothing; `sell` → credits
   +170, hold empty, demand 0.9; the log holds exactly one line
   `2026-09-18T09:28:04, SELL, mineral_iron, 10, +170, 10170` (six fields, qty 10,
   delta +170, balance = post-sale balance).
6. **Component flow** — 50 `comp_scrap_1`: stock 40, sellable 40, queued 10,
   unit 11, gross 440, fee 10, paid 430; after `sell` credits +430, hold empty,
   stock 0, queue 10, one SELL + one QUEUE line; one band → +100, queue 0,
   stock 30, one QUEUE_BUY line.
7. **`sell_all`** — ore 5 copper (paid 100) + component 20 `comp_pow_1` (paid
   270): 2 lines, none skipped, total 370 = sum of lines, credits +370, ingot
   stack untouched and not attempted, only the copper demand moved; empty hold →
   paid 0, no lines, ok.
8. **Refusals** — unknown item, qty 0, negative qty, more than held → the exact
   reason, cargo/credits/demand untouched, nothing logged; empty-stock sale →
   sellable 0, queued 5, paid 0, credits unchanged, goods taken into the queue.

## Deviations and calls a reviewer should check

1. **Two real defects found by the gate and fixed in the module.**
   (a) `commission_for(0)` returned the 10 CR floor, so a stack sold into an
   empty stock paid **-10** and `add_credits` debited 10 CR (observed FAILs:
   "empty stock: paid 0", "credits unchanged"). (b) The component branch and the
   queue flush used raw `gross - fee`. Fix: `commission_for` returns 0 for
   `gross <= 0` ("a zero-gross transaction is not a sale") and both paths use
   `maxi(0, gross - fee)`; the floor at gross ≥ 1 is unchanged and asserted. The
   header records the rule.
2. **05 §2's raw-ore aside is a typo, not special-cased** (as briefed):
   `18 × 0.98 = 17.64 → 18`. The probe asserts 18 and prints the discrepancy.
3. **Catalogue id spelling.** 05 §3 names the mineral "Krillum"; the catalogue id
   is `krilium` (`game/mineral_catalog.gd:246`). The first probe used
   `ingot_krillum` and correctly got baseline 0 / price 0; it now uses
   `ingot_krilium`. Nothing in the module hardcodes either spelling.
4. **Init materialises stock only.** Per the brief's init branch, `demand` stays
   implicit at 1.0 (05 §2's start state) and only becomes a key at the first band,
   so `market()["demand"]` is empty right after the first evaluation.
5. **`sell_all` overflow.** The brief ("every surplus-book component, each per the
   `sell` rules") is implemented as full stacks, so overflow queues; the stricter
   reading of 05 §6 / STATION_HUB §5.8 ("within quota") would leave the overflow
   in the hold. Flagged. Ingots appear in neither `lines` nor `skipped`.
6. **`sell_all` writes the market once**, after all lines, on the single
   evaluation the brief requires; `sell` writes once per transaction.
7. **A fully-queued component sale still logs** `SELL … 0 … +0` plus the QUEUE
   line, the literal reading of the brief's log step.
8. **`demand_of` accepts the item form** (`ingot_gold` → gold's demand) as well
   as the bare mineral id; unknown ids default to 1.0.
9. **`Log`, not `EconomyLog`**, is the local const name: preloading the log under
   the global class name would shadow `EconomyLog`. `MineralCatalog`,
   `ComponentCatalog` and `Clock` do shadow their global names in this file,
   exactly as the brief prescribes; the run showed no warning.
10. **RNG consumption order is part of the contract**: one `randf_range` per mineral per band, catalogue order, no draws during init or a 0-band call, so the P1l market suite must seed the same way to see identical tables.
11. **Typing note for sibling modules**: with `profile: Node` the engine cannot
    infer types, so every local derived from a profile call needs an explicit
    type; `var state := profile.market()` is a parse error.
12. **The gate itself was hardened**: `EXPECTED_CHECKS = 153`, because a runtime
    error inside a step function aborts that function only, and the first broken
    run still printed `PROBE OK` with 7 checks.
