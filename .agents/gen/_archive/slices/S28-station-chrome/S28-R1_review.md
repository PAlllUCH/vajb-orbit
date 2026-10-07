---
slice: S28
reviewer: S28-R1
verdict: passed-with-followups
gate: "1038/0 (R1 fresh-scratch re-run; B1 claimed 1038/0 twice)"
---

# S28-R1 review

Graded against `S28_BRIEF.md` §5 (UI_SPEC §8), `STATION_HUB.md` §16 P6 and
`UI_SPEC.md` §3.10 A5.1–A5.4 — never against B1's report. Every code site was
re-read from the working tree diff, the law sections re-read by range, and the
gate re-run once on fresh scratch (`XDG_DATA_HOME=$(mktemp -d)`,
`~/.local/bin/godot`, log `/tmp/s28_r1_gate.log`).

## Acceptance list

- **A1** — pass — every switch entry routes `_select_module` (`station.gd:179,451,455`), which calls `_clear_inspector()` before any branch (`station.gd:470-473`); a foreign pane's publish is dropped by the bound-pane guard (`station.gd:385,520-523`); the unhover-with-no-selection clear is the pre-existing empty-title path (`test_s11_inspector.gd:303-310`). New pins `test_s11_inspector.gd:313-330`.
- **A2** — pass — fold route chosen and disclosed: `turn_left`/`turn_right` ship **no** events (`project.godot:143-149`) and hide behind the ADVANCED toggle (`settings.gd:32-36,205-227`). Deconfliction is real: the shipped map binds Q once (`target_next`, `project.godot:103-108`) and E once (`mine`, `:63-68`); a commit steals the key from every other rebindable action and persists (`settings.gd:302-313`), and a persisted-profile duplicate is flagged in words, not colour (`settings.gd:336-350`, `settings_rebind_row.gd:86-88`). Pin `test_flight_feel_g1.gd:656-720`.
- **A3** — pass — `REFUSAL_COPY` reads the reason tokens into play copy (`launch_panel.gd:152-158,516-521`); the strip re-anchors to the arm state on every service report (`launch_panel.gd:504-507`) and the raw token never rides it; `Repairs.REASON_*` API untouched (no diff in `repairs` service files). Pins `test_p2b_services.gd:662-690`.
- **A4** — pass — one source: both readers take the catalogue hull row's `shield` (`launch_panel.gd:561`; `shipyard_panel.gd:90`, file untouched/read-only); winning figure **400** disclosed. Pin `test_p2b_services.gd:694-709`.
- **A5** — pass — one count-aware helper `StationCatalog.plural()` (`station_catalog.gd:377-382`), applied across the survivor panes (launch `:566-570,593`, exchange `:628,737-751`, refinery `:540-545,645-651,680-686`, auction `:631-634`); shipyard `%d ENGINES` correctly rides S29.
- **A6** — pass — the three dev-speak strings rewritten (`exchange_panel.tscn` footer, `launch_panel.gd:150`, `refinery_panel.tscn` "REFINE ALL"); "SHIP VIEWER ONLY" is the shipyard's own subtitle and "MINE BACK" was a 640 misread of the catalogue's "Mine Rack" — neither ships, both judged with cites. No test outside the moved suites pins any rewritten string (checked all of `tests/`).
- **A7** — pass — `game.gd:391-393`: the mount sits behind `OS.is_debug_build()`; pin `test_s13_devmenu.gd:333-346` asserts the gate from source.
- **A8** — pass — one font-measured reserve on the value label (`station.gd:277-289`) + right alignment (`station.tscn:150`); containers/A5.2-clean, no coordinates.
- **A9** — pass (S28's scope) — the inspector height floors (`station.gd:305-315`) and the LAUNCH hull plate floors (`launch_panel.gd:800-804`); the armory/shipyard fractionals live in S29's bodies and are disclosed as deferred, exactly per the scope guard.
- **A10** — pass — `_has_raw` (`exchange_panel.gd:504-517`) mirrors `Exchange._bulk_ids`' reach exactly (ore + components, `exchange.gd:374-385`); ammo is not in `ComponentCatalog` (`component_catalog.gd` ids are `comp_*` only), so an ammo-only hold stays disabled, same as `sell_all`. Pin `test_s5_ammo_cargo.gd:555-567`.
- **A11** — pass — a fresh selection steps 1 (`exchange_panel.gd:656-662`), the primary carries the quantity (`:630-634`); the owner reversal of the 05 §6 whole-stack default is named in the code comment. Pin `test_s5_ammo_cargo.gd:569-576`.
- **A12** — drift (judged, LOW) — the brief's wording names CAP; the pane has no per-item cap column (the quota pair rides the board, captioned QUOTA), so the header ships HELD / CR EACH / VALUE (`exchange_panel.gd:101-106,284-318`). B1 disclosed the judgement and the one-word reversal instead of inventing a column; tiered LOW for the owner tick, not a fixer pass.
- **A13** — pass — the tag reads the live listing count against `MODULE_SLOTS+STOCK_SLOTS` with the restock beside it (`auction_panel.gd:138-143,587-602`); both halves are reads (`auction.gd:309,316,420` only read), the no-write boot rule holds; format matches the brief's `5 OF 20 ON SHELF · NEXT RESTOCK 20:00` form (`auction.gd:141`). Pin `test_s3_auction.gd:884-911`.
- **A14** — pass — state-neutral body (`quit_confirm.tscn:7`); the dialog opens only from the top-level menu (`main_menu.gd:156,209`).
- **A15** — pass — `metal_light` → `text_dim` (`boot.gd:52-55`): one step up the neutral ramp per §1's hexes (`#3d4654` → `#6b7484`), no new hue. The brief's "(13 px StationCaption)" parenthetical matched no boot node; the splash line is MAIN_MENU_V2 §17.1's 2 px bar and took the brightening — disclosed, doc rows ticketed below.
- **A16** — pass — every survivor action button is the 360×56 Pressables token (the 88 px primaries retired: `exchange_panel.tscn`, `refinery_panel.tscn`, `launch_panel.tscn` + `launch_panel.gd:388-410`); clusters are P2 rows — `ActionsRow` HBox, 16 px gutter (`theme_override_constants/separation = 16`), primary rightmost (`SellButton`/`RefineButton`/`LaunchButton` last child), row sitting directly above the footer band in all three scenes' root order. Composition is containers + `custom_minimum_size` only — no coordinate anywhere in the diff (A5.2 clean). Bounty stays in DECK CONTROL's column (§8 names no bounty action; a fourth 360 plate overflows the pane — disclosed); auction rows are the data-row idiom with BUY as a row cell, no separate action button, and the 96×32 inline chip's ammo host is the armory (S29); rail 272×56 and the stepper ±/leave-dialog chrome keep their §8 exclusions. P3: the sliders were the one fallback-ring family and take the §6 1 px `accent_danger_bright` box in code (`settings.gd:443-472`), no `.tres` drift; no other focus override remains in `settings.tscn`.

## Findings

| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| F1 | LOW | `exchange_panel.gd:101-106` | A12 ships CR EACH where the acceptance list says CAP; the reasoning is code-derived and disclosed, but the header word is the owner's tick, not the worker's | → ticketed T-98 |
| F2 | LOW | `docs/design/MAIN_MENU_V2.md` §17.1, `MENU_FLOW.md` §5, `STATION_HUB.md` §5.4 | A14/A15/A3 leave three stale doc rows (the boot fill's `metal_light` row, the hangar-body quit copy, the "pane's own status line" wording); docs are untouchable this wave | → ticketed T-99 |
| F3 | NOTE | `game/station_catalog.gd:377-382` | Dispatch said this file was touched "for the shield source"; the diff shows the touch is the A5 `plural()` helper, and the shield cure lives in `launch_panel.gd:556-561` reading the pre-existing catalogue field. Both in the declared set (`game/`), neither an S29 body file — lawful either way; attribution corrected here | — |

No HIGH, no MED. Scope: every touched file sits in the declared set
(`ui/`, `game/`, `tests/`); no armory/fitting/shipyard/repairs body file moved;
docs carry no S28-attributed edit (§8/§16 were committed law before the wave;
the working-tree doc diffs are §10/§17, D18's). The untracked `staging/mockup`
and `staging/compare` files are D18's lane output, not B1's.

## Moved test rows (disclosure check)

B1 disclosed exactly what the diff carries: `test_p2b_services.gd:634,648,660,675`
(strip→status capture, A3) and `:686-701` (cluster row / 360×56 / rightmost, A16);
`test_s8_launch_ammo.gd:177-188,316-322` (plural grammar, A5);
`test_s11_inspector.gd:299` (module-0 re-anchor). Added rows: p2b ×1, s11 ×2,
s13 ×1, s3 ×1, s5 ×1, g1 ×1 = 7, matching 1031 → 1038. No undisclosed moved row.
`test_p1_repairs.gd:128,139` and `test_s5_ammo_cargo.gd:509` correctly did **not**
move (they pin the reason-token / `sell_all` APIs the brief keeps).

## Gate

```
XDG_DATA_HOME=$(mktemp -d) ~/.local/bin/godot --headless --path vajb-orbit \
  res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=1038 failed=0        # /tmp/s28_r1_gate.log:1337, fresh scratch, 2026-10-03
```

Matches B1's two fresh-scratch runs; only the benign ObjectDB/RID leak warnings
at exit. Zero failures — the wave's gate law holds.

## Verified fixes

First review — nothing to verify yet. F1/F2 are LOW and ride the backlog as
T-98/T-99; no fixer pass is owed (no HIGH or MED remains).
