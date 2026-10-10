extends SceneTree
## S27-R2 probe 1 (data lane, no scene): the fixer's two MEDs against live code,
## every acceptance re-measured on the final tree. Bounded; self-quits.

const ModuleData := preload("res://game/module_catalog.gd")
const LootTables := preload("res://game/loot_tables.gd")
const Shipyard := preload("res://game/shipyard.gd")
const Auction := preload("res://game/auction.gd")
const ContractData := preload("res://game/contract_registry.gd")
const Affixes := preload("res://game/affixes.gd")
const Components := preload("res://game/component_catalog.gd")
const Minerals := preload("res://game/mineral_catalog.gd")
const ShipFit := preload("res://game/ship_fit.gd")
const Profile := preload("res://autoload/player_profile.gd")

## The doc's own hull list prices, 10 §3.1's "vs list" column
## (docs/gameplay/10_ship_acquisition.md §3.1).
const DOC_LIST := {
	&"ship_fighter": 9000, &"ship_vanguard": 18000, &"ship_miner": 16000,
	&"ship_trader": 21000, &"ship_corvette": 27000, &"ship_freighter": 24000,
	&"ship_gunship": 36000, &"ship_patrol": 54000, &"ship_destroyer": 72000,
}

var _fail := 0


func _init() -> void:
	_p1_rare_property_law()
	_p1b_affix_law_all_bases()
	_p2_pyre_seam_arithmetic()
	_p3_variant_prices_and_pools()
	_p4_loot_ev()
	_p5_shipyard_recipes()
	_p6_queue_and_scrap()
	_p7_tier4_clamp()
	print("PROBE_R2_DATA verdict failed=%d" % _fail)
	quit(1 if _fail > 0 else 0)


func _fail_line(text: String) -> void:
	_fail += 1
	print("PROBE_R2_DATA FAIL %s" % text)


## --- F1: a Rare never pairs one property twice, count still grows id/pool-wise ---
func _p1_rare_property_law() -> void:
	var weapon_bases: Array[StringName] = []
	var all_bases: Array[StringName] = []
	for id: StringName in ModuleData.MODULES:
		all_bases.append(id)
		if StringName(ModuleData.fit_slot_of(id)) == &"weapons":
			weapon_bases.append(id)
	for base: StringName in ModuleData.variant_ids():
		all_bases.append(base)
		var slot := StringName(ModuleData.fit_slot_of(str(ModuleData.VARIANTS[base]["base"])))
		if slot == &"weapons":
			weapon_bases.append(base)
	seed(20261010)
	var trials_per := 3000
	var dup_pairs := 0
	var wrong_count := 0
	var seen_pairs := {}
	for base: StringName in weapon_bases:
		for i in trials_per:
			var ps: Array = ModuleData.roll_prefixes(base, &"rare")
			if ps.size() != 2:
				## wanted 2; a weapon pool's distinct stats are 4, so 2 is the law
				wrong_count += 1
				continue
			var stats: Array[String] = []
			for entry: Dictionary in ps:
				stats.append(str(ModuleData.PREFIXES[StringName(str(entry["id"]))]["stat"]))
			if stats[0] == stats[1]:
				dup_pairs += 1
				if dup_pairs == 1:
					_fail_line("F1 dup property %s on %s" % [stats[0], base])
			seen_pairs[stats[0] + "+" + stats[1]] = true
	if wrong_count > 0:
		_fail_line("F1 weapon pair count wrong %d times" % wrong_count)
	print("PROBE_F1 weapons=%d bases=%d dup_pairs=%d wrong_count=%d distinct_pairs=%d"
		% [weapon_bases.size(), trials_per, dup_pairs, wrong_count, seen_pairs.size()])
	## Single-row families (engines/power/boosters/utility): a Rare takes the one row.
	var trials := 400
	var single_families := 0
	var broken_single := 0
	seed(424242)
	for base: StringName in all_bases:
		var pool: Array[String] = ModuleData.prefix_pool(base)
		var distinct := _distinct_stats(pool)
		if distinct != 1:
			continue
		single_families += 1
		for i in trials:
			var ps: Array = ModuleData.roll_prefixes(base, &"rare")
			if ps.size() != 1:
				broken_single += 1
				if broken_single == 1:
					_fail_line("F1 single-prop family %s yielded %d" % [base, ps.size()])
	if broken_single == 0:
		print("PROBE_F1 single-prop families=%d trials=%d ok" % [single_families, trials])
	else:
		_fail_line("F1 single-prop family yields wrong count x%d" % broken_single)
	## Magic count never moved by the dedupe (1 pick, 1 row -> no walk).
	seed(909090)
	for i in trials:
		var ps: Array = ModuleData.roll_prefixes(weapon_bases[i % weapon_bases.size()], &"magic")
		var ps2: Array = ModuleData.roll_suffixes(weapon_bases[i % weapon_bases.size()], &"magic")
		if ps.size() != 1 or ps2.size() != 1:
			_fail_line("F1 magic yields != 1/1")
			break

func _distinct_stats(pool: Array[String]) -> int:
	var set := {}
	for id: String in pool:
		set[str(ModuleData.PREFIXES[StringName(id)]["stat"])] = true
	return set.size()

## --- A1: the whole affix contract over every base x rarity, 5k seeded ---
func _p1b_affix_law_all_bases() -> void:
	var bases: Array[StringName] = [&"s_light", &"h_composite", &"w_laser", &"c_target",
		&"u_crates", &"b_thruster", &"p_microoutput", &"e_thruster"]
	for id: StringName in ModuleData.variant_ids():
		bases.append(id)
	seed(707070)
	var n := 0
	var bad_family := 0
	var bad_band := 0
	var bad_count := 0
	var bad_suffix := 0
	while n < 5000:
		var base: StringName = bases[n % bases.size()]
		var rarity: StringName = [&"common", &"magic", &"rare"][n % 3]
		n += 1
		var rolled := ModuleData.roll_affixes(base, rarity)
		var wanted := ModuleData.affix_count(rarity)
		var expected := mini(wanted, _distinct_stats(ModuleData.prefix_pool(base)))
		if rolled["prefixes"].size() != expected or rolled["suffixes"].size() != wanted:
			bad_count += 1
			if bad_count == 1:
				_fail_line("A1 count got=%d/%d expected=%d on %s/%s"
					% [rolled["prefixes"].size(), rolled["suffixes"].size(), expected, base, rarity])
			continue
		var slot := StringName(ModuleData.fit_slot_of(base))
		for entry: Dictionary in rolled["prefixes"]:
			var p: Dictionary = ModuleData.PREFIXES[StringName(str(entry["id"]))]
			if StringName(p.get(&"slot", &"")) != slot:
				bad_family += 1
				if bad_family == 1:
					_fail_line("A1 family %s on %s" % [entry["id"], base])
			var band: Array = p.get(&"band", [])
			if band.is_empty():
				continue
			var value := float(entry["value"])
			if value < minf(band[0], band[2]) or value > maxf(band[0], band[2]):
				bad_band += 1
				if bad_band == 1:
					_fail_line("A1 band %s %f on %s" % [entry["id"], value, base])
		var flags: Array[StringName] = []
		for s: String in rolled["suffixes"]:
			flags.append(StringName(s))
		var pool: Array[String] = ModuleData.suffix_pool(
			String(module_exclusive_faction(base)))
		for s: String in rolled["suffixes"]:
			if not pool.has(s):
				bad_suffix += 1
				if bad_suffix == 1:
					_fail_line("A1 suffix %s out of pool on %s" % [s, base])
	print("PROBE_A1 rolls=%d bad_family=%d bad_band=%d bad_count=%d bad_suffix=%d"
		% [n, bad_family, bad_band, bad_count, bad_suffix])

func module_exclusive_faction(base: StringName) -> StringName:
	return ModuleData.exclusive_faction(base)

## --- F2's seam arithmetic: the threshold table itself ---
func _p2_pyre_seam_arithmetic() -> void:
	var summary := {Affixes.KEY_SUFFIXES: [&"pyre"]}
	for shard in [0.0, 0.12, 0.24, Affixes.PYRE_HULL_THRESHOLD - 0.0001]:
		if Affixes.pyre_ring_damage(summary, shard) != Affixes.PYRE_RING_DAMAGE:
			_fail_line("F2 seam shard=%f failed" % shard)
	for shard in [Affixes.PYRE_HULL_THRESHOLD, 0.5, 1.0]:
		if Affixes.pyre_ring_damage(summary, shard) != 0.0:
			_fail_line("F2 seam shard=%f wrongly fired" % shard)
	if Affixes.pyre_ring_damage({}, 0.10) != 0.0:
		_fail_line("F2 no-flag fired")
	print("PROBE_F2_SEAM ok gate=pyre_ring_damage(threshold=%f,damage=%f)"
		% [Affixes.PYRE_HULL_THRESHOLD, Affixes.PYRE_RING_DAMAGE])

## --- A3: the 15 variant rows re-derived from the live ladder ---
func _p3_variant_prices_and_pools() -> void:
	var sc: Array[int] = ContractData.SC
	var bad_price := 0
	var bad_headline := 0
	for id: StringName in ModuleData.variant_ids():
		var row := ModuleData.module(id)
		var base := ModuleData.module(StringName(str(row.get(&"base", &""))))
		var tier := int(row.get(&"tier", 0))
		var btier := int(base.get(&"tier", 0))
		var derived := roundi(float(int(base.get(&"cost", 0)))
			* float(sc[tier - 1]) / float(sc[btier - 1]))
		var banded := clampi(derived, sc[tier - 1], 2 * sc[tier - 1])
		if int(row.get(&"cost", 0)) != banded:
			bad_price += 1
			if bad_price == 1:
				_fail_line("A3 price %s stored=%d derived=%d banded=%d"
					% [id, int(row.get(&"cost", 0)), derived, banded])
		var headline := _headline_stat(StringName(ModuleData.fit_slot_of(id)))
		if headline == &"":
			continue
		var base_effect := float((base.get(&"effects", {}) as Dictionary).get(headline, 0.0))
		var var_effect := float((row.get(&"effects", {}) as Dictionary).get(headline, 0.0))
		if not is_equal_approx(var_effect, base_effect * 1.15):
			bad_headline += 1
			if bad_headline == 1:
				_fail_line("A3 headline %s %f != %f" % [id, var_effect, base_effect])
	## sale_pool one tier up; tier_pool(4) carries only variants.
	for tier: int in [2, 3, 4]:
		for id in ModuleData.variant_pool(tier):
			if not Auction.sale_pool(tier).has(id):
				_fail_line("A3 sale_pool lacks %s@t%d" % [id, tier])
	for id in Auction.tier_pool(4):
		if String(id).ends_with("_mk2") == false:
			_fail_line("A3 tier_pool(4) carries non-variant %s" % id)
	print("PROBE_A3 variants=%d bad_price=%d bad_headline=%d sale/tier-pool ok"
		% [ModuleData.variant_ids().size(), bad_price, bad_headline])

func _headline_stat(slot: StringName) -> StringName:
	match slot:
		&"shields": return &"shield_add"
		&"armour": return &"hull_add"
		&"computers": return &"damage_add"
		&"boosters": return &"boost_speed_mult"
		&"utility": return &"cargo_add"
		&"power": return &"power_add"
	return &""

## --- A4: the four tables over 20k seeded rolls ---
func _p4_loot_ev() -> void:
	for kind: StringName in [&"interceptor", &"turret", &"sibelon", &"boss"]:
		var credits := 0.0
		var empty := 0
		for i in 20000:
			var payload := LootTables.roll_band(kind, 90210 + i)
			if payload.is_empty():
				empty += 1
			for e: Dictionary in payload:
				if bool(e.get(LootTables.KEY_CACHE, false)):
					credits += float(e[LootTables.KEY_AMOUNT])
				else:
					var item := StringName(str(e[LootTables.KEY_ITEM]))
					var value := float(e[LootTables.KEY_AMOUNT]) * oitem_value(item)
					credits += value
		print("PROBE_A4 %s ev=%.1f empty=%.2f%%" % [kind, credits / 20000.0, 100.0 * empty / 20000.0])

func oitem_value(item: StringName) -> float:
	var comp := Components.component(item)
	if not comp.is_empty():
		return float(comp.get(&"value", 0))
	if Minerals.is_ore(item):
		return float(Minerals.entry_for_item(item).get(&"ore_value", 0))
	return 0.0

## --- A5: the recipes re-derived from the live catalogues ---
func _p5_shipyard_recipes() -> void:
	## Hulls: materials bill at live values, labour per §3.1, total % of the doc list.
	var low := 200.0
	var hi := 0.0
	for hull: StringName in Shipyard.HULL_RECIPES:
		var recipe := Shipyard.hull_recipe(hull)
		var materials := int(Shipyard.materials_value(recipe.get(Shipyard.KEY_MATERIALS, {})))
		var labour := int(recipe.get(Shipyard.KEY_LABOUR, 0))
		var total := materials + labour
		var list := int(DOC_LIST.get(hull, 0))
		var pct := 100.0 * float(total) / float(list) if list > 0 else 0.0
		var mpct := 100.0 * float(materials) / float(list) if list > 0 else 0.0
		print("PROBE_A5 hull %s mats=%d labour=%d total=%d list=%d total%%=%.1f mats%%=%.1f"
			% [hull, materials, labour, total, list, pct, mpct])
		low = minf(low, pct)
		hi = maxf(hi, pct)
	print("PROBE_A5 hull band total %.1f%%-%.1f%% of doc list" % [low, hi])
	## Modules: the shape rule re-derived mechanically for every buildable id.
	var shape_bad := 0
	for id: StringName in Shipyard.buildable_modules():
		var row := ModuleData.module(id)
		var tier := int(row.get(&"tier", 1))
		var expected: Dictionary = {}
		var comp := Shipyard.component_id(id)
		if comp != &"":
			expected[comp] = 2
		var ore := Shipyard.ore_id(tier)
		if ore != &"":
			expected[ore] = 12
		var got := Shipyard.module_recipe(id)
		var gm: Dictionary = got.get(Shipyard.KEY_MATERIALS, {})
		var gl := int(got.get(Shipyard.KEY_LABOUR, -1))
		var el := roundi(float(int(row.get(&"cost", 0))) * 0.20)
		if not _dict_eq(gm, expected) or gl != el:
			shape_bad += 1
			if shape_bad == 1:
				_fail_line("A5 shape %s got=%s expected=%s labour=%d/%d"
					% [id, gm, expected, gl, el])
	print("PROBE_A5 module_shape_bad=%d over=%d ids" % [shape_bad, Shipyard.buildable_modules().size()])
	print("PROBE_A6 variants at tier 4 priced %d-%d (L2 band %d-%d)"
		% [_tier4_cost_low(), _tier4_cost_hi(), 1 * ContractData.SC[3], 2 * ContractData.SC[3]])

func _tier4_cost_low() -> int:
	var low := 999999
	for id: StringName in Auction.tier_pool(4):
		low = mini(low, int(ModuleData.module(id).get(&"cost", 0)))
	return low

func _tier4_cost_hi() -> int:
	var hi := 0
	for id: StringName in Auction.tier_pool(4):
		hi = maxi(hi, int(ModuleData.module(id).get(&"cost", 0)))
	return hi

func _dict_eq(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size():
		return false
	for key: Variant in a:
		var av := float(a[key])
		var bv := float(b.get(key, -999999.0))
		if absf(av - bv) > 0.001:
			return false
	return true

## --- A5's queue + scrap semantics over a scratch profile ---
func _p6_queue_and_scrap() -> void:
	var profile := Profile.new()
	profile.save_path = "user://probe_r2_s27.cfg"
	profile.reset_to_defaults()
	var stock := {&"mineral_iron": 100, &"mineral_chromium": 100, &"comp_scrap_1": 10}
	for key: StringName in stock:
		profile.add_cargo(key, int(stock[key]))
	var recipe := Shipyard.hull_recipe(&"ship_fighter")
	profile.add_credits(200000)
	var ok := Shipyard.queue_job(profile, Shipyard.KIND_HULL, &"ship_fighter")
	if not ok:
		_fail_line("A5 queue refused with stocked hold")
		return
	## every material left the hold in the recipe's quantity, the labour left the credits
	for key: StringName in stock:
		if int(profile.cargo_qty(key)) != int(stock[key]) - int(recipe[Shipyard.KEY_MATERIALS].get(key, 0)):
			_fail_line("A5 queue did not commit %s (hold=%d)" % [key, int(profile.cargo_qty(key))])
	var second := Shipyard.queue_job(profile, Shipyard.KIND_MODULE, &"s_light")
	if second:
		_fail_line("A5 second queue allowed (one at a time)")
	if Shipyard.is_ready(profile):
		_fail_line("A5 ready before a flight")
	Shipyard.note_flight(profile)
	if not Shipyard.is_ready(profile):
		_fail_line("A5 not ready after one flight")
	if not Shipyard.collect(profile):
		_fail_line("A5 collect refused")
	if not profile.owned_ships().has(&"ship_fighter"):
		_fail_line("A5 hull not delivered")
	var jobs := profile.shipyard_job()
	if not jobs.is_empty():
		_fail_line("A5 job survived collect")
	## no refunds after completion
	var crate := profile.cargo_qty(&"mineral_iron")
	var cancelled := Shipyard.cancel_job(profile)
	if cancelled:
		_fail_line("A5 cancel allowed after completion")
	if int(profile.cargo_qty(&"mineral_iron")) != crate:
		_fail_line("A5 completion refund leaked")
	## scrap: 50 % round down over a fresh job
	var recipe2 := Shipyard.hull_recipe(&"ship_fighter")
	var scrap := Shipyard.scrap_materials(recipe2[Shipyard.KEY_MATERIALS])
	for key: StringName in recipe2[Shipyard.KEY_MATERIALS]:
		var expect := int(floor(float(int(recipe2[Shipyard.KEY_MATERIALS][key])) * 0.5))
		if int(scrap.get(key, 0)) != expect:
			_fail_line("A5 scrap yield %s %d != %d" % [key, int(scrap.get(key, 0)), expect])
	print("PROBE_A5 queue/scrap semantics ok")

## --- A6's clamp: a tier-4 sector reserves tier 4 ---
func _p7_tier4_clamp() -> void:
	var station := {&"sector": 6}
	var tier := Auction._reserved_tier(station)
	if tier < 4:
		_fail_line("A6 reserved tier %d < 4 (sector_tier=%d)" % [tier, tier])
	print("PROBE_A6 _reserved_tier()=%d (TIER_ORDER[0]=%d max=4)"
		% [tier, Auction.TIER_ORDER[0]])
