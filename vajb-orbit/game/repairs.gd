class_name Repairs
extends RefCounted
## Station REPAIRS module: the K2 credit sink from docs/gameplay/01_economy_core.md
## section 6, executed with the section 7 ordering (verify -> pay -> restore -> log).
## Stateless and fully static: the profile is passed in, never reached through a
## bare autoload identifier.
## Fee (01 section 6): 1 CR per 2 missing hull points + 1 CR per 3 missing shield
## points, each side rounded up, so a Vanguard home at 20 % hull / 50 % shield pays
## (800/2) + (300/3) = 500 CR. Shield alone at >= 90 % is exempt (01 section 6):
## a trivial trip is not taxed.
## Depends on the PlayerProfile `vitals` amendment added for this panel (01
## section 6): vitals_of(ship_id) -> {hull, shield} is the stored damage report and
## set_vitals(ship_id, hull, shield) writes it back. Ship maxima come from
## StationCatalog.ship(). Profile calls are dynamic (call()): the autoload has no
## class_name on purpose (see autoload/player_profile.gd).
## Contract: docs/gameplay/01_economy_core.md sections 6 and 7.

const Catalog := preload("res://game/station_catalog.gd")
const Log := preload("res://game/economy_log.gd")

const HULL_CR_PER_POINTS := 2
const SHIELD_CR_PER_POINTS := 3
const SHIELD_MIN_EXEMPT_PERCENT := 0.9

const REASON_NO_DAMAGE_REPORT: StringName = &"no_damage_report"
const REASON_NO_DAMAGE: StringName = &"no_damage"
const REASON_INSUFFICIENT: StringName = &"insufficient_credits"

const EVENT_REPAIR := "REPAIR"


## 01 section 6 fee for topping the ship back up, 0 when there is nothing to pay:
## an unknown ship, no damage report, or the shield-alone exemption.
static func fee(profile: Node, ship_id: StringName) -> int:
	var current := _vitals(profile, ship_id)
	if current.is_empty():
		return 0
	var ship := Catalog.ship(ship_id)
	if ship.is_empty():
		return 0
	var hull_max := int(ship.get(&"hull", 0))
	var shield_max := int(ship.get(&"shield", 0))
	var hull := int(current.get(&"hull", 0))
	var shield := int(current.get(&"shield", 0))
	var hull_missing := maxi(0, hull_max - hull)
	var shield_missing := maxi(0, shield_max - shield)
	if hull_missing == 0 and float(shield) >= SHIELD_MIN_EXEMPT_PERCENT * float(shield_max):
		return 0
	return (
		ceili(float(hull_missing) / float(HULL_CR_PER_POINTS))
		+ ceili(float(shield_missing) / float(SHIELD_CR_PER_POINTS))
	)


## One all-or-nothing repair (01 section 7: verify -> pay -> restore -> log).
## Nothing is touched unless every step can be completed. Success returns
## {&"ok": true, &"ship_id", &"fee", &"hull_max", &"shield_max"}; a refusal returns
## {&"ok": false, &"reason": ...} and leaves credits and vitals exactly as they were.
static func repair(profile: Node, ship_id: StringName) -> Dictionary:
	var current := _vitals(profile, ship_id)
	if current.is_empty():
		return _refuse(REASON_NO_DAMAGE_REPORT)
	var ship := Catalog.ship(ship_id)
	if ship.is_empty():
		return _refuse(REASON_NO_DAMAGE_REPORT)
	var hull_max := int(ship.get(&"hull", 0))
	var shield_max := int(ship.get(&"shield", 0))
	var hull := int(current.get(&"hull", 0))
	var shield := int(current.get(&"shield", 0))
	if hull >= hull_max and shield >= shield_max:
		return _refuse(REASON_NO_DAMAGE)
	var cost := fee(profile, ship_id)
	if cost > 0:
		if _credits(profile) < cost:
			return _refuse(REASON_INSUFFICIENT)
		if not _spend(profile, cost):
			return _refuse(REASON_INSUFFICIENT)
	_restore(profile, ship_id, hull_max, shield_max)
	Log.append(EVENT_REPAIR, ship_id, 0, -cost, _credits(profile))
	return {
		&"ok": true,
		&"ship_id": ship_id,
		&"fee": cost,
		&"hull_max": hull_max,
		&"shield_max": shield_max,
	}


## Whether the REPAIRS panel should offer anything at all: false for a full ship
## and for a ship with no damage report.
static func is_repairable(profile: Node, ship_id: StringName) -> bool:
	var current := _vitals(profile, ship_id)
	if current.is_empty():
		return false
	var ship := Catalog.ship(ship_id)
	if ship.is_empty():
		return false
	var hull := int(current.get(&"hull", 0))
	var shield := int(current.get(&"shield", 0))
	if hull >= int(ship.get(&"hull", 0)) and shield >= int(ship.get(&"shield", 0)):
		return false
	if fee(profile, ship_id) > 0:
		return true
	# Exemption case (01 section 6): the free top-up is still a repair.
	return shield < int(ship.get(&"shield", 0))


static func _vitals(profile: Node, ship_id: StringName) -> Dictionary:
	if profile == null or ship_id == &"":
		return {}
	var stored: Variant = profile.call(&"vitals_of", ship_id)
	if stored is Dictionary:
		var record: Dictionary = stored
		return record
	return {}


static func _credits(profile: Node) -> int:
	return int(profile.call(&"credits"))


static func _spend(profile: Node, amount: int) -> bool:
	return profile.call(&"spend", amount) == true


static func _restore(profile: Node, ship_id: StringName, hull_max: int, shield_max: int) -> void:
	profile.call(&"set_vitals", ship_id, hull_max, shield_max)


static func _refuse(reason: StringName) -> Dictionary:
	return {&"ok": false, &"reason": reason}
