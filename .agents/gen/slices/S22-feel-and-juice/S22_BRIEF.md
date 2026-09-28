# S22 — Feel, juice & balance (wave brief)

**Wave:** S22 (code lane, item 28 of `dispatch_coder.md`)
**Slice folder:** `.agents/gen/slices/S22-feel-and-juice/`
**Baseline:** gate after S21's close (record the live `[SUMMARY]` in the report);
`python3 staging/verify_wave.py snapshot --name s22_start` before the first dispatch.
**Owner go (2026-09-27):** "i want to focus on content, bugfixes, playability and feel" — this wave is the playability/feel half. **Depends on:** `slices/D15-flight-feedback/D15-A1_report.md` (the owner-ticked feel sheet); where it is silent, use §11's PROPOSED defaults.

## 1. The law to read, in order
1. `slices/S22-feel-and-juice/SLICE.md` — scope, file sets.
2. `slices/D15-flight-feedback/D15-A1_report.md` — the ticked feel rows (T-feel-1..7).
3. `docs/gameplay/09_ship_slots_modules.md` §3.3's 2026-09-26 amendment + the
   **2026-09-27 P3 block** (R-S22-2/3/4); `01_economy_core.md`'s **2026-09-27
   P3 block** (R-S22-1) — by range.
4. `.agents/gen/_state/LOW_BACKLOG.md` — only the rows §3 names.
5. The §5 spec extract (operative law).

## 2. The owner's request (verbatim)
> "i want to focus on content, bugfixes, playability and feel" (2026-09-27).

The feel pillars behind this wave, from the owner's rulings archive: "hits must
read" (the S2.6 feel rulings), ruling 18 (speed fantasy is feedback only),
ruling 23 (quadrants and breach malfunctions). A designer deliverable must name
the rulings it implements; this implementer wave names them in its report.

## 3. What is already measured (file:line)
| Row | Measured | Site |
|---|---|---|
| L28 | hit marker fires only for the marked target (pool-drop poll) | `game/game.gd` poll; components publish no signal |
| L56 | a ram charges damage with no cue and no spark | `player_ship.gd:472-492`, `npc_ship.gd:538-548` |
| L51 | muzzle flash mouth = shot spawn (reads over the hull middle) | `weapons.gd:285,1445,1664` |
| L52/L65 | mining chip sparks draw nothing (`_play_chip` is audio-only) | `mining_laser.gd:174`; `spawn_chip_sparks` exists in `projectile.gd` |
| L241 | `set_quadrants` has zero production callers (rows print the even split) | `ship_status_screen.gd:843`; feed site `hud.gd:835-840` |
| L54 | anti-flam unimplemented (30 ms min, caps 4/6/1/2, skip-last) | `audio_manager.gd:352` (`play_pool`) |
| L48 | the mine has no release cue (no row, no asset) | `weapons.gd` FIRE_CUES; AUDIO_SPEC §8 has no deployable row |
| L55 | low-hull arcs unwired (only the plume ships) | `projectile.gd` plume seam; no interval in any spec |
| L25 | seeker has no fuse radius (409 u min turn radius → orbiting locks) | `projectile.gd:68,74` |
| L39/L103 | NPC brake is 2× hard (coast ×0.50 reaches every hull); NPC skid ~2× long (no midline drag) | `ship_fit.gd:151`, `npc_ship.gd:695-709`, `player_ship.gd:_lateral_damp` |
| L182 | lateral release stops on the ramp, not the pinned damp shape | `player_ship.gd:873-884`; CONTRACTS §23.5 |
| L168/L244 | repairs fee/rows read the catalogue while panes print the resolved pair | `repairs.gd:64-65,89-90,107-108`, `repairs_panel.gd` |
| L242 | even-split spill under-lands (400 hit → 266.67 landed on `[200,100,0,0]`) | `player_state.gd` `_charge_quadrant` |
| L169 | a twin battery seeds every cell from one pack (2× magazine) | `game.gd` `_seed_ammo`/`_auto_load_ammo` |
| L70 | a `w_mining` slot's label falls back to a gun name | `hud.gd:1488` (`_refresh_weapon`) |

## 4. Pinned interface (verbatim) + rules
```gdscript
# game/weapons.gd:1839 — every delivery path passes here (add hit_landed)
func _deliver(
# game/ui/hud/hud.gd:581 — the marker that must fire per landed hit
func hit_marker() -> void:
# ui/hud/ship_status_screen.gd:843 — the feed that gains one production caller
func set_quadrants(...) -> void:   # signature per the file; four pool floats
# autoload/audio_manager.gd:352 — the pool that gains the anti-flam rules
func play_pool(cue: StringName, take: int = -1) -> Dictionary:
# game/mining_laser.gd:174 — the chip that gains the existing burst
func _play_chip(
```

Rules:
1. **Feedback is cosmetic** (ruling 18's shape): no feedback change moves a
  gameplay number — the muzzle offset may desync flash and shot (tick
  T-feel-4 accepts it), nothing else may.
2. **One `hit_landed(target, amount)` signal** on the delivery seam (components
  publish, HUD consumes; Layer Cake: signal up, call down).
3. **Anti-flam is exactly AUDIO_SPEC §4.1's three rules** (30 ms min retrigger
  per cue; per-pool caps weapons 4 / impacts 6 / mining 1 / UI 2; skip the last
  used variant) — no fourth rule invented.
4. **Feel rows implement the ticked value**; unticked, the §11 PROPOSED default
  ships and the report says so row by row (the S19 precedent).
5. **Spill conserves damage** (R-S22-2): `hull == sum(pools)` holds and the
  landed total equals the incoming amount while any pool has room.

## 5. Spec extract (verbatim, cited)
`18_engine_spec.md` §3.1/§3.2 (flight):
> "**Linear inertia.** Velocity chases `throttle × max_speed` with the class's `accel_time`; with no input, speed decays over `coast_time` (heavy classes glide noticeably, light ones settle fast). S-thrust brakes at `BRAKE_MULT ×` the acceleration rate, so stopping hard costs attention."
> "**Angular inertia.** Turn rate spins up over `turn_spinup` and damps down the same way — heavy hulls arc into turns and overshoot, light hulls snap."

`18_engine_spec.md` §4.5:
> "**Breach malfunctions:** when a quadrant's armor reaches 0: **RCS drift** (random rotational torque every 2 s) from a stern breach, **engine flicker** (15 % chance to ignore a thrust input) from a prow breach; port/starboard breaches clip the turn rate on that side until repaired."

`18_engine_spec.md` §3.4:
> "All of it is *feedback*, not physics: zero gameplay numbers live here."

`docs/design/AUDIO_SPEC.md` §4.1 (per L54's cite — the three anti-flam rules):
> the 30 ms minimum between triggers of one cue, the per-pool voice caps (weapons 4 / impacts 6 / mining 1 / UI 2) and "skip the last used variant"

`09_ship_slots_modules.md` §3.3 tick list (2026-09-26):
> "Owner tick list (calibrate later): T1 P1 split, T2 P2 arcs, T3 P3 application point, T4 P4/P5 malfunction strengths, T5 P6 spill, T6 P7 NPC staging, T7 P8 rows."

`09_ship_slots_modules.md` + `01_economy_core.md` **2026-09-27 P3 blocks**:
**R-S22-1** (one repair figure — proposed, tick M4), **R-S22-2** (proportional
spill, P6's named reversal — proposed, tick M5), **R-S22-3** (S19 initials
stand — tick M6), **R-S22-4** (keep the per-cell magazine model — tick M7).
D15's report carries the feel rows' ticked values (T-feel-1..7).

## 6. Acceptance list (numbered; the report answers each with a cite)
- **A1 (L28):** `hit_landed(target, amount)` fires on every delivery that lands
  (all families, beams and projectiles, NPCs included) and the marker shows for
  any hull, not just the marked one.
- **A2 (L56):** each hull's contact handler plays `sfx_impact_hull` /
  `sfx_impact_rock` and spawns one contact spark at the contact point.
- **A3 (L51):** the muzzle flash anchors at the nose (tick T-feel-4's value);
  shots still spawn at the pinned point (rule 1).
- **A4 (L52/L65):** the mining beam's chip event draws the existing
  `spawn_chip_sparks` burst beside its cue (the gun path already does).
- **A5 (L241):** the HUD pushes `set_quadrants` every status update, so a
  breached quadrant reads its real pool in flight; the repairs panel's fallback
  stays disclosed.
- **A6 (L54):** the three §4.1 anti-flam rules enforce in `play_pool`, each
  proven by a seeded probe (a 20 ms double-trigger; a 5th weapon voice refused).
- **A7 (L48):** `mine_drop` sounds: one CC0 cue sourced via `assetmcp`
  (license-checked; manifest + `CREDITS.md` rows), wired in FIRE_CUES; the
  AUDIO_SPEC §8 row lands with D15's amendment (note it in the report).
- **A8 (L55):** the low-hull arc emitter joins the plume below 25 % hull at the
  ticked interval (default `BREACH? — no: ARC_INTERVAL = 4.0 s`, tick T-feel-5).
- **A9 (feel rows L25/L39/L103/L182/T3):** the ticked D15 values land — default
  `SEEKER_FUSE = 80.0 u` proxy detonation (T-feel-1); the NPC midline drag
  mirrored in `npc_ship.gd` (T-feel-2); the lateral release keeps the ramp with
  §23.5's wording corrected by R1 (T-feel-3); CONTRACTS §22's contradictory
  T3 row struck by R1. Each row's as-shipped value tabled with its reversal.
- **A10 (L168/L244):** R-S22-1 as written — `Repairs.fee()`/`repair()` resolve
  the same `ShipFit.resolve` pair the panes print (tick M4).
- **A11 (L242/L169/S19 T1–T7):** R-S22-2's proportional spill (the 400 hit
  lands 300 and kills), R-S22-3's stance (initials stand), R-S22-4's
  disposition (per-cell model kept, M7) — each tabled.
- **A12 (L70):** a tool-module slot's HUD label reads its `ModuleCatalog` name
  (tick T-feel-6, default yes); summary table + `damage.gd` byte-identical.

## 7. Worker table
| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| S22-B1 | coder (builder) | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/autoload/audio_manager.gd, vajb-orbit/assets/audio/, vajb-orbit/tests/, .agents/gen/slices/S22-feel-and-juice/S22-B1_report.md` | A1–A12 + `S22-B1_report.md` |
| S22-R1 | reviewer | `vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S22-feel-and-juice/S22-R1_review.md` | `S22-R1_review.md` + CONTRACTS §22/§23 ticked values + §9/§10 + LOW rows |
| S22-F1 | fixer (only on HIGH/MED) | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/autoload/audio_manager.gd, vajb-orbit/assets/audio/, vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S22-feel-and-juice/` | `S22-F1_report.md` |

## 8. Run order + the tests that move
**B1 → R1 → F1 only on HIGH/MED.** Expected gate growth: **+
`test_s22_feel.gd` rows (one per AC)** only. Candidates:

| Suite | Why | Verdict |
|---|---|---|
| `test_flight_feel_g1.gd`, `test_s2_6_flight.gd`, `test_engine_c3_flight_decay.gd` | A9's feel rows | may move ⇒ listed here only if D15 ticked a value that changes them; a surprise move is bucket 2 |
| `test_s19_quadrants.gd` | A11's spill | one corrected row max (the 400-hit spill row) |
| `test_weapon_fx_f1/f2/f4.gd` | A1/A3 feedback seams | unchanged (cosmetic, rule 1) |
| `test_p1_repairs.gd`, `test_combat_repair_c5.gd` | A10's repair figure | unchanged totals; only the source of the pair |

Any other count moving is a bucket-2 pause: report it, leave it, stop.

## 9. Hard rules
- Docs read-only (`CONTRACTS.md` is R1's). `--forbidden` at verify: `docs/`,
  `vajb-orbit/project.godot`, `vajb-orbit/addons/`, `vajb-orbit/game/damage.gd`.
- Audio is **CC0 1.0 only** (assetmcp, license recorded in the manifest; no
  CC-BY/OGA-BY). No AI art. Bounded runs, scratch stores (L229), no shell edits.

## 10. Staged / deferred
- L57 (bolt/slug aspect) → D15's tick. L129 (index spaces) documented. L49
  (laser_04 trim) → the audio-lane pass. Mine/AUDIO_SPEC rows → D15's amendment.

## 11. Owner tick list (unticked ⇒ the PROPOSED default ships)
| Tick | Row | PROPOSED default |
|---|---|---|
| T-feel-1 (L25) | seeker fuse vs blessed orbit | `SEEKER_FUSE 80.0 u` proxy detonation |
| T-feel-2 (L39/L103) | mirror NPC midline drag / accept asymmetry | mirror in `npc_ship.gd` |
| T-feel-3 (L182 + §22 T3) | ramp vs damp-shaped release | keep the ramp; R1 tightens §23.5's wording |
| T-feel-4 (L51) | muzzle at nose (accept desync) | yes, at the nose |
| T-feel-5 (L55) | arc interval | `4.0 s` |
| T-feel-6 (L70) | label from module name | yes |
| M4/M5/M6/M7 | R-S22-1..4 (see the doc blocks) | as written in the P3 blocks |

## 12. Close-out (the orchestrator)
1. Gate twice on fresh scratch stores (identical counts).
2. `python3 staging/verify_wave.py verify --baseline s22_start --forbidden
   vajb-orbit/project.godot docs/ vajb-orbit/addons/ vajb-orbit/game/damage.gd
   --tests --expect-reports .agents/gen/slices/S22-feel-and-juice/S22-B1_report.md
   .agents/gen/slices/S22-feel-and-juice/S22-R1_review.md`
3. WAVEBOARD + `dispatch_coder.md` one-liners; `MASTER_REPORT.md` §6 recap.
4. Wave-boundary commit.
