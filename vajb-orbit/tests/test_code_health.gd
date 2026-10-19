extends McpTestSuite
## Suite code_health: the maintainability guardrails from CODE_AUDIT 2026-10-19.
## It pins the structural invariants the refactor introduced and the one
## data-table integrity rule the audit found unmeasured:
##
##   1. every station panel extends the shared `StationPanel` base (the armory does so
##      through `armory_panel_base.gd`, its declaration half);
##   2. no station panel re-declares a helper the base owns (the armory's
##      `_token` override is the one documented exception);
##   3. every NPC archetype row carries its required keys, so a copy-paste row
##      that drops one cannot silently fall back to a default;
##   4. every `_token` outside the kit delegates to `UiTokens.colour`;
##   5. the HUD's rack ids are `PlayerState.WEAPONS` plus its two extras, and
##      every autoload `_service` delegates to `ServiceLookup.find`.
##
## These are maintainability rows, not gameplay rows; they read the shipped
## files and the shipped catalogue, and they never touch the live profile.

const NpcRegistryScript := preload("res://game/npc_registry.gd")
const HudScript := preload("res://ui/hud/hud.gd")
const PlayerStateScript := preload("res://game/player_state.gd")

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
## The armory's P2 split: the scene attaches `armory_panel.gd`, whose declaration half
## (`armory_panel_base.gd`) is the direct StationPanel child.
const ARMORY_BASE := "armory_panel_base.gd"
const ARMORY_EXTENDS := 'extends "res://ui/station/armory_panel_base.gd"'

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
		var expected := ARMORY_EXTENDS if name == "armory_panel" else BASE_EXTENDS
		assert_true(
			text.begins_with(expected),
			"%s extends the StationPanel base" % path
		)
		if name == "armory_panel":
			var base := FileAccess.get_file_as_string(PANEL_DIR + ARMORY_BASE)
			assert_true(
				base.begins_with(BASE_EXTENDS),
				"%s extends the StationPanel base" % (PANEL_DIR + ARMORY_BASE)
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


func test_every_token_reader_delegates_to_the_kit() -> void:
	var offenders: Array[String] = []
	for path in _gd_files("res://ui/"):
		var text := FileAccess.get_file_as_string(path)
		if text.contains("func _token(") and not text.contains("UiTokensScript.colour(self, token"):
			offenders.append(path)
	assert_eq(
		offenders,
		[] as Array[String],
		"every _token outside ui/components/ui_tokens.gd delegates to it"
	)


func test_the_hud_weapon_ids_read_the_one_family_source() -> void:
	var expected: Array[StringName] = PlayerStateScript.WEAPONS.duplicate()
	expected.append_array(HudScript.WEAPON_ID_EXTRAS)
	assert_eq(PlayerStateScript.WEAPONS.size(), 5, "the five v1 families")
	assert_eq(
		HudScript.WEAPON_IDS,
		expected,
		"the rack ids are the default five plus the HUD's railgun and mining entries"
	)


func test_every_autoload_service_delegates_to_the_one_lookup() -> void:
	var offenders: Array[String] = []
	var found := 0
	for path in _gd_files("res://autoload/"):
		var text := FileAccess.get_file_as_string(path)
		if not text.contains("func _service("):
			continue
		found += 1
		if not text.contains("ServiceLookupScript.find(self, service_name)"):
			offenders.append(path)
	assert_eq(found, 4, "the four node autoloads keep their _service door")
	assert_eq(offenders, [] as Array[String], "every _service delegates to ServiceLookup")


func _gd_files(dir_path: String) -> Array[String]:
	var files: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return files
	for name in dir.get_files():
		if name.ends_with(".gd"):
			files.append(dir_path.path_join(name))
	for child in dir.get_directories():
		files.append_array(_gd_files(dir_path.path_join(child)))
	return files
