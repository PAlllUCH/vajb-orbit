---
slice: S34
worker: S34-B1
model: "hyper/deepseek-v4.1-flash"
status: informational
gate: "1121/0 → 1131/0"
---

# S34-B1 report

## Result
The refinery is now a queue: a confirmed batch is one job on one of 2..5 bought
slots, timed per resource on the wall clock, drawing from `refinery_input` and
settling into `refinery_output` (04 §7 R1-R8). Panel rewritten to P42/P43 (three
blocks, header SLOTS + UPGRADE, QUEUE N / QUEUE ALL / CANCEL / LOAD / COLLECT ALL).
Gate 1121/0 → 1131/0 (10 new rows); sealed row byte-identical.

## Acceptance list answers
1. R1 exact — `resource_seconds = clamp(round(ingot_value/10),10,60)` — `game/refinery.gd:109-115`; probe Iron 10, Gold 40, Copper 10, Krilium 60, unknown 10 — `tests/test_s34_refinery_queue.gd` `test_resource_seconds_is_the_r1_formula`.
2. queue() all-or-nothing — `game/refinery.gd:219-261` (verify→spend→take input→job; each failure restores); duration = conversions × RESOURCE_SECONDS set on promotion — `game/refinery.gd:411-417`; probe every refusal path leaves credits/input/jobs untouched, ready_at = now+R1 — `test_queue_is_all_or_nothing_on_every_failure_path`, `test_settle_completes_a_fake_ready_job`.
3. Slots — `BASE_SLOTS` 2 / `MAX_SLOTS` 5 / `SLOT_UPGRADE_COST` 3000 `game/refinery.gd:36-38`; `upgrade_slots` `:473-489`; probe ladder 2→3→5 then refusal at 5; 2 run / 1 pending then promotion on the new slot — `test_slot_ladder_two_to_five_at_three_thousand_each`, `test_slots_run_jobs_in_parallel_and_upgrade_promotes_pending`.
4. Inventory — `load_ore` `:420`, `collect_all` `:440`, `cancel` `:324`; probe refund + ore back to input (overflow to the hold when input is full), input over-cap refused whole, output overflow stays — `test_cancel_refunds_the_fee_and_returns_the_ore`, `test_input_and_output_caps_refuse_and_hold_overflow`.
5. settle() — `game/refinery.gd:365-418`; called on becoming visible `ui/station/refinery_panel.gd:250`, on a `&"refinery"` refresh `:177-187`, and on the 1 Hz tick `:263` (timer `:238`); probe fake-ready completes 1 job into output, a not-ready job settles nothing — `test_settle_completes_a_fake_ready_job`.
6. Panel — three blocks (`refinery_panel.tscn`: HoldTable | RefineBox | JobsTable); header SLOTS n/5 + UPGRADE `:328-334`; words QUEUE %d / QUEUE ALL / CANCEL / LOAD / COLLECT ALL `:71-75` + tscn; mm:ss `:1168`; empty-state `:637-651`; grep finds no hardcoded price/duration (only layout constants).
7. Gate green ×2 fresh scratch (1131/0 twice) + rows disclosed; sealed row diff-clean.

## Deviations from SLICE.md
- Job records carry two extra fields beyond the pinned `{id, mineral_id, conversions, ready_at, state}`: `fee` (what `cancel` refunds) and `settled` (whether the conversions reached `refinery_output`, so a done job whose output did not fit is distinguishable from one already moved). Reversal: recompute the fee at cancel from `fee_for(conversions, fee_multiplier(profile))` and drop `settled`.
- The five pinned profile keys are stored privately and reached through ten doors (`refinery_slots()` / `set_refinery_slots()`, …, the house getter/setter shape), per the brief's "behind public doors only"; the save keys keep the pinned names. Reversal: expose the vars directly.
- `tests/test_p1_refinery.gd`'s sealed row (`test_stacks_lists_only_convertible_minerals`) is byte-identical (`diff` clean) but its line number shifts 192 → 238, because the five restated rows above it are longer. Reversal: none; the row is untouched.
- The UPGRADE label renders the cost comma-grouped ("3,000 CR") to match STATION_HUB §21.3 verbatim, unlike the house `_format_int` space grouping. Reversal: call `_format_int`.
- `tests/probe_s23_r1.gd` was NOT changed: it calls only `fee_for` / `fee_multiplier` / `ORE_PER_INGOT`, none of which moved (the brief expected `refine`/`refine_all` calls there; there are none).
- `tests/test_s8_qa_fixes.gd` and `tests/test_s11_describe.gd` mount the panel and were kept green without edits: the stepper's default `_stepper` of 1 keeps the "1 CONVERSION" copy row green, and `_conversions_text` / `_inspect_row` / `STATUS_READY` / `INSPECT_TITLE_FORMAT` are retained verbatim.

## Evidence
- Gate baseline: `[SUMMARY] passed=1121 failed=0`.
- Gate after (three runs, each `XDG_DATA_HOME=$(mktemp -d)`): `[SUMMARY] passed=1131 failed=0` ×3.
- `probe_w3_lint`: `[W3-PASS] res://ui/station/refinery_panel.gd:778`, `player_profile.gd:2210`, `player_profile.gd:2795`; `[W3] passed=49 failed=7` (the 7 are pre-existing drift in files this wave never touched).
- `probe_s23_r1`: `refine list fee1=15 fee2=30` / `fitted mult=0.5 fee1=7 fee2=15 ore_per_ingot=3` (unchanged).
- Sealed row: `diff` of `git show HEAD:…test_p1_refinery.gd` lines 192-219 vs the shipped row → identical.

## Files touched
- `vajb-orbit/game/refinery.gd` — rewritten to the S34 surface (jobs, slots, caps, wall-clock settle).
- `vajb-orbit/autoload/player_profile.gd` — refinery keys, ten doors, save read/write, defaults.
- `vajb-orbit/ui/station/refinery_panel.gd` — rewritten to P42/P43 (three blocks, jobs, tick).
- `vajb-orbit/ui/station/refinery_panel.tscn` — the three-block layout with the header SLOTS/UPGRADE.
- `vajb-orbit/tests/test_p1_refinery.gd` — the five instant rows restated as queue/settle/collect.
- `vajb-orbit/tests/test_s23_content.gd` — the `u_refine` row moved to queue/settle/collect; borrow/restore covers the refinery keys.
- `vajb-orbit/tests/test_s34_refinery_queue.gd` — new suite (10 rows).
- `vajb-orbit/tests/probe_w3_lint.gd` — line pins updated (refinery 533→778, profile 576→2210, 735→2795).

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| `probe_w3_lint.gd`'s 7 stale line pins (settings_manager/audio_manager/station.gd) — pre-existing drift, not this wave | probe hygiene | `tests/probe_w3_lint.gd` |
| `u_refine` synergy (R3's reversal: module-granted slots) + 04 §6 tuning — brief §9 staged | design | next economy pass |
