# WAVEBOARD — one-file agent state

**Updated: 2026-09-21 (compression pass).** Full history of what every worker
did, with known errors and open findings, now lives in
`.agents/gen/MASTER_REPORT.md` — this board keeps only current state,
contracts, enforcement and the queue. Executed-wave reports, briefs and
evidence were moved to `.agents/gen/_archive/` (2026-09-21, reversible) —
citation paths of the form `.agents/gen/<report>.md` now resolve one level
deeper.

**Current state: UI chrome blocker open, one playtest session done.** Engine
waves closed as below (slice 0 + slice 2 review-verified clean; gate
`passed=219 failed=0`; last commit `c24ed3f`). A full-loop live playtest
(2026-09-21, godot-ai driven, owner crosschecking in `USER_NOTES.md`) verified
the whole menu → station → launch → space structure but found the `ui_slot_*`
chrome shipping as whole sheet cells (880×876 / 873×864), visually breaking
the shipyard, the launch panel and the in-flight HUD. **The UI chrome fix
wave goes before slice 2.5.** Findings + evidence:
`.agents/gen/playtest_fullloop_20260921.md`.

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

1. **UI chrome blocker wave (NEW 2026-09-21, before slice 2.5).** The
   2026-09-21 00:17 chrome re-cut shipped whole sheet cells for the
   `ui_slot_*` family: `ui_slot_weapon_*.png` 880×876 and `ui_slot_cargo_*.png`
   873×864, consumed at native size by shipyard Hardpoint01–07, the launch
   panel's CargoSlot01–05 and the HUD slot buttons — those panels overflow to
   ~4 800–6 200 px and their content lands off-screen ("only pistols" /
   "only crates"). Design lane: tight plate re-cut (`plates_cut.py` route 1)
   plus the standing R7/R8 scope (`ui_chrome_regression.md`). Coding lane:
   TextureButton guard (`ignore_texture_size` + `custom_minimum_size`) +
   stale-UID cleanup (`player_ship.tscn`, `game.tscn`) + one lint pass
   (D4/D5 in the playtest report). Dispatchers below were rewritten for this
   wave on 2026-09-21.
2. **Playtest session 2 (after #1).** Finish the loop legs session 1 could
   not reach: flight/fuel/reactor, mining, combat + countermeasures, death/
   respawn, dock-back economy, save/load, boot/loading logo, menu stutter
   (user note). Same crosscheck protocol against `USER_NOTES.md`.
3. **Slice-2.5 (Feel) — READY, first engine wave after #1/#2.** Motion blur + camera
   pull-back + dust streaks (§3.4), damage smoke/ripple/shatter (FX_SPEC §6),
   dash charge FX (FX_SPEC §7) — no new gameplay systems, every number already
   in §13. All signals exist: the hull publishes `velocity()`, the HUD has
   `set_speedometer`, the damage pipeline fires, `hit_marker`/
   `set_lock_progress` are wired. Snapshot + commit before the first dispatch.
4. **Owner spec pass (blocks nothing, unblocks tests):** the six
   `18_engine_spec.md` edits listed in MASTER_REPORT §3 item 1 (R-key +
   Z/X countermeasure rows, strike the refuel-for-CR wording, speed-table-v2 △
   tick, mine-alpha/kinetic-cadence rows, §6 fragment wording, rock-mass row,
   seeker-orbit and Q-marks readings).
5. **Graphics lane, rest:** 4K 2× backdrop cuts (R8) + tint-stencil import
   settings + `_48` zoom buttons; B2-1 hover direction waits for the owner's
   pick; owner-endorsed direction: evaluate asset-library background plates
   for the station panels (user note, review sheet still owner-gated);
   F10's credit-cache salvage glyph. Later: MMO/faction liveries, six boss
   hulls, `ship_vanguard_damaged` — i2i re-liveries gated on the owner's
   naming overhaul.
6. **Non-blocking spec/economy items:** F3's three-owner delivery-seam
   refactor, F7's six doc holes, F8's `cm_*` rows in `03`, the REPAIRS panel's
   free-service rows, HUD pool blocks into `hud.tscn` (with L19, L20, L21
   backlog items when their files next have an owner), the mining laser's
   5 E/s drain (L11/L26 — the next wave owning `mining_laser.gd` or
   `player_ship.gd`), the station-boot-gate profile write (L18).
7. **Cleanup pass (deferred items)** — the five sealed-archive moves (need a
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
