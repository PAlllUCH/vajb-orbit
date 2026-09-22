# S3_prompts — dispatch blocks (worker prompts live here; the owner never pastes them)

Model for every worker: `deepseek/deepseek-v4-flash` (owner instruction 2026-09-22).
Run from the workspace root. Reports: `slices/S3-module-affixes/<WorkerID>_report.md`,
the review `S3-K4_review.md`. Run this wave **after S2.6 closes** (the gate is only
trustworthy once the harness fix lands).

## Before the first dispatch (one line)

```bash
cd "$VAJB_WORKSPACE" && python3 staging/verify_wave.py snapshot --name s3_start && git add -A && git commit -m "Record the pre-wave state before the item-economy wave"
```

## S3-K0 — docs drift check

```bash
VAJB_WORKER_FILES="docs/,vajb-orbit/tests/,vajb-orbit/tools/" crush run "You are worker S3-K0 on the Vajb Orbit workspace (wave S3, brief .agents/gen/slices/S3-module-affixes/S3_BRIEF.md — read it first, then docs/gameplay/15_module_affixes.md end to end, docs/gameplay/10_ship_acquisition.md §2/§2.4/§5/§6, docs/design/STATION_HUB.md §5.10, docs/CONTRACTS.md §15/§12/§13). Task: read the pinned set against the actual tree and report every contradiction, stale line or missing file this wave will touch (player_profile.gd, module_catalog.gd, ship_fit.gd, auction_panel new, outfitting_panel.gd, fitting_panel.gd, shipyard_panel.gd, station.gd). Invent no numbers and fix nothing: deliver .agents/gen/slices/S3-module-affixes/S3-K0_report.md with findings at file:line. Hard rules in the brief apply." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## S3-K1 — instance core + save v6

```bash
VAJB_WORKER_FILES="vajb-orbit/autoload/player_profile.gd,vajb-orbit/game/module_catalog.gd,vajb-orbit/game/ship_fit.gd,vajb-orbit/tests/" crush run "You are worker S3-K1 on the Vajb Orbit workspace (wave S3, brief .agents/gen/slices/S3-module-affixes/S3_BRIEF.md — read it first, then docs/gameplay/15_module_affixes.md incl. §8 and docs/CONTRACTS.md §15/§13). Task: implement the §15 PlayerProfile API exactly as pinned — the instance record {instance_id=mod_%04d, base_id, rarity, prefixes[], suffixes[]}, roll_instance with 15 §2's source tables and §3/§4's bands (roll at creation, global RNG, persisted, never re-rolled), sell at base × rarity × 60 %, and SAVE_VERSION 6 with the idempotent v5→v6 Common-instance migration (the P2-B flag-day pattern). resolved_fit/fit_legal see through instance()[&\"base_id\"]; REMOVE/SWAP return the same instance (L80). Fit cells may hold instance ids. Add tests/test_s3_instances.gd and tests/test_s3_migration.gd (seeded roll outcomes, never-re-roll, v5 stacked record → N Common instances, second migration call returns 0, remove/swap identity). Report .agents/gen/slices/S3-module-affixes/S3-K1_report.md with measured numbers. Hard rules in the brief apply; no price or weight may move." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## S3-K2 — the AUCTION + the retirement

```bash
VAJB_WORKER_FILES="vajb-orbit/ui/station/auction_panel.gd,vajb-orbit/ui/station/auction_panel.tscn,vajb-orbit/ui/station/outfitting_panel.gd,vajb-orbit/ui/station/outfitting_panel.tscn,vajb-orbit/ui/screens/station.gd,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/" crush run "You are worker S3-K2 on the Vajb Orbit workspace (wave S3, brief .agents/gen/slices/S3-module-affixes/S3_BRIEF.md — read it first, then docs/gameplay/10_ship_acquisition.md §2/§2.4, docs/design/STATION_HUB.md §5.10 and docs/CONTRACTS.md §15). Task: build the AUCTION screen exactly as STATION_HUB §5.10 (the rail entry after EXCHANGE, HULLS 6 + MODULES 10 rolled-instance rows, hot slot −20 % after rarity, the 20-minute station-clock restock footer, the SELL MODULES sub-list at base × rarity × 60 %, rarity tints through the three rarity_* theme tokens, focus order) over 10 §2's mechanics (weights, buyout, persistence) and 15 §8's faction-lot interim (AUCTION_FACTION_LOTS_INTERIM := true). Then retire OUTFITTING's seven weapon module rows completely (10 §2.4/§6) — the pane returns to ammunition and the FITTED WEAPONS strip; buy_module/ModuleCatalog remain the price source with no new UI callers. Module listings roll at restock draw via S3-K1's roll_instance. Add tests/test_s3_auction.gd (seeded rotation draw and weights over N draws, hot slot, F lot at Magic+ floor, buy → instance in inventory, sell price). Report .agents/gen/slices/S3-module-affixes/S3-K2_report.md with measured numbers. Hard rules in the brief apply." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## S3-K3 — naming + fitting integration

```bash
VAJB_WORKER_FILES="vajb-orbit/ui/station/fitting_panel.gd,vajb-orbit/ui/station/shipyard_panel.gd,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/" crush run "You are worker S3-K3 on the Vajb Orbit workspace (wave S3, brief .agents/gen/slices/S3-module-affixes/S3_BRIEF.md — read it first, then docs/gameplay/15_module_affixes.md §6/§7/§8, docs/design/STATION_HUB.md §5.3/§5.10 and docs/CONTRACTS.md §15/§13). Task: surface rolled identity everywhere the fit is read — FITTING's OWNED MODULES rows, its hover line and the shipyard hover line show the 15 §7 full rolled name and its stat block (base stats + one line per affix), rarity-tinted per §5.10 — and make install/swap/remove instance-true through the §13 transactions (a fit cell holds the instance id; REMOVE/SWAP hand back the same instance; two same-base instances stay distinguishable). Aggregate rows by base_id with OWNED ×<n> as today; the expander detail lists instances. Extend tests/test_p2b_fitting_panel.gd accordingly (counts hold) and add instance round-trip coverage. Report .agents/gen/slices/S3-module-affixes/S3-K3_report.md with measured numbers. Hard rules in the brief apply." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## S3-K4 — mandatory review (after K1, K2, K3 report)

```bash
VAJB_WORKER_FILES="vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md" crush run "You are worker S3-K4, the mandatory reviewer of wave S3 (brief .agents/gen/slices/S3-module-affixes/S3_BRIEF.md; diff findings against docs/CONTRACTS.md §15/§13/§12 and the pinned docs 15/10/09/STATION_HUB, not against the brief). Re-measure everything yourself: re-run each builder probe byte-identically; verify seeded roll tables against 15 §2/§3/§4 row by row; verify the migration idempotence and L80's remove/swap identity; verify the auction's weights over a large seeded draw and the hot-slot/F-lot arithmetic (15 §1's multiplier order); verify no frozen file moved and no base price or weight moved (staging/verify_wave.py verify --baseline s3_start --forbidden vajb-orbit/project.godot,vajb-orbit/docs/gameplay/18_engine_spec.md --tests); run the gate twice. Tier findings HIGH/MED/LOW with file:line and measured evidence. Write .agents/gen/slices/S3-module-affixes/S3-K4_review.md, append LOW rows to .agents/gen/_state/LOW_BACKLOG.md (next free L numbers), update docs/CONTRACTS.md §9/§10 measured notes. Never fix. Bounded probes only." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## S3-K5 — fixer (only if K4 leaves HIGH or MED)

```bash
VAJB_WORKER_FILES="vajb-orbit/autoload/player_profile.gd,vajb-orbit/game/module_catalog.gd,vajb-orbit/game/ship_fit.gd,vajb-orbit/ui/station/auction_panel.gd,vajb-orbit/ui/station/auction_panel.tscn,vajb-orbit/ui/station/outfitting_panel.gd,vajb-orbit/ui/station/outfitting_panel.tscn,vajb-orbit/ui/station/fitting_panel.gd,vajb-orbit/ui/station/shipyard_panel.gd,vajb-orbit/ui/screens/station.gd,vajb-orbit/tests/,docs/CONTRACTS.md" crush run "You are worker S3-K5, the fixer of wave S3 (brief .agents/gen/slices/S3-module-affixes/S3_BRIEF.md; review .agents/gen/slices/S3-module-affixes/S3-K4_review.md). Fix ONLY the HIGH and MED findings at their named file:line; adjust tests only where a fix changes what is proven. No LOW items, no refactors, no price or weight changes. Re-run the gate twice and report .agents/gen/slices/S3-module-affixes/S3-K5_report.md with a finding-by-finding disposition and the gate lines." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```
