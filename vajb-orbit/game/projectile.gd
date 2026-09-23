class_name Projectile
extends Area2D
## One shot in flight: ENGINE_SPEC section 4.1's four travelling families (bolt,
## slug, rocket, mine) plus section 4.2 items 7/8's push physics at the hit site.
##
## Built entirely in code by `configure(config)` (the slice-2 brief's pinned key
## set), so there is no scene file: the shot's sprite is built here out of the
## shipped `assets/fx/` sheets (`_sync_visual`) - the same art every other effect
## draws from, never a re-cut or a re-key of it (ASSET_WIRING_HANDOFF section 3).
##
## Contract: ENGINE_SPEC sections 4.1 (families, travel, shield rule, "kinetics
## fizzle at max range", "rockets require a lock to home, without a lock they
## dumb-fire", "mines arm after 2 s, proximity trigger 60 u", "rockets are
## destructible, any weapon hit kills them"), 4.2 items 7-8 (recoil is the
## shooter's half and lives on the hull; knockback and the blast wave are the hit
## site's), 6 (guns on rocks: 10 % of the DPS-equivalent rate, depletion only,
## ruling 17), 4.6 (a flare decoy retargets a homing rocket: `retarget` is this
## file's half), 13 (ranges, speeds, rocket/mine rows); docs/CONTRACTS.md sections
## 4/5/8.1 (the `Impact` helpers, the `&"npc_ship"` group); the slice-2 brief's
## pinned interface item 3.
##
## Damage leaves through the pinned target seam - `take_damage(amount,
## bypass_shield, ctx)` when the target takes the context, else
## `take_damage(amount, bypass_shield)`, else `PlayerState.damage(amount,
## bypass_shield, ctx)` - so a hit lands on whatever the pipeline's owners ship
## (W2's `Damage.apply` calls the same method on the same targets).
##
## Layers. Rocks are layer 1 (`Asteroid.COLLISION_LAYER`), the player hull is
## layer 2 (`player_ship.tscn`'s `HullBody`); projectiles own bit 3 so a shot can
## find a rocket without seeing rocks or hulls. A hull on another layer is
## invisible to shots, so slice-2's NPC hulls must share layer 2 (reported).

signal detonated(pos: Vector2, damage: float, bypass_shield: bool)

const ImpactScript := preload("res://game/impact.gd")
const FxScript := preload("res://game/fx.gd")

const KIND_BOLT: StringName = &"bolt"
const KIND_SLUG: StringName = &"slug"
const KIND_ROCKET: StringName = &"rocket"
const KIND_MINE: StringName = &"mine"

## Section 4.2 item 5's `family` key, derived from the kind rather than passed in:
## the family table's single owner is `weapons.gd`, and it configures a kind.
const KIND_FAMILIES: Dictionary = {
	&"bolt": &"kinetic",
	&"slug": &"kinetic",
	&"rocket": &"missile",
	&"mine": &"deployable",
}

## A rocket is the warhead a weapon can shoot down (section 4.1); a bolt, slug and
## mine are not named as destructible, so only this kind answers true.
const DESTRUCTIBLE_KINDS: Array[StringName] = [&"rocket"]

const ROCK_GROUP: StringName = &"asteroid"
const PLAYER_GROUP: StringName = &"player_ship"
const NPC_GROUP: StringName = &"npc_ship"
const PROJECTILE_GROUP: StringName = &"projectile"

const PROJECTILE_LAYER := 4
const ROCK_LAYER_MASK := 1
const HULL_LAYER_MASK := 2
const TARGET_MASK := ROCK_LAYER_MASK | HULL_LAYER_MASK

## The shape's own radius: how close a shot must pass a body to touch it, and how
## close a shot must come to a decoy to detonate on it. No spec value exists for a
## projectile's cross-section, so this is a detection radius, reported as such; the
## sprite's size comes from the sheet's own pixels (`SHEETS`) and never reads this.
const HIT_RADIUS := 4.0

## --- The shot's art (FX_SPEC sections 0 and 1.1, Phase G's trail sheet) -----
##
## One row per kind: the per-frame file the kind draws, the art's own ink box inside that
## frame (the re-cut frames share one canvas per effect, so a single-frame read takes the
## object's own box), that box's pixel size, the length it reads at in world units, and -
## for a multi-frame row - the frame rate and whether it loops.
##
## The re-cut (2026-09-21) ships `fx_<effect>_fN.png` beside the untouched 2K masters and
## every frame carries its own alpha, so the masters are no longer an atlas source and the
## blend is the sheet's own alpha (`Fx.alpha_material`). FX_SPEC section 2's amendment is
## the reason the frames are separate files at all: a `GPUParticles2D` draws its texture at
## the texture's own size.
##
## FX_SPEC section 1.1 gives the bolt sheet's two objects a 64 px light and a 96 px medium
## read, so the thin and thick cuts of that sheet are exactly those lengths on screen - and
## the sheet's own four frames are those two tiers bright and dimming (`_f1`/`_f2` light,
## `_f3`/`_f4` medium), so the still each kind draws is the tier's bright frame. The mine
## and the trail have no size row and take a third of a hull and a hull's own length plus a
## little (measured against the 43 px Vanguard side view, reported).
##
## Tier mapping: the cannon's `bolt` is the sheet's thin object and the railgun's
## heavier `slug` its thick one.
const SHEETS: Dictionary = {
	&"bolt": {
		&"frames": ["res://assets/fx/fx_laser_bolt_f1.png"],
		&"region": Rect2(245.0, 35.0, 310.0, 92.0),
		&"source": Vector2(310.0, 92.0),
		&"world": 64.0,
	},
	&"slug": {
		&"frames": ["res://assets/fx/fx_laser_bolt_f3.png"],
		&"region": Rect2(75.0, 37.0, 651.0, 89.0),
		&"source": Vector2(651.0, 89.0),
		&"world": 96.0,
	},
	## FX_SPEC section 7.2's mine: the deployable's own art, all four of its frames (the
	## lamp's own pulse), read at the row's own 22 u. It replaces the `fx_ember_pulse`
	## crop the wiring used until 2026-09-21 (owner ruling), and its frames are the mine
	## family's burst too (`FEEDBACK`'s `mine_burst`).
	&"mine": {
		&"frames": [
			"res://assets/fx/fx_mine_f1.png",
			"res://assets/fx/fx_mine_f2.png",
			"res://assets/fx/fx_mine_f3.png",
			"res://assets/fx/fx_mine_f4.png",
		],
		&"region": Rect2(41.0, 42.0, 661.0, 653.0),
		&"source": Vector2(661.0, 653.0),
		&"world": 22.0,
		&"fps": FxScript.DEFAULT_FPS,
		&"loop": true,
	},
	&"rocket": {
		&"frames": [
			"res://assets/fx/fx_missile_trail_f1.png",
			"res://assets/fx/fx_missile_trail_f2.png",
			"res://assets/fx/fx_missile_trail_f3.png",
			"res://assets/fx/fx_missile_trail_f4.png",
		],
		&"source": Vector2(552.0, 248.0),
		&"world": 48.0,
		&"fps": 12.0,
		&"loop": true,
	},
}

## The sprite's node name, so a probe (or a tracer) can find it without a walk.
const VISUAL_NODE: StringName = &"Visual"

## Above the rocks and hulls a shot crosses (both draw at the default 0).
const VISUAL_Z := 1

## --- The hit's feedback (F2): the cue per target kind and the blast sheets -------
##
## The shot's own fire is `weapons.gd`'s half of this wave; the hit is this file's.
## AUDIO_SPEC section 8 gives an impact its own cue per target kind (S4 impacts, S5
## shield hits) and S6 a barrier bed for a shield that holds; FX_SPEC section 1.4 gives
## a destruction the five-frame explosion and section 7.2 the arc, the shield break and
## the low-hull plume. F1's `fx.gd` owns the mechanics (frame, material, scale,
## lifetime) and every sheet here is spawned through it.
##
## The three target kinds a shot can land on. A rock and a hull are two different
## sounds; a shield takes the third and reads as its own bed while it holds.
const IMPACT_KIND_ROCK: StringName = &"rock"
const IMPACT_KIND_HULL: StringName = &"hull"
const IMPACT_KIND_SHIELD: StringName = &"shield"

const IMPACT_CUES: Dictionary = {
	IMPACT_KIND_ROCK: &"sfx_impact_rock",
	IMPACT_KIND_HULL: &"sfx_impact_hull",
	IMPACT_KIND_SHIELD: &"sfx_impact_shield_hit",
}

## AUDIO_SPEC S6's shield-up bed (a loop-material file, handoff section 1.4), held
## while a shield holds and put out when it drops.
const SHIELD_LOOP_CUE: StringName = &"sfx_impact_shield_loop"

## The wave's blast cue: AUDIO_SPEC S3's warhead bang, the pool F1 published
## (`sfx_weapon_explosion_01/02`, F1 report section "Pools added to AudioManager").
const BLAST_CUE: StringName = &"sfx_weapon_explosion"

## AUDIO_SPEC section 4.5: S12, the one-shot that pairs with the thruster bed - "fires
## once on booster activation", and its take is the cue the station already plays at
## launch, so no second asset is owed. It has no pool row, so the cue door falls back to
## `play_sfx` (the same route the station's LAUNCH cue takes).
const BOOST_CUE: StringName = &"sfx_ship_boost_01"

## FX_SPEC section 1.8 and Phase G's section 7.1 both put a hull's damage states at
## "hull fraction < 25 %", so the plume comes up below exactly that line.
const LOW_HULL_FRACTION := 0.25

## The plume emitter's node name, so a hull can find and drop its own.
const PLUME_NODE: StringName = &"DamagePlume"

## Above the shot's own sprite (VISUAL_Z): a hit reads over the art.
const FEEDBACK_Z := 2

## FX_SPEC section 1.5: the ripple grows 0 -> 1.5x with the alpha fade over 0.3 s.
const RIPPLE_SCALE := 1.5
const RIPPLE_SECONDS := 0.3

## The plume emitters' engine numbers. FX_SPEC section 7.2 fixes the look and 7.3 the
## node ("a lifetime owner - the emitter frees with its target") but states no rate,
## size or speed; these are the wiring's own and are reported as such. The two scale
## constants are factors on the row's own read, so a puff is a plume-sheet-sized puff
## rather than the master's 755 x 1580 pixels.
const PLUME_AMOUNT := 16
const PLUME_LIFETIME := 1.4
const PLUME_PREPROCESS := 0.6
const PLUME_RADIUS := 14.0
const PLUME_SPREAD := 25.0
const PLUME_SPEED_MIN := 8.0
const PLUME_SPEED_MAX := 24.0
const PLUME_SCALE_MIN := 0.5
const PLUME_SCALE_MAX := 1.1

## --- The thruster trail's engine numbers (FX_SPEC section 1.3, amended 2026-09-21) --
##
## The amendment is the one place these values exist: one `GPUParticles2D` per engine
## cell, parented to the hull, `local_coords = false` so the streaks trail in world
## space; active while the thrust input is held **or** the ratio is at or above 0.15;
## 20 streaks/s at that floor rising linearly to 60/s at 1.0; 0.4 s per streak (the
## section's own alpha falloff); a 24 u streak at the floor rising to 56 u; 6 u wide;
## additive ember at alpha 0.35 rising to 0.85.
##
## The emitter's capacity is the spec's own top rate over its own lifetime (24), and the
## per-frame rate rides `amount_ratio` on top of it - the documented way to scale a GPU
## emitter's output without reallocating its buffer (which would drop every live streak).
##
## The tail point is a seam: `PlayerShip.thruster_anchors()` returns one point behind the
## hull's centre today and one point per engine cell once `ShipFit.mount_offset` lands
## (wave P2-A). Nothing here knows which.
const TRAIL_NODE_PREFIX := "ThrusterTrail"
const TRAIL_RATIO_MIN := 0.15
const TRAIL_RATE_MIN := 20.0
const TRAIL_RATE_MAX := 60.0
const TRAIL_LIFETIME := 0.4
const TRAIL_LENGTH_MIN := 24.0
const TRAIL_LENGTH_MAX := 56.0
const TRAIL_WIDTH := 6.0
const TRAIL_ALPHA_MIN := 0.35
const TRAIL_ALPHA_MAX := 0.85

## FX_SPEC section 1.3's streak points its hot head away from its transparent tail, and
## the shipped master reads exactly that way (measured: mean luminance 37.6 -> 18.2 ->
## 9.9 over the plate's thirds, left to right). A hull-local emitter therefore turns half
## a turn so the head sits on the anchor and the tail streams behind it, and its origin
## is pulled back by half a streak so the head - not the streak's middle - is the point
## that rides the engine.
const TRAIL_TURN := PI

## The audio service, reached the way every other caller reaches it (anchor at the
## tree root). A static helper has no tree of its own, so a caller passes the node that
## has one.
const AUDIO_SERVICE: StringName = &"AudioManager"

## One row per effect: the per-frame files the effect draws, in the art's own reading
## order, the largest object's pixel size, the length its longest side reads at in world
## units, and - for a multi-frame row - the frame rate and whether it loops.
##
## Every row addresses `fx_<effect>_fN.png` directly. The 2026-09-21 re-cut put every
## effect on its own frames (beside the untouched 2K masters, which are no longer an atlas
## source) and gave each frame its own alpha, so the rows carry the *files* and the blend
## is the sheet's own alpha.
##
## A row that **plays a sequence** (the explosion, the secondary burst, the arc, the chip
## sparks, the shatter) draws its frames whole: the re-cut gives a sequence's frames one
## shared canvas on purpose, so a frame's object grows and shrinks inside a fixed box and
## the relative size survives the split. `source` is then that canvas, measured off the
## files.
##
## A row that draws **one frame** of a sequence (the streak, the ring, the plume, the dust,
## the charge) carries that frame's own ink box as `region`, so the row's `world` reads the
## *object* rather than the frame's margin - which is also what keeps the trail's streak
## on the engine instead of floating behind it. The region is measured off the frame's ink
## (the objects are found by masking the ink, never by cutting on a divider - AGENTS.md's
## asset rule). FX_SPEC section 2's amendment blesses the one-frame read: "a one-frame
## consumer can always draw `_f1`".
##
## `world` is measured against the shipped Vanguard side view, 59 x 30 world units at the
## scene's own 0.0663 sprite scale, where the spec states no size (reported).
##
## Rates are the spec's own: 15 FPS for the explosion (section 1.4), 20 FPS for the arc
## (section 7.2's "0.2 s per arc" over four frames), 10 FPS for the shield break
## (section 7.1's "outward over 0.4 s" over four frames), section 1.5's 0.3 s for
## the ripple, and section 1.6's "4-frame mini sheet at 20 FPS = 0.2 s" for the chip
## sparks. The secondary burst is the one rate ASSET_EXPANSION_SPEC section 7
## leaves unstated; it takes the explosion's own. The mine's own frames are the one
## sequence the spec gives no rate, so they take `Fx.DEFAULT_FPS` (the helper's
## documented fallback, reported).
##
## `chip` is FX_SPEC section 1.6 / section 3's mining chip sparks, the sheet
## `fx_mining_beam.png` names for exactly this. It is a beam's read rather than a
## projectile's in this table's terms: `weapons.gd`'s rock branch spawns it when a gun
## chips an asteroid, through `spawn_chip_sparks`, and `mining_laser.gd`'s own chip read
## (L65) takes the same door. Section 1.6 states no world size for
## the burst, so `world` is the wiring's own and matches section 7.2's arc read of 40
## (reported).
const FEEDBACK: Dictionary = {
	&"explosion": {
		&"frames": [
			"res://assets/fx/fx_explosion_f1.png",
			"res://assets/fx/fx_explosion_f2.png",
			"res://assets/fx/fx_explosion_f3.png",
			"res://assets/fx/fx_explosion_f4.png",
			"res://assets/fx/fx_explosion_f5.png",
		],
		&"source": Vector2(904.0, 776.0),
		&"world": 96.0,
		&"fps": 15.0,
	},
	&"secondary": {
		&"frames": [
			"res://assets/fx/fx_secondary_explosion_f1.png",
			"res://assets/fx/fx_secondary_explosion_f2.png",
			"res://assets/fx/fx_secondary_explosion_f3.png",
			"res://assets/fx/fx_secondary_explosion_f4.png",
		],
		&"source": Vector2(352.0, 312.0),
		&"world": 48.0,
		&"fps": 15.0,
	},
	&"arc": {
		&"frames": [
			"res://assets/fx/fx_arc_spark_f1.png",
			"res://assets/fx/fx_arc_spark_f2.png",
			"res://assets/fx/fx_arc_spark_f3.png",
			"res://assets/fx/fx_arc_spark_f4.png",
		],
		&"source": Vector2(912.0, 672.0),
		&"world": 40.0,
		&"fps": 20.0,
	},
	&"shield_break": {
		&"frames": [
			"res://assets/fx/fx_shield_break_f1.png",
			"res://assets/fx/fx_shield_break_f2.png",
			"res://assets/fx/fx_shield_break_f3.png",
			"res://assets/fx/fx_shield_break_f4.png",
		],
		&"source": Vector2(536.0, 624.0),
		&"world": 64.0,
		&"fps": 10.0,
	},
	&"chip": {
		&"frames": [
			"res://assets/fx/fx_mining_beam_f1.png",
			"res://assets/fx/fx_mining_beam_f2.png",
			"res://assets/fx/fx_mining_beam_f3.png",
			"res://assets/fx/fx_mining_beam_f4.png",
		],
		&"source": Vector2(440.0, 424.0),
		&"world": 40.0,
		&"fps": 20.0,
	},
	&"ripple": {
		&"frames": ["res://assets/fx/fx_shield_ripple_f1.png"],
		&"region": Rect2(196.0, 192.0, 343.0, 334.0),
		&"source": Vector2(343.0, 334.0),
		&"world": 64.0,
	},
	&"plume": {
		&"frames": ["res://assets/fx/fx_smoke_plume_f1.png"],
		&"region": Rect2(110.0, 58.0, 244.0, 882.0),
		&"source": Vector2(244.0, 882.0),
		&"world": 40.0,
	},
	## FX_SPEC section 1.3's single streak, the row the thruster emitters draw from. The
	## section's own amendment gives it a length *pair* (24 u -> 56 u by ratio), so the row
	## carries the art and its measured size and the lengths live in `TRAIL_*` above. The
	## frame's ink box is what the emitter draws, so the drawn quad is the streak itself
	## (24 x 6 u at the floor) rather than the frame's own canvas.
	&"trail": {
		&"frames": ["res://assets/fx/fx_engine_trail_f1.png"],
		&"region": Rect2(253.0, 18.0, 159.0, 26.0),
		&"source": Vector2(159.0, 26.0),
	},
	## FX_SPEC section 5 row 3's dust streak: the camera's own read (one object, 147 x 29).
	&"dust": {
		&"frames": ["res://assets/fx/fx_dust_streak_f1.png"],
		&"region": Rect2(222.0, 17.0, 147.0, 29.0),
		&"source": Vector2(147.0, 29.0),
		&"world": 12.0,
	},
	## FX_SPEC section 7.1's dash charge ("one-shot on booster activation, proposed 32 u,
	## 0.2 s"): a single frame the engine scales, so the row carries the read and the fade.
	&"dash_charge": {
		&"frames": ["res://assets/fx/fx_dash_charge_f1.png"],
		&"region": Rect2(178.0, 194.0, 580.0, 572.0),
		&"source": Vector2(580.0, 572.0),
		&"world": 32.0,
		&"seconds": 0.2,
	},
	## The mine family's own burst (owner ruling 2026-09-21: "fx_mine ... gives the mine
	## family its own sprite and burst"). It is the mine's own four frames, read at the
	## mine's own 22 u, played once at the point a mine detonates - the same art as the
	## deployed sprite, which is the one asset the mine family owns, so no size or rate is
	## new: `world` is `SHEETS`' mine row and the rate is the helper's documented fallback.
	## The detonation keeps FX_SPEC section 1.4's explosion beside it, so removing this row
	## is the whole reversal.
	&"mine_burst": {
		&"frames": [
			"res://assets/fx/fx_mine_f1.png",
			"res://assets/fx/fx_mine_f2.png",
			"res://assets/fx/fx_mine_f3.png",
			"res://assets/fx/fx_mine_f4.png",
		],
		&"region": Rect2(41.0, 42.0, 661.0, 653.0),
		&"source": Vector2(661.0, 653.0),
		&"world": 22.0,
		&"fps": FxScript.DEFAULT_FPS,
	},
}

## Section 4.2 item 7's terms: the shooter's recoil is `mass x muzzle_speed` and a
## hit's knockback is 40 % of `0.5 x mass x speed^2`. Section 13 pins neither a
## projectile's mass nor any of the six weapons' projectile weight, so every shot
## carries this mass and the term is a one-line tunable (reported).
const DEFAULT_MASS := 1.0

const SHAPE_NODE: StringName = &"Shape"

## Blast range: `I(d) = P0 / (1 + d^2)` is its own range (impact.gd's reading of
## section 4.2 item 8), so the query radius is where the impulse falls to one
## unit-impulse - about 63 u, the floor below which a push is not worth applying.
const MIN_SHOCKWAVE_IMPULSE := 1.0
const MAX_SHOCKWAVE_BODIES := 32

## The rock break's own read of section 1.4's explosion (the owner's 2026-09-21
## asteroid ruling: rocks "should somehow explode"). A hull dies at the row's shipped
## 96 u; a rock is a thing of its own size, so its break is `diameter x 1.2`, clamped
## to the row's own 96 u floor and a 224 u ceiling. The floor is the row's own `world`
## (a small rock's 1.2 x read - about 58 u - would otherwise draw a spark), and the
## ceiling sits above the largest shipped look's read (LOOK_WIDTHS' 132 u x 1.2 =
## 158.4 u) so a stray radius cannot blow the effect up past the spec's own scale.
## One optional `world` argument on `spawn_sheet` is the whole mechanism; these three
## constants are the reversal.
const ROCK_BREAK_WORLD_SCALE := 1.2
const ROCK_BREAK_WORLD_MIN := 96.0
const ROCK_BREAK_WORLD_MAX := 224.0

var kind: StringName = KIND_BOLT
var speed := 0.0
var damage := 0.0
var bypass_shield := false
var homing := false
var turn_rate := 0.0
var mass := DEFAULT_MASS
## Flight limit: the shot fizzles once it has travelled this far (0 = no limit).
var max_range := 0.0
## The mine's two rows: arm after `arm_time` seconds, trigger inside
## `trigger_radius` of a hull's centre.
var arm_time := 0.0
var trigger_radius := 0.0
## Guns on rocks (section 6, ruling 17): the fraction of a landed hit's damage that
## becomes depletion work. The rate itself is `weapons.gd`'s (the family table's
## owner) and arrives in `configure`.
var chip := 0.0

var _velocity := Vector2.ZERO
var _lock_target: Node2D = null
var _decoy: Node2D = null
var _source: Node2D = null
var _shape: CollisionShape2D = null
## The sprite the shot is drawn with, and the kind it was built for (the kind is
## fixed by `configure`, so the two can only differ while a node is being rebuilt).
var _visual: Node2D = null
var _visual_kind: StringName = &""
var _travelled := 0.0
var _armed := false
var _arm_clock := 0.0
var _spent := false

## Whether a target's `take_damage` takes section 4.2 item 5's context, cached per
## target class (the answer is a property of the script, not the instance).
var _ctx_arity: Dictionary = {}


## The pinned configuration entry point. Every pinned key is read here - `kind`,
## `speed`, `damage`, `bypass_shield`, `homing`, `target`, `turn_rate`, `source` -
## plus five additive keys the projectile cannot derive on its own: `direction`
## (the muzzle's aim, which a cursor-only design would put in the weapon and a
## second caller such as an NPC could not reproduce), `range` (the fizzle
## distance), `arm`/`trigger` (the mine rows), `mass` (section 4.2 item 7's term)
## and `chip` (section 6's 10 %). Keys are normalized to `StringName`, so a caller
## passing plain strings still lands.
##
## Call order: `configure` first, then `add_child`, then the spawner's
## `global_position`. Both orders work (`_ready` only needs the shape, and the
## collision exceptions are applied again at the end of `configure` when the node
## is already in the tree).
func configure(config: Dictionary) -> void:
	var cfg := {}
	for key: Variant in config:
		cfg[StringName(key)] = config[key]
	kind = StringName(cfg.get(&"kind", KIND_BOLT))
	speed = maxf(_number(cfg.get(&"speed")), 0.0)
	damage = maxf(_number(cfg.get(&"damage")), 0.0)
	bypass_shield = bool(cfg.get(&"bypass_shield", false))
	homing = bool(cfg.get(&"homing", false))
	turn_rate = maxf(_number(cfg.get(&"turn_rate")), 0.0)
	mass = maxf(_number(cfg.get(&"mass"), DEFAULT_MASS), 0.0)
	max_range = maxf(_number(cfg.get(&"range")), 0.0)
	arm_time = maxf(_number(cfg.get(&"arm")), 0.0)
	trigger_radius = maxf(_number(cfg.get(&"trigger")), 0.0)
	chip = clampf(_number(cfg.get(&"chip")), 0.0, 1.0)
	var aim: Variant = cfg.get(&"direction")
	_velocity = Vector2.ZERO
	if aim is Vector2 and not (aim as Vector2).is_zero_approx():
		_velocity = (aim as Vector2).normalized() * speed
	var target: Variant = cfg.get(&"target")
	if target is Node2D:
		_lock_target = target as Node2D
	var src: Variant = cfg.get(&"source")
	if src is Node2D:
		_source = src as Node2D
	_sync_shape()
	_sync_visual()


func _ready() -> void:
	add_to_group(PROJECTILE_GROUP)
	_sync_shape()
	_sync_visual()


## Flight. A travelling shot sweeps for what is in front of it this frame (a ray,
## not an overlap event, so the impact point is exact and the blast lands where the
## hull was hit); a mine sits still and watches for a hull.
func _physics_process(delta: float) -> void:
	if _spent or delta <= 0.0:
		return
	if kind == KIND_MINE:
		_step_mine(delta)
		return
	_step_flight(delta)


## --- The public seams the weapons and the countermeasures read -------------


func family() -> StringName:
	return StringName(KIND_FAMILIES.get(kind, &"kinetic"))


## Section 4.1: "destroyed in flight (any weapon hit kills it)". Only a rocket.
func is_destructible() -> bool:
	return DESTRUCTIBLE_KINDS.has(kind)


func hit_radius() -> float:
	return HIT_RADIUS


func damage_amount() -> float:
	return damage


func bypasses_shield() -> bool:
	return bypass_shield


func lock_target() -> Node2D:
	return _lock_target


## The decoy a flare pulled this shot onto (section 4.6), null when none is live.
func decoy() -> Node2D:
	return _decoy


## The live flight vector: the shot's speed and bearing, which a probe measures for
## section 4.1's travel rows and a trail renderer reads for its orientation.
func velocity() -> Vector2:
	return _velocity


## Who fired the shot. A beam's segment test reads it so it cannot shoot down its
## own rockets.
func source() -> Node2D:
	return _source


## The sprite this shot flies with (null while its sheet is missing). The wiring
## tests read it; a trail renderer would too.
func visual() -> Node2D:
	return _visual


## Section 4.6's half that belongs here: a live flare overrides the lock target,
## so the shot keeps flying (and keeps turning) at the decoy instead. Harmless on
## a non-seeker: a mine and a ballistic shot are not homing, so the override is
## stored and never read.
func retarget(lure: Node2D) -> void:
	if lure == null or not is_instance_valid(lure):
		return
	_decoy = lure


## A weapon hit on a destructible shot (section 4.1). No detonation: the warhead is
## destroyed, not fired.
func fizzle() -> void:
	_consume()


## The shot leaves the world: it fizzled at its range, struck a body, or was shot
## down. One door, so `_spent` can never be left behind.
func _consume() -> void:
	if _spent:
		return
	_spent = true
	queue_free()


## --- Flight ---------------------------------------------------------------


func _step_flight(delta: float) -> void:
	_drive(delta)
	if _velocity.is_zero_approx():
		return
	_face_travel()
	var from := global_position
	var to := from + _velocity * delta
	var hit := _nearest(from, to)
	if hit.is_empty():
		global_position = to
		_travelled += from.distance_to(to)
		if _reaches_decoy(to, delta):
			return
		if max_range > 0.0 and _travelled >= max_range:
			fizzle()
		return
	_resolve(hit)


## Section 4.1: "homing, 2.2 rad/s turn" toward the lock target, and section 4.6:
## "a live flare overrides that target". Without either, the shot keeps its muzzle
## bearing - the dumb-fire the same row names.
func _drive(delta: float) -> void:
	if not homing or turn_rate <= 0.0 or speed <= 0.0:
		return
	var target := _homing_target()
	if target == null:
		return
	var bearing := (target.global_position - global_position).angle()
	var error := wrapf(bearing - _velocity.angle(), -PI, PI)
	var step := turn_rate * delta
	if absf(error) > step:
		_velocity = _velocity.rotated(signf(error) * step)
	else:
		_velocity = _velocity.rotated(error)
	if not is_zero_approx(_velocity.length()):
		_velocity = _velocity.normalized() * speed


## The decoy while it lives, else the lock target while it is valid (section 4.6:
## "a live flare overrides that target").
func _homing_target() -> Node2D:
	if _decoy != null and is_instance_valid(_decoy):
		return _decoy
	if _lock_target != null and is_instance_valid(_lock_target):
		return _lock_target
	return null


## A decoy is not a physics body, so the sweep cannot find it: a shot that has
## arrived at one detonates on the spot. "Arrived" is this frame's own travel, so
## no separate proximity radius is invented.
func _reaches_decoy(to: Vector2, delta: float) -> bool:
	var lure := _homing_target()
	if lure == null or lure is CollisionObject2D:
		return false
	var reach := maxf(_velocity.length() * delta, HIT_RADIUS)
	if to.distance_to(lure.global_position) > reach:
		return false
	_detonate(to)
	return true


## The nearest thing on this frame's segment: a body (rock or hull) or a
## destructible shot. Both queries exclude the shot itself and its source's bodies.
func _nearest(from: Vector2, to: Vector2) -> Dictionary:
	var best := _sweep_bodies(from, to)
	var shot := _sweep_projectiles(from, to)
	if shot.is_empty():
		return best
	if best.is_empty():
		return shot
	return shot if float(shot[&"distance"]) < float(best[&"distance"]) else best


func _sweep_bodies(from: Vector2, to: Vector2) -> Dictionary:
	var space := _space()
	if space == null:
		return {}
	var query := PhysicsRayQueryParameters2D.create(from, to, TARGET_MASK, _exclusions())
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return _hit_of(space.intersect_ray(query), from, false)


## A rocket dies to any weapon hit, so a shot looks for destructible shots on the
## same segment. A rocket does not shoot down rockets: the warhead's job is the
## hull it was aimed at.
func _sweep_projectiles(from: Vector2, to: Vector2) -> Dictionary:
	if is_destructible():
		return {}
	var space := _space()
	if space == null:
		return {}
	var query := PhysicsRayQueryParameters2D.create(from, to, PROJECTILE_LAYER, _exclusions())
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return {}
	if not _is_destructible_shot(hit.get("collider")):
		return {}
	return _hit_of(hit, from, true)


func _hit_of(hit: Dictionary, from: Vector2, is_shot: bool) -> Dictionary:
	if hit.is_empty():
		return {}
	var point: Vector2 = hit.get("position", from)
	return {
		&"point": point,
		&"collider": hit.get("collider"),
		&"distance": from.distance_to(point),
		&"projectile": is_shot,
	}


## Nothing survives the frame it lands: every kind either fizzles or detonates.
func _resolve(hit: Dictionary) -> void:
	var collider: Variant = hit[&"collider"]
	var point: Vector2 = hit[&"point"]
	if bool(hit[&"projectile"]):
		_shot_down(collider, point)
		return
	global_position = point
	if _is_rock(collider):
		_hit_rock(collider, point)
		return
	_hit_body(collider, point)


## A weapon hit on a rocket (section 4.1). The shooter's shot keeps flying - the
## kill is not a hit on the world.
func _shot_down(collider: Variant, point: Vector2) -> void:
	if not _is_destructible_shot(collider):
		return
	(collider as Node).call(&"fizzle")
	global_position = point + _velocity.normalized() * HIT_RADIUS
	## F1's item 11: a rocket killed in flight is a destruction, so it takes FX_SPEC
	## section 1.4's explosion (the sheet the spec pairs with S3's detonations) and the
	## blast cue. The shooter's own shot flies on - only the warhead leaves.
	_blast(point)


## Section 6, ruling 17: a gun's work on a rock is `10 %` of its DPS-equivalent
## rate, depletion only. The units `apply_work` returns are delivered pickups the
## mining laser owns; a chip never extracts, so the return is discarded.
func _hit_rock(rock: Node, point: Vector2) -> void:
	if chip > 0.0 and rock.has_method(&"apply_work"):
		rock.call(&"apply_work", damage * chip)
	## FX_SPEC section 1.4 / AUDIO_SPEC S4: the hit's other half. A rock is its own
	## sound (the mining shaft keeps its chip cue; this is the weapon's own hit).
	play_impact(self, IMPACT_KIND_ROCK)
	_spawn_weapon_hit(point)
	if _is_explosive():
		_detonate(point)
		return
	_consume()


## Section 4.2 item 7: a hit transfers `KNOCKBACK_FRACTION` of the shot's remaining
## kinetic energy along the impact line. `Impact.knockback` gives the share; the
## impulse that carries it is `sqrt(2 x E x M)`, which this site can compute
## because it knows both the shot's mass and the target's.
func _hit_body(target: Node, point: Vector2) -> void:
	var share := ImpactScript.knockback(_velocity.length(), mass)
	var impulse := Vector2.ZERO
	var target_mass := _mass_of(target)
	if share > 0.0 and target_mass > 0.0:
		impulse = _velocity.normalized() * sqrt(2.0 * share * target_mass)
		_apply_push(target, impulse)
	## The sink is resolved once for the shield read and the delivery, so the cue, the
	## ring and the damage can never disagree about what took the hit.
	var sink := _sink_for(target)
	var shielded := not bypass_shield and _shield_up(sink)
	_report_hit(point, shielded)
	_deliver(sink, damage, bypass_shield, point, impulse)
	_note_shield(sink, point, shielded)
	_spawn_weapon_hit(point)
	if _is_explosive():
		_detonate(point)
		return
	_consume()


## Section 4.1's trigger: a mine detonates on a hull inside its radius. The blast
## damages the hull that triggered it and pushes every rigid body in range with
## section 4.2 item 8's curve; the spec pins no blast-damage falloff, so none is
## invented.
func _step_mine(delta: float) -> void:
	if not _armed:
		_arm_clock += delta
		if _arm_clock >= arm_time:
			_armed = true
		return
	var victim := _mine_victim()
	if victim == null:
		return
	_detonate(global_position, victim)


## "Proximity trigger 60 u": a hull's centre inside the radius. Hulls are found by
## their groups (the player's and W3's `&"npc_ship"`), so the trigger does not
## depend on a collision layer; the ship that dropped the mine is not a trigger
## (a mine that armed under its own layer would be unusable).
func _mine_victim() -> Node2D:
	var tree := get_tree()
	if tree == null:
		return null
	var best: Node2D = null
	var best_distance := trigger_radius
	for group: StringName in [PLAYER_GROUP, NPC_GROUP]:
		for node: Node in tree.get_nodes_in_group(group):
			var candidate := node as Node2D
			if candidate == null or _is_source(candidate):
				continue
			var distance := candidate.global_position.distance_to(global_position)
			if distance <= best_distance:
				best_distance = distance
				best = candidate
	return best


## Section 4.2 item 8: "every detonation applies I(d) = P0 / (1 + d^2) as an
## outward impulse over EXPLOSION_WINDOW to every rigid body in range". The push
## itself is `Impact.apply_shockwave` (slice 0's helper, never reimplemented here).
##
## A mine's own detonation adds the mine family's burst (`spawn_mine_burst`) beside
## section 1.4's explosion: the deployable's own art, played once where it went off.
func _detonate(at: Vector2, victim: Node2D = null) -> void:
	if _spent:
		return
	_spent = true
	if victim != null and damage > 0.0:
		_deliver(victim, damage, bypass_shield, at, Vector2.ZERO)
	_push_bodies(at)
	_blast(at)
	if kind == KIND_MINE:
		spawn_mine_burst(_fx_parent(), at)
	detonated.emit(at, damage, bypass_shield)
	queue_free()


func _push_bodies(at: Vector2) -> void:
	var space := _space()
	if space == null:
		return
	var circle := CircleShape2D.new()
	circle.radius = _shockwave_radius()
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, at)
	query.collision_mask = TARGET_MASK
	query.collide_with_areas = false
	query.collide_with_bodies = true
	for result: Dictionary in space.intersect_shape(query, MAX_SHOCKWAVE_BODIES):
		var body: Variant = result.get("collider")
		if body is RigidBody2D:
			ImpactScript.apply_shockwave(at, body, ImpactScript.EXPLOSION_WINDOW)


## The `I(d)` curve's own range: `P0 / (1 + d^2)` reaches
## `MIN_SHOCKWAVE_IMPULSE` at `d = sqrt(P0 / MIN - 1)`, so no new radius is
## invented - the curve says where a push stops mattering.
func _shockwave_radius() -> float:
	return sqrt(maxf(ImpactScript.EXPLOSION_P0 / MIN_SHOCKWAVE_IMPULSE - 1.0, 0.0))


## --- Damage delivery ------------------------------------------------------


## The pinned target seam (brief pinned interface item 4, W2's pipeline): the
## target owns `take_damage(amount, bypass_shield, ctx)`; a two-argument
## `take_damage` also lands (the context is dropped, arity-detected), and
## `PlayerState.damage` is the resource-level fallback. `ctx` is section 4.2 item
## 5's combat context, populated on every hit this file deals.
func _deliver(
	target: Object, amount: float, bypass: bool, point: Vector2, impulse: Vector2
) -> void:
	if amount <= 0.0:
		return
	target = _sink_for(target)
	if target == null:
		return
	if target.has_method(&"take_damage"):
		if _takes_ctx(target, &"take_damage"):
			target.call(&"take_damage", amount, bypass, _ctx(target, point, impulse))
		else:
			target.call(&"take_damage", amount, bypass)
		return
	if target.has_method(&"damage"):
		if _takes_ctx(target, &"damage"):
			target.call(&"damage", amount, bypass, _ctx(target, point, impulse))
		else:
			target.call(&"damage", amount, bypass)


## The ship behind a physics collider, so a shot that strikes a hull's own body is
## still dealt to the hull (section 4.1: the damage belongs to the ship; the collider
## is a `HullBody` with no damage method, measured). The walk is `game.gd:_hull_of`'s:
## the target itself once it answers for damage, else its nearest ancestor in the
## player / NPC ship groups. Anything else - a rock, a decoy, a probe fixture - is
## returned unchanged, so every existing caller keeps its behaviour.
func _sink_for(target: Object) -> Object:
	if target == null:
		return null
	if target.has_method(&"take_damage") or target.has_method(&"damage"):
		return target
	var cursor := target as Node
	while cursor != null:
		if cursor.is_in_group(PLAYER_GROUP) or cursor.is_in_group(NPC_GROUP):
			return cursor
		cursor = cursor.get_parent()
	return target


func _ctx(target: Object, point: Vector2, impulse: Vector2) -> Dictionary:
	return {
		&"direction": _impact_bearing(target, point),
		&"impulse": impulse,
		&"family": family(),
	}


## Section 4.2 item 5: `direction` is the impact bearing relative to the target's
## heading, which is what slice 3's prow/stern/port/starboard quadrants read.
func _impact_bearing(target: Object, point: Vector2) -> float:
	var node := target as Node2D
	if node == null:
		return 0.0
	return wrapf((point - node.global_position).angle() - node.global_rotation, -PI, PI)


## Whether a method takes the context. The answer belongs to the class, not the
## instance, so it is cached per script and a stream of shots pays for one
## `get_method_list` per target class.
func _takes_ctx(target: Object, method: StringName) -> bool:
	var key: Variant = target.get_script()
	if key == null:
		key = target.get_class()
	if _ctx_arity.has(key):
		return bool(_ctx_arity[key])
	var count := 0
	for entry: Dictionary in target.get_method_list():
		if StringName(entry.get("name", "")) == method:
			count = (entry.get("args", []) as Array).size()
			break
	var takes := count >= 3
	_ctx_arity[key] = takes
	return takes


## --- Push helpers ---------------------------------------------------------


func _apply_push(target: Object, impulse: Vector2) -> void:
	if impulse.is_zero_approx():
		return
	if target.has_method(&"apply_impulse"):
		target.call(&"apply_impulse", impulse)
		return
	var rigid := target as RigidBody2D
	if rigid != null:
		rigid.apply_central_impulse(impulse)


## The hit's mass, in the same tonnes the section 13 class column uses: a rigid
## body's own mass, or the body a ship hull exposes through `impact_body`. A target
## with no readable mass takes no push (there is nothing to push).
func _mass_of(target: Object) -> float:
	var rigid := target as RigidBody2D
	if rigid != null:
		return rigid.mass
	if target.has_method(&"impact_body"):
		var body: Variant = target.call(&"impact_body")
		if body is RigidBody2D:
			return (body as RigidBody2D).mass
	return 0.0


## --- The shot's sprite ----------------------------------------------------


## The sprite is built once per kind, from the kind's row in `SHEETS`: a single
## additive frame for a bolt, a slug and a mine, and the four-frame trail sheet's
## own animation for the seeker. Idempotent, so `configure` and `_ready` can both
## ask and only the first one builds.
func _sync_visual() -> void:
	if _visual != null and _visual_kind == kind and is_instance_valid(_visual):
		return
	_clear_visual()
	_visual_kind = kind
	var sprite := _build_visual()
	if sprite == null:
		return
	_visual = sprite
	_face_travel()


func _clear_visual() -> void:
	if _visual == null or not is_instance_valid(_visual):
		_visual = null
		return
	remove_child(_visual)
	_visual.free()
	_visual = null


## The kind's row as a parented node (these are `Fx`'s spawn calls, which own the
## `add_child`), or null when the row or its files are missing - a missing sheet leaves
## the shot invisible rather than crashing the run.
func _build_visual() -> Node2D:
	var row: Variant = SHEETS.get(kind)
	if not row is Dictionary:
		return null
	var entry := row as Dictionary
	var textures := _row_textures(entry)
	if textures.is_empty():
		return null
	var scale_factor := FxScript.scale_for(
		entry.get(&"source", (textures[0] as Texture2D).get_size()) as Vector2,
		float(entry.get(&"world", 0.0))
	)
	if textures.size() > 1:
		var frames := FxScript.texture_frames(
			textures,
			float(entry.get(&"fps", FxScript.DEFAULT_FPS)),
			bool(entry.get(&"loop", false))
		)
		if frames.get_frame_count(FxScript.ANIMATION) == 0:
			return null
		var animated := AnimatedSprite2D.new()
		animated.name = VISUAL_NODE
		animated.sprite_frames = frames
		animated.animation = FxScript.ANIMATION
		animated.material = FxScript.alpha_material()
		animated.scale = Vector2.ONE * scale_factor
		animated.z_index = VISUAL_Z
		add_child(animated)
		animated.play(FxScript.ANIMATION)
		return animated
	var still := FxScript.display(self, textures[0] as Texture2D)
	if still == null:
		return null
	still.name = VISUAL_NODE
	still.position = Vector2.ZERO
	still.scale = Vector2.ONE * scale_factor
	still.z_index = VISUAL_Z
	return still


## The sheets' objects point right, so the sprite carries the shot's own bearing: a
## homing rocket's exhaust swings with every turn. A mine has no velocity and keeps
## the bearing it was dropped at.
func _face_travel() -> void:
	if _visual == null or not is_instance_valid(_visual):
		return
	if _velocity.is_zero_approx():
		return
	_visual.rotation = _velocity.angle()


## --- Collision plumbing ---------------------------------------------------


func _space() -> PhysicsDirectSpaceState2D:
	if not is_inside_tree():
		return null
	var world := get_world_2d()
	if world == null:
		return null
	return world.direct_space_state


func _sync_shape() -> void:
	if _shape == null:
		_shape = CollisionShape2D.new()
		_shape.name = SHAPE_NODE
		add_child(_shape)
	var circle := _shape.shape as CircleShape2D
	if circle == null:
		circle = CircleShape2D.new()
		_shape.shape = circle
	circle.radius = HIT_RADIUS
	collision_layer = PROJECTILE_LAYER
	collision_mask = PROJECTILE_LAYER
	monitoring = true
	monitorable = true


## The shot must not touch the hull that fired it, and an `Area2D` has no collision
## exceptions (`PhysicsBody2D` owns those), so the area's mask is the projectile
## layer alone: the source's hull never overlaps it, and the two sweep queries
## exclude the source's bodies by RID instead.
func _exclusions() -> Array[RID]:
	var out: Array[RID] = [get_rid()]
	for body: CollisionObject2D in _source_bodies():
		if not out.has(body.get_rid()):
			out.append(body.get_rid())
	return out


## Every collision object in the source's subtree, without a `get_node` walk: the
## hull's own bodies are the shot's launch platform and nothing else in the tree is.
func _source_bodies() -> Array[CollisionObject2D]:
	var out: Array[CollisionObject2D] = []
	if _source == null or not is_instance_valid(_source):
		return out
	var stack: Array[Node] = [_source]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		var body := node as CollisionObject2D
		if body != null:
			out.append(body)
		for child: Node in node.get_children():
			stack.append(child)
	return out


func _is_source(node: Node) -> bool:
	if _source == null or not is_instance_valid(_source):
		return false
	var cursor := node
	while cursor != null:
		if cursor == _source:
			return true
		cursor = cursor.get_parent()
	return false


func _is_rock(collider: Variant) -> bool:
	var node := collider as Node
	return node != null and node.is_in_group(ROCK_GROUP)


func _is_destructible_shot(collider: Variant) -> bool:
	var node := collider as Node
	if node == null or node == self:
		return false
	if not node.has_method(&"is_destructible"):
		return false
	return bool(node.call(&"is_destructible"))


func _is_explosive() -> bool:
	return kind == KIND_ROCKET or kind == KIND_MINE


func _number(value: Variant, fallback: float = 0.0) -> float:
	if value is float or value is int:
		return float(value)
	return fallback


## --- The hit's feedback: the cue, the ring and the blast (F2) --------------------
##
## Everything a landed hit draws and sounds, kept out of `_damage`'s path so no number
## there moves: the cue per target kind, the shield's ring and bed, the railgun's arc
## and the blast every destruction shares. The sheets are F1's `Fx` calls, spawned
## additively (FX_SPEC section 0: the masters are RGB on Void Black).


## The cue a landed hit plays for `target_kind`, or "" for a kind AUDIO_SPEC gives none.
static func impact_cue_of(target_kind: StringName) -> StringName:
	return StringName(IMPACT_CUES.get(target_kind, &""))


## One cue through the audio service: a pooled row (S4's `sfx_impact_hull`, S5's
## `sfx_impact_shield_hit`, S3's explosion) takes a take through `play_pool`; a plain
## one (`sfx_impact_rock`) plays through the same call, which falls back to `play_sfx`.
## A missing service is a no-op, exactly like every other cue in the project; a headless
## probe reads `AudioManager.last_sfx()` and the `play_pool` plan instead of listening.
static func play_cue(host: Node, cue: StringName) -> void:
	var audio := _audio(host)
	if audio == null or not audio.has_method(&"play_pool"):
		return
	audio.call(&"play_pool", cue)


## The cue a hit on `target_kind` plays, and the cue name back. A kind the table does
## not carry (AUDIO_SPEC section 8 has these three) plays nothing.
static func play_impact(host: Node, target_kind: StringName) -> StringName:
	var cue := impact_cue_of(target_kind)
	if cue == &"":
		return &""
	play_cue(host, cue)
	return cue


## The blast cue, through the same pool route.
static func play_blast(host: Node) -> StringName:
	play_cue(host, BLAST_CUE)
	return BLAST_CUE


## S6's shield bed: asked for on every absorbed hit, which `play_loop` answers as a
## no-op while that bed is already the one playing.
static func hold_shield(host: Node) -> void:
	var audio := _audio(host)
	if audio == null or not audio.has_method(&"play_loop"):
		return
	audio.call(&"play_loop", SHIELD_LOOP_CUE)


## The bed goes out when the shield drops. Only the bed the shield started is stopped -
## the mining shaft's S7 bed is not this one's to silence (the manager owns one loop
## voice, reported).
static func release_shield(host: Node) -> void:
	var audio := _audio(host)
	if audio == null or not audio.has_method(&"current_loop"):
		return
	if StringName(audio.call(&"current_loop")) != SHIELD_LOOP_CUE:
		return
	audio.call(&"stop_loop")


## A feedback row, or an empty dictionary for a name the table does not carry.
static func feedback_row(row_name: StringName) -> Dictionary:
	var row: Variant = FEEDBACK.get(row_name)
	if row is Dictionary:
		return row as Dictionary
	return {}


## A row's drawn frame as a texture, for the callers that live outside this file (the
## dust streak is `speed_fantasy.gd`'s emitter): the same read every spawn helper makes,
## so a row's file and its measured region have one owner.
static func feedback_texture(row_name: StringName) -> Texture2D:
	return _row_texture(feedback_row(row_name))


## FX_SPEC sections 2/7.3: a one-shot sheet, spawned through F1's helper (which also frees
## it on `animation_finished`) with the sheet's own alpha, placed at `at` in world space
## and returned. Null when the row, its files or its frames are unavailable - a missing
## sheet leaves the hit quiet rather than crashing a run.
##
## `world` is the row's own size unless a caller has one of its own (0 means "the row's"):
## the rock break is the only such caller, and it is the one effect whose subject is a
## body of a variable size rather than a hull (`spawn_rock_break`). The scale is the same
## `Fx.scale_for` computation either way, so the override changes no mechanic.
static func spawn_sheet(
	parent: Node, fx_name: StringName, at: Vector2, world: float = 0.0
) -> AnimatedSprite2D:
	if parent == null:
		return null
	var row := feedback_row(fx_name)
	if row.is_empty():
		return null
	var textures := _row_textures(row)
	if textures.is_empty():
		return null
	var frames := FxScript.texture_frames(
		textures,
		float(row.get(&"fps", FxScript.DEFAULT_FPS)),
		bool(row.get(&"loop", false))
	)
	if frames.get_frame_count(FxScript.ANIMATION) == 0:
		return null
	var scale_factor := FxScript.scale_for(
		row.get(&"source", (textures[0] as Texture2D).get_size()) as Vector2,
		world if world > 0.0 else float(row.get(&"world", 0.0))
	)
	var sprite := FxScript.play_once(parent, frames, Vector2.ZERO, 0.0, scale_factor)
	if sprite == null:
		return null
	sprite.name = String(fx_name)
	sprite.z_index = FEEDBACK_Z
	_place(sprite, at)
	return sprite


## FX_SPEC section 1.4's five-frame explosion, at a hull's death, a detonation or a shot
## down in flight.
static func spawn_explosion(parent: Node, at: Vector2) -> AnimatedSprite2D:
	return spawn_sheet(parent, &"explosion", at)


## The rock break's explosion (the owner's 2026-09-21 asteroid ruling): the same
## section 1.4 sequence, at the rock's own centre and read at the rock's size -
## `diameter x ROCK_BREAK_WORLD_SCALE`, clamped to the row's floor and the ceiling above
## the largest shipped look. `diameter` is the rock's collision diameter
## (`2 x Asteroid.world_radius()`), so a Large rock's break covers it and a Small's does
## not read as a hull-sized blast.
static func spawn_rock_break(parent: Node, at: Vector2, diameter: float) -> AnimatedSprite2D:
	var world := clampf(
		maxf(diameter, 0.0) * ROCK_BREAK_WORLD_SCALE,
		ROCK_BREAK_WORLD_MIN,
		ROCK_BREAK_WORLD_MAX
	)
	return spawn_sheet(parent, &"explosion", at, world)


## ASSET_EXPANSION_SPEC section 7's secondary burst - what a hull's death adds over the
## single explosion.
static func spawn_secondary_explosion(parent: Node, at: Vector2) -> AnimatedSprite2D:
	return spawn_sheet(parent, &"secondary", at)


## FX_SPEC section 7.2's four-frame arc: the railgun's own hit signature.
static func spawn_arc_spark(parent: Node, at: Vector2) -> AnimatedSprite2D:
	return spawn_sheet(parent, &"arc", at)


## FX_SPEC section 1.6 / section 3's four-frame chip-sparks burst (`fx_mining_beam.png`,
## the sheet section 3 names), one-shot per S8 chip event at the spec's 20 FPS: what a gun
## chipping an asteroid draws at the contact. The readers are `weapons.gd`'s rock branch
## and `mining_laser.gd`'s own chip read (L65).
static func spawn_chip_sparks(parent: Node, at: Vector2) -> AnimatedSprite2D:
	return spawn_sheet(parent, &"chip", at)


## ASSET_EXPANSION_SPEC section 7 / FX_SPEC section 7.1's shield shatter, on the hit
## that empties the shield pool.
static func spawn_shield_break(parent: Node, at: Vector2) -> AnimatedSprite2D:
	return spawn_sheet(parent, &"shield_break", at)


## The mine family's own burst (owner ruling 2026-09-21: `fx_mine` "gives the mine family
## its own sprite and burst"): the mine's own frames, played once where it goes off, beside
## FX_SPEC section 1.4's explosion. The deployed sprite is the same art (`SHEETS`' mine
## row), so the family owns one asset and this row is the burst's read of it.
static func spawn_mine_burst(parent: Node, at: Vector2) -> AnimatedSprite2D:
	return spawn_sheet(parent, &"mine_burst", at)


## FX_SPEC section 1.5: the single-frame steel ring, collapsed and grown 0 -> 1.5x over
## the spec's 0.3 s while F1's `fade_and_free` takes its alpha out and frees it. Null
## when the sheet is missing.
static func spawn_shield_ripple(parent: Node, at: Vector2) -> Sprite2D:
	if parent == null:
		return null
	var row := feedback_row(&"ripple")
	if row.is_empty():
		return null
	var texture := _row_texture(row)
	if texture == null:
		return null
	var scale_factor := FxScript.scale_for(
		row.get(&"source", texture.get_size()) as Vector2, float(row.get(&"world", 0.0))
	)
	var sprite := FxScript.display(parent, texture, Vector2.ZERO, 0.0, scale_factor)
	if sprite == null:
		return null
	sprite.name = "shield_ripple"
	sprite.z_index = FEEDBACK_Z
	_place(sprite, at)
	if not sprite.is_inside_tree():
		return sprite
	sprite.scale = Vector2.ZERO
	var grow := sprite.create_tween()
	grow.tween_property(
		sprite, "scale", Vector2.ONE * scale_factor * RIPPLE_SCALE, RIPPLE_SECONDS
	)
	FxScript.fade_and_free(sprite, RIPPLE_SECONDS)
	return sprite


## FX_SPEC sections 7.1/7.3, the low-hull damage state: a plume parented to the hull, so
## it rides the damage and frees with its owner. Idempotent - a hull that already
## carries one keeps it. Returns the emitter, or null when the sheet is missing.
static func spawn_smoke_plume(hull: Node2D) -> GPUParticles2D:
	if hull == null or not is_instance_valid(hull):
		return null
	var existing := hull.get_node_or_null(NodePath(PLUME_NODE)) as GPUParticles2D
	if existing != null:
		return existing
	var row := feedback_row(&"plume")
	if row.is_empty():
		return null
	var texture := _row_texture(row)
	if texture == null:
		return null
	var emitter := GPUParticles2D.new()
	emitter.name = PLUME_NODE
	emitter.texture = texture
	emitter.material = FxScript.alpha_material()
	emitter.process_material = _plume_material(
		FxScript.scale_for(
			row.get(&"source", texture.get_size()) as Vector2, float(row.get(&"world", 0.0))
		)
	)
	emitter.amount = PLUME_AMOUNT
	emitter.lifetime = PLUME_LIFETIME
	emitter.preprocess = PLUME_PREPROCESS
	emitter.local_coords = false
	emitter.emitting = true
	emitter.z_index = FEEDBACK_Z
	hull.add_child(emitter)
	return emitter


## FX_SPEC section 7.1's "spawn while hull < 25 %": a hull that climbs back above the
## line drops the plume it was carrying.
static func clear_smoke_plume(hull: Node2D) -> void:
	if hull == null or not is_instance_valid(hull):
		return
	var existing := hull.get_node_or_null(NodePath(PLUME_NODE))
	if existing == null:
		return
	existing.queue_free()


## --- The thruster trail (FX_SPEC section 1.3's 2026-09-21 amendment) -------


## The section's shared ramp for its three ratio rows: 0 at the 0.15 floor, 1 at 1.0.
static func trail_ramp(ratio: float) -> float:
	if ratio <= TRAIL_RATIO_MIN:
		return 0.0
	return clampf((ratio - TRAIL_RATIO_MIN) / (1.0 - TRAIL_RATIO_MIN), 0.0, 1.0)


## "20 streaks/s at ratio 0.15 -> 60/s at 1.0 (linear)".
static func trail_rate(ratio: float) -> float:
	return lerpf(TRAIL_RATE_MIN, TRAIL_RATE_MAX, trail_ramp(ratio))


## "24 u at ratio 0.15 -> 56 u at 1.0".
static func trail_length(ratio: float) -> float:
	return lerpf(TRAIL_LENGTH_MIN, TRAIL_LENGTH_MAX, trail_ramp(ratio))


## "0.35 at ratio 0.15 -> 0.85 at 1.0".
static func trail_alpha(ratio: float) -> float:
	return lerpf(TRAIL_ALPHA_MIN, TRAIL_ALPHA_MAX, trail_ramp(ratio))


## One engine cell's own numbers for a frame: the rate, the streak's length and alpha, and
## the two emitter settings that carry them - `amount_ratio` (the rate against the
## emitter's own top-rate capacity) and the **draw pass's** quad scale, because the section
## gives a length *and* a width and the drawn frame's own aspect is neither.
##
## `scale` is the quad's size in the drawn frame's texels, and it is applied through
## `Fx.set_quad_scale` - the emitter's node `scale` never reaches what a
## `GPUParticles2D` draws (S2's report section 2.2), and the process material's own
## `scale_min/max` is uniform, so it could not give 6 u of width at any length.
static func trail_read(ratio: float, source: Vector2) -> Dictionary:
	var length := trail_length(ratio)
	var rate := trail_rate(ratio)
	var capacity := roundi(TRAIL_RATE_MAX * TRAIL_LIFETIME)
	var scale := FxScript.quad_scale_for(source, length, TRAIL_WIDTH)
	return {
		&"ramp": trail_ramp(ratio),
		&"rate": rate,
		&"length": length,
		&"width": TRAIL_WIDTH,
		&"alpha": trail_alpha(ratio),
		&"amount": capacity,
		&"amount_ratio": rate / TRAIL_RATE_MAX,
		&"count": float(capacity) * (rate / TRAIL_RATE_MAX),
		&"scale": scale,
	}


## One emitter per anchor, parented to the hull (FX_SPEC section 1.3's amendment), shaped
## from the frame's ratio. Idempotent: a hull that already carries its emitters keeps
## them, a shorter anchor list drops the extras, and a missing sheet leaves the hull
## without a trail rather than crashing a run. Returns the emitters in anchor order, so a
## caller - or a probe - can read what it got.
##
## `flags` is S5's addition (09 section 11, CONTRACTS section 17): when it is a
## per-anchor array the same length as `anchors`, each emitter's own flag decides whether
## it fires - so a hull whose measured map holds rear, front and both side rows lights
## only the row the stick asked for, and a coasting hull lights the rear row on the
## ratio's own floor. An empty `flags` is the pre-S5 shape: every anchor takes `active`.
static func sync_thruster_trails(
	hull: Node2D, anchors: Array, ratio: float, active: bool, flags: Array = []
) -> Array[GPUParticles2D]:
	var emitters: Array[GPUParticles2D] = []
	if hull == null or not is_instance_valid(hull):
		return emitters
	var row := feedback_row(&"trail")
	var texture := _row_texture(row)
	var read := trail_read(ratio, row.get(&"source", Vector2.ZERO) as Vector2)
	var per_anchor := flags.size() == anchors.size()
	for index in anchors.size():
		var emitter := _trail_emitter(hull, index)
		if emitter == null and texture != null:
			emitter = _make_trail(hull, index, texture)
		if emitter == null:
			continue
		var firing := bool(flags[index]) if per_anchor else active
		_shape_trail(emitter, anchors[index] as Vector2, read, firing)
		emitters.append(emitter)
	_drop_extra_trails(hull, anchors.size())
	return emitters


## A hull that stops carrying a trail (an anchor list that shrank, a hull swap) drops the
## emitters it no longer has an anchor for.
static func clear_thruster_trails(hull: Node2D) -> void:
	if hull == null or not is_instance_valid(hull):
		return
	_drop_extra_trails(hull, 0)


## FX_SPEC section 7.1's dash charge: one frame, engine-scaled (the row's `world` of 32 u)
## and faded out over the row's 0.2 s, on the afterburner's own activation. Null when the
## sheet is missing.
static func spawn_dash_charge(parent: Node, at: Vector2) -> Sprite2D:
	if parent == null:
		return null
	var row := feedback_row(&"dash_charge")
	if row.is_empty():
		return null
	var texture := _row_texture(row)
	if texture == null:
		return null
	var scale_factor := FxScript.scale_for(
		row.get(&"source", texture.get_size()) as Vector2, float(row.get(&"world", 0.0))
	)
	var sprite := FxScript.display(parent, texture, Vector2.ZERO, 0.0, scale_factor)
	if sprite == null:
		return null
	sprite.name = "dash_charge"
	sprite.z_index = FEEDBACK_Z
	_place(sprite, at)
	if not sprite.is_inside_tree():
		return sprite
	FxScript.fade_and_free(sprite, float(row.get(&"seconds", 0.0)))
	return sprite


## AUDIO_SPEC section 4.5's last paragraph: S12's one-shot on **booster activation** (the
## afterburner's, in v1 - `b_fold`'s movement is slice 4's, so its charge waits with it).
static func play_boost(host: Node) -> StringName:
	play_cue(host, BOOST_CUE)
	return BOOST_CUE


## AUDIO_SPEC section 4.5's thruster bed, asked for once a frame by its driver: the curve,
## the hysteresis and the voice all live in `AudioManager` (`hold_thruster_bed`), so the
## caller owns *when* and the manager owns *what*.
static func hold_thruster(host: Node, ratio: float, thrusting: bool) -> bool:
	var audio := _audio(host)
	if audio == null or not audio.has_method(&"hold_thruster_bed"):
		return false
	return bool(audio.call(&"hold_thruster_bed", ratio, thrusting))


## The bed goes out by its own cue, never by "whatever is in the foreground": the mining
## shaft's bed and the shield hum are other holders of the manager's voices.
static func release_thruster(host: Node) -> bool:
	var audio := _audio(host)
	if audio == null or not audio.has_method(&"stop_thruster_bed"):
		return false
	return bool(audio.call(&"stop_thruster_bed"))


## A hull's death: FX_SPEC section 1.4's explosion plus section 7.2's secondary burst,
## both parented to the world so they outlive the hull that died, and the blast cue.
## `host` is the dying hull itself - it has the tree the cue needs.
static func spawn_hull_death(host: Node, hull: Node2D) -> void:
	if hull == null or not is_instance_valid(hull):
		return
	var parent: Node = hull.get_parent()
	if parent == null:
		parent = hull
	var at := hull.global_position
	spawn_explosion(parent, at)
	spawn_secondary_explosion(parent, at)
	play_blast(host)


## The world node a hit's effect hangs from: the shot's own parent (the scene node
## `weapons.gd` spawns shots into), because the shot leaves the tree the frame it lands.
func _fx_parent() -> Node:
	var parent := get_parent()
	return parent if parent != null else self


## The cue and the ring for one landed hit. A shield that took the hit reads as the
## shield (S5) and draws section 1.5's ring at the contact; every other hull hit reads
## as S4's hull foley.
func _report_hit(point: Vector2, shielded: bool) -> void:
	play_impact(self, IMPACT_KIND_SHIELD if shielded else IMPACT_KIND_HULL)
	if shielded:
		spawn_shield_ripple(_fx_parent(), point)


## After the damage lands: a shield that is still holding keeps S6's bed up, and one
## this hit emptied draws section 7.1's shatter and puts the bed out.
func _note_shield(sink: Object, point: Vector2, shielded: bool) -> void:
	if not shielded:
		return
	if _shield_up(sink):
		hold_shield(self)
		return
	spawn_shield_break(_fx_parent(), point)
	release_shield(self)


## FX_SPEC section 7.2's arc is the heavy kinetic's own read, so only the railgun's slug
## arcs; every other kind hits quietly.
func _spawn_weapon_hit(point: Vector2) -> void:
	if kind == KIND_SLUG:
		spawn_arc_spark(_fx_parent(), point)


## The blast every destruction shares: section 1.4's explosion and the wave's cue. A
## hull's death adds the secondary burst (`spawn_hull_death`).
func _blast(at: Vector2) -> void:
	spawn_explosion(_fx_parent(), at)
	play_blast(self)


## Whether a target's shields are still up. The same read order `weapons.gd._shield_up`
## makes (`shield_up()`, a `shield` number, a `state` object's own pool), so the shield
## rule, plasma's bonus and this file's cue can never disagree.
func _shield_up(target: Object) -> bool:
	if target == null:
		return false
	if target.has_method(&"shield_up"):
		return bool(target.call(&"shield_up"))
	var direct: Variant = target.get(&"shield")
	if direct is float or direct is int:
		return float(direct) > 0.0
	var state: Variant = target.get(&"state")
	if state is Object and state != null:
		var pooled: Variant = (state as Object).get(&"shield")
		if pooled is float or pooled is int:
			return float(pooled) > 0.0
	return false


## The audio service, reached the way every other caller reaches it. A static has no
## tree of its own, so the caller passes the node that has one.
static func _audio(host: Node) -> Node:
	if host == null or not is_instance_valid(host) or not host.is_inside_tree():
		return null
	var tree := host.get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null(NodePath(AUDIO_SERVICE))


## The plume's seeded behaviour: puffs rising from the hull's own middle. FX_SPEC states
## the emitter and its palette, not its numbers (reported). `base` is the row's own read
## (a puff's length in world units over the master's pixels), so the two scale factors
## below vary a plume-sized puff instead of the master's raw pixels.
static func _plume_material(base: float) -> ParticleProcessMaterial:
	var plume := ParticleProcessMaterial.new()
	plume.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	plume.emission_sphere_radius = PLUME_RADIUS
	plume.direction = Vector3(0.0, -1.0, 0.0)
	plume.spread = PLUME_SPREAD
	plume.initial_velocity_min = PLUME_SPEED_MIN
	plume.initial_velocity_max = PLUME_SPEED_MAX
	plume.scale_min = base * PLUME_SCALE_MIN
	plume.scale_max = base * PLUME_SCALE_MAX
	plume.gravity = Vector3.ZERO
	return plume


## The emitter an anchor already has, by the same name-and-index rule the sync uses.
static func _trail_emitter(hull: Node2D, index: int) -> GPUParticles2D:
	var node := hull.get_node_or_null(NodePath(TRAIL_NODE_PREFIX + str(index)))
	return node as GPUParticles2D


## One engine cell's emitter (FX_SPEC section 1.3's amendment): the streak's own frame,
## drawn through the draw pass so its quad is the section's own size, emitting in world
## space so the streaks it leaves behind the flying hull are what reads as thrust. It
## carries no velocity of its own - the hull's motion is the trail - so no number is
## needed for one.
static func _make_trail(hull: Node2D, index: int, texture: Texture2D) -> GPUParticles2D:
	var emitter := GPUParticles2D.new()
	emitter.name = TRAIL_NODE_PREFIX + str(index)
	emitter.texture = texture
	emitter.material = FxScript.quad_material()
	emitter.process_material = _trail_material()
	emitter.amount = roundi(TRAIL_RATE_MAX * TRAIL_LIFETIME)
	emitter.lifetime = TRAIL_LIFETIME
	emitter.local_coords = false
	emitter.rotation = TRAIL_TURN
	emitter.emitting = false
	emitter.visible = false
	hull.add_child(emitter)
	return emitter


static func _trail_material() -> ParticleProcessMaterial:
	var trail := ParticleProcessMaterial.new()
	trail.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	trail.direction = Vector3(1.0, 0.0, 0.0)
	trail.spread = 0.0
	trail.initial_velocity_min = 0.0
	trail.initial_velocity_max = 0.0
	trail.gravity = Vector3.ZERO
	trail.scale_min = 1.0
	trail.scale_max = 1.0
	return trail


## One frame of one engine cell: where it sits, how long and how bright its streak is, and
## whether it is emitting at all. The size goes to the **draw pass** (`Fx.set_quad_scale`),
## because the drawn quad is what the ratio's 24-56 u x 6 u is a statement about and the
## node's own `scale` does not reach it (S2's report section 2.2; `probe_s3_trail_quad.tscn`
## measures the rectangle this writes). The node itself stays unscaled, which is the state
## the probe reads.
static func _shape_trail(
	emitter: GPUParticles2D, anchor: Vector2, read: Dictionary, active: bool
) -> void:
	if emitter == null or not is_instance_valid(emitter):
		return
	var length := float(read.get(&"length", 0.0))
	emitter.position = anchor - Vector2(length * 0.5, 0.0)
	emitter.scale = Vector2.ONE
	FxScript.set_quad_scale(emitter.material, read.get(&"scale", Vector2.ONE) as Vector2)
	emitter.amount_ratio = float(read.get(&"amount_ratio", 0.0))
	var material := emitter.process_material as ParticleProcessMaterial
	if material != null:
		material.color = Color(1.0, 1.0, 1.0, float(read.get(&"alpha", 1.0)))
	emitter.emitting = active
	emitter.visible = active


## Every emitter past `kept` anchors goes, so a hull whose anchor list shrank carries
## exactly one emitter per engine cell it still has.
static func _drop_extra_trails(hull: Node2D, kept: int) -> void:
	if hull == null or not is_instance_valid(hull):
		return
	var index := kept
	while true:
		var emitter := _trail_emitter(hull, index)
		if emitter == null:
			return
		emitter.queue_free()
		index += 1


## A row's shipped frame files as the textures it draws: every frame whole, or - for a
## row that draws one frame of a sequence - that frame at the art's own measured ink box.
## Empty when a row names no file or a file is missing, so a missing sheet leaves the
## caller quiet rather than half-drawn.
static func _row_textures(row: Dictionary) -> Array:
	var paths: Variant = row.get(&"frames", [])
	if not paths is Array:
		return []
	var region: Variant = row.get(&"region")
	return FxScript.frame_textures(
		paths, region as Rect2 if region is Rect2 else Rect2()
	)


## A row's drawn frame: the single texture a one-frame read (an emitter, a still sprite)
## takes from it, or null when the row or its file is missing.
static func _row_texture(row: Dictionary) -> Texture2D:
	var textures := _row_textures(row)
	return textures[0] as Texture2D if not textures.is_empty() else null


## A sheet's own point in world space: set after it is parented, because it is spawned
## into whichever world node survives the shot that spawned it.
static func _place(node: Node2D, at: Vector2) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node.is_inside_tree():
		node.global_position = at
		return
	node.position = at


## --- The contact FX's scatter (FX_SPEC section 1.6's 2026-09-22 amendment) --


## The radius FX_SPEC section 1.6's scatter disc is measured from: the target's own.
## A rock answers `world_radius()` (24/42/66 u by class, `asteroid.gd:296`); a hull does
## not, and its figure lives in the `CircleShape2D` its body carries (30 u,
## `player_ship.tscn`'s `HullBody/Shape`), so the subtree is searched rather than the
## node alone - a ray hands back the bare collider for a hull but the ship above it for
## the shield rule, and both have to read the same number. 0.0 means the target carries
## no radius at all, which is where the caller's floor binds (a destructible shot's own
## 4 u detection circle is far below it, so it lands on the floor too).
static func collision_radius(target: Object) -> float:
	var node := target as Node
	if node == null or not is_instance_valid(node):
		return 0.0
	if node.has_method(&"world_radius"):
		return maxf(float(node.call(&"world_radius")), 0.0)
	return _circle_radius(node)


## A uniform random point in the disc of `radius` u around `at`, drawn from the caller's
## own generator so one component's effects never perturb another's stream (or the global
## one the rock looks roll on). `sqrt` on the reach is what makes it uniform per unit
## area; without it every spark would crowd the rim. `radius <= 0.0` hands `at` back
## untouched, which is the amendment's own reversal (`HIT_FX_JITTER_MULT 0.0`).
static func scatter_in_disc(rng: RandomNumberGenerator, at: Vector2, radius: float) -> Vector2:
	if rng == null or radius <= 0.0:
		return at
	return at + Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU)) * (radius * sqrt(rng.randf()))


## The first `CircleShape2D` radius in `node`'s own subtree, in child order. Depth-first,
## so a hull's own collider (the first body under the ship) wins over anything mounted
## after it; 0.0 when the subtree carries no circle at all.
static func _circle_radius(node: Node) -> float:
	for child: Node in node.get_children():
		var shape := child as CollisionShape2D
		if shape != null and shape.shape is CircleShape2D:
			return maxf((shape.shape as CircleShape2D).radius, 0.0)
		var deeper := _circle_radius(child)
		if deeper > 0.0:
			return deeper
	return 0.0
