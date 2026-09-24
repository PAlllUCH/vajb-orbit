# WAVEBOARD — one-file agent state

**Session start (read in this order):** 1) this file — header, Living contracts, Queued; 2) `docs/CONTRACTS.md` §n for your wave; 3) the slice's `SLICE.md` in `.agents/gen/slices/<SliceID>-<slug>/`; 4) `LOW_BACKLOG.md` only if reviewing or fixing. Old reports are opened only when investigating a regression — slice ID + git tag is how you find the right one.

**Keep this file live-only.** It is read at the start of every orchestrator session, so its size is a recurring cost. It holds the current state, the queue, the living contracts and the enforcement rules — and nothing else. At a wave's close-out, the wave's recap (gate history, deliverables, the gates it raised) is appended to `.agents/gen/MASTER_REPORT.md` §6 and only its one-line outcome stays here. Closed-wave detail moved there on 2026-09-24; do not let it accumulate here again.

**Paths (folder law adopted 2026-09-22):** state files live in `.agents/gen/_state/` — `WAVEBOARD.md` (this file), `LOW_BACKLOG.md`, `_wave_state/` baselines; the folder/ID law and the six templates in `.agents/gen/_templates/`; one folder per slice in `.agents/gen/slices/`, one manifest per phase in `.agents/gen/phases/`. Nothing new is written loose in `.agents/gen/` root. **2026-09-22 purge:** the executed-wave reports, briefs and evidence were removed from `.agents/gen/` (recoverable from the system trash; the last git tree carrying them is `3f5688b`) — the historical record is `MASTER_REPORT.md` plus the newest session report, and older citations below name the purged paths.

**Updated: 2026-09-24 (**batch prepared end-to-end: the independent QA review triaged;
`.agents/gen/` cleanup executed; **both dispatch files rewritten clean with live handoff
blocks**; item 14 = **S8 READY** (§21 + v0.18 + 05 §9, incl. the owner's O1–O3);
item 15 = flight-feel with **numbers PROPOSED in §22 (v0.19) — waiting on ticks**;
designer item 13 = **D11 station scene READY** (ENVIRONMENT_SPEC §11, five-piece written,
A0 mockup-gate handoff live); designer items 9–12 await owner picks).** Waves of record: item 13 = S7 CLOSED gate 711 → **753/0** (0 HIGH / 0 MED /
5 LOW L163–L167); designer item 8 = D7 CLOSED gate 727/0. Both lanes idle until their next
dispatch. CONTRACTS §20 (S7), §21 (S8), §22 (item 15's proposals), §18 (D7) are the pins;
changelog **v0.19** (§22) is the newest row — close-outs take the next free rows
read at close-out (v0.20+; L167's lesson for LOW ids too). The QA input stays loose at
`slices/S7-affix-application/S7_QA_playtest_review_2026-09-24.md` (it is S8's brief input);
every other closed slice now holds only `SLICE.md` + `_archive/` (cleanup 2026-09-24).
This session's
end-to-end record — items 4–7, their numbers, the incidents and the open items — is
`.agents/gen/session_2026-09-22_items_4_to_7_report.md`; items 8–13 + D6/D7 + the QA pass
are `.agents/gen/session_2026-09-24_items_8_to_13_report.md`. Full history of what every worker
did, with known errors and open findings, now lives in
`.agents/gen/MASTER_REPORT.md` — this board keeps only current state,
contracts, enforcement and the queue. Executed-wave reports, briefs and
evidence were purged to the system trash (2026-09-22) and archived to the slices'
`_archive/` folders (2026-09-24) —
citation paths of the form `.agents/gen/<report>.md` name the purged files.

**Current state: thirteen coding waves closed (chrome, combat repair, weapon FX wiring, flight
feel & beam polish, slice 2.5 Feel, P2-A ship slot frames, Rock cleave, P2-B1 weapon fit,
P2-B proper fitting panel, **S2.6 truth-and-feel**, **S3 the item economy**,
**S4 weapon batteries**, **S5 playtest fixes**, **S6 travel**, **S7 affix application**; gate
`passed=578 failed=0` at S5, **`passed=608 failed=0`** after the D6 design wave,
**`passed=674 failed=0`** after S6, **`passed=753 failed=0`** after S7 (the 711 at S7's
`s7_start` snapshot = S6's 674 + D7's in-flight 37), hermetic). The queue of record is
`dispatch_coder.md`: items 4–13 are all DONE and **item 14 = S8 QA playtest fixes
(CONTRACTS §21) is READY 2026-09-24** — the independent reviewer's 2 HIGH / 6 MED +
copy/naming/warning bundle **plus the owner's same-day O1–O3** (FITTING drag, weapon
groups, ram strength — §21's O-table), input at
`slices/S7-affix-application/S7_QA_playtest_review_2026-09-24.md`, run order Q0 →
dispositions into §21 → Q1 → Q2 → R1 → F1 only on HIGH/MED. **Item 15 = the
flight-feel retune — NUMBERS PROPOSED in §22 (v0.19), waiting on the owner's ticks**
(O4/O5: T1 `COAST_TIME_MULT` 2.0→2.5, T2 new `ANGULAR_DAMP_MULT` 0.5, T3 new
`STRAFE_RATE_MULT` 0.75, T4 `LATERAL_DAMP` 1.0→0.6; any subset ticks → **S9**'s
five-piece is written from the ticked table). Beyond it: **slice 4's
remainder** — quadrants/directional armour (18 §4.5 + ruling 23, deferred from S6) and
bosses/arena hooks (14 §5, blocked on the P4 contract type and boss-hull art) — **not yet
briefed**. Designer queue: **item 13 = D11 station scene READY** (five-piece written,
ENVIRONMENT_SPEC §11 landed, A0 mockup-gate handoff live in `dispatch_designer.md`,
incl. the owner's `game/sector.gd` + `game/station_scene.gd` grant); items 9–12 await
their owner picks (briefs at dispatch-prep).
Owner gates:
the chrome art half, the **`18_engine_spec.md` §6/§13/§15 cleaving amendment** (owner-locked; §15
is the test checklist and now contradicts the shipped suite), the launch fit (**both symptoms
closed** — symptom 1 by P2-A, symptom 2 by P2-B1's `w_mining` row), four spec ticks, the §13
turn column, and the engine-bed / vignette-strength calls slice 2.5 raised.**

Closed-wave recaps (gate histories, per-wave deliverables and the older owner
gates they raised) live in `.agents/gen/MASTER_REPORT.md` §6 — moved there
2026-09-24 so this header stays the live state only.
## Living contracts

- `docs/CONTRACTS.md` — pinned interfaces; **§11 (P2 ship frames) landed by P2-A
  2026-09-21**, **§5's cleaving sentence merged by Rock cleave (v1.4, 2026-09-22)**, and
  **§12 (the weapon-fit pin) landed by P2-B1 and resolved at its close-out (v0.4,
  2026-09-22 — the MODULES row set is seven, `w_mining` included, and MED-1's shell price
  reads the module catalogue)**, and **§13 (the fitting pin) landed by P2-B proper and
  corrected at its close-out (v0.5/v0.6, 2026-09-22 — the composed `fit_module_at` /
  `clear_fit_slot` transactions, the six-row retirement table, save v5 and `resolved_fit`,
  the fit the launch would fly)**; the §10 changelog carries the v0.2, v1.4, v0.3, v0.4,
  v0.5 and v0.6 entries (plus v0.7.x for the item economy and v0.8.0 for the weapon
  batteries), and §9's gate figure is the measured **493**. Briefs say "code
  against CONTRACTS.md §n"; review waves own updating it.
- `docs/gameplay/18_engine_spec.md` — the engine contract. §2.1 carries owner
  rulings 8–26. **Owner-locked**: no worker may edit it; the six owed spec
  edits are the owner's (MASTER_REPORT §3 item 1).
- Universal test gate: `res://tests/headless_runner.tscn` → `[SUMMARY]
  passed=457 failed=0` **on any `user://`, including the owner's live one, twice,
  byte-identical, with the live account present and never written** (S2.6, 2026-09-22:
  CONTRACTS §14's runner sandbox — the gate had read 437/0 only on a fresh `user://`
  and 433/4 against the live save, L90/L93; **the scratch-`XDG_DATA_HOME` workaround
  is retired** — §9 of CONTRACTS carries the measured block). (exact command in
  CONTRACTS.md §9; grew 53 → 78 → 219 → 226
  with the UI-chrome wave's `test_ui_slot_layout.gd`, 236 with the combat repair wave's
  `test_engine_c3_flight_decay.gd` and `test_combat_repair_c5.gd`, 277 with the weapon FX
  wave's `test_weapon_fx_f{1,2,4}.gd` suites, 294 with the flight/beam wave's
  `test_flight_feel_g1.gd` and `test_flight_beam_g2.gd`, 311 with slice 2.5's S3 pass, and
  **372 with P2-A's suites** — `test_ship_grids.gd` (27), `test_p2a_profile_fits.gd` (11),
  `test_p2a_launch_fit.gd` (12), `test_p2a_ship_roster.gd` (4), `test_ui_slot_layout.gd`
  rewritten 7 → 12, `test_p2a_lint_shadow.gd` (2)), then 378 with Rock cleave's
  `test_engine2_cleaving.gd` 9 → 15 (the only suite whose count moved; the rock brief's
  311 was stale — its baseline measured 372 against a stashed tree), then **389 with P2-B1**
  (`test_p2b1_outfitting_panel.gd` 0 → 7, then 7 → 9 with F1's two guards; W1's profile
  refusals ride `test_p1_profile.gd`'s +47 assertions and the row count's 6 → 7 move rides
  F1's seventh row), then **437 with P2-B proper** (`test_p2b_retirement.gd` 13,
  `test_p2b_fitting_panel.gd` 18 → 20 with F1's two, `test_p2b_services.gd` 11 → 12 with F1's
  one; F1's profile-fallback tests ride the retirement suite, and F2 cured three pre-existing
  engine2 fixture assumptions to take the **live-profile** gate from 434/3 to 437/0 —
  that live-profile reading did **not** reproduce: 433/4 measured twice on
  2026-09-22 (L93; S2.6-R0/F10 confirms 433/4 on a byte-copy of the live profile)), and
  then **457 with S2.6** (`test_s2_6_gate_hygiene.gd` 3, `test_s2_6_burst.gd` 4,
  `test_s2_6_beam.gd` 4, `test_s2_6_flight.gd` 5, `test_s2_6_blur.gd` 2 — no existing
  count moved; the wave's own two yardstick rows live in `test_flight_beam_g2.gd` and
  `test_weapon_fx_f4.gd`, re-derived by the fixer pass).
- `staging/verify_wave.py` — mechanical wave gates: `snapshot` before a wave,
  `verify --baseline <tag> [--forbidden ...] [--expect-reports ...] [--tests]`
  after. Baselines live in `.agents/gen/_state/_wave_state/` (`wave1_closed`,
  `slice0_start`, `slice2_start`, `pipeline_v2_start`, `cleanup_delete_list`).
- **`AGENTS.md` §"Designer lane — the output format"** — the standing rule for
  how planning work is delivered: docs amended first, one brief, one prompts
  file, queued in this board and in `dispatch_coder.md`, handed over with the
  short paragraph template. Read it before planning or dispatching anything.
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
