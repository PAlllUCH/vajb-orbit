# Master report — what the workers did, and what is still wrong (2026-09-21)

One file that answers "what happened" without reading the per-wave reports.
**2026-09-21 cleanup:** per-worker report chains, task briefs, prompt files,
dispatch scripts and probe/boot/gate logs were deleted from `.agents/gen/`
(≈270 files, git-tracked so the history survives in git); kept are the
wave-level + review reports below, `LOW_BACKLOG.md` (the L1–L29 backlog),
`ui_chrome_regression.md` (the art-lane handover), the two dispatcher files,
`previews/`, `batch2_evidence/`, `_wave_state/` (verify baselines) and
`headless_sweep.log`. Deleted-report citations in `docs/` were repointed here.

**State in one line:** engine wave 1 (fly-and-mine), engine slice 0 (Physics &
Fuel) and engine slice 2 (Fight) are all **CLOSED and review-verified clean**;
batch-2, the two doc lanes and the Phase G graphics lane closed beside them;
the universal gate reads **219 tests, 0 failures, exit 0**; the last commit
`c24ed3f` closes slice 2. Nothing is in flight.

---

## 1. What the workers did

### Engine wave 1 — fly-and-mine (closed, review-verified)

| Workers | Did | Evidence |
|---|---|---|
| W0–W5 | doc amendments, flight fit, mining, sector population, HUD | `engine_wave1_w0..w5_report.md` |
| W6/W8 | review + re-review: 8/8 fixes verified, 40/40 probe checks, boot gates exit 0 | `engine_wave1_review_report.md`, `engine_wave1_review2_report.md` |
| W7 | fixes H1–H4, M1–M3 | `engine_wave1_w7_report.md` |

Git baseline `2a420a7` pushed to `origin/main`.

### Engine slice 0 — Physics & Fuel (closed 2026-09-21; gate 78/0)

Workers M0→M6, orchestrator-owned interventions for owner rulings and the input map.

- **Delivered:** the hull on a real `RigidBody2D` (forces/torque, contact damage,
  recoil, knockback, `I(d)` shockwave — new `game/impact.gd`); the energy/fuel
  reactor chain (10 E → 1 F, boost 3.0 fuel/s, fuel-cell on **R**); asteroid
  cleaving (L→2–3 M→2 S→1–2 pickups, fragments are field members, rocks now
  560 t bodies); free instant refuel/recharge at stations; **save schema v3**;
  HUD energy/fuel bars + EMERGENCY FLIGHT banner. +25 tests.
- **Review (M4) found 1 HIGH + 6 MED; M5 fixed; M6 re-verified all clean.**
  The HIGH was a stale save-v2 assertion; the MEDs were the reactor chain's
  *unwired seams* (thrust not gated on empty fuel, afterburner burning nothing,
  `PlayerState.tick` and `consume_fuel_cell` unreachable) — M1/M2/M3 each
  implemented their slice correctly and each left the seam between them dead.
- Owner rulings R1–R4 (`slice0_owner_rulings.md`): refuel/recharge FREE (the
  §13 CR rate does not exist); asset-tree failures environment-deferred;
  `consume_fuel_cell` = R (C stays `cargo_toggle`); owner strikes the
  superseded "fuel for CR" wording in their own spec pass.
- Wave report: `slice0_report.md`; chain `slice0_m0..m6_report.md`.

### Engine slice 2 — Fight (closed 2026-09-21; gate 219/0)

Workers W0→W9, plus one closing fixer.

- **Delivered:** `WeaponComponent` (six families, lock seam, countermeasures,
  guns-on-rocks, recoil), `Projectile` (ballistic + 2.2 rad/s homing, mine
  arm/trigger, flare retarget, knockback + blast), `Damage` pipeline (§4.2
  item-5 context/bearing, shield rule, `REGEN_QUIET`), NPC registry (9
  archetypes + sector bands) / brain (one state set, leash, AGGRO_COOLDOWN) /
  ship (RigidBody2D on the player's physics law, `died`), loot tables (4 tables,
  EV drift ≤ 0.65 % over 20 000 seeded rolls), HUD lock ring + radial
  speedometer + hit marker + ghost blips, countermeasures Z/X, death → respawn
  docked. +139 tests (six new suites).
- **Review (W6) found 1 HIGH + 10 MED; W7 fixed F1/F2/F4, W9 fixed R1, W8
  re-verified all clean.** The HIGH: *no weapon damaged a real ship* — both
  delivery sites handed hits to a bare `HullBody` with no damage-sink
  resolution; fixed by `_sink_for` (measured: laser 800 → 770 = exactly 30).
  W8 caught the F2 fix *turning on* a latent double ammo charge (R1, 297 → 294);
  W9's one-line seed update closed it with a negative control (297 → 297).
- Owner rulings R5–R8 (`slice2_owner_rulings.md`): chaff = **Z**, flare = **X**;
  mine alpha 180 / kinetic cadence 0.6 s accepted as their own spec rows owed;
  chrome re-cut routed to the art lane; backdrops target 4K (2× cuts owed).
- Wave report: `slice2_report.md`; chain `slice2_{w0,w0b,w1..w9}_report.md`,
  review `slice2_review_report.md` + `slice2_w8_report.md`.

### Batch-2 playtest lane (closed)

- **B2-3 minimap zoom inversion was a real code defect** — fixed in
  `ui/hud/hud.gd` (deltas renamed to the direction they mean, bindings swapped;
  measured `%ZoomPlus` → radius 3200→2400).
- **B2-1 (hover look) and B2-2 (soft backdrops) are art-side, not code** — the
  2026-09-21 00:17 chrome re-cut replaced whole sheet cells where the theme and
  scenes still carry the 2026-09-18 geometry (§2 below). Measured, recipe
  written, routed to the graphics lane. Reports `batch2_report.md`,
  `batch2_docs_report.md`, handover `ui_chrome_regression.md`.

### Doc lanes (closed)

- `slice2_lootdocs_report.md`: landed the reviewer-measured 06 figures
  (2.15 / 28.375 / 11.83 %, 2.30, 1.50, 6.375, floor 1025 CR, mean 1584.75) and
  the `11 §3` → `18 §13` pointer (F9, F11).
- `batch2_docs_report.md`: `19_testing_notes.md` B2-3 ticked, B2-1/B2-2
  annotated; the `IMPLEMENTATION_PLAN.md` §9.8 follow-up line.

### Graphics lane — Phase G (closed for this run; `designer_phase_g_report.md`)

- **65 files shipped and imported:** alien hull sheets (Swarmer — unblocks
  slice-2 W3's visual pass, Sibelon, Apex), the **human roster reworked — 14
  hulls** (core five owner-approved "look good, go ahead", plus
  `ASSET_EXPANSION_SPEC.md` §3 classes 7–15), and 7 Phase G FX.
- `fx_shield_shatter` retired by owner ruling (`fx_shield_break` covers it).
- **Pipeline lessons now law** (`staging/phase_g/`): panel order is render →
  find objects → cut each → key each → trim (panel-level keying ate a hull,
  the 2×2 grid clipped two); a 2×2 sheet's fourth cell is often a second front,
  not a rear (silhouette IoU vs front > 0.80 = refuse; `refit_panels.py`
  enforces); `cells` in `wave_g.py` is the authority, `cuts` derived.
- **Still on the old art:** MMO/faction liveries (`ship_*_mmo`, `_concord`,
  `_meridian`, `_choir`), the six boss hulls, `ship_vanguard_damaged` — i2i
  re-liveries that wait on the owner's naming overhaul.
- The assets re-layout also **healed slice 0's environment fallout**:
  `asset_path_fallout.md` now reports **181 asset literals, 0 unresolvable**;
  the Small-rock pickup burst measures green again (`ok=25 failed=0`, spawn
  half; full spawn→collect chain still unproven).

---

## 2. Known errors and live defects (measured, not fixed)

The authoritative defect list is `ui_chrome_regression.md` (art) and
`LOW_BACKLOG.md` (L1–L29, code/spec/harness). Headlines:

### Art / chrome (routed to the graphics lane, rulings R7/R8)

| Defect | Measured |
|---|---|
| Button plates | 1041×1087 cell stretched into a 350×70 plate → renders **287.1 × 8.6 px, 90 % transparent** |
| Menu wordmark | crop `AtlasTexture Rect2(44,707,1961,615)` holds **0 ink pixels** of the new 2170×823 art |
| Minimap bezel | nine-patch frame band draws **3.0 px** instead of 16 |
| Bar caps, slot families, panel frame | same cell-vs-box class of defect |
| Backdrops | every `@2x` cut deleted → 1.25× upscale at 1440p, 1.875× at 4K |
| Tint stencils | 1 080 files lost the F.1/F.2 import settings (`mipmaps/generate=false`) |
| HUD zoom buttons | 3.43 texels/px minification; `_48` cuts are the fix |

**Owner gates still open:** B2-1 hover direction (flicker / directional glow /
ember) needs the owner's pick from a standalone 1080p + 1440p look; B2-2's
display target decided (4K, R8). Nine-slice margins cannot fix this art; the
fix is a tight re-cut + re-pull + re-import.

### Code/spec/harness (backlog, none blocking)

- **Mining laser's 5 E/s beam drain has no code owner** (L11/L26 — still open
  after two waves; route in the next wave owning `mining_laser.gd` or
  `player_ship.gd`).
- **Ships do not pair with ships** (L22): hull layer 2 / mask 1 — ship-vs-ship
  rams are nobody's job; needs a ram authority (design decision, slice 4).
- **Wreck window doesn't survive a scene transition** (L23) and the **hull
  flies for frames between death and respawn** (L24) — both slice 4.
- **Q cycles marks, not locks** (L27 — self-consistent reading, owner's call);
  **hit-marker only fires for the marked target** (L28 — needs a
  `hit_landed` signal on the components).
- **`hud.tscn` byte-identical**, widgets built in code (L19 — W6 ruled
  acceptable; revisit with the next HUD/theme pass); **`HULL_SCALE` has three
  homes** (L20); **NPC flight maths duplicated** from `player_ship.gd` (L21 —
  values single-owner, code shape is not).
- **The station boot gate writes the dev profile** (L18: normalises the market
  band on panel open); `test_engine2_pools.gd` also triggers a normalisation
  write of `user://profile.cfg` (attributed in `slice2_w7_profile_hygiene.md`;
  content normalisation, no data loss). Fix shape: normalise at dock.
- **Stale `ext_resource` UIDs** in `player_ship.tscn` / `game.tscn` warn on
  every load (L29 — clears when the editor next re-saves the scenes).
- **Unpinned values** behind the "report, never guess" rule: mine alpha 180 and
  kinetic cadence 0.6 s (R6, accepted), `HIT_RADIUS` 4.0, `SHOT_MASS` 1.0, and
  a seeker has no fuse radius (min turn radius 409 u → a beam lock inside that
  distance is orbited, not struck — owner blesses orbiting or adds a row).
- **Spec self-contradictions** for the next spec pass: §6's fragment tier vs
  §13's mineral+tier/yield (ruled: §13 + §12 item 12 win); the §13 rock mass is
  an inference (4 × `ship_miner` 140 t); 09/11/14 column-form items (L1–L5).

---

## 3. Open items, ranked

1. **Owner (spec is owner-locked, nobody else may touch it)** — one
   `18_engine_spec.md` pass covering: strike the superseded refuel-for-CR
   wording (§2.1 ruling 13, §4.4, §12 item 8); §11 `consume_fuel_cell` C → **R**
   + the missing `countermeasure_chaff`/`countermeasure_flare` rows (Z/X); the
   §13 speed-table-v2 △ tick; the mine-alpha-180 / kinetic-cadence-0.6s rows
   (R6); the §6 fragment wording; a §13 rock-mass row; bless-or-fix the seeker
   orbit (L25) and the Q-marks reading (L27).
2. **Graphics lane** — the chrome re-cut (R7) + 4K 2× backdrop cuts (R8) + tint
   import settings + `_48` zoom buttons; B2-1 owner approval gate; F10's credit
   cache salvage glyph.
3. **Spec/economy, none blocking** — F3's three-owner delivery-seam refactor,
   F7's six doc holes (human/alien split, patrol count, alien/turret rows, NPC
   armament, stand-off, turret scan radius), F8's `cm_*` rows in `03`,
   the REPAIRS panel's free-service rows, HUD pool blocks into `hud.tscn`.
4. **Next engine wave — slice 2.5 (Feel) is READY**: motion blur + camera
   pull-back + dust streaks (§3.4), damage smoke/ripple/shatter (FX_SPEC §6),
   dash charge FX (FX_SPEC §7). No new gameplay systems; every number already
   in §13; all signals it needs exist (`velocity()`, `set_speedometer`, the
   damage pipeline, `hit_marker`, `set_lock_progress`). Snapshot + commit
   before its first dispatch.
5. **Backlog code items** (§2 list above) ride with whichever wave next owns
   the file; the probe-hygiene rule (L17) goes into the next brief.

## 4. Housekeeping facts

- **2026-09-21 cleanup executed:** `.agents/gen/` shrank from ~300 evidence
  files to the keep-set described in the header (≈270 deletions, staged in
  git at the next commit; history survives in git). `docs/` citations to the
  deleted chains were repointed to this file.
- Evidence chain per wave: the surviving wave-level + review reports listed in
  §1; baselines in `.agents/gen/_wave_state/` (`wave1_closed`, `slice0_start`,
  `slice2_start`).
- The test gate grew 53 → 78 (slice 0) → 219 (slice 2). Current contract:
  `res://tests/headless_runner.tscn` → `[SUMMARY] passed=219 failed=0`.
