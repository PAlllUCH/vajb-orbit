# P1r task — independent review of the P1 economy core

Worker: coder (reviewer). Do NOT edit any file. Do NOT use MCP tools. Do not
run the editor. Output is a findings report only.

## Your inputs

The specs, in this order:
- `docs/gameplay/01_economy_core.md`, `02_minerals.md`, `03_components.md`,
  `04_refinery.md`, `05_exchange.md` — the law for every number.
- `docs/gameplay/17_coder_handoff.md` — §3 persistence, §4 one clock, §5
  transaction law, §6 the test checklist.
- `docs/design/STATION_HUB.md` — §2 (rail), §3.1 (the measured grid every
  panel must reuse), §5.6 (refusal path), §5.7–§5.9 (the P1 amendment
  sections), §12.3/§12.4.
- `docs/design/STATION_SPEC.md` — the frozen PlayerProfile/StationCatalog
  contract. New APIs must be additive; the old ones unregressed.
- `docs/design/ICONS_SPEC.md` — §8.6 only (tints).

The code under review (all of it, read fully):
- `vajb-orbit/game/mineral_catalog.gd`, `component_catalog.gd`
- `vajb-orbit/game/exchange.gd`, `refinery.gd`, `repairs.gd`, `economy_log.gd`
- `vajb-orbit/autoload/world_clock.gd`, `autoload/player_profile.gd`
- `vajb-orbit/ui/station/refinery_panel.gd/.tscn`,
  `exchange_panel.gd/.tscn`, `repairs_panel.gd/.tscn`
- `vajb-orbit/ui/screens/station.gd` (the rail extension only)
- `vajb-orbit/game/game.gd` (the vitals dock wiring only)
- `vajb-orbit/tests/` (runner + suites)
- `vajb-orbit/ui/screens/station.tscn` may have been touched by the panel
  wave — check whether it should have been.

Worker briefs and reports in `.agents/gen/p1*_task.md` / `p1*_report.md` are
context, not truth; the docs are truth.

## What to check (be specific and exhaustive)

1. **Numbers:** every value in every catalogue, formula, fee, quota, tint,
   id and description matches the cited doc section. Reproduce the 05 §3
   table and both 05 §5 worked examples by hand from the shipped code; flag
   any mismatch with file:line.
2. **Transaction law (17 §5):** verify -> take -> pay -> emit -> log in
   `exchange.sell`, `refinery.refine`, `repairs.repair`; all-or-nothing on
   every failure path; no negative balances; no partial states.
3. **One clock:** no `Timer` anywhere for market/stock; band math only via
   `world_clock.gd`; the exchange evaluates at station entry and at each
   transaction.
4. **No UI math:** prices/fees in the panels come only from
   `Exchange` / `Refinery` / `Repairs` / catalogue data. Flag any literal
   price, fee, quota or baseline in UI code.
5. **Persistence:** `player_profile.gd` keeps the frozen API; v1 profiles
   migrate with defaults and no data loss; every 17 §3 key (plus `vitals`)
   round-trips; signal keys exactly `modules`/`fits`/`standing` (plus the
   original five); getters return copies.
6. **Panel contract:** `status_requested` / `refresh_profile` /
   `focus_primary` / optional `disarm`; rows reuse the measured grid
   (76 px rows, 130/110/160 columns, 360 px action column); no new theme
   items; no baked theme; no new measurements beyond the amendment text.
7. **Shell integration:** `station.gd` arrays and enum are consistent (7
   modules, correct order per §2), cycling/focus/beds arrays agree in length;
   `game.gd` seeds vitals safely and files a damage report at dock without
   changing routing.
8. **Tests:** do the suites actually assert the 17 §6 checklist items (05 §3
   table, 05 §5 examples, 04 iron case, persistence round-trip and v1
   migration)? Do they avoid touching the production save/log? Are there
   assertions that would pass against a broken implementation (assert the
   exact numbers, not "> 0")?
9. **Hygiene:** no `print` in production code, no dead code, no TODOs, no
   commented-out blocks, no edits to `addons/` or `project.godot`, no 07
   crafting code, typed GDScript, tabs, header comments cite docs.

## Output

Write `.agents/gen/p1r_report.md`:
- a findings table: `| # | severity (blocker/major/minor) | file:line | problem | suggested fix |`
- a section per finding with enough detail to act without re-reading the
  whole file, including the doc section it violates;
- a short "looks correct" list (the checks that passed) so the orchestrator
  knows the coverage;
- do not fix anything, do not edit code, do not write tests.

Under 200 lines.
