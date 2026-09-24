class_name ArmoryStyle
extends "res://ui/hud/cockpit_style.gd"
## UI_SPEC section 3.9 rule 5 for the ARMORY: the battery window's one style surface. It
## **extends `CockpitStyle`** (`ui/hud/cockpit_style.gd`), so the pane reads the palette,
## the `ui_seg_*` asset parts and the texture/colour lookups through the very same
## Resource the cluster uses - one palette, one asset idiom, no second colour store - and
## adds the armory's own **layout** (section 3.10's Mockup A rects) and **assets** (the
## console and the two plates) here.
##
## Every number is section 3.10's own, at the mockup's **logical** scale: Mockup A's canvas
## (`staging/mockup/mockup_rest.py`, 872 x 908) is a 2x render, so its pixels are halved
## here (bay 194x182 -> 97x91, slot 40x44 -> 20x22, a 42 px SALVO step -> 21, a 64 px ammo
## box -> 32). `art_scale` is section 10's own `@2x` recipe (a master is twice the logical
## box), so the console block is drawn at `canvas * art_scale` = **872x908** - the mockup's
## own canvas and exactly half the shipped `ui_armory_console` master (1744x1816).
##
## **The wells are the mockup's rects** (`racks_well` / `inventory_well` / `ammo_well`);
## a well may grow below its pinned height when its group holds more rows than the mockup
## drew (the pane is content-driven: up to five owned weapon ids, six ammo packs), and its
## pinned height is then the floor. `group_rect` is the one place that arithmetic lives, so
## the pane and its tests cannot disagree about where a group lands.
##
## A user drops `res://ui/station/armory_style_user.tres` in and the pane restyles and
## relayouts with no code edit. Reversal: the pane's D6/S5 theme-stylebox chrome.

## The override path (section 3.9 rule 5 for this surface; the cluster's own is
## `CockpitStyle.USER_PATH`).
const ARMORY_USER_PATH: String = "res://ui/station/armory_style_user.tres"
## This file, reached by path so the surface still parses in a headless gate whose global
## class table predates it (the family's own lesson).
const ARMORY_SCRIPT_PATH: String = "res://ui/station/armory_style.gd"

@export_group("armory layout")
## Section 10's `@2x` recipe: a master is this many times its logical box. The console block
## is drawn at `canvas * art_scale`, which is exactly half the shipped console master.
@export var art_scale: float = 2.0
## Mockup A's own canvas at the logical scale (the mockup is a 2x render).
@export var canvas: Vector2 = Vector2(436.0, 454.0)
## The band each group's caption occupies above its well (Mockup A: 30 px at 2x).
@export var caption_band: float = 15.0
## The three recessed wells, in Mockup A's own coordinates (`mockup_rest.py`'s rects, halved):
## BATTERY RACKS (30,122)-(842,512), INVENTORY (30,570)-(842,740), AMMUNITION (30,796)-(842,884).
@export var racks_well: Rect2 = Rect2(15.0, 61.0, 406.0, 195.0)
@export var inventory_well: Rect2 = Rect2(15.0, 285.0, 406.0, 85.0)
@export var ammo_well: Rect2 = Rect2(15.0, 398.0, 406.0, 68.0)
## The block's foot margin below the last well (Mockup A: 908 - 884 = 24 at 2x).
@export var block_foot: float = 12.0
## The rack bay plate: 97x91 logical (194x182 at 2x - the shipped master's own box), in a
## 4+3 grid at Mockup A's own offsets (`bay_origin` is relative to the racks well).
@export var bay_size: Vector2 = Vector2(97.0, 91.0)
@export var bay_gap: float = 4.0
@export var bay_origin: Vector2 = Vector2(7.0, 7.0)
@export var bay_columns: int = 4
## The W cells as machined slot recesses: four 20x22 on a 22 px pitch, Mockup A's own
## `x + 10 + s * 44`, `y + 38 .. y + 82` at 2x (`slot_origin` is relative to the bay).
@export var slot_count: int = 4
@export var slot_size: Vector2 = Vector2(20.0, 22.0)
@export var slot_pitch: float = 22.0
@export var slot_origin: Vector2 = Vector2(5.0, 19.0)
## The bay's engraved ledge and its SALVO strip: the mockup's `bevel(y + 96 .. y + 100)`,
## the `SALVO s` caption at `y + 112` and the three drums at `x + 64`, `y + 104`, step 42
## (all at 2x, `salvo_origin` relative to the bay's own top-left).
@export var ledge_offset: float = 48.0
@export var salvo_caption: String = "SALVO s"
@export var salvo_cells: int = 3
@export var salvo_cell: Vector2 = Vector2(20.0, 36.0)
@export var salvo_pitch: float = 21.0
@export var salvo_origin: Vector2 = Vector2(32.0, 52.0)
## The `SALVO s` caption's own origin inside the bay (the mockup: `x + 10`, `y + 112` at 2x).
@export var salvo_caption_origin: Vector2 = Vector2(5.0, 56.0)
@export var salvo_caption_font_size: int = 12
## The pane's own two row families (section 3.10): inventory rows 22 tall with a 20 x 18
## icon slot, ammunition rows 32 tall.
@export var inventory_row_height: float = 22.0
@export var inventory_icon: Vector2 = Vector2(20.0, 18.0)
@export var ammo_row_height: float = 32.0
## The vertical gap between two rows of one group and between two bay rows.
@export var row_gap: float = 4.0
## A row plate's nine-slice margins, in **master** pixels (A0's own note for the 192 x 64
## master: 32/8/32/8 px leave a flat stretch zone and keep the left bolts whole).
@export var row_plate_margins: Vector4 = Vector4(32.0, 8.0, 32.0, 8.0)
## The 1 px danger frame on a row (section 3.1/3.1b's row treatment) and the 2 px ember
## frame on the selected bay (section 3.2's active-weapon precedent).
@export var danger_frame_width: float = 2.0
@export var selected_frame_width: float = 3.0

@export_group("armory assets")
## The painted console plate: a FLAT plate since UI_CHROME section 12 Amendment 2 (the wells
## are code-drawn), master 1744 x 1816 for the 872 x 908 block.
@export var console_path: String = "res://assets/ui/ui_armory_console.png"
## One rack bay's bolted plate: four machined slot recesses and a ledge, master 194 x 182.
@export var rack_plate_path: String = "res://assets/ui/ui_armory_rack_plate.png"
## The invented/ammunition rows' brushed strip (a nine-slice, flat bands only), master 192 x 64.
@export var row_plate_path: String = "res://assets/ui/ui_armory_row_plate.png"


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


## The console block's drawn size: the logical canvas at section 10's `@2x` scale (872 x 908).
func block_size() -> Vector2:
	return canvas * art_scale


## A logical length in drawn pixels.
func drawn(value: float) -> float:
	return value * art_scale


func drawn_vector(value: Vector2) -> Vector2:
	return value * art_scale


func drawn_rect(rect: Rect2) -> Rect2:
	return Rect2(rect.position * art_scale, rect.size * art_scale)


## The three wells in Mockup A's order: BATTERY RACKS, INVENTORY, AMMUNITION.
func pinned_wells() -> Array[Rect2]:
	var out: Array[Rect2] = [racks_well, inventory_well, ammo_well]
	return out


## One group's own box: its caption band above its well, with the well grown to
## `content_height` when the group holds more rows than the mockup drew (the pinned height
## is the floor). `offset` is the accumulated growth of every group above this one, so a
## grown group pushes the ones below it down instead of overlapping them.
func group_rect(index: int, content_height: float = 0.0, offset: float = 0.0) -> Rect2:
	var well: Rect2 = pinned_wells()[index]
	var height: float = maxf(well.size.y, content_height)
	return Rect2(well.position.x, well.position.y - caption_band + offset, well.size.x, caption_band + height)


## The well a group actually draws (the same rect `group_rect` opens up, without the caption).
func drawn_well(index: int, content_height: float = 0.0, offset: float = 0.0) -> Rect2:
	var group := group_rect(index, content_height, offset)
	return Rect2(group.position.x, group.position.y + caption_band, group.size.x, group.size.y - caption_band)


## How much a group grew past its pinned well height, 0 when it fits.
func growth(index: int, content_height: float = 0.0) -> float:
	return maxf(content_height - pinned_wells()[index].size.y, 0.0)


## One rack bay's rect inside the racks well (the mockup's 4+3 grid, `columns` per row):
## `index` is the rack's own ordinal, so B1..B7 place by the same rule.
func bay_rect(index: int) -> Rect2:
	var well: Rect2 = racks_well
	var columns: int = maxi(bay_columns, 1)
	var column: int = index % columns
	var row: int = floori(float(index) / float(columns))
	return Rect2(
		well.position.x + bay_origin.x + column * (bay_size.x + bay_gap),
		well.position.y + bay_origin.y + row * (bay_size.y + bay_gap),
		bay_size.x,
		bay_size.y
	)


## How many bay rows a rack count needs.
func bay_row_count(count: int) -> int:
	if count <= 0:
		return 0
	return int(ceil(float(count) / float(maxi(bay_columns, 1))))


## The bay grid's own height for `count` racks (what the racks well must hold).
func bay_grid_height(count: int) -> float:
	var rows: int = bay_row_count(count)
	if rows <= 0:
		return 0.0
	return float(rows) * bay_size.y + float(rows - 1) * bay_gap


## One W cell's rect inside its bay (`slot_origin` + `slot_pitch` per cell).
func slot_rect(index: int) -> Rect2:
	return Rect2(
		slot_origin.x + index * slot_pitch, slot_origin.y, slot_size.x, slot_size.y
	)


## One SALVO drum cell's rect inside its bay (three cells on Mockup A's own step).
func salvo_cell_rect(index: int) -> Rect2:
	return Rect2(
		salvo_origin.x + index * salvo_pitch, salvo_origin.y, salvo_cell.x, salvo_cell.y
	)


## The three SALVO cells' own width, so the strip can be centred or bounded.
func salvo_width() -> float:
	if salvo_cells <= 0:
		return 0.0
	return float(salvo_cells - 1) * salvo_pitch + salvo_cell.x


## One group's content height: `rows` rows of `row_height` with `row_gap` between them.
func rows_height(rows: int, row_height: float) -> float:
	if rows <= 0:
		return 0.0
	return float(rows) * row_height + float(rows - 1) * row_gap


## The row plate's nine-slice margins as `(left, top, right, bottom)` - the Vector4 is kept
## in the export so a user `.tres` can move them, this is the one reader.
func row_plate_sides() -> Array[float]:
	return [
		row_plate_margins.x, row_plate_margins.y, row_plate_margins.z, row_plate_margins.w
	]


func _to_string() -> String:
	return "ArmoryStyle(canvas=%s art_scale=%s wells=%s bays=%s)" % [
		canvas, art_scale, pinned_wells(), bay_size
	]
