class_name CargoSummary
extends RefCounted
## The C overlay's cargo grammar's single home (UI_SPEC section 20, the
## owner's playtest passes): the A14 slots law, the icon ink law, the
## formatters, the title words and the category/tab constants — the overlay
## delegates its derivation here and builds its own chip-bearing rows. The
## station surfaces read the hold through the shell's HOLD chip or the C step
## over the one moveable window (A22/A23/A24).

const MineralCatalogScript := preload("res://game/mineral_catalog.gd")
const ComponentCatalogScript := preload("res://game/component_catalog.gd")
const Catalog := preload("res://game/station_catalog.gd")

## A10: the refinery row grammar's own numbers (the overlay's, verbatim).
const ROW_ICON_IDLE_ALPHA := 0.72
const TINT_DIR := "res://assets/icons/tint/"
const DEDICATED_ICON_PREFIX := "icon_mineral_"
## The column band's lead gap: the row's own 12 px inner margin rides in front
## of the 40 px icon, so the captions seat exactly over the row's columns.
const ROUNDS_IN_PACK := "%d ROUNDS IN PACK"
const TIER_ORE_META := "TIER %d ORE"
const TIER_INGOT_META := "TIER %d INGOT"
const GRADE_COMPONENT_META := "GRADE %d COMPONENT"
const GRADE_FUEL_META := "GRADE %d FUEL CELL"
const POW_FAMILY: StringName = &"pow"
const TOKENS_TYPE: StringName = &"Tokens"

## A8's pinned copy - the single home; the overlay and the armory's block
## caption read it.
const TITLE_FORMAT := "CARGO — %d/%d UNITS"

## A9's five words + ALL, in A9's order; the section headers reuse the labels.
const CATEGORY_AMMO: StringName = &"ammo"
const CATEGORY_ORE: StringName = &"ore"
const CATEGORY_INGOTS: StringName = &"ingots"
const CATEGORY_COMPONENTS: StringName = &"components"
const CATEGORY_FUEL: StringName = &"fuel"
const TAB_ALL: StringName = &"all"
const CATEGORY_ORDER: Array[StringName] = [
	CATEGORY_AMMO, CATEGORY_ORE, CATEGORY_INGOTS, CATEGORY_COMPONENTS, CATEGORY_FUEL,
]
const CATEGORY_LABELS := {
	CATEGORY_AMMO: "AMMUNITION",
	CATEGORY_ORE: "ORE",
	CATEGORY_INGOTS: "INGOTS",
	CATEGORY_COMPONENTS: "COMPONENTS",
	CATEGORY_FUEL: "FUEL CELLS",
	TAB_ALL: "ALL",
}

## A11's strip: the five categories + ALL, in the strip's own order — the
## overlay's tab row and the A21 windows' read the same list.
const CARGO_TABS: Array[Dictionary] = [
	{&"id": CATEGORY_AMMO, &"label": "AMMUNITION"},
	{&"id": CATEGORY_ORE, &"label": "ORE"},
	{&"id": CATEGORY_INGOTS, &"label": "INGOTS"},
	{&"id": CATEGORY_COMPONENTS, &"label": "COMPONENTS"},
	{&"id": CATEGORY_FUEL, &"label": "FUEL CELLS"},
	{&"id": TAB_ALL, &"label": "ALL"},
]

## A21's window chrome — the overlay's own values (its scene plus its
## `_fit()`), verbatim: the PanelRaised panel, the 16 px margin, the
## content/title/tab/row separations, the tab chip's own 32 px height.


## A14's law, verbatim from the overlay's `_slots`: the one slot list, A9's
## five categories in order, the catalogue's own order within each.
## AMMUNITION carries only the families the hold lists (A14: hold units are
## the row's existence test); its amount is the hold stack, the pack rides the
## meta line.
static func slots(profile: Node, items: Dictionary) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	if profile != null and profile.has_method(&"ammo_of"):
		for family: StringName in Catalog.ammo_ids():
			var pack := Catalog.ammo_pack(family)
			if pack.is_empty():
				continue
			var item_id := Catalog.ammo_item_id(family)
			var rounds := int(profile.call(&"ammo_of", family))
			var units := held(items, item_id)
			## A14: the zero-hold ammo law - the hold's units are the row's own
			## existence test; the fitted pack's rounds never summon one.
			if units <= 0:
				continue
			list.append({
				&"id": item_id,
				&"category": CATEGORY_AMMO,
				&"name": String(pack.get(&"name", String(family))).to_upper(),
				&"meta": ROUNDS_IN_PACK % rounds,
				&"amount": units,
				&"dispose": units > 0,
				&"icon": String(pack.get(&"icon", &"")),
				&"tint": Color.WHITE,
			})
	for mineral_id: StringName in MineralCatalogScript.mineral_ids():
		var mineral: Dictionary = MineralCatalogScript.mineral(mineral_id)
		if mineral.is_empty():
			continue
		_add_mineral_slot(list, items, mineral_id, mineral, true)
		_add_mineral_slot(list, items, mineral_id, mineral, false)
	for entry: Dictionary in ComponentCatalogScript.COMPONENTS:
		var component_id := StringName(entry.get(&"id", &""))
		var family := StringName(entry.get(&"family", &""))
		if component_id == &"" or (family == POW_FAMILY) != false:
			continue
		var qty := held(items, component_id)
		if qty <= 0:
			continue
		list.append({
			&"id": component_id,
			&"category": CATEGORY_COMPONENTS,
			&"name": String(entry.get(&"name", String(component_id))).to_upper(),
			&"meta": GRADE_COMPONENT_META % int(entry.get(&"grade", 0)),
			&"amount": qty,
			&"dispose": true,
			&"icon": String(entry.get(&"icon", &"")),
			&"tint": grade_tint(int(entry.get(&"grade", 0))),
		})
	for entry: Dictionary in ComponentCatalogScript.COMPONENTS:
		var component_id := StringName(entry.get(&"id", &""))
		var family := StringName(entry.get(&"family", &""))
		if component_id == &"" or (family == POW_FAMILY) != true:
			continue
		var qty := held(items, component_id)
		if qty <= 0:
			continue
		list.append({
			&"id": component_id,
			&"category": CATEGORY_FUEL,
			&"name": String(entry.get(&"name", String(component_id))).to_upper(),
			&"meta": GRADE_FUEL_META % int(entry.get(&"grade", 0)),
			&"amount": qty,
			&"dispose": true,
			&"icon": String(entry.get(&"icon", &"")),
			&"tint": grade_tint(int(entry.get(&"grade", 0))),
		})
	return list


static func _add_mineral_slot(
		list: Array[Dictionary], items: Dictionary, mineral_id: StringName,
		mineral: Dictionary, ore: bool
) -> void:
	var item_id := MineralCatalogScript.ore_id(mineral_id) if ore \
			else MineralCatalogScript.ingot_id(mineral_id)
	var qty := held(items, item_id)
	if qty <= 0:
		return
	list.append({
		&"id": item_id,
		&"category": CATEGORY_ORE if ore else CATEGORY_INGOTS,
		&"name": ("%s ORE" if ore else "%s INGOT") % String(mineral.get(&"name", String(mineral_id))).to_upper(),
		&"meta": (TIER_ORE_META if ore else TIER_INGOT_META) % int(mineral.get(&"tier", 0)),
		&"amount": qty,
		&"dispose": true,
		&"icon": String(mineral.get(&"icon_ore" if ore else &"icon_ingot", &"")),
		&"tint": tier_tint(int(mineral.get(&"tier", 0))),
	})


static func tier_tint(tier: int) -> Color:
	if MineralCatalogScript.TIER_TINTS.has(tier):
		return MineralCatalogScript.TIER_TINTS[tier]
	return Color.WHITE


static func grade_tint(grade: int) -> Color:
	if ComponentCatalogScript.GRADE_TINTS.has(grade):
		return ComponentCatalogScript.GRADE_TINTS[grade]
	return Color.WHITE


## A8's `<n>`: the hold's own units summed.
static func held_units(items: Dictionary) -> int:
	var used := 0
	for quantity: Variant in items.values():
		used += int(quantity)
	return used


## A8's `<cap>`: the active hull's cargo column (08 section 3).
static func cargo_capacity(profile: Node) -> int:
	if profile == null or not profile.has_method(&"active_ship"):
		return 0
	var ship: Dictionary = Catalog.ship(StringName(profile.call(&"active_ship")))
	return int(ship.get(&"cargo", 0))


static func held(items: Dictionary, item_id: StringName) -> int:
	return int(items.get(item_id, 0))


## The stencil route: prefer `assets/icons/tint/` when a stencil of the same
## file exists, the catalogue path otherwise.
## The grouped-number formatter (the overlay's `_format_int`, moved here as
## the shared home - the AMOUNT cell and every summary read it).
static func format_int(value: int) -> String:
	var digits := str(absi(value))
	var grouped := ""
	var count := 0
	for index in range(digits.length() - 1, -1, -1):
		grouped = digits[index] + grouped
		count += 1
		if count % 3 == 0 and index > 0:
			grouped = " " + grouped
	return ("-" if value < 0 else "") + grouped


static func icon_source(icon_path: String) -> String:
	if icon_path.is_empty():
		return ""
	var stencil := TINT_DIR + icon_path.get_file()
	if stencil != icon_path and ResourceLoader.exists(stencil):
		return stencil
	return icon_path


## The refinery's ink law: `text_primary` on the dedicated `icon_mineral_*`
## stencils, the slot's tier/grade tint on other stenciled art, WHITE on raw
## catalogue art - the idle alpha always. The theme token reads off the host
## control (a static helper cannot reach a theme without one).
static func icon_ink(slot: Dictionary, host: Control) -> Color:
	var ink := Color.WHITE
	var source := icon_source(String(slot.get(&"icon", &"")))
	if source.begins_with(TINT_DIR):
		if source.get_file().begins_with(DEDICATED_ICON_PREFIX):
			if host != null and host.has_theme_color(&"text_primary", TOKENS_TYPE):
				ink = host.get_theme_color(&"text_primary", TOKENS_TYPE)
		else:
			var tint: Variant = slot.get(&"tint", Color.WHITE)
			if tint is Color:
				ink = tint
	ink.a = ROW_ICON_IDLE_ALPHA
	return ink
