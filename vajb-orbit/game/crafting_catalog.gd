class_name CraftingCatalog
extends RefCounted
## The crafting recipes of `docs/gameplay/07_crafting.md` section 6 (C1-C10), as data
## plus the one transaction and the scrap derivation -- the shipyard's own file shape
## (`game/shipyard.gd`: the recipe table is data, the queue is its static API).
## Contract: section 6.2's recipe table (C3, every value verbatim), C4's fee law
## (the four fees land at 2 500 / 3 000 / 2 800 / 4 000), C5's material baselines
## (the panel displays inputs as counts, never as CR), C6's outputs (effects in 09
## section 3's own language), C8's reverse craft (50 % of the recipe materials,
## round down -- 10 section 3.3's scrap law verbatim) and C10's commit law (the
## all-or-nothing transaction the CRAFT chip's confirmed answer runs).
##
## Prices are **never** hand-picked here: the fees are section 6.2's own pinned
## cells (derived in the doc, recorded here), and every material figure re-derives
## from the live 02 ore values (`MineralCatalog`, the 2026-10-08 block) and 03
## component values (`ComponentCatalog`) -- `materials_value` is the one reader of
## those tables, and `scrap_value` reads it.
##
## The four output module ids are the implementation wave's own mint (C6 leaves the
## 09 section 3.x rows to the module-catalogue wave): `p_core_mk3` continues the
## power ladder's `p_core_mk2` naming with `p_core`'s own +4 output (C6's flag --
## the crafted reactor's value is paying in goods, not a stat above stock);
## `s_lattice`, `c_rail_refit` and `c_deep_scanner` follow the slot-family letter
## idiom. Reversal: any other id shape.
##
## Pure data + API: no nodes, no scene tree. The recipe bag the commit fills lives
## in `PlayerProfile`'s module inventory through the shipped `add_module` seam --
## the one write this file makes, the same write `buy_module` makes.

const MineralData := preload("res://game/mineral_catalog.gd")
const ComponentData := preload("res://game/component_catalog.gd")
const Log := preload("res://game/economy_log.gd")

## C2's table, section 6.2 verbatim: one row per recipe, `inputs` id -> count in
## the doc's own order, the fee C4's pinned cell, the output its module id + the
## C6 effect text.
const RECIPES: Array[Dictionary] = [
	{
		&"id": &"p_core_mk3",
		&"name": "Reactor Mk3",
		&"inputs": {&"comp_mech_2": 2, &"comp_pow_2": 1, &"ingot_cobalt": 6},
		&"fee": 2500,
		&"output": {&"module": &"p_core_mk3", &"effect": "+4 power output"},
		&"description": "A reactor core rebuilt from station salvage. Its output matches the stock best; the price was paid in goods, not above it.",
	},
	{
		&"id": &"s_lattice",
		&"name": "Shield Lattice",
		&"inputs": {&"comp_ore_2": 1, &"ingot_cerulite": 3, &"comp_elec_2": 2},
		&"fee": 3000,
		&"output": {&"module": &"s_lattice", &"effect": "+500 pool · regen 10/s"},
		&"description": "Cerulite grown into an emitter lattice: a deeper pool than the yard's own shields, and it refills faster.",
	},
	{
		&"id": &"c_rail_refit",
		&"name": "Rail Refit",
		&"inputs": {&"comp_weap_2": 2, &"ingot_tungsten": 4},
		&"fee": 2800,
		&"output": {&"module": &"c_rail_refit", &"effect": "kinetic weapons +25 % damage"},
		&"description": "A refit kit that re-cuts every kinetic barrel to rail tolerance. One per ship: the mounting is unique.",
	},
	{
		&"id": &"c_deep_scanner",
		&"name": "Deep Scanner Array",
		&"inputs": {&"comp_elec_3": 1, &"ingot_voidglass": 5},
		&"fee": 4000,
		&"output": {&"module": &"c_deep_scanner", &"effect": "+45 % scanner range"},
		&"description": "Long-optic scanner array. Reads the belt a further forty-five percent out.",
	},
]

## C4's floor (07 section 5's K7 sink law) -- the four fees all clear it; recorded
## so the law is code, not prose.
const MIN_FEE := 2000
## C8 / 10 section 3.3: the scrap share of the recipe materials, round down.
const SCRAP_SHARE := 0.5

const REASON_UNKNOWN_RECIPE: StringName = &"unknown_recipe"
const REASON_INSUFFICIENT_MATERIALS: StringName = &"insufficient_materials"
const REASON_INSUFFICIENT_CREDITS: StringName = &"insufficient_credits"

## The economy-log event tag (01 section 7's one line per transaction).
const EVENT := "CRAFT"


## The whole table, in the doc's own order.
static func recipes() -> Array[Dictionary]:
	return RECIPES


## One recipe by id, `{}` when the table does not carry it.
static func recipe(recipe_id: StringName) -> Dictionary:
	for row: Dictionary in RECIPES:
		if StringName(row.get(&"id", &"")) == recipe_id:
			return row
	return {}


## C5's derivation reader (the shipyard's own `materials_value` shape): the recipe's
## material bill priced at the baselines -- 03 section 3's component values, 02's
## 2026-10-08 ingot values. An id neither catalogue carries prices 0 (never invented).
static func materials_value(inputs: Dictionary) -> int:
	var total := 0
	for input_id: StringName in inputs:
		var count := int(inputs[input_id])
		total += count * unit_value(input_id)
	return total


## C8's reverse craft: 50 % of the recipe materials, round down (10 section 3.3's
## scrap law verbatim), priced at the same baselines `materials_value` reads.
static func scrap_value(recipe: Dictionary) -> int:
	@warning_ignore("integer_division")
	return materials_value(recipe.get(&"inputs", {})) / 2


## The first input the hold cannot cover, in the recipe's own order:
## `{id, count}` with `count` the shortfall, `{}` when every input is held.
static func first_missing(profile, recipe: Dictionary) -> Dictionary:
	var inputs: Dictionary = recipe.get(&"inputs", {})
	for input_id: StringName in inputs:
		var count := int(inputs[input_id])
		var held := int(profile.cargo_qty(input_id)) if profile != null else 0
		if held < count:
			return {&"id": input_id, &"count": count - held}
	return {}


## C10's commit (the confirmed CRAFT press's transaction): consumes every `inputs`
## entry from the hold (`cargo_qty`), pays the fee from credits, grants the output
## module through the shipped `add_module` seam. All-or-nothing (01 section 7):
## verify everything first, then spend, then take, then grant; a mid-take failure
## restores what earlier steps took and reports the refusal. Refusals write nothing
## and log nothing; the one success writes one economy-log line.
## Returns `{ok, recipe_id, module, fee}` or
## `{ok, reason, recipe_id, missing_id?, missing_count?, fee?}`.
static func craft(profile, recipe_id: StringName) -> Dictionary:
	var recipe := recipe(recipe_id)
	if recipe.is_empty() or profile == null:
		return _refusal(REASON_UNKNOWN_RECIPE, recipe_id, 0, &"", 0)
	var fee := int(recipe.get(&"fee", 0))
	var missing := first_missing(profile, recipe)
	if not missing.is_empty():
		return _refusal(
			REASON_INSUFFICIENT_MATERIALS, recipe_id, fee,
			StringName(missing[&"id"]), int(missing[&"count"])
		)
	if int(profile.credits()) < fee or not bool(profile.spend(fee)):
		return _refusal(REASON_INSUFFICIENT_CREDITS, recipe_id, fee, &"", 0)

	var inputs: Dictionary = recipe.get(&"inputs", {})
	var taken: Array[Dictionary] = []
	for input_id: StringName in inputs:
		var count := int(inputs[input_id])
		if not bool(profile.remove_cargo(input_id, count)):
			for row: Dictionary in taken:
				profile.add_cargo(row[&"id"], row[&"count"])
			profile.add_credits(fee)
			return _refusal(REASON_INSUFFICIENT_MATERIALS, recipe_id, fee, input_id, count)
		taken.append({&"id": input_id, &"count": count})

	var output: Dictionary = recipe.get(&"output", {})
	var module_id: StringName = StringName(output.get(&"module", &""))
	profile.add_module(module_id, 1)
	Log.append(EVENT, module_id, 1, -fee, int(profile.credits()))
	return {&"ok": true, &"recipe_id": recipe_id, &"module": module_id, &"fee": fee}


static func _refusal(
	reason: StringName, recipe_id: StringName, fee: int, missing_id: StringName, missing: int
) -> Dictionary:
	var out := {
		&"ok": false,
		&"reason": reason,
		&"recipe_id": recipe_id,
		&"fee": fee,
	}
	if missing_id != &"":
		out[&"missing_id"] = missing_id
		out[&"missing_count"] = missing
	return out


## One material's baseline value: an ingot reads its mineral's `ingot_value`, a
## component its own `value`, anything else 0 (never invented).
static func unit_value(item_id: StringName) -> int:
	if MineralData.is_ingot(item_id):
		return int(MineralData.entry_for_item(item_id).get(&"ingot_value", 0))
	return int(ComponentData.component(item_id).get(&"value", 0))
