# WAVEBOARD — one-file agent state

**Updated: 2026-09-22 (Rock cleave closed; P2-B1 next).** Full history of what every worker
did, with known errors and open findings, now lives in
`.agents/gen/MASTER_REPORT.md` — this board keeps only current state,
contracts, enforcement and the queue. Executed-wave reports, briefs and
evidence were moved to `.agents/gen/_archive/` (2026-09-21, reversible) —
citation paths of the form `.agents/gen/<report>.md` now resolve one level
deeper.

**Current state: seven coding waves closed (chrome, combat repair, weapon FX wiring, flight
feel & beam polish, slice 2.5 Feel, P2-A ship slot frames, Rock cleave; gate `passed=378
failed=0`). The queue of record is `dispatch_coder.md`: P2-B1 (item 6) next. Owner gates: the
chrome art half, the **`18_engine_spec.md` §6/§13/§15 cleaving amendment** (owner-locked; §15
is the test checklist and now contradicts the shipped suite), the launch fit (symptom 1
closed by P2-A; symptom 2, the mining-laser swap, opens with P2-B1), four spec ticks, the §13
turn column, and the engine-bed / vignette-strength calls slice 2.5 raised.** Engine waves closed as below
(slice 0 + slice 2 review-verified clean; gate `passed=311 failed=0`). A full-loop live
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
carry 430.32 → 216.85 u, §13 tick pending). **Owner gates from this wave:** the §13
`coast_time` table (still open), and the launch fit, which **P2-A closed at its measured root
cause** — the launch now resolves the active hull's own fit and files ammo per fitted weapon
(measured: Vanguard `[laser]` 300 rounds, Lancer `[laser, laser]` 600; was five families /
1500), with the mining-laser swap (symptom 2) opening with P2-B1.  The **weapon FX & audio wiring wave is Done** (reports
`.agents/gen/weapon_fx_f{1,2,3,4}_report.md`, gate 236 → 277): a projectile now draws its
shipped sprite (bolt, slug, missile-trail sheet or mine ember) additively and turns to its
bearing, the instant families draw an engine-side beam line, a four-frame muzzle flash fires
per release, and every family plays its cue through a new cue-pool API (`sfx_weapon_laser`
round-robin 01–04 with ±10 % pitch / −3..0 dB, cannon tiers, the rocket's +80 ms warhead
layer); hits play `sfx_impact_{rock,hull,shield_hit}` plus the shield bed and spawn the
explosion/arc/ripple/break/plume sheets, a beam's own hits now read (the reviewer's one HIGH,
fixed in the fixer pass), and the mining shaft carries its beam bed. The reviewer verified by
measurement — every event's node, blend mode, sheet master, cue resolution and the absence of
any moved damage/cadence/range/Energy/ammo number. Evidence:
`.agents/gen/owner_playtest_findings_20260921.md`, `.agents/gen/playtest_fullloop_20260921.md`.
**P2-A (2026-09-21): the owner's per-class slot/layout request shipped — DONE** (gate
311 → 372). Every class owns its slot count and layout: the nine matrices, the engine set
(1–3 cells by mass band, summed deltas with the 1.40 ceiling), profile fits at save v4, the
nine-hull `StationCatalog` roster, the launch resolving the active hull's own fit, and the
station/HUD layout displays. Reviewer: no HIGH; one MED fixed; six LOW (L66–L71). The
owner's §8 tick list is resolved (all six kept); the one follow-up is the 7-W capital's
`weapon_6`/`weapon_7` input-map extension (an owner `project.godot` pass). Full entry under
§Closed.

## Living contracts

- `docs/CONTRACTS.md` — pinned interfaces; **§11 (P2 ship frames) landed by P2-A
  2026-09-21** and **§5's cleaving sentence merged by Rock cleave (v1.4, 2026-09-22)**
  (status line v1.3; the §10 changelog carries the v0.2 and v1.4 entries). §9's expected
  gate figure is still the stale 294 — the next review wave owns it. Briefs say "code
  against CONTRACTS.md §n"; review waves own updating it.
- `docs/gameplay/18_engine_spec.md` — the engine contract. §2.1 carries owner
  rulings 8–26. **Owner-locked**: no worker may edit it; the six owed spec
  edits are the owner's (MASTER_REPORT §3 item 1).
- Universal test gate: `res://tests/headless_runner.tscn` → `[SUMMARY]
  passed=378 failed=0` (exact command in CONTRACTS.md §9; grew 53 → 78 → 219 → 226
  with the UI-chrome wave's `test_ui_slot_layout.gd`, 236 with the combat repair wave's
  `test_engine_c3_flight_decay.gd` and `test_combat_repair_c5.gd`, 277 with the weapon FX
  wave's `test_weapon_fx_f{1,2,4}.gd` suites, 294 with the flight/beam wave's
  `test_flight_feel_g1.gd` and `test_flight_beam_g2.gd`, 311 with slice 2.5's S3 pass, and
  **372 with P2-A's suites** — `test_ship_grids.gd` (27), `test_p2a_profile_fits.gd` (11),
  `test_p2a_launch_fit.gd` (12), `test_p2a_ship_roster.gd` (4), `test_ui_slot_layout.gd`
  rewritten 7 → 12, `test_p2a_lint_shadow.gd` (2)), then 378 with Rock cleave's
  `test_engine2_cleaving.gd` 9 → 15 (the only suite whose count moved; the rock brief's
  311 was stale — its baseline measured 372 against a stashed tree).
- `staging/verify_wave.py` — mechanical wave gates: `snapshot` before a wave,
  `verify --baseline <tag> [--forbidden ...] [--expect-reports ...] [--tests]`
  after. Baselines live in `.agents/gen/_wave_state/` (`wave1_closed`,
  `slice0_start`, `slice2_start`, `pipeline_v2_start`, `cleanup_delete_list`).
- **`AGENTS.md` §"Designer lane — the output format"** — the standing rule for
  how planning work is delivered: docs amended first, one brief, one prompts
  file, queued in this board and in `dispatch_coder.md`, handed over with the
  short paragraph template. Read it before planning or dispatching anything.

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

**Queued (the queue of record is `dispatch_coder.md` §Current queue):** item 6
**P2-B1 — runs next** (the weapon fit surface: OUTFITTING sells the six weapon modules
and installs/swaps them into the hull's W cells through `ShipFit.fit_legal`; brief
`.agents/gen/p2b1_weapon_fit_wave_task.md` + prompts). Items 4 **P2-A** and 5
**Rock cleave** — **DONE** (see §Closed). **The designer phase
is deferred to the next day (owner, 2026-09-21):** the graphics queue of record
is `.agents/gen/dispatch_designer.md` + `designer_generation_backlog.md`
(component icons, the `_48`/tint re-cuts, the decisions), hand-over prompt ready;
nothing from it is in flight. Owner ticks open: the
`18_engine_spec.md` §6/§13/§15 cleaving amendment (owner-locked — the wave shipped,
the spec text lags) and P2-B1's refusal wordings.

## Closed (details in MASTER_REPORT.md)

- **Rock cleave — DONE 2026-09-22** (gate 372 → 378; reports
  `.agents/gen/rock_cleave_a{1,2,3}_report.md`): every depletion now draws FX_SPEC §1.4's
  explosion at the rock's centre (`clamp(1.2 × diameter, 96, 224) u`, five frames, MIX,
  self-freeing), plays S4's rock cue through the new four-take `CUE_POOLS` row, and shoves
  reachable bodies with the shipped `Impact.apply_shockwave`; fragments are a uniform **2–5**
  on both cleaving tiers in **uniform 360°** directions at the shipped ×1.2 speed (measured:
  Large {2:80, 3:69, 4:72, 5:79}, Medium {2:78, 3:69, 4:70, 5:83}; widest fragment pair
  179.8°; 529/529 at exactly ×1.2); a Small keeps its 1–2 pickups; a yield-0 rock cracks
  bare but still plays the break read. Reviewer: no HIGH, one MED (`CONTRACTS.md` §5's
  retired cleaving sentence) fixed by A3 (+ v1.4 changelog), four LOW → L72–L75. **Owner
  tick owed: the §6/§13/§15 dated amendment (spec owner-locked).**
- **P2-A ship slot frames — DONE 2026-09-21** (gate 311 → 372; reports
  `.agents/gen/p2a_{d0,w1,w2,w3,w4,w5,r1,f1}_report.md`): every class owns its slot count and
  layout — nine matrices (shipyard grids 4×3 → 5×6, columns 4×8 + 5, plates
  8/11/12/13/13/15/14/17/23), the engine set (1–3 cells by §13 mass band, summed deltas with
  the 1.40 ceiling; single-engine snapshots byte-identical to HEAD), profile fits at save v4
  with v1–v3 loading clean, the nine-hull `StationCatalog` roster, the launch resolving the
  active hull's own fit (measured: Vanguard `[laser]` 300 rounds, Lancer `[laser, laser]` 600,
  was five families / 1500), and the station/HUD layout displays. Reviewer no HIGH, one MED
  (a shadowing const in `test_p2a_ship_roster.gd:10`) fixed by F1 (+2 tests), six LOW →
  `LOW_BACKLOG.md` L66–L71. **Owner launch-fit gate: symptom 1 closed at root cause;
  symptom 2 (the mining-laser swap) opens with P2-B1.** Owner ticks (brief §8) resolved, all
  six kept.
- **Slice 2.5 (Feel) — DONE 2026-09-21** (gate 294 → 311, `test_slice2_5_feel` 13): S1 shipped
  all nine deliverables (motion blur via `game/speed_fantasy.gd` + `speed_blur.gdshader`, the
  camera pull-back composed with the wheel zoom, dust streaks, the hull-critical vignette,
  low-hull arcs, the thruster trail behind a `thruster_anchors()` seam, the S16 thruster bed
  with its speed curve and 0.15/0.10 hysteresis, the boost cue and the dash charge). S2's review
  reproduced the gate and S1's probe byte-identically and blocked the close with **2 HIGH, 0 MED,
  6 LOW (L66–L72)**: the thruster bed held a voice but never loaded a stream (a fresh voice was
  silent, a reused one played the previous bed's file), and the trail drew at the master's native
  1401 × 86 px because `GPUParticles2D.scale` is inert for the drawn quad. The owner then re-cut
  every effect as per-frame RGBA sheets (`fx_<effect>_f1..fN.png`, true alpha, cropped to the
  effect's bounds) beside the untouched v1 masters, added `fx_mine.png`, and ruled the beam stays
  an engine-drawn line. **S3 (resumed with those facts) closed both HIGHs and re-wired all 15
  FEEDBACK rows plus the vignette to the per-frame sheets with alpha blending** — measured: the
  bed's voice plays its own cue from frame 1 on a fresh and a re-used voice, and the trail draws
  **22 × 6 px at ratio 0.15 → 54 × 6 at 1.0** (spec 24–56 × 6) where the node-scale lever still
  reads 159 × 26, `fx_mine` is the mine family's sprite and burst. Reports
  `.agents/gen/slice2_5_s{1,2,3}_report.md`. **Two owner calls raised:** which engine bed
  (`sfx_ship_engine_01` vs `_02_loop`) and whether the vignette under alpha needs a strength
  compensation (it draws 0.41× its additive reading, one line to reverse).
- **Flight feel & beam polish wave** (2026-09-21, gate 277 → 294): G1 the nose follows the
  cursor while `thrust_forward` is held (heading holds otherwise), A/D strafe derived from
  the class's own `max_speed`/`accel_time`, the nine `turn_rate` rows ×0.50 (Vanguard 3.0 →
  1.5 rad/s) and the two strafe actions in the Controls list; G2 the beam stops on the point
  its ray resolved (was drawn to the aim point, so it passed through), a laser chipping a
  rock plays the chip cue and the 4-frame burst, a held beam's feedback repeats, plus 29
  shadowing warnings cleared; G3 the UI/game warning sweep (75 → 65 raw rows); G4 reviewed
  with no HIGH (two MED, both fixed by G5) and found the gate's `SCRIPT ERROR` is pre-existing
  in `tests/test_weapon_fx_f4.gd:176`; G5 recorded the behaviours in CONTRACTS v1.3 and cleared
  the wave's own three new warning sites. Reports `.agents/gen/flight_beam_g{1..5}_report.md`.
  **Owner ticks owed:** `18_engine_spec.md:67` and `IMPLEMENTATION_PLAN.md:231` still say
  "A/D turn", and §13's turn column needs the ×0.50 tick.
- **Weapon FX & audio wiring wave** (2026-09-21, gate 236 → 277): F1 fire & travel, F2 impact
  & death, F3 review (1 HIGH, 3 MED, 11 LOW), F4 closed all four. Reports
  `.agents/gen/weapon_fx_f{1,2,3,4}_report.md`; the 11 LOW items are L48–L59 in
  `LOW_BACKLOG.md`. No balance number moved.
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
