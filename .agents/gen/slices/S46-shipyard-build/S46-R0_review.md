---
slice: S46
reviewer: S46-R0
verdict: passed-with-followups
gate: "1387/0 baseline → 1387/0 re-measured (the wave itself moved 1379 → 1387)"
---

# S46-R0 review

## Acceptance list
1 — pass — `_fill_build_view` (`shipyard_panel.gd:1693`): `SectionHulls` header → the P40
column band → nine rows in `buildable_hulls()` order → `SectionModules` → the staged
caption → slack; recipes read `Shipyard.buildable_hulls()`/`hull_recipe()` live, no
parallel table anywhere in the panel. Suite row 1 pins the captions, the band's five
cells and the nine-id order (`tests/test_s46_shipyard_build.gd:129`).

2 — pass — `_build_hull_row` (`:1776`): a `Button` 76 tall wearing C4 `ui_row_strip` with
`RowInner/RowBox/{TitleBox,MaterialsBox,LabourBox,State,BuildChip}` children; the meta is
the hangar's own `META_FORMAT` (`:210`, `CORVETTE CLASS · 1300 HULL · 13 SLOTS`); one
`<n>× <name>` run per material (`_make_build_run :1857`) with the family glyph 24 at its
own cut (`STRETCH_KEEP_ASPECT_CENTERED`) and `<held>/<needed>` read from `cargo_qty`
only; the labour line value + `CR LABOUR` caption; the chip is label + 1 px `metal_mid`
frame over `armory_chip_bg` (`_strip_chip_box :1927`). Suite rows 2–3, including the
empty-hold `MISSING 60× TUNGSTEN ORE`, the covered-bill `READY`, and the partial-stack
shortfall `MISSING 1× TUNGSTEN ORE`.

3 — pass — `_on_build_row_pressed` (`:2017`) emits `sheet_requested` with `{name, stats}`
carrying the full bill (`MATERIALS · …` / `LABOUR · 9 450 CR`); the sheet hides the
price/owned row when the keys are absent (`inspect_sheet.gd:139-148`), so N35 holds and
no CR figure leaks into the sheet. Suite row 4.

4 — pass — `_on_build_chip_pressed` (`:2040`) emits the S25 payload — title
`CONFIRM PURCHASE`, body A6's shipyard wording, `OK`/`CANCEL`, action `queue_build`; the
shell answers through `confirm_action` (`:2062`) which runs `Shipyard.queue_job`
unchanged (can still refuse); the refusal writes `BUILD_REFUSED` in danger. Suite row 5
pins the verbatim body string, the confirmed commit (materials + 9 450 left the account,
job queued, `QUEUED · SPEARHEAD`) and the still-possible refusal.

5 — pass — `BUILD_HULL_FORMAT`, `BUILD_MODULE_FORMAT` and `_ship_list_price` are deleted;
suite row 6 walks every `%BuildList` label: no `TO BUY`/`TO BUILD` anywhere, exactly
nine CR texts and each is `CR LABOUR` — the labour line is the only CR figure.

6 — pass — `git diff --stat` on `game/shipyard.gd` is empty (byte-identical to baseline);
the queue view's idle wording and the scrap row's `VANGUARD · <n> CR OF MATERIALS` keep
the S27 wordings (suite row 7 asserts both, rendered); the model-level law is re-proven
on a throwaway profile: commit at queue, one build at a time, refund in full on cancel,
one session then collect grants the hull.

7 — pass — `%PaneSubtitle` renders through `StationCaption` (`shipyard_panel.tscn:37-42`,
the S41 cure — already shipped); a strict `\bPORT\b|\bSTBD\b` grep over the panel's .gd
and .tscn finds nothing, so there is nothing to re-point. Suite row 8 pins the
subtitle's variation and wording.

8 — pass — `tests/test_s46_shipyard_build.gd`: 8 tests, at least one row per item 1–6
(AC2 carries two: the row anatomy and the chips) plus the T-175 row; scoped run 8/0.
Suite shaping follows the S45 lesson: one persistent mount, no `profile_changed`
connection, `refresh_profile(&"cargo")` rebuilds.

## Disclosed readings
- The shell confirm seam — pass — the emit shape is `contracts_panel.gd:426-435`'s
  verbatim; the shell opens the payload's own title/body/OK/CANCEL
  (`ui/screens/station.gd:566-575`), returns focus on both answers
  (`:592-601`, `_focus_active_panel()` runs after the close either way), and hands
  `confirm_action(action, id)` to the confirmed press only — the panel guards the
  action name (`:2062-2065`).
- The staged MODULES caption — pass — `Shipyard.buildable_modules()`/`module_recipe()`
  do carry live recipes (`game/shipyard.gd:210-218`, S27's landing) and the pin still
  ships the caption; the worker shipped caption-only (suite asserts no Button after it)
  and recorded the follow-up instead of over-delivering — the correct escalation-bucket
  behaviour.
- The confirm `<NAME>` disclosure (class word, not the catalogue ship name) — verified,
  not drift: A6's own worked example reads `…BUILD CORVETTE FOR 60× TUNGSTEN ORE…`, the
  value is a catalogue read (`ShipFit.HULLS`' `ship_class`, never hardcoded), and the
  row title stays the catalogue name (`Spearhead`). The report's reversal path stands.

## Findings
| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| F1 | LOW | `.agents/gen/slices/S46-shipyard-build/S46-V0_BRIEF.md` | The brief itself rides the working-tree diff (+8 lines: the 5-minute failsafe and the suite-shaping bullets under Hard constraints). The `VAJB_WORKER_FILES` fence bars the worker from this path, so the edit reads as the developer session's pre-dispatch amendment; owner confirms attribution at close-out. No code impact. | owner (attribution only; file a ticket only if attributed to the worker) |
| F2 | LOW | `shipyard_panel.gd` `_on_build_chip_pressed`/`confirm_action` | The confirm path's kind plumbing is forward-loaded: the row payload never carries `kind`, so `_pending_kind` always takes its `KIND_HULL` fallback and the emit hardcodes `KIND_HULL` too. Harmless this wave; the module wave must add `kind` to both the row payload and the emit, or module builds would queue as hulls. | the module-catalogue wave → ticketed as `T-200` |

No HIGH, no MED — no fixer pass. The staged-MODULES row is the pin's own staging, not a
finding; it lives in the report's follow-ups table.

## Diff scope
`git diff --name-only HEAD` names `shipyard_panel.gd` (in the file set) and the brief
(F1); untracked are the report, the suite and its `.uid` sidecar — the repo's own
convention (`tests/*.gd.uid` are tracked). `shipyard_panel.tscn` is in the brief's file
set but byte-unchanged (disclosed in the report: the shipped `BuildView`/
`BuildScroll`/`BuildList`/`BuildFooter` nodes carry the script-built sections, the S27
pattern) — an empty tscn diff trivially proves the queue/scrap/hangar rows and every
tscn-borne surface untouched, and the four mode plates' script block (S41's
`ChromeFamily.apply_chip(_mode_*)`, pre-wave `:276-286`) sits outside every hunk.

## Gate
- Baseline: 1387/0 (the dispatch's post-wave count; the wave itself moved 1379 → 1387,
  +8 = exactly the new suite's rows, no other suite moved).
- Re-measure: `python3 staging/gate.py --times 1` → `[GATE] run 1: ok - [SUMMARY]
  passed=1387 failed=0` — matches the baseline; no `SCRIPT ERROR` line in the log.
- Scoped negative control: `--suite=test_s46_shipyard_build` → `[SUMMARY] passed=8
  failed=0`, no SCRIPT ERROR.
- `staging/check_wiring.py` → 1582 hard refs, 989 advisory; every hard reference
  resolves (matches the report's cite).
- Static negative controls over the .gd diff: no `#rrggbb` literal (the only colour work
  is `Color.WHITE` alpha 0.72, mirroring `refinery_panel.gd:64`'s
  `ROW_ICON_IDLE_ALPHA` — the disclosed shared presentation value, not a new hex); no
  `position`/`offset`/anchor writes — containers + `custom_minimum_size` only
  (A5.2(i)); every catalogue/theme/chrome API used (`is_ore`, `entry_for_item`,
  `component`, `ChromeFamily.apply_row/apply_chip`, `UiCue.CLICK/CONFIRM/DENIED`)
  resolves.
