# S22 — Feel, juice & balance (wave brief)

**Wave:** S22 (code lane, item 28 of `dispatch_coder.md`)
**Slice folder:** `.agents/gen/slices/S22-feel-and-juice/`
**Baseline (measured 2026-09-30 at `93d6afb`):** `[SUMMARY] passed=941 failed=0`,
exit 0 — the figure the brief used to carry (`914`) predates S21's close and is
corrected here. `python3 staging/verify_wave.py snapshot --name s22_start` runs
before the first dispatch.
**Owner go (2026-09-27):** "i want to focus on content, bugfixes, playability and
feel" — this wave is the playability/feel half. **Depends on:**
`slices/D15-flight-feedback/D15-A1_report.md` — the owner ticked **all 25 rows**
on 2026-09-29 (one to its reversal, T-feel-5), so nothing in this wave ships at a
"PROPOSED default": §11 is the ruling of record.

## Amendment 2026-09-30 (owner-ruled in the planning session)

The brief was written 2026-09-28, three days **before** D15's ticks landed and
before this wave's sites were re-measured. Five owner rulings amend it; the body
below is the amended law and §11/§6/§7 carry the changes.

| # | Owner ruling (2026-09-30) | Reversal |
|---|---|---|
| 1 | The seeker fuze's home row in owner-locked `18_engine_spec.md` §13 is landed by **the developer at S22's open** (it is in the pre-flight commit), so no worker implements against a number whose spec home is absent | strike the §13 row; the fuse then cites D15's sheet alone |
| 2 | **Three builders**, strictly sequential (B1 feedback seams → B2 HUD + audio → B3 flight & balance), not one B1 carrying every row — S21's three-way split is the precedent and its reasons hold (regions overlap on `hud.gd`, `weapons.gd`, `projectile.gd`, `npc_ship.gd`) | collapse to one builder with A1–A14 |
| 3 | The rows §3 proves **already shipped at the ticked value** become **verify-only** (A4, A8, A13, and A11's R-S22-3/R-S22-4 + S19 T1–T7 half, A9's T-feel-3/§22-T3 half): the builder measures and reports each with a cite, and rewrites nothing | restore the original build wording for any row the review finds *not* at its ticked value |
| 4 | The five bucket-2 doc edits D15 routed to the developer (CONTRACTS §22's T3 strike, §23.5's ramp sentence, §14's NPC-brake disclosure, the S5 pin note, `ship_fit.gd`'s retune comment) are **landed at S22's open** in the pre-flight commit, so R1 verifies them instead of editing `CONTRACTS.md` §22/§23 | R1 lands them; the developer reverts the pre-flight edits |
| 5 | **Three suites**, one per builder region (`test_s22_feedback.gd`, `test_s22_audio.gd`, `test_s22_balance.gd`), instead of one `test_s22_feel.gd` three builders append to | one appended suite |

Also closed at this open (no code): **L250** (D15's stale anchors — the §3 table
below is re-anchored) and **L251** (the chip-spark re-cut now rides §10).

### Amendment 2026-09-30b (developer-ruled after S22-B1, S21 precedent)

| # | Ruling | Reversal |
|---|---|---|
| 6 | **S19's byte-seal row is red by design until B3 re-pins it.** A1 edits `weapons.gd` and A2 `npc_ship.gd`, both pinned in `tests/test_s19_quadrants.gd:94-105`, and B2 moves `weapons.gd` again (FIRE_CUES) — so the **last** builder (`S22-B3`) re-pins both strings from the finished tree, once, with the hashes in its report (the S21 rule: the last editor re-pins; B1 must not edit the yardstick) | restore the two pinned strings and accept the red row |
| 7 | **`test_engine2_wiring.gd:428`'s one rewritten row is accepted** (B1's deviation (d)): it pinned the retired pool-drop poll's exact behaviour, so it now proves a drop does *not* mark and a landed delivery does. Row count unchanged | restore the poll and the row with it |
| 8 | **A3's "nose" is the hull's bow band** (B1's deviation (b)): the acceptance's intent — the flare must read at the nose, not over the hull middle — governs the tick's literal "(mount, else radius-forward)", because the mounts sit amidships. Bucket 1 (inside a pinned acceptance); R1 grades the measured mouth against the intent | anchor at the firing barrel's `muzzle_position`, or restore the origin |

## 1. The law to read, in order
1. `slices/S22-feel-and-juice/SLICE.md` — scope, file sets.
2. `slices/D15-flight-feedback/D15-A1_report.md` §A1 — **the ticked feel rows**
   (T-feel-1..7, FX-1/FX-2a–e, AUDIO-1..3, S19 T1–T7, M4–M7).
3. `docs/gameplay/09_ship_slots_modules.md` §3.3's 2026-09-26 amendment + the
   **2026-09-27 P3 block** (R-S22-2/3/4); `01_economy_core.md`'s **2026-09-27 P3
   block** (R-S22-1) — by range.
4. `docs/gameplay/18_engine_spec.md` §13's **Rocket fuze** row (new, 2026-09-29).
5. `.agents/gen/_state/LOW_BACKLOG.md` — only the rows §3 names.
6. The §5 spec extract (operative law).

## 2. The owner's request (verbatim)
> "i want to focus on content, bugfixes, playability and feel" (2026-09-27).

The feel pillars behind this wave, from the owner's rulings archive: "hits must
read" (the S2.6 feel rulings), ruling 18 (speed fantasy is feedback only),
ruling 23 (quadrants and breach malfunctions). A designer deliverable must name
the rulings it implements; this implementer wave names them in its report.

## 3. What is already measured (file:line)

Re-anchored 2026-09-30 (L250): every cite below re-lands at the pre-flight
commit. **"SHIPPED" rows are verify-only** per amendment ruling 3.

| Row | Measured | Site |
|---|---|---|
| L28 | hit marker fires only for the marked target (pool-drop poll); components publish no signal | `game/game.gd` `_target_pools_seen` poll; `ui/hud/hud.gd:581` `hit_marker()` |
| L56 | a ram charges damage with no cue and no spark | `player_ship.gd:1147-1210`, `npc_ship.gd:546-600` (contact handlers) |
| L51 | muzzle flash mouth = the component origin (reads over the hull middle) | `weapons.gd:266-285` `FLASH_MUZZLE_PX`; `:1437,1445-1468` `_spawn_muzzle_flash` |
| L52/L65 | **SHIPPED** — the mining beam's chip event plays the cue **and** draws the burst | `mining_laser.gd:214-225` (`_apply_cycle` → `_play_chip()` + `ProjectileScript.spawn_chip_sparks`); chip world 40 u at `projectile.gd:344` |
| L241 | `set_quadrants` has zero production callers | `ui/hud/ship_status_screen.gd:843`; feed site `hud.gd:835-839` (`_push_status` pushes `set_pools` only) |
| L54 | anti-flam unimplemented (30 ms min, caps 4/6/1/2, skip-last) | `autoload/audio_manager.gd:352` (`play_pool`); no `Time.*`/cooldown/min-interval code exists |
| L48 | the mine has no release cue (no row, no asset) | `weapons.gd:266-273` `FIRE_CUES` (no `mine` row); AUDIO_SPEC §8.6 AUDIO-1 now carries the row |
| L55 | **SHIPPED** — low-hull arcs run at the ticked random cadence, seeded | `player_ship.gd:207-213` (`ARC_INTERVAL_MIN 1.6` / `MAX 2.6`, `ARC_SEED`), `:1787-1810` `_update_damage_arcs` (< 25 %), `arc_count()`/`arc_interval()` `:543-550` |
| L25 | seeker has no fuse radius (409 u min turn radius → orbiting locks) | `projectile.gd:70` `HIT_RADIUS`; homing drive `:641-665`; `SHOT_MASS` `weapons.gd:224` |
| L39/L103 | NPC skid ~2× long (no midline drag in `npc_ship.gd`); the retune comment claims no other file reads the column | `npc_ship.gd:761-776` (`_coast_rate`/`_linear_damp`, no `_step_lateral_drag`); `player_ship.gd:1367-1377`; `ship_fit.gd:401-405` (comment corrected at this open) |
| L182 | **SHIPPED as ruled** — the release rides the ramp, axial and lateral identical | `player_ship.gd:1050-1060` `_step_release`, `:1066` `_thrust_axis`; §23.5's new ramp row |
| L168/L244 | repairs fee/rows read the catalogue while panes print the resolved pair | `repairs.gd:62-84` `fee`, `:90-120` `repair` (both `Catalog.ship`); `repairs_panel.gd:212-217` |
| L242 | even-split spill under-lands (400 hit → 266.67 landed on `[200,100,0,0]`) | `game/player_state.gd:337-352` `_charge_quadrant` (the `remainder / (COUNT-1)` branch) |
| L169 | a twin battery seeds every cell from one pack (2× magazine) — **kept by R-S22-4** | `game/game.gd:1995-2035` `_seed_ammo`/`_auto_load_ammo` |
| L70 | a `w_mining` slot's label falls back to a gun name | `ui/hud/hud.gd:1539-1548` `_refresh_weapon` (`WEAPON_LABELS`/`WEAPON_IDS` fallback) |
| L49 | `sfx_weapon_laser_04` is a 1.244 s outlier in a 0.064–0.092 s pool | `autoload/audio_manager.gd:54-64` `CUE_POOLS[&"sfx_weapon_laser"][&"takes"]` |
| FX-2 | **SHIPPED** — every FX-2 pin matches the code | rocket 48 u / 12 FPS `projectile.gd:132-133`; mine 22 u `:120`; plume `:198-206`; chip + arc 40 u `:322,344` |

## 4. Pinned interface (verbatim) + rules
```gdscript
# game/weapons.gd:1839 — every delivery path passes here (add hit_landed)
func _deliver(
# ui/hud/hud.gd:581 — the marker that must fire per landed hit
func hit_marker() -> void:
# ui/hud/ship_status_screen.gd:843 — the feed that gains one production caller
func set_quadrants(prow: float, stern: float, port: float, starboard: float) -> void:
# autoload/audio_manager.gd:352 — the pool that gains the anti-flam rules
func play_pool(cue: StringName, take: int = -1) -> Dictionary:
# game/mining_laser.gd:214 — the chip event (already wired; verify only)
func _apply_cycle() -> void:
# game/player_state.gd:337 — the spill branch R-S22-2 rewrites
func _charge_quadrant(quadrant: StringName, amount: float) -> void:
# game/npc_ship.gd:761 — the twin the midline drag is mirrored into
func _coast_rate() -> float:
# game/repairs.gd:62 — the figure that moves to ShipFit.resolve
static func fee(profile: Node, ship_id: StringName) -> int:
```

Rules:
1. **Feedback is cosmetic** (ruling 18's shape): no feedback change moves a
  gameplay number — the muzzle offset may desync flash and shot (tick T-feel-4
  accepts it), nothing else may.
2. **One `hit_landed(target, amount)` signal** on the delivery seam (components
  publish, HUD consumes; Layer Cake: signal up, call down).
3. **Anti-flam is exactly AUDIO_SPEC §4.1's three rules** (30 ms min retrigger
  per cue; per-pool caps weapons 4 / impacts 6 / mining 1 / UI 2; skip the last
  used variant) — no fourth rule invented.
4. **Every feel row ships at its ticked value** (D15's sheet): §11 is the ruling
  of record, so nothing is left to a default. Each row's as-shipped value goes in
  the report's table with its reversal.
5. **Spill conserves damage** (R-S22-2): `hull == sum(pools)` holds and the
  landed total equals the incoming amount while any pool has room.
6. **A verify-only row is measured, never rewritten** (amendment ruling 3): A4,
  A8, A13 and the A11 dispositions report the shipped value with a cite and a
  probe; a row found *off* its ticked value is a bucket-2 report, not a licence
  to edit.

## 5. Spec extract (verbatim, cited)
`18_engine_spec.md` §3.1/§3.2 (flight):
> "**Linear inertia.** Velocity chases `throttle × max_speed` with the class's `accel_time`; with no input, speed decays over `coast_time` (heavy classes glide noticeably, light ones settle fast). S-thrust brakes at `BRAKE_MULT ×` the acceleration rate, so stopping hard costs attention."
> "**Angular inertia.** Turn rate spins up over `turn_spinup` and damps down the same way — heavy hulls arc into turns and overshoot, light hulls snap."

`18_engine_spec.md` §13 (Combat table, row landed at this open):
> "| Rocket fuze | the lock detonates on a near miss inside **80 u** of the target, **or** when its **6 s** flight fuze expires: a 900 u/s, 2.2 rad/s pursuit has a minimum turn radius of 409 u, so a lock acquired abeam inside that distance would otherwise be orbited and never struck. |"

`18_engine_spec.md` §4.5:
> "**Breach malfunctions:** when a quadrant's armor reaches 0: **RCS drift** (random rotational torque every 2 s) from a stern breach, **engine flicker** (15 % chance to ignore a thrust input) from a prow breach; port/starboard breaches clip the turn rate on that side until repaired."

`18_engine_spec.md` §3.4:
> "All of it is *feedback*, not physics: zero gameplay numbers live here."

`docs/design/AUDIO_SPEC.md` §4.1 + §8.6's amendment:
> the 30 ms minimum between triggers of one cue, the per-pool voice caps (weapons 4 / impacts 6 / mining 1 / UI 2), "skip the last used variant", and **AUDIO-1..3** (the `mine` deploy row with take `sfx_weapon_mine_drop_01.ogg` ≤ 0.5 s in the weapons pool; the three-rule wiring note; take 04 dropped with the trim staged).

`docs/design/FX_SPEC.md` §8's amendment (owner-ticked 2026-09-29):
> **FX-1** (chip-spark master is a 3-object sheet, playback 4 cells @ 20 FPS), **FX-2a–e** (trail 12 FPS/loop/48 u; mine 22 u; plume 16/1.4/0.6/14/25°/8–24/0.5–1.1; chip + arc 40 u; ripple not pinned), **T-feel-5 ticked to its REVERSAL** (arc onsets at random **1.6–2.6 s**; the 4.0 s proposal does **not** ship), **T-feel-7** (bolt/slug 64×4 u / 96×10 u accepted as measured).

`docs/CONTRACTS.md` §22 + §23.5:
> **T3 struck** (self-contradictory row; nothing implements it), and §23.5's new **release ramp** row: a released hull decays through `_step_release()` → `_thrust_axis()` with `_coast_rate()` driving it, so axial and lateral releases ride the same ramp (`t_10` Vanguard 1.150 s, both axes).

## 6. Acceptance list (numbered; the report answers each with a cite)
- **A1 (L28)** — `hit_landed(target, amount)` fires on every delivery that lands
  (all families, beams and projectiles, NPCs included) and the marker shows for
  any hull, not just the marked one; the pool-drop poll is retired.
- **A2 (L56)** — each hull's contact handler plays `sfx_impact_hull` /
  `sfx_impact_rock` and spawns one contact spark at the contact point.
- **A3 (L51)** — the muzzle flash anchors at the nose (tick T-feel-4's value);
  shots still spawn at the pinned point (rule 1).
- **A4 (L52/L65) — verify-only** — the mining beam's chip event already draws
  `spawn_chip_sparks` beside its cue; report the probe and the 40 u read.
- **A5 (L241)** — the HUD pushes `set_quadrants` every status update, so a
  breached quadrant reads its real pool in flight; the repairs panel's fallback
  stays disclosed.
- **A6 (L54)** — the three §4.1 anti-flam rules enforce in `play_pool`, each
  proven by a seeded probe (a 20 ms double-trigger; a 5th weapon voice refused).
- **A7 (L48)** — `mine_drop` sounds: one CC0 cue sourced via `assetmcp`
  (license-checked; `generation_log_audio.md` + `CREDITS.md` rows), wired in
  `FIRE_CUES`; the AUDIO_SPEC §8.6 row already carries the name and pool.
- **A8 (L55) — verify-only** — the arcs already run at the ticked **random
  1.6–2.6 s** cadence below 25 % hull with a seeded generator; report the
  measured interval and `arc_count()` (the 4.0 s proposal does not ship).
- **A9 (feel rows L25/L39/L103/L182/T3)** — the ticked values land:
  `SEEKER_FUSE := 80.0 u` **and** `SEEKER_FUSE_S := 6.0 s` (T-feel-1/1b, the §13
  row above); the NPC midline drag mirrored into `npc_ship.gd` (T-feel-2); the
  release ramp kept and §23.5's sentence tightened (T-feel-3, `CONTRACTS.md`
  already carries the row); §22's T3 row struck (already landed). Each row's
  as-shipped value tabled with its reversal.
- **A10 (L168/L244)** — R-S22-1 as written: `Repairs.fee()`/`repair()` resolve
  the same `ShipFit.resolve` pair the panes print (tick M4); the pane rows and
  the fee then read one figure.
- **A11 (L242/L169/S19 T1–T7)** — R-S22-2's **proportional spill** (the 400 hit
  lands 300 and kills; `hull == sum(pools)`), R-S22-3's stance (S19's initials
  stand) and R-S22-4's disposition (per-cell magazine model kept) — the stance
  and the disposition are dispositions, tabled not coded; the spill is the one
  code row.
- **A12 (L70)** — a tool-module slot's HUD label reads its `ModuleCatalog` name
  (tick T-feel-6, "yes"); summary table + `damage.gd` byte-identical.
- **A13 (FX-1/FX-2a–e/T-feel-7) — verify-only** — every pinned FX-2 number
  already matches `projectile.gd`; FX-1 and T-feel-7 are spec-text rows already
  in FX_SPEC §8. Report the pinned-vs-shipped table row by row.
- **A14 (AUDIO-3/L49)** — `sfx_weapon_laser_04` drops from
  `CUE_POOLS[&"sfx_weapon_laser"][&"takes"]` (the round-robin runs 01–03 and
  skip-last still applies at N = 3); the 0.06–0.09 s trim stays staged and the
  drop is proven by a probe over the take list.

## 7. Worker table
| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| S22-B1 | coder (builder) | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/tests/, .agents/gen/slices/S22-feel-and-juice/S22-B1_report.md` | A1–A4 + A8 + A12 + A13 (feedback seams; the verify rows measured) + `tests/test_s22_feedback.gd` + `S22-B1_report.md` |
| S22-B2 | coder (builder) | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/autoload/audio_manager.gd, vajb-orbit/assets/audio/, vajb-orbit/tests/, .agents/gen/slices/S22-feel-and-juice/S22-B2_report.md` | A5–A7 + A14 + `tests/test_s22_audio.gd` + `S22-B2_report.md` |
| S22-B3 | coder (builder) | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/tests/, .agents/gen/slices/S22-feel-and-juice/S22-B3_report.md` | A9–A11 + `tests/test_s22_balance.gd` + `S22-B3_report.md` |
| S22-R1 | reviewer | `vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S22-feel-and-juice/S22-R1_review.md` | `S22-R1_review.md` + CONTRACTS §9/§10 + LOW rows |
| S22-F1 | fixer (only on HIGH/MED) | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/autoload/audio_manager.gd, vajb-orbit/assets/audio/, vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S22-feel-and-juice/` | `S22-F1_report.md` |

Ground truth for R1: **A1–A14, in one list**, graded against §5's extract and
D15's ticked sheet. The verify-only rows (A4, A8, A13, and the A11/A9
disposition halves) are graded on whether the report's measured value **equals
the ticked value** — a mismatch is HIGH (a value that moved without a tick), a
missing cite is MED.

## 8. Run order + the tests that move
**B1 → B2 → B3 → R1 → F1 only on HIGH/MED.** Expected gate growth: the three new
suites only, one row per acceptance. Candidates:

| Suite | Why | Verdict |
|---|---|---|
| `test_s22_feedback.gd`, `test_s22_audio.gd`, `test_s22_balance.gd` | new, one per builder | **+ rows (the only expected growth)** |
| `test_flight_feel_g1.gd`, `test_s2_6_flight.gd`, `test_engine_c3_flight_decay.gd`, `test_slice2_5_feel.gd` | A9's seeker fuse + NPC drag | may move (the NPC skid number is *expected* to move — T-feel-2) ⇒ a row moving on the **player** side is bucket 2 |
| `test_s19_quadrants.gd` | A11's spill **+ the byte-seal row** | one corrected row (the 400-hit spill row); **the seal row is red from B1 until B3 re-pins it** (amendment 6) |
| `test_engine2_npc.gd` | T-feel-2's NPC drag | may move; ~1 row |
| `test_engine2_wiring.gd` | A1's retired pool-drop poll | one row rewritten (amendment 7, accepted) |
| `test_weapon_fx_f1/f2/f4.gd` | A1/A3/A13 seams | unchanged (cosmetic, rule 1) |
| `test_p1_repairs.gd`, `test_combat_repair_c5.gd` | A10's repair figure | unchanged totals; only the source of the pair |
| `test_s5_ammo_cargo.gd` | A14's take list | unchanged (the drop is a pool member, not a test pin) |

Any other count moving is a bucket-2 pause: report it, leave it, stop. The
**audio reimport** (a new `.ogg` needs its `.import` sidecar) is the
orchestrator's close-out step, not a worker's.

## 9. Hard rules
- Docs read-only (`CONTRACTS.md` is R1's). `--forbidden` at verify: explicit
  files — `vajb-orbit/project.godot`, `vajb-orbit/game/damage.gd`,
  `vajb-orbit/addons/`, `docs/CONTRACTS.md` — **never a directory** (L245:
  directory entries are inert).
- Audio is **CC0 1.0 only** (assetmcp, license recorded in the manifest; no
  CC-BY/OGA-BY). No AI art. Bounded runs, scratch stores (L229), no shell edits.
- Bounded runs only: every Godot invocation carries `--quit-after`; never wait on
  an unbounded process (the S21-F1 wedge).

## 10. Staged / deferred
- L57's bolt/slug aspect → **accepted deviation** (T-feel-7; the art re-cut stays
  staged). L129 (index spaces) documented. L49's laser_04 trim → the audio-lane
  pass. **FX-1's chip-spark master re-cut** (a true 4-object sheet) is staged
  here so it has a forward home (L251).
- The mine cue's alternates (2–3 takes if the CC0 pack carries them) and the
  anti-flam assets pass (D15_BRIEF §10) stay staged.

## 11. Owner tick list — **TICKED 2026-09-29 (the ruling of record)**
| Tick | Ruling (D15-A1_report.md §A1) | Value that ships |
|---|---|---|
| T-feel-1 | y | `SEEKER_FUSE := 80.0 u` proxy detonation |
| T-feel-1b | y | `SEEKER_FUSE_S := 6.0 s` flight fuze (orbiting not blessed) |
| T-feel-2 | y | mirror the midline drag into `npc_ship.gd` + the L39 disclosure fix |
| T-feel-3 | y | keep the release ramp; §23.5's wording tightened (landed at this open) |
| T3 | y | strike CONTRACTS §22's strafe row (landed at this open) |
| T-feel-4 | y | muzzle flash anchors at the nose (desync accepted) |
| T-feel-5 | **y to the REVERSAL** | arcs at random **1.6–2.6 s**; the 4.0 s proposal does **not** ship |
| T-feel-6 | y | tool slots label by `ModuleCatalog` name |
| T-feel-7 | y | 64×4 u / 96×10 u pinned as measured (re-cut staged) |
| S19 T1–T7, M4–M7 | y | all at their PROPOSED values (M6's post-playtest-2 re-tick stands) |
| FX-1, FX-2a–e | y | as drafted in FX_SPEC §8 |
| AUDIO-1, AUDIO-2 | y | as drafted in AUDIO_SPEC §8.6 |
| AUDIO-3 | y | drop `sfx_weapon_laser_04` now; the 0.06–0.09 s trim stays staged |

## 12. Close-out (the orchestrator)
1. Gate twice on fresh scratch stores (identical counts).
2. Reimport the new audio cue in the editor (or `--editor --quit` with the editor
   closed) so its `.import` sidecar lands, then commit it.
3. `python3 staging/verify_wave.py verify --baseline s22_start --forbidden
   vajb-orbit/project.godot vajb-orbit/game/damage.gd docs/CONTRACTS.md
   --tests --expect-reports .agents/gen/slices/S22-feel-and-juice/S22-B1_report.md
   …/S22-B2_report.md …/S22-B3_report.md …/S22-R1_review.md`.
4. LOW rows closed with reversals; WAVEBOARD + `dispatch_coder.md` one-liners;
   `MASTER_REPORT.md` §6 recap.
5. Wave-boundary commit.
