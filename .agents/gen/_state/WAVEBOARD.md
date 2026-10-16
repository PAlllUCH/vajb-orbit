# WAVEBOARD — one-file agent state

**Session start (read in this order):** 1) this file — header, Living contracts, the queue; 2) `docs/CONTRACTS.md` §n for your wave; 3) `docs/CODE_MAP.md` §n when the task wires into existing scenes or scripts (generated map of what lies where); 4) the slice's `SLICE.md` in `.agents/gen/slices/<SliceID>-<slug>/`; 5) `LOW_BACKLOG.md` only if reviewing or fixing. Old reports are opened only when investigating a regression — slice ID + git tag is how you find the right one.

**Keep this file live-only.** It is read at the start of every orchestrator session, so its size is a recurring cost. It holds the current state, the queue, the living contracts and the enforcement rules — and nothing else. At a wave's close-out, the wave's recap (gate history, deliverables, the gates it raised) is appended to `.agents/gen/MASTER_REPORT.md` §6 and only its one-line outcome stays here. Closed-wave detail moved there on 2026-09-24; do not let it accumulate here again.

**Paths (folder law adopted 2026-09-22):** state files live in `.agents/gen/_state/` — `WAVEBOARD.md` (this file), `LOW_BACKLOG.md`, `TICKS.md`, `_wave_state/` baselines; the folder/ID law and the six templates in `.agents/gen/_templates/`; one folder per slice in `.agents/gen/slices/`, one manifest per phase in `.agents/gen/phases/`. Nothing new is written loose in `.agents/gen/` root. **Clear-out history:** the 2026-09-25 and 2026-10-07 owner clear-outs and their extraction files are listed in `_templates/README.md` §"2026-10-07 (owner clear-out)". **2026-10-08 clear-out (owner ask):** the board keeps only the S24–S27 queue — the S36/S37 `Updated` blocks moved to `_archive/waveboard_updates_2026-10-07_to_2026-10-08.md`, the closed S36/S37 slice folders to `_archive/slices/`, the dispatch done sections to `_archive/dispatch_done_2026-10-08.md`, the S36/S37 backlog rows to `_archive/low_backlog_s36_s37_rows_2026-10-08.md`, and the S36 baseline to `_archive/wave_state_baselines/`. Citation paths into moved trees name historical files. **2026-10-14 collapse (P4 code-lane close):** every closed-wave `Updated` block accumulated since (the S24–S41 era, the P3 close, the phase-prep and P4's D24 + S42–S49) was collapsed to the one-liners below — each block's full recap lives in `MASTER_REPORT.md` §6 under the same wave name, so nothing was lost.

Closed-wave recaps live in `.agents/gen/MASTER_REPORT.md` §6.

## Queued (phase P4 — `phases/P4-station-overhaul/`; one live session, one item per order)

The code queue is **empty** — P4's eight implementation waves are closed (S49,
the last, 2026-10-14; gate 1330 → **1422/0 ×2 byte-identical**, re-verified at
the review pass below; the done rows verbatim in
`_archive/dispatch_done_2026-10-14.md`). Before the next queued code:

- **Done 2026-10-14 (owner-directed, single session): the C-key cargo overlay
  rework** — implemented in the orchestrator session itself per the owner's
  "do the rework yourself" (no designer round, no slice; the planned
  `dispatch_designer.md` round is cancelled). UI_SPEC §18.2 **A10–A13** is the
  owning pin (refinery slot rows, armory categories, the DISPOSE chip, the
  sort cycle); gate 1422 → **1426/0 ×2**; uncommitted — the owner's reviewer
  pass precedes the wave-boundary commit.
- **Then the P4 exit pass** — playtest build 3 + the owner's eye over it
  (`phases/P4-station-overhaul/PHASE.md`'s exit criteria; T-179 and the S41
  chrome tokens re-present there). The build waits for the cargo redo so the
  owner tests the finished surface — the redo is in, the review is next.

**Updated 2026-10-14 (cargo overlay rework — owner-directed, the orchestrator
session itself; a rework, tracked like a wave).** The owner's S48 playtest
verdict ("the C-key Cargo doesnt look good... do the rework yourself") was
implemented docs-first in one session: UI_SPEC **§18.2** pins **A10–A13** (the
refinery slot row idiom, the armory MENU_TABS category strip, the DISPOSE chip
as the one transactional control through `PlayerProfile.remove_cargo`, the
CATEGORY/NAME/AMOUNT sort cycle); STATION_HUB §23.10 carries the tick row and
§23.11 rows 11–12 the supersessions (A8's read-only bar narrowed by the owner's
carve-out, A9's row grammar superseded, 02 §7's no-auto-jettison untouched).
The s48 suite re-pins the surface (13 → 17 rows); gate 1422 → **1426/0 ×2
byte-identical, zero SCRIPT ERROR**; `check_wiring.py` clean; CODE_MAP and the
doc indexes regenerated; CONTRACTS v0.61. **The owner's reviewer pass is the
owed eye** — the tree stays uncommitted until it lands. Full block:
`MASTER_REPORT.md` §6's "cargo overlay rework".

**Updated 2026-10-14 (P4 code-lane close — the developer session's review and
cleanup pass; housekeeping, not a wave).** Evaluation: the gate re-read
**1422/0 ×2 hermetic, byte-identical, zero `SCRIPT ERROR` lines** (S49's
close-out figure re-verified from scratch) and the game boots headless clean
(exit 0). Every wave's mandatory review closed with nothing left open above
LOW (S42's 2 MED, S43's 1, S44's 1, S45's 1 HIGH, S47's 1 MED all cured in
their fixer passes; S48's R0 clean; S49 left 3 LOW — one cured, two →
T-202). **The record gap found and backfilled (CONTRACTS v0.60):** the eight
close-outs refreshed this board, MASTER_REPORT §6 and the code map but
**skipped CONTRACTS §9/§10** — §9's Expected figure still read the S28-era
1202 and §10 stopped at v0.59. §9 now carries the S42–S49 chain block (1330 →
1422, +92 rows, the eight suites named) and §10 the v0.60 backfill;
record-only drift — every wave's gate pair ran and passed, no number or pin
moved. **Board cleanup per its own live-only law:** the closed-wave Updated
blocks collapsed to the one-liners below; `dispatch_coder.md` purged (items
46–53 → `_archive/dispatch_done_2026-10-14.md`, the stale S43 "queued" status
cured, the queue empty); LOW_BACKLOG's header next-free corrected (T-203); the
P4 manifest's slice boxes ticked. **Trash removed:** the regenerable
`__pycache__` bytecode caches under `staging/`, `.crush/hooks/` and the D21
archive slice. Full block: `MASTER_REPORT.md` §6's "P4 code-lane close".

**Updated 2026-10-16 (the cargo windows round — the owner's second pass; gate
held 1429/0 ×2 byte-identical, net 0 rows).** UI_SPEC §20.1 pins **A21** (the
armory's and launch's cargo surfaces render the C overlay's own window —
chrome, tab strip, category grouping, uncapped scroll; the A17 cap retires on
the station surfaces), **A21.1/A21.2** (the seats) and **A21.3** (the armory's
left column splits into LAYOUT/HOLD pages under the owner's "two tabs if
needed" authorization). The S50-A review dispatch found the two escapes
(fixed), the band's 108 px mis-seat (fixed) and the title-collapse defect
(the overlay's own title too — fixed). Resolution sweep: 16:9 = uniform scale;
the wide layouts (2016/2657/3373 logical) hold with no overflow. CONTRACTS
v0.64. **Same-day third instruction:** the A21.3 split and the armory's block
retire (the column restores to grid → CELL INFO → EQUIPPED); the shell gains
the global HOLD chip beneath INSPECT (A22) and the overlay becomes a moveable,
always-on-top window with a CLOSE chip (A23) — the S50-B review accepted the
resize re-fit, the stale-drag reset and the idiom flag, declined the sub-720
canvas on the measured stretch. Gate **1430/0 ×2**; CONTRACTS v0.65.
**Same-day fourth instruction:** the header's chips seat in a 2×2 grid
(TERMINAL | INSPECT over HOLD — A22.1) and the launch's embedded manifest
retires (A24 — every module reads the hold through HOLD or C over the one
moveable window; `cargo_summary`'s window half retired with it). Gate
**1429/0 ×2**; CONTRACTS v0.66.

**Updated 2026-10-15 (the owner's playtest pass — the ammunition rows, the
armory's cargo preview and the launch manifest; one session).** The owner's
first pass over the fixed surfaces raised three items, pinned docs-first as
UI_SPEC **§20 A18–A20** and cured the same session: **A18** the armory's
AMMUNITION rows are the shared menu's own full-width container rows (the
pinned 320×68 hand-placed card retired — `_position_card`'s coordinates were
the A5 composition law's own violation; the crushed nine-slice at 320 was the
"warped" the owner saw; the band seats HELD/STATE/COST; every cell name, word
and the danger frame stand); **A19** the armory's left column gains the CARGO
HOLD block (the overlay's title words + the capped summary rows — the owner
can now see his ammo in the armory); **A20** the LAUNCH manifest is the C
overlay's read-only instance (the faint plate strip retired, the banded rows
ride `%CargoList`). The slots law's and the read-only row grammar's single
home is the new `ui/station/cargo_summary.gd` — the overlay delegates (the
s48 seams stand; one label-set slip — a missing `ALL` key — caught by the
suite and cured in-session). Gate **1429/0 ×2 byte-identical, net 0 rows**
(the strip rows −2, the new pins +2); `check_wiring.py` clean (1628 hard
refs). Full block: `MASTER_REPORT.md` §6's "the playtest pass".

**Updated 2026-10-15 (T-203 closed — the pack icon masters regenerated bright;
the owner's three audit-round questions all answered).** The owner ruled
"Ok, regenerate" (the icons), "Keep for now" (the A17 6-row cap) and "keep"
(the audit tool). The round needed no corpus restore: the pack masters are
single unsuffixed files with no panel render behind them, so they regenerated
as fresh runs on **Qwen-Image 2.1** (the owner's model pick, 1K, native
transparency), lifted to ICONS_SPEC §10.2's brightness gates by the scripted
`staging/cut/lift_pack_icons.py` and centred to the 1.5 px law. Measured:
laser avg 90 / p90 154 (was 42/87), rocket 90/168 (was 42/81); the four SVG
packs were never dark and proton/flak follow their donors. Docs-first: ICONS
SPEC **§10** (the defect measured, the brightness law, the execution record);
ASSET_CATALOG regenerated; the pre-regeneration bytes backed up to
`_prekey_backup/pack_icons_2026-10-15/`. The audit sweep gained the rocket
pack in its mixed-hold fixture and the standalone run proved both icons
legible at the 40 px slot (21 shots, zero SCRIPT ERROR). Gate **1429/0 ×2
byte-identical** (asset-only round, no suite rows moved). Full block:
`MASTER_REPORT.md` §6's "pack icon regeneration".

**Updated 2026-10-15 (the owner's visual audit — one session: the cargo overlay
audit round, the container bounds, and the visual round).** The owner's verdict
on the rework ("shows ammo even if i have 0 ammo", "different categories have
different sizes", "containers expand/retract") drove a scripted visual audit
(`tools/audit_sweep.gd`, 21 full-res captures per run) whose findings were
pinned docs-first and cured in three commits: **9675aa1** (the overlay: A14
zero-hold ammo law, A15 one-geometry law, A16 measured title column — the
audit's invisible names, eight AMOUNT-0 ammo rows and per-tab resizing all
cured; gate 1426 → 1428/0 ×2), **2e915b4** (A17's bounded flight readout + the
OVERVIEW stack's 20 px slack; 1428 → 1429/0 ×2), and the visual round commit
(**V1–V4**: the HUD blocks on the nine-slice plates, the panes' header bands,
the AUCTION tail, the SETTINGS console; gate held 1429/0 ×2). UI_SPEC §18.3 +
§19 and STATION_HUB §23.11 rows 13–14 are the pins; CONTRACTS v0.62. The
audit's instrument ships in `tools/` (boot scene + sweep worker, runs
standalone, never touches the real save).

One-line outcomes, newest first (full blocks: `MASTER_REPORT.md` §6, same-named
entries):

- **The playtest pass** (2026-10-15, owner-directed single session) — the
  ammunition rows full-width (A18), the armory's CARGO HOLD block (A19), the
  launch manifest as the C overlay's read-only instance (A20); gate held
  **1429/0 ×2**, net 0 rows; `cargo_summary.gd` the shared grammar's home.

- **Pack icon regeneration** (2026-10-15, owner-directed single session) —
  T-203 closed: both pack masters regenerated on Qwen-Image 2.1 to ICONS_SPEC
  §10's brightness gates (42 → 90 avg); gate held 1429/0 ×2; no corpus restore
  needed.

- **Visual audit round** (2026-10-15, owner-directed single session) — the
  cargo overlay fixes (A14–A16), the container bounds (A17 + the OVERVIEW
  slack) and the visual round (V1–V4); gate 1426 → **1429/0 ×2**; uncommitted
  pending the owner's eye, then closed as the three commits above.

- **Cargo overlay rework** (2026-10-14, owner-directed single session) — the
  refinery/armory rework of the C-key overlay (A10–A13: slot rows, categories,
  DISPOSE, sort); gate 1422 → **1426/0 ×2**; uncommitted, awaiting the owner's
  review.
- **S49** (2026-10-14) — the A2 confirm doors on the untouched surfaces
  (auction hull + listing, insurance opt-in, vault rent); gate 1409 →
  **1422/0 ×2**; 2 LOW → T-202.
- **S48** (2026-10-13) — the C-key cargo overlay, both planes (one read-only
  scene, station layer-19 + flight layer-20); gate 1396 → **1409/0 ×2**; R0
  clean; 1 LOW → T-201.
- **S47** (2026-10-13) — the 3.0 s launch sequence + its two CC0 cues
  (AUDIO-4/5); gate 1387 → **1396/0 ×2**; T-174/T-185 closed.
- **S46** (2026-10-13) — the shipyard build view in the AUCTION house style;
  gate 1379 → **1387/0 ×2**; 1 LOW → T-200; the staged-MODULES question on
  TICKS.
- **S45** (2026-10-12) — refinery LOAD ALL + the machine strip + the CRAFT
  tab (two sequential builders); gate 1358 → **1379/0 ×2** (the runner
  frame-yield is the message-queue ceiling cure); 2 LOW → T-198/T-199.
- **S44** (2026-10-12) — the exchange bulk sell (CheckChip, MARK ALL/CLEAR,
  SELL MARKED); gate 1351 → **1358/0 ×2**; T-190 closed; 2 LOW → T-196/T-197.
- **S43** (2026-10-12) — the armory EQUIPPED list + its buy doors; gate 1341
  → **1351/0 ×2**; 1 LOW → T-194.
- **S42** (2026-10-12) — the OVERVIEW 3×3 nine-tile grid; gate 1330 →
  **1341/0 ×2**; T-184/T-187/T-189/T-162 closed; 3 LOW → T-191–T-193.
- **D24** (2026-10-12) — the station-overhaul design round: the owner's nine
  asks pinned across six docs, every value PROPOSED; gate unmoved 1330/0; 5
  LOW → T-186–T-190.
- **P3 close + phase-prep** (2026-10-12) — the owner's build-2 playtest ruled
  the ten ticks, P3 closed and P4 opened; `staging/gate.py` became the gate
  wrapper (T-183); playtest build 2 delivered (v0.4).
- **S41** (2026-10-11) — the composition pass (the D23 visual audit's 16
  findings); gate 1300 → **1330/0 ×2**; T-177 closed; 4 follow-ups →
  T-180–T-183.
- **S27** (2026-10-10) — catalog breadth + the shipyard; gate 1275 →
  **1300/0 ×2**; T-153 closed; T-178/T-179 filed.
- **S40** (2026-10-10) — the owner visibility review: the caption ink
  WCAG-fixed (241/607 below-AA → 34/610); gate 1267 → **1275/0 ×2**;
  T-171/T-172/T-173 closed; T-174/T-175/T-176/T-177 filed.
- **S39** (2026-10-10) — flight feel, hostile fire, visible cargo (the
  owner's playtest #2); gate 1258 → **1267/0 ×2**; T-164–T-170 closed.
- **S26** (2026-10-10) — bosses, arenas, insurance, vaults; gate 1237 →
  **1258/0 ×2**; T-161/T-162/T-163 filed.
- **S38 + the board-draws-no-rows fix** (2026-10-08/09) — the hub cold start
  + the countdown, then T-160's service-host fix; gate 1226 → **1237/0**;
  T-156/T-157 closed; T-158/T-159 filed.
- **S25** (2026-10-08) — the contracts board; gate 1202 → **1226/0 ×2**;
  T-138/T-152/T-154 closed; T-156/T-157 filed.
- **S28** (2026-10-08) — the universal cost law (SC(t), the fee door, the
  battery, the bloom); gate 1186 → **1202/0 ×2**; T-154/T-155 filed.
- **S24** (2026-10-08) — world identity (stations, standing, bands,
  nebula); gate 1152 → **1186/0 ×2**; T-152/T-153 filed.

## Living contracts

- `docs/CONTRACTS.md` — pinned interfaces; the merged section pins (§5
  cleaving, §11 ship frames, §12 weapon fit, §13 fitting, §14 runner
  sandbox, §17 armory panel, §18–§27 by wave) are the seams briefs code
  against; **§9 carries the live gate figure (live in CONTRACTS §9)** and
  §10 the changelog. Briefs say "code against CONTRACTS.md §n"; review
  waves own updating it.
- `docs/gameplay/18_engine_spec.md` — the engine contract. §2.1 carries
  owner rulings 8–26. **Owner-locked**: no worker may edit it; owed spec
  edits are the owner's (MASTER_REPORT §3 item 1).
- Universal test gate: run **`staging/gate.py --times 2`** — the pinned §9
  command on fresh scratch stores, `[SUMMARY] passed=<live count> failed=0`
  byte-identical across runs, **and a hard fail on any `SCRIPT ERROR` line**
  (T-183, closed 2026-10-12: an erroring row still prints `[PASS]`, so the
  wrapper is the only eye; CONTRACTS §9's seventh harness limit); §14's runner
  sandbox law and §9's measured block are the authority. Growth history
  (437 → 1422 across the waves) is `MASTER_REPORT.md` §6.
- `staging/verify_wave.py` — mechanical wave gates: `snapshot` before a
  wave, `verify --baseline <tag> [--forbidden ...] [--expect-reports ...]
  [--tests]` after. Baselines live in `.agents/gen/_state/_wave_state/`
  (the wave's brief names its own).
- **`AGENTS.md` §"Designer lane — the output format"** — the standing rule for
  how planning work is delivered: docs amended first, one brief, one prompts
  file, queued in this board and in the lane's dispatch file, handed over
  with the short paragraph template. Read it before planning or dispatching
  anything.
- **`AGENTS.md` §"Slice / folder law"** and `.agents/gen/_templates/README.md` —
  the IDs, the folders, the six templates and the brief/slice lifecycle. Read
  before opening a slice or writing any agent file.

## Enforcement protocol (how workers are held to CONTRACTS/WAVEBOARD)

Three layers, in order of reliability:

1. **Injection, not reading** — the orchestrator copies the relevant
   `CONTRACTS.md` section *into* each prompt (source of truth stays
   CONTRACTS.md). A worker never has to go find the contract, so it cannot
   skip it. Review waves diff their findings against CONTRACTS.md, not against
   the brief.
2. **Prevention hook** — `.crush/hooks/enforce_worker_files.py` (registered in
   workspace `crush.json` for `edit|write|multiedit`). The dispatch sets
   `VAJB_WORKER_FILES=<comma-separated rel paths, "dir/" allowed>` and the hook
   denies any write outside that set (fail-open when unset; `.agents/` always
   allowed for reports). Known gap: bash writes bypass it — briefs forbid
   shell-based file edits.
3. **Detection (always applies)** — `staging/verify_wave.py` snapshot before /
   verify after the wave surfaces every touched file; `--forbidden` fails on
   protected files, `--expect-reports` fails on missing reports. Review workers
   also grep pinned signatures across all changed files to catch interface
   drift.

Dispatch template (worker waves, bash form):

```bash
VAJB_WORKER_FILES="vajb-orbit/game/hud.gd,vajb-orbit/ui/hud/hud.tscn" \
  crush run "<prompt>" -m opencode-go/<model> --cwd "<project>"
```

PowerShell form: `$env:VAJB_WORKER_FILES='...'; crush run "<prompt>" -m opencode-go/<model> --cwd "<project>"`

## Review rules for the next waves

- Findings tiering: **HIGH blocks the wave; MED gets one fixer pass; LOW goes
  to a backlog file and rides with the next wave.** Max one fix+re-review
  cycle per wave unless HIGH findings remain.
- Every dispatch sets `VAJB_WORKER_FILES`.
- Review waves diff against `docs/CONTRACTS.md`, not against the brief.
- **Lesson of the last two waves:** workers each implement their slice
  correctly and leave the *seam between them* unwired (slice 0: the reactor
  chain never ticked; slice 2: no weapon damaged a real ship). Reviewers must
  probe at the seams by measurement, never by trusting reports — W8's method
  (re-run the reviewer's probe byte-identically; it caught the fixer once).
- Probe hygiene (L17): a probe that repoints `PlayerProfile.save_path` must
  stop/flush the 0.5 s debounce before restoring `save_path`.

## Closed

Wave closure history lives in `.agents/gen/MASTER_REPORT.md` §6 (moved there
on 2026-09-24 so this file stays the live state only). Git history carries the
version that was here before the move.
