---
slice: S45
worker: S45-V0
role: coder
status: ready
tier: paid
---

# S45-V0 — refinery LOAD ALL, the machine strip, the REFINE/CRAFT pair (P50/P51, R9–R11, P52's switch)

## Context (read in this order, by range)
1. `docs/gameplay/04_refinery.md` §9 (lines ~202–217, verbatim below) and §7
   (the job/slot/inventory model R1–R8 you build on; §7.3's panel contract).
2. `docs/design/STATION_HUB.md` §23.5 (lines ~2145–2150, verbatim below) and
   §21.3 P42 (the superseded readout), §5.6 (the status family), §5.7.
3. `docs/design/UI_SPEC.md` §3.10 A5.1–A5.5, §17 A4 door (7) + A6's slot
   wording, §16.1.
4. `vajb-orbit/ui/station/refinery_panel.gd` (1 247 lines — your main file;
   read whole), `refinery_panel.tscn`.
5. `vajb-orbit/game/refinery.gd` — the model you extend: `load_ore` (`:442`),
   `queue`/`queue_all`/`cancel`/`settle`/`collect_all` (`:241-493`),
   `upgrade_slots` (`:495`), `slots`/`jobs`/`running_count`/`pending_count`/
   `done_count` (`:178-239`), `INPUT_CAP := 60` (`:47`), `BASE_SLOTS 2`/
   `MAX_SLOTS 5`/`SLOT_UPGRADE_COST 3000` (`:43-45`).
6. The confirm seam contract (verbatim in the S43 brief §"The disclosed route
   reading"; `contracts_panel.gd:426-435` + `station.gd:568-599`) — the same
   seam, same reading as S43's (disclosed there; grade-identical here).

## Spec extract (the pinned law, verbatim)

**04 §9 R9** — "**`LOAD ALL`** transfers every hold ore stack into
`refinery_input` whole-stack at a time, up to R5's **60-unit** cap; overflow
stays in the hold (R8's idiom); no credits move (the `LOAD` law); status
`LOADED · <n> ORE`, refusal `INPUT FULL` (the pane's §5.6 family)."

**R10** — "**the machine read**: the pane models per-slot machine state for
the strip — `AVAILABLE` (no job), `RUNNING` with the job's `ready_at`
countdown, `DONE` (settled into `refinery_output`, awaiting collection), plus
a pending-queue count (R7's FIFO) — state is data the strip reads; the chips
never colour alone."

**R11** — "**the fourth plate**: the foot-band cluster gains `LOAD ALL`
beside `QUEUE`/`LOAD`/`COLLECT ALL` at 360×56 — T-181's words and band stand,
the cluster widens (STATION_HUB §23.5 P50's 1 408/1 765 arithmetic)."

**STATION_HUB §23.5 P50** — "the foot-band cluster (T-181's own 360×56 plates
and anchor) gains the fourth plate: **`QUEUE` (primary, rightmost) · `LOAD` ·
`LOAD ALL` · `COLLECT ALL`** — 4×360 + 3×16 = 1 408 ≤ 1 765 (§19.3's foot
band), seats with the hint cell intact. … **no credits move** (the `LOAD`
law); status `LOADED · <n> ORE` / refusal `INPUT FULL` (the §5.6 family).
T-181's closure stands — the words and the 360×56 band are unchanged; the
cluster widens. `QUEUE ALL` / `CANCEL` stay in the conversion column (T-181)."

**P51** — "the SLOTS readout (P42: `n/5 · UPGRADE (3,000 CR)`, header band)
becomes the **machine strip** in the same seat: `SLOTS 2/5` first, then **one
chip per owned slot** (A5.4 State chips — label + 1 px frame, **never colour
alone**): **`AVAILABLE`** (free slot) / **`RUNNING <mm:ss>`** (its job's
countdown, 04 §7 R6's 1 Hz tick) / **`DONE`** (finished, awaiting collection),
then a `+ <n> QUEUED` caption for pending jobs (04 §7 R7), the `UPGRADE
(3,000 CR)` `ActionInline` rightmost (its door is UI_SPEC §17's A4 list)."

**P52 (the switch only — the CRAFT list is S45-W0's)** — "the REFINERY pane
gains a **two-entry mode switch** in the header band (P32's idiom: a P2
`ActionInline` pair): **`REFINE` / `CRAFT`**, exactly one mode visible,
switching a pure visibility operation (A5.5)."

## Measured facts (cite, do not re-derive)
- The foot cluster is the three 360×56 plates `QUEUE`/`LOAD`/`COLLECT ALL`
  (`refinery_panel.gd:82-87` words; the D23-F14 seat); `QUEUE ALL`/`CANCEL`
  live in the conversion column (`:83-84`, T-181). Adding the fourth plate
  widens the cluster; the three keep their words and sizes.
- The header band's SLOTS readout: `SLOTS_FORMAT`/`UPGRADE_FORMAT`
  (`refinery_panel.gd:87-88`, refreshed at `:348-349`) — the strip replaces it
  in the same seat; the UPGRADE chip's existing press path (`upgrade_slots`)
  gains the A4 door (7) confirm in front of it: `CONFIRM PURCHASE` /
  `ARE YOU SURE YOU WANT TO BUY A REFINERY SLOT FOR 3 000 CREDITS?` (A6's
  worked example), the confirmed answer running `upgrade_slots` unchanged.
- The machine state's data source: `RefineryModule.jobs(profile)` (`{id,
  mineral_id, conversions, ready_at, state, fee, settled}`), `running_count`,
  `pending_count`, `done_count`, `input_total` — the strip reads these; it
  computes no state itself (R10).
- `load_ore(profile, mineral_id, units)` (`:442`) is R8's whole-stack door —
  LOAD ALL iterates the hold's ore stacks through it, stopping at `INPUT_CAP`
  60 (overflow stays in the hold); report `LOADED · <n> ORE` with `<n>` the
  units that moved; a hold with nothing to move reads `REFUSED · NOTHING TO
  LOAD`; an input already at cap reads `INPUT FULL`.
- The 1 Hz display tick idiom: `refinery_panel.gd:250` (the mm:ss countdown
  timer — the S38 pattern `world_clock.gd` consumers own).
- Gate baseline 1330/0 (2026-10-12).

## Task
Build R9's LOAD ALL (the model seam + the fourth plate), P51's machine strip
(per-slot chips + pending caption + the UPGRADE door), and P52's REFINE/CRAFT
mode switch with the CRAFT body as the `NOTHING TO CRAFT` empty state (the
list itself is S45-W0's). Add the suite `tests/test_s45_refinery.gd` pinning
your acceptance items.

## Acceptance list
1. `game/refinery.gd` gains the LOAD ALL seam (a `load_all(profile)` in the
   file's own transaction idiom — verify, iterate `load_ore` whole-stack,
   cap-aware, all-or-nothing not required across stacks; returns the loaded
   count and the reason). Its doc comment cites 04 §9 R9.
2. The foot cluster is `QUEUE` (primary, rightmost) · `LOAD` · `LOAD ALL` ·
   `COLLECT ALL`, four 360×56 plates, 16 px apart, the hint cell intact; the
   three existing plates keep their words and sizes; `QUEUE ALL`/`CANCEL`
   stay in the conversion column.
3. A LOAD ALL press moves whole ore stacks into `refinery_input` up to the 60
   cap, overflow stays in the hold, no credits move; status `LOADED · <n>
   ORE`; refusals `INPUT FULL` / nothing-to-load through §5.6's strip.
4. The machine strip sits in the P42 header seat: `SLOTS n/5` first, then one
   chip per owned slot — `AVAILABLE` / `RUNNING <mm:ss>` / `DONE` (the job's
   own state; the countdown ticks at 1 Hz) — then `+ <n> QUEUED`, then the
   `UPGRADE (3,000 CR)` `ActionInline` rightmost. Label + frame carry state
   (never colour alone).
5. The UPGRADE press opens the confirm dialog (title `CONFIRM PURCHASE`, body
   `ARE YOU SURE YOU WANT TO BUY A REFINERY SLOT FOR 3 000 CREDITS?`, OK/
   CANCEL) through the shell's confirm seam; OK runs `upgrade_slots` unchanged
   (which can still refuse); CANCEL returns focus; the strip still reports the
   refusal.
6. The header band carries the `REFINE` / `CRAFT` `ActionInline` pair (P32's
   idiom), exactly one mode visible, switching a pure visibility operation;
   the CRAFT body renders the `NOTHING TO CRAFT` caption (§19.4's idiom) and
   nothing else this wave; REFINE shows today's pane unchanged.
7. New suite `tests/test_s45_refinery.gd` pins items 1–6 (at least one row
   each; the countdown row may drive the tick directly); the report answers
   every item with a cite.

## Hard constraints
- **The 5-minute failsafe (the S43 process law):** every shell command you run must be
  bounded — run anything that can take longer than a minute as `timeout 280 <command>
  > /tmp/<log>.txt 2>&1; tail -n 40 /tmp/<log>.txt` and read the log; **never** wait on a
  background job, never use a background-run feature; poll the log file with short sleeps.
  If any single wait exceeds five minutes, stop, write the report with what is done, and
  say so.
- File set: `vajb-orbit/ui/station/refinery_panel.gd`,
  `vajb-orbit/ui/station/refinery_panel.tscn`, `vajb-orbit/game/refinery.gd`,
  `vajb-orbit/tests/test_s45_refinery.gd`. Do not touch
  `game/crafting_catalog.gd` (S45-W0 creates it), other panels, docs, the
  theme. `tests/test_p1_refinery.gd` and `tests/test_s34_refinery.gd` pin the
  model's rows — if your seam change goes red there, report the row and stop;
  the developer re-cuts.
- No new hex; no new tokens; A5.1–A5.5 composition; every run bounded;
  probes self-quit; never leave a command in the background.
- Gate: `python3 staging/gate.py --times 1` for your own check; record
  before/after `[SUMMARY]`.

## Output contract
- Report: `.agents/gen/slices/S45-refinery-craft/S45-V0_report.md` (≤120
  lines, from `_templates/REPORT.md`).
- Deliverable: the four files above.

## Paste block
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="vajb-orbit/ui/station/refinery_panel.gd,vajb-orbit/ui/station/refinery_panel.tscn,vajb-orbit/game/refinery.gd,vajb-orbit/tests/test_s45_refinery.gd" crush run "You are worker S45-V0. Read .agents/gen/slices/S45-refinery-craft/S45-V0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```
