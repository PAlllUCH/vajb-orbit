extends SceneTree
## P2-A W2 evidence probe: drive the fit store's save v2 -> v4 migration end to
## end and print the persisted shapes before and after, so every number in
## `.agents/gen/p2a_w2_report.md` can be re-measured by hand.
##
##   godot --headless --path vajb-orbit --script res://tests/probe_p2a_fits_migration.gd
##
## Throwaway `PlayerProfile` instances only - never the shipped autoload, and no
## instance is added to the tree, so there is no debounce Timer to flush. Every
## scratch file is removed at the end.

const Profile := preload("res://autoload/player_profile.gd")
const FitData := preload("res://game/ship_fit.gd")

const PROBE_PATH := "user://probe_p2a_fits_migration.cfg"
const SECTION := "profile"


func _init() -> void:
	_write_v2_fixture()
	print("[probe] v2 fixture on disk:")
	print(_file_text())

	var before := _stored()
	print("[probe] before: save_version=%s fits=%s" % [before["version"], before["fits"]])

	var first = _profile()
	print("[probe] fit_for(ship_vanguard) = %s" % str(first.fit_for(&"ship_vanguard")))
	var after_read := _stored()
	print(
		"[probe] after the read: save_version=%s fits=%s"
		% [after_read["version"], after_read["fits"]]
	)

	print(
		"[probe] set_fit_slot(ship_vanguard, engines, 0, e_ion) = %s"
		% first.set_fit_slot(&"ship_vanguard", &"engines", 0, &"e_ion")
	)
	first.save()
	var after_write := _stored()
	print(
		"[probe] after the write: save_version=%s fits=%s"
		% [after_write["version"], after_write["fits"]]
	)
	print("[probe] v4 file on disk:")
	print(_file_text())

	var second = _profile()
	print("[probe] reloaded fit_for(ship_vanguard) = %s" % str(second.fit_for(&"ship_vanguard")))

	print("[probe] hull capacities in FitData.FIT_SLOT_KEYS order (E/W/S/H/C/B/U/P):")
	for hull: StringName in FitData.HULLS:
		var counts: Array = []
		for slot_key: StringName in FitData.FIT_SLOT_KEYS:
			counts.append(FitData.slot_capacity(hull, slot_key))
		print(
			"[probe]   %-16s %s  fit_for(engines)=%s"
			% [hull, str(counts), str(second.fit_for(hull)[&"engines"])]
		)

	## Probe hygiene (L17): nothing is restored, but any pending debounce is
	## flushed before the scratch file goes away.
	first.flush()
	second.flush()
	_remove(PROBE_PATH)
	print("[probe] scratch file removed: %s" % str(not FileAccess.file_exists(PROBE_PATH)))
	quit()


func _profile():
	var profile := Profile.new()
	profile.save_path = PROBE_PATH
	profile.reload()
	return profile


func _write_v2_fixture() -> void:
	var fixture := ConfigFile.new()
	fixture.set_value(SECTION, "save_version", 2)
	fixture.set_value(SECTION, "credits", 4321)
	fixture.set_value(
		SECTION,
		"fits",
		{
			"ship_vanguard":
			{
				"engine": "e_std",
				"power": "p_std",
				"weapons": "w_laser",
				"shields": "s_light",
			},
		}
	)
	var err := fixture.save(PROBE_PATH)
	print("[probe] v2 fixture written: %s" % error_string(err))


func _stored() -> Dictionary:
	var config := ConfigFile.new()
	config.load(PROBE_PATH)
	return {
		"version": int(config.get_value(SECTION, "save_version", 0)),
		"fits": config.get_value(SECTION, "fits", {}),
	}


func _file_text() -> String:
	var file := FileAccess.open(PROBE_PATH, FileAccess.READ)
	if file == null:
		return "(missing)"
	var text := file.get_as_text()
	file.close()
	return text


func _remove(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())
