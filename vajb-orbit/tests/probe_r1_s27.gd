extends SceneTree
## S27-R1 probe v3 - rare-weapon property check, loot EV, shipyard totals.
const ModuleData := preload("res://game/module_catalog.gd")
const LootTables := preload("res://game/loot_tables.gd")
const Shipyard := preload("res://game/shipyard.gd")

func _init() -> void:
	_rare_weapons()
	_loot_ev()
	_shield_totals()
	_module_recipe_totals()
	quit(0)

static func _stat_of(id: String) -> String:
	return str(ModuleData.PREFIXES[StringName(id)]["stat"])

func _rare_weapons() -> void:
	var dupes := 0
	var trials := 2000
	var example := ""
	seed(777)
	for i in trials:
		var affixes := ModuleData.roll_affixes(&"w_laser", "rare")
		var ps: Array = affixes["prefixes"]
		if ps.size() != 2:
			continue
		if _stat_of(ps[0]["id"]) == _stat_of(ps[1]["id"]):
			dupes += 1
			if example == "":
				example = "%s+%s" % [ps[0]["id"], ps[1]["id"]]
	print("PROBE_RARE_W dup_property=%d/%d example=%s" % [dupes, trials, example])

func _loot_ev() -> void:
	for kind: StringName in [&"interceptor", &"turret", &"sibelon", &"boss"]:
		var credits := 0.0
		var units := 0.0
		var empty := 0
		for i in 20000:
			var payload := LootTables.roll_band(kind, 4242 + i)
			credits += _payload_credits(payload)
			units += float(payload.size())
			if payload.is_empty():
				empty += 1
		print("PROBE_EV %s credits=%.1f entries/kill=%.2f empty=%.2f%%" % [kind, credits / 20000.0, units / 20000.0, 100.0 * empty / 20000.0])

func _payload_credits(payload: Array) -> float:
	var total := 0.0
	const Components := preload("res://game/component_catalog.gd")
	for e: Dictionary in payload:
		if bool(e.get("is_credit_cache", false)):
			total += float(e["amount"])
		else:
			total += float(Components.component(StringName(str(e["item_id"]))).get("value", 0)) * float(e["amount"])
	return total

func _shield_totals() -> void:
	for hull: StringName in Shipyard.HULL_RECIPES:
		var r := Shipyard.hull_recipe(hull)
		var total := Shipyard.recipe_total(r)
		print("PROBE_HULL %s materials=%d labour=%d total=%d" % [hull, Shipyard.materials_value(r["materials"]), int(r["labour"]), total])

func _module_recipe_totals() -> void:
	print("PROBE_MOD c_target %s" % str(Shipyard.module_recipe(&"c_target")))
	var r := Shipyard.module_recipe(&"s_light")
	print("PROBE_MOD s_light total=%d (materials=%d labour=%d)" % [Shipyard.recipe_total(r), Shipyard.materials_value(r["materials"]), int(r["labour"])])
	var r1 := Shipyard.module_recipe(&"s_ion_mk2")
	print("PROBE_MOD s_ion_mk2 total=%d" % Shipyard.recipe_total(r1))
