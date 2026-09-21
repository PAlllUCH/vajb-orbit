# Wave Weapon FX & audio wiring — task brief

Law, in order: `AGENTS.md`, `docs/CONTRACTS.md` (v1.2), `docs/gameplay/18_engine_spec.md`
(§4.1/§4.2 rows), `docs/design/FX_SPEC.md` (§0 the void-black/additive emission rule, §1.2
muzzle flash, §1.4 explosion, §1.6 the engine-drawn beam, §7 the Phase G inventory),
`docs/design/AUDIO_SPEC.md` (§8 cue names), `docs/design/ASSET_WIRING_HANDOFF.md` (§1.1–§1.2
the cue table and the variant pools, §3 the FX sheet rules), this brief,
`.agents/gen/WAVEBOARD.md`. Evidence: `.agents/gen/owner_playtest_findings_20260921.md`.

## The owner's report (2026-09-21)

> "Yes shooting works but there is no sprite and no sound to them."

## What is measured (this report, before the wave)

| Fact | Evidence |
|---|---|
| A projectile is an `Area2D` with a `CollisionShape2D` and **nothing else** — no sprite, no trail, no audio | `game/projectile.gd:622` (`add_child(_shape)`) is the only child the shot builds; the file references no `Audio` and no texture |
| Weapon beams have **no visual at all** and no sound | `game/weapons.gd:520` `_beam_started()` only emits `shot_fired`; `grep -n "_draw\|Line2D\|beam_"` finds no renderer |
| `shot_fired` has **no shipped consumer** | `grep -rn "shot_fired"` → the signal's own declaration, two emits, and the C2 probe |
| Only the mining laser makes any sound | `game/mining_laser.gd:224` plays `CHIP_CUE`; its beam line is engine-drawn per FX_SPEC §1.6 |
| Exactly **one** `assets/fx/` reference exists in the whole project | `grep -rn "assets/fx/"` → `ui/screens/main_menu.tscn` (`fx_ember_pulse.png`) |
| The assets are all on disk and unused | 32 `assets/fx/*.png` including `fx_laser_bolt`, `fx_missile_trail`, `fx_muzzle_flash` (+ `_f1`–`_f4`), `fx_explosion` (5-frame), `fx_secondary_explosion`, `fx_arc_spark`, `fx_shield_ripple`, `fx_shield_break`, `fx_smoke_plume`, `fx_mining_beam` (4-frame); `assets/audio/sfx/` carries `sfx_weapon_laser_01..04`, `sfx_weapon_cannon_01..03`, `sfx_weapon_rocket_01/02_warhead`, `sfx_weapon_explosion_01/02`, `sfx_impact_{rock,hull,shield_hit,shield_loop}*`, `sfx_mining_beam_01`, `sfx_mining_chip_01..04` |
| The wiring contract already exists | `ASSET_WIRING_HANDOFF.md` §1.1/§1.2 give the exact cue names, the round-robin pools and their pitch/volume ranges, and the rocket's +80 ms warhead layer; §3 gives the sheet frame counts and the `animation_finished → queue_free()` rule; FX_SPEC §0 requires RGB-on-void-black sheets to be drawn **additive** |

So this is a **wiring** wave, not a generation wave: no new art, no new sound, no new
balance number. Coder workers never touch `assets/**`; they reference the shipped paths.

## Owner rulings this wave executes

1. **Fire must look and sound like fire** — muzzle flash, the bolt/trail sprite, the beam
   line, and the family's cue, with the handoff's pools.
2. **Hits must read** — the impact cue per target kind and the explosion/arc/shield FX on
   the hit, which is the other half of "shooting does nothing".
3. Nothing here changes damage, cadence, range, Energy or ammo. Any number the wiring needs
   beyond the handoff's ranges is proposed in the report, never invented silently.

## Worker table

| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| **F1** | coder — fire & travel | `vajb-orbit/game/weapons.gd,vajb-orbit/game/projectile.gd,vajb-orbit/game/mining_laser.gd,vajb-orbit/autoload/audio_manager.gd,vajb-orbit/game/fx.gd,vajb-orbit/tests/` | A projectile **sprite** (bolt vs missile trail by `kind`), a **muzzle flash** at the muzzle on each release (the 4-frame sheet, additive), a **beam line** for the instant families (engine-drawn like `mining_laser.gd:227`, or a sprite if FX_SPEC §1.6 sanctions it), the family **fire cue** with the handoff's pools (`sfx_weapon_laser_{01..04}` round-robin ±10 % pitch / −3..0 dB, cannon tiers, rocket + its warhead layer at +80 ms), and the mining **beam loop** cue alongside the existing chip cue. Add the cue-pool API to `AudioManager` only if the pools cannot be reached through `play_sfx` — the handoff §1.2 records that gap explicitly. A shared FX helper (`game/fx.gd`) for "spawn a sheet, play it additively, free on `animation_finished`" is the seam F2 reuses. One test per wired event. |
| **F2** | coder — impact & death | `vajb-orbit/game/projectile.gd,vajb-orbit/game/impact.gd,vajb-orbit/game/player_ship.gd,vajb-orbit/game/npc_ship.gd,vajb-orbit/game/asteroid.gd,vajb-orbit/tests/` | The hit's other half: the **impact cue** per target kind (`sfx_impact_rock`, `sfx_impact_hull`, `sfx_impact_shield_hit`, `sfx_impact_shield_loop` while a shield holds), the **explosion** (5-frame) on a hull's death and the **secondary explosion**, `fx_arc_spark` for the railgun's hit, `fx_shield_ripple`/`fx_shield_break` on the shield, `fx_smoke_plume` at low hull, and `sfx_weapon_explosion` from its pool. Uses F1's `game/fx.gd` read-only; if it must extend it, say so in the report and the reviewer checks the seam. One test per wired event. |
| **F3** | coder — reviewer (**mandatory**) | `vajb-orbit/tests/,vajb-orbit/tools/` | Verifies every wired path by measurement: each event spawns its node/plays its cue (a deterministic headless probe counting spawns and capturing `play_sfx` calls through a stub, since audio cannot be heard headless), each `res://assets/fx/...` path resolves, each cue resolves through `AudioManager`'s own lookup, no damage/cadence/range/Energy/ammo number moved, and the additive blend mode is set on every void-black sheet. Tiers HIGH/MED/LOW; LOW → `.agents/gen/LOW_BACKLOG.md`. |
| **F4** | coder — fixer | per F3's per-finding sets | Only if F3 leaves HIGH or MED. One pass, then F3's probe re-run. |

Run order: **F1**, then **F2**, then **F3**, then **F4** if needed. F1 and F2 both touch
`game/projectile.gd`, so they are sequential by design, not parallel.

## Hard rules

- `VAJB_WORKER_FILES` exactly as tabled; the hook denies writes outside it (and denies
  absolute paths on this host — use workspace-relative paths).
- No `assets/**` edits: the art and audio are the graphics lane's and already shipped.
  A missing asset is a report item, never a regeneration.
- FX sheets are **RGB on void black** for additive blending (FX_SPEC §0) — a wiring that
  assumes alpha will render a black box; the reviewer checks the blend mode.
- Bounded Godot runs only (`--quit-after N`, stdout to a log the worker reads). Audio cannot
  be verified by ear headless: prove it by capturing the `play_sfx` call and by resolving the
  cue through `AudioManager`'s own loader.
- The gate is `godot --headless --path vajb-orbit res://tests/headless_runner.tscn
  --quit-after 1200`, measured at **passed=236 failed=0** before this wave. Grow the count;
  never shrink it.
- No theme, no `project.godot`, no `addons/**`, no `docs/**` (a doc tick for
  `ASSET_WIRING_HANDOFF.md`'s status column is a later pass).

## Close-out (orchestrator)

Gate re-run; `python3 staging/verify_wave.py verify --baseline weapon_fx_start --forbidden
project.godot --expect-reports <the wave's reports> --tests`; WAVEBOARD updated; wave-boundary
commit; report to the owner with what now renders and what now sounds, per family.
