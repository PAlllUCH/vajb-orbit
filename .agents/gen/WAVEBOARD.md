# WAVEBOARD — one-file agent state

**Updated: 2026-09-18.** Every agent (orchestrator or fresh session) reads this
file first; the goal is "resume from one file read". Update it at every wave
close, dispatch, and review cycle.

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

## In flight — engine wave 1 (owner-dispatched, other agent)

Order W0 → W1–W4 parallel → W5 → W6 → W7/W8 (max 3 fix cycles). Brief:
`.agents/gen/engine_wave1_task.md`; prompts: `.agents/gen/engine_wave1_prompts.md`;
spec: `ENGINE_SPEC.md` (§2 decisions, §13 calibration, §14 slices).

| Worker | Scope | Report | Status |
|---|---|---|---|
| W0 | doc amendments | `engine_wave1_w0_report.md` | report on disk — unverified |
| W1 | ShipFit/ShipStats | `engine_wave1_w1_report.md` | report on disk — unverified |
| W2 | flight + game.gd | `engine_wave1_w2_report.md` | report on disk — unverified |
| W3 | asteroids/mining/pickups | `engine_wave1_w3_report.md` | report on disk — unverified |
| W4 | sector/registry/station | `engine_wave1_w4_report.md` | report on disk — unverified |
| W5 | HUD pass | `engine_wave1_w5_report.md` | report on disk — unverified |
| W6 | mandatory review | `engine_wave1_review_report.md` | report on disk |
| W7/W8 | fix + re-review | `..._fix_report.md` / `..._review2_report.md` | **in flight** — W7 probe (`tools/_probe_w7_seams.gd`+`.tscn`) present 2026-09-18 |

Rule: nothing runs on this side while workers are in flight. When the owner
signals closure: read all reports → support review/fix loop if asked (owner
dispatches) → then cleanup + git baseline.

## Queued (do not start before wave 1 closes)

1. **Verify wave closure** — read W0–W8 reports; if the review loop is
   unfinished, provide further fix/re-review prompts (owner dispatches).
2. **Cleanup pass** — per `CLEANUP_PLAN.md` §4; owner ticks §3 dispositions and
   grants `VAJB_ARCHIVE_OK=1` for the reference audit; report →
   `.agents/gen/cleanup_pass_report.md`. Includes deleting executed briefs,
   probe logs, mockup scenes, `engine_wave1_task.md`/`_prompts.md`,
   `engine_brainstorm_notes.md` (reports stay).
3. **AGENTS.md wiring** (same pass as cleanup): doc map gains `docs/CONTRACTS.md`
   + WAVEBOARD entry; deferred from now to avoid conflicting with in-flight workers.
4. **Git baseline commit** — repo initialized 2026-09-18 (`main`, remote
   `github.com/PAlllUCH/vajb-orbit`, empty so far). Text-only `.gitignore` at
   workspace root (binaries ignored by extension, incl. `assets/` images and
   `asset-library/` packs; text like generation logs, `.import`, manifests stays
   tracked). First commit = wave-1-closed state; commit at every wave boundary
   thereafter. Owner sets `git config user.name/user.email` (currently unset)
   before the first commit. No push without explicit ask.

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
