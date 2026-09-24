class_name Poi
extends Node2D
## One point of interest in a sector: a scannable derelict, a one-roll anomaly, a nav
## beacon that reveals the sector's POIs, or the wreck site a destroyed hull leaves.
## Contract: docs/CONTRACTS.md §19 (the pin), docs/gameplay/11_galactic_map.md §3/§5
## (derelicts, the three anomaly kinds, blip classes and soft fog), 06 §4 (the wreck
## site and its 90 s window), 15 §2/§5 (the derelict's rarity roll), 17 §4 (the sector
## clock is the only respawn timer) and 18_engine_spec §14 slice 3.
##
## The class is the POI's own logic and nothing else: it rolls, channels, grants and
## reports, and every number it grants arrives through a catalogue (`ComponentCatalog`,
## `MineralCatalog`, `ModuleCatalog`) or a constant the pin names. The wiring
## (`game.gd`) drives it - the scan channel needs the player's position and a damage
## signal - and the sector owns its placement and its blips.
##
## Pure queries (`roll_derelict`, `roll_anomaly`, `sector_band`) are static so a probe
## and a test can measure a distribution without a scene tree; the instance API works
## on a bare `Node2D` too (out of tree, a grant that needs the profile is skipped and
## reported by the return value, never by a crash).

const Registry := preload("res://game/sector_registry.gd")
const PickupScript := preload("res://game/pickup.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const MineralCatalogScript := preload("res://game/mineral_catalog.gd")
const ComponentCatalogScript := preload("res://game/component_catalog.gd")
const ModuleCatalogScript := preload("res://game/module_catalog.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const LootTablesScript := preload("res://game/loot_tables.gd")
const EconomyLogScript := preload("res://game/economy_log.gd")

## 11 §3/§3.1-§3.3's four kinds. The pin names the first three; `wreck` is 06 §4's
## wreck site, which is the same object shape (a position, a payload, a clock) and so
## lives here rather than in a fifth file (reported: 06 §4 calls it "a wreck site",
## never a POI, but nothing about it needs a class of its own).
const KIND_DERELICT: StringName = &"derelict"
const KIND_ANOMALY: StringName = &"anomaly"
const KIND_BEACON: StringName = &"beacon"
const KIND_WRECK: StringName = &"wreck"

## 11 §3.2's three anomaly kinds, in the roll's own order.
const ANOMALY_ORE_BLOOM: StringName = &"ore_bloom"
const ANOMALY_GRAVE_CACHE: StringName = &"grave_cache"
const ANOMALY_VOID_RIFT: StringName = &"void_rift"
const ANOMALY_KINDS: Array[StringName] = [
	ANOMALY_ORE_BLOOM, ANOMALY_GRAVE_CACHE, ANOMALY_VOID_RIFT,
]

## 11 §3.2's equal weights, and the Hollows' doubled rift weight (11 §5, the sector
## list lives on `SectorRegistry.ANOMALY_WEIGHTS_RIFT_DOUBLED`).
const ANOMALY_WEIGHT := 1
const ANOMALY_WEIGHT_RIFT_DOUBLED := 2

## 11 §5's blip mapping: gates and beacons `friendly`, derelicts, anomalies and wreck
## sites `neutral`. The kind set itself is frozen by §7 (no new blip kind).
const BLIP_FRIENDLY: StringName = &"friendly"
const BLIP_NEUTRAL: StringName = &"neutral"

## `scan`'s return codes (CONTRACTS §19): 0 the channel is running (or the beacon
## revealed), -1 refused (out of range, no scanner, or already spent), -2 interrupted
## (left range or took a hull hit since the last call).
const SCAN_OK := 0
const SCAN_REFUSED := -1
const SCAN_INTERRUPTED := -2

## 11 §3.1: "a 5 s scan channel, interruptible".
const SCAN_SECONDS := 5.0

## 11 §3.2: "flying within 200 units triggers a one-roll event".
const ANOMALY_TRIGGER_RADIUS := 200.0

## 11 §3.1's one reward roll: 40 % a small ore/component cache, 35 % a data core
## (03 `comp_elec` + credits), 25 % a magic-rarity module. The cache's item and stack
## are this file's own choice (the doc names no id): a small component stack of an
## already-specced pickup type. Reversal: roll the sector tier's ore instead.
const DERELICT_CACHE: StringName = &"cache"
const DERELICT_DATA_CORE: StringName = &"data_core"
const DERELICT_MODULE: StringName = &"module"
const DERELICT_CACHE_CHANCE := 0.40
const DERELICT_DATA_CORE_CHANCE := 0.35
const DERELICT_CACHE_ITEM: StringName = &"comp_scrap_1"
const DERELICT_CACHE_MIN := 1
const DERELICT_CACHE_MAX := 3

## 11 §3.1 / CONTRACTS §19: the data core pays 03's `comp_elec` plus
## `DATA_CORE_CREDITS` (120 CR proposed, reversal 60). The item grade is this file's
## choice (the doc names the family, not a grade): the family's base row.
const DATA_CORE_ITEM: StringName = &"comp_elec_1"
const DATA_CORE_CREDITS := 120

## 11 §3.2's ore bloom: "a rich T+1 asteroid cluster (10 rocks, 2× yield)".
const ORE_BLOOM_ROCKS := 10
const ORE_BLOOM_YIELD_MULT := 2
const ORE_BLOOM_TIER_BONUS := 1
const ORE_BLOOM_RADIUS := 320.0
const ORE_BLOOM_JITTER := 0.25

## 11 §3.2's grave cache: "3–5 pickups: components one grade above the sector band".
const GRAVE_CACHE_MIN := 3
const GRAVE_CACHE_MAX := 5
const GRAVE_CACHE_GRADE_BONUS := 1
const GRAVE_CACHE_GRADE_CEILING := 3

## 11 §3.2's void rift: "holds 1 exotic pickup (T4 ore or a rare affix module at
## 10 %) at its heart"; the shield drain inside is `Registry.RIFT_DRAIN` (11 §5).
const RIFT_EXOTIC_TIER := 4
const RIFT_EXOTIC_MODULE_CHANCE := 0.10

## Both module rewards (11 §3.1's derelict and 11 §3.2's rift exotic) roll at 15 §2's
## `derelict` source, the row that never pays Common (75 magic / 25 rare) - so the
## "magic-rarity module" the docs promise is the table's own floor.
const MODULE_SOURCE_DERELICT: StringName = &"derelict"

## 01 §7's log vocabulary, extended by the derelict's cache.
const EVENT_CACHE := "CACHE"

## Raised once a derelict's channel completes or a beacon reveals, carrying the
## reward (`derelict` kinds) or `&""` (a beacon). The wiring reads the credits that
## landed off this so the `+120 CR SALVAGE` feed needs no second accounting.
signal scanned(reward: StringName, credits: int)

## Raised once when an anomaly's 200 u event fires, carrying its kind.
signal triggered(anomaly_kind: StringName)

## Raised when this POI becomes visible on the minimap (scanned, triggered, or
## beacon-revealed).
signal revealed(kind: StringName)

## Raised when a credit-cache pickup a wreck site spawned leaves the world while the
## site is still open (06 §5's collection), carrying the credits the cache paid. The
## wiring turns it into the `+120 CR SALVAGE` feed line.
signal cache_collected(amount: int)

var kind: StringName = &""
var anomaly_kind: StringName = &""
var sector_id: StringName = &""

var _row: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _reward: StringName = &""
var _revealed := false
var _one_shot := false
var _triggered := false
var _channelling := false
var _channel_elapsed := 0.0
var _interrupted := false
var _rift_active := false
## A beacon reveals the sector's other POIs once, not once per frame the ship sits in
## its range (the wiring calls `scan` every frame it is the nearest scannable).
var _reveal_asked := false

## The wreck site's own clock (06 §4): `_age` counts to
## `LootTables.WRECK_PICKUP_LIFETIME`, and `_pickups` are the payload it holds.
var _age := 0.0
var _expired := false
var _pickups: Array[Node2D] = []


func _process(delta: float) -> void:
	if kind == KIND_WRECK:
		advance_lifetime(delta)


## One POI from its kind and the row its spawner rolled. `row` may carry:
##   `&"sector_id"`   - the sector this POI stands in (the Hollows' rift weighting)
##   `&"anomaly_kind"` - pins an anomaly's kind (absent rolls it, 11 §3.2)
##   `&"seed"`        - a reproducible roll for probes and tests
##   `&"payload"`     - a wreck site's already-rolled pickup payloads (06 §4)
## A beacon is visible from the moment it spawns (it is the sector's own nav aid);
## every other kind starts fogged until scanned or revealed.
func setup(poi_kind: StringName, row: Dictionary = {}) -> void:
	kind = poi_kind
	_row = row.duplicate(true)
	sector_id = StringName(_row.get(&"sector_id", &""))
	_rng = RandomNumberGenerator.new()
	var seed_value := int(_row.get(&"seed", 0))
	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	_revealed = kind == KIND_BEACON or kind == KIND_WRECK
	if kind == KIND_ANOMALY:
		var pinned := StringName(_row.get(&"anomaly_kind", &""))
		anomaly_kind = pinned if ANOMALY_KINDS.has(pinned) else roll_anomaly(
			sector_id, _rng.randi()
		)
	if kind == KIND_DERELICT:
		_reward = roll_derelict(seed_value)
	if kind == KIND_WRECK:
		_spawn_payload(_row.get(&"payload", []))


## ---------------------------------------------------------------------------
## The pure rolls (11 §3.1/§3.2) - static so a distribution is measurable alone
## ---------------------------------------------------------------------------


## 11 §3.1's one reward roll: 0.40 cache / 0.35 data core / 0.25 module.
## `random_seed` 0 randomizes; a non-zero seed makes the roll reproducible.
static func roll_derelict(random_seed: int = 0) -> StringName:
	var rng := RandomNumberGenerator.new()
	if random_seed == 0:
		rng.randomize()
	else:
		rng.seed = random_seed
	var roll := rng.randf()
	if roll < DERELICT_CACHE_CHANCE:
		return DERELICT_CACHE
	if roll < DERELICT_CACHE_CHANCE + DERELICT_DATA_CORE_CHANCE:
		return DERELICT_DATA_CORE
	return DERELICT_MODULE


## 11 §3.2's anomaly kind: equal weights over the three kinds, except the Hollows
## (11 §5's `ANOMALY_WEIGHTS_RIFT_DOUBLED`) rolls `void_rift` at 2× weight.
static func roll_anomaly(sector_id_value: StringName, random_seed: int = 0) -> StringName:
	var weights := anomaly_weights(sector_id_value)
	var total := 0
	for kind_name: StringName in ANOMALY_KINDS:
		total += int(weights[kind_name])
	if total <= 0:
		return ANOMALY_ORE_BLOOM
	var rng := RandomNumberGenerator.new()
	if random_seed == 0:
		rng.randomize()
	else:
		rng.seed = random_seed
	var roll := rng.randi_range(1, total)
	var accumulated := 0
	for kind_name: StringName in ANOMALY_KINDS:
		accumulated += int(weights[kind_name])
		if roll <= accumulated:
			return kind_name
	return ANOMALY_ORE_BLOOM


## 11 §3.2's rift exotic roll: true for a module, false for the T4 ore. Separate from
## the spawn so a distribution is measurable without minting 10 000 instances.
static func roll_rift_exotic(random_seed: int = 0) -> bool:
	var rng := RandomNumberGenerator.new()
	if random_seed == 0:
		rng.randomize()
	else:
		rng.seed = random_seed
	return rng.randf() < RIFT_EXOTIC_MODULE_CHANCE


## The three kinds' weights in one sector (11 §5: only the Hollows' rift is doubled).
static func anomaly_weights(sector_id_value: StringName) -> Dictionary:
	var rift := ANOMALY_WEIGHT
	if Registry.ANOMALY_WEIGHTS_RIFT_DOUBLED.has(sector_id_value):
		rift = ANOMALY_WEIGHT_RIFT_DOUBLED
	return {
		ANOMALY_ORE_BLOOM: ANOMALY_WEIGHT,
		ANOMALY_GRAVE_CACHE: ANOMALY_WEIGHT,
		ANOMALY_VOID_RIFT: rift,
	}


## 11 §1's tier band for one sector number: 1-2 → T1, 3-4 → T2, 5-6 → T3, 7 → T4.
## The anomaly rewards scale off it (T+1 ore, one component grade up), and 11 §1.1's
## per-sector mixes are the same bands. Clamped 1..4 so an unknown sector still rolls
## a legal tier.
static func sector_band(sector_number: int) -> int:
	return clampi(int(ceil(float(maxi(sector_number, 1)) / 2.0)), 1, 4)


## The sector number this POI stands in (`&"sector_3"` → 3, 0 for an unnamed row).
func sector_number() -> int:
	return Registry.sector_number(sector_id)


## ---------------------------------------------------------------------------
## The scan channel (11 §3.1)
## ---------------------------------------------------------------------------


## 11 §3.1's derelict scan: a 5 s channel that needs a scanner and close range.
## Returns `SCAN_OK` when the channel is (now) running, `SCAN_REFUSED` for an
## out-of-range or scannerless attempt (and for any second attempt on a spent
## derelict), and `SCAN_INTERRUPTED` when the channel was running and this call found
## the player gone or the hull hit. A beacon answers `SCAN_OK` and reveals the
## sector's POIs at once (11 §3.3); an anomaly is not scannable - it triggers.
##
## The player may be any node: the range comes from its `global_position`, and a
## duck-typed `has_scanner()` is honoured first so a probe can answer for itself. In
## flight the player is the hull, which has no such method, and the scanner is read
## off the launched fit (11 §3.1: "requires any C-slot scanner").
func scan(player) -> int:
	if kind == KIND_BEACON:
		reveal()
		_ask_parent_to_reveal()
		scanned.emit(&"", 0)
		return SCAN_OK
	if kind != KIND_DERELICT:
		return SCAN_REFUSED
	if _one_shot:
		return SCAN_REFUSED
	if not has_scanner(player):
		return SCAN_REFUSED
	if not in_scan_range(player):
		if _channelling:
			_interrupt()
			return SCAN_INTERRUPTED
		return SCAN_REFUSED
	if _interrupted:
		_interrupt()
		return SCAN_INTERRUPTED
	_channelling = true
	return SCAN_OK


## One step of the channel's clock. `SCAN_OK` while it runs and on the step that
## completes it (the reward lands then), `SCAN_INTERRUPTED` when `interrupt()` was
## called since the last step (a hull hit - `game.gd` forwards its own damage signal).
func advance_scan(delta: float) -> int:
	if not _channelling:
		return SCAN_OK
	if _interrupted:
		_interrupt()
		return SCAN_INTERRUPTED
	_channel_elapsed += delta
	if _channel_elapsed < SCAN_SECONDS:
		return SCAN_OK
	_channel_elapsed = SCAN_SECONDS
	_complete_scan()
	return SCAN_OK


## 0..1 across the 5 s channel.
func channel_progress() -> float:
	return clampf(_channel_elapsed / SCAN_SECONDS, 0.0, 1.0)


func is_channelling() -> bool:
	return _channelling


## The hull hit that breaks the channel (11 §3.1's "interruptible"). Idempotent, and
## the next `scan`/`advance_scan` call reports `SCAN_INTERRUPTED` and resets.
func interrupt() -> void:
	if _channelling:
		_interrupted = true


## Whether the player carries a scanner (11 §3.1's "any C-slot scanner"). A
## duck-typed `has_scanner()` on the player wins; otherwise the launched fit is read
## through `PlayerProfile.resolved_fit` and any computer module with a `scanner_add`
## effect answers yes (09 §3.4's scanner column - the Deep Scanner and the Nexus).
func has_scanner(player) -> bool:
	if player != null and player.has_method(&"has_scanner"):
		return bool(player.call(&"has_scanner"))
	var profile := _profile()
	if profile == null or not profile.has_method(&"resolved_fit"):
		return false
	var fit: Dictionary = profile.call(&"resolved_fit", profile.call(&"active_ship"))
	for id: StringName in ShipFitScript.fitted_ids(fit):
		var row: Dictionary = ModuleCatalogScript.module(id)
		if row.is_empty():
			continue
		var effects: Dictionary = row.get(&"effects", {})
		if float(effects.get(&"scanner_add", 0.0)) > 0.0:
			return true
	return false


## 11 §5's proposed `DERELICT_SCAN_RANGE` (300 u), measured from the POI's centre.
func in_scan_range(player) -> bool:
	return _within(player, Registry.DERELICT_SCAN_RANGE)


## ---------------------------------------------------------------------------
## The anomaly event (11 §3.2)
## ---------------------------------------------------------------------------


## 11 §3.2's one-roll event, fired when the ship flies within 200 u. ore_bloom spawns
## the rich cluster, grave_cache the grade-up pickups, void_rift its exotic and arms
## the drain. One-shot per respawn cycle (`respawn` re-arms it).
func trigger(player) -> void:
	if kind != KIND_ANOMALY or _triggered:
		return
	_triggered = true
	reveal()
	match anomaly_kind:
		ANOMALY_ORE_BLOOM:
			_spawn_ore_bloom()
		ANOMALY_GRAVE_CACHE:
			_spawn_grave_cache()
		ANOMALY_VOID_RIFT:
			_rift_active = true
			_spawn_rift_exotic()
	triggered.emit(anomaly_kind)


## The rift's shield drain for one step: `Registry.RIFT_DRAIN` (12/s) × `delta` while
## the player is inside 200 u of an active rift, 0 otherwise (11 §3.2/§5). The wiring
## applies the returned amount through the ship's own damage sink.
func update_presence(delta: float, player) -> float:
	if kind != KIND_ANOMALY or anomaly_kind != ANOMALY_VOID_RIFT or not _rift_active:
		return 0.0
	if not _within(player, ANOMALY_TRIGGER_RADIUS):
		return 0.0
	return Registry.RIFT_DRAIN * delta


## Whether the ship sits inside this POI's trigger radius (11 §3.2's 200 u).
func in_trigger_radius(player) -> bool:
	return _within(player, ANOMALY_TRIGGER_RADIUS)


## Whether this POI has spent its one shot for the current cycle.
func is_consumed() -> bool:
	if kind == KIND_DERELICT:
		return _one_shot
	if kind == KIND_ANOMALY:
		return _triggered
	if kind == KIND_WRECK:
		return _expired
	return false


## Re-arms a POI for the next sector clock band (17 §4: the sector owns the clock and
## calls this; the POI owns no timer). An anomaly re-rolls its kind.
func respawn(random_seed: int = 0) -> void:
	if kind == KIND_WRECK:
		return
	_one_shot = false
	_triggered = false
	_channelling = false
	_channel_elapsed = 0.0
	_interrupted = false
	_rift_active = false
	_reveal_asked = false
	if kind == KIND_DERELICT:
		_reward = roll_derelict(random_seed if random_seed != 0 else _rng.randi())
	if kind == KIND_ANOMALY:
		anomaly_kind = roll_anomaly(sector_id, random_seed if random_seed != 0 else _rng.randi())
	if kind != KIND_BEACON and kind != KIND_WRECK:
		_revealed = false


## This derelict's rolled reward (11 §3.1), `&""` for every other kind. Rolled at
## `setup` off the row's seed, so a probe and a test can predict it.
func reward() -> StringName:
	return _reward


## ---------------------------------------------------------------------------
## The minimap (11 §3.3/§5)
## ---------------------------------------------------------------------------


## The blip class this POI wears: beacons `friendly`, everything else `neutral`.
func blip_kind() -> StringName:
	return BLIP_FRIENDLY if kind == KIND_BEACON else BLIP_NEUTRAL


## 11 §5's soft fog: a POI's blip shows once scanned or beacon-revealed. A beacon is
## a nav aid and a wreck site is something the player just made, so both show from
## their first frame.
func is_revealed() -> bool:
	return _revealed


## Makes this POI visible on the minimap. Idempotent.
func reveal() -> void:
	if _revealed:
		return
	_revealed = true
	revealed.emit(kind)


## Whether a world point sits inside this POI's trigger radius.
func contains(world_position: Vector2) -> bool:
	return global_position.distance_to(world_position) <= ANOMALY_TRIGGER_RADIUS


## ---------------------------------------------------------------------------
## The wreck site (06 §4)
## ---------------------------------------------------------------------------


## One step of the wreck site's 90 s window. While the site lives it keeps its
## pickups aboard (their own 60 s clock is subordinated to the site's, which is the
## only persistence 06 §4 gives them); at 90 s the pickups are freed and the site
## reports expired. Returns true on the step the window closes.
func advance_lifetime(delta: float) -> bool:
	if kind != KIND_WRECK or _expired:
		return false
	_age += delta
	if _age < LootTablesScript.WRECK_PICKUP_LIFETIME:
		_hold_pickups()
		return false
	_expired = true
	_release_pickups()
	queue_free()
	return true


func is_expired() -> bool:
	return _expired


func age() -> float:
	return _age


## The live pickups this POI spawned (a derelict's cache, an anomaly's haul, a wreck
## site's payload), in spawn order.
func pickups() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for pickup: Node2D in _pickups:
		if is_instance_valid(pickup):
			out.append(pickup)
	return out


## ---------------------------------------------------------------------------
## Grants
## ---------------------------------------------------------------------------


func _complete_scan() -> void:
	_channelling = false
	_one_shot = true
	reveal()
	var reward := _reward if _reward != &"" else roll_derelict(_rng.randi())
	var credits := 0
	match reward:
		DERELICT_CACHE:
			_spawn_pickup(DERELICT_CACHE_ITEM, _rng.randi_range(DERELICT_CACHE_MIN, DERELICT_CACHE_MAX), false)
		DERELICT_DATA_CORE:
			_spawn_pickup(DATA_CORE_ITEM, 1, false)
			credits = _grant_credits(DATA_CORE_CREDITS)
		DERELICT_MODULE:
			_grant_module()
	scanned.emit(reward, credits)


## The data core's credits (11 §3.1), through the only credit owner (`PlayerProfile`,
## 17 §5 rule 2) with one `CACHE` economy-log line (01 §7). Answers what landed, 0
## when there is no profile to pay (a bare probe) so the caller's feed never lies.
func _grant_credits(amount: int) -> int:
	var profile := _profile()
	if profile == null or not profile.has_method(&"add_credits"):
		return 0
	profile.call(&"add_credits", amount)
	EconomyLogScript.append(
		EVENT_CACHE, DATA_CORE_ITEM, amount, amount, int(profile.call(&"credits"))
	)
	return amount


## 11 §3.1's 25 % magic-rarity module: `PlayerProfile.roll_instance` at 15 §2's
## `derelict` source, which never rolls Common (75 magic / 25 rare), so the floor is
## the doc's own. The base module is rolled uniformly over the catalogue's
## non-exclusive rows (15 §2/§5: the three exclusives spawn at faction stations).
func _grant_module() -> void:
	var profile := _profile()
	if profile == null or not profile.has_method(&"roll_instance"):
		return
	var base := _roll_module_base()
	if base == &"":
		return
	profile.call(&"roll_instance", base, MODULE_SOURCE_DERELICT)


func _roll_module_base() -> StringName:
	var ids: Array[StringName] = []
	for key: Variant in ModuleCatalogScript.MODULES:
		var id := StringName(str(key))
		if ModuleCatalogScript.EXCLUSIVES.has(id):
			continue
		ids.append(id)
	if ids.is_empty():
		return &""
	return ids[_rng.randi_range(0, ids.size() - 1)]


func _spawn_ore_bloom() -> void:
	var tier := mini(sector_band(sector_number()) + ORE_BLOOM_TIER_BONUS, 4)
	for index in ORE_BLOOM_ROCKS:
		var mineral: Dictionary = MineralCatalogScript.roll_mineral(tier, _rng)
		var mineral_id := StringName(mineral.get(&"id", &""))
		if mineral_id == &"":
			continue
		var units := MineralCatalogScript.roll_yield(tier, _rng) * ORE_BLOOM_YIELD_MULT
		var rock: Node2D = AsteroidScript.new() as Node2D
		_container().add_child(rock)
		rock.global_position = global_position + _cluster_offset(index)
		rock.call(&"setup", mineral_id, tier, units)


func _spawn_grave_cache() -> void:
	var grade := mini(
		sector_band(sector_number()) + GRAVE_CACHE_GRADE_BONUS, GRAVE_CACHE_GRADE_CEILING
	)
	var rows: Array[Dictionary] = ComponentCatalogScript.grade_components(grade)
	if rows.is_empty():
		return
	var count := _rng.randi_range(GRAVE_CACHE_MIN, GRAVE_CACHE_MAX)
	for index in count:
		var row: Dictionary = rows[_rng.randi_range(0, rows.size() - 1)]
		var item := StringName(row.get(&"id", &""))
		if item == &"":
			continue
		_spawn_pickup(item, 1, false, _cluster_offset(index))


func _spawn_rift_exotic() -> void:
	if roll_rift_exotic(_rng.randi()):
		_grant_module()
		return
	var rows: Array[Dictionary] = MineralCatalogScript.tier_minerals(RIFT_EXOTIC_TIER)
	if rows.is_empty():
		return
	var row: Dictionary = rows[_rng.randi_range(0, rows.size() - 1)]
	var mineral_id := StringName(row.get(&"id", &""))
	if mineral_id == &"":
		return
	_spawn_pickup(MineralCatalogScript.ore_id(mineral_id), 1, false)


## One wreck site's payload: the already-rolled `Pickup.setup` payloads (06 §2's
## shape) become the pickups the site holds for its 90 s.
func _spawn_payload(payload: Variant) -> void:
	if not payload is Array:
		return
	for entry: Variant in (payload as Array):
		if not entry is Dictionary:
			continue
		var record: Dictionary = entry
		var item := StringName(record.get(LootTablesScript.KEY_ITEM, &""))
		if item == &"":
			continue
		var pickup := _new_pickup(
			item,
			int(record.get(LootTablesScript.KEY_AMOUNT, 1)),
			bool(record.get(LootTablesScript.KEY_CACHE, false))
		)
		if pickup == null:
			continue
		## 06 §5's feed: a credit cache leaving the world is a collection while the
		## site is still open (the site's own release is guarded by `_expired`).
		if bool(record.get(LootTablesScript.KEY_CACHE, false)):
			pickup.tree_exited.connect(_on_cache_pickup_left.bind(pickup))


## 06 §5's collection hook: the cache pickup is freed (by its own collection or by the
## site's release) and this reports what it carried. A release at expiry is not a
## collection, so `_expired` silences it.
func _on_cache_pickup_left(pickup: Node2D) -> void:
	if _expired or not is_instance_valid(pickup):
		return
	cache_collected.emit(int(pickup.get(&"amount")))


func _spawn_pickup(
	item_id: StringName, amount: int, is_cache: bool, offset: Vector2 = Vector2.ZERO
) -> Node2D:
	var pickup := _new_pickup(item_id, amount, is_cache)
	if pickup != null:
		pickup.global_position = global_position + offset
	return pickup


func _new_pickup(item_id: StringName, amount: int, is_cache: bool) -> Node2D:
	if item_id == &"":
		return null
	var pickup: Node2D = PickupScript.new() as Node2D
	_container().add_child(pickup)
	pickup.global_position = global_position
	pickup.call(&"setup", item_id, maxi(amount, 1), is_cache)
	_pickups.append(pickup)
	return pickup


## 06 §4: the site is the pickups' only persistence, so while it lives it holds their
## own 60 s clock at zero (`Pickup.LIFETIME` is a constant and cannot be lengthened).
func _hold_pickups() -> void:
	for pickup: Node2D in pickups():
		pickup.set(&"_age", 0.0)


func _release_pickups() -> void:
	for pickup: Node2D in _pickups:
		if is_instance_valid(pickup):
			pickup.free()
	_pickups.clear()


func _cluster_offset(index: int) -> Vector2:
	var angle := TAU * float(index) / float(maxi(ORE_BLOOM_ROCKS, 1))
	angle += _rng.randf_range(-ORE_BLOOM_JITTER, ORE_BLOOM_JITTER)
	var radius := _rng.randf_range(ORE_BLOOM_RADIUS * 0.35, ORE_BLOOM_RADIUS)
	return Vector2.RIGHT.rotated(angle) * radius


func _within(player, radius: float) -> bool:
	if player == null or not (player is Node2D):
		return false
	return global_position.distance_to((player as Node2D).global_position) <= radius


func _interrupt() -> void:
	_channelling = false
	_channel_elapsed = 0.0
	_interrupted = false


## The beacon's reveal (11 §3.3): the sector it stands in owns its POIs, so the beacon
## asks its parent once; a bare fixture with no such parent is inert.
func _ask_parent_to_reveal() -> void:
	if _reveal_asked:
		return
	_reveal_asked = true
	var parent := get_parent()
	if parent != null and parent.has_method(&"reveal_pois"):
		parent.call(&"reveal_pois")


## Rocks and pickups are parented to the POI's container (the sector, when there is
## one) so they outlive a spent anomaly and die with the sector's own repopulation.
func _container() -> Node:
	var parent := get_parent()
	return parent if parent != null else self


## The profile autoload, anchored at the tree root (the pickup's own reach).
func _profile() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null(NodePath(&"PlayerProfile"))
