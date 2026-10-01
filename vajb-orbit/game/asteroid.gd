class_name Asteroid
extends RigidBody2D
## One mineable rock: a solid body that accumulates extraction work and cracks
## open at yield 0.
## Contract: ENGINE_SPEC.md §6 (mining — the laser is primary, guns work rocks at
## 10 %; rocks are solid, block shots and beams; tiered cleaving per ruling 17),
## §13 (`MINE_CYCLE` 1.2 s per ore unit; the cleaving rows; the class mass column),
## §15 ("Mining: N cycles on a rock spawn N ore pickups; gun work accumulates at
## 10 %; cracks at yield 0"; "a depleted Large spawns 2-3 Medium fragments ejecting
## at x1.2 velocity ±15°; a depleted Small bursts 1-2 pickups; yield-0 rocks still
## despawn bare"); docs/gameplay/02_minerals.md §5 (the mineral and yield rolls) and
## §7 (the mining flow); slice-0 brief §M2 and pinned interface item 5.
##
## **The owner's asteroid ruling (2026-09-21, verbatim: "asteroids breaking effects
## (they should somehow explode, random fragments from 2 to 5 moving in random
## directions)") amends §6/§13's two cleaving rows and §15's read of them**: both
## cleaving tiers now split into a uniform random 2-5, and the ejection direction is
## uniform over the full circle (the ±15° cone is retired; see the constants), while
## the `x 1.2` speed is untouched. The explosion, the break cue and the blast the
## rock's death owes its neighbours are the field's (§7.3's wiring contract), because
## the field is what spawns. The tick for §6/§13/§15 is the owner's (the engine spec
## is owner-locked); this file and `asteroid_field.gd` cite the amendment until it
## lands.
##
## **S22.5 -- rock toughness, debris budgets and chip splinters (02 §5.3, owner-ticked
## 2026-09-30).** Every rock rolls its own `toughness` (A1) uniform in
## `OreTuning.toughness_min..max` at spawn, rolled by the field on its own seeded RNG
## and kept for life; the **gun** door (`apply_gun_work`) divides its amount by
## `OreTuning.size_toughness_mult[size_class()] x _toughness` (A2), so an XL under fire
## lasts several S rocks and the divisor never reaches the mining door (`apply_work`).
## A rock with **no ore** (`_bore_ore <= 0.0`, a gun-born fragment, a splinter, or a
## bare original) cracks at `OreTuning.fragment_work[size_class()]` work instead of on
## the first positive point (A3); the field rolls the 25 %-per-hit splinter off a
## non-cracking L/XL chip (A4) through `gun_chipped`. Reversals are the five rows'
## own (`ore_tuning.gd` carries each).
##
## Work, not damage: `apply_work` accumulates fractional work and converts it to
## whole ore units at `OreTuning.work_per_unit`, so 02 §7.1's "one completed
## extraction cycle pops one ore unit" and ENGINE_SPEC §6's 10 % gun rate are the
## same arithmetic with different callers. A gun's chip work comes through
## `apply_gun_work` (S13), which carries the gun attribution a shatter's payout
## reads; the arithmetic is otherwise untouched, and no weapon code lives here.
##
## **S13 — the reserve split and the shatter attribution (01 §5.6, 02 §5.1 Rule
## A).** `setup` receives the extractable whole units and the rock's own original
## yield (`_bore_ore`, additive `bore` argument), and holds aside
## `_reserve = _bore_ore x fragment_core_share`. Extraction realises only
## `yield_units` (the extractable). At the crack, `shatter_from_mining()` tells the
## field which route delivered the last work unit: a mining shatter pays the full
## reserve, a gun shatter at most `gun_burst_share x _bore_ore`.
##
## **Slice 0 (ruling 8): the rock is a real body.** A `RigidBody2D` with a heavy
## mass and linear damping, so a rammed rock is a near-wall and a knocked rock settles
## like the vacuum it is in (ruling 15/16: every body-body impact deals kinetic
## damage to both sides). S22.6 (18 §13's Rock drift damping row, owner 2026-09-30)
## lightens that damping -- a kicked rock now carries its own width many times over
## instead of settling inside it -- and gives debris a lighter one still; the two
## constants below carry the row and its superseded derivation. Gravity is off -- this is
## space, not a planet -- and `can_sleep` stays false so a rock is always able to answer a
## contact, which is what the ship's contact monitor needs to charge the ram to both
## sides.
##
## **Cleaving (ruling 17):** this file owns the *rules and the numbers*; the field
## that spawned the rock does the spawning, because it owns the generation RNG, the
## field count and the pickups' world parent. `AsteroidField._on_rock_cracked`
## reads `size_class()`, `mineral_id`, `tier`, `cleaves()` and `eject_velocity()`
## off the rock during the `cracked` emission (the node is freed right after), and
## spawns the fragments per `OreTuning.split_mix` / `PICKUP_BURST` (S14 replaced the
## retired `FRAGMENT_SPLIT` row below).
##
## The 02 §5 mineral and yield rolls happen in `AsteroidField`; this file only
## carries the result (mineral, tier, yield). The sprite's size class is a look and
## never a stat for throughput — a large rock mines exactly as fast as a small one —
## but ruling 17 makes it the cleaving class, which is why `setup` can be told which
## row to roll from.

signal cracked

## S22.5 (02 §5.3 A4): emitted once per **gun-door** contribution that did not crack
## this rock, so the field that spawned it can roll the chip splinter. Mining work
## never emits (a splinter is the gun's chip, not the laser's tailings) and a cracking
## hit never emits (its break is `cracked`).
signal gun_chipped

## 02 §7.1 / §15: one unit of ore per unit of work. The mining laser applies
## exactly this per cycle; a weapon applies a fraction of it per hit.
const WORK_PER_UNIT := 1.0

## Work is accumulated in floats, so a caller applying 0.1 per hit reaches
## 0.9999999999999999 after ten hits. The conversion forgives that much and no
## more, so 02 §6's 10 % rate is exact by intent rather than an eleventh hit.
const WORK_EPSILON := 0.0001

## Physics layer 1 (bit 0). Rocks are solid to ships, to shots and beams (ENGINE_SPEC
## §6) and -- since S22.7 (18 §13's Rock-rock contact row, owner tick R1) -- to each
## other. Godot pairs two bodies from both sides: `interacts_with` (either mask) decides
## the pair exists, and `collides_with` (this body's mask ∩ the peer's layer) decides
## whether this body's mass enters the solve. With the shipped `collision_mask` 0 the
## rock's inverse mass was forced to 0, so the solver resolved every contact as if the
## rock were immovable: the ship's half landed and the rock's half was dropped (C1
## measured `v_peak = 0.000 u/s`, `pos_delta = 0.000 u`). The hull is layer 2 / mask 1
## (`player_ship.tscn`'s `HullBody`), and mask 3 (layers 1|2) pairs rock-vs-hull (`3 &
## 2`) and rock-vs-rock (`3 & 1`) alike. A rock-rock contact stays a **nudge, not a
## fight** (R2): this file carries no contact monitor, so no damage route reads a
## rock-rock pair -- ruling 15/16's kinetic damage stays ship-vs-rock.
const COLLISION_LAYER := 1
const COLLISION_MASK := 3
const ROCK_GROUP: StringName = &"asteroid"

## The ram sink's conversion is the shipped 10 % gun chip (ENGINE_SPEC §6, ruling 17):
## the owner's 2026-09-21 re-scope rejected a second damage-to-work constant, so a ram
## and a shot chip a rock through the same arithmetic. S13: that rate is read live from
## `OreTuning.gun_chip_rate` (its default is `weapons.gd`'s `GUN_CHIP_RATE`), whose
## declared owner is the weapon file - this file no longer preloads it for the value.
const OreTuningScript := preload("res://game/ore_tuning.gd")

## The look rows of `LOOK_TEXTURES`: four size classes (S, M, L, XL) times three
## silhouettes. Row order is S1-S3, M1-M3, L1-L3, XL1-XL3, so the size class of a
## look is `_look / LOOKS_PER_SIZE`.
##
## S14 (02 §5.2): `SIZE_XL` is the fourth class (the owner's "i want 4 ... XL>L>M>S"),
## and its three looks are the L silhouettes scaled to `LOOK_WIDTHS`' 180 u until
## dedicated XL art is commissioned (staged). Reversal: drop the class and its row.
const LOOKS_PER_SIZE := 3
const SIZE_SMALL := 0
const SIZE_MEDIUM := 1
const SIZE_LARGE := 2
const SIZE_XL := 3
const SIZE_ANY := -1

## **RETIRED (S14, 02 §5.2): the split rule moved to `OreTuning.split_mix`.** A
## cleaving rock now rolls a *mixed* child set per kind (`XL -> L 1-3, M 2-4,
## S 2-5`; `L -> M 1-3, S 2-4`; `M -> S 1-3`; `S -> none`), so a single
## "one kind, one pair" row per tier can no longer express the rule, and no live
## arithmetic reads this const. It is **kept, not deleted**, because the frozen
## `rock_cleave` evidence probes still read it as their own wave's record
## (`tests/probe_rock_cleave.gd`'s SPLIT rows, `tests/probe_rock_cleave_a2.gd`'s
## CONST rows, `tests/probe_s12_*.gd`'s CONST line); deleting it would force edits
## to rows no wave has on its moved list. The shipped 2026-09-21 shape (`L -> 2-5`,
## `M -> 2-5`, `S -> none`) is the reversal of S14, restored by putting it back
## into `OreTuning.split_mix`.
const FRAGMENT_SPLIT: Dictionary = {
	SIZE_SMALL: Vector2i(0, 0),
	SIZE_MEDIUM: Vector2i(2, 5),
	SIZE_LARGE: Vector2i(2, 5),
}
const PICKUP_BURST: Vector2i = Vector2i(1, 2)

## §13's ejection row, speed half: fragments still "eject at `current_velocity x
## 1.2`" -- the owner's ruling changes the *direction*, never the speed.
const FRAGMENT_EJECT_MULT := 1.2

## §13's ejection row, direction half, as amended by the owner's 2026-09-21 ruling
## ("random fragments ... moving in random directions"): the field rotates the
## parent's own velocity by `randf_range(-cone, +cone)`, so a cone of **360.0** is
## the whole circle and the direction is uniform over it (the shipped ±15° cone is
## retired). One constant swap: `0.0` fires every fragment straight ahead and
## `15.0` restores the retired cone exactly.
const FRAGMENT_EJECT_CONE_DEG := 360.0

## §13's Ejection row as amended 2026-09-30 (S22.7, ticks S1+S2): every debris body's
## **whole** ejection vector -- the `FRAGMENT_EJECT_MULT` inherit plus the field's
## outward kick together -- scales by a per-child jitter uniform over this band, so a
## split never leaves at one speed. The field draws it (`asteroid_field.gd`'s
## `_deploy_debris`, the one carrier). Reversal: `(1.0, 1.0)`.
const FRAGMENT_SPEED_JITTER := Vector2(0.7, 1.3)

## The ejection row's mass weighting, applied to the same whole vector: the per-child
## scale is also `pow(m_M / child_mass, THIS)` with `m_M` the M-class mass
## (`ROCK_MASS_M`) -- splinters fly, boulders lumber. Reversal: exponent `0.0`.
const FRAGMENT_MASS_SPEED_EXP := 0.5

## §13's Rock mass row (S22.7, owner tick M1): `mass = ROCK_MASS_DENSITY × r²`, the
## density anchored so the M class (§13's own radius, 42 u) keeps today's 560 t --
## S 183 · M 560 · L 1 383 · XL 2 571 t at the shipped look widths (48/84/132/180 u).
## A pebble is no longer a wall and an XL is 4.6× one. `_configure_body` reads the
## **built** `_radius`, which is why `setup` runs it after `_build_look`. Reversal:
## the flat pair below.
const ROCK_MASS_DENSITY := 560.0 / (42.0 * 42.0)

## The M-class mass the ejection row's weighting divides by -- the density's own
## anchor, not a second literal (§13 pins the M class at 560 t).
const ROCK_MASS_M := ROCK_MASS_DENSITY * 42.0 * 42.0

## **SUPERSEDED (S22.7, 18 §13's Rock mass row): the flat one-mass rule** -- every
## rock weighed `ROCK_MASS_MULT ×` the `ROCK_MASS_REFERENCE` handling row
## (`ship_miner`, 4.0 × 140 = 560 t whatever the size). Kept, not deleted, as the
## reversal's record with **no live reader** (the `FRAGMENT_SPLIT` precedent): the
## frozen evidence probes read these as their own wave's record. Restoring it (and
## retiring `ROCK_MASS_DENSITY`/`ROCK_MASS_M`) puts the flat 560 t back on every
## class.
const ROCK_MASS_MULT := 4.0
const ROCK_MASS_REFERENCE: StringName = &"ship_miner"

## The rock's body damp (18 §13's Rock drift damping row, owner tick 2026-09-30,
## S22.6: "why asteroid upon breaking stops moving after few meters?"). In a vacuum a
## rock flies: continuous form `v(t) = v0 · e^(−d·t)`, carry `v0 / d`. The row's own
## targets -- the fragment kick's 150 u/s reads ≈106 u/s after one second and carries
## ≈429 u before settling; a cleave child, on its own `FRAGMENT_LINEAR_DAMP` below,
## reads ≈117 u/s and carries ≈600 u. Discrete check at 60 Hz (the integration the
## probe measured): `150 · (1 − 0.35/60)⁶⁰ ≈ 105.6 u/s`. The worst ram's 409 u/s
## hand-off (the unchanged collision half) then settles to the 10 u/s ceiling in
## `ln(409/10) / 0.35 ≈ 10.6 s` over ≈1 140 u.
##
## **SUPERSEDED -- the derivation `3.71` was sized to, kept as the record (not the
## target):** the heaviest hull at its §13 max speed under the +60 % afterburner
## carries the most momentum of the nine classes (Destroyer 300 t × 504 u/s =
## 151 200), a momentum-conserving contact with a `ROCK_MASS_MULT` rock hands it
## `2·151200/(300+560) ≈ 409 u/s`, and requiring that to fall to the 10 u/s drift
## ceiling inside one second gave `d = ln(409/10) ≈ 3.71·s⁻¹` -- discrete check
## `409 · (1 − 3.71/60)⁶⁰ ≈ 8.9 u/s`, measured 8.88 u/s by the M2 probe and again by
## the S22.6 probe for its "before" row. S22.6 replaced that one-second ceiling with
## the row above. Reversal: `3.71` here and on `FRAGMENT_LINEAR_DAMP`.
##
## `DAMP_MODE_REPLACE` is required: the project default (`physics/2d/
## default_linear_damp` 0.1) would otherwise be *added* and the derivation drift.
const LINEAR_DAMP := 0.35

## The damp a **debris** body carries (18 §13's Rock drift damping row): a cleave
## child and an S22.5 chip splinter are the rocks that should fly, so the field hands
## them this lighter damp through `AsteroidField._deploy_debris` -- the one placement
## and ejection carrier both debris paths ride -- instead of letting them inherit the
## parent's. Targets: the kick's 150 u/s carries ≈600 u (continuous `150 / 0.25`) and
## reads ≈117 u/s after one second. Reversal: `3.71` (the parent's own damp, what a
## pre-S22.6 child inherited).
const FRAGMENT_LINEAR_DAMP := 0.25

## The drift the **superseded** damping was sized to (10 u/s one second after the worst
## ram, above). Not a runtime clamp -- the number that derivation targeted, and the
## "settled" line the S22.6 probe still reads, so it reads the ceiling instead of
## repeating it. S22.6 keeps the constant as the record of why 3.71 existed.
const DRIFT_SPEED_CEILING := 10.0

## The twelve rock sprites: ENVIRONMENT_SPEC §4's three size tiers times three
## silhouettes plus S14's XL row, all pre-cut `rgba` (ASSET_CATALOG). Row order is
## S1-S3, M1-M3, L1-L3, XL1-XL3 -- the XL row reuses the three L textures (staged
## until dedicated XL art exists, 02 §5.2), so the fourth row is scale only.
##
## The `env/prop/` container is ASSET_NAMING_SPEC §3's (`env/` splits into
## `backdrop/ body/ poi/ prop/ pickup/ tile/`) and is the folder `pull.py` copies
## this family into. Slice 0 repaired these nine parse-time paths: the asset
## re-layout emptied `assets/env/` and re-pulled every file into its container, so
## the flat paths this file carried since wave 1 no longer resolved (the same
## sweep is still owed to `pickup.gd`, `sector.gd`, `sector_registry.gd` and the
## icon consumers — see the M2 report's blocker section).
const LOOK_TEXTURES: Array[Texture2D] = [
	preload("res://assets/env/prop/env_asteroid_S1.png"),
	preload("res://assets/env/prop/env_asteroid_S2.png"),
	preload("res://assets/env/prop/env_asteroid_S3.png"),
	preload("res://assets/env/prop/env_asteroid_M1.png"),
	preload("res://assets/env/prop/env_asteroid_M2.png"),
	preload("res://assets/env/prop/env_asteroid_M3.png"),
	preload("res://assets/env/prop/env_asteroid_L1.png"),
	preload("res://assets/env/prop/env_asteroid_L2.png"),
	preload("res://assets/env/prop/env_asteroid_L3.png"),
	preload("res://assets/env/prop/env_asteroid_L1.png"),
	preload("res://assets/env/prop/env_asteroid_L2.png"),
	preload("res://assets/env/prop/env_asteroid_L3.png"),
]

## Target world width per look row, in units, one entry per LOOK_TEXTURES row.
## No spec number exists for a rock's size and none is invented as a gameplay
## value: this is the phase's only visual constant, read off the shipped hull
## scale (the 905 px `ship_vanguard_side.png` at game.tscn's 0.0663 is 60.0 u
## long), so the three shipped tiers read at 0.8 / 1.4 / 2.2 hull lengths. S14 adds
## the XL row's 180 u (02 §5.2's own number: "XL renders the L silhouettes scaled to
## a 180 u target width", L being 132 u), three entries because the row reuses the
## three L silhouettes. Reversal is one edit; see the W3 report's open points.
const LOOK_WIDTHS: Array[float] = [
	48.0, 48.0, 48.0,
	84.0, 84.0, 84.0,
	132.0, 132.0, 132.0,
	180.0, 180.0, 180.0,
]

const LOOK_NODE: StringName = &"Look"
const SHAPE_NODE: StringName = &"Shape"

var mineral_id: StringName = &""
var tier: int = 0
var yield_units: int = 0
var work: float = 0.0

var _look := 0
var _sprite: Sprite2D = null
var _shape: CollisionShape2D = null
var _radius := 0.0
var _cracked := false
## The rock's own original yield (02 §5.1 Rule A's `_bore_ore`), in units. Ruling
## 17's "a yield-0 rock still cracks and despawns bare" is `_bore_ore <= 0`: a rock
## that never carried ore has nothing to cleave, so it cracks, emits and frees
## without fragments. S13: at setup this splits into the extractable `yield_units`
## (what extraction realises) and `_reserve` (what the shatter pays).
var _bore_ore := 0.0

## 02 §5.1 Rule A's reserve: the part of `_bore_ore` set aside at setup and never
## directly extractable, paid at the shatter. `_bore_ore - float(yield_units)`.
var _reserve := 0.0

## Which route delivered the work that cracked this rock (S13_BRIEF §2 rule 3):
## true = mining work (the laser's apply path, and a direct `apply_work` caller),
## false = gun chip work (`apply_gun_work`). The field reads it during `cracked` to
## attribute the shatter's payout. Defaults to mining so a direct `apply_work`
## caller (every committed probe and suite depleting a rock) reads as mining.
var _shatter_mining := true

## S16 (02 §5.2 ter): true when this rock was built by `AsteroidField._cleave`, so
## it is debris and splits again per its own size class whatever its bore. An
## original (a field spawn, a POI roll or a test fixture built through `setup`) is
## never marked. Runtime-only: one field, one method, one call site, never persisted.
var _cleave_child := false

## S22.5 (02 §5.3 A1): this rock's own rolled toughness, uniform in
## `OreTuning.toughness_min..max`. The field rolls it on its seeded RNG and passes it
## to `setup`; a `setup` call with no explicit value rolls on the global RNG (seedable
## by a caller that needs it), so every rock carries one. Read back through
## `toughness()`. `1.0` is A1's reversal (no roll).
var _toughness := 1.0

## S22.5 (02 §5.3 A4): the `Time.get_ticks_msec()` stamp of the last splinter this
## rock shed. The field's cap reads it through `splinter_ready`; runtime-only state
## that dies with the rock, like the marker above.
var _last_splinter_ms := -1


## 02 §5's roll lands here: which mineral the rock holds, its tier and how many ore
## units it carries. The look is rolled here too, uniformly over the shipped rows
## (the twelve silhouettes, nine before S14's XL row) on the global RNG (a caller
## that needs a reproducible look calls `seed()` first; the generation rolls that
## carry gameplay numbers are seeded in `AsteroidField`, not here).
##
## `size_class` (slice 0's addition, defaulted so every pre-existing three-argument
## call resolves exactly as before) pins the look row: a cleaving fragment must be
## the kind the split rolled, never whatever the uniform roll produced. `SIZE_ANY`
## keeps the uniform roll over all twelve silhouettes (nine before S14's XL row).
##
## `defer_shape` (S8, CONTRACTS §21 M1) hands the collision shape's install to the
## deferred queue instead of adding it here: a fragment is born inside a physics
## query flush (a hull contact cracks the parent), where Godot refuses
## `body_set_shape_disabled` and `body_set_shape_as_one_way_collision`. The radius
## is known before the node is (`world_radius` reads it), and the deferred install
## lands before the next step, so the fragment collides from its first eligible
## frame. A physics-frame call defers even without the flag.
## `bore` is S13's additive seam: the rock's **own original yield** (02 §5.1's
## `_bore_ore`) when the caller already holds it, which is every roll the field or a
## POI makes. The default `-1.0` derives it from `units` (the extractable) through
## `fragment_core_share`, which keeps every pre-S13 five-argument caller (and
## `test_combat_repair_c5.gd`'s `setup(..., 100, ...)`) exact: its `yield_units` is
## the number it passed and its reserve is the derived remainder.
##
## `toughness` is S22.5's seam (02 §5.3 A1): the field rolls it on its own seeded RNG
## and hands it in, so the value is reproducible under `setup(config)`'s seed. The
## default `-1.0` rolls on the global RNG (a caller that wants a repeatable one seeds
## it first), because every spawned rock must carry a roll; an explicit value pins a
## fixture exactly.
func setup(
	mineral: StringName,
	mineral_tier: int,
	units: int,
	size_class: int = SIZE_ANY,
	defer_shape: bool = false,
	bore: float = -1.0,
	toughness: float = -1.0
) -> void:
	mineral_id = mineral
	tier = mineral_tier
	yield_units = maxi(units, 0)
	work = 0.0
	_cracked = false
	_bore_ore = maxf(bore, float(yield_units)) if bore >= 0.0 else derive_bore(yield_units)
	_reserve = maxf(_bore_ore - float(yield_units), 0.0)
	_shatter_mining = true
	_cleave_child = false
	_toughness = toughness if toughness > 0.0 else _roll_toughness()
	_last_splinter_ms = -1
	add_to_group(ROCK_GROUP)
	collision_layer = COLLISION_LAYER
	collision_mask = COLLISION_MASK
	_build_look(size_class, defer_shape)
	## S22.7: after `_build_look`, so the mass reads the built `_radius` (the density
	## law). The reorder draws nothing: `_build_look`'s look roll is the only RNG draw
	## between the two, and `_configure_body` rolls none -- the RNG stream is
	## unchanged.
	_configure_body()


## Fractional work in, whole ore units out. Work accumulates across calls, so a
## 0.1-per-hit caller mines one unit every ten hits. Returns the units this call
## mined; the rock emits `cracked` and despawns when the last unit leaves.
##
## This is the **mining** door (S13_BRIEF §2 rule 3): the mining laser's apply
## path, and every direct caller. A gun's chip work must come through
## `apply_gun_work`, which attributes a shatter to the gun route instead.
func apply_work(amount: float) -> int:
	return _accumulate(amount, true)


## The **gun** door (projectile.gd's rock branch, weapons.gd's beam branch, and
## `apply_collision_damage`'s ram). S22.5 (02 §5.3 A2): the amount divides by
## `size_toughness_mult[size_class()] x toughness` before it reaches the accumulation,
## so a bigger rock (and a tougher roll) takes proportionally more fire. A rock that
## carries **no ore** (a cleave child, a splinter: `_bore_ore <= 0.0`) keeps the raw
## amount: its crack is A3's flat `fragment_work` budget, measured in the chip's own
## work (02 §5.3's own figures: a 10-damage chip is work 1.0 against an S budget of
## 2.0). A shatter it delivers is attributed to the gun route: its payout is capped at
## `OreTuning.gun_burst_share x _bore_ore` and the excess reserve burns.
func apply_gun_work(amount: float) -> int:
	var scaled := amount
	if _bore_ore > 0.0:
		scaled = amount / _gun_divisor()
	return _accumulate(scaled, false)


## The one work arithmetic both doors share. `from_mining` is stamped on the rock
## only when the last unit leaves, so a non-cracking chip cannot re-attribute an
## earlier shatter (a rock cracks once and is freed).
##
## S22.5 (02 §5.3 A3): a rock with **no ore** (`_bore_ore <= 0.0`) does not crack on
## the first positive work point; it must reach `fragment_work[size_class()]`. A rock
## that carried ore keeps the S13 rule exactly: it cracks when its extractable units
## run out, and the mining door's per-unit conversion is untouched (A5). Every
## non-cracking gun-door call emits `gun_chipped` for the field's A4 splinter roll.
func _accumulate(amount: float, from_mining: bool) -> int:
	if amount <= 0.0 or _cracked:
		return 0
	work += amount
	var per_unit := maxf(OreTuningScript.work_per_unit, WORK_EPSILON)
	var units := 0
	while yield_units > 0 and work >= per_unit - WORK_EPSILON:
		work = maxf(work - per_unit, 0.0)
		yield_units -= 1
		units += 1
	var cracks := yield_units <= 0 if _bore_ore > 0.0 else work >= _fragment_budget()
	if cracks:
		_shatter_mining = from_mining
		_crack()
	elif not from_mining:
		gun_chipped.emit()
	return units


## The rock's own original yield (02 §5.1's `_bore_ore`), read by the field at the
## shatter for the gun cap and the reserve.
func bore_ore() -> float:
	return _bore_ore


## S22.5 (02 §5.3 A1): this rock's own rolled toughness, its life multiplier on the
## gun door. Rolled once at spawn and kept: the accessor a suite reads instead of
## guessing at the roll.
func toughness() -> float:
	return _toughness


## S22.5 (02 §5.3 A4): true when this rock may shed another splinter at `now_ms`
## (the field's own `Time.get_ticks_msec()` reading): the first shed is always due and
## the cap is `OreTuning.splinter_interval` seconds per rock.
func splinter_ready(now_ms: int) -> bool:
	if _last_splinter_ms < 0:
		return true
	return float(now_ms - _last_splinter_ms) >= OreTuningScript.splinter_interval * 1000.0


## S22.5 (02 §5.3 A4): stamp the shed the field just rolled, starting the cap window.
func mark_splinter_shed(now_ms: int) -> void:
	_last_splinter_ms = now_ms


## 02 §5.1 Rule A's reserve: the part of `_bore_ore` a mining-attributed shatter
## pays in full and a gun-attributed one caps.
func reserve_units() -> float:
	return _reserve


## Which route delivered the work that cracked this rock (S13_BRIEF §2 rule 3).
func shatter_from_mining() -> bool:
	return _shatter_mining


## The extractable whole units a bore of `bore_total` leaves after the reserve is
## set aside. The field's roll path and its fragment handoff both use it, so the
## split cannot drift between a field's own rocks and a cleave's children.
static func extractable_units(bore_total: int) -> int:
	return maxi(bore_total - reserve_units_of(bore_total), 0)


## The whole units 02 §5.1 Rule A sets aside from a bore of `bore_total`.
static func reserve_units_of(bore_total: int) -> int:
	var share := clampf(OreTuningScript.fragment_core_share, 0.0, 1.0)
	return clampi(roundi(float(bore_total) * share), 0, maxi(bore_total, 0))


## The `_bore_ore` a five-argument `setup` implies: the extractable units carry the
## `1 - fragment_core_share` share, so the bore is `units / (1 - share)`. A share of
## 1.0 (or more) leaves nothing extractable, so the bore is then the units
## themselves and the whole rock is reserve.
static func derive_bore(extractable_units_count: int) -> float:
	var keep := clampf(1.0 - OreTuningScript.fragment_core_share, 0.0, 1.0)
	if keep <= 0.0:
		return float(extractable_units_count)
	return float(extractable_units_count) / keep


## The other half of a body-body impact (ENGINE_SPEC §4.2 item 6, CONTRACTS §4): the
## hull's contact monitor charges its own side and offers the peer's half through this
## method, which `NpcShip` answers by passing it to `take_damage`. A rock carries no
## hull pool, so its half goes through the rock's own mining channel at the shipped gun
## chip rate, exactly what a beam (`weapons.gd:_apply_beam`) and a bolt
## (`projectile.gd:_hit_rock`) apply, and is therefore readable as `work` and
## `yield_units` rather than vanishing. Measured (C1's 450 u/s ram at a 560 t medium
## rock): the offer is 186.179, so the rock gains 18.618 work, 18 ore units leave it and
## the rock moves 73.351 u/s / 21.056 u.
func apply_collision_damage(amount: float) -> void:
	apply_gun_work(amount * OreTuningScript.gun_chip_rate)


func is_depleted() -> bool:
	return yield_units <= 0


## Which look row this rock rolled, for probes and review sheets.
func look_index() -> int:
	return _look


## The look row this rock rolled: `SIZE_SMALL`, `SIZE_MEDIUM`, `SIZE_LARGE` or
## `SIZE_XL` (ruling 17's cleaving class). Read off the look, so it is the sprite the
## player sees that decides what the rock breaks into.
func size_class() -> int:
	return floori(float(_look) / float(LOOKS_PER_SIZE))


## S16 (02 §5.2 ter): the field marks every fragment it builds in `_cleave` with
## this, so parentage -- not ore -- gates a *fragment's* cleave. Only the cleave
## itself may mark: a field spawn, a POI roll and any `setup` fixture stays an
## original and keeps ruling 17's yield-0 law below.
func mark_cleave_child() -> void:
	_cleave_child = true


## S22.6 (18 §13's Rock drift damping row): the lighter damp a debris body carries, so
## a cleave child and an S22.5 splinter fly instead of inheriting the parent rock's
## damp. `AsteroidField._deploy_debris` calls this on every body it places, which is
## the one carrier both debris paths ride; a field spawn and a `setup` fixture never
## call it, so an original keeps `LINEAR_DAMP`. The mode is restated because this is
## the debris body's whole damp story, not a delta on the parent's.
func apply_fragment_damp() -> void:
	linear_damp = FRAGMENT_LINEAR_DAMP
	linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE


## Ruling 17's "a yield-0 rock still cracks and despawns without fragments": only a
## rock that rolled ore cleaves. The field asks this before spawning anything. S16
## (02 §5.2 ter) amends it for debris: a rock born of a cleave (`_cleave_child`)
## splits per its own size class whatever its bore, so shot debris re-splits; an
## original that rolled no ore still breaks bare and cleaves into nothing.
func cleaves() -> bool:
	return _bore_ore > 0.0 or _cleave_child


## The velocity the fragments inherit: `current_velocity × 1.2` of the §13 cleaving
## row, read while the rock still exists (the `cracked` emission happens before the
## free). The direction is the field's roll over `FRAGMENT_EJECT_CONE_DEG`, because
## the field owns the RNG: 360° there means uniform over the full circle. This is the
## shape's half only — CONTRACTS §14's outward burst is `AsteroidField`'s
## (`FRAGMENT_OUTWARD_KICK` along the spawn radial), because the fragment's spawn
## point is the field's to compute.
func eject_velocity() -> Vector2:
	return linear_velocity * FRAGMENT_EJECT_MULT


## The collision radius the sprite's shorter side implies, in world units.
func world_radius() -> float:
	if _shape == null or _shape.shape == null:
		return _radius
	return (_shape.shape as CircleShape2D).radius


func _crack() -> void:
	if _cracked:
		return
	_cracked = true
	cracked.emit()
	queue_free()


## S22.5 (02 §5.3 A1): the roll itself, uniform over the live band. Read live so the
## F1 overlay can retune the band and the next spawn takes it.
func _roll_toughness() -> float:
	return randf_range(OreTuningScript.toughness_min, OreTuningScript.toughness_max)


## S22.5 (02 §5.3 A2): the gun door's divisor,
## `size_toughness_mult[class] x toughness`. The epsilon guards a tuned-to-zero table
## or roll from turning the door into a divide-by-zero.
func _gun_divisor() -> float:
	var class_mult := float(
		OreTuningScript.size_toughness_mult.get(size_class(), 1.0)
	)
	return maxf(class_mult * _toughness, WORK_EPSILON)


## S22.5 (02 §5.3 A3): the work a no-ore rock needs to crack, by its own class.
func _fragment_budget() -> float:
	return maxf(float(OreTuningScript.fragment_work.get(size_class(), 0.0)), WORK_EPSILON)


## Slice 0's rigid body: a heavy, damped, gravity-free rock (ruling 8). The mass is
## §13's Rock mass row (S22.7): `ROCK_MASS_DENSITY × _radius²` off the **built**
## look, so a rock weighs what its size says (S 183 / M 560 / L 1 383 / XL 2 571 t).
func _configure_body() -> void:
	mass = ROCK_MASS_DENSITY * _radius * _radius
	linear_damp = LINEAR_DAMP
	linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	## Space, not a planet: the project's 980 u/s² 2D gravity would rain the field.
	gravity_scale = 0.0
	## A sleeping body stops answering contacts, and the ship's contact monitor is
	## what charges a ram to both sides (ruling 15). Rocks are few and cheap.
	can_sleep = false


func _build_look(size_class: int, defer_shape: bool = false) -> void:
	_look = _roll_look(size_class)
	var texture := LOOK_TEXTURES[_look]
	var scale_factor := LOOK_WIDTHS[_look] / maxf(float(texture.get_width()), 1.0)
	_sprite = Sprite2D.new()
	_sprite.name = LOOK_NODE
	_sprite.texture = texture
	_sprite.scale = Vector2(scale_factor, scale_factor)
	add_child(_sprite)
	var shorter_side := float(mini(texture.get_width(), texture.get_height()))
	_radius = 0.5 * shorter_side * scale_factor
	if defer_shape or Engine.is_in_physics_frame():
		_install_shape.call_deferred()
		return
	_install_shape()


func _install_shape() -> void:
	var circle := CircleShape2D.new()
	circle.radius = _radius
	_shape = CollisionShape2D.new()
	_shape.name = SHAPE_NODE
	_shape.shape = circle
	add_child(_shape)


## A pinned row rolls one of its three silhouettes -- `SIZE_XL` is a row like any
## other, so an XL request lands in the row it asked for and never in the uniform
## fallback; `SIZE_ANY` (or an out-of-range request) keeps the original uniform roll
## over every shipped look (twelve since S14's XL row), so a pre-slice-0 caller's
## shape is unchanged. S14 makes the *spawn* size-first instead:
## `AsteroidField._spawn_rock` rolls the size class from
## `OreTuning.spawn_size_weights` and asks this function for the row's look.
func _roll_look(size_class: int) -> int:
	if size_class < SIZE_SMALL or size_class > SIZE_XL:
		return randi_range(0, LOOK_TEXTURES.size() - 1)
	var first := size_class * LOOKS_PER_SIZE
	return randi_range(first, first + LOOKS_PER_SIZE - 1)
