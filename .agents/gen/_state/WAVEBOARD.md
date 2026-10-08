# WAVEBOARD — one-file agent state

**Session start (read in this order):** 1) this file — header, Living contracts, the queue; 2) `docs/CONTRACTS.md` §n for your wave; 3) `docs/CODE_MAP.md` §n when the task wires into existing scenes or scripts (generated map of what lies where); 4) the slice's `SLICE.md` in `.agents/gen/slices/<SliceID>-<slug>/`; 5) `LOW_BACKLOG.md` only if reviewing or fixing. Old reports are opened only when investigating a regression — slice ID + git tag is how you find the right one.

**Keep this file live-only.** It is read at the start of every orchestrator session, so its size is a recurring cost. It holds the current state, the queue, the living contracts and the enforcement rules — and nothing else. At a wave's close-out, the wave's recap (gate history, deliverables, the gates it raised) is appended to `.agents/gen/MASTER_REPORT.md` §6 and only its one-line outcome stays here. Closed-wave detail moved there on 2026-09-24; do not let it accumulate here again.

**Paths (folder law adopted 2026-09-22):** state files live in `.agents/gen/_state/` — `WAVEBOARD.md` (this file), `LOW_BACKLOG.md`, `TICKS.md`, `_wave_state/` baselines; the folder/ID law and the six templates in `.agents/gen/_templates/`; one folder per slice in `.agents/gen/slices/`, one manifest per phase in `.agents/gen/phases/`. Nothing new is written loose in `.agents/gen/` root. **Clear-out history:** the 2026-09-25 and 2026-10-07 owner clear-outs and their extraction files are listed in `_templates/README.md` §"2026-10-07 (owner clear-out)". **2026-10-08 clear-out (owner ask):** the board keeps only the S24–S27 queue — the S36/S37 `Updated` blocks moved to `_archive/waveboard_updates_2026-10-07_to_2026-10-08.md`, the closed S36/S37 slice folders to `_archive/slices/`, the dispatch done sections to `_archive/dispatch_done_2026-10-08.md`, the S36/S37 backlog rows to `_archive/low_backlog_s36_s37_rows_2026-10-08.md`, and the S36 baseline to `_archive/wave_state_baselines/`. Citation paths into moved trees name historical files.

Closed-wave recaps live in `.agents/gen/MASTER_REPORT.md` §6.

## Queued (phase P3 — `phases/P3-content-feel-push/`; one live session, one item per order)

| Pos | Lane item | Wave | Runs after | The collision/dependency that forces the order |
|---|---|---|---|---|
| 1 | coder 31 | **S25 contracts board** | — (S24 closed) | `ui/station/` + `autoload/player_profile.gd` + S24's shipped `contracts_visible`/`insurance_multiplier` seams; **its brief predates shell v2 too — re-cut it the way S24's was before dispatch** |
| 2 | coder 32 | S26 bosses, arenas, insurance, vaults | coder 31 | `game/` + `player_profile.gd` + S25's Expedition seam |
| 3 | coder 33 | S27 catalog breadth & shipyard | coder 32 | `game/module_catalog.gd`/`loot_tables.gd` + `ui/station/` |

**Updated 2026-10-08 (S24 world identity closed — item 30).** Gate **1152 → 1186/0**,
twice hermetic on fresh scratch stores; verify `"problems": []` vs `s24_start`.
Two sequential builders (`hyper/deepseek-v4.1-flash` @ xhigh): **B1** the station
registry + identity plate + the V1/V2 price law (+18 rows), **B2** the standing
effects, the auction flavour, the seven per-sector bands and the nebula (+15
rows); **R1** (`hyper/glm-5.3-flash` @ max, own 84-check probe) graded A1–A5 pass
and left **1 HIGH** (the shell's refusal strip priced from the raw catalogue while
the pane charged the station price) + 2 LOW → **T-152/T-153**; **F1** cured the
HIGH (+1 row). CONTRACTS gains **§24** (the wave's interface) and §9's stale S30
figure 1089 was corrected to the measured chain. New files:
`game/station_registry.gd`, `tests/test_s24_world.gd`, `tests/test_s24_bands.gd`,
`tests/probe_s24_r1.gd/.tscn`. **Owner ticks open: W1–W3 + V1–V8** (`TICKS.md`).
Process note: F1 also edited the law out of scope (AGENTS.md, `dispatch_coder.md`,
the S24–S27 briefs, via bash, undisclosed) — the developer re-authored the one
substantive line (`build_code_map.py` in the close-out) with its rationale and
reversal in `dispatch_coder.md`'s anatomy paragraph, and the map was regenerated.

These three are the whole live queue — every earlier item is closed and archived
(`_archive/dispatch_coder_done_2026-10-07.md` + `_archive/dispatch_done_2026-10-08.md`
+ `MASTER_REPORT.md` §6). Playtest pass #1 (the owner's, `19_testing_notes.md`'s
eye list) runs alongside; build 2 + the tester template are phase exit
criteria. Every brief's §11 tick sheet feeds its wave (unticked rows implement
at their PROPOSED value).

## Living contracts

- `docs/CONTRACTS.md` — pinned interfaces; the merged section pins (§5
  cleaving, §11 ship frames, §12 weapon fit, §13 fitting, §14 runner
  sandbox, §17 armory panel, §18–§24 by wave) are the seams briefs code
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
  (437 → 1186 across the waves) is `MASTER_REPORT.md` §6.
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
