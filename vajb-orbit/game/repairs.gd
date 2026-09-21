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
## The same module offers the two power services (18_engine_spec section 4.4 ruling
## 13, section 12 item 8, 14_station_services section 1): `refuel` fills the tank and
## `recharge` reports the Energy top-up. The owner ruling of 2026-09-21 made both free
## and instant, so neither charges CR and no rate is invented: the `fee` in their
## results is the free-rate report, exactly as this module's own fee reports 0 for the
## exempt shield top-up. Fuel is the persisted pool (18 section 12 item 13), so
## `refuel` writes it into the same vitals record the damage report lives in; Energy
## is recomputed at launch (the `PlayerState.setup` handshake, section 4.4), so
## `recharge` has nothing to persist and reports the launch figure instead.
## Depends on the PlayerProfile `vitals` amendment added for this panel (01
## section 6, extended by 18 section 12 item 13): vitals_of(ship_id) ->
## {hull, shield, fuel} is the stored damage report and set_vitals(ship_id, hull,
## shield, fuel) writes it back. Ship maxima come from StationCatalog.ship(); the
## tank figure comes from ShipFit's snapshot — the 18 section 9/13 single owner of
## the pool numbers, so no rate or pool size is written twice. Profile calls are
## dynamic (call()): the autoload has no class_name on purpose (see
## autoload/player_profile.gd).
## Contract: docs/gameplay/01_economy_core.md sections 6 and 7,
## docs/gameplay/14_station_services.md section 1.

const Catalog := preload("res://game/station_catalog.gd")
const Fit := preload("res://game/ship_fit.gd")
const Log := preload("res://game/economy_log.gd")

const HULL_CR_PER_POINTS := 2
const SHIELD_CR_PER_POINTS := 3
const SHIELD_MIN_EXEMPT_PERCENT := 0.9

## The owner ruling of 2026-09-21: refuel and recharge are free and instant, and the
## spec carries no refuel CR rate. This is the only figure a free service may report;
## nothing may be invented in its place.
const FREE_FEE := 0

const REASON_NO_DAMAGE_REPORT: StringName = &"no_damage_report"
const REASON_NO_DAMAGE: StringName = &"no_damage"
const REASON_INSUFFICIENT: StringName = &"insufficient_credits"
const REASON_FUEL_FULL: StringName = &"fuel_full"
const REASON_NO_SERVICE: StringName = &"no_service"

const EVENT_REPAIR := "REPAIR"
const EVENT_REFUEL := "REFUEL"
const EVENT_RECHARGE := "RECHARGE"


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


## The station's free refuel (18 section 4.4 ruling 13, section 12 item 8): the tank
## is filled to the hull's `fuel_max` and filed with the damage report, so the launch
## handshake seeds it (fuel persists; Energy recomputes). Rounded to whole fuel
## points, because that is the unit the vitals record stores and the log prints.
## Refuses a full tank — there is nothing to fill — and a ship with no filed report,
## exactly as `repair` refuses a full hull and an unfiled ship. Nothing is touched
## unless the whole call can run. Success returns
## {&"ok": true, &"ship_id", &"fee", &"fuel_max"} with the fee at the free rate.
static func refuel(profile: Node, ship_id: StringName) -> Dictionary:
	if Catalog.service(Catalog.SERVICE_REFUEL).is_empty():
		## 14 section 1: the catalogue is the availability authority. A station that
		## does not offer the service cannot run it.
		return _refuse(REASON_NO_SERVICE)
	var current := _vitals(profile, ship_id)
	if current.is_empty():
		return _refuse(REASON_NO_DAMAGE_REPORT)
	var tank := _pool_max(ship_id)
	if tank <= 0:
		return _refuse(REASON_NO_DAMAGE_REPORT)
	var filed := int(current.get(&"fuel", 0))
	if filed >= tank:
		return _refuse(REASON_FUEL_FULL)
	_write(profile, ship_id, current, tank)
	Log.append(EVENT_REFUEL, ship_id, tank - filed, FREE_FEE, _credits(profile))
	return {
		&"ok": true,
		&"ship_id": ship_id,
		&"fee": FREE_FEE,
		&"fuel_max": tank,
	}


## The station's free Energy top-up (14 section 1: every station, free and instant).
## Energy is not a persisted pool — 18 section 12 item 13 recomputes it at launch,
## which is precisely the top-up this service promises — so the call files nothing to
## the profile and reports the figure the launch handshake will use. Refusals match
## `refuel`'s, minus the full-tank case (an unfiled Energy reading has no "full").
## Success returns {&"ok": true, &"ship_id", &"fee", &"energy_max"} at the free rate.
static func recharge(profile: Node, ship_id: StringName) -> Dictionary:
	if Catalog.service(Catalog.SERVICE_RECHARGE).is_empty():
		return _refuse(REASON_NO_SERVICE)
	var current := _vitals(profile, ship_id)
	if current.is_empty():
		return _refuse(REASON_NO_DAMAGE_REPORT)
	var cells := _pool_max(ship_id, true)
	if cells <= 0:
		return _refuse(REASON_NO_DAMAGE_REPORT)
	Log.append(EVENT_RECHARGE, ship_id, 0, FREE_FEE, _credits(profile))
	return {
		&"ok": true,
		&"ship_id": ship_id,
		&"fee": FREE_FEE,
		&"energy_max": cells,
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


## The 18 section 9/13 pool figure for a hull, from its single owner: the launch
## snapshot resolver. The fit is the 09 section 7 standard fit, the one `game.gd`
## launches with, so the tank the station fills is the tank the launch handshake
## seeds (P2's fitting UI moves both together). Zero for an unknown hull, which is
## the caller's refusal signal.
static func _pool_max(ship_id: StringName, energy: bool = false) -> int:
	var stats: ShipStats = Fit.resolve(ship_id, Fit.STANDARD_FIT)
	if stats == null:
		return 0
	return maxi(0, int(round(stats.energy_max if energy else stats.fuel_max)))


## Files the tank beside the hull and shield of the existing report. The hull and
## shield arguments are the stored ones, so a refuel never moves them.
static func _write(profile: Node, ship_id: StringName, current: Dictionary, fuel: int) -> void:
	profile.call(
		&"set_vitals",
		ship_id,
		int(current.get(&"hull", 0)),
		int(current.get(&"shield", 0)),
		fuel,
	)


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
