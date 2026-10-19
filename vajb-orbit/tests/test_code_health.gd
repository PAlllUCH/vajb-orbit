extends McpTestSuite
## Suite code_health: the maintainability guardrails from CODE_AUDIT 2026-10-19.
## It pins the two structural invariants the refactor introduced and the one
## data-table integrity rule the audit found unmeasured:
##
##   1. every station panel extends the shared `StationPanel` base;
##   2. no station panel re-declares a helper the base owns (the armory's
##      `_token` override is the one documented exception);
##   3. every NPC archetype row carries its required keys, so a copy-paste row
##      that drops one cannot silently fall back to a default.
##
## These are maintainability rows, not gameplay rows; they read the shipped
## files and the shipped catalogue, and they never touch the live profile.

const NpcRegistryScript := preload("res://game/npc_registry.gd")

const PANEL_DIR := "res://ui/station/"
const PANELS: Array[String] = [
	"armory_panel",
	"auction_panel",
	"contracts_panel",
	"exchange_panel",
	"fitting_panel",
	"insurance_panel",
	"launch_panel",
	"overview_panel",
	"refinery_panel",
	"repairs_panel",
	"shipyard_panel",
	"vaults_panel",
]
const BASE_EXTENDS := 'extends "res://ui/station/station_panel.gd"'

## The helpers `StationPanel` owns. `_token` is checked separately because the
## armory's style object answers before the theme, so it keeps its override.
const SHARED_HELPERS: Array[String] = [
	"_format_int",
	"_make_tween",
	"_exit_tree",
	"_profile",
	"_pulse",
	"_clear_list",
	"_base_id",
	"_active_hull",
	"_vitals",
	"_plate_texture",
	"_strip_chip_box",
	"_slot_glyph",
]

const REQUIRED_NPC_KEYS: Array[StringName] = [
	NpcRegistryScript.KEY_ID,
	NpcRegistryScript.KEY_HULL_ID,
	NpcRegistryScript.KEY_SPRITE_BASE,
	NpcRegistryScript.KEY_LIVERY_SOURCE,
	NpcRegistryScript.KEY_TIER,
	NpcRegistryScript.KEY_LOOT_KIND,
	NpcRegistryScript.KEY_AGGRO_RADIUS,
	NpcRegistryScript.KEY_SCAN_RADIUS,
	NpcRegistryScript.KEY_FLEE_HULL,
	NpcRegistryScript.KEY_FLEE_TIER,
	NpcRegistryScript.KEY_SCAN_TIER,
	NpcRegistryScript.KEY_ATTACK_TIER,
	NpcRegistryScript.KEY_HOSTILITY,
	NpcRegistryScript.KEY_STATIC,
	NpcRegistryScript.KEY_BLIP_KIND,
	NpcRegistryScript.KEY_HEAT_ON_KILL,
	NpcRegistryScript.KEY_STANDING_ON_KILL,
	NpcRegistryScript.KEY_SPAWN,
	NpcRegistryScript.KEY_SEAM,
	NpcRegistryScript.KEY_DENSITY,
	NpcRegistryScript.KEY_GROUP_KIND,
	NpcRegistryScript.KEY_MEMBERS,
]


func suite_name() -> String:
	return "code_health"


func test_every_station_panel_extends_the_shared_base() -> void:
	for name in PANELS:
		var path := PANEL_DIR + name + ".gd"
		var text := FileAccess.get_file_as_string(path)
		assert_false(text.is_empty(), "%s is readable" % path)
		assert_true(
			text.begins_with(BASE_EXTENDS),
			"%s extends the StationPanel base" % path
		)


func test_no_station_panel_redeclares_a_shared_helper() -> void:
	for name in PANELS:
		var text := FileAccess.get_file_as_string(PANEL_DIR + name + ".gd")
		for helper in SHARED_HELPERS:
			assert_false(
				text.contains("func %s(" % helper),
				"%s must not re-declare %s (StationPanel owns it)" % [name, helper]
			)
		if name != "armory_panel":
			assert_false(
				text.contains("func _token("),
				"%s must use the base _token (the armory is the one override)" % name
			)


func test_every_npc_archetype_answers_its_required_keys() -> void:
	var ids: Array[StringName] = NpcRegistryScript.ids()
	ids.append(NpcRegistryScript.ARCHETYPE_BONEYARD)
	ids.append(NpcRegistryScript.ARCHETYPE_PYRE)
	assert_eq(ids.size(), 11, "nine population rows plus the two arena bosses")
	for id in ids:
		var row := NpcRegistryScript.archetype(id)
		assert_false(row.is_empty(), "archetype %s resolves" % String(id))
		for key in REQUIRED_NPC_KEYS:
			assert_true(
				row.has(key),
				"archetype %s carries %s" % [String(id), String(key)]
			)
