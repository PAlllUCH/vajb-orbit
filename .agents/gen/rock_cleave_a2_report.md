# A2 — rock cleave: the mandatory review

Wave `rock_cleave` (brief `.agents/gen/rock_cleave_wave_task.md`, law read in the order the
brief fixes: `AGENTS.md`, `docs/CONTRACTS.md` §5/§9, `18_engine_spec.md` §6/§13,
`02_minerals.md` §5/§8, `FX_SPEC.md` §1.4/§7.3, the brief, `WAVEBOARD.md`). Worker **A2**,
reviewer. Date 2026-09-22, host Linux (`/home/kamil-paluszkiewicz/VajbOrbit`), engine
`4.7.2.stable.official.ed1daf0bf`.

Owner ruling under review, verbatim: *"asteroids breaking effects (they should somehow
explode, random fragments from 2 to 5 moving in random directions)"*.

A1's report under review: `.agents/gen/rock_cleave_a1_report.md`.

---

## 0. Verdict

**No HIGH. One MED. Four LOW. Nothing was fixed** (A2 changes no production file, per the
brief).

Every one of the brief's five sanctioned changes is present and independently
re-measured, the four invariants the brief names are provably untouched, the pinned
CONTRACTS §5 signatures are unchanged, and the gate is green at **378/0** — measured by me,
and **+6** against a pre-wave tree I measured myself at **372/0**, with no other suite's
count moving.

| Finding | Tier | Owner |
|---|---|---|
| `docs/CONTRACTS.md` §5's cleaving sentence still states the retired rows and the ±15° cone | **MED** | close-out / orchestrator (the contract's own rule; not a code fixer) |
| `game/projectile.gd:1177`'s `play_cue` comment calls `sfx_impact_rock` "plain" — this wave gave it a pool row | LOW → L72 | next owner of that file |
| `AsteroidField.respawn(now)`'s `now` does not reach the yield roll, so a probe-driven window rolls *unmodified* yields | LOW → L73 | pre-existing, no producer |
| `test_the_fragment_count_varies_inside_the_amended_bounds` would also pass on the retired `(2,3)/(2,2)` rows | LOW → L74 | next owner of the suite |
| the worker-file hook normalises Windows paths only: an absolute Linux path is denied even when it is inside the declared set | LOW → L75 | agent tooling |

**Owner tick owed** (blocked nothing, and A1 named it): `18_engine_spec.md` §6, §13 and
**§15** still carry the retired numbers — §13/§15 are in the tick too, which is worth
stating because §15 is the *headless test checklist* and it now contradicts the shipped
suite.

Nothing renders or sounds wrong in the shipped tree as far as a headless host can tell:
every FX/cue claim is measured on the node graph (`AnimatedSprite2D` count, order, scale,
frames, blend, `animation_finished` connection) and on `AudioManager.last_sfx()` /
`play_pool`'s returned plan — that is what a headless probe can prove, and it is not the
same as seeing the frame. **No pixel or audio was watched**; §7 records that limit.

---

## 1. The gate, measured by me

```bash
godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
```

| Tree | Summary | Exit | Non-`[PASS]` lines |
|---|---|---|---|
| this wave (`git status` = the six files below) | **`[SUMMARY] passed=378 failed=0`** | 0 | 4 (below) |
| HEAD `8d189bf`, the six wave files stashed | **`[SUMMARY] passed=372 failed=0`** | 0 | the same 4 |

The pre-wave number was measured by me, not carried over: `git stash push --` the six
modified files, run, `git stash pop` (md5 of all six verified identical before and after;
`git stash list` empty). Evidence: `.agents/gen/rock_cleave_a2_gate.txt`.

- **The brief's `311` is stale; the wave's growth is +6, from 372 to 378** — the whole of it
  is `test_engine2_cleaving` 9 → 15. A per-suite diff of the two runs reports exactly one
  changed line, and `test_weapon_fx_f2` is 13 before and after (its assertion moved, its
  count did not).
- The four non-`[PASS]` lines are the *same four lines at the same positions* as A1's log:
  `:6 ERROR: Parameter "data.tree" is null.` (`weapons.gd:1330 _world_parent`, from a
  detached bow in `test_combat_repair_c5`), `:228` the `EconomyLog` fixture warning,
  `:416 SCRIPT ERROR … previously freed instance` at `tests/test_weapon_fx_f4.gd:176`
  (LOW_BACKLOG **L61**, the file untouched here), `:427` the leak counter.
- The exit-time counters (`ObjectDB instances were leaked`, `resources still in use`) are
  not a signal, and this review adds a second data point to A1's: on the **byte-identical**
  gate for the same six files, A1's log reads `34 / 2` and mine reads `34 / 16`, while A1's
  stashed-HEAD run on unchanged code reads `84 / 36`. Same summary, same exit 0, different
  counters — run to run, not wave to wave.
- `[FAIL]` count: 0 in both runs.

## 2. A1's probe, re-run byte-identically

```bash
godot --headless --path vajb-orbit res://tests/probe_rock_cleave.tscn --quit-after 900
```

**Byte-identical**: `md5 7f1ec8c82cb53be65403caefea079077` for both A1's saved log and my
re-run (and again on a third run at the end of the review), `exit 0`, `[RC] done
failures=0`, 22 `[RC] ok` assertions. `diff` of the two files is empty, not just of the
`[RC]` lines.

Byte-identity proves determinism, not correctness — so §3 re-derives every number on my
own instrument.

## 3. Every number, re-measured on my own instrument

`vajb-orbit/tests/probe_rock_cleave_a2.gd` + `.tscn` (new, inside A2's declared set) is a
**different** measurement, not a re-run: seed `424242` (A1 used `20260921`), parent velocity
`137 u/s` at `-1.1 rad` (A1 used `120` at `0.7`), **300** cleaves per tier for the count
(A1: 8), 150 cleaves for the direction (A1: 8), a non-zero field offset `(37, -19)` so "the
FX sits on the rock's centre" is measured in *global* space rather than being an accident of
a field at the origin, and an added blast-reach check. **54 assertions, 0 failures**,
byte-identical over two consecutive runs
(`md5 d6b3605bf537c9314ea8ce38c275edac`). All raw output:
`.agents/gen/rock_cleave_a2_probe.txt`.

```bash
godot --headless --path vajb-orbit res://tests/probe_rock_cleave_a2.tscn --quit-after 900
```

| Brief's §1 row | My measurement (raw line) |
|---|---|
| 1. count is uniform random **2–5**, both tiers | `COUNT Large n=300 min=2 max=5 hist={2:80, 3:69, 4:72, 5:79} chi2=1.15 landed=[1]` · `COUNT Medium n=300 min=2 max=5 hist={2:78, 3:69, 4:70, 5:83} chi2=1.79 landed=[0]` — all four values present on both tiers, χ² 1.15 / 1.79 against uniform (95 % critical 7.81), every fragment one tier down |
| 2. direction **uniform 360°**, cone retired | `DIR n=529 resultant=0.0638 chi2_8sector=4.49 sectors=[75, 74, 66, 56, 62, 64, 70, 62] widest_pair=179.812 (cleave 79) inside_15=8.9% min=-179.616 max=179.769` — mean resultant length ≈ 0 (a cone reads near 1), 8-sector χ² 4.49 (95 % critical 14.07), both far sides reached, 8.9 % inside ±15° against the 8.3 % a uniform circle predicts |
| 2. speed stays `× 1.2` | `SPEED n=529 min=1.200000 max=1.200000 parent_speed=137.000` — 529/529 exactly 1.2, at a parent speed and heading A1 never used |
| 3. one `fx_explosion` at the rock's centre, rock-scaled | `FX Large rock_local=(-280.0, 260.0) rock_global=(-243.0, 241.0) sprite_local=(-243.0, 241.0) sprite_global=(-243.0, 241.0) diameter=132.0000 world=158.4000 scale=0.175221 frames=5 fps=15.0 loop=false mix=0 freed_on_finish=1 z=2` · Medium `world=100.8000 scale=0.111504` · Small `diameter=48.0000 world=96.0000 scale=0.106195` — one sprite per break (1 → 2 → 3), global position = the rock's own global centre, `clamp(1.2 × diameter, 96, 224)`, FX_SPEC §1.4's 5 frames at 15 FPS, `loop=false`, MIX blend, one `animation_finished` connection |
| 3. one cue | `CUE row takes=[sfx_impact_rock_01..04] mode=round_robin pitch=0.0 volume=[0.0, 0.0] files=[…01.ogg, …02.ogg, …03.ogg, …04.ogg]` · `CUE break played=sfx_impact_rock_02 (seeded sfx_impact_hull) in_row=true` · `CUE round_robin=[_02, _03, _04, _01, _02, _03]` — all four take files resolve through `play_pool`, the break plays a take, consecutive reads never repeat |
| 4. Small bursts **1–2 pickups**, no fragments | `BURST n=40 counts=[2,1,1,1,2,2,2,2,1,1,1,2,2,2,2,1,2,2,1,1,2,1,2,1,1,1,1,2,2,1,1,1,2,2,2,1,2,1,1,2] min=1 max=2 ore_id=mineral_iron items=[&"mineral_iron"] small_fragments=0` — 40 Smalls, 1–2 each, every pickup carrying the rock's own ore id, 0 rock fragments |
| 5. yield-0 cracks bare **but still plays the break** | `BARE cleaves=false fragments=0 fx=0->1 cue=sfx_impact_rock_04 (seeded sfx_impact_hull) live=18->17` — no fragment, the rock leaves the field, and the FX and the cue fire anyway |

Two numbers A1 reported that the brief did not ask for, re-measured because A1 claimed them:

- **the blast.** `BLAST reach=63.2376 near_offset=20.0 near 0.000000 -> 0.254471 (dx=0.254471)
  far_offset=200.0 far 0.000000 -> 0.000000 impulse(near)=9.9751 impulse(far)=0.1000`. The
  reach is `sqrt(P0 / MIN − 1) = sqrt(3999) = 63.2376 u` — **no radius constant was
  invented**; a rock at 20 u inside it gains outward velocity, one at 200 u is not moved at
  all. Note `Impact.apply_shockwave` (`impact.gd:93-116`) applies **momentum only, never
  damage**, so a rock's death cannot hurt the player — worth stating because the brief calls
  this a presentation wave.
- **mineral inheritance** (this one *was* asked: the brief's deliverable line names it).
  `INHERIT cleaves=30 n=97 parent=(iron,1) minerals=[&"iron"] tiers=[1] classes=[0]
  yields=[7, 6, 5, … 4] band=3-9` — 30 Medium cleaves, 97 fragments, every one iron/1/Small,
  every yield re-rolled inside T1's band.

---

## 4. The invariants the brief names, all provably untouched

The strongest form of "no balance number moved" is not a reading, it is a diff of every
constant and every numeral literal. Saved as re-runnable tooling (inside A2's declared set):

```bash
python3 vajb-orbit/tools/a2_const_audit.py
```

It prints, per changed production file, (1) a **const map** — each `const NAME := …`
declaration's full text, dictionary bodies included — and (2) a **numeral multiset** of
every numeric literal outside a comment, both HEAD against the working tree. Raw output:
`.agents/gen/rock_cleave_a2_const_audit.txt`. **Every delta, accounted for:**

| File | Constant deltas | Numeral deltas |
|---|---|---|
| `autoload/audio_manager.gd` | `CUE_POOLS` gains **one** row (`&"sfx_impact_rock"`), body otherwise byte-equal | `+0.0 ×3` (that row's `pitch` and `volume_db`) |
| `game/asteroid.gd` | `FRAGMENT_SPLIT` M/L `(2,2)/(2,3)` → `(2,5)/(2,5)`; `FRAGMENT_EJECT_CONE_DEG` `15.0` → `360.0` | `+5 ×2, +360.0` / `−3, −2, −15.0` — exactly the two changed rows and the cone |
| `game/asteroid_field.gd` | `+ProjectileScript`, `+ImpactScript` (preloads) | `+2.0` (the diameter), `+0.0` (`maxf(…, 0.0)`) |
| `game/projectile.gd` | `+ROCK_BREAK_WORLD_SCALE 1.2`, `+ROCK_BREAK_WORLD_MIN 96.0`, `+ROCK_BREAK_WORLD_MAX 224.0` | `+1.2, +96.0, +224.0, +0.0 ×3` |

**No mining rate, mass, damping, collision term, yield, tier weight or spawn-probability
number appears in either delta list.** The CUE_POOLS body diff in full:
`.agents/gen/rock_cleave_a2_pools_diff.txt`.

The same four invariants, re-measured behaviourally on my probe (not read off the source):

- **02 §8's respawn bookkeeping** — `respawn_window_constants` (300 s window, ×0.7, 6–12
  rocks), `respawn_guard_and_stamp` (no respawn while rocks live; a full depletion stamps
  `last_depleted_time`; a respawn re-rolls 6), `respawn_diminishing_window` (open at +299 s,
  closed at +300 s), and `respawn_diminished_yields`: a field respawned on the real clock
  rolls T1 yields `[3, 4, 4, 4, 2, 2]` — all ≤ 6, where the unmodified band tops at 9.
  `last_depleted_time`/`last_respawn_time` are still the field's own vars and `respawn` is
  still the only writer.
- **Ruling 17** — `invariant_gun_chip`: 5.0 of gun work lands as 0.5 rock work (the 10 %
  chip) and a second 5.0 completes the one unit, so guns still chip toward depletion only;
  the four `cleaves()`/`is_depleted()`/`cracked`-once behaviours are in the suite A1 kept
  verbatim and the gate re-ran.
- **§13's collision terms** — `invariant_collision_rows`: `COLLISION_FACTOR 2.0e-5`,
  `COLLISION_MIN_DV 40`, `KNOCKBACK_FRACTION 0.40`, `EXPLOSION_P0 4000`, `EXPLOSION_WINDOW
  0.2`, `MIN_SHOCKWAVE_IMPULSE 1.0`, `MAX_SHOCKWAVE_BODIES 32` — read off their owners
  (`impact.gd`, `projectile.gd`). `impact.gd` is not in the wave's file set at all
  (`git status` does not name it), and `projectile.gd`'s entire delta list is the three
  `ROCK_BREAK_*` constants plus their arithmetic, so no collision or impulse term moved.
- **Every mining rate** — `WORK_PER_UNIT 1.0`, `WORK_EPSILON 1e-4`, `MINE_CYCLE 1.2 s`,
  laser range `220 u`, gun chip `10 %`; and the body terms the rock still owes ruling 8:
  `mass 560.0` (4 × `ship_miner`'s 140), `linear_damp 3.71` with `DAMP_MODE_REPLACE`,
  `gravity_scale 0`, `can_sleep false`, `layer 1 / mask 2`, group `asteroid`.

## 5. CONTRACTS §5's pinned signatures, grepped across every changed file

| §5 pin | `game/asteroid.gd` | `game/asteroid_field.gd` |
|---|---|---|
| `setup(...)` | `:216` | `:122 setup(config: Dictionary = {}) -> void` |
| `apply_work(work: float) -> int` | `:238` | — |
| `size_class() -> int` | `:277` | — |
| `cleaves() -> bool` | `:283` | — |
| `eject_velocity() -> Vector2` | `:291` | — |
| `world_radius() -> float` | `:296` | — |
| `signal cracked` | `:52` | — |
| `is_depleted()` / `respawn(now := -1)` / `rocks()` | — | `:141` / `:153` / `:172` |
| `last_depleted_time` / `last_respawn_time` | — | `:99` / `:100` |

`audio_manager.gd` is not a §5 entity; neither is `projectile.gd`. Both are in the wave's
file set, so both were checked for API drift anyway:

- `audio_manager.gd` gains no function and changes no signature — `play_pool`, `play_sfx`,
  `has_pool`, `cue_pool`, `pool_takes`, `last_sfx` are untouched.
- `projectile.gd`'s **only** changed `func` line in the whole diff is
  `static func spawn_sheet(parent, fx_name, at, world: float = 0.0)` — a trailing
  **defaulted** parameter. Every pre-existing call site passes three arguments
  (`spawn_explosion`, `spawn_secondary_explosion`, `spawn_arc_spark`,
  `spawn_chip_sparks`, `spawn_shield_break`, `spawn_mine_burst` are all in-file) and
  `world > 0.0` is false for them, so each keeps the row's own `world` and byte-identical
  behaviour. `spawn_rock_break` is the one new static helper.
- `MIN_SHOCKWAVE_IMPULSE` (1.0) and `MAX_SHOCKWAVE_BODIES` (32) are read, never re-declared.

The file set is exactly A1's claim: `git status --porcelain` shows six modified files
(`autoload/audio_manager.gd`, `game/asteroid.gd`, `game/asteroid_field.gd`,
`game/projectile.gd`, `tests/test_engine2_cleaving.gd`, `tests/test_weapon_fx_f2.gd`) and
four new ones under `tests/` — no `assets/**`, no theme, no `project.godot`, no
`addons/**`, no `docs/**`. `game/pickup.gd` is **not** modified (last touched by slice 0's
close, `de40b19`): A1's "it was repaired to `assets/env/pickup/…`" refers to that earlier
repair, and the burst is measured working in both probes.

---

## 6. Findings

### MED — `docs/CONTRACTS.md` §5's cleaving sentence is now wrong

Reproduce:

```bash
git grep -n "±15° cone" docs/CONTRACTS.md
```

```text
docs/CONTRACTS.md:267:`× 1.2` inside a ±15° cone, fragment mineral **and tier** inherited from the parent
```

Raw text at `docs/CONTRACTS.md:265-271`:

```text
The size class is a look *and* the cleaving class:
`FRAGMENT_SPLIT` L (2,3) → M, M (2,2) → S, `PICKUP_BURST` (1,2) for an S, ejection
`× 1.2` inside a ±15° cone, fragment mineral **and tier** inherited from the parent
with the yield re-rolled through the 02 §5 path (the §13 row and §12 item 12 are
law; §6's "re-rolled tier" parenthetical is not representable, since a mineral
fixes its tier).
```

Three clauses are retired by the ruling the brief makes law: the `(2,3)/(2,2)` rows, the
`±15°` cone, and the silence about the break read (every depletion now also draws the
explosion, plays the cue and shoves its neighbours). The tier/mineral/yield sentence below
them stays true and was re-measured (§3).

`docs/` is outside A2's declared file set, and CONTRACTS' own preamble settles the owner:
"every review/fix wave owns updating it (additions and amendments recorded at the bottom in
the changelog). Never edit it mid-wave while workers hold the same files — **the
orchestrator merges review-wave changes after a wave closes**". So this is a close-out item,
and the orchestrator should land it with the wave-boundary commit. (If the orchestrator
prefers the A3 route the brief's run order allows, `docs/CONTRACTS.md` as A3's whole
`VAJB_WORKER_FILES` is the other valid shape — no worker holds that file now that A1 has
stopped, and the patch above is exact enough to apply without judgement.)

Suggested replacement for the paragraph's second sentence, plus one §10 changelog entry
(`v1.4 (2026-09-22, rock-cleave review — A2)`): `FRAGMENT_SPLIT` **uniform 2–5 on both
cleaving tiers** (`(2,5)` L → M and M → S), `PICKUP_BURST` `(1,2)` for an S, ejection
`× 1.2` in a **uniform 360°** direction (`FRAGMENT_EJECT_CONE_DEG`, `0.0`/`15.0` restore the
retired cone), fragment mineral **and tier** inherited with the yield re-rolled through the
02 §5 path; every depletion — cleaving, bursting or yield-0 — also draws FX_SPEC §1.4's
explosion at the rock's centre scaled `clamp(1.2 × diameter, 96, 224) u`, plays S4's rock
cue through the new four-take `CUE_POOLS` row, and applies `Impact.apply_shockwave` to the
bodies inside `I(d) ≥ MIN_SHOCKWAVE_IMPULSE`.

### LOW — see `.agents/gen/LOW_BACKLOG.md` L72–L75

Each carries its own reproducing command and raw output there; in brief:

- **L72** `game/projectile.gd:1177` still says a "plain" `sfx_impact_rock` "falls back to
  `play_sfx`" — this wave's L53 row makes that false, and `play_cue` is now driven from a
  new call site (`asteroid_field.gd:_break_read`).
- **L73** `respawn(now)`'s `now` reaches `last_respawn_time` and `diminishing_active(now)`
  but not `_yield_multiplier()`, which reads `Clock.now()`. A probe that drives the window
  with `respawn(1000)` therefore gets *unmodified* yields — measured in my own probe before
  I switched it to the real clock (`fake_now_yields=[6, 4, 7, 3, 8, 4]`, up to 9, where the
  real-clock respawn reads `[3, 4, 4, 4, 2, 2]`). Production always passes the real clock,
  so no gameplay effect; only the parameter's documented purpose is half-honoured.
- **L74** `test_the_fragment_count_varies_inside_the_amended_bounds` asserts "≥ 2 distinct
  counts, all inside 2–5" over 40 alternating cleaves — which the retired `(2,3)/(2,2)` rows
  also satisfy (`{2,3}`). `test_the_split_table_is_the_amended_row` is what actually pins the
  row, so a revert is still caught; tightening it to "all four of 2, 3, 4, 5 appear" would
  make the variety test carry its own weight (my 300-cleave sample sees all four on both
  tiers).
- **L75** the worker-file hook rewrites only `g:/…` prefixes, so on Linux an absolute path
  under the declared set is denied; workspace-relative paths work. Cost me one blocked write.

---

## 7. Owed owner tick, and the limits of this review

**Owed to the owner** (`18_engine_spec.md` is owner-locked; the brief assigns this tick at
§1's "Owner tick owed", and A1 recorded it): the dated amendment for

- §6, lines 283-290 — "spawns 2–3 Medium fragments, a Medium 2 Small … plus a random ±15°
  cone. A yield-0 rock still cracks and despawns without fragments." The first two clauses
  are the retired rows/cone; the last needs the break read added.
- §13, lines 493-497 — `Fragment split L → 2–3 M · M → 2 S · S → 1–2 pickups` and
  `Ejection current_velocity × 1.2 + random ±15° cone`.
- **§15, lines 619-621** — `Cleaving: a depleted Large spawns 2–3 Medium fragments ejecting
  at ×1.2 velocity ±15°; … yield-0 rocks still despawn bare.` **This one matters most of the
  three:** §15 is the headless-assertable checklist, and as written it instructs the next
  worker to assert behaviour the shipped suite now contradicts.

Reproduce the set: `git grep -n "±15° cone\|2–3 Medium" docs/gameplay/18_engine_spec.md`.

**Review limits, stated plainly.** (1) This is a headless host: I measured node structure,
properties, counts, `AudioManager.last_sfx()` and `play_pool`'s plan. I did not watch a
frame or hear a cue, so "the explosion looks right at a rock's scale" is a claim about
`scale = clamp(1.2 × diameter, 96, 224) / 904` and not about the render — the closed-out
designer lane owns the look. (2) `AsteroidField`'s blast on *hulls* was verified by
reading (`_blast_targets` walks `&"player_ship"`/`&"npc_ship"` to `impact_body`, both hulls
expose it at `player_ship.gd:329` / `npc_ship.gd:874`) and by measuring the blast on a rock
neighbour; a ship-in-the-loop measurement is not in this probe and the walking pattern is
`game.gd`'s wreck blast's own, so the risk is low. (3) A rock's *look* rolls on the global
RNG, not the field's seeded one (`asteroid.gd:350`), so my probe pins it (`seed(LOOK_SEED)`)
to stay byte-reproducible; the count and direction sections needed no such help.

---

## 8. Files this review produced

Inside A2's declared set (`VAJB_WORKER_FILES=vajb-orbit/tests/,vajb-orbit/tools/`; `.agents/`
is hook-exempt):

```text
vajb-orbit/tests/probe_rock_cleave_a2.gd|.tscn   the independent probe (54 assertions)
vajb-orbit/tools/a2_const_audit.py               the const + numeral audit (re-runnable)
.agents/gen/rock_cleave_a2_probe.txt             the probe's raw log + determinism note
.agents/gen/rock_cleave_a2_gate.txt              the gate, before/after, per suite
.agents/gen/rock_cleave_a2_lint.txt              the warning ledger + its HEAD A/B
.agents/gen/rock_cleave_a2_const_audit.txt       every const/numeral delta
.agents/gen/rock_cleave_a2_pools_diff.txt        the CUE_POOLS body diff
.agents/gen/rock_cleave_a2_report.md             this report
```

Plus the LOW entries appended to `.agents/gen/LOW_BACKLOG.md` (L72–L75).

**No production file was changed by this review**; `git status --porcelain` after the last
measurement is the six files A1 modified, the four A1 added, and the additions above. The
two `git stash`/`pop` cycles used for the before/after A/B left the tree byte-identical (md5
of all six verified), and `git stash list` is empty.

Close-out inputs: measured gate **378/0** (pre-wave **372/0**), the only moved suite
`test_engine2_cleaving 9 → 15`, findings **0 HIGH / 1 MED / 4 LOW**, and the owner tick owed
at §6/§13/**§15**. A fixer pass is needed only for the MED, and that MED is one paragraph of
`docs/CONTRACTS.md` §5 plus its §10 changelog entry — the exact replacement text is above.
