# S3_prompts — dispatch blocks (worker prompts live here; the owner never pastes them)

Model for every worker: `deepseek/deepseek-v4-flash` (owner instruction 2026-09-22).
Run from the workspace root. Reports: `slices/S3-module-affixes/<WorkerID>_report.md`,
the review `S3-K4_review.md`.
**v2, 2026-09-22 — amended after K0's 7 HIGH findings.** Three changes the first
version needed: K2's file set gains `game/auction.gd` (the rotation's home — the brief
never named one) and `ui/theme/vajb_theme.tres` (the three `rarity_*` tokens are this
wave's by rule and no set contained the file); every builder runs its own suite by full
basename (`--suite=test_s3_instances`, never `--suite=s3_instances` — L95/L99); and the
close-out's verify command is fixed (v1's commas, engine-spec path and bare report names
made it exit 1 with an inert frozen-file guard).

## Before the first dispatch (one line)

```bash
cd "$VAJB_WORKSPACE" && python3 staging/verify_wave.py snapshot --name s3_start && git add -A && git commit -m "Record the pre-wave state before the item-economy wave"
```

## S3-K0 — docs drift check — **DONE 2026-09-22**

```bash
VAJB_WORKER_FILES="docs/,vajb-orbit/tests/,vajb-orbit/tools/" crush run "You are worker S3-K0 on the Vajb Orbit workspace (wave S3, brief .agents/gen/slices/S3-module-affixes/S3_BRIEF.md — read it first, then docs/gameplay/15_module_affixes.md end to end, docs/gameplay/10_ship_acquisition.md §2/§2.4/§5/§6, docs/design/STATION_HUB.md §5.10, docs/CONTRACTS.md §15/§12/§13). Task: read the pinned set against the actual tree and report every contradiction, stale line or missing file this wave will touch (player_profile.gd, module_catalog.gd, ship_fit.gd, auction_panel new, outfitting_panel.gd, fitting_panel.gd, shipyard_panel.gd, station.gd). Invent no numbers and fix nothing: deliver .agents/gen/slices/S3-module-affixes/S3-K0_report.md with findings at file:line. Hard rules in the brief apply." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

Delivered `S3-K0_report.md` (548 lines): 7 HIGH, 7 MED, 13 LOW, gate 457/0. Its
answers are CONTRACTS §15 v0.7.3, 15 §9, this brief's v2 and the file sets below.

## S3-K1 — instance core + save v6

```bash
VAJB_WORKER_FILES="vajb-orbit/autoload/player_profile.gd,vajb-orbit/game/module_catalog.gd,vajb-orbit/game/ship_fit.gd,vajb-orbit/tests/" crush run "You are worker S3-K1 on the Vajb Orbit workspace (wave S3, brief .agents/gen/slices/S3-module-affixes/S3_BRIEF.md — read it first, then docs/gameplay/15_module_affixes.md incl. §8 AND §9 (the new exclusive rows) and docs/CONTRACTS.md §15 (v0.7.3)/§13). Task: implement the §15 API exactly as pinned — the record {instance_id, base_id, rarity, prefixes[], suffixes[], count} with count 1 in the bag and 0 while fitted (the record is never erased), the INSTANCE_ID_FORMAT mod_%04d counter key, roll_instance with 15 §2's source tables and §3/§4's bands plus the three exclusive rows of 15 §9.1 in module_catalog.gd, buy_instance(id, cost)/sell_instance at base × rarity × 60 %, take_instance/restore_instance as the fitted-instance round trip, auction()/set_auction(), and SAVE_VERSION 6 with the idempotent v5→v6 Common-instance migration (the P2-B flag-day pattern). A fit cell may hold an instance id, so the composed transactions and resolved_fit/fit_legal must translate cells through base_module_id BEFORE judging a fit — that is the required fix for fit_legal scoring an instance as draw 0. Add tests/test_s3_instances.gd and tests/test_s3_migration.gd (seeded roll outcomes, never-re-roll, the count 0/1 round trip, remove/swap handing back the same instance, two same-base instances distinguishable, a v5 stacked record → N Common instances, a second migration call returning 0). Also move the save-version digit in the suites the brief's tests-that-move list names. Report .agents/gen/slices/S3-module-affixes/S3-K1_report.md with measured numbers. Hard rules in the brief apply; no price or weight may move, and no affix may reach a flight stat." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## S3-K2 — the AUCTION + the retirement

```bash
VAJB_WORKER_FILES="vajb-orbit/game/auction.gd,vajb-orbit/ui/station/auction_panel.gd,vajb-orbit/ui/station/auction_panel.tscn,vajb-orbit/ui/station/outfitting_panel.gd,vajb-orbit/ui/station/outfitting_panel.tscn,vajb-orbit/ui/screens/station.gd,vajb-orbit/ui/theme/vajb_theme.tres,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/" crush run "You are worker S3-K2 on the Vajb Orbit workspace (wave S3, brief .agents/gen/slices/S3-module-affixes/S3_BRIEF.md — read it first, then docs/design/STATION_HUB.md §5.10 and §5.1, docs/gameplay/10_ship_acquisition.md §2/§2.2/§2.4, docs/gameplay/15_module_affixes.md §8/§9 and docs/CONTRACTS.md §15). Task: build the AUCTION as STATION_HUB §5.10 (the rail entry Module.AUCTION after EXCHANGE with all five parallel arrays in station.gd:54-86 gaining an entry at index 3, HULLS 6 + MODULES 10 rolled-instance rows reusing each hull's preview as its icon, the hot slot −20 % after the rarity multiplier, the SELL MODULES sub-list at base × rarity × 60 %, the three rarity_* tokens in vajb_theme.tres, the focus order) over 10 §2's mechanics and 15 §8/§9's F lot (one exclusive per shelf at the Magic+ floor, 85 % Magic / 15 % Rare, tagged F LOT). Put the rotation in a new game/auction.gd that mirrors game/exchange.gd's lazy band accumulation (evaluate_shelf(profile, now, rng) over WorldClock.bands_between, state in the profile's top-level auction key — never a market sub-key), render NEXT RESTOCK <m:ss> as a reading taken at pane entry, and give the pane its own footer strip (the shell's copy would print 0 NEEDED for an instance). Then retire OUTFITTING's seven weapon module rows completely as §5.1's amendment: the pane returns to the FITTED WEAPONS strip and the ammo rows; buy_module/ModuleCatalog remain the price source with no new UI callers. Add tests/test_s3_auction.gd (seeded rotation draw and weights over N draws, hot slot arithmetic, the F lot at its floor with the 85/15 split, buy → instance with count 1 in the bag, sell price) and rewrite the retired rows' tests. Report .agents/gen/slices/S3-module-affixes/S3-K2_report.md with measured numbers. Hard rules in the brief apply." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## S3-K3 — naming + fitting integration

```bash
VAJB_WORKER_FILES="vajb-orbit/ui/station/fitting_panel.gd,vajb-orbit/ui/station/shipyard_panel.gd,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/" crush run "You are worker S3-K3 on the Vajb Orbit workspace (wave S3, brief .agents/gen/slices/S3-module-affixes/S3_BRIEF.md — read it first, then docs/gameplay/15_module_affixes.md §6/§7/§8/§9, docs/design/STATION_HUB.md §5.3/§5.10 and docs/CONTRACTS.md §15/§13). Task: surface rolled identity everywhere the fit is read — FITTING's OWNED MODULES rows aggregate by base_id with OWNED ×<n> as today and gain a ▸ expander listing one sub-row per instance (15 §7 full rolled name, rarity tint, its own ACTION), and the hover/selection line plus the shipyard hover show the rolled name plus the two-line stat block (base stats + one line per affix). Install/swap/remove must be instance-true through the §13 transactions: a fit cell holds the instance id, REMOVE/SWAP hand back the SAME instance (count 0 → 1, affixes intact), two same-base instances stay distinguishable. From HOLD, a display must translate to base ids before judging legality. Extend tests/test_p2b_fitting_panel.gd and tests/test_p2b_services.gd accordingly (counts hold; the rail test's hardcoded index 4 becomes 5) and add instance round-trip coverage. Report .agents/gen/slices/S3-module-affixes/S3-K3_report.md with measured numbers. Hard rules in the brief apply; no affix may reach a flight stat." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## S3-K4 — mandatory review (after K1, K2, K3 report)

```bash
VAJB_WORKER_FILES="vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md" crush run "You are worker S3-K4, the mandatory reviewer of wave S3 (brief .agents/gen/slices/S3-module-affixes/S3_BRIEF.md; diff findings against docs/CONTRACTS.md §15 (v0.7.3)/§13/§12 and the pinned docs 15 (incl. §9)/10/09/STATION_HUB, not against the brief). Re-measure everything yourself: re-run each builder probe byte-identically; verify seeded roll tables against 15 §2/§3/§4 row by row and the three exclusive rows against 15 §9.1; verify the migration idempotence, the count 0/1 round trip and L80's remove/swap identity; verify the auction's weights over a large seeded draw, the hot-slot arithmetic (15 §1's multiplier order) and the F lot's 85/15 split; verify that no affix moves a flight stat (the fit→flight path stays base-id); verify no frozen file moved and no base price or weight moved, with python3 staging/verify_wave.py verify --baseline s3_start --forbidden vajb-orbit/project.godot docs/gameplay/18_engine_spec.md --tests ; run the gate twice (the runner's scratch store is automatic). Tier findings HIGH/MED/LOW with file:line and measured evidence. Write .agents/gen/slices/S3-module-affixes/S3-K4_review.md, append LOW rows to .agents/gen/_state/LOW_BACKLOG.md using the file's own law (L94-L106 are taken, so continue at L107; the global ticket counter's next free id is T-93), update docs/CONTRACTS.md §9/§10 measured notes. Never fix. Bounded probes only." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## S3-K5 — fixer (only if K4 leaves HIGH or MED)

```bash
VAJB_WORKER_FILES="vajb-orbit/autoload/player_profile.gd,vajb-orbit/game/module_catalog.gd,vajb-orbit/game/ship_fit.gd,vajb-orbit/game/auction.gd,vajb-orbit/ui/station/auction_panel.gd,vajb-orbit/ui/station/auction_panel.tscn,vajb-orbit/ui/station/outfitting_panel.gd,vajb-orbit/ui/station/outfitting_panel.tscn,vajb-orbit/ui/station/fitting_panel.gd,vajb-orbit/ui/station/shipyard_panel.gd,vajb-orbit/ui/screens/station.gd,vajb-orbit/ui/theme/vajb_theme.tres,vajb-orbit/tests/,docs/CONTRACTS.md" crush run "You are worker S3-K5, the fixer of wave S3 (brief .agents/gen/slices/S3-module-affixes/S3_BRIEF.md; review .agents/gen/slices/S3-module-affixes/S3-K4_review.md). Fix ONLY the HIGH and MED findings at their named file:line; adjust tests only where a fix changes what is proven. No LOW items, no refactors, no price or weight changes, and no affix may start reaching a flight stat. Re-run the gate twice and report .agents/gen/slices/S3-module-affixes/S3-K5_report.md with a finding-by-finding disposition and the gate lines." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```
