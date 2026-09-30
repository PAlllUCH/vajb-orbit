---
slice: D15
worker: D15-A1
model: mimo-v2.6-pro
status: actionable
gate: "n/a (design only — no gate rows move)"
---

# D15-A1 report — flight feel & feedback: tick sheet, spec amendments, composition

## Result
The feel pile resolves into one owner-tickable sheet (25 rows below): S22 §11's T-feel-1..7 + M4–M7, 09 §3.3's S19 T1–T7, CONTRACTS §22's T3 and L39/L103/L182/L57, each row carrying PROPOSED | reversal | tick id | the §text it implements. Amendment blocks landed in FX_SPEC.md §8 and AUDIO_SPEC.md §8.6; the feedback composition (quadrant feed, hit-marker verb, ram spark) is specified under A5.2 with a labelled sketch in `staging/mockup/out/d15_feedback_composition.svg`. Unticked rows implement at the PROPOSED value.

## Acceptance list answers
A1 — done — the tick sheet below covers every S22 §11 row (incl. M4–M7), 09 §3.3's S19 T1–T7, CONTRACTS §22 T3 and L39/L103/L182/L57, each with PROPOSED | reversal | tick | §text + `file:line`.
A2 — done — FX_SPEC.md §8 (ticks FX-1, FX-2a–e, T-feel-5, T-feel-7) and AUDIO_SPEC.md §8.6 (AUDIO-1..3) appended as dated amendment blocks, each row carrying its reversal + tick id; the mine cue is CC0 sourced via `assetmcp` per AGENTS.md (AUDIO-1 row).
A3 — done — composition + labelled sketch `staging/mockup/out/d15_feedback_composition.svg` under A5.2; rulings 18, 23 and the A5 chrome law named there and below.
A4 — done — rulings + escalations below; writes stayed inside `docs/design/`, `staging/mockup/` and this slice folder.

## A1 — the owner tick sheet — **TICKED 2026-09-29 (owner, interactive pass)**

Every row ticked; the record below is the ruling of record. One row is ticked to
its **REVERSAL** (T-feel-5); all others ship at their PROPOSED value. Both
bucket-3 forks are resolved (the seeker fuze pair; `sfx_weapon_laser_04` drops
with a staged trim).

| Tick | Ruling (2026-09-29) |
|---|---|
| T-feel-1 | y — `SEEKER_FUSE := 80 u` proxy detonation |
| T-feel-1b | y — `SEEKER_FUSE_S := 6 s` flight fuze (orbiting not blessed) |
| T-feel-2 | y — mirror the midline drag into `npc_ship.gd` + the L39 disclosure fix |
| T-feel-3 | y — keep the release ramp; the developer tightens §23.5's wording at S22's open |
| T3 | y — strike the §22 strafe row |
| T-feel-4 | y — muzzle flash anchors at the nose (desync accepted) |
| T-feel-5 | **y to the REVERSAL** — arc onsets at random **1.6–2.6 s** (§6 cadence); the 4.0 s proposal does **not** ship |
| T-feel-6 | y — tool slots label by `ModuleCatalog` name |
| T-feel-7 | y — accepted deviation: 64×4 u / 96×10 u pinned as measured (re-cut stays staged) |
| S19 T1–T7, M4–M7 | y — all at PROPOSED (M6's post-playtest-2 re-tick stands) |
| FX-1, FX-2a–e | y — as drafted in `FX_SPEC.md` §8 |
| AUDIO-1, AUDIO-2 | y — as drafted in `AUDIO_SPEC.md` §8.6 |
| AUDIO-3 | y — drop `sfx_weapon_laser_04` now; the 0.06–0.09 s trim stays staged (L49 resolved) |

The developer lands the flight/§13/CONTRACTS rows in the owning docs at S22's
open (docs-first, close-out 1). The original sheet (values | reversals | cites)
follows.

| Row | PROPOSED value | Reversal | Tick | Implements (§text · evidence) |
|---|---|---|---|---|
| T-feel-1 · L25 | `SEEKER_FUSE := 80.0 u` proxy detonation (a near-miss inside 80 u detonates) | bless orbiting (today: no fuze) | **T-feel-1** | 18 §4.1 rocket row + one new §13 row (owner folds in) · `projectile.gd:68,74` |
| T-feel-1b · L25 (completion) | `SEEKER_FUSE_S := 6.0 s` flight fuze — the proxy alone cannot catch the measured orbit (pure pursuit circles at v/ω = 900/2.2 ≈ 409 u) | no flight fuze (80 u alone ships) | **T-feel-1b** | same §text · L25's measured geometry |
| T-feel-2 · L103 | mirror the midline drag in `npc_ship.gd` (its own `_step_lateral_drag` twin) — **moves an NPC flight number** (skid settle ~2× faster than today; §14 re-scope consequence named) | accept the asymmetry; record in §14's disclosure | **T-feel-2** | CONTRACTS §14 re-scope · `player_ship.gd:_lateral_damp` vs `npc_ship.gd:695-709` |
| T-feel-2 · L39 (unconditional) | disclosure fix: correct `ship_fit.gd:151`'s "no other file reads this column" + one playtest-note line (pirate/patrol brake ×2 hard) | leave undisclosed | **T-feel-2** | L39's [DOC] disposition · `game/ship_fit.gd:151` |
| T-feel-3 · L182 | keep the ramp (axial = lateral release — §23's one-vector feel); the developer tightens §23.5's wording to name the ramp at S22's open | restore the damp-shaped release (lateral t_10 → 2.383 s) | **T-feel-3** | CONTRACTS §23.5 · `player_ship.gd:873-884` |
| §22 T3 · strafe | **strike** the row — its chase × 0.75 and its worked 4.8 → 3.6 s are each other's inverse, and §23.5 superseded the lever; the developer strikes it in CONTRACTS §22 at S22's open | corrected row: chase × 1.333 → the stated 3.6 s, re-proposed at a later tick | **T3** | CONTRACTS §22 T3 + §23.5 "T3 is HELD" · `CONTRACTS.md:3063,3086-3089` |
| T-feel-4 · L51 | muzzle flash mouth anchors at the nose (`ShipFit.HARDPOINTS` mount, else radius-forward point); shots stay at the pinned spawn — flash/shot desync accepted (cosmetic) | flash stays at the spawn (today) | **T-feel-4** | FX_SPEC §1.2 "over the muzzle"; 18 §3.4 · `weapons.gd:285,1445` |
| T-feel-5 · L55 | `ARC_INTERVAL := 4.0 s` between arc onsets at hull < 25 % (0.2 s per arc stands) | FX_SPEC §6's proposed 1.6–2.6 s random cadence | **T-feel-5** | FX_SPEC §7.1 + §6 · FX_SPEC §8 block |
| T-feel-6 · L70 | a tool-module slot's HUD label reads its `ModuleCatalog` name | keep the family-table index fallback | **T-feel-6** | UI_SPEC §3.8 "rows read `ModuleCatalog` names" · `hud.gd:1488` |
| T-feel-7 · L57 | accepted deviation: light **64×4 u** / medium **96×10 u** pinned as measured (objects 16.4:1 / 9.4:1); §1.1's 4:1/6:1 superseded-by-measurement | wiring-side fix refused (non-uniform scale = the A5.3 smear); art re-cut restores 4:1/6:1 (staged) | **T-feel-7** | FX_SPEC §1.1 + §8 block · `assets/fx/fx_laser_bolt.png`, `projectile.gd:94-106` |
| S19 T1 · P1 | pools split `hull_max / 4` at full repair; plating feeds `hull_max` as today | plating-only pools | **S19 T1** | 09 §3.3 P1 · `09_ship_slots_modules.md:195-197` |
| S19 T2 · P2 | routing quarters: prow \|d\| ≤ 45°, stern \|d\| ≥ 135°, STBD 45–135°, PORT −135…−45°; missing `direction` reads 0.0 (dead ahead = ×1.0) | any other arc map | **S19 T2** | 09 §3.3 P2 + 18 §4.5 · `:198-201` |
| S19 T3 · P3 | the rear 160° arc's ×1.6 multiplies the incoming amount **before** the shield-first absorb | hull-side only | **S19 T3** | 09 §3.3 pinned para + P3 · `:189-203` |
| S19 T4 · P4/P5 | RCS drift = **15 %** of max turn torque, random sign, every **2 s** (stern breach); clipped side runs ×0.5 turn (port/STBD) | any fraction | **S19 T4** | 18 §4.5 + P4/P5 · `:202-204` |
| S19 T5 (= M5) · P6 | R-S22-2: proportional spill to remaining capacity, damage conserved (400 on [200,100,0,0] lands 300 and kills) | even-split clamp (today: lands 266.67) | **S19 T5 / M5** | P6's named reversal + 09 P3 block · `:688` |
| S19 T6 · P7 | player-side only this wave (`NpcShip` hulls stay flat) | mirror the routing into NPCs | **S19 T6** | 09 §3.3 P7 · `:206-207` |
| S19 T7 · P8 | status screen gains the four append-only pool rows; repairs panel gains the four per-quadrant lines | drop the rows/lines | **S19 T7** | 09 §3.3 P8 + 18 §4.5 "damage report" · `:208-210` |
| M4 (cross-ref) | R-S22-1: `Repairs.fee()`/`repair()` resolve the `ShipFit.resolve` pair the panes print | the base `station_catalog` rows | **M4** | 01 P3 block · `01_economy_core.md:294` |
| M6 (cross-ref) | R-S22-3 stance: S19's P1–P8 initials stand; T1–T4/T6–T7 re-tick after playtest round 2 | — | **M6** | 09 P3 block · `09_ship_slots_modules.md:689` |
| M7 (cross-ref) | R-S22-4: keep the per-cell magazine model (a twin = 2× from the family pack) | the family-pack model | **M7** | 09 P3 block · `:690` |
| FX-1 · L52 | chip-spark **3-object master** correction; playback stays 4 cells @ 20 FPS (f4 = faint tail, 5.5 % ink measured) | re-cut a true 4-object master (staged) | **FX-1** | FX_SPEC §1.6 corrected in §8 · `asset-library/INDEX.md:244` |
| FX-2 · L59/L64 | pin trail 12 FPS/loop/48 u, mine 22 u, plume 16 / 1.4 s / 0.6 / 14 u / 25° / 8–24 u/s / 0.5–1.1, chip+arc 40 u; ripple **not** pinned (§1.5 already states it) | one constant each | **FX-2** | FX_SPEC §8 block · `projectile.gd:94-135,198-206` |
| AUDIO-1 · L48 | S26 `sfx_weapon_mine_drop` (CC0 via `assetmcp`, ≤ 0.5 s, weapons pool), wired in `FIRE_CUES`; detonation keeps `sfx_weapon_explosion` | any other name/pool; silence (today) | **AUDIO-1** | AUDIO_SPEC §8.6 · `weapons.gd:266-273` |
| AUDIO-2 · L54 | §4.1's three rules enforced in `play_pool`; "steal the oldest" non-operative (the Cap's "dropped, not queued" fires first) | implement steal-oldest instead of the drop | **AUDIO-2** | AUDIO_SPEC §8.6 · `audio_manager.gd:352` |
| AUDIO-3 · L49 (taste) | drop `sfx_weapon_laser_04` now (1.244 s vs the pool's 0.064–0.092 s); stage a trim returning it at 0.06–0.09 s | keep 04 (a 1.2 s tail in one shot of four) | **AUDIO-3** | AUDIO_SPEC §8.6 · `audio_manager.gd:CUE_POOLS` |

## Owner rulings implemented + escalations
- **Ruling 18** (speed fantasy = feedback only): A3's three elements are cosmetic (18 §3.4); the rows moving gameplay — T-feel-1/1b (their new 18 §13 row is the owner's to fold in, the §23 range-row precedent) and T-feel-2·L103 (the NPC drag mirror, §14 re-scope) — say so on their own rows.
- **Ruling 23** (quadrants + breach malfunctions): S19 T1–T7 + A3's panel-1 feed reading the real pools and breaches.
- **§23's one-vector inertia** ("go ahead with all"): T-feel-3 keeps the ramp that makes axial and lateral releases identical — the ruling's intent; §23.5's mechanism sentence is corrected by the developer at S22's open.
- **A5 chrome law** (A5.1 flat chrome / A5.2 composition / A5.4 danger never colour alone) + "hits must read" (S2.6) + the Tween animation house rule: A3's three panels.
- **Bucket-3 escalations (owner's call, routed through this sheet): (1) AUDIO-3/L49 is taste — L49 itself says "Owner's call"; (2) T-feel-1's fork (fuse vs blessed orbiting) is L25's named owner choice. No row supersedes an existing owner ruling.**
- Bucket-2 items named for the developer at S22's open (R1 may not edit CONTRACTS; no owner pause): §23.5 wording (T-feel-3), the §22 T3 strike, §14's disclosure (T-feel-2), the new 18 §13 row (T-feel-1), the S5 brief's "takes 01 to 04" pin (AUDIO-3); FX_SPEC §1.1/§6 wording landed in my own file set as the §8 block.

## Deviations from D15_BRIEF
- "T-feel-1..7": S22_BRIEF §11 stops at T-feel-6 — **T-feel-7 is defined here as L57's disposition** (S22 §10 defers L57 to D15's tick). Reported and numbered, not renamed.
- L55's "no interval anywhere" is wrong: FX_SPEC §6 already proposes "one arc every 1.6–2.6 s (random)". T-feel-5 keeps S22 §11's 4.0 s default (brief is law) and names §6's cadence as the row's reversal.
- L59's ripple item is a misread (§1.5 states the 0→1.5× / 0.3 s track) — recorded as FX-2e, deliberately not pinned.
- An 80 u proxy alone cannot resolve the measured 409 u orbit, so T-feel-1b (flight fuze) is staged as its own tick rather than folded in.

## Evidence
- Pillow over `assets/fx/fx_mining_beam_f1..f4.png`: ink 35.4 / 47.6 / 29.9 / **5.5 %** (FX-1's f4 figure).
- `rg -n 'QUADRANT_ROWS|func set_quadrants|_push_status' vajb-orbit/ui/hud/`: rows `ship_status_screen.gd:123-131`, setter `:843`, feed site `hud.gd:835-840` (no `set_quadrants` call — L241).
- `rg -n 'FIRE_CUES|class HitMarker' vajb-orbit/game/weapons.gd vajb-orbit/ui/hud/hud.gd`: `weapons.gd:266-273` (mine row absent on purpose, "section 8 states no deployable cue"), `hud.gd:1960` (the X, Tween fade).
- FX_SPEC diff is append-only: `git diff --stat docs/design/FX_SPEC.md` → 23 insertions, 0 deletions.

## Files touched
- `docs/design/FX_SPEC.md` — appended §8 amendment block (FX-1, FX-2a–e, T-feel-5, T-feel-7)
- `docs/design/AUDIO_SPEC.md` — appended §8.6 amendment block (AUDIO-1..3)
- `staging/mockup/out/d15_feedback_composition.svg` — new labelled sketch (3 panels)
- `.agents/gen/slices/D15-flight-feedback/D15-A1_report.md` — this report

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| Bolt/slug art re-cut restoring 4:1/6:1 | staged (generation budget) | D15_BRIEF §10 |
| Anti-flam assets pass | staged | D15_BRIEF §10 |
| S19 T1–T4/T6–T7 re-tick after playtest round 2 | owner tick (M6 stance) | 09 P3 block |
