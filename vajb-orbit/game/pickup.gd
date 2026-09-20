class_name Pickup
extends Node2D
## A floating cargo pickup: an ore unit popped off a rock (02 §7.1) or, later, a
## credit cache from a wreck (ENGINE_SPEC §2 decision 7).
## Contract: ENGINE_SPEC.md §6 ("Pickups: tractor range/speed base values in §13;
## uncollected pickups despawn after 60 s"; "hold full: further pickups drift, no
## auto-sell, no jettison"), §13 (60 s lifetime, 120 u tractor range, 90 u/s pull),
## §15 ("hold-full leaves pickups drifting"); docs/gameplay/02_minerals.md §7
## (tractoring, the 60 s despawn, hold-full, per-mineral cargo identity) and
## §7.5/§1.2 (cargo keys and one unit of weight per item); 01 §7 (every economy
## event logs); brief §W3 item 4 and pinned interface item 6.
##
## Collection is the only place this file changes the world, and it goes through
## `PlayerProfile` — the sole owner of credits and cargo (17 §5 rule 2) — plus one
## `economy_log` line per stack (01 §7).
##
## Slice-1 scope: the tractor figures are §13's base values as constants, because
## the pinned `setup(item_id, amount, is_credit_cache)` carries no `ShipStats`.
## `u_salvage` (2× range and speed) and `u_tractor` (+1 stream) are slice 4 and need
## a `bind(stats)` seam this file does not have; see the W3 report's open points.
## The hold capacity is the one ship number this file does read, through the live
## accessor `PlayerShip.cargo_max()`, so the hold-full gate and the HUD bar share it.

const ProfileService: StringName = &"PlayerProfile"
const Log := preload("res://game/economy_log.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const MineralCatalogScript := preload("res://game/mineral_catalog.gd")

## ENGINE_SPEC §13, verbatim: "Pickup lifetime 60 s; tractor 120 u range, 90 u/s
## pull".
const LIFETIME := 60.0
const TRACTOR_RANGE := 120.0
const TRACTOR_SPEED := 90.0

## The distance at which a pulled pickup counts as aboard. No spec number exists
## (the ship is ~60 u long, so this is the hold mouth); one edit reverses it.
const ARRIVAL_RADIUS := 16.0

## 01 §7's log vocabulary, extended by the two events the flight scene adds.
const EVENT_MINE := "MINE"
const EVENT_CACHE := "CACHE"

## The shipped world-pickup prop (ASSET_CATALOG, `env/` Phase D: "ore container
## with visible rusted-ochre ore veins at the seam"), drawn at a hold-sized 20 u
## across. Credit caches are slice-2 content with no dedicated prop, so the seam
## reuses this one; see the W3 report's art-gap note.
const POD_TEXTURE := preload("res://assets/env/env_pickup_ore_pod.png")
const POD_WIDTH := 20.0

const PICKUP_GROUP: StringName = &"pickup"
const PLAYER_GROUP: StringName = &"player_ship"

var item_id: StringName = &""
var amount: int = 1
var is_credit_cache := false

var _age := 0.0
var _sprite: Sprite2D = null


## Which cargo identity this pickup carries and how much of it. Ore arrives as the
## rock's mineral (a bare catalogue id like `&"iron"`); the cargo key is the item
## id the rest of the economy reads (`mineral_iron`), so both forms are accepted
## and resolved once, at collection.
func setup(item: StringName, quantity: int, credit_cache: bool) -> void:
	item_id = item
	amount = maxi(quantity, 1)
	is_credit_cache = credit_cache
	add_to_group(PICKUP_GROUP)
	_build_look()


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	var ship := _player_ship()
	if ship == null:
		return
	var distance := global_position.distance_to(ship.global_position)
	if distance > TRACTOR_RANGE:
		return
	## 02 §7.3: a full hold leaves the pickup drifting, uncollected, until its
	## lifetime runs out. It is not pulled either, so it cannot be dragged into the
	## hull: `hold full` costs the pickup, not the player's cargo. A credit cache
	## is not cargo — `amount` is credits, which no hold limits (ENGINE_SPEC §6:
	## "credit caches pay on pickup") — so the gate is an ore rule only, and it sits
	## behind the range check so a field of pickups costs nothing until it is close.
	if not is_credit_cache and not _hold_has_room(ship):
		return
	if distance <= ARRIVAL_RADIUS:
		_collect()
		return
	global_position = global_position.move_toward(ship.global_position, TRACTOR_SPEED * delta)


## The credits/cargo handoff. Credits go through the profile's credit API, ore
## through `add_cargo`, and both write exactly one `economy_log` line (01 §7).
func _collect() -> void:
	var profile := _profile()
	if profile == null:
		return
	var key := _cargo_key()
	if is_credit_cache:
		profile.call(&"add_credits", amount)
		Log.append(EVENT_CACHE, key, amount, amount, int(profile.call(&"credits")))
	else:
		profile.call(&"add_cargo", key, amount)
		Log.append(EVENT_MINE, key, amount, 0, int(profile.call(&"credits")))
	queue_free()


## A bare mineral id (`iron`) becomes its ore item id (`mineral_iron`) because
## that is the key 02 §7.5's manifest and 05's sale path read cargo by
## (`Exchange._bulk_ids` walks `MineralCatalog.ore_id()`). An id already in item
## form passes through untouched, and an unknown id is passed through so the
## profile's own free-form cargo contract still applies (02 §7.5).
func _cargo_key() -> StringName:
	if MineralCatalogScript.is_ore(item_id) or MineralCatalogScript.is_ingot(item_id):
		return item_id
	var ore := MineralCatalogScript.ore_id(item_id)
	return ore if ore != &"" else item_id


## 02 §1.2: every item weighs one unit, so the fill is the summed manifest. The
## capacity is the hold the ship actually flies, `PlayerShip.cargo_max()`, the live
## value `game.gd` seeds `PlayerState.cargo_max` from out of the `ShipFit` snapshot
## (ENGINE_SPEC §9) and the number the HUD bar reads. One source, so the hold-full
## line and the bar can never disagree, and a hull the station catalogue does not
## list still fills to its real capacity. A missing profile, or a hull with no hold,
## reports "no room" and the pickup keeps drifting rather than silently losing its
## cargo.
func _hold_has_room(ship: Node) -> bool:
	var capacity := _ship_hold(ship)
	if capacity <= 0:
		return false
	var profile := _profile()
	if profile == null:
		return false
	var used := 0
	var items: Dictionary = profile.call(&"cargo_items")
	for quantity: Variant in items.values():
		used += int(quantity)
	return used + amount <= capacity


## The live accessor is the primary reader; a group member that does not expose it
## (a probe's stand-in, or a ship before `setup`) falls back to `ShipFit.HULLS` for
## the profile's active hull, which is the table the accessor is seeded from and the
## one ENGINE_SPEC §9 pins. The station catalogue's `cargo` column is deliberately
## not consulted: it lists four of the nine hulls, so reading it stranded ore on the
## other five.
func _ship_hold(ship: Node) -> int:
	if ship != null and ship.has_method(&"cargo_max"):
		return int(ship.call(&"cargo_max"))
	var profile := _profile()
	if profile == null:
		return 0
	var row: Dictionary = ShipFitScript.HULLS.get(StringName(profile.call(&"active_ship")), {})
	return int(row.get(&"cargo", 0))


## Anchored at the tree root: the profile is an autoload, so a bare `PlayerProfile`
## path would resolve against this node instead (STATION_SPEC §1).
func _profile() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null(NodePath(ProfileService))


func _player_ship() -> Node2D:
	if not is_inside_tree():
		return null
	return get_tree().get_first_node_in_group(PLAYER_GROUP) as Node2D


func _build_look() -> void:
	_sprite = Sprite2D.new()
	_sprite.name = &"Pod"
	_sprite.texture = POD_TEXTURE
	var scale_factor := POD_WIDTH / maxf(float(POD_TEXTURE.get_width()), 1.0)
	_sprite.scale = Vector2(scale_factor, scale_factor)
	add_child(_sprite)
