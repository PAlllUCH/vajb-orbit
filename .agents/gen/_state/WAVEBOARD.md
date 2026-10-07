# WAVEBOARD — one-file agent state

**Session start (read in this order):** 1) this file — header, Living contracts, the queue; 2) `docs/CONTRACTS.md` §n for your wave; 3) `docs/CODE_MAP.md` §n when the task wires into existing scenes or scripts (generated map of what lies where); 4) the slice's `SLICE.md` in `.agents/gen/slices/<SliceID>-<slug>/`; 5) `LOW_BACKLOG.md` only if reviewing or fixing. Old reports are opened only when investigating a regression — slice ID + git tag is how you find the right one.

**Keep this file live-only.** It is read at the start of every orchestrator session, so its size is a recurring cost. It holds the current state, the queue, the living contracts and the enforcement rules — and nothing else. At a wave's close-out, the wave's recap (gate history, deliverables, the gates it raised) is appended to `.agents/gen/MASTER_REPORT.md` §6 and only its one-line outcome stays here. Closed-wave detail moved there on 2026-09-24; do not let it accumulate here again.

**Paths (folder law adopted 2026-09-22):** state files live in `.agents/gen/_state/` — `WAVEBOARD.md` (this file), `LOW_BACKLOG.md`, `_wave_state/` baselines; the folder/ID law and the six templates in `.agents/gen/_templates/`; one folder per slice in `.agents/gen/slices/`, one manifest per phase in `.agents/gen/phases/`. Nothing new is written loose in `.agents/gen/` root. **2026-09-25 clear-outs (owner asks):** every closed slice folder moved to the system trash (last git tree carrying them: `7a081ef`), old session reports live in `_state/_archive/`, and the two dispatch files were purged to live-items-only (2026-09-25 ter). **2026-10-07 clear-out (owner ask):** closed slice folders moved to `_archive/slices/` (kept, not deleted), the old Updated blocks to `_archive/waveboard_updates_2026-09-25_to_2026-10-06.md`, the dispatch files' done sections to `_archive/dispatch_*_done_2026-10-07.md`, CLOSED backlog rows to `_archive/low_backlog_closed_rows_2026-10-07.md`. Citation paths into moved trees name historical files.


**Updated 2026-10-07 (S36 closed; the owner prune stands):** the clear-out
record stands in the Paths paragraph above — the workspace keeps S36, S24,
S25, S26, S27; the retirements live in `_archive/`, TICKS is empty, next free
ticket **T-148**. **S36 closed 2026-10-07:** R1 blocked (1 HIGH/4 MED/4 LOW)
→ F1 executed the designer's fix list: the drawn-space margins cure + the
`⌊rect/2⌋` guard (86 degenerate plates → 0), the A4 reverts (REFINERY bars,
cluster chip, bay rows), the tooltip inset restored, and F1c fixed B1's
lrtb-order defect (designer-ratified, `UI_SPEC.md` §15.7). Census 13 rows;
gate **1151/0 ×2** fresh scratch; verify `"problems": []` vs `s36_start`;
wave-boundary commit landed. Tickets **T-144–T-147** ride for the fresh
design round. **Next: S24 world identity** (§Queued row 2).

Closed-wave recaps live in `.agents/gen/MASTER_REPORT.md` §6.

## Queued (phase P3 — `phases/P3-content-feel-push/`; one live session, one item per order)

| Pos | Lane item | Wave | Runs after | The collision/dependency that forces the order |
|---|---|---|---|---|
| 1 | coder 43 | **S36 the chrome re-skin** (**done 2026-10-07** — gate 1151/0 ×2, committed at the wave boundary; `slices/S36-chrome-reskin/`) | — | shares `vajb-orbit/ui` + `tests` with S24, so S24 waited |
| 2 | coder 30 | S24 world identity | S36's close-out | its five-piece predates shell v2 AND the 2026-10-05/06 rounds — the developer re-checks `slices/S24-world-identity/S24_BRIEF.md` against `UI_SPEC.md` §12–§15 + `STATION_HUB.md` §19–§21 and re-cuts the handoff before dispatch |
| 3 | coder 31 | S25 contracts board | coder 30 | `ui/station/` + `autoload/player_profile.gd` + S24's `contracts_visible` seam |
| 4 | coder 32 | S26 bosses, arenas, insurance, vaults | coder 31 | `game/` + `player_profile.gd` + S25's Expedition seam |
| 5 | coder 33 | S27 catalog breadth & shipyard | coder 32 | `game/module_catalog.gd`/`loot_tables.gd` + `ui/station/` |

Queue rows 1–25 of the old table are closed — archived
(`_archive/waveboard_updates_2026-09-25_to_2026-10-06.md` +
`MASTER_REPORT.md` §6). Playtest pass #1 (the owner's, `19_testing_notes.md`'s
eye list) runs alongside; build 2 + the tester template are phase exit
criteria. Every brief's §11 tick sheet feeds its wave (unticked rows implement
at their PROPOSED value).

## Living contracts

- `docs/CONTRACTS.md` — pinned interfaces; the merged section pins (§5
  cleaving, §11 ship frames, §12 weapon fit, §13 fitting, §14 runner
  sandbox, §17 armory panel, §18–§23 by wave) are the seams briefs code
  against; **§9 carries the live gate figure (live in CONTRACTS §9)** and
  §10 the changelog. Briefs say "code against CONTRACTS.md §n"; review
  waves own updating it.
- `docs/gameplay/18_engine_spec.md` — the engine contract. §2.1 carries
  owner rulings 8–26. **Owner-locked**: no worker may edit it; owed spec
  edits are the owner's (MASTER_REPORT §3 item 1).
- Universal test gate: `res://tests/headless_runner.tscn` → `[SUMMARY]
  passed=<live count> failed=0`, run **twice on fresh scratch stores**
  (`XDG_DATA_HOME=$(mktemp -d)`), byte-identical; CONTRACTS §14's runner
  sandbox law and §9's measured block are the authority. Growth history
  (437 → 895 across the waves) is `MASTER_REPORT.md` §6.
- `staging/verify_wave.py` — mechanical wave gates: `snapshot` before a
  wave, `verify --baseline <tag> [--forbidden ...] [--expect-reports ...]
  [--tests]` after. Baselines live in `.agents/gen/_state/_wave_state/`
  (e.g. `s16_start`; the wave's brief names its own).
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
