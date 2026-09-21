# WAVEBOARD — one-file agent state

**Updated: 2026-09-21 (compression pass).** Full history of what every worker
did, with known errors and open findings, now lives in
`.agents/gen/MASTER_REPORT.md` — this board keeps only current state,
contracts, enforcement and the queue. Executed-wave reports, briefs and
evidence were moved to `.agents/gen/_archive/` (2026-09-21, reversible) —
citation paths of the form `.agents/gen/<report>.md` now resolve one level
deeper.

**Current state: two coding waves closed, the combat repair measured and fixed; the
chrome art half and the launch fit wait on the owner.** Engine waves closed as below
(slice 0 + slice 2 review-verified clean; gate `passed=236 failed=0`). A full-loop live
playtest (2026-09-21, godot-ai driven) verified the whole menu → station → launch →
space structure but found the `ui_slot_*` chrome shipping as whole sheet cells
(880×876 / 873×864). The **UI-chrome code lane is Done** (D3 guard, D4 stale UIDs, D5
lint, D6 docs; reports `.agents/gen/ui_chrome_w{1..6}_report.md`; no HIGH, two MED
fixed, ten LOW; measured: shipyard strip 6184 → 360 px, launch panel 4781 → 952 px
with the oversized art still on disk, gate 219 → 226). **Its art half is owner-gated**:
the graphics lane measured that the shipped alpha holds only the silhouette (the paid
matte keyed the plate out), so no crop recovers it — the pre-redesign cells came back
from Godot's import cache and await approval on
`staging/phase_f/_preview/review_slots.png`. The **combat/collision repair wave is Done**
(reports `.agents/gen/combat_repair_{c1,c2,c3,c5,c6,c7,t1}_report.md`; reviewer verdict
no HIGH, two MED — one an orchestrator record error, one the contract's own stale pins —
both fixed). Measured and fixed: the rock's `collision_mask` 0 → 2 (the pair solved as
immovable; a ram now hands the rock 72.821 u/s and 20.323 u), the rock's missing ram
sink (rides the shipped `GUN_CHIP_RATE` 0.10, no new constant), plasma's +25 % bonus
through a live shield (`NpcShip.shield_up()`), the mine's borrowed kinetic cadence, and
the owner-ruled drag retune (nine `coast_time` rows ×0.50: Vanguard t10 1.890 → 0.945 s,
carry 430.32 → 216.85 u, §13 tick pending). **Two owner gates stay open:** the launch fit
(the briefing reports five weapons / 1500 rounds while the ship mounts `[w_laser]` and no
mining laser — the measured root cause of "shooting is not working" and "cannot shoot
asteroids") and the §13 `coast_time` table. Evidence:
`.agents/gen/owner_playtest_findings_20260921.md`, `.agents/gen/playtest_fullloop_20260921.md`.

## Living contracts

- `docs/CONTRACTS.md` — pinned interfaces, **v1.1** (wave 1 + slice 0 + slice 2).
  Briefs say "code against CONTRACTS.md §n"; review waves own updating it.
- `docs/gameplay/18_engine_spec.md` — the engine contract. §2.1 carries owner
  rulings 8–26. **Owner-locked**: no worker may edit it; the six owed spec
  edits are the owner's (MASTER_REPORT §3 item 1).
- Universal test gate: `res://tests/headless_runner.tscn` → `[SUMMARY]
  passed=236 failed=0` (exact command in CONTRACTS.md §9; grew 53 → 78 → 219 → 226
  with the UI-chrome wave's `test_ui_slot_layout.gd`, then 236 with the combat repair
  wave's `test_engine_c3_flight_decay.gd` and `test_combat_repair_c5.gd`).
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
   plus the standing R7/R8 scope (`ui_chrome_regression.md`). **Designer
   finding (2026-09-21, after task): the keying cache holds 235 more orphans**
   (button plates `@2x` 560×112, bezel, panel frame, bar caps, logo, backdrop
   plate) — R7/R8 are recoverable the free way from the cache, which retires
   `plates_cut.py`'s "needs regeneration, $0.05" note; regenerate only what
   the cache cannot cover. Also: `apply_import_settings.py` has **no `--only`**
   and wants to rewrite 1080 of 1620 `.import` files (the R8 tint-stencil
   defect) — it stays out of every batch until the coder lane adds the scoped
   flag. Coding lane: TextureButton guard (`ignore_texture_size` +
   `custom_minimum_size`) + stale-UID cleanup (`player_ship.tscn`,
   `game.tscn`) + one lint pass (D4/D5 in the playtest report) — **DONE
   2026-09-21** (brief `ui_chrome_wave_task.md`, prompts `ui_chrome_wave_prompts.md`,
   reports `.agents/gen/ui_chrome_w{1..6}_report.md`, gate 226/0, six worker
   reports verified by W5 with no HIGH). The art half stays owner-gated on the
   slot review sheet, and the coder lane owes the graphics lane one small
   tooling fix: an `--only` scope for `staging/phase_f/apply_import_settings.py`
   before any batch may use it.
2. **Playtest session 2 — now the head of the queue.** Finish the loop legs
   session 1 could not reach: flight/fuel/reactor, mining, combat +
   countermeasures, death/respawn, dock-back economy, save/load, boot/loading
   logo, menu stutter (user note), and re-test the repaired rock ram, the drag
   retune and the launch fit (the owner deferred that decision to this
   session). Same crosscheck protocol; the notes file moved out of the root —
   read `TO_REVIEW/` and `USER_NOTES.md` at HEAD if the root copy is absent.
3. **Combat / collision repair wave — DONE 2026-09-21** (brief
   `combat_repair_wave_task.md`, prompts `combat_repair_wave_prompts.md`, reports
   `combat_repair_{c1,c2,c3,c5,c6,c7,t1}_report.md`, gate 226 → 236). C1 proved the
   rock's `collision_mask = 0` made the physics pair solve as immovable and that the
   40 u/s floor was not the cause; C2 overturned the wave's own premise (weapons
   already chip rocks at `GUN_CHIP_RATE` 0.10) and found the real cause of the owner's
   report — the launch fit — plus plasma's shield bonus and the mine's borrowed
   cadence; C3 measured the decay and located it in the §13 `coast_time` row, not the
   `DRAG`/`ACCELERATION` pair the brief assumed. C5 fixed four defects and applied the
   owner's retune; C6 reviewed with no HIGH; C7 corrected the contract's own stale
   pins. **Open owner gates: the launch fit and the §13 `coast_time` table.**
4. **Slice-2.5 (Feel) — READY, first engine wave after #2/#3.** Motion blur + camera
   pull-back + dust streaks (§3.4), damage smoke/ripple/shatter (FX_SPEC §6),
   dash charge FX (FX_SPEC §7) — no new gameplay systems, every number already
   in §13. All signals exist: the hull publishes `velocity()`, the HUD has
   `set_speedometer`, the damage pipeline fires, `hit_marker`/
   `set_lock_progress` are wired. Snapshot + commit before the first dispatch.
5. **Owner spec pass (blocks nothing, unblocks tests):** the six
   `18_engine_spec.md` edits listed in MASTER_REPORT §3 item 1 (R-key +
   Z/X countermeasure rows, strike the refuel-for-CR wording, speed-table-v2 △
   tick, mine-alpha/kinetic-cadence rows, §6 fragment wording, rock-mass row,
   seeker-orbit and Q-marks readings).
6. **Graphics lane, rest:** 4K 2× backdrop cuts (R8) + tint-stencil import
   settings + `_48` zoom buttons; B2-1 hover direction waits for the owner's
   pick; owner-endorsed direction: evaluate asset-library background plates
   for the station panels (user note, review sheet still owner-gated);
   F10's credit-cache salvage glyph. Later: MMO/faction liveries, six boss
   hulls, `ship_vanguard_damaged` — i2i re-liveries gated on the owner's
   naming overhaul.
7. **Non-blocking spec/economy items:** F3's three-owner delivery-seam
   refactor, F7's six doc holes, F8's `cm_*` rows in `03`, the REPAIRS panel's
   free-service rows, HUD pool blocks into `hud.tscn` (with L19, L20, L21
   backlog items when their files next have an owner), the mining laser's
   5 E/s drain (L11/L26 — the next wave owning `mining_laser.gd` or
   `player_ship.gd`), the station-boot-gate profile write (L18).
8. **Cleanup pass (deferred items)** — the five sealed-archive moves (need a
   `VAJB_ARCHIVE_OK=1` session), `_mockup_station.tscn` deletion (gated on
   live S2 verification + wave-4 review), MAIN_MENU_SPEC reference repointing
   (see `docs/design/CLOSEOUT_PLAN.md` / `CLEANUP_PLAN.md`).
9. **Wave P2-A — ship slot frames (NEW 2026-09-21, owner's per-class
   slot/layout request; queued behind #1's art half and #3, parallel-safe with
   #4).** Every class gets its own slot count **and** its own layout: the nine
   grid matrices, the engine **set** (1/2/3 cells by the §13 mass band, summed
   deltas with a 1.40 ceiling), armour and weapons counts that rise with hull
   size (Lancer 2 mounts, Spearhead 4), the profile's per-hull fits at save
   **v4**, the nine-hull `StationCatalog` roster (all nine side renders exist,
   so the 08 §4 miner gap is closed), the launch path resolving the active
   hull's own fit instead of the one global `STANDARD_FIT`, and the
   station/HUD layout displays reading `ShipFit.grid_cells`. Brief
   `.agents/gen/p2a_slot_frames_wave_task.md`, prompts
   `.agents/gen/p2a_slot_frames_wave_prompts.md`. **Docs are already amended
   and are the law** (08 §3/§3.1/§3.2/§3.3/§6, 09 §1/§2/§3.7/§4/§5/§7/§8/§9,
   10 §2.3); the owner's tick list is brief §8 and blocks nothing. Its
   follow-up **P2-B (fitting panel, module install/remove, power meter, legacy
   UPGRADES flag day)** is briefed after this wave's review. Two things are
   staged out of it on purpose: mount-anchor **consumption** in flight (the
   feel wave's, spec in brief §7) and the input map's five weapon groups vs a
   7-W capital (owner's).

## Parked (independent)

- Mockup scenes `_mockup_main_menu.tscn` / `_mockup_station.tscn` — deleted
  when their verification close-out lands (IMPLEMENTATION_PLAN §9.6).
- `docs/gameplay/19_testing_notes.md` batch-2 items B2-1/B2-2 — annotated;
  land with the graphics lane's pass.

## Closed (details in MASTER_REPORT.md)

- **Combat/collision repair wave** (2026-09-21, gate 226 → 236): C1–C3 measured, C5
  fixed (rock `collision_mask` 0 → 2, the rock's ram sink on the shipped
  `GUN_CHIP_RATE`, plasma's live-shield bonus, the mine's cadence fallback, and the
  owner's nine `coast_time` rows ×0.50), C6 reviewed with no HIGH, C7 corrected
  CONTRACTS §4/§5/§8.2/§9 and wrote the v1.2 changelog, T1 gave the import tool its
  `--only` scope. Reports `.agents/gen/combat_repair_*_report.md`.
- **UI-chrome wave, code lane** (2026-09-21, gate 219 → 226): W1–W4 built the D3
  `TextureButton` size guard (six sites, measured shipyard strip 6184 → 360 px and
  launch panel 4781 → 952 px with the oversized art still on disk, new
  `tests/test_ui_slot_layout.gd` 7 tests), repaired the D4 stale `ext_resource` UIDs
  through the editor writer, ran the D5 lint pass (23 warning rows across nine files,
  including a latent `push_overlay` Callable trap it caught itself) and landed the D6
  doc ticks. W5 reviewed with no HIGH (two MED, ten LOW — all LOW now in
  `LOW_BACKLOG.md` as L30–L37), W6 closed both MEDs. Reports
  `.agents/gen/ui_chrome_w{1..6}_report.md`. The art half of the same blocker is the
  graphics lane's and stays owner-gated on the slot review sheet.
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
