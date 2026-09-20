# WAVEBOARD — one-file agent state

**Updated: 2026-09-18 — engine wave 1 CLOSED and review-verified**
(`engine_wave1_review2_report.md`: 8/8 fixes verified, 40/40 probe checks,
boot gates exit 0, P1 suite 53/53, theme deterministic). Git baseline
`2a420a7` pushed to `origin/main`. Cleanup pass in progress per
`CLOSEOUT_PLAN.md`.

## Living contracts

- `docs/CONTRACTS.md` — pinned interfaces, **v0** (wave 1). Briefs say "code
  against CONTRACTS.md §n"; review waves own updating it.
- `staging/verify_wave.py` — mechanical wave gates: `snapshot` before a wave,
  `verify --baseline <tag> [--forbidden ...] [--expect-reports ...] [--tests]`
  after. Baselines live in `.agents/gen/_wave_state/`.
- Universal test gate: `res://tests/headless_runner.tscn` → `[SUMMARY]
  passed=53 failed=0` (exact command in CONTRACTS.md §9).

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
   denies any write outside that set (fail-open when unset, so sessions without
   it are unaffected; `.agents/` always allowed for reports). Known gap: bash
   writes bypass it — briefs forbid shell-based file edits.
3. **Detection (always applies)** — `staging/verify_wave.py` snapshot before /
   verify after the wave surfaces every touched file; `--forbidden` fails on
   protected files, `--expect-reports` fails on missing reports. Review workers
   also grep pinned signatures across all changed files to catch interface
   drift.

Dispatch template (worker waves, bash form):

```bash
VAJB_WORKER_FILES="vajb-orbit/game/hud.gd,vajb-orbit/ui/hud/hud.tscn" \
  crush run "<prompt>" -m deepseek/deepseek-v4-flash --cwd "G:/Mój dysk/Projekty/Vajb Orbit"
```

PowerShell form: `$env:VAJB_WORKER_FILES='...'; crush run "<prompt>" -m deepseek/deepseek-v4-flash --cwd "G:/Mój dysk/Projekty/Vajb Orbit"`

## In flight — none. Engine wave 1 closed.

Final table kept until the cleanup report is written:

| Worker | Scope | Report | Status |
|---|---|---|---|
| W0–W5 | doc amendments, fit, flight, mining, sector, HUD | `engine_wave1_w0..w5_report.md` | closed |
| W6/W8 | review + re-review | `engine_wave1_review_report.md`, `engine_wave1_review2_report.md` | **clean — no unresolved findings** |
| W7 | fixes (H1–H4, M1–M3) | `engine_wave1_w7_report.md` | closed |

## Review rules for the next waves

- Findings tiering: **HIGH blocks the wave; MED gets one fixer pass; LOW goes
  to a backlog file and rides with the next wave.** Max one fix+re-review
  cycle per wave unless HIGH findings remain.
- Every dispatch sets `VAJB_WORKER_FILES` (see Enforcement protocol below).
- Review waves diff against `docs/CONTRACTS.md`, not against the brief.


## Queued

1. **Cleanup pass** — executing per `CLOSEOUT_PLAN.md` Phase C: briefs + logs
   deleted (reports kept), MAIN_MENU_SPEC boot/loading absorbed into
   MAIN_MENU_V2 §17, AGENTS.md doc map updated. **Deferred items (owner inputs
   pending):** the five sealed-archive moves (need a `VAJB_ARCHIVE_OK=1`
   session — the seal blocked even a plan draft that named the path),
   `_mockup_station.tscn` deletion (gated on live S2 verification + wave-4
   review), MAIN_MENU_SPEC reference repointing (same sealed pass).
2. **Git** — done: baseline `2a420a7` on `origin/main`; repo-local identity
   `Kamil <PAlllUCH@users.noreply.github.com>` (override anytime with your own
   global identity). Commit at every wave boundary from now on.
3. **Slice-2 pre-brief** (combat) from ENGINE_SPEC §14 — brief + prompts with
   CONTRACTS inlined + `VAJB_WORKER_FILES` per worker.
4. **Batch-2 lane brief** (B2-1 hover, B2-2 backdrops, B2-3 minimap zoom) —
   the parallel lane for the next engine wave.

## Parked (independent)

- `TESTING_NOTES.md` batch-2: B2-1 hover look, B2-2 blurry backdrops, B2-3
  minimap zoom inversion + untested wave-1 items. Fold into the cleanup pass's
  TESTING_NOTES absorption when they land.
- Mockup scenes `_mockup_main_menu.tscn` / `_mockup_station.tscn` — deleted
  when their verification close-out lands (IMPLEMENTATION_PLAN §9.6).

## Done (for context)

- Phase C closed; Phase D menu/station M1+S1+S2 landed; P1 RPG economy
  code-complete (53-test headless suite); Phase F.1 icons shipped.
- Engine design closed: `ENGINE_SPEC.md` is the contract (7 locked decisions,
  brainstorm log at `.agents/gen/engine_brainstorm_notes.md`, status closed).
