class_name MiningLaser
extends Node2D
## The fitted mining laser (`w_mining`, a W-slot tool, 09 §4.5): a cursor-aimed
## beam that converts one ore unit per completed extraction cycle into one floating
## pickup.
## Contract: ENGINE_SPEC.md §6 ("cursor-aimed beam, range 220 u. Each `MINE_CYCLE`
## (1.2 s) on a rock converts 1 ore unit → spawns a floating pickup of that rock's
## mineral"), §4.3 ("`E` fires the mining laser ... Mining laser spends no ammo"),
## §13 (`MINE_CYCLE` 1.2 s, range 220 u), §15; docs/gameplay/02_minerals.md §7.1;
## brief §W3 item 3 and pinned interface item 5.
##
## Trigger: the owning `PlayerShip` holds the `mine` action and calls
## `set_active()` on the key's edges, so this file never reads the input map. It
## owns range, targeting and the cycle.
##
## The beam is engine-drawn, as FX_SPEC §1.6 says ("the beam line itself is
## engine-drawn; no texture needed"), and it reads its colours from the project
## theme: the brief's item 3 rules out ICONS_SPEC §1's ember accent (reserved for
## danger states) for a mining beam, and STYLE_BIBLE §4 permits emission only in
## ember (plus the sanctioned shield/explosion exceptions), so the beam is a plain
## neutral steel token and never additive. See the W3 report for the FX_SPEC §1.6
## deviation this brief overrides.

const AsteroidScript := preload("res://game/asteroid.gd")
const MineralCatalogScript := preload("res://game/mineral_catalog.gd")
## The chip read's own door (L65): the burst `weapons.gd`'s rock branch spawns through
## `spawn_chip_sparks`, and the scatter its amendment pins, are `Projectile`'s statics -
## so the shaft and a gun cannot draw two different chips.
const ProjectileScript := preload("res://game/projectile.gd")

## 05 §13's numbers, verbatim: the beam reaches 220 u and each 1.2 s of contact
## mines one ore unit.
const MINE_LASER_RANGE := 220.0
const MINE_CYCLE := 1.2

## The rock layer the shaft is masked to (Asteroid.COLLISION_LAYER), so rocks block
## the beam among themselves and the nearest rock under the cursor is the target.
const ROCK_MASK := 1
const ROCK_GROUP: StringName = &"asteroid"

const PLAYER_GROUP: StringName = &"player_ship"

const PICKUP_SCRIPT := "res://game/pickup.gd"
const PICKUP_NODE_NAME: StringName = &"Pickup"

const AUDIO_SERVICE: StringName = &"AudioManager"

## AUDIO_SPEC S8's chip transient, one per extracted unit. `_01` and not a
## round-robin over 01-04: `sfx_mining_chip_04` is a documented 21 s outlier
## (ASSET_AUDIT item 8).
const CHIP_CUE: StringName = &"sfx_mining_chip_01"

## AUDIO_SPEC S7's beam bed, the loop that sounds for as long as the shaft is on a
## rock. It goes out through `AudioManager.play_loop`, which owns a dedicated voice
## (`play_sfx` would hand a looping stream to a one-shot voice that the next shot
## steals), and it resolves through the cue's own `_01` take. The chip transient
## above keeps playing per unit alongside it.
const BEAM_LOOP_CUE: StringName = &"sfx_mining_beam"

const THEME_PATH := "res://ui/theme/vajb_theme.tres"
const TOKENS_TYPE: StringName = &"Tokens"
const TOKEN_HALO: StringName = &"metal_light"
const TOKEN_CORE: StringName = &"text_dim"

const HALO_WIDTH := 3.0
const CORE_WIDTH := 1.0
const HALO_ALPHA := 0.45
const CORE_ALPHA := 0.9

## FX_SPEC section 1.6's 2026-09-22 amendment, the mining shaft's half of it (S2.6, the
## owner's sixth and seventh requests: "a beam's hit should spawn its impact FX somewhat
## randomly across the struck surface"; "a laser beam should connect to more of the middle
## of the object (its termination point, for the beam itself)"). Both are drawn-line and
## effect-position only - the extraction, the cycle and the pickup point never move.
##
##   `BEAM_SINK` - the drawn shaft ends `BEAM_SINK` of the way from the point the ray
##   resolved to the rock's own centre. Reversal: `0.0` = the rim hit.
##
##   `HIT_FX_JITTER_MULT` - the chip sparks spawn at a uniform random point in a disc of
##   `clamp(HIT_FX_JITTER_MULT x collision radius, MIN, MAX)` u around that point, with
##   the rock's own `world_radius()` (24/42/66 u) as the radius. Reversal: `0.0` = the
##   fixed contact point.
##
## The values are `weapons.gd`'s, so the two beams read identically; the radius and the
## disc sampler themselves are `Projectile`'s statics, the one owner of that geometry.
const BEAM_SINK := 0.45
const HIT_FX_JITTER_MULT := 0.35
const HIT_FX_JITTER_MIN := 8.0
const HIT_FX_JITTER_MAX := 48.0

@onready var _halo: Line2D = $Beam
@onready var _core: Line2D = $BeamCore

var _stats: ShipStats = null
var _active := false

var _target: Node2D = null
var _hit_point := Vector2.ZERO
var _cycle := 0.0

## The chip's own generator, private like the asteroid field's and the hull's arc
## sparks', so the mining effects never perturb a gameplay stream.
var _fx_rng := RandomNumberGenerator.new()


func _ready() -> void:
	_apply_beam_tokens()
	_extinguish()


## The launch handshake (pinned interface): the resolved snapshot. §13 fixes the
## beam's range and cycle as global calibration, so nothing in `ShipStats` feeds
## the beam yet; the snapshot is held for slice 4's `u_refine`/`u_tractor` gear.
func bind(stats: ShipStats) -> void:
	_stats = stats


## The trigger, called by `PlayerShip` on the `mine` action's edges (ENGINE_SPEC
## §4.3). Releasing the key drops the target and the cycle, as 02 §7.1's cycle is
## "contact" time.
func set_active(active: bool) -> void:
	_active = active
	if not active:
		_extinguish()


func is_active() -> bool:
	return _active


## Whether a rock is under the cursor within `MINE_LASER_RANGE`. W5's reticle pass
## reads this for its mining state; game.gd does not need it.
func has_target() -> bool:
	return _target != null


func target_position() -> Vector2:
	return _hit_point


func _physics_process(delta: float) -> void:
	if not _active:
		return
	var target := _acquire()
	if target != _target:
		## Contact with a different rock starts a fresh cycle; there is no credit
		## carried from one rock to another (02 §7.1 counts cycles per rock).
		_target = target
		_cycle = 0.0
	if _target == null:
		_extinguish()
		return
	_cycle += delta
	if _cycle >= MINE_CYCLE:
		_cycle = fmod(_cycle, MINE_CYCLE)
		_apply_cycle()
	_draw_beam()


## The rock under the cursor within range: a physics ray from the hull, masked to
## the rock layer, with the player ship's own bodies excluded by RID so the shaft
## does not stop on the hull that fires it.
func _acquire() -> Node2D:
	if not is_inside_tree():
		return null
	var world := get_world_2d()
	if world == null:
		return null
	var space := world.direct_space_state
	if space == null:
		return null
	var origin := global_position
	var offset := get_global_mouse_position() - origin
	var reach := minf(offset.length(), MINE_LASER_RANGE)
	if reach <= 0.0:
		return null
	var query := PhysicsRayQueryParameters2D.create(
		origin, origin + offset.normalized() * reach, ROCK_MASK, _exclusions()
	)
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return null
	var collider: Variant = hit.get("collider")
	if not collider is Node2D:
		return null
	var rock := collider as Node2D
	if not rock.is_in_group(ROCK_GROUP):
		return null
	_hit_point = hit.get("position", rock.global_position)
	return rock


## One completed cycle: `WORK_PER_UNIT` of work into the rock, one pickup per unit
## the rock yields (02 §7.1), and the S8 chip transient on the sound bus.
func _apply_cycle() -> void:
	if _target == null or not is_instance_valid(_target):
		_target = null
		return
	var units := int(_target.call(&"apply_work", AsteroidScript.WORK_PER_UNIT))
	for _unit: int in units:
		_spawn_pickup(_hit_point)
	if units > 0:
		_play_chip()
		## L65: the shaft's own chip read draws FX_SPEC section 1.6's chip-sparks burst,
		## wired exactly as `weapons.gd`'s rock branch wires it (`:640-641`: the cue and
		## the burst together, on the one chip event). The pickup stays on the resolved
		## contact - only the effect scatters.
		ProjectileScript.spawn_chip_sparks(_hit_fx_parent(), _hit_fx_point())


## The rock's mineral becomes the cargo identity: the bare catalogue id goes
## through `MineralCatalog.ore_id`, which is the ore item id the profile's
## manifest and the exchange's sale path both read (02 §7.5, 05 §6).
func _spawn_pickup(at: Vector2) -> void:
	if _target == null:
		return
	if not ResourceLoader.exists(PICKUP_SCRIPT):
		return
	var script := load(PICKUP_SCRIPT) as GDScript
	if script == null:
		return
	var pickup := script.new() as Node2D
	if pickup == null:
		return
	pickup.name = PICKUP_NODE_NAME
	var parent := _world_parent()
	parent.add_child(pickup)
	pickup.global_position = at
	var item := MineralCatalogScript.ore_id(StringName(_target.get(&"mineral_id")))
	pickup.call(&"setup", item, 1, false)


## Pickups live in world space and outlive the shaft: the ship's transform must not
## carry them, so they are parented to the running scene (the game root) rather
## than to this node's parent chain. `current_scene` is null only in a probe that
## never changed scene, where the tree root is the world instead.
func _world_parent() -> Node:
	var tree := get_tree()
	if tree == null:
		return self
	var scene := tree.current_scene
	if scene != null:
		return scene
	return tree.root


func _exclusions() -> Array[RID]:
	var excluded: Array[RID] = []
	if not is_inside_tree():
		return excluded
	for node: Node in get_tree().get_nodes_in_group(PLAYER_GROUP):
		var body := node as CollisionObject2D
		if body != null:
			excluded.append(body.get_rid())
	return excluded


func _play_chip() -> void:
	_play_cue(CHIP_CUE)


## S7's beam bed: the loop rides the shaft, so it starts when the shaft has a rock
## under it and stops with it. `play_loop` is idempotent, so the per-frame call costs
## nothing once the bed is up.
func _play_beam_loop() -> void:
	_play_cue(BEAM_LOOP_CUE, true)


func _stop_beam_loop() -> void:
	if not is_inside_tree():
		return
	var audio := get_tree().root.get_node_or_null(NodePath(AUDIO_SERVICE))
	if audio == null or not audio.has_method(&"current_loop"):
		return
	## Only the bed this laser started is stopped - another miner's shaft is not ours
	## to silence.
	if StringName(audio.call(&"current_loop")) != BEAM_LOOP_CUE:
		return
	audio.call(&"stop_loop")


## The one door to the audio service, so a held bed and a one-shot chip cannot drift
## apart: a missing service is a no-op, exactly as before.
func _play_cue(cue: StringName, loop := false) -> void:
	if not is_inside_tree():
		return
	var audio := get_tree().root.get_node_or_null(NodePath(AUDIO_SERVICE))
	if audio == null:
		return
	if loop and audio.has_method(&"play_loop"):
		audio.call(&"play_loop", cue)
		return
	if not loop and audio.has_method(&"play_sfx"):
		audio.call(&"play_sfx", cue)


func _draw_beam() -> void:
	var local_end := to_local(_beam_drawn_end())
	_halo.points = PackedVector2Array([Vector2.ZERO, local_end])
	_core.points = PackedVector2Array([Vector2.ZERO, local_end])
	_halo.visible = true
	_core.visible = true
	## The shaft is live on a rock, so the S7 bed plays under the chip transients.
	_play_beam_loop()


## What the shaft is drawn to: the point the ray resolved, pulled `BEAM_SINK` of the way
## towards the rock's own centre (FX_SPEC section 1.6's amendment), so the beam connects
## to more of the object's middle instead of stopping at its rim. The cycle, the pickup
## and the extraction keep the resolved contact.
func _beam_drawn_end() -> Vector2:
	if _target == null or not is_instance_valid(_target):
		return _hit_point
	return _hit_point.lerp(_target.global_position, BEAM_SINK)


## FX_SPEC section 1.6's amendment: the chip sparks spawn at a uniform random point in
## the pinned `clamp(HIT_FX_JITTER_MULT x collision radius, MIN, MAX)` u disc around the
## resolved contact. The radius is the rock's own `world_radius()` (24/42/66 u by class);
## a target that answers no radius lands on the 8 u floor.
func _hit_fx_point() -> Vector2:
	var radius := clampf(
		HIT_FX_JITTER_MULT * ProjectileScript.collision_radius(_target),
		HIT_FX_JITTER_MIN,
		HIT_FX_JITTER_MAX
	)
	return ProjectileScript.scatter_in_disc(_fx_rng, _hit_point, radius)


## Where the burst hangs: the world node the rock lives in, so the sparks stay on the
## contact instead of riding the ship that fired - `weapons.gd:_hit_fx_parent`'s rule,
## kept in step with it. A target with no parent falls back to the world node.
func _hit_fx_parent() -> Node:
	if _target != null and is_instance_valid(_target) and _target.get_parent() != null:
		return _target.get_parent()
	return _world_parent()


func _extinguish() -> void:
	_target = null
	_cycle = 0.0
	_halo.visible = false
	_core.visible = false
	_stop_beam_loop()


## Leaving the tree (a hull swap, a death, a scene change) must not leave the bed
## sounding under a shaft that no longer exists.
func _exit_tree() -> void:
	_stop_beam_loop()


## Both tones come from the generated theme (no hex literals outside
## `tools/build_theme.gd`): `metal_light` is UI_SPEC §1's gunmetal light, the token
## §3.1 already uses for a non-danger energy read.
func _apply_beam_tokens() -> void:
	var theme := load(THEME_PATH) as Theme
	_halo.width = HALO_WIDTH
	_core.width = CORE_WIDTH
	var halo := Color.WHITE
	var core := Color.WHITE
	if theme != null:
		halo = theme.get_color(TOKEN_HALO, TOKENS_TYPE)
		core = theme.get_color(TOKEN_CORE, TOKENS_TYPE)
	halo.a = HALO_ALPHA
	core.a = CORE_ALPHA
	_halo.default_color = halo
	_core.default_color = core
