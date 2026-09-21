# F2 report — impact and death feedback (weapon FX & audio wave, 2026-09-21)

Brief: `.agents/gen/weapon_fx_wave_task.md` (worker F2, `VAJB_WORKER_FILES` =
`game/projectile.gd`, `game/impact.gd`, `game/player_ship.gd`, `game/npc_ship.gd`,
`game/asteroid.gd`, `tests/`). Nothing under `assets/`, the theme, `project.godot`,
`addons/` or `docs/` was touched; no damage, cadence, range, Energy or ammo number was
moved (the only removed line in `projectile.gd` is `_deliver(target, …)` becoming
`_deliver(sink, …)`, the sink hoisted so the shield read and the delivery agree).

Evidence: `.agents/gen/weapon_fx_f2_probe.txt` (a real `game.tscn` run, one line per
event, headless and self-quitting) and the gate (`passed=271 failed=0`, measured at
`passed=258 failed=0` after F1, so +13 tests, none removed). Commands:

```
~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_f2_weapon_fx.tscn --quit-after 600
~/.local/bin/godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
```

## Asset + cue per wired event

| Event | Asset (shipped path) | Geometry | Cue (AUDIO_SPEC) |
|---|---|---|---|
| Shot lands on a rock | — | — | `sfx_impact_rock` (S4's rock row; a plain file, no pool) |
| Shot lands on a hull, shields down | — | — | `sfx_impact_hull` → a take of F1's `_01.._05` pool |
| A shield absorbs a hit | `res://assets/fx/fx_shield_ripple.png` | `Rect2(394,379,1240,1212)`, 64 units across, scale 0 → 1.5× over 0.3 s + alpha fade | `sfx_impact_shield_hit` → a take of F1's `_01.._09` pool |
| A shield keeps holding | — | — | `sfx_impact_shield_loop` (S6's bed) held through `AudioManager.play_loop` |
| The hit empties the shield | `res://assets/fx/fx_shield_break.png` | 4 frames (row 1 of the 4-object row), 64 units, 10 FPS | the same S5 take; the bed goes out |
| The railgun's slug lands (hull or rock) | `res://assets/fx/fx_arc_spark.png` | 4 frames 2×2 in reading order, 40 units, 20 FPS | that hit's S4 cue (the arc is the signature, not the sound) |
| A hull dies (player or NPC) | `res://assets/fx/fx_explosion.png` + `res://assets/fx/fx_secondary_explosion.png` | 5 frames at 15 FPS, 96 units; 4 frames at 15 FPS, 48 units | `sfx_weapon_explosion` → a take of `_01/_02` |
| A rocket or mine detonates | `res://assets/fx/fx_explosion.png` | 5 frames, 96 units | `sfx_weapon_explosion` |
| A rocket is shot down in flight | `res://assets/fx/fx_explosion.png` | 5 frames, 96 units | `sfx_weapon_explosion` |
| A hull falls below 25 % | `res://assets/fx/fx_smoke_plume.png` | `Rect2(641,199,755,1580)`, `GPUParticles2D`, puffs read 10×20 … 21×44 units | none (FX_SPEC 7.1 pairs the damage state with no cue) |

Every sheet is composited **additively** (`CanvasItemMaterial.BLEND_MODE_ADD`, FX_SPEC
§0) through F1's `fx.gd` — the probe prints `additive=true` on each. The regions were
measured off each shipped master's ink (the objects are found by masking the ink, never
by cutting on a divider); the master's objects do not respect a nominal grid, which the
measurement showed for `fx_explosion` (its five objects straddle the 2×3 cell midlines)
and for the four dark debris frames of the shield break.

## What was added, by file

- **`game/projectile.gd`** — the hit site's half, in one section: `IMPACT_CUES`
  (rock/hull/shield) with `impact_cue_of`, `SHIELD_LOOP_CUE`, `BLAST_CUE`,
  `LOW_HULL_FRACTION` (0.25, FX_SPEC §1.8/§7.1's own line) and the `FEEDBACK` table
  (explosion, secondary, arc, shield break, ripple, plume). Static spawns
  (`spawn_explosion`, `spawn_secondary_explosion`, `spawn_arc_spark`,
  `spawn_shield_break`, `spawn_shield_ripple`, `spawn_smoke_plume`,
  `clear_smoke_plume`, `spawn_hull_death`) all build through `fx.gd`;
  `play_impact`/`play_blast`/`hold_shield`/`release_shield` go through
  `AudioManager.play_pool`/`play_loop`. The hooks: `_hit_rock` (rock cue),
  `_hit_body` (shield read once into `sink`, shield cue + ring, then the bed or the
  shatter after the damage lands), `_shot_down` and `_detonate` (the blast).
- **`game/player_ship.gd`** — `_state.died` is connected in `setup` and released in
  `_release_state`; `_on_hull_death` spawns the death blast and stops the shield bed,
  and `_note_damage_state` raises/drops the plume off `hull_changed`.
- **`game/npc_ship.gd`** — the same plume in `set_hull`, the same blast in `_die`.
- **`game/impact.gd`, `game/asteroid.gd`** — **untouched.** No event in the brief's list
  lands there: the push physics is not a sound, and a rock's hit is played by the shot,
  not by the rock.
- **`game/fx.gd`** — **not edited** (read-only, as the brief requires): the sheets go
  through `Fx.play_once`/`display`/`sheet_frames`/`scale_for`/`frame`/
  `additive_material`, and §1.5's alpha half uses `fade_and_free` (F1's item 10 seam).
  It needed no extension; the two things the helper does not cover are kept at the call
  site instead — the ripple's 0 → 1.5× **scale** track (a tween on the node the helper
  returned) and the plume's particle emitter (FX_SPEC 7.3's `GPUParticles2D`, built from
  the helper's own `frame`/`additive_material`). Say the word if the seam should own
  either; both are one small static in `fx.gd` away.
- **`tests/test_weapon_fx_f2.gd` (new, 13 tests)** — one per wired event: the cue table,
  the rock cue, the hull pool, the shield pool + held bed, the ring's placement/collapsed
  start/additive blend, the break + bed out, the railgun's arc beside a bolt control,
  an NPC's death, the player hull's death, a detonation, the low-hull plume in both hull
  kinds (with the puff size), and that every sheet, region and cue resolves. Nothing
  awaits a frame.
- **`tests/probe_f2_weapon_fx.gd` + `.tscn` (new)** — the measured evidence above.

## Decisions the brief/specs left open (each a one-line reversal if the owner disagrees)

1. **The shield bed's hold.** "while it holds" is read as: an absorbed hit raises S6's
   bed and it stays up until the shield drops (the break) or the hull leaves/dies. No
   hold-window number exists in any spec, so none was invented. Consequence: after a
   shield's first absorbed hit the bed keeps sounding until the shield goes down.
2. **A hit that both absorbs and collapses** draws the ring *and* the shatter (the hit
   was absorbed; the pool then emptied). The alternative is the shatter alone.
3. **The blast covers every destruction**, not only a hull's death: `_detonate`
   (rocket/mine warhead, decoy arrival) and a rocket shot down in flight
   (`_shot_down`, F1's open item 11) take the same §1.4 explosion and
   `sfx_weapon_explosion`. FX_SPEC §1.4's own purpose row pairs the sheet with "S3 rocket
   detonation, S4 impacts", and AUDIO_SPEC S3 names that cue as the warhead bang, so this
   is the spec's pairing rather than a new cue. A hull's death adds the secondary burst.
   A warhead that lands on a *shielded* hull therefore plays S5's take and the blast
   together (the shield absorbed it, then it went off) — two cues on one event, by design.
4. **The secondary burst has no timing in any spec** (ASSET_EXPANSION_SPEC §7 lists the
   file only), so both it and the explosion are spawned on the death frame at the same
   point; its own 4 frames and smaller read make the layering.
5. **The railgun arcs on any hit**, rock or hull — the brief says "the railgun's hit"
   without a target, and the kind (`slug`) is what carries it.
6. **The plume's numbers** (amount 16, lifetime 1.4 s, preprocess 0.6, radius 14 u,
   spread 25°, 8–24 u/s, scale 0.5–1.1× of the row's 40-unit read) are the wiring's own;
   FX_SPEC 7.2 states the look and 7.3 the node, neither a rate nor a size.
7. **World sizes** where the spec states none, measured against the shipped Vanguard side
   view (59 × 30 world units at the scene's own 0.0663 sprite scale): explosion 96,
   secondary 48, arc 40, shield break 64, ripple 64, plume 40.

## Open items (F1's four respected, plus what this pass found)

1. **F1's four are untouched, not papered over.** The mine family still has no *drop*
   cue (the deployable family is absent from AUDIO_SPEC §8); `sfx_weapon_laser_04` is
   still a pool member; cannon tier 3 still serves no family; the muzzle is still the
   component's origin. Nothing here assigns a cue or a number to any of them.
2. **The mine's *detonation* now uses the generic explosion fill** (`sfx_weapon_explosion`)
   as every other destruction does. That is AUDIO_SPEC §8's own stated purpose for the
   cue ("generic explosion fills") and not a deployable-family cue, but it is the one
   place where a mine makes a sound — flagging it so it cannot read as F1's item 1 being
   overruled by accident.
3. **The manager owns one loop voice.** S6's shield bed and S7's mining bed share
   `AudioManager._loop_player`, so a mining player who takes a shielded hit has the beds
   replace each other frame by frame (the shaft re-asks every frame). `release_shield`
   only stops the bed it started, so it can never silence the shaft — but the fight is
   real and needs either a second loop voice or a priority rule in `audio_manager.gd`,
   which is F1's file set, not F2's.
4. **A beam that shoots a rocket down is silent.** `weapons.gd._beam` calls
   `fizzle()` directly, bypassing `_shot_down`, so a beam-killed rocket draws no blast
   while a projectile-killed one does. One line at that call site; `weapons.gd` is not in
   F2's file set.
5. **Beam contact has no hit feedback.** The instant families (laser/plasma, and F1's
   railgun beam if it ever becomes one) deliver per-frame damage through
   `weapons.gd._apply_beam`, which is outside F2's set; a per-frame cue there would
   machine-gun the bus, so it wants a sustained-contact design (the mining shaft's own
   bed is the model), not a hit cue.
6. **A body-body ram plays no impact cue.** `PlayerShip._on_hull_body_entered` /
   `NpcShip._on_body_entered` charge section 4.2 item 6's collision damage on both sides
   with no sound or spark. The brief's cue list is the *shot's* hit site, so this was left
   alone; if a ram should read, the cleanest place is the contact handler in each hull
   (`sfx_impact_hull`/`sfx_impact_rock` plus a spark at the contact).
7. **FX_SPEC 7.1's low-hull arcs are not wired.** The brief names the plume for the damage
   state, so `fx_arc_spark` is wired to the railgun's hit only. 7.1 also asks for
   "intermittent electrical arcs" on a sub-25 % hull; that wants a cadence number
   (an interval) no spec gives, so it is reported rather than invented.
8. **`sfx_impact_rock` is the one impact cue with no variant pool** (handoff §1.2 lists
   takes for hull and shield only), so it never varies take to take. Left as shipped.
9. **AUDIO_SPEC §4.1's anti-flam rules are not implemented**: no 30 ms minimum between
   triggers of one cue and no per-pool voice cap (F1's `play_pool` cycles takes and
   applies the stated pitch/volume ranges only). Under a sustained shield barrage the S5
   transient can stack; that is the pool's business, not the hit site's.
10. **Headless exit warnings** are unchanged in kind from F1's report and no worse: the
    full gate ends with 18 leaked `ObjectDB` instances / 8 leaked resources, against
    20/8 measured on the pre-F2 tree, so the count moved down with the extra emitters and
    tweens rather than up. Measured as an engine artefact of the dummy audio driver, not a
    wiring defect; the gate's `passed=271 failed=0` is unaffected.
