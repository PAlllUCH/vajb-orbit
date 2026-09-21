# Wave Rock cleave — asteroid destruction effects — task brief

Law, in order: `AGENTS.md`, `docs/CONTRACTS.md` (§5 entities, §8.1/§8.2, §9 gate),
`docs/gameplay/18_engine_spec.md` **§6** (Mining — owner-locked, cite it) and
**§13** (the cleaving rows), `docs/gameplay/02_minerals.md` §5/§8 (mineral
inheritance, respawn), `docs/design/FX_SPEC.md` §1.4 (explosion) + §7.3 (the
wiring contract), then this brief, then `.agents/gen/WAVEBOARD.md`. The gate
before this wave is **311** (slice 2.5 closed 2026-09-21, S3 report
`.agents/gen/slice2_5_s3_report.md`).

## 1. The owner ruling this wave executes (2026-09-21, verbatim)

*"asteroids breaking effects (they should somehow explode, random fragments from
2 to 5 moving in random directions)"*

Today (measured, `game/asteroid.gd:92-102`): depletion cleaves **deterministically**
— a Large spawns **2–3** Medium fragments, a Medium **2** Small, ejecting at
`linear_velocity × 1.2` inside a **±15°** cone; a Small bursts 1–2 pickups; a
yield-0 rock cracks and despawns bare (ruling 17). Nothing explodes visually and
nothing plays a break cue.

The ruling amends §6's cleaving:

| # | Change | Law |
|---|---|---|
| 1 | **Fragment count is random 2–5** per cleaving tier (Large → 2–5 Medium, Medium → 2–5 Small), replacing the fixed (2,3)/(2,2) rows | one constant pair per tier, uniform random |
| 2 | **Ejection direction is uniform 360°** (the ±15° cone is retired); speed stays `linear_velocity × 1.2` | one constant swap |
| 3 | **The break explodes**: one `fx_explosion` sequence at the rock's centre + one cue | FX_SPEC §1.4 (RGBA frames), §7.3 |
| 4 | Small rocks keep bursting **1–2 pickups** (there is no tier below Small) — no fragments | §6, unchanged |
| 5 | A yield-0 rock still cracks and despawns **without fragments** (ruling 17) but **does** play the break effect — the explosion is the rock's death read, not an ore event | owner tick below |

Tier ladder, respawn (20 min + ×0.7 diminishing), mineral inheritance (02 §5:
children re-roll) and every mining rate stay **exactly as shipped**. Nothing here
moves a damage, yield or mass value.

**Proposed numbers (one constant each; the owner tunes):**

| Constant | Proposed | Reversal |
|---|---|---|
| `FRAGMENT_COUNT` (per cleaving tier) | `Vector2i(2, 5)` — uniform, both tiers | restore the old `(2,3)/(2,2)` rows |
| `FRAGMENT_EJECT_CONE_DEG` | **360.0** (uniform direction; `0.0` restores the cone) | the constant's own |
| Explosion `world` size | `1.2 × the rock's collision diameter`, clamped **96–224 u** | one constant pair |
| Break cue | `play_pool(&"sfx_impact_rock")` with the pool row `CUE_POOLS` gains (L53: four takes sit on disk with no row) | `play_sfx` instead, or the explosion cue |

**Owner tick owed (blocked nothing):** `18_engine_spec.md` §6 is owner-locked —
the owner applies the dated amendment (count 2–5 uniform, direction 360°, the
break read) themselves, exactly like the §13 `coast_time` tick.

## 2. What is measured (do not re-discover)

- `game/asteroid.gd` — `FRAGMENT_SPLIT` / `PICKUP_BURST` / `FRAGMENT_EJECT_MULT`
  1.2 / `FRAGMENT_EJECT_CONE_DEG` 15.0; `cleaves()` (only ore-rolled rocks),
  `fragment_size()`, `eject_velocity()`; the **field** spawns the fragments
  (`asteroid_field.gd` asks `cleaves()` first), `mineral_id`/`tier` re-roll on
  children (02 §5), field respawn bookkeeping on the one clock.
- The FX machinery is ready: `game/projectile.gd`'s `FEEDBACK` table +
  `spawn_sheet`, `game/fx.gd`'s `sheet_frames`/`display`/`scale_for`, and the
  **re-cut RGBA frames** (`fx_explosion_f1..f5`, true alpha, shared canvas) —
  one `spawn_sheet(&"explosion", centre)` call is the whole visual.
- `game/impact.gd` owns the explosion terms (§4.2 item 8: `I(d) = P0/(1+d²)`,
  `EXPLOSION_P0` 4 000, `MIN_SHOCKWAVE_IMPULSE` 1.0, `MAX_SHOCKWAVE_BODIES` 32) —
  the break **reuses** the existing shockwave helper on nearby bodies; no new
  constant.
- `autoload/audio_manager.gd` has per-bed voices and `CUE_POOLS`;
  `sfx_impact_rock_01..04.ogg` sit on disk with **no pool row** (L53) — the row
  is one entry.
- `tests/test_engine2_cleaving.gd` (9 tests) pins the **old deterministic
  behaviour** — it moves in this wave (§4), and that is sanctioned.

## 3. Worker table

| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| **A1** | coder | `vajb-orbit/game/asteroid.gd,vajb-orbit/game/asteroid_field.gd,vajb-orbit/game/projectile.gd,vajb-orbit/autoload/audio_manager.gd,vajb-orbit/tests/` | The four changes of §1 exactly, with `projectile.gd` touched only if the fixed world sizes need one optional scale override (a single named constant). The break sequence: crack → explosion FX at the centre (rock-scaled) → cue → fragments ejecting in uniformly random directions at ×1.2 speed → pickups for a Small. Tests: count bounds (2–5, both tiers, seeded RNG), direction spread (two fragments >90° apart proves randomness), speed = ×1.2, the FX spawn, the cue, ruling 17's yield-0 path, the Small pickup burst, and that a Medium's fragments are Small. |
| **A2** | coder — reviewer (**mandatory**) | `vajb-orbit/tests/,vajb-orbit/tools/` | Re-run A1's probe byte-identically; re-measure every number; check each change against §1's table and FX_SPEC §1.4/§7.3; confirm 02 §5's mineral inheritance, 02 §8's respawn, ruling 17, the §13 collision terms and every mining rate are untouched; grep CONTRACTS §5 for drift; tier HIGH/MED/LOW with reproducing commands and raw output. LOW → `.agents/gen/LOW_BACKLOG.md`. |
| **A3** | coder — fixer | per-finding sets from A2's report | Only A2's HIGH/MED, one pass, each re-measured before and after with A2's own command. |

Run order: **A1 → A2 → A3** (only if A2 leaves HIGH or MED).

## 4. Tests that move (named, sanctioned)

- `tests/test_engine2_cleaving.gd` — the deterministic-count and cone assertions
  become the random bounds (2–5) and the uniform-direction checks. Nothing else
  moves; the gate grows from **311**.

## 5. Hard rules

- `VAJB_WORKER_FILES` exactly as tabled; bounded Godot runs only; L17 probe
  hygiene; the gate `godot --headless --path vajb-orbit
  res://tests/headless_runner.tscn --quit-after 1200`.
- No `assets/**`, no theme, no `project.godot`, no `addons/**`, no `docs/**`;
  `18_engine_spec.md` is owner-locked. **No invented number** — every value is
  §6/§13's, §1's table above, or marked proposed.
- A load failing only on a missing sprite/texture path is environment-deferred.

## 6. Close-out (orchestrator)

Gate re-run; `python3 staging/verify_wave.py verify --baseline rock_cleave_start
--forbidden project.godot --expect-reports <the wave's reports> --tests`;
WAVEBOARD updated; wave-boundary commit; report to the owner with the measured
gate count, the before/after cleave numbers, A2's findings by tier, and the §6
tick owed to them.
