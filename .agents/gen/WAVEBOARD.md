# WAVEBOARD — one-file agent state

**Updated: 2026-09-21 — engine slices 0 (Physics & Fuel) and 2 (Fight) are
CLOSED and review-verified; slice 2.5 (Feel) is next** (owner rulings 8–26 in
`docs/gameplay/18_engine_spec.md` §2.1; root `.md` files folded into `docs/`,
only `AGENTS.md` stays at the root). Engine wave 1 CLOSED and
review-verified (`engine_wave1_review2_report.md`: 8/8 fixes verified,
40/40 probe checks, boot gates exit 0, P1 suite 53/53, theme deterministic).
Git baseline `2a420a7` pushed to `origin/main`. **Slice 0: M4 review found 1
HIGH + 6 MED, M5 fixed every code finding, M6 re-verified all of them clean;
the universal gate reads 78/78 with zero failures — wave report
`.agents/gen/slice0_report.md`, evidence chain `slice0_m0..m6_report.md`,
owner rulings in `slice0_owner_rulings.md`. **Slice 2: W6 review found 1 HIGH
(no weapon damaged a real ship) + 10 MED, W7 fixed F1/F2/F4, the closing pass W9
fixed the one MED the re-review found, and W8 verified all of it clean; the gate
reads 219/219 with zero failures — wave report `.agents/gen/slice2_report.md`,
evidence chain `slice2_w0..w9_report.md` + `slice2_review_report.md`, owner
rulings in `slice2_owner_rulings.md`.**

## Living contracts

- `docs/CONTRACTS.md` — pinned interfaces, **v1.1** (wave 1 + slice 0 + slice 2).
  Briefs say "code against CONTRACTS.md §n"; review waves own updating it.
- Universal test gate: `res://tests/headless_runner.tscn` → `[SUMMARY]
  passed=219 failed=0` (exact command in CONTRACTS.md §9; the suite grew 53 → 78
  with slice 0's two suites and 78 → 219 with slice 2's six).
- `docs/gameplay/18_engine_spec.md` — the engine contract (was the workspace
  root `ENGINE_SPEC.md`, moved 2026-09-20). §2.1 carries the 19 new owner
  rulings; slice 0 and slice 2 briefs code against it.
- `staging/verify_wave.py` — mechanical wave gates: `snapshot` before a wave,
  `verify --baseline <tag> [--forbidden ...] [--expect-reports ...] [--tests]`
  after. Baselines live in `.agents/gen/_wave_state/`.
- Universal test gate: `res://tests/headless_runner.tscn` → `[SUMMARY]
  passed=219 failed=0` (the figure above is superseded by this line; the count is
  the measured one).

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

## In flight — none. Engine wave 1, slice 0 and slice 2 are all closed.

Engine wave 1, final table kept until the cleanup report is written:

| Worker | Scope | Report | Status |
|---|---|---|---|
| W0–W5 | doc amendments, fit, flight, mining, sector, HUD | `engine_wave1_w0..w5_report.md` | closed |
| W6/W8 | review + re-review | `engine_wave1_review_report.md`, `engine_wave1_review2_report.md` | **clean — no unresolved findings** |
| W7 | fixes (H1–H4, M1–M3) | `engine_wave1_w7_report.md` | closed |

Engine slice 0 (Physics & Fuel), 2026-09-21:

| Worker | Scope | Report | Status |
|---|---|---|---|
| M0, M0b | doc check + the refuel free-services ruling | `slice0_m0_report.md`, `slice0_m0b_report.md` | closed |
| M1 | hull `RigidBody2D` + `impact.gd` | `slice0_m1_report.md` | closed (44/44 checks) |
| M2 | pools, reactor chain, rock body, cleaving | `slice0_m2_report.md` | closed (31/0 + 24/0, +25 tests) |
| M3 | refuel/recharge, save v3, HUD pools | `slice0_m3_report.md` | closed (26/0 + 23/0 + 14/0) |
| M4/M6 | review 1 HIGH + 6 MED + 18 LOW; re-review | `slice0_m4_report.md`, `slice0_m6_report.md` | **clean — every finding verified fixed** |
| M5 | F1–F5 fixes | `slice0_m5_report.md` | closed (gate 77/1 → 78/0) |

Engine slice 2 (Fight), 2026-09-21:

| Worker | Scope | Report | Status |
|---|---|---|---|
| W0, W0b | doc check + the NPC-count transcription | `slice2_w0_report.md`, `slice2_w0b_report.md` | closed |
| W1 | weapons + projectiles (+29 tests) | `slice2_w1_report.md` | closed (probe 95/0) |
| W2 | damage pipeline (+16 in `test_engine2_damage.gd`) | `slice2_w2_report.md` | closed |
| W3 | NPC registry/brain/ship (+28 tests) | `slice2_w3_report.md` | closed (probe 22/0) |
| W4 | loot tables (+13 tests) | `slice2_w4_report.md` | closed |
| W5 | HUD widgets + all the wiring (+32 tests) | `slice2_w5_report.md` | closed (probe 65/0) |
| W6/W8 | review 1 HIGH + 10 MED + 11 LOW; re-review | `slice2_review_report.md`, `slice2_w8_report.md` | **clean — every assigned fix verified** |
| W7 | F1 HIGH + F2 + F4 fixes (+17 tests) | `slice2_w7_report.md` | closed (probe 124/2 → 126/0) |
| W9 | the one MED the re-review found (idempotent ammo settle) | `slice2_w9_report.md` | closed (297 → 297, negative control) |
| batch-2 lane | B2-1/2/3 playtest + its doc close-out | `batch2_report.md`, `batch2_docs_report.md` | B2-3 fixed; B2-1/B2-2 measured and routed to the art lane |
| doc lanes | 06's stale hauls + the 11 §3 pointer | `slice2_lootdocs_report.md` | closed |

## Review rules for the next waves

- Findings tiering: **HIGH blocks the wave; MED gets one fixer pass; LOW goes
  to a backlog file and rides with the next wave.** Max one fix+re-review
  cycle per wave unless HIGH findings remain.
- Every dispatch sets `VAJB_WORKER_FILES` (see Enforcement protocol below).
- Review waves diff against `docs/CONTRACTS.md`, not against the brief.


## Queued

**Dispatch flow (owner ruling 2026-09-20):** the owner no longer pastes
worker prompts. The coding orchestrator receives `.agents/gen/dispatch_coder.md`
(it executes slice 0 → slice 2 → batch-2 with the briefs and prompts files
below); the graphics orchestrator receives `.agents/gen/dispatch_designer.md`
(ship rework → alien hulls → Phase G FX, owner-gated review sheets).

0. **Slice-0 (Physics & Fuel) — CLOSED 2026-09-21.** Report
   `.agents/gen/slice0_report.md`; dispatch + verify evidence in
   `.agents/gen/_dispatch/slice0_m*.sh|log` and `_slice0_verify.log`
   (`problems: []`, gate 78/0). **Three items carry forward into slice 2:**
   (a) the graphics lane still owes the `env/` family its path sweep — the
   live list is `.agents/gen/asset_path_fallout.md`, and until it lands the
   `game.tscn` boot gate cannot compile `game.gd` and a depleted Small rock's
   pickup burst stays unproven end to end (owner ruling: environment-deferred);
   (b) the REPAIRS panel still does not list the free refuel/recharge rows
   (`ui/station/repairs_panel.gd|.tscn` were in no slice-0 set) and the HUD's
   pool blocks are built in `hud.gd` rather than in `hud.tscn`;
   (c) `18_engine_spec.md` §11 still says `consume_fuel_cell` = C while the
   owner ruled cargo keeps C and the action ships on **R**.
2. **Slice-2 (Fight) — CLOSED 2026-09-21.** Report `.agents/gen/slice2_report.md`;
   dispatch + verify evidence in `.agents/gen/_dispatch/slice2_w*.sh|log` and
   `_slice2_verify.log` (`problems: []`, gate 219/0). **What carries forward:**
   (a) the spec is owner-locked and owes six edits — §11's `consume_fuel_cell` = C
   → R and the two `countermeasure_chaff`/`countermeasure_flare` rows (Z/X), the
   superseded refuel wording, the speed-table-v2 △ tick, and the mine's 180 alpha
   + the kinetics' 0.6 s cadence as their own rows (ruling R6);
   (b) the graphics lane owes the UI chrome re-cut (ruling R7) and 4K 2× backdrop
   cuts (R8) — `.agents/gen/ui_chrome_regression.md`;
   (c) W6's F3 (the item-5 delivery seam still has three owners), F7 (W3's six doc
   holes), F8 (`cm_*` have no `03` §3 row), F10 (a credit cache has no visual) and
   the slice-0 REPAIRS-panel rows are all open with owners and block nothing.
3. **Batch-2 lane — CLOSED 2026-09-21.** B2-3 (the minimap zoom inversion) was a
   real code defect and is fixed and measured in `ui/hud/hud.gd`; B2-1 (hover look)
   and B2-2 (soft backdrops) are art-side, measured, and routed to the graphics
   lane — reports `batch2_report.md` + `batch2_docs_report.md`, evidence
   `batch2_evidence/`, handover `.agents/gen/ui_chrome_regression.md`. B2-1's look
   direction and B2-2's display target are settled: 4K (ruling R8), art re-cut
   (R7).
4. **Slice-2.5 (Feel) — READY, the next engine wave.** Brief written after
   slice-2 reports landed: motion blur + camera pull-back + dust streaks (§3.4),
   damage smoke/ripple/shatter (FX_SPEC §6), dash charge FX (FX_SPEC §7) — no new
   gameplay systems, every number already in §13. All the signals it needs now
   exist: the hull publishes `velocity()`, the HUD has `set_speedometer`, the
   damage pipeline fires, and `hit_marker`/`set_lock_progress` are wired. Snapshot
   + commit before its first dispatch, as always.
5. **Graphics orchestrator lane (parallel, no coder)** — hand the designer
   agent `.agents/gen/dispatch_designer.md`: ship rework → alien hull sheets
   for all three families (swarmer first — slice-2 W3's visual pass gates on
   it; STYLE_BIBLE §2.5 + §9.1 alien style block) → Phase G FX sheets
   (FX_SPEC §7.2). Review sheets wait for owner approval before anything
   ships; slice-2 W3's behaviour probes never gate on art.
   **State 2026-09-21, night run** (`designer_phase_g_report.md`): the
   **swarmer sheet is done and in the game** (so W3's visual pass is unblocked
   on art), Sibelon and Apex hulls and seven Phase G FX are shipped and
   imported — the hulls rebuilt per cell after the owner caught panel-level
   keying eating one hull, the 2x2 grid clipping two others, and two sheets
   repeating the front where a rear belonged (order is law: render, find the
   objects, cut each one, key each one, trim; the duplicate-view check lives in
   `staging/phase_g/refit_panels.py`). `fx_shield_shatter` retired by owner
   ruling — `fx_shield_break` is the shield-shatter asset. The five human rework
   hulls were then approved by the owner ("look good, go ahead") and **the whole
   human roster was reworked the same way** — 14 hulls, the five core classes
   plus `ASSET_EXPANSION_SPEC.md` section 3 classes 7-15 — so 65 files shipped
   in total. Still on the old art: the MMO/faction liveries, the six boss hulls
   and `ship_vanguard_damaged`, all i2i re-liveries that wait on the owner's
   naming overhaul. Review pages: `staging/phase_g/_review/g_ships.jpg` (all 65),
   `g_roster.jpg`, `g_turret.jpg`, `g_alien2.jpg`, `g_back_fixed.jpg`,
   `g_fx.jpg`, `g_human_a/b.jpg`, `g_fighter.jpg`.
6. **Cleanup pass (deferred items)** — the five sealed-archive moves (need a
   `VAJB_ARCHIVE_OK=1` session), `_mockup_station.tscn` deletion (gated on
   live S2 verification + wave-4 review), MAIN_MENU_SPEC reference repointing
   (same sealed pass).

## Parked (independent)

- `docs/gameplay/19_testing_notes.md` (moved 2026-09-20) batch-2: B2-1 hover
  look, B2-2 blurry backdrops, B2-3 minimap zoom inversion + untested wave-1
  items. Fold into the cleanup pass's absorption when they land.
- Mockup scenes `_mockup_main_menu.tscn` / `_mockup_station.tscn` — deleted
  when their verification close-out lands (IMPLEMENTATION_PLAN §9.6).

## Done (for context)

- Phase C closed; Phase D menu/station M1+S1+S2 landed; P1 RPG economy
  code-complete (53-test headless suite); Phase F.1 icons shipped.
- Engine design closed: `docs/gameplay/18_engine_spec.md` is the contract
  (decisions 1–7 owner-locked 2026-09-18; rulings 8–26 owner-ruled
  2026-09-20, §2.1).
