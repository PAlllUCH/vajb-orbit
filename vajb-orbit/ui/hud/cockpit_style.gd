class_name CockpitStyle
extends Resource
## UI_SPEC section 3.9 rule 5 (amendment 2026-09-24, wave D7), owner: "make sure that it is
## easily modified by the user in the future, like different styles, layout etc": the one
## Resource every cockpit-family surface reads its colours, layout metrics and asset paths
## from. Nothing in the cluster is hardcoded - a user drops
## `res://ui/hud/cockpit_style_user.tres` in and the surface restyles and relayouts with no
## code edit (`load_style` prefers that file when it exists).
##
## **Defaults are UI_SPEC's own numbers.** The palette's default values are the section 1
## colour tokens and the field names are those tokens' own names, so this file is the
## cockpit family's one place for them, exactly as `ui/theme/vajb_theme.tres` is for every
## other surface - no hex literal appears anywhere else in the family. `panel_steel` is the
## section 3.7/3.9 painted-metal family's own tone (the design report's Panel-Steel
## #2a2e35), and the two derived tones (`lamp_fill`, `recess_edge`) are computed from the
## tokens rather than written down. The layout defaults are section 3.7's Mockup v5/v7
## numbers: box 464x256, band 32, bays 126/104/156, gutters 7, drum 20x36 on a 22 px pitch,
## label zone 36 at 11 px, dials r 36 at (214,78) and (214,181), lamps 22 on 3 px gaps.
##
## The derived geometry (`interior`, `left_bay`, `middle_bay`, `right_bay`, `foot_well`,
## `readout_well`, `row_rect`, `gauge_centre`, `lamp_origin`, ...) is computed here, once, so
## the cluster and its tests cannot disagree about where a well lands.
##
## Reversal: hardcoded tokens (the D6 status quo).

## The override path (section 3.9 rule 5): when this file exists the cluster loads it
## instead of the built-in defaults. Reversal: a differently-named path passed to
## `load_style`/`set_style_file`.
const USER_PATH: String = "res://ui/hud/cockpit_style_user.tres"

## This file, reached by path so the family still parses in a headless gate whose global
## class table predates it (the reason `hud.gd` preloads the D6 status screen the same way).
const SCRIPT_PATH: String = "res://ui/hud/cockpit_style.gd"

## The role names the surfaces ask for, in section 1's vocabulary. `panel_steel` is the
## painted-metal family's own tone; the rest are the section 1 tokens.
const ROLE_VOID_BASE: StringName = &"void_base"
const ROLE_VOID_PANEL_RAISED: StringName = &"void_panel_raised"
const ROLE_METAL_DARK: StringName = &"metal_dark"
const ROLE_METAL_MID: StringName = &"metal_mid"
const ROLE_METAL_LIGHT: StringName = &"metal_light"
const ROLE_TEXT_PRIMARY: StringName = &"text_primary"
const ROLE_TEXT_DIM: StringName = &"text_dim"
const ROLE_DANGER: StringName = &"accent_danger"
const ROLE_DANGER_BRIGHT: StringName = &"accent_danger_bright"
const ROLE_PANEL_STEEL: StringName = &"panel_steel"
## STYLE_BIBLE section 2.4's Bone Text - section 3.9 rule 2's "Bone/Panel-Steel palette".
const ROLE_BONE: StringName = &"bone"

@export_group("palette")
## Panel-Steel (section 3.7/3.9's painted plate family); also the fallback fill when the
## panel texture does not resolve.
@export var panel_steel: Color = Color("#2a2e35")
## The recess interior behind every well - section 1's `void_base`.
@export var void_base: Color = Color("#07090d")
## An unlit lamp's fill - section 1's `void_panel_raised`.
@export var void_panel_raised: Color = Color("#10151d")
## A recess's top/left shadow edge and an unlit lamp's border - `metal_dark`.
@export var metal_dark: Color = Color("#1b2028")
## The dial hub, a resting wedge and the plate seam - `metal_mid`.
@export var metal_mid: Color = Color("#2a313c")
## A lit wedge and a recess's bottom/right lit edge - `metal_light`.
@export var metal_light: Color = Color("#3d4654")
## Row labels once they carry a read, lamp captions, the dial needle - `text_primary`.
@export var text_primary: Color = Color("#c9d1dc")
## The row labels' default and every unlit mark - `text_dim`.
@export var text_dim: Color = Color("#6b7484")
## The danger frame on a row and a danger dial's lit arc - `accent_danger`.
@export var accent_danger: Color = Color("#c8471f")
## A danger dial's needle and the lit lamp's border and caption - `accent_danger_bright`.
@export var accent_danger_bright: Color = Color("#e8622a")
## STYLE_BIBLE section 2.4's Bone Text (`#c9cdd2`) - section 3.9 rule 2's "Bone/Panel-Steel
## palette". It is not a section 1 token: it is the painted-metal family's own heading/value
## tone and it colours the section 3.8 hardpoint markers' ring (the bone-ringed ember dots).
@export var bone: Color = Color("#c9cdd2")

@export_group("layout")
## Section 3.7: the cluster's outer box (the panel master is 2x this, no nine-slice).
@export var box_size: Vector2 = Vector2(464.0, 256.0)
## The painted band around the interior (section 3.7: 32 logical, the logical half of the
## master's 64 px band).
@export var band: float = 32.0
@export var bay_left: float = 126.0
@export var bay_middle: float = 104.0
@export var bay_right: float = 156.0
@export var gutter: float = 7.0
## A recess well's inset from its bay rect (and from the interior's foot).
@export var well_inset: float = 3.0
## The unified interior foot band (Mockup v5 delta 1: every readout row is this tall).
@export var foot_height: float = 36.0
@export var row_height: float = 36.0
## Section 3.7 Mockup v7: the four readout rows spread evenly, pitch 50.7.
@export var row_pitch: float = 50.7
## The first row's inset from the interior's top edge.
@export var row_inset: float = 1.0
## The readout row block's inset from the right bay's left edge.
@export var row_x_inset: float = 7.0
## Mockup v5 delta 3: the label zone widened 34 -> 36 so four-letter labels fit.
@export var label_zone: float = 36.0
@export var label_font_size: int = 11
## The digit drum cell (section 3.7's digit fit law) and its pitch.
@export var cell_size: Vector2 = Vector2(20.0, 36.0)
@export var cell_pitch: float = 22.0
## The 1 px state frame on a danger row (section 3.1/3.1b's row treatment).
@export var frame_width: float = 1.0
## The two value dials (Mockup v7): 36 px radius, their rims 23 px clear.
@export var dial_radius: float = 36.0
## The disc well's rim beyond the face; the two rims 23 px apart is this number's own
## consequence (103 - 2 x (36 + 4)).
@export var dial_rim: float = 4.0
@export var dial_top: Vector2 = Vector2(214.0, 78.0)
@export var dial_bottom: Vector2 = Vector2(214.0, 181.0)
@export var dial_wedges: int = 10
@export var dial_sweep_degrees: float = 270.0
@export var dial_needle_width: float = 2.0
@export var dial_hub_radius: float = 3.0
@export var dial_label_font_size: int = 12
## The left bay's gauge: the section 3.6 dial's own 120 x 120 box, centred in the bay's
## gauge area (the mockup's own Ø112 well cannot hold the pinned 120 px dial).
@export var gauge_size: Vector2 = Vector2(120.0, 120.0)
## The battery lamps (Mockup v5 delta 2): five 22 px squares on 3 px gaps (122 wide).
@export var lamp_count: int = 5
@export var lamp_size: float = 22.0
@export var lamp_gap: float = 3.0
@export var lamp_font_size: int = 11
@export var lamp_corner: float = 2.0

## Section 3.8's ship status modal (amendment 2026-09-24, Mockup C). The box is the D6 pin
## (720 x 520); the three wells and the slot grid are `staging/mockup/mockup_rest.py`'s own
## 1:1 geometry, so the mockup and the surface cannot disagree.
@export var status_box: Vector2 = Vector2(720.0, 520.0)
## The left well: the hull side render (aspect-fit inside) + the hardpoint markers.
@export var status_well_left: Rect2 = Rect2(24.0, 60.0, 276.0, 368.0)
## The right well: the hull's slot grid.
@export var status_well_right: Rect2 = Rect2(316.0, 60.0, 380.0, 288.0)
## The footer strip: HULL / SHLD / PWR `cur / max`.
@export var status_footer: Rect2 = Rect2(24.0, 444.0, 672.0, 50.0)
## A well's inset for its content (the grid's origin, the render's fit area).
@export var status_well_inset: float = 16.0
## Mockup C's slot cell and pitch: 60 x 74 on a 72 x 88 pitch (a 5 x 3 grid fits the well
## exactly). A hull whose matrix is larger is scaled to fit rather than clipped
## (`status_grid_scale`).
@export var status_cell_size: Vector2 = Vector2(60.0, 74.0)
@export var status_cell_pitch: Vector2 = Vector2(72.0, 88.0)
## A cell's `W1..W5` ref Label: the mockup's own 6 / 4 px corner inset and the ref zone above
## the glyph, plus the glyph plate's own 28 x 32 box (centred under the ref zone).
@export var status_ref_inset: Vector2 = Vector2(6.0, 4.0)
@export var status_ref_zone: float = 26.0
@export var status_glyph_size: Vector2 = Vector2(28.0, 32.0)
@export var status_title_pos: Vector2 = Vector2(30.0, 22.0)
## The close box: 26 x 26, its left edge `status_close_margin` in from the box's right edge.
@export var status_close_size: Vector2 = Vector2(26.0, 26.0)
@export var status_close_margin: float = 52.0
## The `SLOT LAYOUT` caption (12 px below the right well) and the module rows under it; the
## rows scroll when a hull carries more than the band holds.
@export var status_caption_inset: float = 12.0
@export var status_caption_height: float = 18.0
@export var status_rows_inset: float = 4.0
## The footer labels' origins (Mockup C's own 40 / 250 / 470) and their top inset in the strip.
@export var status_footer_x: Array[float] = [40.0, 250.0, 470.0]
@export var status_footer_label_y: float = 14.0
@export var status_title_font_size: int = 20
@export var status_ref_font_size: int = 10
@export var status_row_font_size: int = 13
## Section 3.8's markers: 5 px radius, 1 px ring (the mockup's own dot).
@export var status_marker_radius: float = 5.0

@export_group("assets")
## The painted panel plate (a FLAT plate since UI_CHROME section 12 Amendment 2 - the wells
## are code-drawn). Master 928x512 for the 464x256 box.
@export var panel_path: String = "res://assets/ui/ui_cockpit_panel.png"
## The section 3.6 gauge's painted face and needle (masters 240x240 and 16x192), drawn by
## `Hud.Speedometer` under its code-drawn marks - the dial keeps the same fallbacks when a
## path here does not resolve.
@export var gauge_face_path: String = "res://assets/ui/ui_gauge_face.png"
@export var gauge_needle_path: String = "res://assets/ui/ui_gauge_needle.png"
## The twelve seven-segment cells: `<dir><prefix><cell>.png`.
@export var seg_dir: String = "res://assets/ui/"
@export var seg_prefix: String = "ui_seg_"
@export var seg_blank_cell: String = "blank"
@export var seg_pct_cell: String = "pct"
## Section 3.8's painted console panel (a FLAT plate since A1's re-render - the wells are
## code-drawn). Master 1440 x 1040 for the 720 x 520 box, 2x, never a nine-slice.
@export var status_panel_path: String = "res://assets/ui/ui_status_panel.png"
## The modal's close icon (the D6 cut, unchanged).
@export var close_icon_path: String = "res://assets/icons/hud/icon_close.svg"
## The RETIRED D6 nine-slice frame: section 3.8's amendment replaces it in the visible modal,
## but `test_d6_status.gd` pins its node, so it stays in the tree (hidden) and keeps it as
## this style's own path. Reversal: draw it again and drop the plate.
@export var status_legacy_frame_path: String = "res://assets/ui/ui_cockpit_frame.png"
## The retired frame master's 64 px band, drawn at half scale (the D6 read-back).
@export var status_legacy_frame_patch: int = 64
@export var status_legacy_frame_scale: float = 0.5


## The style a surface should use: the user's `.tres` when it exists, the built-in defaults
## otherwise (section 3.9 rule 5). A path that does not resolve is a silent fallback to the
## defaults rather than a broken cluster.
static func load_style(path: String = USER_PATH) -> Resource:
	var script := load(SCRIPT_PATH) as GDScript
	if not path.is_empty() and ResourceLoader.exists(path):
		var loaded: Resource = load(path)
		if loaded != null and loaded.get_script() == script:
			return loaded
	return script.new()


## A fresh default style (the shipped numbers), for a probe or a caller that wants to hand
## the cluster its own.
static func defaults() -> Resource:
	return (load(SCRIPT_PATH) as GDScript).new()


## One palette role by its section 1 name (`ROLE_*`); an unknown role is white, exactly as
## the D6 surfaces' own token lookup fell back.
func colour(role: StringName) -> Color:
	if role.is_empty():
		return Color.WHITE
	var value: Variant = get(role)
	return value if value is Color else Color.WHITE


## A lit lamp's dark-ember fill: derived from the ember so the lamp follows a restyle
## instead of carrying a tone of its own (section 3.7 Mockup v5 delta 2).
func lamp_fill(role: StringName) -> Color:
	var ember: Color = colour(role)
	return ember.darkened(0.75)


## The cell texture path for one `ui_seg_*` cut, from the three asset parts.
func seg_path(cell: String) -> String:
	return "%s%s%s.png" % [seg_dir, seg_prefix, cell]


## A texture at one of this style's paths, or null when the path does not resolve (the
## caller then draws its own fallback in `panel_steel`).
func texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


## The painted interior (section 3.7: 400 x 192 inside the 464 x 256 box with a 32 band).
func interior() -> Rect2:
	return Rect2(band, band, box_size.x - 2.0 * band, box_size.y - 2.0 * band)


## The three bays, in the order section 3.7 lists them, separated by `gutter`.
func left_bay() -> Rect2:
	var area := interior()
	return Rect2(area.position.x, area.position.y, bay_left, area.size.y)


func middle_bay() -> Rect2:
	var area := interior()
	return Rect2(area.position.x + bay_left + gutter, area.position.y, bay_middle, area.size.y)


func right_bay() -> Rect2:
	var area := interior()
	return Rect2(area.end.x - bay_right, area.position.y, bay_right, area.size.y)


## The left bay's foot recess: the battery lamps band, one `foot_height` band inside the
## interior's foot with a `well_inset` shadow gap below it (Mockup v7: the left foot keeps
## only the lamps band).
func foot_well() -> Rect2:
	var bay := left_bay()
	var area := interior()
	return Rect2(
		bay.position.x, area.end.y - well_inset - foot_height, bay.size.x, foot_height
	)


## The gauge's well centre: the left bay's own gauge area (interior top to foot well)
## centred both ways.
func gauge_centre() -> Vector2:
	var bay := left_bay()
	var top: float = bay.position.y
	var bottom: float = foot_well().position.y
	return Vector2(bay.position.x + bay.size.x * 0.5, top + (bottom - top) * 0.5)


## The gauge well's radius: the pinned 120 x 120 dial fits it exactly.
func gauge_well_radius() -> float:
	return gauge_size.x * 0.5


## The lamps band's own width (five 22 px lamps on 3 px gaps = 122).
func lamp_width() -> float:
	return lamp_count * lamp_size + maxf(lamp_count - 1, 0) * lamp_gap


## The lamps band's top-left corner, centred in the foot well.
func lamp_origin() -> Vector2:
	var foot := foot_well()
	return Vector2(
		foot.position.x + (foot.size.x - lamp_width()) * 0.5,
		foot.position.y + (foot.size.y - lamp_size) * 0.5
	)


## The rect of one lamp (anchored at `lamp_origin`, `lamp_size` square, `lamp_gap` apart).
func lamp_rect(index: int) -> Rect2:
	var origin := lamp_origin()
	return Rect2(origin.x + index * (lamp_size + lamp_gap), origin.y, lamp_size, lamp_size)


## The drawn width of one readout row: the label zone plus the drums, the last drum's
## trailing gap trimmed (section 3.7: the right bay's rows are 122 wide at four cells).
func row_width(cells: int) -> float:
	return label_zone + cells * cell_pitch - (cell_pitch - cell_size.x)


## The first readout row's top edge and the row block's left edge.
func rows_top() -> float:
	return interior().position.y + row_inset


func row_x() -> float:
	return right_bay().position.x + row_x_inset


## One readout row's rect, `index` counted from the top of the stack.
func row_rect(index: int, cells: int) -> Rect2:
	return Rect2(row_x(), rows_top() + index * row_pitch, row_width(cells), row_height)


## One drum cell's rect inside its row, at the cell pitch.
func cell_rect(index: int) -> Rect2:
	return Rect2(label_zone + index * cell_pitch, 0.0, cell_size.x, cell_size.y)


## The bottom of the last row of a `count`-row stack (the foot band's bottom edge).
func rows_bottom(count: int) -> float:
	return rows_top() + maxf(count - 1, 0) * row_pitch + row_height


## The right bay's readout well: full interior height, from the top frame's bottom edge to
## the row stack's own bottom (Mockup v7's own owner wording).
func readout_well(count: int) -> Rect2:
	var bay := right_bay()
	return Rect2(
		bay.position.x + well_inset,
		interior().position.y,
		bay.size.x - 2.0 * well_inset,
		rows_bottom(count) - interior().position.y
	)


## A value dial's disc well radius (the face plus the rim).
func dial_well_radius() -> float:
	return dial_radius + dial_rim


## The clear gap between the two dial wells' rims (Mockup v7: 23 px).
func dial_clearance() -> float:
	return absf(dial_bottom.y - dial_top.y) - 2.0 * dial_well_radius()


## The whole dial sweep, in radians, from the bottom-left gap edge (section 3.6's own
## 135 degree start: the gap sits at the bottom).
func dial_sweep() -> float:
	return deg_to_rad(dial_sweep_degrees)


func dial_start() -> float:
	return deg_to_rad(135.0)


## The cluster's code-drawn wells in paint order: the left bay's gauge disc, its foot band,
## the two dial discs and the right bay's readout well. A probe (and the mount test) reads
## the same list the painter walks.
func wells(readout_rows: int) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var gauge := gauge_centre()
	var radius := gauge_well_radius()
	out.append(Rect2(gauge - Vector2(radius, radius), Vector2(radius, radius) * 2.0))
	out.append(foot_well())
	var rim := dial_well_radius()
	for centre: Vector2 in [dial_top, dial_bottom]:
		out.append(Rect2(centre - Vector2(rim, rim), Vector2(rim, rim) * 2.0))
	out.append(readout_well(readout_rows))
	return out


## The ship status modal's three code-drawn wells, in paint order: the left render well, the
## right slot well and the footer strip. A probe (and the mount test) reads the same list the
## painter walks.
func status_wells() -> Array[Rect2]:
	var out: Array[Rect2] = [status_well_left, status_well_right, status_footer]
	return out


## The left well's render area: the well inset by `status_well_inset` (the hull side render is
## aspect-fit into it, section 3.8's amendment).
func status_render_area() -> Rect2:
	return status_well_left.grow(-status_well_inset)


## The slot grid's own origin: the right well's top-left, inset.
func status_grid_origin() -> Vector2:
	return status_well_right.position + Vector2(status_well_inset, status_well_inset)


## The area the slot grid may fill (the right well, inset).
func status_grid_inner() -> Rect2:
	return status_well_right.grow(-status_well_inset)


## The gap between two slot cells (the pitch minus the cell).
func status_cell_gap() -> Vector2:
	return status_cell_pitch - status_cell_size


## The factor a `columns` x `rows` matrix is drawn at: 1.0 while the pinned 60 x 74 / 72 x 88
## geometry fits the well (a 5 x 3 matrix does, exactly), smaller for a hull with more cells so
## the whole matrix stays inside the well instead of being clipped. An empty matrix reads 1.0.
func status_grid_scale(columns: int, rows: int) -> float:
	if columns <= 0 or rows <= 0:
		return 1.0
	var gap := status_cell_gap()
	var natural := Vector2(
		columns * status_cell_size.x + maxf(columns - 1, 0) * gap.x,
		rows * status_cell_size.y + maxf(rows - 1, 0) * gap.y
	)
	var inner := status_grid_inner().size
	return minf(minf(inner.x / natural.x, inner.y / natural.y), 1.0)


## One drawn cell size for a `columns` x `rows` matrix.
func status_cell_size_for(columns: int, rows: int) -> Vector2:
	return status_cell_size * status_grid_scale(columns, rows)


## One drawn cell pitch for a `columns` x `rows` matrix.
func status_cell_pitch_for(columns: int, rows: int) -> Vector2:
	return status_cell_pitch * status_grid_scale(columns, rows)


## One cell's rect in the modal's own coordinates, `col` / `row` counted from the matrix's
## top-left (Mockup C: the first cell is the grid origin).
func status_cell_rect(col: int, row: int, columns: int, rows: int) -> Rect2:
	var pitch := status_cell_pitch_for(columns, rows)
	var cell := status_cell_size_for(columns, rows)
	var origin := status_grid_origin()
	return Rect2(origin + Vector2(col * pitch.x, row * pitch.y), cell)


## The rect the whole `columns` x `rows` matrix covers.
func status_grid_rect(columns: int, rows: int) -> Rect2:
	if columns <= 0 or rows <= 0:
		return Rect2(status_grid_origin(), Vector2.ZERO)
	var first := status_cell_rect(0, 0, columns, rows)
	var last := status_cell_rect(columns - 1, rows - 1, columns, rows)
	return Rect2(first.position, last.end - first.position)


## A cell's fitted-module glyph plate: the style's 28 x 32 box, centred under the ref zone.
func status_glyph_rect(col: int, row: int, columns: int, rows: int) -> Rect2:
	var scale := status_grid_scale(columns, rows)
	var cell := status_cell_rect(col, row, columns, rows)
	var glyph := status_glyph_size * scale
	return Rect2(
		Vector2(cell.position.x + (cell.size.x - glyph.x) * 0.5, cell.position.y + status_ref_zone * scale),
		glyph
	)


## A cell's ref Label inset and its ref zone, scaled with the cell.
func status_ref_inset_for(columns: int, rows: int) -> Vector2:
	return status_ref_inset * status_grid_scale(columns, rows)


func status_ref_zone_for(columns: int, rows: int) -> float:
	return status_ref_zone * status_grid_scale(columns, rows)


## The `SLOT LAYOUT` caption's rect, below the right well.
func status_caption_rect() -> Rect2:
	return Rect2(
		status_well_right.position.x,
		status_well_right.end.y + status_caption_inset,
		status_well_right.size.x,
		status_caption_height
	)


## The module rows' band: under the caption, down to the footer strip.
func status_rows_rect() -> Rect2:
	var caption := status_caption_rect()
	return Rect2(
		caption.position.x,
		caption.end.y + status_rows_inset,
		status_well_right.size.x,
		status_footer.position.y - caption.end.y - status_rows_inset * 2.0
	)


## The close box's rect, from the box's own right edge.
func status_close_rect() -> Rect2:
	return Rect2(
		Vector2(status_box.x - status_close_margin, status_title_pos.y - 2.0),
		status_close_size
	)


## One footer label's origin (`HULL` / `SHLD` / `PWR`), by index.
func status_footer_label_pos(index: int) -> Vector2:
	var x: float = (
		status_footer_x[index] if index >= 0 and index < status_footer_x.size() else status_footer.position.x
	)
	return Vector2(x, status_footer.position.y + status_footer_label_y)


func _to_string() -> String:
	return "CockpitStyle(box=%s bays=%s/%s/%s gutter=%s)" % [
		box_size, bay_left, bay_middle, bay_right, gutter
	]
