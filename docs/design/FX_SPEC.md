# Vajb Orbit — FX Spec

**Status:** final 2026-09-17. Visual effects inventory: purpose, composition, palette, timing, and generation prompt notes for every in-game effect sprite. Palette and rules are copied verbatim from `docs/design/STYLE_BIBLE.md`; HUD surfacing follows `docs/design/UI_SPEC.md`; effect names align with SFX cues in `docs/design/AUDIO_SPEC.md` (S1 lasers, S3 rocket detonation, S5 shield hits, S7/S8 mining, S4 impacts).

---

## 0. Master Emission Rule

**Only Burnt Ember `#C8461B` and Ember Glow `#E8703A` may glow.**
Exception: the shield hit ripple uses Steel Highlight `#565C63` because the shield is **not a danger state** — it regenerates, and orange stays reserved for damage and weapons (mirrors UI_SPEC §3.1 shield bar logic).
Nothing else ever emits. No blue, no green, no purple, no teal, no yellow glow. Emissive content in FX is always small, hot, and contained — never ambient.

**Alien-family exception (owner ruling 24, 2026-09-20, STYLE_BIBLE §2.5):** alien-entity FX glow in that family's signature colour only — Bioluminescent Green `#4AE86C` (swarmers, slice 2), Corrupted Plasma Cyan `#2BE8E8` (Sibelon, slice 3), Void Magenta `#E82BE8` (Apex, slice 4) — mirroring the ember rule one-to-one: signature FX are small, hot, contained. Human FX never borrow these colours, and no alien FX ever carries ember.

**Sanctioned exceptions (STYLE_BIBLE §3 amendment 2026-09-17):** (1) the shield ripple's Steel Highlight `#565C63`; (2) frame-1 "white-hot" flash frames of muzzle flash (§1.2) and explosion (§1.4) — in generated art these stay a brightened, desaturated Ember Glow `#E8703A` hot core (no pure white pixels); the true white read comes from engine-side bloom on top of `#E8703A`; (3) the **field repair pulse** (`fx_repair_pulse.png`, added 2026-09-17) — an expanding Steel Highlight `#565C63` maintenance ring with fine engineering sparks, on the same reasoning as (1): a repair is not a danger state, so the ember pair stays reserved.

**Amendment 2026-09-18 (Phase F, anomaly trio):** `docs/gameplay/11_galactic_map.md` §3.2 defines three anomalies — ore bloom, grave cache and void rift. Only the rift is a hazard, so `FX_SPEC` §0's threat rule assigns the palette accordingly, and the trio becomes the fourth sanctioned non-ember glow site:

| File | Anomaly | Glow |
|---|---|---|
| `fx_anomaly_shimmer.png` | ore bloom (reward) | Steel Highlight `#565C63` only — a wide thin cold refraction ring, hollow centre, suspended non-glowing `#6E5B4A`/`#8A6A50` ore flecks. No ember, no warm colour. |
| `fx_anomaly_grave_glow.png` | grave cache (reward) | Steel Highlight `#565C63` core over an unlit Deep Void Blue `#111823`/Void Haze `#1A2230` halo, rising pale motes, a flat Iron Black `#232629` debris-haze ring at the base. No ember, no warm colour, no gravestone shape. |
| `fx_anomaly_rift.png` | void rift (hazard) | the ember pair alone — Burnt Ember `#C8461B` tear rim with a thin Ember Glow `#E8703A` edge line and crooked ember stress cracks. Danger state, so the existing accent applies unchanged. |

Three files, three distinct forms (hollow ring / dense point glow / vertical tear), exactly one accent per file, no new palette hex. All three are RGB on Void Black `#0A0E14` and are **never alpha-keyed** (§0.1).

## 0.1 Generation Rules (all sheets)

- Every sheet is generated from `vajb-orbit/assets/style-block.txt` **verbatim as the prompt preamble**, then the asset-specific subject below.
- Background: **flat black `#0A0E14` (Void Black), NOT white** — these are emissive effects composited in Godot with additive blending; a white background would bleed.
- Resolution 2K, aspect 1:1, then split into frames in Godot.
- Effects are generated as **isolated objects**: no ship parts, no text, no labels, no grid lines, no frames, no UI chrome.
- **Negative list (every panel, every prompt, copied from STYLE_BIBLE §8):** no purple, no green, no teal, no yellow, no blue, no rainbow, no chrome, no glossy highlights, no text, no watermark.
- Subtle film grain applies (style block carries it).

---

## 1. FX Inventory

### 1.1 Laser bolt — player light and medium

| Field | Value |
|---|---|
| Purpose | Player primary weapon projectile (pairs with S1 Lasers). Two sizes: light (thin, 4:1) and medium (6:1 elongation). |
| Composition | Burnt Ember `#C8461B` core line with an Ember Glow `#E8703A` soft halo, stretched along the travel direction (facing right in the sheet). Slight painterly hot-tip at the head. |
| Palette | `#C8461B` core, `#E8703A` halo, Void Black `#0A0E14` bg. |
| Timing | Single frame per tier; motion is handled by the engine (position + rotation). Light bolt ~64×16 px region, medium ~96×16 px region in the sheet. |
| Prompt notes | "single elongated energy bolt, horizontal, burnt ember #C8461B core with ember glow #E8703A halo, isolated on flat void black #0A0E14 background, 2K, 1:1" + style block. Generate both tiers on one sheet, spaced grid cells. |

### 1.2 Muzzle flash

| Field | Value |
|---|---|
| Purpose | Weapon port flash on fire (pairs with S1/S2). Plays once per shot over the muzzle. |
| Composition | 4-frame sheet: **f1** brightened desaturated-ember hot core (engine bloom renders it white-hot; art stays `#E8703A`-based, no pure white pixels) → **f2** burnt ember `#C8461B`/ember glow `#E8703A` expanding flare → **f3** ember flare collapsing with iron black `#232629` smoke wisps → **f4** smoke-dark residual puff. |
| Palette | `#E8703A` hot core (desaturated/brightened in art), `#C8461B`, `#E8703A`, `#232629` smoke, `#0A0E14` bg. |
| Timing | 4 frames at 20 FPS = 0.2 s total, one-shot, no loop. |
| Prompt notes | "4-frame horizontal sprite sheet of a weapon muzzle flash: frame 1 brightened pale-ember hot starburst core, frame 2 burnt ember #C8461B and ember glow #E8703A flare, frame 3 ember flare with iron black #232629 smoke, frame 4 dark smoke dissipating, isolated effects only, flat void black #0A0E14 background, 2K, 1:1" + style block. |

### 1.3 Engine trail

| Field | Value |
|---|---|
| Purpose | Continuous thrust streak behind the player (pairs with S16 Thruster loop). Spawned per-frame while thrusting. |
| Composition | Thin fading ember streak: burnt ember `#C8461B` hot head, ember glow `#E8703A` mid, alpha falloff to transparent tail. Slight painterly wobble allowed. |
| Palette | `#C8461B`, `#E8703A`, alpha fade, `#0A0E14` bg. |
| Timing | Alpha falloff over **0.4 s** per streak particle; engine-side fade, single frame texture. |
| Prompt notes | "single thin horizontal ember streak, burnt ember #C8461B core fading to ember glow #E8703A and transparent tail, isolated on flat void black #0A0E14 background, 2K, 1:1" + style block. One texture; length and alpha animated in engine. |

**Amendment 2026-09-21 — the engine-side numbers (owner request: thrusters must
read while travelling).** §1.3 left "length and alpha animated in engine" open,
which is the whole effect; these are the values the emitter uses, all keyed off
`speed_ratio = |v| / v_max` (engine spec §3.4's single input). They are
**proposals** — playtest-tunable, one constant each, and the reversal is the
value's own row.

| Field | Value | Reversal |
|---|---|---|
| Emitter | one `GPUParticles2D` per engine cell, parented to the hull, `local_coords = false` so the streaks trail in world space | — |
| Active while | thrust input is held **or** `speed_ratio ≥ 0.15` (the drift case still reads as motion) | drop the ratio half to make it input-only |
| Spawn rate | 20 streaks/s at ratio 0.15 → 60/s at 1.0 (linear) | one constant pair |
| Lifetime | **0.4 s** (§1.3's own falloff) | §1.3 |
| World length | 24 u at ratio 0.15 → 56 u at 1.0 | one constant pair |
| Width | 6 u | one constant |
| Alpha | 0.35 at ratio 0.15 → 0.85 at 1.0 | one constant pair |
| Blend | additive, `#C8461B` head → `#E8703A` mid → transparent tail (§1.3) | §1.3 |
| Anchor | the hull's engine cells when `ShipFit.mount_offset` is available, else one tail point behind the hull's centre | see the brief's seam rule |

### 1.4 Explosion

| Field | Value |
|---|---|
| Purpose | Ship / hostile destruction (pairs with S3 rocket detonation, S4 impacts). |
| Composition | **5-frame 2×3 grid sheet**: f1 brightened desaturated-ember hot flash (no pure white pixels; engine bloom whitens it) → f2 ember bloom (`#C8461B` core, `#E8703A` rim) → f3 ember and iron black `#232629` smoke expansion → f4 dissolving debris streaks (gunmetal `#2B2F35` fragments against ember glow) → f5 empty. |
| Palette | `#E8703A` hot flash (brightened in art), `#C8461B`, `#E8703A`, `#232629` smoke, `#2B2F35` debris, `#0A0E14` bg. |
| Timing | 5 frames at 15 FPS ≈ 0.33 s, one-shot. |
| Prompt notes | "sprite sheet, 2 by 3 grid, 5 frames of a space explosion sequence: brightened pale-ember hot flash, burnt ember #C8461B bloom with ember glow #E8703A rim, ember and iron black #232629 smoke cloud, dissolving gunmetal debris streaks, last cell empty, isolated effects only, flat void black #0A0E14 background, 2K, 1:1" + style block. |

### 1.5 Shield hit ripple

| Field | Value |
|---|---|
| Purpose | Shield absorbing a hit (pairs with S5 Shield hits). **The single non-ember glow exception** — shield is not a danger state. |
| Composition | Expanding ring in Steel Highlight `#565C63`, thin cold pale rim, faint inner haze, no ember anywhere. |
| Palette | `#565C63` only, `#0A0E14` bg. |
| Timing | Single frame texture; ring scale animated 0→1.5× over **0.3 s** with alpha fade in engine. |
| Prompt notes | "single expanding energy ripple ring, cold pale steel highlight #565C63 only, thin rim, no orange, no ember, isolated on flat void black #0A0E14 background, 2K, 1:1" + style block. Add "no orange glow" explicitly to the negative list for this panel. |

### 1.6 Mining beam

| Field | Value |
|---|---|
| Purpose | Asteroid mining beam and contact feedback (pairs with S7 Mining beam loop + S8 Mining chip hit). |
| Composition | Thin burnt ember `#C8461B` line with ember glow `#E8703A` edge (line drawn in engine between ship and target) plus a chip-sparks burst texture at the contact point: small angular ember sparks radiating from the impact. |
| Palette | `#C8461B`, `#E8703A`, `#0A0E14` bg. |
| Timing | Beam: continuous, subtle width flicker 0.1 s cycle in engine. Chip sparks: **4-frame mini sheet** at 20 FPS = 0.2 s, one-shot per S8 chip event. |
| Prompt notes | "4-frame horizontal sprite sheet of mining chip sparks: frame 1 small angular spark burst, burnt ember #C8461B and ember glow #E8703A sparks radiating from a point, frames 2 to 4 the sparks dissipate outward and fade, frame 4 nearly empty, isolated effects only, flat void black #0A0E14 background, 2K, 1:1" + style block. The beam line itself is engine-drawn; no texture needed. |

### 1.7 Cargo pickup pulse

| Field | Value |
|---|---|
| Purpose | Confirmation flourish when cargo is collected. Small, subtle, non-urgent. |
| Composition | Small ember ring pulse: burnt ember `#C8461B` ring with ember glow `#E8703A` inner glow, compact (~64 px). |
| Palette | `#C8461B`, `#E8703A`, `#0A0E14` bg. |
| Timing | Single frame texture; scale 0.5→1.2× and alpha 1→0 over **0.25 s** in engine. |
| Prompt notes | "single small energy ring, burnt ember #C8461B with ember glow #E8703A inner glow, isolated on flat void black #0A0E14 background, 2K, 1:1" + style block. |

### 1.8 Hull-critical screen vignette

| Field | Value |
|---|---|
| Purpose | Static full-screen overlay when hull fraction < 25 % — ties to the damage-overlay stack in `docs/assets/research/grimdark_ui_hud.md` section C (C1/C2/C3 class of assets) and to the HUD hull-critical state in UI_SPEC §3.1 (fill/label switch to `accent_danger_bright`). |
| Composition | Ember-dark gradient at screen edges: deep burnt ember `#C8461B` smouldering inward from all four edges to transparent centre, painterly, heavy at corners. Screen centre stays clear so gameplay and HUD stay legible. |
| Palette | `#C8461B` at the rim fading to transparent; `#232629` smoke texture inside the ember; `#0A0E14` bg (discarded on import — centre must be fully transparent). |
| Timing | Static art; alpha pulsing (0.6→1.0, 1.2 s sine) done in engine, matching the sin-driven alpha pattern documented for the C2 reference. |
| Prompt notes | "full-screen vignette, burnt ember #C8461B dark gradient glowing inward from all screen edges, corners heaviest, iron black #232629 smoke texture within the ember, transparent empty centre, isolated overlay only, flat void black #0A0E14 background, 2K, 1:1" + style block. Single frame, no sheet. |

---

## 2. Generation Plan

1. One run per sheet/prompt in §1, each = `style-block.txt` verbatim + asset subject + "flat black #0A0E14 background, NOT white — emissive effect for additive blending" + "2K, 1:1" + the §0.1 negative list.
2. Sheets are the shipped masters, split in Godot (`AtlasTexture` over the 2K PNG): `fx_muzzle_flash.png` (4 frames) and `fx_explosion.png` (5 frames) are the masters; the per-frame names in §3 are optional split exports, produced only if AtlasTexture is insufficient.
3. Import with additive blend intent; verify each frame against the §0 master emission rule before commit.
4. Record generator, prompt, seed, and date per asset in a generation log next to `vajb-orbit/assets/` (AI art is not CC0 — per AGENTS.md).

## 3. File Naming

| Asset | File |
|---|---|
| Laser bolt sheet (light + medium) | `fx_laser_bolt.png` |
| Muzzle flash sheet (4-frame master) | `fx_muzzle_flash.png` (split exports `fx_muzzle_flash_f1.png` … `_f4.png` optional) |
| Engine trail streak (§1.3) | `fx_engine_trail.png` |
| Explosion sheet (5-frame master) | `fx_explosion.png` (split exports `fx_explosion_f1.png` … `_f5.png` optional) |
| Shield hit ripple | `fx_shield_ripple.png` |
| Mining beam chip sparks (4-frame sheet) | `fx_mining_beam.png` |
| Cargo pickup pulse | `fx_cargo_pulse.png` |
| Hull-critical vignette | `fx_hull_critical_vignette.png` |
| Menu wreck ember pulse (MAIN_MENU_SPEC §5) | `fx_ember_pulse.png` |

Snake_case throughout; all live under `vajb-orbit/assets/fx/`.

**Amendment 2026-09-17:** `docs/design/ASSET_EXPANSION_SPEC.md` §7 extends this inventory with `fx_jump_portal.png`, `fx_missile_trail.png` and `fx_shield_break.png` (wave 1), plus `fx_tractor_beam.png`, `fx_emp_arc.png`, `fx_secondary_explosion.png` and `fx_repair_pulse.png` (wave 2). They obey §0 and §0.1 unchanged: void black background, no alpha keying, RGB output for additive blending, no glow colour outside the ember pair (and the sanctioned steel-highlight shield exception).

---

**Amendment 2026-09-21 — §4–§6 written (they were cited before they existed).**
`18_engine_spec.md` §2.1 item 18 and §3.4 cite "FX_SPEC §5" for the
speed-fantasy shader inputs, and the slice-2.5 queue cites "FX_SPEC §6" for the
damage states; both sections, and §4, were missing from this file after the
Phase G absorption (its content had moved into §7.1/§7.2). §5 and §6 below
**transcribe** those rows — no number is new except the two marked **proposed** —
so every existing citation resolves. §4 is unused: this file numbers by
inventory first and has no fourth chapter.

## 4. (unused)

Reserved. Nothing cites it; leave the number alone so §5/§6 keep their cited
names.

## 5. Speed fantasy — shader and emitter inputs

One input drives all three rows: `speed_ratio = |v| / v_max`, onset
`FX_BLUR_ONSET` **0.70** (engine spec §3.4, ruling 18). All of it is feedback;
zero gameplay numbers live here.

| Effect | Node | Values |
|---|---|---|
| Directional motion blur | screen-space `ColorRect` with a `canvas_item` shader on its own `CanvasLayer`, above the world and below the HUD | `blur_strength` clamps **0.1** at cruise → **0.8** during a dash; `blur_direction = v / |v|`; `chromatic_aberration` scales with strength; strength is 0 below the 0.70 onset |
| Camera pull-back | the flight camera's `zoom` | multiplied by `lerp(1.0, 0.82, (speed_ratio − 0.7) / 0.3)` — it **stacks with the wheel zoom**, never replaces it (the wheel owns the target, this owns the applied value) |
| Dust streaks | `GPUParticles2D` parented to the camera | emits micro streaks opposite the velocity vector while the ratio is high; texture `fx_dust_streak.png`; **proposed:** 30/s at ratio 1.0, 0.5 s lifetime, 12 u, low alpha, never additively blown |

## 6. Damage states

All four key off `PlayerState`'s own pool signals — no new gameplay coupling
(§7.3).

| State | Trigger | Effect |
|---|---|---|
| Hull-critical vignette | hull fraction < **25 %** | `fx_hull_critical_vignette.png` as a static full-screen overlay, alpha pulsing **0.6 → 1.0 at 1.2 s** (sine, §1.8), removed above the threshold |
| Damage smoke | hull fraction < 25 % | persistent non-emissive plume, `fx_smoke_plume.png`, `#232629`/`#2B2F35`; one emitter per hull, idempotent (**shipped** in the weapon-FX wave: `Projectile.spawn_smoke_plume` / `clear_smoke_plume`) |
| Electrical arcs | hull fraction < 25 % | intermittent `fx_arc_spark.png` bursts, **proposed:** one arc every 1.6–2.6 s (random), 0.2 s per arc (§7.2's own rate) |
| Shield shatter | shield pool reaches 0 (ruling 20) | one-shot `fx_shield_break.png` burst, 0.4 s, 10 FPS (**shipped**) |
| Shield hit ripple | a landed hit on a live shield | `fx_shield_ripple.png`, 0.3 s (§1.5) (**shipped**) |

---


## 7. Phase G — speed fantasy, damage states & alien FX (rulings 18/20/24, 2026-09-20)

Owner-approved additions from the `PHYSICS_SPEC.md`/`GRAPHICS_IDEAS.md`
brainstorm, absorbed after `docs/gameplay/18_engine_spec.md` §2.1. Existing
§0–§3 rules stand unchanged.

### 7.1 Engine-side FX (no generation — code + shader work)

| Effect | Node | Law |
|---|---|---|
| Directional motion blur | screen-space `ColorRect` shader on a `CanvasLayer` | Active from `FX_BLUR_ONSET` 0.70 of v_max; inputs `blur_strength` (0.1 cruise → 0.8 dash), `blur_direction = v/|v|`, `chromatic_aberration` scaled with strength. Engine spec §3.4. |
| Camera pull-back | `Camera2D.zoom` multiplier | `lerp(1.0, 0.82, (ratio − 0.7)/0.3)`, stacks with wheel zoom. |
| Dust streaks | `GPUParticles2D` on the camera | Emits counter-velocity micro streaks while the ratio is high; texture `fx_dust_streak.png` below. |
| Thruster trail | one `GPUParticles2D` per engine cell, parented to the hull | §1.3's engine-side table: 20–60 streaks/s, 0.4 s lifetime, 24–56 u, alpha 0.35–0.85, all by `speed_ratio`; additive ember. The thruster **loop** is S16 in AUDIO_SPEC §4.5. |
| Dash charge | one-shot on booster activation | `fx_dash_charge.png`, ember pair, engine-scaled (proposed: 32 u, 0.2 s); fires for `b_afterburner` today — `b_fold`'s movement is slice 4's, so its charge waits with it. |
| Damage smoke + arcs | two parented `GPUParticles2D` on the hull | Spawn while hull < 25 %: persistent black plume puffs (`fx_smoke_plume.png`) + intermittent electrical arcs (`fx_arc_spark.png`). Ember sparks only inside the arc sprite — the plume itself is `#232629`/`#2B2F35`, non-emissive. **The plume half shipped 2026-09-21** (`Projectile.spawn_smoke_plume`, called from `player_ship.gd` and `npc_ship.gd`); the arcs' cadence is FX_SPEC §6's. |
| Shield shatter | one-shot `GPUParticles2D` burst | Fires when the shield pool hits 0 (ruling 20): glass-like shards of Steel Highlight `#565C63` outward over 0.4 s; texture `fx_shield_shatter.png`. The existing `fx_shield_break.png` (ASSET_EXPANSION_SPEC §7) covers the same event — reuse it; this row defines behaviour, not a second asset. |

### 7.2 New generated assets

| Asset | Composition | Palette / rule |
|---|---|---|
| `fx_bio_plasma.png` | Swarmer projectile: pulsing organic orb + falling bio-spore motes (single frame, spores engine-emitted) | Bioluminescent Green `#4AE86C` glow on Corrosive Dark `#1A281F` mass; alien block addendum (STYLE_BIBLE §9.1); never alpha-keyed. Sibelon/Apex variants re-tint in engine or get per-family sheets at slice 3/4. |
| `fx_acid_burn.png` | Corrosion DoT emitter puff: dissolving bio-acid wisps parented to the target hull for the 3 s Corrosion window | `#3D6E49` body, `#4AE86C` hot flecks; non-additive `MIX` blend — the only MIX effect in the inventory (stains, not light). |
| `fx_shield_shatter.png` | **retired before shipping (owner ruling 2026-09-21): it duplicates `fx_shield_break.png`.** The four-frame sheet was generated and reviewed, then dropped; the shield-shatter event uses the shipped `fx_shield_break.png` per §7.1, which already defines that row as behaviour, not a second asset. The render stays in `staging/phase_g/fx/` as provenance. | - |
| `fx_smoke_plume.png` | Single painterly black smoke puff, soft alpha column | `#232629`/`#2B2F35`, non-emissive; RGB on Void Black per §0.1 (no alpha keying). |
| `fx_arc_spark.png` | 4-frame sheet: jagged electrical arc snapping between frames | Steel Highlight `#565C63` arc with a brightened-ember core flash (same frame-1 rule as §1.2); 0.2 s per arc. **The arc itself is steel, never ember** — the first render came back rust-red over the whole arc and was regenerated (owner ruling 2026-09-21). |
| `fx_dust_streak.png` | Single micro streak, thin, low alpha | `#1A2230`→transparent; camera-space, never additively blown. |
| `fx_dash_charge.png` | Charge ring + streak burst for the fold/dash (ruling 9) | Ember pair (it is an engine state): `#C8461B` rim, `#E8703A` hot edge; single frame, engine scales it. |
| `fx_lock_channel.png` | Thin progress arc texture for the reticle lock ring (§4.1) | Steel Highlight `#565C63` arc; the ring completes to `metal_light` when the lock lands. Engine may draw it in `_draw()` instead — texture is the fallback. |

All: 2K masters, Void Black `#0A0E14` background, isolated subjects, §0.1
negative list, generation log next to the assets.

### 7.3 Wiring contract

- One-shot sheets (`AnimatedSprite2D`, `loop = false`,
  `animation_finished → queue_free()`): muzzle flash, explosion, chip sparks,
  shatter, arc spark.
- Continuous/parented emitters (smoke plume, acid burn, dust, bio-spores):
  `GPUParticles2D` with a lifetime owner — the emitter frees with its target.
- The speed-fantasy stack (§7.1 rows 1–3) keys off `speed_ratio` only
  (engine spec §3.4); the damage states key off `PlayerState` pool signals —
  no new gameplay coupling.
- HUD surfacing for the radial speedometer is UI_SPEC §3.6; the prograde
  needle's cyan is a navigation colour, not an FX glow (STYLE_BIBLE §3).
