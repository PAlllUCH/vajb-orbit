---
slice: S22
phase: P3
lane: code
status: in-progress
gate_baseline: "941/0"
---

# S22 — Feel, juice & balance

## Goal
"Hits must read" becomes true everywhere: every landed hit marks, rams spark, the
muzzle flash sits at the nose, breach malfunctions show on the HUD, and audio
stops flamming. The flight-feel rows land exactly as the owner ticked them in
D15's sheet (2026-09-29), and the S19 balance rows take their first calibration
pass.

## In scope
- Hit/ram feedback (L28/L56): `game/weapons.gd:1839 (_deliver)` +
  `game/projectile.gd` (`hit_landed`), `game/player_ship.gd:1147-1210`,
  `game/npc_ship.gd:546-600`, `ui/hud/hud.gd:581 (hit_marker)`,
  `game/game.gd` (retire the poll)
- Muzzle anchor (L51): `game/weapons.gd:266-285 (FLASH_MUZZLE_PX)`, `:1445`
- Mining chip (L52/L65 — **verify only**, shipped `mining_laser.gd:214-225`)
- Low-hull arcs (L55 — **verify only**, shipped `player_ship.gd:207-213,1787-1810`)
- Quadrant feed (L241): `ui/hud/hud.gd:835 (_push_status)` →
  `ui/hud/ship_status_screen.gd:843 (set_quadrants)`
- Audio anti-flam (L54) + mine cue (L48) + laser_04 drop (L49):
  `autoload/audio_manager.gd:54-64 (CUE_POOLS), :352 (play_pool)`,
  `game/weapons.gd` FIRE_CUES; one CC0 cue via `assetmcp` into
  `vajb-orbit/assets/audio/sfx/` (+ `generation_log_audio.md` + `CREDITS.md`)
- Flight feel (L25/L39/L103/L182 + §22 T3): `game/projectile.gd` (the two fuse
  consts), `game/npc_ship.gd:761-776` (the mirrored midline drag),
  `game/player_ship.gd:1050-1066` (the ramp, kept) — **as D15's ticked sheet
  rules** (§11 of the brief)
- Repairs one figure (L168/L244, R-S22-1): `game/repairs.gd:62-120`,
  `ui/station/repairs_panel.gd:182-217`
- Balance rows (L242/L169/S19 T1–T7): `game/player_state.gd:337`
  (`_charge_quadrant`'s spill branch — the only code row; R-S22-3/R-S22-4 are
  dispositions)
- FX pins (FX-1/FX-2a–e/L57 — **verify only**, `game/projectile.gd`)
- Ammo label (L70): `ui/hud/hud.gd:1539 (_refresh_weapon)`
- Three suites: `tests/test_s22_feedback.gd`, `test_s22_audio.gd`,
  `test_s22_balance.gd`

## Out of scope
- `game/damage.gd` and the ctx contract (byte-identical), `docs/` (read-only),
  `game/module_catalog.gd` (S23's)
- L57's bolt/slug re-cut art (accepted deviation; the re-cut stays staged)
- L129's two index spaces (stays documented-not-unified unless the owner rules)
- L49's returning trim (the audio-lane pass; only the drop ships here)

## Acceptance criteria
See `S22_BRIEF.md` §6 (A1–A14), each probe- or gate-provable. A4/A8/A13 and the
disposition halves of A9/A11 are **verify-only** (amendment ruling 3).

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S22-B1 | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/tests/, .agents/gen/slices/S22-feel-and-juice/S22-B1_report.md` | `S22_BRIEF.md` |
| S22-B2 | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/autoload/audio_manager.gd, vajb-orbit/assets/audio/, vajb-orbit/tests/, .agents/gen/slices/S22-feel-and-juice/S22-B2_report.md` | `S22_BRIEF.md` |
| S22-B3 | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/tests/, .agents/gen/slices/S22-feel-and-juice/S22-B3_report.md` | `S22_BRIEF.md` |
| S22-R1 | `vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S22-feel-and-juice/S22-R1_review.md` | `S22_BRIEF.md` |
| S22-F1 | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/autoload/audio_manager.gd, vajb-orbit/assets/audio/, vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S22-feel-and-juice/` | `S22_BRIEF.md` |

## References
- `docs/gameplay/09_ship_slots_modules.md` **2026-09-27 P3 block** (R-S22-2/3/4,
  ticks M5/M6/M7) + §3.3's 2026-09-26 amendment (S19's P1–P8)
- `docs/gameplay/01_economy_core.md` **2026-09-27 P3 block** (R-S22-1, tick M4)
- `docs/gameplay/18_engine_spec.md` §3.1/§3.2/§3.4/§4.5 + §13's **Rocket fuze**
  row (landed 2026-09-29 by the owner's grant)
- `docs/design/FX_SPEC.md` §8 (owner-ticked) · `AUDIO_SPEC.md` §4.1 + §8.6
- `docs/CONTRACTS.md` §22 (T3 struck) / §23.5 (the ramp row) / §14 (the NPC-brake
  disclosure) — all landed in the pre-flight commit by the developer
- `slices/D15-flight-feedback/D15-A1_report.md` — **the ticked sheet this wave
  implements**

## Carries forward
- L57 → accepted deviation. L129 stays documented. L49 → audio lane.
- L250/L251 closed at this wave's open. The L229-class rule binds every probe
  (scratch stores only).
