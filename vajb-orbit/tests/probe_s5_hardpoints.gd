extends SceneTree
## S5-J4 measurement probe: the per-hull hardpoint map (09 section 11), derived from the
## hulls' own side renders - the sprite the world draws for a hull
## (`res://assets/ships/ship_<stem>_side.png`, the bow-right view `npc_registry` builds
## and the station previews).
##
##   XDG_DATA_HOME=/tmp/s5j4_scratch/xdg $GODOT_CONSOLE --headless --path vajb-orbit \
##     --script res://tests/probe_s5_hardpoints.gd
##
## It prints one paste-ready `ShipFit.HARDPOINTS` literal and the measured table, and it
## writes nothing (no profile read, no file write; the scratch store is arm's-length
## anyway, T-93/L106-L121).
##
## The method, per hull (all values in render px relative to the sprite's own centre -
## the point the scene's `Hull` sprite draws at - x right, y down):
##
##  1. `ink` = alpha > 16; ink box `[x0..x1] x [y0..y1]`; `L = x1 - x0 + 1`.
##  2. **rear**: flame-coloured pixels (r > 150, 40 < g < 190, b < 110, r > g + 40,
##     r > b + 60) form 8-connected blobs of at least 60 px in the rear fifth of the
##     ink box; blobs whose y-centres are within 20 px are one nozzle (a plume split by
##     the bell rim). The anchor is the blob's **mouth**: its max-x pixel, at the mean y
##     of the pixels within 3 px of that column.
##  3. **front**: the bow band (the forward 4 % of `L`); its two ink extremes are the
##     anchors (the bow's leading face, where a retro plume leaves).
##  4. **left / right**: the ink columns at 25 % and 75 % of `L`; each column's ink top
##     edge is the left anchor and its bottom edge the right one.
##  5. **weapon_mounts**: one per W cell of the hull's own grid (`ShipFit.grid_cells`,
##     row-major): the cell's column fraction places the longitudinal station on the
##     measured ink box and its row fraction its height, the nearest ink run to that
##     height is the cell's body section, and the mount sits at the cell's own height
##     inside that section (clamped 4 px clear of the run's edges, so a mount never
##     floats off the drawn hull). `facing` is the **silhouette's own tilt** at the
##     station, measured on the hull's top contour for a cell in the grid's upper half
##     (the bottom contour below) between 20 px behind and 20 px ahead of it, and read as
##     0 (the hull's axis) when that tilt exceeds 45 deg - a 40 px contour jump that steep
##     is a step between structures, not a taper. The renders' barrels all lie along the
##     hull's axis, so 0 is also each mount's rest direction wherever the art is silent.
##
## A hull the probe cannot measure prints nothing for that row, so a missing render can
## never become a silently invented anchor.

const FitData := preload("res://game/ship_fit.gd")

const RENDER_PATH := "res://assets/ships/ship_%s_side.png"
const TAG := "[s5j4]"
const INK_ALPHA := 16
const FLAME_MIN_PX := 60
const FLAME_REAR_FRACTION := 0.20
const NOZZLE_MERGE_PX := 20.0
const MOUTH_BAND_PX := 3
const BOW_BAND_FRACTION := 0.04
const SIDE_STATIONS: Array[float] = [0.25, 0.75]
const MOUNT_INSET_PX := 4.0
const MOUNT_TILT_SPAN_PX := 20
const TILT_LIMIT_DEG := 45.0

## Hull id -> render stem. The nine player hulls, 08 section 2's own names.
const STEMS: Dictionary = {
	&"ship_fighter": "fighter",
	&"ship_vanguard": "vanguard",
	&"ship_miner": "miner",
	&"ship_trader": "trader",
	&"ship_corvette": "corvette",
	&"ship_freighter": "freighter",
	&"ship_gunship": "gunship",
	&"ship_patrol": "patrol",
	&"ship_destroyer": "destroyer",
}

var _ink: Array = []
var _flame: Array = []
var _w := 0
var _h := 0
var _x0 := 0
var _x1 := 0
var _y0 := 0
var _y1 := 0


func _initialize() -> void:
	print("%s hardpoint measurement, %d hulls" % [TAG, STEMS.size()])
	for hull_id: StringName in STEMS:
		_measure(hull_id)
	print("%s done" % TAG)
	quit(0)


func _measure(hull_id: StringName) -> void:
	var path := RENDER_PATH % String(STEMS[hull_id])
	var texture := load(path) as Texture2D
	if texture == null:
		print("%s %s MISSING RENDER %s" % [TAG, hull_id, path])
		return
	var image := texture.get_image()
	if image == null:
		print("%s %s NO IMAGE %s" % [TAG, hull_id, path])
		return
	_w = image.get_width()
	_h = image.get_height()
	var data := image.get_data()
	_ink = []
	_flame = []
	var xs: Array[int] = []
	var ys: Array[int] = []
	for x in _w:
		var column: Array[bool] = []
		var flames: Array[bool] = []
		column.resize(_h)
		flames.resize(_h)
		for y in _h:
			var base := (y * _w + x) * 4
			var alpha := data[base + 3]
			var red := data[base]
			var green := data[base + 1]
			var blue := data[base + 2]
			var here := alpha > INK_ALPHA
			column[y] = here
			if here:
				xs.append(x)
				ys.append(y)
			flames[y] = (
				here
				and red > 150
				and green > 40
				and green < 190
				and blue < 110
				and red > green + 40
				and red > blue + 60
			)
		_ink.append(column)
		_flame.append(flames)
	if xs.is_empty():
		print("%s %s EMPTY RENDER %s" % [TAG, hull_id, path])
		return
	_x0 = xs.min()
	_x1 = xs.max()
	_y0 = ys.min()
	_y1 = ys.max()
	var centre := Vector2(_w * 0.5, _h * 0.5)
	var length := _x1 - _x0 + 1
	var rear := _flame_mouths(centre)
	var front := _bow_anchors(centre)
	var left: Array[Vector2] = []
	var right: Array[Vector2] = []
	for station: float in SIDE_STATIONS:
		var x := _x0 + int(round(float(length) * station))
		var runs := _runs(x)
		if runs.is_empty():
			continue
		left.append(Vector2(float(x), float(runs[0].x)) - centre)
		right.append(Vector2(float(x), float(runs[-1].y)) - centre)
	var mounts := _weapon_mounts(hull_id, centre)
	print(
		"%s %s render=%s canvas=%dx%d ink=[%d..%d]x[%d..%d] L=%d"
		% [TAG, hull_id, path, _w, _h, _x0, _x1, _y0, _y1, length]
	)
	print("%s   rear   %s" % [TAG, _show(rear)])
	print("%s   front  %s" % [TAG, _show(front)])
	print("%s   left   %s" % [TAG, _show(left)])
	print("%s   right  %s" % [TAG, _show(right)])
	for mount: Dictionary in mounts:
		print(
			"%s   mount %d pos=%s facing=%.2f deg"
			% [
				TAG,
				int(mount[&"cell"]),
				_show_one(mount[&"pos"]),
				rad_to_deg(float(mount[&"facing"])),
			]
		)
	print("%s   literal:" % TAG)
	print(_literal(hull_id, rear, front, left, right, mounts))


## The flame blobs' mouths, merged and sorted by y. Screen y grows downward, which is
## the hull-local y the sprite draws in, so no sign is rewritten anywhere.
func _flame_mouths(centre: Vector2) -> Array[Vector2]:
	var blobs: Array = []
	for component: Array in _components(_flame, true):
		if component.size() < FLAME_MIN_PX:
			continue
		var first := 1 << 30
		var last := -1
		var sum_y := 0.0
		for pixel: Vector2i in component:
			first = mini(first, pixel.x)
			last = maxi(last, pixel.x)
			sum_y += float(pixel.y)
		if float(first) > float(_x0) + FLAME_REAR_FRACTION * float(_x1 - _x0 + 1):
			continue
		blobs.append(
			{
				&"mouth": float(last),
				&"y": sum_y / float(component.size()),
				&"last": last,
				&"pixels": component,
			}
		)
	## A plume split by the bell rim is one nozzle: sort by the mouth's y and fold the
	## neighbours whose centres are within the merge window.
	blobs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a[&"y"] < b[&"y"])
	var merged: Array = []
	for blob: Dictionary in blobs:
		if not merged.is_empty():
			var previous: Dictionary = merged[-1]
			if absf(float(blob[&"y"]) - float(previous[&"y"])) <= NOZZLE_MERGE_PX:
				previous[&"last"] = maxi(int(previous[&"last"]), int(blob[&"last"]))
				previous[&"pixels"] = (previous[&"pixels"] as Array) + (blob[&"pixels"] as Array)
				var pixels: Array = previous[&"pixels"]
				var sum := 0.0
				for pixel: Vector2i in pixels:
					sum += float(pixel.y)
				previous[&"y"] = sum / float(pixels.size())
				continue
		merged.append(blob.duplicate(true))
	var out: Array[Vector2] = []
	for blob: Dictionary in merged:
		var mouth := int(blob[&"last"])
		var band: Array[int] = []
		for pixel: Vector2i in blob[&"pixels"]:
			if pixel.x >= mouth - MOUTH_BAND_PX:
				band.append(pixel.y)
		if band.is_empty():
			continue
		var y := 0.0
		for value: int in band:
			y += float(value)
		out.append(Vector2(float(mouth), y / float(band.size())) - centre)
	return out


## The bow band's two ink extremes: the leading face's upper and lower edges.
func _bow_anchors(centre: Vector2) -> Array[Vector2]:
	var from := _x1 - int(round(float(_x1 - _x0 + 1) * BOW_BAND_FRACTION)) + 1
	var top := 1 << 30
	var bottom := -1
	for x in range(maxi(from, _x0), _x1 + 1):
		for y in _h:
			if not bool((_ink[x] as Array)[y]):
				continue
			top = mini(top, y)
			bottom = maxi(bottom, y)
	var out: Array[Vector2] = []
	if bottom < 0:
		return out
	out.append(Vector2(float(_x1), float(top)) - centre)
	out.append(Vector2(float(_x1), float(bottom)) - centre)
	return out


## One mount per W cell, in the hull's own row-major cell order: the cell's column
## fraction places the station, the cell's row fraction picks the body run, and the mount
## sits on that run's outer edge with the outline's own tilt as its facing.
func _weapon_mounts(hull_id: StringName, centre: Vector2) -> Array:
	var out: Array = []
	var size := FitData.grid_size(hull_id)
	if size == Vector2i.ZERO:
		return out
	var cells: Array = FitData.grid_cells(hull_id)
	var index := 0
	for cell: Dictionary in cells:
		if bool(cell[&"gap"]) or StringName(cell[&"type"]) != &"weapons":
			continue
		var fraction_x := (float(int(cell[&"col"])) + 0.5) / float(size.x)
		var fraction_y := (float(int(cell[&"row"])) + 0.5) / float(size.y)
		var x := _x0 + int(round(float(_x1 - _x0 + 1) * fraction_x))
		var target := float(_y0) + float(_y1 - _y0) * fraction_y
		var runs := _runs(x)
		if runs.is_empty():
			index += 1
			continue
		var run := _nearest_run(x, target)
		var top := float(run.x) + MOUNT_INSET_PX
		var bottom := float(run.y) - MOUNT_INSET_PX
		if bottom < top:
			top = (float(run.x) + float(run.y)) * 0.5
			bottom = top
		var y := clampf(target, top, bottom)
		var upper := y <= (float(run.x) + float(run.y)) * 0.5
		var behind := _edge_y(x - MOUNT_TILT_SPAN_PX, run, upper)
		var ahead := _edge_y(x + MOUNT_TILT_SPAN_PX, run, upper)
		var facing := 0.0
		if not is_nan(behind) and not is_nan(ahead):
			facing = atan2(ahead - behind, float(MOUNT_TILT_SPAN_PX) * 2.0)
			## A 40 px contour jump steeper than TILT_LIMIT_DEG is a structure step (the
			## contour leaving one nacelle for another), not a taper: it reads the hull's
			## axis, the direction the renders' barrels all lie in.
			if absf(facing) > deg_to_rad(TILT_LIMIT_DEG):
				facing = 0.0
		out.append({&"cell": index, &"pos": Vector2(float(x), y) - centre, &"facing": facing})
		index += 1
	return out


## The ink runs of one column, as (top, bottom) pairs, top first.
func _runs(x: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if x < 0 or x >= _w:
		return out
	var column: Array = _ink[x]
	var y := 0
	while y < _h:
		if not bool(column[y]):
			y += 1
			continue
		var start := y
		while y < _h and bool(column[y]):
			y += 1
		out.append(Vector2i(start, y - 1))
	return out


func _has_run(x: int) -> bool:
	return not _runs(x).is_empty()


## The run of column `x` whose centre is nearest `target`; `ZERO` when the column has no
## ink at all.
func _nearest_run(x: int, target: float) -> Vector2i:
	var best := Vector2i.ZERO
	var best_distance := INF
	for run: Vector2i in _runs(x):
		var centre := (float(run.x) + float(run.y)) * 0.5
		var distance := absf(centre - target)
		if distance < best_distance:
			best_distance = distance
			best = run
	return best


## The silhouette's own edge at `x`: the top contour of the whole hull when `upper`, the
## bottom contour otherwise. The outermost run is read rather than the mount's own, so the
## tilt is the hull's taper and not a jump to another structure. NaN when the column
## carries no ink.
func _edge_y(x: int, _reference: Vector2i, upper: bool) -> float:
	var runs := _runs(x)
	if runs.is_empty():
		return NAN
	return float(runs[0].x) if upper else float(runs[-1].y)


## 8-connected components of a mask, optionally clipped to the rear of the ink box.
func _components(mask: Array, _rear_only: bool) -> Array:
	var seen := {}
	var out: Array = []
	for x in _w:
		for y in _h:
			if not bool((mask[x] as Array)[y]) or seen.has(Vector2i(x, y)):
				continue
			var queue: Array[Vector2i] = [Vector2i(x, y)]
			seen[Vector2i(x, y)] = true
			var component: Array = []
			while not queue.is_empty():
				var pixel: Vector2i = queue.pop_back()
				component.append(pixel)
				for dx in [-1, 0, 1]:
					for dy in [-1, 0, 1]:
						var next := Vector2i(pixel.x + dx, pixel.y + dy)
						if next.x < 0 or next.x >= _w or next.y < 0 or next.y >= _h:
							continue
						if seen.has(next) or not bool((mask[next.x] as Array)[next.y]):
							continue
						seen[next] = true
						queue.append(next)
			out.append(component)
	return out


func _literal(
	hull_id: StringName,
	rear: Array[Vector2],
	front: Array[Vector2],
	left: Array[Vector2],
	right: Array[Vector2],
	mounts: Array
) -> String:
	var text := "\t&\"%s\": {\n" % hull_id
	text += "\t\t&\"thrusters\": {\n"
	text += "\t\t\t&\"rear\": %s,\n" % _show(rear)
	text += "\t\t\t&\"front\": %s,\n" % _show(front)
	text += "\t\t\t&\"left\": %s,\n" % _show(left)
	text += "\t\t\t&\"right\": %s,\n" % _show(right)
	text += "\t\t},\n"
	text += "\t\t&\"weapon_mounts\": [\n"
	for mount: Dictionary in mounts:
		var facing := "%.3f" % float(mount[&"facing"])
		if facing == "-0.000":
			facing = "0.000"
		text += "\t\t\t{&\"pos\": %s, &\"facing\": %s},\n" % [_show_one(mount[&"pos"]), facing]
	text += "\t\t],\n\t},\n"
	return text


func _show(values: Array[Vector2]) -> String:
	var parts: Array[String] = []
	for value: Vector2 in values:
		parts.append(_show_one(value))
	return "[%s]" % ", ".join(parts)


func _show_one(value: Vector2) -> String:
	return "Vector2(%s, %s)" % [_num(value.x), _num(value.y)]


## One decimal: the render is measured to the pixel and a tenth of a pixel is already
## finer than the art (0.0663 p.u of scale).
func _num(value: float) -> String:
	var text := "%.1f" % value
	if text == "-0.0":
		text = "0.0"
	return text
