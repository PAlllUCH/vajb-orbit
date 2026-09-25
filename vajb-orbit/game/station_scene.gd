extends Node2D
## D11's composed dockable-station scene (ENVIRONMENT_SPEC §11 — the owner's O6:
## "bigger with more details, not a single sprite, more static and moving
## elements"). Built by `setup()` from the hero render plus the approved element
## set; `game/sector.gd:_spawn_station` swaps this in for the old single
## Sprite2D. Geometry is the approved mockup's (A0's plan of record): every
## position is hero-relative world units, the hero drawn at `HERO_SCALE`.
##
## Motion rides `_process` via `step_motion()` with the three named constants
## below — no `Timer` nodes (17 §4's one-timer law governs respawn bookkeeping
## and is untouched). Every motion rule is a pure static taking its constant as
## a parameter, so a probe can prove the reversal: a reversal-valued constant
## (<= 0) makes its element stand still.

## The approved hero pin: today's `STATION_SCALE` 0.0663 (sector.gd) x 2.2 =
## a 298.8 u frame on the 2048 px hero canvas. Reversal: `STATION_SCALE` as
## shipped (one sprite, today's footprint).
const HERO_SCALE := 0.1459

## Motion constants (the approved mockup's pins; each reversal = the element
## stands still — `STROBE_PERIOD <= 0` freezes the chase on dot 0,
## `SHUTTLE_SPEED <= 0` parks the shuttles at their phase, `SLEW_RATE <= 0`
## parks the crane at rest).
const STROBE_PERIOD := 1.2
const SHUTTLE_SPEED := 30.0
const SLEW_RATE := 4.0

## Slew sweep: +-60 deg (120 span) about the pivot, 30 s per sweep at 4 deg/s.
const SLEW_SPAN := 60.0

## The approved shuttle loop (A0's geometry): rounded rect left -255 right 340
## top -225 bottom 190, corner radius 90 u -> perimeter 1865.5 u (the plan's
## 1866), a 62 s lap at `SHUTTLE_SPEED`.
const LOOP_LEFT := -255.0
const LOOP_RIGHT := 340.0
const LOOP_TOP := -225.0
const LOOP_BOTTOM := 190.0
const LOOP_CORNER := 90.0

## The static element textures (1-object-per-panel renders, `assets/env/poi/`).
const TexArmA := preload("res://assets/env/poi/env_station_arm_a.png")
const TexArmB := preload("res://assets/env/poi/env_station_arm_b.png")
const TexMastA := preload("res://assets/env/poi/env_station_mast_a.png")
const TexMastB := preload("res://assets/env/poi/env_station_mast_b.png")
const TexGantryA := preload("res://assets/env/poi/env_station_gantry_a.png")
const TexGantryB := preload("res://assets/env/poi/env_station_gantry_b.png")
const TexWindowsA := preload("res://assets/env/poi/env_station_windows_a.png")
const TexWindowsB := preload("res://assets/env/poi/env_station_windows_b.png")
const TexPlateA := preload("res://assets/env/poi/env_station_plate_a.png")
const TexPlateB := preload("res://assets/env/poi/env_station_plate_b.png")
const TexLampA := preload("res://assets/env/poi/env_station_lamp_a.png")
const TexLampB := preload("res://assets/env/poi/env_station_lamp_b.png")
const TexShuttleA := preload("res://assets/env/poi/env_station_shuttle_a.png")
const TexShuttleB := preload("res://assets/env/poi/env_station_shuttle_b.png")

var hero_sprite: Sprite2D = null
var _elapsed := 0.0
var _strobes: Array[Sprite2D] = []
var _shuttles: Array[Sprite2D] = []
var _shuttle_phases: Array[float] = []
var _slew_pivot: Node2D = null


## The approved element set (A0's hero-relative placement table). One dict per
## instance: `role` is "static" | "strobe" | "shuttle" | "slew"; `scale_u` is the
## u length of the art's long edge after scaling; `rot_deg` orients that edge.
## An instance method (not static) so a path-loaded script can reach it
## (sector.gd reaches every cross-file symbol by path, never the class table).
func approved_elements() -> Array[Dictionary]:
	return [
		# Docking-arm trusses (tips at +-193 u on the y=0 axis).
		{&"name": &"ArmA", &"texture": TexArmA, &"role": &"static",
			&"pos": Vector2(-162, 0), &"rot_deg": -90.0, &"scale_u": 62.0},
		{&"name": &"ArmB", &"texture": TexArmB, &"role": &"static",
			&"pos": Vector2(162, 0), &"rot_deg": 0.0, &"scale_u": 62.0},
		# Antenna/mast clusters at the hull's upper-left / lower-right corners.
		{&"name": &"MastA", &"texture": TexMastA, &"role": &"static",
			&"pos": Vector2(-130, -130), &"rot_deg": -45.0, &"scale_u": 48.0},
		{&"name": &"MastB", &"texture": TexMastB, &"role": &"static",
			&"pos": Vector2(130, 130), &"rot_deg": 135.0, &"scale_u": 48.0},
		# Gantry crane on the top rail (x -95..-15, body y -157..-137, jib up).
		{&"name": &"GantryA", &"texture": TexGantryA, &"role": &"static",
			&"pos": Vector2(-55, -167), &"rot_deg": 0.0, &"scale_u": 70.0},
		# Lit-window bands (y = -52 / +52, x -85..+85).
		{&"name": &"WindowsA", &"texture": TexWindowsA, &"role": &"static",
			&"pos": Vector2(0, -52), &"rot_deg": 0.0, &"scale_u": 120.0},
		{&"name": &"WindowsB", &"texture": TexWindowsB, &"role": &"static",
			&"pos": Vector2(0, 52), &"rot_deg": 0.0, &"scale_u": 120.0},
		# Hull-plate spines (x = -107 / +51).
		{&"name": &"PlateA", &"texture": TexPlateA, &"role": &"static",
			&"pos": Vector2(-96, 0), &"rot_deg": 0.0, &"scale_u": 70.0},
		{&"name": &"PlateB", &"texture": TexPlateB, &"role": &"static",
			&"pos": Vector2(62, 0), &"rot_deg": 0.0, &"scale_u": 70.0},
		# Ember warning-lamp runs (y = ±123, x -100..+100) — the only emissive.
		{&"name": &"LampA", &"texture": TexLampA, &"role": &"static",
			&"pos": Vector2(0, -123), &"rot_deg": 0.0, &"scale_u": 200.0},
		{&"name": &"LampB", &"texture": TexLampB, &"role": &"static",
			&"pos": Vector2(0, 123), &"rot_deg": 90.0, &"scale_u": 200.0},
		# Moving kind 1 — approach strobes: 5 dots on the lane x=0, 55 u apart
		# (y 160..380), the chase lit one dot per STROBE_PERIOD. No new art: the
		# lamp texture is reused, toggled in code.
		{&"name": &"Strobe0", &"texture": TexLampA, &"role": &"strobe",
			&"pos": Vector2(0, 160), &"rot_deg": 0.0, &"scale_u": 24.0},
		{&"name": &"Strobe1", &"texture": TexLampA, &"role": &"strobe",
			&"pos": Vector2(0, 215), &"rot_deg": 0.0, &"scale_u": 24.0},
		{&"name": &"Strobe2", &"texture": TexLampA, &"role": &"strobe",
			&"pos": Vector2(0, 270), &"rot_deg": 0.0, &"scale_u": 24.0},
		{&"name": &"Strobe3", &"texture": TexLampA, &"role": &"strobe",
			&"pos": Vector2(0, 325), &"rot_deg": 0.0, &"scale_u": 24.0},
		{&"name": &"Strobe4", &"texture": TexLampA, &"role": &"strobe",
			&"pos": Vector2(0, 380), &"rot_deg": 0.0, &"scale_u": 24.0},
		# Moving kind 2 — service shuttles on the loop, opposite phases.
		{&"name": &"ShuttleA", &"texture": TexShuttleA, &"role": &"shuttle",
			&"pos": Vector2.ZERO, &"rot_deg": 0.0, &"scale_u": 40.0, &"phase": 0.0},
		{&"name": &"ShuttleB", &"texture": TexShuttleB, &"role": &"shuttle",
			&"pos": Vector2.ZERO, &"rot_deg": 0.0, &"scale_u": 40.0, &"phase": 0.5},
		# Moving kind 3 — the crane slew: gantry_b hangs off a pivot node at
		# (62,-131) and the pivot rotates under SLEW_RATE.
		{&"name": &"Slew", &"texture": TexGantryB, &"role": &"slew",
			&"pos": Vector2(62, -131), &"offset": Vector2(0, -26),
			&"rot_deg": -90.0, &"scale_u": 92.0},
	]


## Build the composed tree. `hero` is the hero render; `elements` is
## `approved_elements()` (or a probe's own set). Joins `&"station"` on the root
## — the invariant group every reader keys off.
func setup(hero: Texture2D, elements: Array[Dictionary]) -> void:
	hero_sprite = Sprite2D.new()
	hero_sprite.name = &"Hero"
	hero_sprite.texture = hero
	hero_sprite.scale = Vector2(HERO_SCALE, HERO_SCALE)
	add_child(hero_sprite)
	for element: Dictionary in elements:
		_add_element(element)
	add_to_group(&"station")


func _add_element(element: Dictionary) -> void:
	var sprite := Sprite2D.new()
	sprite.name = StringName(element.get(&"name", &"Element"))
	sprite.texture = element.get(&"texture") as Texture2D
	var scale_u := float(element.get(&"scale_u", 32.0))
	var tex := sprite.texture
	var long_px := 1.0
	if tex != null:
		long_px = maxf(float(tex.get_width()), float(tex.get_height()))
	var s := scale_u / long_px
	sprite.scale = Vector2(s, s)
	sprite.rotation_degrees = float(element.get(&"rot_deg", 0.0))
	var role := StringName(element.get(&"role", &"static"))
	match role:
		&"slew":
			_slew_pivot = Node2D.new()
			_slew_pivot.name = &"SlewPivot"
			_slew_pivot.position = element.get(&"pos", Vector2.ZERO) as Vector2
			sprite.position = element.get(&"offset", Vector2.ZERO) as Vector2
			_slew_pivot.add_child(sprite)
			add_child(_slew_pivot)
		&"strobe":
			sprite.position = element.get(&"pos", Vector2.ZERO) as Vector2
			add_child(sprite)
			_strobes.append(sprite)
		&"shuttle":
			sprite.position = element.get(&"pos", Vector2.ZERO) as Vector2
			add_child(sprite)
			_shuttles.append(sprite)
			_shuttle_phases.append(float(element.get(&"phase", 0.0)))
		_:
			sprite.position = element.get(&"pos", Vector2.ZERO) as Vector2
			add_child(sprite)


func _process(delta: float) -> void:
	step_motion(delta)


## Advance every moving element by `delta` seconds under the named constants.
func step_motion(delta: float) -> void:
	_elapsed += delta
	if not _strobes.is_empty():
		var lit := strobe_lit(_elapsed, STROBE_PERIOD, _strobes.size())
		for i in _strobes.size():
			_strobes[i].visible = (i == lit)
	for i in _shuttles.size():
		var s := shuttle_s(_elapsed, SHUTTLE_SPEED, _shuttle_phases[i])
		var here := loop_point(s)
		var ahead := loop_point(fposmod(s + 1.0, loop_length()))
		_shuttles[i].position = here
		_shuttles[i].rotation = (ahead - here).angle()
	if _slew_pivot != null:
		_slew_pivot.rotation_degrees = slew_deg(_elapsed, SLEW_RATE)


## Which strobe dot is lit at `elapsed` (the chase advances one dot per
## `period`). REVERSAL `period <= 0` -> the chase stands still on dot 0.
static func strobe_lit(elapsed: float, period: float, count: int) -> int:
	if period <= 0.0 or count <= 0:
		return 0
	return int(floor(elapsed / period)) % count


## Shuttle distance along the loop at `elapsed`, offset by `phase` (0..1 of the
## lap). REVERSAL `speed <= 0` -> the shuttle parks at its phase.
static func shuttle_s(elapsed: float, speed: float, phase: float) -> float:
	var length := loop_length()
	var parked := fposmod(phase, 1.0) * length
	if speed <= 0.0:
		return parked
	return fposmod(parked + elapsed * speed, length)


## Crane angle at `elapsed`, sweeping +-`SLEW_SPAN` deg at `rate` deg/s (30 s
## per sweep at 4). REVERSAL `rate <= 0` -> the crane parks at rest (0 deg).
static func slew_deg(elapsed: float, rate: float) -> float:
	if rate <= 0.0:
		return 0.0
	var p := fposmod(elapsed * rate, 4.0 * SLEW_SPAN)
	if p < 2.0 * SLEW_SPAN:
		return -SLEW_SPAN + p
	return 3.0 * SLEW_SPAN - p


## Perimeter of the approved shuttle loop (rounded rect, corner radius
## `LOOP_CORNER`): 2 x straights + 4 x quarter arcs = 1865.5 u.
static func loop_length() -> float:
	return (
		2.0 * (LOOP_RIGHT - LOOP_LEFT - 2.0 * LOOP_CORNER)
		+ 2.0 * (LOOP_BOTTOM - LOOP_TOP - 2.0 * LOOP_CORNER)
		+ TAU * LOOP_CORNER
	)


## Position at arc distance `s` along the loop (clockwise from the top-left
## straight's start).
static func loop_point(s: float) -> Vector2:
	var d := fposmod(s, loop_length())
	var top := LOOP_RIGHT - LOOP_LEFT - 2.0 * LOOP_CORNER
	var side := LOOP_BOTTOM - LOOP_TOP - 2.0 * LOOP_CORNER
	var arc := (TAU * LOOP_CORNER) / 4.0
	var tr := Vector2(LOOP_RIGHT - LOOP_CORNER, LOOP_TOP + LOOP_CORNER)
	var br := Vector2(LOOP_RIGHT - LOOP_CORNER, LOOP_BOTTOM - LOOP_CORNER)
	var bl := Vector2(LOOP_LEFT + LOOP_CORNER, LOOP_BOTTOM - LOOP_CORNER)
	var tl := Vector2(LOOP_LEFT + LOOP_CORNER, LOOP_TOP + LOOP_CORNER)
	if d < top:
		return Vector2(tl.x + d, LOOP_TOP)
	d -= top
	if d < arc:
		return tr + Vector2.RIGHT.rotated(-PI / 2.0 + (d / arc) * (PI / 2.0)) * LOOP_CORNER
	d -= arc
	if d < side:
		return Vector2(LOOP_RIGHT, tr.y + d)
	d -= side
	if d < arc:
		return br + Vector2.RIGHT.rotated((d / arc) * (PI / 2.0)) * LOOP_CORNER
	d -= arc
	if d < top:
		return Vector2(br.x - d, LOOP_BOTTOM)
	d -= top
	if d < arc:
		return bl + Vector2.RIGHT.rotated(PI / 2.0 + (d / arc) * (PI / 2.0)) * LOOP_CORNER
	d -= arc
	if d < side:
		return Vector2(LOOP_LEFT, bl.y - d)
	d -= side
	return tl + Vector2.RIGHT.rotated(PI + (d / arc) * (PI / 2.0)) * LOOP_CORNER
