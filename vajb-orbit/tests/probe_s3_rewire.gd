extends Node
## S3's evidence probe for the re-cut wiring: every row the game draws from, as the code
## holds it, plus the mine family's sprite and burst.
##
## Run: ~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_s3_rewire.tscn

const ProjectileScript := preload("res://game/projectile.gd")
const SpeedFantasyScript := preload("res://game/speed_fantasy.gd")
const WeaponScript := preload("res://game/weapons.gd")

const TAG := "[S3R]"


func _ready() -> void:
	print("%s FEEDBACK rows=%d" % [TAG, ProjectileScript.FEEDBACK.size()])
	for name: Variant in ProjectileScript.FEEDBACK:
		_row("FEEDBACK", String(name), ProjectileScript.FEEDBACK[name])
	print("%s SHEETS rows=%d" % [TAG, ProjectileScript.SHEETS.size()])
	for kind: Variant in ProjectileScript.SHEETS:
		_row("SHEETS", String(kind), ProjectileScript.SHEETS[kind])
	print(
		"%s SPEED_FANTASY vignette=%s dust_row=%s"
		% [
			TAG,
			SpeedFantasyScript.VIGNETTE_SHEET,
			String(SpeedFantasyScript.DUST_ROW),
		]
	)
	print(
		"%s MUZZLE_FLASH frames=%s size=%s world=%.1f (weapons.gd, outside this worker's set)"
		% [
			TAG,
			str(WeaponScript.FLASH_FRAMES),
			str(WeaponScript.FLASH_FRAME_SIZE),
			WeaponScript.FLASH_WORLD,
		]
	)
	print("%s done" % TAG)
	get_tree().quit()


func _row(table: String, name: String, row: Dictionary) -> void:
	var frames: Array = row.get(&"frames", [])
	var region: Rect2 = row.get(&"region", Rect2())
	var source: Vector2 = row.get(&"source", Vector2.ZERO)
	var sizes: PackedStringArray = []
	for path: Variant in frames:
		var texture := load(String(path)) as Texture2D
		sizes.append("%s" % ("missing" if texture == null else str(texture.get_size())))
	print(
		(
			"%s ROW %s.%s frames=%d region=%s source=(%.0f,%.0f) world=%.1f fps=%.1f "
			+ "loop=%s sizes=%s first=%s"
		)
		% [
			TAG,
			table,
			name,
			frames.size(),
			"none" if region.size.x <= 0.0 else str(region),
			source.x,
			source.y,
			float(row.get(&"world", 0.0)),
			float(row.get(&"fps", 0.0)),
			str(row.get(&"loop", false)),
			", ".join(sizes),
			"none" if frames.is_empty() else String(frames[0]),
		]
	)
