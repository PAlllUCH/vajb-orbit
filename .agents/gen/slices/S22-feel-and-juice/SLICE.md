---
slice: S22
phase: P3
lane: code
status: draft
gate_baseline: "914/0"
---

# S22 — Feel, juice & balance

## Goal
"Hits must read" becomes true everywhere: every landed hit marks, rams spark,
mining chips spray, the muzzle flash sits at the nose, breach malfunctions show
on the HUD, and audio stops flamming. The flight-feel tick rows land as the
owner ruled them in D15's sheet, and the S19 balance rows take their first
calibration pass.

## In scope
- Hit/ram/mining feedback (L28/L56/L52/L65): `game/weapons.gd:1839 (_deliver)`,
  `game/projectile.gd` (`hit_landed`, `spawn_chip_sparks`),
  `game/player_ship.gd:472-492`, `game/npc_ship.gd:538-548`,
  `game/mining_laser.gd:174 (_play_chip)`, `ui/hud/hud.gd:581 (hit_marker)`
- Muzzle anchor (L51): `game/weapons.gd:285 (FLASH_MUZZLE_PX)`, `:1445,1664`
- Quadrant feed (L241): `ui/hud/hud.gd:835-840 (_push_status)` →
  `ui/hud/ship_status_screen.gd:843 (set_quadrants)`
- Audio anti-flam (L54) + mine cue (L48): `autoload/audio_manager.gd:352
  (play_pool)`, `game/weapons.gd` FIRE_CUES; one CC0 cue via `assetmcp` into
  `vajb-orbit/assets/audio/` (manifest + CREDITS rows)
- Low-hull arcs (L55): `game/projectile.gd` plume seam (the second emitter)
- Flight feel (L25/L39/L103/L182 + CONTRACTS §22 T3): `game/projectile.gd:68,74`,
  `game/npc_ship.gd:695-709`, `game/player_ship.gd:873-884 (release)`,
  `_lateral_damp` — **as D15's owner-ticked sheet rules**, defaults in §11
- Repairs one figure (L168/L244, R-S22-1): `game/repairs.gd:64-65,89-90,107-108`,
  `ui/station/repairs_panel.gd (_refresh_all)`
- Balance rows (L242/L169/S19 T1–T7, R-S22-2/3/4): `game/player_state.gd`
  (`_charge_quadrant` spill branch), `game/game.gd` (`_seed_ammo` family pack —
  disposition only, tick M7 keeps the per-cell model)
- Ammo label (L70): `ui/hud/hud.gd:1488 (_on_weapon_changed / _refresh_weapon)`
- `tests/test_s22_feel.gd` — new suite (A1–A12)

## Out of scope
- `game/damage.gd` and the ctx contract (byte-identical), `docs/` (read-only
  except `CONTRACTS.md`, R1's), `game/module_catalog.gd` (S23's)
- L57's bolt/slug elongation (D15's tick — re-cut art or accepted deviation)
- L129's two index spaces (stays documented-not-unified unless the owner rules)
- L49's laser_04 trim (the audio-lane pass)

## Acceptance criteria
See `S22_BRIEF.md` §6 (A1–A12), each probe- or gate-provable.

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S22-B1 | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/autoload/audio_manager.gd, vajb-orbit/assets/audio/, vajb-orbit/tests/, .agents/gen/slices/S22-feel-and-juice/S22-B1_report.md` | `S22_BRIEF.md` |
| S22-R1 | `vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S22-feel-and-juice/S22-R1_review.md` | `S22_BRIEF.md` |
| S22-F1 | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/autoload/audio_manager.gd, vajb-orbit/assets/audio/, vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S22-feel-and-juice/` | `S22_BRIEF.md` |

## References
- `docs/gameplay/09_ship_slots_modules.md` **2026-09-27 P3 block** (R-S22-2/3/4,
  ticks M5/M6/M7) + §3.3's 2026-09-26 amendment (S19's P1–P8)
- `docs/gameplay/01_economy_core.md` **2026-09-27 P3 block** (R-S22-1, tick M4)
- `docs/gameplay/18_engine_spec.md` §3.1/§3.2/§3.4, §4.2, §4.5 (read-only)
- `docs/design/FX_SPEC.md` §1.6/§7.1/§7.3 · `AUDIO_SPEC.md` §4.1/§8 (D15 amends)
- `docs/CONTRACTS.md` §22/§23 (flight feel) — R1 lands the ticked values here
- `slices/D15-flight-feedback/D15-A1_report.md` — **the tick sheet this wave
  implements** (do not dispatch S22 before it exists)

## Carries forward
- L57 → D15's tick (art or accept). L129 stays documented. L49 → audio lane.
- The L229-class rule binds every probe in this wave (scratch stores only).
