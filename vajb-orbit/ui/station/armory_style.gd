class_name ArmoryStyle
extends "res://ui/hud/cockpit_style.gd"
## UI_SPEC section 3.9 rule 5 for the ARMORY: the battery window's one style surface. It
## **extends `CockpitStyle`** (`ui/hud/cockpit_style.gd`), so the pane reads the palette,
## the `ui_seg_*` asset parts and the texture/colour lookups through the very same
## Resource the cluster uses - one palette, one asset idiom, no second colour store.
##
## **UI_SPEC section 3.10 Amendment 3 (the D13 rework, wave S18)** rules this surface's
## layout: the landscape console **1360x516** at the pinned **1392x610** host, five
## 2x2-cell bays across the top, and one wells band (barrel inventory left, ammunition
## pack cards right). The console's rect is **derived from the host rect at runtime
## (P6)** - there is no pinned pane rect: `console_rect(host)` scales the base insets by
## the host's own width/height, the bands inside it scale their offsets by the console's
## height, and the gaps between elements are fixed. The base numbers live here, once, so
## the pane and its tests cannot disagree about where anything lands.
##
## **Amendment 4 (2026-09-26, wave S20) rules the surface.** The scripted console master
## retires from the pane (its file stays on disk, unwired): the bay
## cards, the wells halves and the pack/row plates wear the theme's **`ui_panel_frame`**
## nine-patch (`PanelRaised`), the bays' cells the `ui_slot_weapon_*` slot chrome, and
## `BUY`/`X`/pressable chips the `StationButton` plates. The palette fields below carry
## **no hex literal**: `resolve_theme` reads them from the generated theme's
## `Tokens/armory_*` entries (the only hex store is `tools/build_theme.gd`), so a theme
## re-band moves this pane with every sibling panel.
##
## A user drops `res://ui/station/armory_style_user.tres` in and the pane restyles and
## relayouts with no code edit (its own stored values win over the theme's). Reversal:
## the pane's D6/S5 theme-stylebox chrome and the mockup palette fields.

## The override path (section 3.9 rule 5 for this surface; the cluster's own is
## `CockpitStyle.USER_PATH`).
const ARMORY_USER_PATH: String = "res://ui/station/armory_style_user.tres"
## This file, reached by path so the surface still parses in a headless gate whose global
## class table predates it (the family's own lesson).
const ARMORY_SCRIPT_PATH: String = "res://ui/station/armory_style.gd"

@export_group("armory palette")
## The mockup's CAP: dim ink on painted metal, the caption tone of every mark drawn over
## the frame chrome. Measured >= 4.5:1 against the plate (HIGH-2's cure).
@export var caption: Color
## The mockup's CAP_VOID: dim ink on the host/void outside the plate.
@export var caption_void: Color
## A bay card's own recess tone (the mockup's 30,34,41); the panel frame carries it now.
@export var bay_bg: Color
## A cell's recess fill (the mockup's 18,21,26); the salvo drums sit on it.
@export var cell_bg: Color
## The salvo ledge's band (the mockup's 22,26,31).
@export var ledge_bg: Color
## An inventory row's / pack card's fill (the mockup's 38,43,50); under the frame.
@export var item_bg: Color
## A resting chip's fill (READY) - the mockup's 46,51,58.
@export var chip_bg: Color
## The OVER CAP chip's fill, paired with the ember border. The mockup's 78,32,18 was
## darkened in `tools/build_theme.gd` so the OVER CAP label clears 4.5:1 (L227).
@export var chip_danger_bg: Color
## The fitted cell's decorative ember line (the mockup's cell underline).
@export var fit_line: Color

@export_group("armory layout")
## Section 10's `@2x` recipe: a master is this many times its logical box. The console box
## is drawn at `canvas * art_scale`, once the base console's own 1360x516.
@export var art_scale: float = 2.0
## The measured host rect the base numbers were fitted at (the station's module host at
## 1920x1080). Every rect derives from the *actual* host rect by scaling against this.
@export var host_base: Vector2 = Vector2(1392.0, 610.0)
## The console's inset inside the host at the base size, in drawn pixels: left, top,
## right, bottom. The 68 px top band carries the pane's own title and captions; the
## 26 px foot clears the shell's status strip.
@export var console_inset: Vector4 = Vector4(16.0, 68.0, 16.0, 26.0)
## The base console (drawn 1360x516; 2x = the master's 2720x1072); `canvas * art_scale`
## must equal `host_base` less `console_inset`.
@export var canvas: Vector2 = Vector2(680.0, 258.0)
## The rack band (P36's amendment): the five racks are full-width rows stacked from the
## console's top down to the wells band, so the whole console width is used. `band_top`
## and `band_side` are the band's own insets (both fixed drawn pixels).
@export var band_top: float = 0.0
@export var band_side: float = 0.0
@export var bay_columns: int = 5
## The gap between two stacked rack rows, and the one gap between the rack band and the
## wells band below it (both fixed).
@export var rack_gap: float = 6.0
@export var body_gap: float = 6.0
## A rack row's own minimum height, its head block's width and its salvo ledge's width.
@export var rack_row_height: float = 56.0
@export var row_head_width: float = 200.0
@export var row_salvo_width: float = 270.0
## The wells band's own height at the console's foot (the empty-cell list and the summary).
@export var wells_height: float = 92.0
## A rack row's four cells (P36: the four W cells ride one row), the margin from the row's
## edges and the gap between the cells (all fixed).
@export var cell_columns: int = 4
@export var cell_rows: int = 1
@export var cell_margin: float = 10.0
@export var cell_gap: float = 6.0
## A cell's own text inset (the name block's left/right padding).
@export var cell_text_inset: float = 6.0
## The salvo ledge's parts: the four `ui_seg_*` drum cells and the carved 13 px caption's
## gap from them. **Four cells since S22.8** (the owner's cadence split): the heavy
## tier's cooldowns read 10.00-15.00 s, which the three-cell drum's 9.99 s ceiling
## could not carry.
@export var salvo_cells: int = 4
@export var salvo_cell: Vector2 = Vector2(18.0, 32.0)
@export var salvo_pitch: float = 20.0
@export var salvo_caption: String = "SALVO s"
@export var salvo_caption_left: float = 74.0
## The wells band: the fixed gutter between its two halves.
@export var wells_gutter: float = 32.0
## The band's item grid, per half: two columns of three (barrel inventory rows left,
## ammunition pack cards right) on a fixed gap.
@export var item_columns: int = 2
@export var item_rows: int = 3
@export var item_gap: float = 8.0
## A pack card's / inventory row's own icon box.
@export var item_icon: float = 24.0
## A wells half's caption band above its item grid (the `BARREL INVENTORY` /
## `AMMUNITION` lines).
@export var caption_band: float = 20.0
## The bay head's state chip, right-aligned in the head (room for `OVER CAP`, the
## chevron and the padding at 13 px).
@export var head_chip: Vector2 = Vector2(104.0, 22.0)

## The 3 px ember frame on the selected bay (the 1 px chip/danger frame is
## `CockpitStyle.frame_width`).
@export var selected_frame_width: float = 3.0

## The generated theme carrying this palette (`Tokens/armory_*`) and the chrome family's
## panels, slots and plates - the same read `game/weapons.gd` makes for its beam tones, so
## no hex literal has to live in this file (Amendment 4, A4.3).
const THEME_PATH: String = "res://ui/theme/vajb_theme.tres"
const TOKENS_TYPE: StringName = &"Tokens"
## One palette role's theme token: `armory_` + the field's own name.
const TOKEN_PREFIX: String = "armory_"
## Every palette field `resolve_theme` fills, in the role vocabulary `colour()` reads.
const PALETTE_ROLES: Array[StringName] = [
	&"caption", &"caption_void", &"bay_bg", &"cell_bg", &"ledge_bg",
	&"item_bg", &"chip_bg", &"chip_danger_bg", &"fit_line",
]


func _init() -> void:
	resolve_theme()


## Read every palette field from the generated theme's `Tokens/armory_*` entries (A4.3:
## the hex values live only in `tools/build_theme.gd`). Runs at construction, so a user
## `.tres`'s own stored values still win - the loader applies them after `_init`.
func resolve_theme(theme: Theme = null) -> void:
	var source: Theme = theme if theme != null else load(THEME_PATH) as Theme
	if source == null:
		return
	for role: StringName in PALETTE_ROLES:
		var token := StringName(TOKEN_PREFIX + String(role))
		if source.has_color(token, TOKENS_TYPE):
			set(role, source.get_color(token, TOKENS_TYPE))


## The armory's style: the user's `.tres` when it exists (and is this script), the shipped
## defaults otherwise - the same contract as `CockpitStyle.load_style`.
static func load_style(path: String = ARMORY_USER_PATH) -> Resource:
	var script := load(ARMORY_SCRIPT_PATH) as GDScript
	if not path.is_empty() and ResourceLoader.exists(path):
		var loaded: Resource = load(path)
		if loaded != null and loaded.get_script() == script:
			return loaded
	return script.new()


static func defaults() -> Resource:
	return (load(ARMORY_SCRIPT_PATH) as GDScript).new()


## The console's own size at the base host (1360x516): the host less the console insets.
func console_size_at_base() -> Vector2:
	return Vector2(
		host_base.x - console_inset.x - console_inset.z,
		host_base.y - console_inset.y - console_inset.w
	)


## A logical length in drawn pixels.
func drawn(value: float) -> float:
	return value * art_scale


func drawn_vector(value: Vector2) -> Vector2:
	return value * art_scale


func drawn_rect(rect: Rect2) -> Rect2:
	return Rect2(rect.position * art_scale, rect.size * art_scale)


## The base console's drawn box: `canvas * art_scale`, asserted equal to
## `console_size_at_base()` (the two cannot drift).
func block_size() -> Vector2:
	return canvas * art_scale


## P6's law, one function: the console's rect inside `host`. Each inset scales with the
## host's own axis against the base host, so a wider window widens the console beside its
## fixed side margins and a taller one grows the top band proportionally.
func console_rect(host: Rect2) -> Rect2:
	var sx := _axis(host.size.x, host_base.x)
	var sy := _axis(host.size.y, host_base.y)
	var base := console_size_at_base()
	return Rect2(
		host.position + Vector2(_scale(console_inset.x, sx), _scale(console_inset.y, sy)),
		Vector2(_scale(base.x, sx), _scale(base.y, sy))
	)


## The rack band inside `console` (P36's amendment): the five racks are **full-width rows**
## stacked from the console's top down to the wells band, so the whole console width is
## used (T-122's dead space dies). The band is the console less the wells band and the one
## body gap.
func bays_band(console: Rect2) -> Rect2:
	var bottom: float = console.position.y + console.size.y - wells_height - body_gap
	return Rect2(
		console.position + Vector2(band_side, band_top),
		Vector2(
			maxf(console.size.x - band_side * 2.0, 0.0),
			maxf(bottom - (console.position.y + band_top), 0.0)
		)
	)


## One rack row's rect inside the band (drawn pixels), `index` 0-based, `B1` at the top.
## The rows stack full-width on the fixed rack gap.
func bay_rect(index: int, console: Rect2) -> Rect2:
	var band := bays_band(console)
	var count: int = maxi(bay_columns, 1)
	var height: float = (band.size.y - float(count - 1) * rack_gap) / float(count)
	return Rect2(
		band.position + Vector2(0.0, float(index) * (height + rack_gap)),
		Vector2(band.size.x, maxf(height, 0.0))
	)


## A rack row's head block: the strip the `B<n>` label, its key hint and its state chip sit
## on, at the row's left.
func bay_head_rect(row: Rect2) -> Rect2:
	return Rect2(row.position, Vector2(minf(row_head_width, row.size.x), row.size.y))


## One cell's rect inside its rack row (0..3, left to right: the rack's four W cells). The
## cells block is the row less its head and its salvo ledge; the cell size derives from it
## with the fixed margin and gap.
func bay_cell_rect(index: int, row: Rect2) -> Rect2:
	var area := cells_area(row)
	var count: int = maxi(cell_columns, 1)
	var width: float = (area.size.x - float(count - 1) * cell_gap) / float(count)
	return Rect2(
		area.position + Vector2(float(index) * (width + cell_gap), 0.0),
		Vector2(maxf(width, 0.0), area.size.y)
	)


## The cells block of one rack row: right of the head, left of the salvo ledge, inset by the
## fixed cell margin.
func cells_area(row: Rect2) -> Rect2:
	var left: float = row.position.x + minf(row_head_width, row.size.x)
	var right: float = row.position.x + row.size.x - minf(row_salvo_width, row.size.x)
	return Rect2(
		Vector2(left + cell_margin, row.position.y + cell_margin),
		Vector2(
			maxf(right - left - cell_margin * 2.0, 0.0),
			maxf(row.size.y - cell_margin * 2.0, 0.0)
		)
	)


## A rack row's salvo ledge: the block its `ui_seg_*` cells and the `SALVO s` caption sit
## in, at the row's right.
func ledge_rect(row: Rect2) -> Rect2:
	return Rect2(
		Vector2(row.position.x + row.size.x - minf(row_salvo_width, row.size.x), row.position.y),
		Vector2(minf(row_salvo_width, row.size.x), row.size.y)
	)


## One salvo drum cell's rect inside its ledge.
func salvo_cell_rect(index: int, ledge: Rect2) -> Rect2:
	return Rect2(
		ledge.position + Vector2(float(index) * salvo_pitch, (ledge.size.y - salvo_cell.y) * 0.5),
		salvo_cell
	)


## The `SALVO s` caption's own origin inside the ledge (left edge, vertically centred):
## to the right of the drum block.
func salvo_caption_pos(ledge: Rect2) -> Vector2:
	var block: float = 0.0
	if salvo_cells > 0:
		block = float(salvo_cells - 1) * salvo_pitch + salvo_cell.x
	return ledge.position + Vector2(maxf(block, salvo_caption_left), ledge.size.y * 0.5)


## The wells band inside `console` (P34/P36): a fixed-height band at the console's foot,
## holding the read-only empty-cell list (left) and the mode's own summary (right).
func wells_rect(console: Rect2) -> Rect2:
	return Rect2(
		console.position + Vector2(band_side, maxf(console.size.y - wells_height, 0.0)),
		Vector2(
			maxf(console.size.x - band_side * 2.0, 0.0),
			minf(wells_height, console.size.y)
		)
	)


## One half of the wells band (0 = barrel inventory, 1 = ammunition).
func well_half_rect(half: int, console: Rect2) -> Rect2:
	var wells := wells_rect(console)
	var width: float = (wells.size.x - wells_gutter) * 0.5
	return Rect2(
		wells.position + Vector2(float(half) * (width + wells_gutter), 0.0),
		Vector2(maxf(width, 0.0), wells.size.y)
	)


## One item's rect inside a half's grid: `item_columns` x `item_rows`, row-major, on the
## fixed gap; the cells split the given rect's own width and height (the panel passes the
## half less its caption band).
func item_rect(index: int, grid: Rect2) -> Rect2:
	var columns: int = maxi(item_columns, 1)
	var rows: int = maxi(item_rows, 1)
	var width: float = (grid.size.x - float(columns - 1) * item_gap) / float(columns)
	var height: float = (grid.size.y - float(rows - 1) * item_gap) / float(rows)
	var column: int = index % columns
	var row: int = floori(float(index) / float(columns))
	return Rect2(
		grid.position + Vector2(float(column) * (width + item_gap), float(row) * (height + item_gap)),
		Vector2(width, height)
	)


## A rack row head's state chip, right-aligned in the row's head block.
func head_chip_rect(row: Rect2) -> Rect2:
	var head := bay_head_rect(row)
	return Rect2(
		Vector2(head.position.x + head.size.x - head_chip.x - cell_margin, head.position.y + (head.size.y - head_chip.y) * 0.5),
		head_chip
	)


## The whole band an item's icon occupies, vertically centred in the item (left side).
func item_icon_rect(item: Rect2) -> Rect2:
	return Rect2(
		item.position + Vector2(8.0, (item.size.y - item_icon) * 0.5),
		Vector2(item_icon, item_icon)
	)


func _axis(value: float, base: float) -> float:
	return value / maxf(base, 1.0)


func _scale(value: float, factor: float) -> float:
	return value * factor


func _to_string() -> String:
	return "ArmoryStyle(host=%s console=%s art_scale=%s bays=%s)" % [
		host_base, console_size_at_base(), art_scale, bay_columns
	]
