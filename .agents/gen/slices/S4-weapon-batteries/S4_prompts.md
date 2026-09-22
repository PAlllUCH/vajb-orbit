# S4_prompts — dispatch blocks (worker prompts live here; the owner never pastes them)

Model for every worker: `deepseek/deepseek-v4-flash` (owner instruction 2026-09-22).
Run from the workspace root. Reports: `slices/S4-weapon-batteries/<WorkerID>_report.md`,
the review `S4-H3_review.md`. Run this wave **strictly after S3 closes** (it consumes
S3's instance ids and the retired-rows pane).

## Before the first dispatch (one line)

```bash
cd "$VAJB_WORKSPACE" && python3 staging/verify_wave.py snapshot --name s4_start && git add -A && git commit -m "Record the pre-wave state before the weapon-batteries wave"
```

## S4-H0 — docs drift check

```bash
VAJB_WORKER_FILES="docs/,vajb-orbit/tests/,vajb-orbit/tools/" crush run "You are worker S4-H0 on the Vajb Orbit workspace (wave S4, brief .agents/gen/slices/S4-weapon-batteries/S4_BRIEF.md — read it first, then docs/gameplay/09_ship_slots_modules.md §10/§4, docs/design/STATION_HUB.md §5.10/§5.1 and docs/CONTRACTS.md §16/§13/§8.2). Task: read the pinned set against the tree and report every contradiction or stale line this wave will touch (ui/station/outfitting_panel.gd/.tscn, autoload/player_profile.gd, game/weapons.gd, game/projectile.gd), including the measure-first item: does one trigger already discharge multiple barrels today, and where does the volley live? Invent no numbers and fix nothing: deliver .agents/gen/slices/S4-weapon-batteries/S4-H0_report.md with findings at file:line. Hard rules in the brief apply." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## S4-H1 — battery strip + bulk transactions

```bash
VAJB_WORKER_FILES="vajb-orbit/ui/station/outfitting_panel.gd,vajb-orbit/ui/station/outfitting_panel.tscn,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/" crush run "You are worker S4-H1 on the Vajb Orbit workspace (wave S4, brief .agents/gen/slices/S4-weapon-batteries/S4_BRIEF.md — read it first, then docs/gameplay/09_ship_slots_modules.md §10 and docs/design/STATION_HUB.md §5.10). Task: rebuild OUTFITTING's FITTED WEAPONS strip as battery rows exactly as §5.10 pins (3× LASER MKII · W1·W2·W3 · OWNED ×<n>, FIT ALL / REMOVE ALL / SWAP ALL, the per-barrel expander keeping every existing single-cell action and L78's precedence) and add PlayerProfile.fit_battery/clear_battery exactly as CONTRACTS §16 pins — loops over the §13 composed transactions, atomic batches that roll back to the starting fit on any failure with the §13 pinned refusals in the footer. No fit shape change: one instance per W cell. Add tests/test_s4_batteries.gd (grouping, bulk round-trip, batch rollback, expander reachability). Report .agents/gen/slices/S4-weapon-batteries/S4-H1_report.md with measured numbers. Hard rules in the brief apply." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## S4-H2 — volley + strum

```bash
VAJB_WORKER_FILES="vajb-orbit/game/weapons.gd,vajb-orbit/game/projectile.gd,vajb-orbit/tests/" crush run "You are worker S4-H2 on the Vajb Orbit workspace (wave S4, brief .agents/gen/slices/S4-weapon-batteries/S4_BRIEF.md — read it first, then docs/CONTRACTS.md §16/§8.2). Task: make one trigger discharge a whole battery exactly as §16 pins — WeaponComponent.battery(base_id) returns the battery's W indices, a release fires every barrel (one round per barrel's own ammo slot, per-barrel damage, BATTERY_STRUM_MS := 40 random release offset per barrel, reversal 0). If H0's report shows the volley already works per family, reduce to the seam + strum and say so. Extend tests/test_engine2_weapons.gd with volley coverage (rounds charged per barrel, damage per barrel, strum bound 0..40 ms). Report .agents/gen/slices/S4-weapon-batteries/S4-H2_report.md with measured numbers. Hard rules in the brief apply." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## S4-H3 — mandatory review (after H1, H2 report)

```bash
VAJB_WORKER_FILES="vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md" crush run "You are worker S4-H3, the mandatory reviewer of wave S4 (brief .agents/gen/slices/S4-weapon-batteries/S4_BRIEF.md; diff findings against docs/CONTRACTS.md §16/§13 and 09 §10/STATION_HUB §5.10, not against the brief). Re-measure everything yourself: re-run each builder probe byte-identically; verify the bulk transactions' rollback leaves the starting fit (byte-compare the fit dict), the strum bound, one round charged per barrel and per-barrel damage; verify the expander reaches every single-cell action and L78's precedence is unchanged; verify no fit shape, price, damage, cadence or ammo number moved and no frozen file moved (staging/verify_wave.py verify --baseline s4_start --forbidden vajb-orbit/project.godot,vajb-orbit/docs/gameplay/18_engine_spec.md --tests); run the gate twice. Tier findings HIGH/MED/LOW with file:line and measured evidence. Write .agents/gen/slices/S4-weapon-batteries/S4-H3_review.md, append LOW rows to .agents/gen/_state/LOW_BACKLOG.md (next free L numbers), update docs/CONTRACTS.md §9/§10 measured notes. Never fix. Bounded probes only." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```

## S4-H4 — fixer (only if H3 leaves HIGH or MED)

```bash
VAJB_WORKER_FILES="vajb-orbit/ui/station/outfitting_panel.gd,vajb-orbit/ui/station/outfitting_panel.tscn,vajb-orbit/autoload/player_profile.gd,vajb-orbit/game/weapons.gd,vajb-orbit/game/projectile.gd,vajb-orbit/tests/,docs/CONTRACTS.md" crush run "You are worker S4-H4, the fixer of wave S4 (brief .agents/gen/slices/S4-weapon-batteries/S4_BRIEF.md; review .agents/gen/slices/S4-weapon-batteries/S4-H3_review.md). Fix ONLY the HIGH and MED findings at their named file:line; adjust tests only where a fix changes what is proven. No LOW items, no refactors, no balance changes. Re-run the gate twice and report .agents/gen/slices/S4-weapon-batteries/S4-H4_report.md with a finding-by-finding disposition and the gate lines." -m deepseek/deepseek-v4-flash --cwd "$VAJB_WORKSPACE"
```
