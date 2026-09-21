# WAVEBOARD — one-file agent state

**Updated: 2026-09-21 (compression pass).** Full history of what every worker
did, with known errors and open findings, now lives in
`.agents/gen/MASTER_REPORT.md` — this board keeps only current state,
contracts, enforcement and the queue.

**Current state: nothing in flight.** Engine wave 1 (fly-and-mine), engine
slice 0 (Physics & Fuel) and engine slice 2 (Fight) are **CLOSED and
review-verified clean**. Batch-2 (B2-3 fixed in code; B2-1/B2-2 measured and
routed to the art lane), the two doc lanes and the Phase G graphics lane (65
files shipped: swarmer + Sibelon + Apex hulls, 14 human hulls reworked, 7 FX)
are also closed. Universal test gate: **`passed=219 failed=0`, exit 0**. Last
commit `c24ed3f` closes slice 2. Next engine wave: **slice 2.5 (Feel), READY**
— snapshot + commit before its first dispatch.

## Living contracts

- `docs/CONTRACTS.md` — pinned interfaces, **v1.1** (wave 1 + slice 0 + slice 2).
  Briefs say "code against CONTRACTS.md §n"; review waves own updating it.
- `docs/gameplay/18_engine_spec.md` — the engine contract. §2.1 carries owner
  rulings 8–26. **Owner-locked**: no worker may edit it; the six owed spec
  edits are the owner's (MASTER_REPORT §3 item 1).
- Universal test gate: `res://tests/headless_runner.tscn` → `[SUMMARY]
  passed=219 failed=0` (exact command in CONTRACTS.md §9; grew 53 → 78 → 219).
- `staging/verify_wave.py` — mechanical wave gates: `snapshot` before a wave,
  `verify --baseline <tag> [--forbidden ...] [--expect-reports ...] [--tests]`
  after. Baselines live in `.agents/gen/_wave_state/` (`wave1_closed`,
  `slice0_start`, `slice2_start`, `pipeline_v2_start`, `cleanup_delete_list`).

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

## In flight — none.

## Queued

**Dispatch flow (owner ruling 2026-09-20):** the owner no longer pastes
worker prompts. The coding orchestrator receives `.agents/gen/dispatch_coder.md`
(it executes slice 0 → slice 2 → batch-2 with the briefs and prompts files);
the graphics orchestrator receives `.agents/gen/dispatch_designer.md`
(ship rework → alien hulls → Phase G FX, owner-gated review sheets). Both
lanes' queued items below are executed through those files.

1. **Slice-2.5 (Feel) — READY, the next engine wave.** Motion blur + camera
   pull-back + dust streaks (§3.4), damage smoke/ripple/shatter (FX_SPEC §6),
   dash charge FX (FX_SPEC §7) — no new gameplay systems, every number already
   in §13. All signals exist: the hull publishes `velocity()`, the HUD has
   `set_speedometer`, the damage pipeline fires, `hit_marker`/
   `set_lock_progress` are wired. Snapshot + commit before the first dispatch.
2. **Owner spec pass (blocks nothing, unblocks tests):** the six
   `18_engine_spec.md` edits listed in MASTER_REPORT §3 item 1 (R-key +
   Z/X countermeasure rows, strike the refuel-for-CR wording, speed-table-v2 △
   tick, mine-alpha/kinetic-cadence rows, §6 fragment wording, rock-mass row,
   seeker-orbit and Q-marks readings).
3. **Graphics lane, next pass:** the chrome re-cut (R7) + 4K 2× backdrop cuts
   (R8) + tint-stencil import settings + `_48` zoom buttons (recipe:
   `ui_chrome_regression.md`); B2-1 hover direction waits for the owner's pick;
   F10's credit-cache salvage glyph. Later: MMO/faction liveries, six boss
   hulls, `ship_vanguard_damaged` — i2i re-liveries gated on the owner's
   naming overhaul.
4. **Non-blocking spec/economy items:** F3's three-owner delivery-seam
   refactor, F7's six doc holes, F8's `cm_*` rows in `03`, the REPAIRS panel's
   free-service rows, HUD pool blocks into `hud.tscn` (with L19, L20, L21
   backlog items when their files next have an owner), the mining laser's
   5 E/s drain (L11/L26 — the next wave owning `mining_laser.gd` or
   `player_ship.gd`), the station-boot-gate profile write (L18).
5. **Cleanup pass (deferred items)** — the five sealed-archive moves (need a
   `VAJB_ARCHIVE_OK=1` session), `_mockup_station.tscn` deletion (gated on
   live S2 verification + wave-4 review), MAIN_MENU_SPEC reference repointing
   (see `docs/design/CLOSEOUT_PLAN.md` / `CLEANUP_PLAN.md`).

## Parked (independent)

- Mockup scenes `_mockup_main_menu.tscn` / `_mockup_station.tscn` — deleted
  when their verification close-out lands (IMPLEMENTATION_PLAN §9.6).
- `docs/gameplay/19_testing_notes.md` batch-2 items B2-1/B2-2 — annotated;
  land with the graphics lane's pass.

## Closed (details in MASTER_REPORT.md)

- **Engine wave 1** (fly-and-mine): W0–W5 built, W6/W8 reviewed clean
  (8/8 fixes, 40/40 probe checks), W7 fixed H1–H4 + M1–M3. Baseline `2a420a7`
  on `origin/main`.
- **Engine slice 0** (Physics & Fuel, 2026-09-21, gate 78/0): M0→M6. Hull on
  RigidBody2D, reactor chain, cleaving, free refuel, save v3. Review 1 HIGH +
  6 MED, all fixed and re-verified. Rulings R1–R4.
- **Engine slice 2** (Fight, 2026-09-21, gate 219/0): W0→W9. Weapons,
  projectiles, damage, NPCs, loot, HUD widgets, countermeasures Z/X, death →
  respawn. Review 1 HIGH + 10 MED; the HIGH (no weapon damaged a real ship)
  fixed by W7's `_sink_for`; W9 closed W8's R1 double-charge with a negative
  control. Rulings R5–R8.
- **Batch-2 lane:** B2-3 minimap zoom fixed; B2-1/B2-2 art-side, measured,
  routed. **Doc lanes:** 06 figures + 11 §3 pointer (F9/F11); B2 doc close-out.
- **Graphics lane, Phase G:** 65 files shipped (alien + 14 human hulls, 7 FX);
  `fx_shield_shatter` retired by owner ruling; `asset_path_fallout.md` empty
  (181 literals, 0 unresolvable).
- **Phases C, D, P1, F.1/F.2** — earlier, all closed (AGENTS.md has the state).
