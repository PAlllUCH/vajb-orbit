# F3 report — the mandatory review of the weapon FX & audio wave (2026-09-21)

Reviewer: **F3** (no fix was made; this is measurement only). File set
`vajb-orbit/tests/, vajb-orbit/tools/`; the only files written are
`tests/probe_f3_weapon_fx.gd`, `tests/probe_f3_weapon_fx.tscn`,
`.agents/gen/weapon_fx_f3_probe.txt`, this report, and an append to
`.agents/gen/LOW_BACKLOG.md`. No production file, no asset, no doc was touched.

Law read in this order: `.agents/gen/weapon_fx_wave_task.md` (the wave's brief),
`docs/CONTRACTS.md`, `docs/gameplay/18_engine_spec.md` §4.1/§4.2/§13,
`docs/design/FX_SPEC.md` §0/§1.1/§1.2/§1.4/§1.5/§1.6/§1.8/§2/§7,
`docs/design/AUDIO_SPEC.md` §4.1/§4.2/§8, `docs/design/ASSET_WIRING_HANDOFF.md`
§1.1–§1.3/§3, `.agents/gen/WAVEBOARD.md`, then F1's and F2's reports and probes.
Nothing below is taken from either report: every claim is re-measured.

## 0. Verdict

**One HIGH, three MED, eleven LOW.** The HIGH is the one place where the wave's own
owner ruling 2 ("hits must read") is still unmet — and it is met by the wave's
briefed deliverables everywhere else.

| # | Tier | Finding |
|---|---|---|
| **H1** | **HIGH** | The instant families' **hit site has no feedback at all**. The launched ship's own fit is measured as `boot game=true guns=true stub_installed=true launched_fit=[&"laser"] selected=laser`, and a laser that lands on a hull plays no S4/S5 cue and draws no ring/arc (`ITEM beam_hit … damage_landed=true fx_spawned=0 cues=play_pool(sfx_weapon_laser)`). The same seam makes a **held beam nearly silent**: 0.50 s of continuous fire earns one 0.064–0.092 s cue and one flash (`ITEM beam_hold ticks=10 seconds=0.50 flashes=1 cues=play_pool(sfx_weapon_laser)`). Fix: one call site, `weapons.gd._apply_beam`'s hull branch (F1's file set) — call `Projectile.play_impact` + `Projectile.spawn_shield_ripple` behind a per-contact rate guard, and give the hold a sustained bed on the mining-laser model. Owner may downgrade to MED: every *briefed* deliverable is present and correct, and neither worker's file set owned this seam. |
| **M1** | MED | The cannon's cue is **5.8× its own cadence** (3.460 s take against a 0.600 s interval) and the pool has 4 voices, so a sustained burst cuts its own tail every 4 shots. Fix: a same-cue "steal its own oldest voice" rule in `play_pool`, or an audio-lane retrim. Owner-decidable. |
| **M2** | MED | The manager owns **one loop voice**, so a miner who takes a shielded hit never hears S6's bed (`ITEM loop_voice shield=sfx_impact_shield_loop then_beam=sfx_mining_beam after_release=sfx_mining_beam`). Fix: a second loop voice or a priority rule in `audio_manager.gd`. |
| **M3** | MED | A **beam-killed rocket is silent** (`ITEM beam_shotdown rocket_spent=true ballistic_cues=play_pool(sfx_weapon_laser)`) where the projectile-killed route plays the blast (`EVENT shot_down … cues=play_pool(sfx_weapon_explosion)`). Fix: one line in `weapons.gd._fire_beam`'s projectile branch. |
| L48–L58 | LOW | Appended to `.agents/gen/LOW_BACKLOG.md` (mine cue, laser take 04, cannon tier 3, muzzle origin, chip sparks, rock pool, §4.1 anti-flam, low-hull arcs, no ram cue, bolt/slug elongation, the mine's invented crop, the wiring's own sizes/rates). |

## 1. The gate, measured by me

```
~/.local/bin/godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=271 failed=0
```

- Pre-wave baseline in the brief: `passed=236 failed=0`. F1 +22, F2 +13 → 236 + 35 = **271**.
- Cross-check by hand: 22 `test_*.gd` suites, `grep -c "^func test_"` sums to **271**;
  `test_weapon_fx_f1.gd` has 22, `test_weapon_fx_f2.gd` has 13. `git status` shows both
  as new files and **no** existing test modified or deleted → the count grew, nothing shrank.
- Exit warnings: `WARNING: 18 ObjectDB instances were leaked at exit` / `ERROR: 8 resources
  still in use at exit`. F1 measured 20/8 before F2, so the count **fell**; the dummy audio
  driver never mixes the streams. Not a wiring defect (see §6).

## 2. The probe (my own, not F1's or F2's)

```
~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_f3_weapon_fx.tscn --quit-after 900
```

Raw log: `.agents/gen/weapon_fx_f3_probe.txt` (136 `[F3]` lines, exit 0). It is
**deterministic**: three consecutive runs differ only in the probe's own asteroid's random
look variant (`env_asteroid_M1/M2/M3`, rolled by `asteroid.gd`, outside this wave's files);
every wiring line is byte-identical across runs.

What it does that neither worker's probe does:

- **Captures audio through a stub.** The real `AudioManager` autoload is detached from the
  tree (`root.remove_child`, kept alive, never freed) and a `StubAudio` answering to the name
  `AudioManager` is added in its place. The production code reaches the manager by node-name
  lookup, so every `play_sfx` / `play_pool` / `play_loop` / `stop_loop` the wiring makes is
  recorded as `{method, cue, take}`. The real manager is restored for the resolution passes.
  `boot game=true guns=true stub_installed=true launched_fit=[&"laser"] selected=laser` proves
  the swap landed **and** records what the launched ship actually carries (see H1).
- **Falsification controls**, so a green line means something:
  `CONTROL invented_resource=false invented_file=false real_resource=true real_file=true`
  (an invented `fx_laser_bolt_f1.png` resolves nowhere; the real master resolves twice) and
  `CONTROL alpha_reads_additive=false alpha_reads_alpha=true` (my additive detector says
  *false* for a `StandardMaterial3D` with `TRANSPARENCY_ALPHA`).
- **Two end-to-end passes**, so the wiring is not only measured through its private doors:
  a real railgun shot released by the component, flying 7 physics frames into a real rock
  (`E2E rock released=1 frames=7 shots_left=0 cues=play_pool(sfx_weapon_cannon,1),play_pool(sfx_impact_rock)`
  + `e2e_rock_fx node=arc … sheet=res://assets/fx/fx_arc_spark.png`), and the same into a real
  NPC that dies (`E2E hull … cues=…,play_pool(sfx_impact_hull),play_pool(sfx_weapon_explosion)`
  + `explosion`, `secondary`, `arc`).

## 3. Per event: what spawns, what it draws from, what it plays

Every line quoted here is verbatim from the probe log. `additive=true` means
`CanvasItemMaterial.BLEND_MODE_ADD`; `inside=true` means the region lies inside the master's
own 2048² canvas; `sheet=` is the `AtlasTexture`'s own `atlas.resource_path`.

### 3.1 Fire (F1)

| Family | Spawned | Cue captured | Blend | Frames from |
|---|---|---|---|---|
| laser | `flashes=1`, `shots=0`, `beam Beam visible=true width=5.0` / `BeamCore visible=true width=2.0` | `play_pool(sfx_weapon_laser)` | additive | flash `f1..f4` (all four files listed in `frame_paths`) |
| plasma | `flashes=1`, `shots=0`, beam visible | `play_pool(sfx_weapon_laser)` | additive | same |
| cannon | `flashes=1`, `shots=1 kind=bolt` | `play_pool(sfx_weapon_cannon,0)` | additive | `fx_laser_bolt.png` region `(194,604,1718,105)` → **world 64×4** |
| railgun | `flashes=1`, `shots=1 kind=slug` | `play_pool(sfx_weapon_cannon,1)` | additive | `fx_laser_bolt.png` region `(232,1189,1680,178)` → **world 96×10** |
| rocket | `flashes=1`, `shots=1 kind=rocket` | `play_pool(sfx_weapon_rocket)` | additive | `fx_missile_trail.png`, 4 regions, `frames=4 fps=12 loop=true` → world 22×5 |
| mine | `flashes=1`, `shots=1 kind=mine` | **`cues=none`** (`cue_of=` is empty) | additive | `fx_ember_pulse.png` region `(811,791,423,421)` → world 22×22 |

Per-family **exactly one** new flash for one released shot (`flashes=1` six times), so F1's
own item 8 is confirmed rather than accepted: the `flash=x6` in F1's log was that probe's
no-frames artefact, not a double spawn.

### 3.2 Impact and death (F2)

| Event | Spawned (counted) | Cue captured | Notes measured |
|---|---|---|---|
| rock | 1 (the rock's own `Look`; **no** weapon sheet) | `play_pool(sfx_impact_rock)` | a bolt on a rock is cue-only, by design |
| hull, shields down | **0** | `play_pool(sfx_impact_hull)` | cue-only |
| shield absorbs | 1 = `shield_ripple` | `play_pool(sfx_impact_shield_hit)` + `play_loop(sfx_impact_shield_loop)` | ripple starts collapsed: `scale=(0.00001, 0.00001)`; region `(394,379,1240,1212)`; `additive=true` |
| shield empties | 2 = `shield_ripple`, `shield_break` | `play_pool(sfx_impact_shield_hit)` + `stop_loop(sfx_impact_shield_loop)` | break `frames=4 fps=10 loop=false`, region `(63,752,356,457)` → world 43×56 |
| railgun slug lands | 1 = `arc` | `play_pool(sfx_impact_hull)` | **control**: a bolt on the same hull spawns 0 (`bolt_hit … nodes=-`) |
| NPC dies | 4 = `Hull`, `DamagePlume`, `explosion`, `secondary` | `play_pool(sfx_weapon_explosion)` | explosion `frames=5 fps=15` → world 89×79; secondary `frames=4 fps=15` → 29×28 |
| player dies | 4, same four | `play_pool(sfx_weapon_explosion)` | both hulls take one copy of the same table |
| rocket detonates | 1 = `explosion` | `play_pool(sfx_weapon_explosion)` | |
| rocket shot down in flight | 1 = `explosion` | `play_pool(sfx_weapon_explosion)` | |
| hull < 25 % | 2 = `Hull`, `DamagePlume` | none (FX_SPEC §7.1 pairs the state with no cue) | `amount=16 lifetime=1.4 emitting=true local=false pscale=0.0127..0.0278 pvel=8..24`; on recovery `plume_present=true queued_for_deletion=true` |
| mining shaft (S7) | — | `play_sfx(sfx_mining_chip_01),play_loop(sfx_mining_beam)` then `stop_loop(sfx_mining_beam)` on release **and** on `_exit_tree` | the chip stays on `play_sfx` (unchanged behaviour) while the bed uses the new loop voice |

### 3.3 The art is the shipped art

`SHEETS total=16 missing=0` — every master the wiring drew from resolves **and** exists as a
file on disk, printed with its real path:

```
SHEET path=res://assets/fx/fx_laser_bolt.png   resource=true file=true texture=true size=(2048.0, 2048.0) alpha=none disk=…/assets/fx/fx_laser_bolt.png
```

- All **thirteen** `res://assets/fx/*.png` files the wiring drew from are RGB (`alpha=none`, `detect_alpha()`
  = `ALPHA_NONE`) — which is exactly why FX_SPEC §0 requires additive and why an alpha wiring
  would have drawn a black box. The two sprites that are alpha (`ship_fighter_side.png`,
  `ship_vanguard_side.png`) are the hulls' own art, not FX.
- Every frame of every animated sheet is an `AtlasTexture` over one of those masters, with its
  region printed and `inside=true` — the closest-to-invented file in the whole run is the
  muzzle flash's four **whole-file** frames (`fx_muzzle_flash_f1..f4.png`, each 535×487,
  `alpha=none`), and all four exist on disk and are the files FX_SPEC §3 names.
- Every mixed or single-frame sprite's own blend is `additive=true`; the only
  `additive=false` nodes in the log are the asteroid's `Look` and the two hulls' own sprites,
  which is the contrast that proves the detector discriminates.
- Cross-check: every FX file the wiring draws from is `role = "plate"` in
  `asset-library/_library.json` ("Whole-frame plate, not a sprite: it has no object and no
  background to key"), which **is not** a naming-law violation here — FX_SPEC §2 makes the
  `AtlasTexture`-over-the-2K-master route the primary one and the per-frame split exports
  optional, and the library's own note is the reason why (an FX master has no keyable object).
  Two of those names are nevertheless spoken for elsewhere: `fx_mining_beam.png` is FX_SPEC
  §3's "Mining beam chip sparks" and `fx_ember_pulse.png` is its "Menu wreck ember pulse
  (MAIN_MENU_SPEC §5)" — see L52 and L58.

### 3.4 Every cue resolves through the manager's own loader

```
GATE unresolved_cues=0
RESOLVE cue=sfx_weapon_laser path=res://assets/audio/sfx/sfx_weapon_laser_01.ogg resource=true file=true stream=true
```

…one line per cue the events actually asked for (7 cues: the five weapon/impact cues plus
`sfx_impact_shield_loop` and `sfx_weapon_explosion`), each checked as: `cue_path()` non-empty
→ `ResourceLoader.exists` → `FileAccess.file_exists` → `load(...) is AudioStream`.

The pool table is complete and every take inside it is reachable:

```
POOLTABLE cues=6 takes=24
POOLROW cue=sfx_weapon_laser has_pool=true takes=4 resolvable=4 …
POOLROW cue=sfx_weapon_cannon has_pool=true takes=3 resolvable=3 …
POOLROW cue=sfx_impact_shield_hit has_pool=true takes=9 resolvable=9 …
POOL round_robin=[0, 1, 2, 3, 0, 1, 2, 3] pitch_out_of_range=0 volume_out_of_range=0
POOL tier_take=sfx_weapon_cannon_02_medium path=res://assets/audio/sfx/sfx_weapon_cannon_02_medium.ogg
POOL rocket_take=sfx_weapon_rocket_01 layers=[{ &"take": &"sfx_weapon_rocket_02_warhead", &"delay": 0.08 }]
```

The round-robin cycles 0→1→2→3→0…, the pitch and volume draws stay inside the handoff's
stated ranges (±10 %, −3..0 dB), the tier index picks the medium cannon take, and the
rocket's layer carries the handoff's +80 ms offset.

## 4. No balance number moved

Three independent checks, all clean:

1. **Const map, HEAD vs worktree, every changed `.gd` file** (weapons, projectile,
   mining_laser, player_ship, npc_ship, audio_manager): `CHANGED_VALUE: none`,
   `REMOVED: none` for all six; only new names were added (F1's/F2's FX, cue and pool
   constants). Script: a regex sweep over `^const NAME …` in both revisions.
2. **Every removed line that contains a digit** across the whole diff:
   `_sfx_next = (_sfx_next + 1) % _sfx_players.size()` (relocated verbatim from `_play` into
   `_take_sfx_player`, HEAD line 176 → worktree line 386) and six comment lines. **No
   numeric literal was removed anywhere.**
3. **The balance-bearing regions compared verbatim** (unified diff of the byte ranges):
   `weapons.gd`'s `const FAMILIES: Dictionary = { … }` (all six families: `dps`, `range`,
   `draw`, `speed`, `interval`, `alpha`, `arm`, `trigger`, `burst_on/off`) → **identical**;
   `projectile.gd`'s section-4.2 terms block (`KNOCKBACK_FRACTION`, `DEFAULT_MASS`,
   `HIT_RADIUS`) → **identical**.

`impact.gd` and `asteroid.gd` are untouched (F2's report says so and `git status` agrees).
No `assets/`, `project.godot`, `addons/`, theme or `docs/` file was touched by this wave: the
only non-game changes in the tree are `.agents/gen/*` and `docs/gameplay/08_ship_classes.md`,
all of which belong to the queued **P2-A** wave (per-slot per-class layouts), not to F1/F2.
The changed game files are exactly the union of F1's and F2's declared sets.

## 5. The cue-pool API kept `play_sfx`'s behaviour

- **The rotation is the old line, moved.** HEAD's `_play` picked
  `_sfx_players[_sfx_next]` then ran `_sfx_next = (_sfx_next + 1) % _sfx_players.size()`;
  the worktree's `_take_sfx_player()` contains that same expression and nothing else, plus a
  `pitch_scale = 1.0` / `volume_db = 0.0` reset. Those two properties were never set by any
  pre-wave path, so the reset is a no-op for every existing caller — and it is what stops a
  pooled take's variation leaking into the next plain cue.
- **Measured rotation**, five legacy cues in a row:
  ```
  PLAIN_SFX cue=sfx_station_breaker_on_01 last=sfx_station_breaker_on_01 voice=2->3 path=…/sfx_station_breaker_on_01.ogg
  PLAIN_SFX cue=sfx_ship_boost_01        last=sfx_ship_boost_01        voice=3->0 path=…/sfx_ship_boost_01.ogg
  PLAIN_SFX cue=sfx_ship_jump_01         last=sfx_ship_jump_01         voice=0->1 path=…/sfx_ship_jump_01.ogg
  PLAIN_SFX cue=sfx_mining_chip_01       last=sfx_mining_chip_01       voice=1->2 path=…/sfx_mining_chip_01.ogg
  PLAIN_SFX cue=sfx_weapon_laser         last=sfx_weapon_laser         voice=2->3 path=…/sfx_weapon_laser_01.ogg
  ```
  Those are the **only** `play_sfx` call sites in the project (station.gd ×3, launch_panel ×1,
  mining_laser ×1) plus the mining chip; every one resolves.
- **The exact-then-`_01` order survived the `_load_cue` → `_cue_path` refactor**, which matters
  for 49 `play_ui`/`play_music`/`play_ambience` call sites that depend on it:
  ```
  PLAIN_CUE bus=ui cue=ui_click   path=res://assets/audio/ui/ui_click.ogg          (exact)
  PLAIN_CUE bus=ui cue=ui_hover   path=res://assets/audio/ui/ui_hover.ogg          (exact)
  PLAIN_CUE bus=ui cue=ui_confirm path=res://assets/audio/ui/ui_confirm_01.ogg     (_01 fallback)
  PLAIN_CUE bus=music cue=mus_menu_theme path=res://assets/audio/music/mus_menu_theme_01.ogg
  ```
- `_cue_path` also returns `""` for an empty cue and for a bus with no directory, which is
  what the old `_load_cue` returned `null` for, so the dry case is unchanged too.
- F2 never edited `fx.gd` (as the brief requires) and needed no extension: it uses
  `scale_for`, `sheet_frames`, `frame`, `display`, `play_once`, `additive_material` and
  `fade_and_free` — i.e. F1's item 10 seam is **used**, not dead code.

## 6. The two workers' open items, re-measured, one list

| Source | Item | My measurement | Tier |
|---|---|---|---|
| F1-1 | the mine has no cue | `ITEM mine_drop cue_of= cues=none shots=1`; `FIRE_CUES` has no `mine` row; AUDIO_SPEC §8 has no deployable row and no asset exists. The mine does sound on detonation: `ITEM mine_detonation cues=play_pool(sfx_weapon_explosion)` | **LOW** (needs an owner ruling + an asset, not a wiring guess) |
| F1-2 | `sfx_weapon_laser_04` is a 1.244 s outlier | `DURATION cue=sfx_weapon_laser …03=0.064s,sfx_weapon_laser_04=1.244s` — 13.5× the other three | **LOW** (one line: drop the last `CUE_POOLS` take; ASSET_AUDIT C9's call) |
| F1-3 | cannon takes vs cadence, tier 3 unassigned | `DURATION cue=sfx_weapon_cannon …01=3.460s,02_medium=8.381s,03_long=17.974s`; `CADENCE family=cannon interval=0.60s`, `railgun interval=0.60s cue take=1`. 3.460/0.600 = 5.77 voices needed against 4 → **M1**. Tier 3 is reachable (`play_pool(…,2)`) but `fire_take_of` serves only 0 and 1, and no family is a charged shot → **LOW** | **MED (M1)** + **LOW** |
| F1-4 | the muzzle is the component's origin | `ITEM muzzle flash_pos=(-11.1028, -20.02617) mouth_local=(0.0, 0.0) shot_spawn_offset=(0.0, 0.0)` — the flash's **mouth** sits exactly on the origin *and* exactly on the shot's own spawn point, so moving it forward desynchronises the two | **LOW** (a contract change, not a bug) |
| F1-5/6 | sizes and the trail's rate are the wiring's own | measured: mine 22×22, trail 22×5 (widest frame), bolt 64, slug 96, explosion 96 (89×79 read), secondary 48 (29×28), arc 40 (40×21), break 64 (43×56), ripple 64, plume 40; trail `fps=12 loop=true`. FX_SPEC states a rate for the flash (20), the explosion (15), the arc (0.2 s) and the break (0.4 s) only | **LOW** |
| F1-8 | the flash-lifetime artefact | `flashes=1` for **every** one of the six families, i.e. one flash per released shot; the `x6` in F1's log is that probe's no-frames artefact | not a defect |
| F1-9, F2-10 | headless exit warnings | gate `18 ObjectDB / 8 resources` (F1 measured 20/8 pre-F2); probe `15 / 6`. The gate is green; no shipped code pretends to cure it | not a defect |
| F1-10 | `Fx.fade_and_free()` unused | used by F2 at `projectile.gd:1171` (the ripple's 0.3 s fade) | not a defect |
| F1-11 | undrawn feedback left to the hit site | **now wired** for every projectile event (§3.2), **except**: the beam's own hits (**H1**) and a rocket shot down by a beam (**M3**) | H1 + M3 |
| F2-2 | the mine's detonation uses the generic explosion fill | `ITEM mine_detonation cues=play_pool(sfx_weapon_explosion)` + `EVENT detonation`/`EVENT shot_down` all take it. AUDIO_SPEC §8 names `sfx_weapon_explosion` "generic explosion fills" and FX_SPEC §1.4 pairs the sheet with S3 detonations | not a defect |
| F2-3 | the manager owns one loop voice | `ITEM loop_voice shield=sfx_impact_shield_loop then_beam=sfx_mining_beam after_release=sfx_mining_beam` — the shaft takes the voice, and the shield's release cannot take it back (nor silence the shaft) | **MED (M2)** |
| F2-4 | a beam-killed rocket is silent | `ITEM beam_shotdown rocket_spent=true ballistic_cues=play_pool(sfx_weapon_laser)` — `_spent` is true (the kill landed) and no blast cue follows, against `EVENT shot_down … cues=play_pool(sfx_weapon_explosion)` for the projectile route | **MED (M3)** |
| F2-5 | beam contact has no hit feedback | `ITEM beam_hit hull=950.0->950.0 shield=600.0->598.5 damage_landed=true fx_spawned=0 cues=play_pool(sfx_weapon_laser)` — 1.5 damage landed (30 dps × 0.05 s) with zero cues and zero nodes; `ITEM beam_hold ticks=10 seconds=0.50 flashes=1 cues=play_pool(sfx_weapon_laser)` | **HIGH (H1)** |
| F2-6 | a ram plays no impact cue | `PlayerShip._on_hull_body_entered` and `NpcShip._on_body_entered` carry no audio call and no FX spawn (measured by reading both handlers and grepping `play_` across them) | **LOW** |
| F2-7 | FX_SPEC §7.1's low-hull arcs are unwired | `fx_arc_spark.png` is spawned only by the railgun's hit (`EVENT railgun_hit`, `e2e_rock_fx`); §7.1 wants "intermittent electrical arcs" with no interval in any spec | **LOW** (needs an owner number) |
| F2-8 | `sfx_impact_rock` has no pool | `POOLROW` has no rock row; `sfx_impact_rock_0{1..4}.ogg` are all on disk, 3 of them unreachable | **LOW** |
| F2-9 | AUDIO_SPEC §4.1's anti-flam rules | no time comparison, no voice cap and no "skip the last used variant" exist anywhere in `audio_manager.gd` (`grep -n "Time\.\|get_ticks\|min_interval\|cooldown"` → nothing); the round-robin happens to satisfy "no immediate repeats" for N > 2, and the stated pitch/volume spreads *are* applied | **LOW** |

F2's seven "decisions the brief left open" all re-measure as constants or as the spec's own
pairing, and I verified each rather than taking the note: the ring *and* the shatter on a hit
that both absorbs and collapses (`EVENT shield_break spawned=2`), the blast on every
destruction (`detonation`, `shot_down`, both deaths), the secondary on the death frame, the
arc on **any** slug hit (`EVENT railgun_hit` on a hull, `e2e_rock_fx` on a rock) with the bolt
as the negative control, and the shield bed holding until the shield drops.

## 7. What I could not verify, and how far each check reaches

- **The cue reached a speaker.** Impossible headless by construction: the probe proves the
  call, the cue name, the resolved path and the stream, and nothing about what a human hears.
  A live playtest is the only ear.
- **Volume/pitch on the actual bus.** The stub records the *request*; the real manager's
  ranges are verified numerically (`pitch_out_of_range=0`, `volume_out_of_range=0`) against
  `play_pool`'s returned plan, not measured at the mixer.
- **The mining bed's `_physics_process` acquisition ray**, which needs `get_global_mouse_position()`
  and therefore a display server. I drove the bed through `set_active` + `_physics_process`
  with a subclass that overrides `_acquire` only; `_draw_beam`, `_extinguish` and `_exit_tree`
  are the shipped ones. `_acquire` is untouched by this wave (`git diff` shows the mining
  laser's hunks are the cue door only).
- **Animation playback over time.** `--headless` runs no frames in the event passes, so
  "freed on `animation_finished`" is verified structurally (`play_once` connects
  `animation_finished` → `queue_free`) and the frame counts/rates are read off the
  `SpriteFrames`; the E2E passes do run frames, but only for flight.
- **The `Look` sprite's random variant** is the probe's only run-to-run variance; it belongs
  to `asteroid.gd`'s look roll, not to this wave.

## 8. Raw commands

```
# the gate
~/.local/bin/godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
# the review probe
~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_f3_weapon_fx.tscn --quit-after 900
# determinism (three runs, wiring lines identical; only the asteroid's look variant differs)
for i in 1 2 3; do ~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_f3_weapon_fx.tscn --quit-after 900 2>&1 | grep -E '^\[F3\]' > /tmp/f3_run$i.txt; done
diff /tmp/f3_run1.txt /tmp/f3_run2.txt   # → only the `Look` sheet line (env_asteroid_M1 vs _M2)
# no removed numeric literal anywhere in the wave
git diff -U0 -- vajb-orbit/game vajb-orbit/autoload | grep -E '^-[^-]' | grep -E '[0-9]'
# the const map, HEAD vs worktree
python3 - <<'PY'  # regex sweep of '^const NAME …' over both revisions
PY
# the balance-bearing regions, verbatim
git show HEAD:vajb-orbit/game/weapons.gd | sed -n '/const FAMILIES/,/## 09 section 3.1/p' | diff - <(sed -n '/const FAMILIES/,/## 09 section 3.1/p' vajb-orbit/game/weapons.gd)
```
