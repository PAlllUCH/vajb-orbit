extends Node2D
## S23-R1's re-measure probe (worker S23-R1, 2026-10-02): the reviewer's own scratch
## replay of the wave's measured values, per the W8 byte-identical-replay practice -
## the gate suites are the record, this probe re-derives the numbers independently and
## prints one line per measure. Bounded: it prints in `_ready` and quits itself; the
## launching shell also binds the run with `--quit-after`.
##
## Writes nothing that survives: the run is launched under a scratch `XDG_DATA_HOME`
## (L229), the borrowed profile keys are snapshotted and put back, and no economy line
## is filed beyond the one probe purchase the scratch account pays for.

const FitScript := preload("res://game/ship_fit.gd")
const WeaponScript := preload("res://game/weapons.gd")
const StationCatalogScript := preload("res://game/station_catalog.gd")
const ModuleScript := preload("res://game/module_catalog.gd")
const RegistryScript := preload("res://game/npc_registry.gd")
const SectorRegistryScript := preload("res://game/sector_registry.gd")
const LootScript := preload("res://game/loot_tables.gd")
const Components := preload("res://game/component_catalog.gd")
const RefineryScript := preload("res://game/refinery.gd")
const MineralCatalogScript := preload("res://game/mineral_catalog.gd")
const PlayerShipScene := preload("res://game/player_ship.tscn")
const PlayerStateScript := preload("res://game/player_state.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")

const HULL_IDS: Array[StringName] = [
	&"ship_fighter", &"ship_vanguard", &"ship_miner", &"ship_trader",
	&"ship_corvette", &"ship_freighter", &"ship_gunship", &"ship_patrol",
	&"ship_destroyer",
]

const WIRED_ART: Array[String] = [
	"res://assets/ships/ship_fighter_side.png",
	"res://assets/ships/ship_vanguard_side.png",
	"res://assets/ships/ship_miner_side.png",
	"res://assets/ships/ship_trader_side.png",
	"res://assets/ships/ship_corvette_side.png",
	"res://assets/ships/ship_freighter_side.png",
	"res://assets/ships/ship_gunship_side.png",
	"res://assets/ships/ship_patrol_side.png",
	"res://assets/ships/ship_destroyer_side.png",
	"res://assets/ships/ship_sibelon_side.png",
	"res://assets/ships/ship_interceptor_side.png",
	"res://assets/ships/ship_turret_platform.png",
	"res://assets/ships/ship_fighter_choir_side.png",
	"res://assets/ships/ship_fighter_concord_side.png",
	"res://assets/ships/ship_fighter_meridian_side.png",
	"res://assets/ships/ship_vanguard_damaged_side.png",
	"res://assets/icons/weapon/icon_ammo_rocket.png",
	"res://assets/icons/weapon/icon_weapon_cannon.svg",
	"res://assets/icons/cargo/icon_cargo_container.svg",
	"res://assets/icons/module/icon_module_w_railgun.svg",
]

var _staged: Array[Node] = []


func _ready() -> void:
	_families()
	_packs_and_ammo()
	_exclusivity()
	_modules()
	_fits()
	_sibelon_and_hulls()
	_hull_identity()
	_assets()
	_loot()
	_credits_floor()
	print("[S23R1] done")
	get_tree().quit(0)


func _families() -> void:
	var proton := WeaponScript.row_of(&"proton")
	var flak := WeaponScript.row_of(&"flak")
	print("[S23R1] proton cooldown=%s alpha=%s speed=%s turn=%s track=%s bypass=%s draw_key=%s" % [
		proton.get(&"cooldown"), proton.get(&"alpha"), proton.get(&"speed"),
		proton.get(&"turn_rate"), proton.get(&"track_dps"),
		proton.get(&"bypass_shield"), "MISSING" if not proton.has(&"draw") else str(proton[&"draw"]),
	])
	print("[S23R1] flak interval=%s alpha=%s pellets=%s spread=%s speed=%s track=%s bypass=%s bonus=%s draw_key=%s" % [
		flak.get(&"interval"), flak.get(&"alpha"), flak.get(&"pellets"),
		flak.get(&"spread_deg"), flak.get(&"speed"), flak.get(&"track_dps"),
		flak.get(&"bypass_shield"), flak.get(&"target_bonus"),
		"MISSING" if not flak.has(&"draw") else str(flak[&"draw"]),
	])


func _packs_and_ammo() -> void:
	for id: StringName in [&"proton", &"flak"]:
		var pack := StationCatalogScript.ammo_pack(id)
		print("[S23R1] pack %s rounds=%s cost=%s icon=%s" % [
			id, pack.get(&"rounds"), pack.get(&"cost"), pack.get(&"icon"),
		])
	var profile := _profile()
	if profile == null:
		print("[S23R1] packs skip: no profile autoload")
		return
	print("[S23R1] ammo_max proton=%s flak=%s" % [
		profile.call(&"ammo_max", &"proton"), profile.call(&"ammo_max", &"flak"),
	])
	var credits := int(profile.call(&"credits"))
	var cargo: Dictionary = (profile.get(&"_cargo") as Dictionary).duplicate()
	var ammo: Dictionary = (profile.get(&"_ammo") as Dictionary).duplicate()
	var bought := bool(profile.call(&"buy_ammo", &"proton", 40, 400))
	print("[S23R1] buy_ammo proton ok=%s ammo_after=%s credits_after=%s" % [
		bought, profile.call(&"ammo_of", &"proton"), int(profile.call(&"credits")) - credits,
	])
	var loaded := int(profile.call(&"load_ammo_from_hold", &"proton"))
	print("[S23R1] load_ammo_from_hold proton=%s" % loaded)
	profile.set(&"_credits", credits)
	profile.set(&"_cargo", cargo)
	profile.set(&"_ammo", ammo)
	profile.set(&"_ammo_rem", {})


func _exclusivity() -> void:
	print("[S23R1] exclusives proton=%s flak=%s floor=%s magic=%s" % [
		ModuleScript.EXCLUSIVES.get(&"w_proton"), ModuleScript.EXCLUSIVES.get(&"w_flak"),
		ModuleScript.EXCLUSIVE_FLOOR, ModuleScript.RARITY_MAGIC,
	])


func _modules() -> void:
	print("[S23R1] refine list fee1=%s fee2=%s" % [
		RefineryScript.fee_for(1), RefineryScript.fee_for(2),
	])
	var profile := _profile()
	if profile == null:
		print("[S23R1] refine skip: no profile autoload")
		return
	var active: StringName = StringName(profile.call(&"active_ship"))
	var fits: Dictionary = profile.get(&"_fits")
	var saved_fit: Variant = fits.get(active)
	var saved_active: StringName = active
	profile.call(&"set_fit", &"ship_vanguard", {
		&"engines": [&"e_std"], &"power": &"p_std", &"utility": [&"u_refine"],
	})
	profile.set(&"_active_ship", &"ship_vanguard")
	var mult := float(RefineryScript.fee_multiplier(profile))
	print("[S23R1] refine fitted mult=%s fee1=%s fee2=%s ore_per_ingot=%s" % [
		mult, RefineryScript.fee_for(1, mult), RefineryScript.fee_for(2, mult),
		RefineryScript.ORE_PER_INGOT,
	])
	profile.set(&"_active_ship", saved_active)
	if saved_fit != null:
		fits[active] = saved_fit
	else:
		fits.erase(active)
	var ship := _player_rig([&"c_ewar"])
	if ship != null:
		print("[S23R1] ewar alone=%s" % float(ship.call(&"ewar_slow")))
		ship.call(&"set_hull_id", &"ship_vanguard")
		var nexus := _player_rig([&"c_ewar", &"c_nexus"])
		if nexus != null:
			print("[S23R1] ewar with_nexus=%s" % float(nexus.call(&"ewar_slow")))
	var drones := _player_rig([&"u_drones"])
	if drones != null:
		var state: PlayerState = drones.get(&"_state")
		state.set_hull(state.hull_max - 4.0)
		var before := float(state.hull)
		drones.call(&"_physics_process", 0.5)
		print("[S23R1] drones half_s_gain=%s (target 1.0)" % (float(state.hull) - before))


func _fits() -> void:
	for hull_id: StringName in HULL_IDS:
		var fit := FitScript.standard_fit(hull_id)
		var legal := FitScript.fit_legal(hull_id, fit)
		var power: Dictionary = legal.get(&"power", {})
		print("[S23R1] fit %s legal=%s draw=%s out=%s spare=%s overflow=%s missing=%s" % [
			hull_id, legal.get(&"legal"), power.get(&"draw"), power.get(&"out"),
			power.get(&"spare"), legal.get(&"overflow"), legal.get(&"missing"),
		])


func _sibelon_and_hulls() -> void:
	var sibelon := RegistryScript.archetype(&"sibelon")
	print("[S23R1] sibelon hull=%s sprite=%s loot=%s spawn=%s seam=%s fill=%s" % [
		sibelon.get(RegistryScript.KEY_HULL_ID), sibelon.get(RegistryScript.KEY_SPRITE_BASE),
		sibelon.get(RegistryScript.KEY_LOOT_KIND), sibelon.get(RegistryScript.KEY_SPAWN),
		sibelon.get(RegistryScript.KEY_SEAM), RegistryScript.HOSTILE_FILL,
	])
	for index in 7:
		var sector := &"sector_%d" % (index + 1)
		var band := RegistryScript.density(&"pirate", sector)
		band += RegistryScript.density(&"swarmer", sector)
		band += RegistryScript.density(&"sibelon", sector)
		print("[S23R1] fill %s pirate=%s swarmer=%s sibelon=%s sum=%s" % [
			sector, RegistryScript.density(&"pirate", sector),
			RegistryScript.density(&"swarmer", sector),
			RegistryScript.density(&"sibelon", sector), band,
		])
	var interceptor := FitScript.resolve(&"ship_interceptor", {})
	var turret := FitScript.resolve(&"ship_turret_platform", {})
	if interceptor != null:
		print("[S23R1] interceptor hull=%s shield=%s speed=%s" % [
			interceptor.hull_max, interceptor.shield_max, interceptor.max_speed,
		])
	if turret != null:
		print("[S23R1] turret hull=%s shield=%s speed=%s" % [
			turret.hull_max, turret.shield_max, turret.max_speed,
		])
	var turret_row := RegistryScript.archetype(&"turret")
	print("[S23R1] turret_row spawn=%s static=%s" % [
		turret_row.get(RegistryScript.KEY_SPAWN), turret_row.get(RegistryScript.KEY_STATIC),
	])


func _hull_identity() -> void:
	for hull_id: StringName in [&"ship_freighter", &"ship_destroyer", &"ship_vanguard"]:
		var ship := _player_rig([], false, hull_id)
		if ship == null:
			continue
		var sprite := ship.get_node_or_null(NodePath("Hull")) as Sprite2D
		var shape := ship.get_node_or_null(NodePath("HullBody/Shape")) as CollisionShape2D
		var radius := 0.0
		if shape != null and shape.shape is CircleShape2D:
			radius = (shape.shape as CircleShape2D).radius
		print("[S23R1] identity %s tex=%s scale=%s radius=%s anchor_scale=%s" % [
			hull_id,
			String(sprite.texture.resource_path).get_file() if sprite != null else "none",
			sprite.scale.x if sprite != null else -1.0,
			radius,
			(ship.call(&"_hull_sprite_scale") as Vector2).x,
		])
		var row := FitScript.side_view(hull_id)
		print("[S23R1] ladder %s length=%s ink=%s scale=%s radius=%s" % [
			hull_id, row.get(&"length"), row.get(&"ink"), row.get(&"scale"), row.get(&"radius"),
		])


func _assets() -> void:
	var missing := 0
	for path: String in WIRED_ART:
		var ok := ResourceLoader.exists(path)
		if not ok:
			missing += 1
		print("[S23R1] art %s %s" % ["OK" if ok else "MISSING", path])
	print("[S23R1] art_missing=%d of %d" % [missing, WIRED_ART.size()])


func _loot() -> void:
	print("[S23R1] uncatalogued=%s" % [LootScript.uncatalogued_items()])
	var tiers := ""
	for index in 7:
		tiers += "S%d=%s " % [index + 1, SectorRegistryScript.sector_tier(&"sector_%d" % (index + 1))]
	print("[S23R1] sector_tier %s" % tiers)
	print("[S23R1] cache_scale 1=%s 2=%s 3=%s 4=%s hunter_lines=%s" % [
		LootScript.cache_scale(1), LootScript.cache_scale(2), LootScript.cache_scale(3),
		LootScript.cache_scale(4), LootScript.HUNTER_LINES.size(),
	])
	var elec_twos := 0
	var elec_ones := 0
	for seed_value in 60:
		for entry: Dictionary in LootScript.roll_band(&"hunter", 424000 + seed_value):
			var item := StringName(entry[LootScript.KEY_ITEM])
			if item == &"comp_elec_2":
				elec_twos += 1
			elif item == &"comp_elec_1":
				elec_ones += 1
	print("[S23R1] hunter_60_rolls elec_1=%s elec_2=%s (cap keeps 2 off band 1)" % [elec_ones, elec_twos])


func _credits_floor() -> void:
	var profile := _profile()
	if profile == null:
		print("[S23R1] credits skip: no profile autoload")
		return
	var credits := int(profile.call(&"credits"))
	profile.call(&"add_credits", -credits - 5)
	print("[S23R1] credits floor_after_overdraw=%s" % int(profile.call(&"credits")))
	profile.call(&"add_credits", credits)


func _player_rig(fit_ids: Array, _physical := false, hull: StringName = &"ship_vanguard") -> Node2D:
	var ship: Node2D = PlayerShipScene.instantiate() as Node2D
	if ship == null:
		return null
	var host := _profile()
	if host == null:
		ship.free()
		return null
	host.add_child(ship)
	_staged.append(ship)
	var stats: ShipStats = FitScript.resolve(hull, {})
	var state := PlayerStateScript.new()
	state.setup()
	ship.call(&"set_hull_id", hull)
	var fit: Array[StringName] = []
	for id: Variant in fit_ids:
		fit.append(StringName(id))
	ship.call(&"setup", stats, state, fit)
	return ship


func _profile() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(NodePath(&"PlayerProfile"))


func _exit_tree() -> void:
	for node: Node in _staged:
		if is_instance_valid(node):
			node.free()
	_staged.clear()
