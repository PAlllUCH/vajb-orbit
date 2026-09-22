# S3_BRIEF — The item economy (module instances with affixes + the AUCTION)

Wave `S3`, slice `S3-module-affixes`. Read in this order before working:
1. `AGENTS.md` (rules; the folder law; the worker-file enforcement)
2. `docs/gameplay/15_module_affixes.md` **end to end** (§1–§7 the design, §8 the
   dated amendment with every reversal)
3. `docs/gameplay/10_ship_acquisition.md` §2/§2.4/§5/§6 and
   `docs/gameplay/09_ship_slots_modules.md` §3.1/§4/§10
4. `docs/design/STATION_HUB.md` §5.1/§5.3/§5.10
5. `docs/CONTRACTS.md` **§15** (this wave's pin), then §12/§13 (the seams it extends)
6. this brief end to end

## Owner requests, verbatim

- (2026-09-22, deferring affixes out of P2-B proper) — affixes are the next wave:
  the instance shape `{base_id, rarity, prefixes[], suffixes[]}`, the roll sources
  and the 15 §7 naming/stat grammar.
- (2026-09-22) "We need AUCTION. without it we cannot test all items."

That second sentence is why the auction is **inside** this wave: only the auction
carries every module family and the three faction exclusives (15 §5), so the
instance system cannot be tested on all items without it. Instances roll at
creation and the auction sells the rolled shelf — one design, one wave.

## What is already measured (do not re-derive, do verify)

- 15 §1–§7 pins everything economic: rarity contract (Common 0 / Magic 1+1 /
  Rare 2+2), value multipliers ×1.0/×1.6/×2.6, source roll tables (§2), the 12
  prefix bands and 10 suffix boons (§3/§4), the three exclusives' Magic+ floor (§5),
  the naming grammar (§7). 15 §8 pins instance identity, save v6, roll timing and
  the faction-lot interim with reversals.
- 10 §2 pins the auction's mechanics: 6 hulls + 10 modules, 20-minute station-clock
  restock, tier weights I 50 / II 35 / III 15, hull weights (§2.2), buyout at list,
  60 % sell-back, rotation persists with the save.
- The current inventory record shape is `{base_id, count}` in `modules`
  (`autoload/player_profile.gd`, save v5, `SAVE_VERSION` at the top of the file);
  `fit_module_at` / `clear_fit_slot` (CONTRACTS §13, `player_profile.gd:501/:534`)
  and `set_fit_slot` already tolerate arbitrary cell values (15 §6's note).
- OUTFITTING's seven weapon rows are the interim this wave retires
  (`ui/station/outfitting_panel.gd`, `ModuleCatalog`, `buy_module`; 10 §6's note
  closes it). L80 documents the instance-vs-base-id seam this wave resolves.
- Live measured caution (L93): run the gate with a scratch profile until wave
  S2.6's harness fix lands (it runs first).

## The pinned interface (CONTRACTS §15 is the source of truth; nothing here may drift)

```gdscript
# PlayerProfile — additive; the §13 transactions keep their signatures and accept
# instance ids where they accepted module ids.
add_instance(base_id: StringName, rarity: StringName, prefixes: Array, suffixes: Array) -> StringName
instance(id: StringName) -> Dictionary      # {instance_id, base_id, rarity, prefixes, suffixes}; {} when absent
instances_of(base_id: StringName) -> Array  # ids, for the grouped rows
buy_instance(id: StringName) -> bool        # the auction shelf's rolled instance
sell_instance(id: StringName) -> bool       # base × rarity multiplier × 60 %
roll_instance(base_id: StringName, source: StringName) -> StringName  # 15 §2's tables
SAVE_VERSION := 6
# instance_id = "mod_%04d", one per-profile counter
```

Rules that fix every ambiguity:
- **Roll at creation**, global RNG, outcomes persisted, never re-rolled; auction
  listings roll at **restock draw** (the rolled name and price are visible —
  "hunting the good roll"); drops roll at the drop. Tests seed the RNG first and
  assert the seeded outcomes.
- Migration v5→v6: each `{base_id, count}` record → `count` **Common** instances,
  idempotent (the P2-B flag-day pattern; measured acceptance: a v5 file with a
  stacked record reads back as that many instances and a second migration call
  returns 0). The owner tick on retro-rolling is listed below — **build Common**;
  a tick for retro-roll is one function call at migration.
- `resolved_fit` / `fit_legal` see through `instance()[&"base_id"]`; a fit cell
  holds the `instance_id` and REMOVE/SWAP return **the same instance** (L80's
  ruling: instances are never destroyed, never duplicated).
- Prices: 09 §3.1's frozen costs are the `base`; rarity multipliers apply to the
  base; the hot slot's −20 % applies after (15 §1). Sell = `base × rarity × 60 %`.
- The auction UI is `STATION_HUB.md` §5.10 verbatim (rows, footer, sell sub-list,
  rarity tints, focus order). `AUCTION_FACTION_LOTS_INTERIM := true` (15 §8).
- OUTFITTING's module rows retire completely (rows + their tests); the pane
  returns to ammunition + the FITTED WEAPONS strip. `buy_module`/`ModuleCatalog`
  stay as the price source with no new UI callers.
- Refusals gain no new wordings: §13's three + 09 §2's `<n> NEEDED`.

## Worker table

| ID | Role | VAJB_WORKER_FILES | Deliverable |
|---|---|---|---|
| S3-K0 | docs drift check | `docs/,vajb-orbit/tests/,vajb-orbit/tools/` | `S3-K0_report.md`: 15/10/09/STATION_HUB/§15 read against the tree; contradictions listed with file:line; no numbers invented |
| S3-K1 | instance core + save v6 | `vajb-orbit/autoload/player_profile.gd,vajb-orbit/game/module_catalog.gd,vajb-orbit/game/ship_fit.gd,vajb-orbit/tests/` | the §15 API, the roll tables, the migration; `tests/test_s3_instances.gd`, `tests/test_s3_migration.gd` |
| S3-K2 | the AUCTION + retirement | `vajb-orbit/ui/station/auction_panel.gd,vajb-orbit/ui/station/auction_panel.tscn,vajb-orbit/ui/station/outfitting_panel.gd,vajb-orbit/ui/station/outfitting_panel.tscn,vajb-orbit/ui/screens/station.gd,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/` | §5.10's screen (rotation, hot slot, F lots, sell sub-list), OUTFITTING's rows retired; `tests/test_s3_auction.gd` |
| S3-K3 | naming + fitting integration | `vajb-orbit/ui/station/fitting_panel.gd,vajb-orbit/ui/station/shipyard_panel.gd,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/` | 15 §7 names + stat lines in FITTING/shipyard hover, instance-true install/remove round-trips |
| S3-K4 | mandatory review | `vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md` | `S3-K4_review.md` + LOW rows in `_state/LOW_BACKLOG.md` |
| S3-K5 | fixer | the union of K1–K3 sets + `docs/CONTRACTS.md` | only if K4 leaves HIGH/MED |

**Run order:** K0 → K1 → K2 → K3 → K4 → (K5 only on HIGH/MED). K1 lands the
records before K2 sells them; K2's retirement lands before K3 shows names
everywhere. K2 and K3 both touch `player_profile.gd` — sequential, never parallel.

## Tests that move, and why

- `test_p2b1_outfitting_panel.gd` (9) — the MODULES row tests rewrite to the
  ammunition-only pane (rows retired into the auction).
- `test_p2b_fitting_panel.gd` (20) — hover/stat lines now carry rolled names;
  counts hold.
- `test_p1_profile.gd` — the save-version digit moves 5 → 6; the modules record
  shape tests move to instances (counts hold or grow).
- New: `test_s3_instances.gd` (rolls, seeded outcomes, never re-roll, L80's
  remove/swap identity), `test_s3_migration.gd` (v5→v6 idempotence),
  `test_s3_auction.gd` (rotation draw, weights over N seeded draws, hot slot,
  F lot, buy → inventory instance, sell price). Expected gate: **437 → ~455**;
  the measured number at close-out is the one that goes in CONTRACTS §9.

## Hard rules

- Frozen: `project.godot`, `docs/gameplay/18_engine_spec.md`, `08_ship_slots_modules.md`,
  `assets/`, `addons/`, the theme (except the three `rarity_*` theme tokens
  STATION_HUB §5.10 names — those are this wave's, through the theme file only).
- No base price, roll weight, multiplier or §3.1 stat moves —15/10/09 are frozen
  arithmetic this wave implements.
- No shell-based file edits; workspace-relative `VAJB_WORKER_FILES` paths (L92a).
- Bounded probes only (hard iteration bounds — L82). Never leave a background job.
- A number not in the pinned docs: **report it, never invent it**.

## Staged / deferred

- Crafting rolls (15 §2's 40/45/15), derelict and arena roll sources — those
  systems do not exist yet; the roll tables gain their rows but no callers.
- Faction stations (12 §5) — the F-lot interim stands until they ship (owner tick).
- Weapon batteries (09 §10) are wave S4, after this one.

## Owner ticks owed after this wave

1. **v5 stock migration**: Common instances (as built) vs retro-rolled through
   their source tables (one call at migration). One constant.
2. **Faction lots**: the `AUCTION_FACTION_LOTS_INTERIM := true` shelf tag until
   faction stations exist — keep (as built) or false.
3. **Rail position**: AUCTION directly after EXCHANGE — keep or move (one enum value).

## Close-out (the orchestrator runs these, in order)

1. Gate twice (scratch profile; identical counts) + the live-profile untouched check.
2. `python3 staging/verify_wave.py verify --baseline s3_start --forbidden vajb-orbit/project.godot,vajb-orbit/docs/gameplay/18_engine_spec.md --expect-reports S3-K0_report.md,S3-K4_review.md --tests`
3. CONTRACTS §9 figure + §10 measured note updated by K4; 15 §8/10 §2.4 ticked.
4. `_state/WAVEBOARD.md` row closed; LOW findings appended as L94+.
5. Wave-boundary commit.
