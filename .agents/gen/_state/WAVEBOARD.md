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

- **In flight, designer lane (owner, 2026-10-14): the C-key cargo overlay's
  redesign.** S48's built overlay is being redone; that round owns its slice
  folder and `dispatch_designer.md`. Its implementation wave queues through
  the brief loop (docs-first five-piece) once the round closes.
- **Then the P4 exit pass** — playtest build 3 + the owner's eye over it
  (`phases/P4-station-overhaul/PHASE.md`'s exit criteria; T-179 and the S41
  chrome tokens re-present there). The build waits for the cargo redo so the
  owner tests the finished surface.

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

One-line outcomes, newest first (full blocks: `MASTER_REPORT.md` §6, same-named
entries):

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
