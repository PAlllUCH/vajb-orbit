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
## (ASSET_AUDIT item 8), and the S7 beam bed is a `loop = true` stream that the
## shared `play_sfx` voice must not be handed (see the W3 report's open points).
const CHIP_CUE: StringName = &"sfx_mining_chip_01"

const THEME_PATH := "res://ui/theme/vajb_theme.tres"
const TOKENS_TYPE: StringName = &"Tokens"
const TOKEN_HALO: StringName = &"metal_light"
const TOKEN_CORE: StringName = &"text_dim"

const HALO_WIDTH := 3.0
const CORE_WIDTH := 1.0
const HALO_ALPHA := 0.45
const CORE_ALPHA := 0.9

@onready var _halo: Line2D = $Beam
@onready var _core: Line2D = $BeamCore

var _stats: ShipStats = null
var _active := false

var _target: Node2D = null
var _hit_point := Vector2.ZERO
var _cycle := 0.0


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
	if not is_inside_tree():
		return
	var audio := get_tree().root.get_node_or_null(NodePath(AUDIO_SERVICE))
	if audio == null or not audio.has_method(&"play_sfx"):
		return
	audio.call(&"play_sfx", CHIP_CUE)


func _draw_beam() -> void:
	var local_end := to_local(_hit_point)
	_halo.points = PackedVector2Array([Vector2.ZERO, local_end])
	_core.points = PackedVector2Array([Vector2.ZERO, local_end])
	_halo.visible = true
	_core.visible = true


func _extinguish() -> void:
	_target = null
	_cycle = 0.0
	_halo.visible = false
	_core.visible = false


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
