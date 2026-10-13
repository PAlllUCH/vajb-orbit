---
slice: S45
worker: S45-V0
model: hyper/glm-5.3-flash
status: actionable
gate: "1358/0 → 1369/0"
---

# S45-V0 report

## Result
R9's `LOAD ALL` (model seam + the fourth 360×56 foot plate), P51's machine strip
(SLOTS n/5, one A5.4 chip per owned slot, the `+ <n> QUEUED` caption, the UPGRADE
ActionInline), P52's REFINE/CRAFT mode pair with the `NOTHING TO CRAFT` body, and
the UPGRADE door through the S25 confirm seam, all behind `tests/test_s45_refinery.gd`
(11 rows). Gate: before `[SUMMARY] passed=1358 failed=0` (the dispatch's baseline; the
brief's 1330/0 was stale), after `[GATE] run 1: ok - [SUMMARY] passed=1369 failed=0`.
`staging/check_wiring.py`: every hard reference resolves. `tests/test_p1_refinery.gd`
and `tests/test_s34_refinery_queue.gd` stayed green inside the gate (no seam row moved).

## Acceptance list answers
1 — `load_all(profile)` in `game/refinery.gd:469-497` (doc comment cites 04 §9 R9):
catalogue-order iteration, each stack through `load_ore` whole or not at all, cap-stop,
overflow stays in the hold, no credits, returns `{ok, reason, loaded, input_total}`;
refusals `nothing_to_load` (REASON_NOTHING_TO_LOAD added at `:77`) / `input_full`.
2 — `refinery_panel.tscn:339-369`: child order CollectButton, LoadAllButton,
LoadButton, QueueButton (QUEUE primary rightmost, P50's right-to-left list), four
360×56 plates, separation 16, `%PaneFooter` intact; QUEUE ALL/CANCEL still under
`RefineBox/ActionGrid` (tscn :259-273).
3 — `_on_load_all_pressed` `refinery_panel.gd:1194-1215`: `LOADED · <n> ORE`
(`STATUS_LOADED_ALL :123`), `REFUSED · INPUT FULL` / `REFUSED · NOTHING TO LOAD`
(`:124-125`) through §5.6's strip; press row `tests/test_s45_refinery.gd:418-452`.
4 — `_refresh_slots`/`_build_strip`/`_make_strip_chip`/`_refresh_strip_countdowns`
(`refinery_panel.gd:442-528`): header seat order PaneIcon · TitleBox · ModeSwitch ·
PanelTag · SlotsLabel · SlotStrip · QueuedCaption · UpgradeButton (tscn :45-96);
chips read `RefineryModule.jobs/slots/pending_count` only (R10), label + 1 px
`metal_mid` frame over `armory_chip_bg`, never colour alone; countdown ticks in
place on the 1 Hz `_tick` (`:330-341`), pinned by `tests:210-309` (incl. the
chip-node-survives-the-tick row).
5 — `_on_upgrade_pressed` emits `confirm_requested` (`:1238-1248`, signal `:51`) with
A6's wording; shell `station.gd:568-599` answers `confirm_action` (`:1250`) →
`_run_upgrade` (`:1255-1276`) = the old `upgrade_slots` path unchanged, refusal
`REFUSED · NOT ENOUGH CREDITS · 3 000 NEEDED` intact; pinned by `tests:155-207`.
6 — `set_mode`/`_apply_mode` (`refinery_panel.gd:246-266`), P32's idiom verbatim
(96×32 toggle pair, C3 chrome, `armory_panel.tscn:50-70` shape); CRAFT body =
`CraftBody/CraftEmpty` `NOTHING TO CRAFT` and nothing else (tscn :305-317); REFINE
unchanged; pinned by `tests:312-365`.

## Deviations from SLICE.md
- **The gate's message-queue ceiling reshaped the suite (see Evidence):** the pane
  rows mount ONCE per suite and drive state through silent field writes + narrow
  `_refresh_slots`/`_settle`/`_tick` reads, with `profile_changed` deliberately
  disconnected. Every acceptance behaviour is still exercised through the real
  press/confirm paths; only the live signal-refresh path is left to s41/s8's suites
  (disclosed, bucket 1 — the alternative was a red gate).
- **UPGRADE restyled to the P51 wording:** dropped its `StationButton` plate for the
  C3 ActionInline chip, min 96×32 (`tscn:91-96`, `_apply_chrome :232-237`). Reversal:
  restore the plate.
- **CRAFT mode hides `ActionsRow` and swaps the footer hint** (`_apply_mode :256-266`):
  P52's own surface law ("foot band kept, no cluster; hint `EVERY INPUT IS CONSUMED ON
  CRAFT · THE FEE IS LABOUR`"); the CRAFT list itself stays S45-W0's. Reversal: keep
  the refine cluster visible under CRAFT.
- **LOAD ALL never disables** (unlike COLLECT ALL's empty-disable): the brief gives the
  press both refusals through the strip, so the §5.6 channel stays reachable. Reversal:
  disable on an empty hold.
- **Two CR groupings by pin:** the dialog body reads `3 000` (house `_format_int`, A6's
  worked example verbatim) while the header chip keeps `3,000 CR` (§21.3's pinned
  header wording, `_format_cost` untouched).
- **Chip assignment reading (R10, bucket 1):** running jobs claim chips first in list
  order, done jobs fill the rest, overflow done jobs stay only in the RIGHT job list
  (the model's `settle` frees a finished job's slot for promotion, so running+done can
  exceed the slot count only in that queue-heavy state). Reversal: done-first order.

## Evidence
- Before: `timeout 280 python3 staging/gate.py --times 1` → `[SUMMARY] passed=1358 failed=0`.
- After: same command → `[GATE] run 1: ok - [SUMMARY] passed=1369 failed=0` (exit 0).
- Solo suite: `-- --suite=test_s45_refinery` → `[SUMMARY] passed=11 failed=0`.
- **Systemic finding (the investigation this suite's shape buys):** with my first
  suite draft (10 mounts/frees) the gate died `engine exit code -6` in
  `test_ui_slot_layout._mount` — `Message queue out of memory`, then ~1.06 M
  "Object was deleted while awaiting a callback" lines. The runner
  (`tests/headless_runner.gd`) walks all suites inside `_ready` with no frame yield,
  so every suite's freed-node backlog piles onto the shared 32 MB message queue
  (`memory/limits/message_queue/max_size_mb`) and the run's ceiling now sits at
  **~3 refinery-panel mount+free cycles**: 3 bare cycles land (`1361/0`), 4 pass
  their rows and abort at exit (`1362/0`, exit 134), 5 abort mid-run. My suite's
  code changes are innocent: full gate with the panel/model changes applied and my
  suite removed → `1358/0` clean; model-only suite → `1364/0` clean.
- `timeout 120 python3 staging/check_wiring.py` → "1565 hard refs, 987 advisory refs;
  every hard reference resolves".

## Files touched
- `vajb-orbit/game/refinery.gd` — `load_all` seam + `REASON_NOTHING_TO_LOAD`.
- `vajb-orbit/ui/station/refinery_panel.gd` — LOAD ALL press, machine strip, mode
  switch, confirm seam, craft footer/hint swap.
- `vajb-orbit/ui/station/refinery_panel.tscn` — ModeSwitch pair, SlotStrip +
  QueuedCaption, restyled UpgradeButton, CraftBody, four-plate foot order.
- `vajb-orbit/tests/test_s45_refinery.gd` — the 11-row suite (new).

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| Gate message-queue ceiling: the runner yields no frame between suites, so each wave's suite churn accumulates toward the 32 MB cap; today's ceiling ≈ 3 refinery-panel mounts. Next suite-bearing wave (S45-W0) hits it. Cure candidates: one frame yield (or an explicit queue flush) per suite in `tests/headless_runner.gd`, or a documented bump of `memory/limits/message_queue/max_size_mb` in `project.godot` (owner-locked keys — developer's call). | ticket | `tests/headless_runner.gd` (outside my file set) |
