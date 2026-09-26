extends Control
## ARMORY (the OUTFITTING pane renamed, STATION_HUB section 5.11's 2026-09-23 S5
## amendment) as **UI_SPEC section 3.10 Amendment 3 (the D13 rework, wave S18)** rules its
## layout: the **landscape console 1360x516** at the pinned (452,214)+1392x610 host, five
## **2x2-cell** bays across the top, and one wells band below - the barrel inventory left,
## the ammunition pack cards right. The console's rect is **derived from the host rect at
## runtime (P6)**: no pane rect is a constant, so the pane reflows at every window size
## (`ArmoryStyle.console_rect`).
##
## **Amendment 4 (2026-09-26, wave S20) rules the surface.** The scripted console master
## retires from the pane (the file stays on disk; the **module host's own panel frame is
## the pane's outer edge**), the bay cards, wells halves and pack/row plates wear the
## theme's **`ui_panel_frame`** nine-patch (A4.1), the bay cells the **`ui_slot_weapon_*`**
## slot chrome (A4.2), `BUY`/`X` the **`StationButton`** plates, and every palette field
## resolves from the theme's `Tokens/armory_*` (`ArmoryStyle.resolve_theme`, A4.3).
##
##   - **BAYS** - racks `B1..B5`, one drop zone per `weapon_1..5` key (09 section 11,
##     CONTRACTS section 17; 09 section 12's 5x4 hardcap). A rack holds the W cells that
##     fire together; each bay draws four slot-chrome cells (A4.2), prints the full barrel
##     name at 13 px on a fitted cell and `DROP HERE` on an empty one, and carries its
##     salvo readout on the ledge (`ui_seg_*` hundredths of a second beside `SALVO s`)
##     and its `READY` / `OVER CAP` state chip on the head. Dragging an inventory weapon
##     onto a bay installs it into the rack's next free W cell through the profile's
##     composed `fit_into_rack` (the section 13/16 transactions: `fit_legal` and the
##     mandatory set are checked before the first write, a refusal writes nothing). A
##     barrel drags within/between racks to re-order and swap; the `x` on a fitted cell
##     (or a right-click, the chrome's own hint) returns it to the inventory.
##   - **BARREL INVENTORY** - one row per owned weapon **id** (aggregated, catalogue
##     order) in the wells band's left half, each one a drag source.
##   - **AMMUNITION** - one card per `StationCatalog.AMMO_PACKS` entry in the right half
##     (two columns of three), buying **cargo units** (`units = rounds /
##     ROUNDS_PER_CARGO_UNIT`) through `PlayerProfile.buy_ammo`; the card carries the
##     worded held line (P5: `HELD 60 ROUNDS - HOLD 30 UNITS`) and the section 5.1 state
##     tag and state line.
##
## **Surface only** (section 3.10): the pane's signals, transactions, drag-drop behaviour
## and the refusal-writes-nothing rule are untouched - every seam and number of STATION_HUB
## section 5.11, 09 section 11/12 and CONTRACTS section 17 survives. Every colour, layout
## metric and asset path comes from `ArmoryStyle` (`ui/station/armory_style.gd`), which
## extends `CockpitStyle` (section 3.9 rule 5): one palette, one asset idiom, and a user
## `.tres` restyles and relayouts the pane with no code edit. **No font size is overridden**
## (HIGH-1's cure): every label reads its size from a theme variation registered in
## `Router.FONT_SIZE_ITEMS` (13 px `StationCaption` throughout, the title 20).
##
## The panel never writes the store directly (STATION_HUB section 12.4): it calls the
## profile's composed APIs, `fit_for`/`resolved_fit`/`instances_of`/`battery_groups`/
## `free_weapon_cell` and `ShipFit.*`, and reports every refusal through its footer.
##
## Panel contract with the shell:
##   signal status_requested(message: String, danger: bool)   write the footer strip
##   signal inspect_requested(title: String, body: String, danger: bool) the inspector
##   func refresh_profile(key: StringName) -> void             react to profile_changed
##   func focus_primary() -> void                              focus entry after a switch

const StyleScript := preload("res://ui/station/armory_style.gd")

const TOKENS_TYPE: StringName = &"Tokens"

const Catalog := preload("res://game/station_catalog.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")
const ModuleData := preload("res://game/module_catalog.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"

signal status_requested(message: String, danger: bool)
## CONTRACTS section 23.1: emitted when the pointer lands on or leaves a catalogue row
## (an ammunition card, an owned-weapon row or a fitted barrel). `title` is the row's
## identity line, `body` its catalogue description - a fitted barrel's carries a second
## line with its salvo/dps facts (P4) - and `danger` colours the title. `title == ""`
## clears the shell's inspector block.
signal inspect_requested(title: String, body: String, danger: bool)

## The three refusal wordings, byte-equivalent to `ui/station/fitting_panel.gd:147-149`
## (CONTRACTS section 16 rule 9, the L116 precedent): ARMORY may not preload the pane
## whose constants are the pin's single home, so it declares its own twins. The overload
## line takes `fit_legal`'s own power numbers; the mandatory wording is **unreachable for
## a W cell** (`FitData.MANDATORY_SLOT_KEYS` is `[engines, power]`, game/ship_fit.gd:117)
## and is carried for the set's completeness only, so no test may assert it through a
## rack. The fourth line is the P2-B1 strip's own `W SLOTS FULL - SWAP OR REMOVE FIRST`,
## kept for the states it names: every W cell of the hull already holds a barrel, and --
## since S15's hardcap -- one battery's four cells are all taken (09 section 12).
const REFUSAL_OVERLOAD := "%d / %d PWR — OVER BY %d"
const REFUSAL_MANDATORY := "MANDATORY CELL — SWAP ONLY, NEVER EMPTY"
const REFUSAL_FIT_ILLEGAL := "REFUSED · FIT ILLEGAL"
const REFUSAL_W_SLOTS_FULL := "W SLOTS FULL — SWAP OR REMOVE FIRST"
const REFUSAL_NO_WEAPONS := "NO WEAPONS IN THE INVENTORY"
const STATUS_INSTALLED := "INSTALLED · %s · %s"
const STATUS_MOVED := "MOVED · %s · %s"
const STATUS_REMOVED := "REMOVED · %s · BACK IN INVENTORY"

## The pane's own chrome, in the D13 mockup's words (the chrome line and the caption
## line). The subtitle counts the racks the pane draws (`GROUPS_MAX`, `game/weapons.gd`)
## and the packs the catalogue carries, so neither figure can go stale.
const SUBTITLE := "BATTERY RACKS AND AMMUNITION - %d RACKS - %d PACKS"
const PANE_HINT := "DRAG TO FIT - RIGHT-CLICK TO PULL - 1-5 SELECT RACK"
const TAG_LIST_PREFIX := "IDS "
const TAG_LIST_SEPARATOR := " · "

## The rack column (09 section 11/12): `B1..B5`, one drop zone per `weapon_1..5` key.
const WEAPON_SLOT: StringName = &"weapons"
const POWER_SLOT: StringName = &"power"
const RACK_COUNT: int = WeaponComponent.GROUPS_MAX
const RACK_LABEL := "B%d"
const RACK_KEY := "(%d)"
const RACK_ACTION := "weapon_%d"
## The empty cell's cue (T4) and the bay's state chip (T7): the chip states `READY`, or
## `OVER CAP` when the battery holds the hardcap's four cells - shape (chevron) plus
## label, never colour alone.
const RACK_INSTALL_CUE := "DROP HERE"
const RACK_READY := "READY"
const RACK_STATE_OVER := "OVER CAP"
const RACK_SALVO := "SALVO %.1f s"
const BARREL_TEXT := "W%d %s"
const BARREL_CLOSE := "✕"
const INVENTORY_EMPTY := "NO WEAPONS IN THE INVENTORY · BUY THEM IN THE AUCTION"
const INVENTORY_TEXT := "%s  ×%d"
const INVENTORY_CAPTION := "BARREL INVENTORY - %d OWNED"
const AMMO_CAPTION := "AMMUNITION - %d PACKS"

## The SALVO drum's approved figure (Mockup A, owner "Looks good" 2026-09-24; T8 keeps
## it): the cycle in **hundredths of a second**, three cells, zero-padded (`073` =
## 0.73 s). A cycle of 0 s has no figure and reads blanks.
const SALVO_MAX := 999

## The pack card's own lines (P5, MED-1/2's cures): the worded held line, the price's
## unit word (the section 5.1 `CREDITS` caption became the `CR` word beside the number),
## and the `BUY` chip.
const HELD_FORMAT := "HELD %d ROUNDS - HOLD %d UNITS"
const PRICE_FORMAT := "%s CR"
const ROUNDS_CAPTION := "%d ROUNDS PER PACK"
const BUY_CHIP := "BUY"
const TAG_EMPTY := "EMPTY"
const TAG_IN_STOCK := "IN STOCK"
const TAG_AT_CAP := "AT CAP"
const TAG_OVER_CAP := "OVER CAP"
const TAG_UNAVAILABLE := "STOCK UNAVAILABLE"
const META_NO_ROUNDS := "NO ROUNDS HELD"
const META_ADVISORY := "CAPACITY IS ADVISORY"
const META_NO_CAP := "NO PURCHASE CAP"
const META_BELOW_CAPACITY := "BELOW CAPACITY"
const META_INCOMPLETE := "CATALOGUE ENTRY INCOMPLETE"
const UNAVAILABLE_VALUE := "0"
const STATUS_HINT := "ENTER BUY · %s · %s CREDITS"

## CONTRACTS section 23.1: the inspector's own identity line - the same name and price
## phrase as `STATUS_HINT`, joined by the pane's own separator, with the leading key-hint
## verb dropped so the always-visible title is the row, not the action.
const INSPECT_TITLE_FORMAT := "%s · %s CREDITS"
## The fitted barrel's inspector body: the catalogue description, then a facts line
## (P4/MED-3). The salvo figure is the family's own cycle (`WeaponComponent.interval_of`),
## `INSTANT` for the beam families that state none.
const INSPECT_STATS := "SALVO %s · DPS %.1f /s · FITTED IN %s W%d"
const STATS_INSTANT := "INSTANT"
const STATUS_BOUGHT := "PURCHASED · %s · +%d ROUNDS"

## A row's inner padding, in drawn pixels (the plates carry the chrome, not the margins).
const ROW_TEXT_INSET := 6.0
## The pack card's four 13 px lines at the base item height (68): the first line's top
## offset and the pitch between them (4 x 13 + 3 x 3 = 61, so every line and both chips sit
## inside the card). The card's own anatomy, not the style's (a restyle moves the grid, not
## the lines).
const CARD_LINE_FIRST := 1.0
const CARD_LINE_PITCH := 16.0

## The drag payloads (`_get_drag_data` / `_can_drop_data` / `_drop_data`):
## an inventory row carries its base id, a barrel its address in the racks.
const DRAG_INVENTORY: StringName = &"inventory"
const DRAG_BARREL: StringName = &"barrel"
const DRAG_KEY_KIND: StringName = &"kind"
const DRAG_KEY_BASE: StringName = &"base"
const DRAG_KEY_RACK: StringName = &"rack"
const DRAG_KEY_POSITION: StringName = &"position"
## A drop on the rack's own body rather than on one of its cells (the install route).
const DROP_RACK_BODY := -1

const ROW_ICON_IDLE_ALPHA := 0.72
const HOVER_SECONDS := 0.09
const PULSE_MIN_ALPHA := 0.35
const PULSE_DOWN_SECONDS := 0.12
const PULSE_UP_SECONDS := 0.16

## Audit anomaly C16: these three catalogue icons are flat Phase B glyphs (mean RGB about
## 40, 44, 47) that read as near-black shapes on the row chrome, so the row draws the
## derived icons/tint/ stencil moderated with Tokens/text_primary instead. Every other
## catalogue icon is painted and is drawn at full colour.
const FLAT_GLYPH_ICONS: Array[String] = [
	"res://assets/icons/weapon/icon_weapon_cannon.svg",
	"res://assets/icons/weapon/icon_weapon_mine.svg",
	"res://assets/icons/weapon/icon_weapon_plasma.svg",
]
const TINT_DIR := "res://assets/icons/tint/"

## The style roles this surface asks for, in section 1's own vocabulary (the style is the
## only colour store: section 3.9 rule 5).
const ROLE_TEXT_PRIMARY: StringName = &"text_primary"
const ROLE_DANGER: StringName = &"accent_danger"
const ROLE_DANGER_BRIGHT: StringName = &"accent_danger_bright"
const ROLE_METAL_LIGHT: StringName = &"metal_light"
const ROLE_METAL_MID: StringName = &"metal_mid"
const ROLE_METAL_DARK: StringName = &"metal_dark"
const ROLE_BONE: StringName = &"bone"
const ROLE_CAPTION: StringName = &"caption"
const ROLE_BAY_BG: StringName = &"bay_bg"
const ROLE_CELL_BG: StringName = &"cell_bg"
const ROLE_LEDGE_BG: StringName = &"ledge_bg"
const ROLE_ITEM_BG: StringName = &"item_bg"
const ROLE_CHIP_BG: StringName = &"chip_bg"
const ROLE_CHIP_DANGER_BG: StringName = &"chip_danger_bg"
const ROLE_FIT_LINE: StringName = &"fit_line"


## One barrel cell's name plate: the drag source of a barrel (S5, 09 section 11). The
## payload is its address in the racks, so a drop knows what is being moved without
## reading the tree it may be about to rebuild. Its own ink is transparent - the cell
## prints the full name on two 13 px labels (T3, HIGH-5's cure) while `text` stays the
## identity every read-back and tooltip uses.
class BarrelName extends Button:
	var armory: Control = null
	var rack := 0
	## The barrel's index in its rack's chip list ("position" is `Control`'s own).
	var slot := 0

	func _get_drag_data(_at: Vector2) -> Variant:
		if armory == null:
			return null
		return armory.call(&"drag_barrel", rack, slot)

	func _ready() -> void:
		clip_text = true

	func _gui_input(event: InputEvent) -> void:
		if armory == null:
			return
		if not (event is InputEventMouseButton):
			return
		var button := event as InputEventMouseButton
		if button.pressed and button.button_index == MOUSE_BUTTON_RIGHT:
			armory.call(&"remove_barrel", rack, slot)
			accept_event()


## One fitted cell: the drag source (the name plate), the visible name block, the `x` and
## a drop zone of its own - dropping a barrel **on** another barrel is the swap (09
## section 11's between-rack swap). The `x` in the top-right corner and a right-click
## anywhere on the cell are the two remove routes (both call `remove_barrel`).
class BarrelCell extends HBoxContainer:
	var armory: Control = null
	var rack := 0
	var slot := 0

	func _get_drag_data(_at: Vector2) -> Variant:
		if armory == null:
			return null
		return armory.call(&"drag_barrel", rack, slot)

	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		return armory != null and bool(armory.call(&"can_drop", rack, slot, data))

	func _drop_data(_at: Vector2, data: Variant) -> void:
		if armory != null:
			armory.call(&"drop", rack, slot, data)

	func _gui_input(event: InputEvent) -> void:
		if armory == null:
			return
		if not (event is InputEventMouseButton):
			return
		var button := event as InputEventMouseButton
		if button.pressed and button.button_index == MOUSE_BUTTON_RIGHT:
			armory.call(&"remove_barrel", rack, slot)
			accept_event()

	func _draw() -> void:
		if armory == null:
			return
		var style: Resource = armory.call(&"style")
		if style == null:
			return
		## The decorative ember fit line: a fitted cell is already marked by its own name
		## (T7's rule - no state is carried by colour alone).
		draw_line(
			Vector2(8.0, size.y - 6.0), Vector2(size.x - 8.0, size.y - 6.0),
			style.colour(ROLE_FIT_LINE), 2.0
		)
## One empty cell: the `DROP HERE` cue and the drop zone that installs a dragged
## inventory weapon into the rack's next free W cell (the body-drop route).
class DropCell extends Control:
	var armory: Control = null
	var rack := 0
	var slot := 0

	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		return armory != null and bool(armory.call(&"can_drop", rack, DROP_RACK_BODY, data))

	func _drop_data(_at: Vector2, data: Variant) -> void:
		if armory != null:
			armory.call(&"drop", rack, DROP_RACK_BODY, data)


## One rack: the `B<n>` label, its key hint, its state chip, its fitted cells and the
## drop zones that install a dragged inventory weapon. A press on the bay is the mouse
## half of the selection seam (STATION_HUB section 5.11's five selectable bays): it moves
## the section 3.2 ember frame and writes nothing.
class RackRow extends PanelContainer:
	var armory: Control = null
	var rack := 0

	func _gui_input(event: InputEvent) -> void:
		if not event.is_pressed():
			return
		if not (event is InputEventMouseButton):
			return
		if (event as InputEventMouseButton).button_index != MOUSE_BUTTON_LEFT:
			return
		if armory != null:
			armory.call(&"set_selected_rack", rack)

	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		return armory != null and bool(armory.call(&"can_drop", rack, -1, data))

	func _drop_data(_at: Vector2, data: Variant) -> void:
		if armory != null:
			armory.call(&"drop", rack, -1, data)


## One inventory row: a drag source carrying its base id, drawn from the catalogue and
## the bag. Its own `pressed` does nothing - the row is a handle, not an action.
class InventoryRow extends Button:
	var armory: Control = null
	var base_id: StringName = &""

	func _get_drag_data(_at: Vector2) -> Variant:
		if armory == null:
			return null
		return armory.call(&"drag_inventory", base_id)


## A chip: the rounded plate, its border and - for the OVER CAP state - the chevron that
## makes the state a shape as well as a label (T7, HIGH-3's cure).
class ChipPlate extends Control:
	var style: Resource = null
	var danger := false
	var chevron := false

	func configure(new_style: Resource, is_danger: bool, has_chevron: bool) -> void:
		style = new_style
		danger = is_danger
		chevron = has_chevron
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()

	func _draw() -> void:
		if style == null:
			return
		var box := StyleBoxFlat.new()
		box.bg_color = style.colour(ROLE_CHIP_DANGER_BG if danger else ROLE_CHIP_BG)
		box.corner_radius_top_left = 6
		box.corner_radius_top_right = 6
		box.corner_radius_bottom_left = 6
		box.corner_radius_bottom_right = 6
		draw_style_box(box, Rect2(Vector2.ZERO, size))
		draw_rect(
			Rect2(Vector2.ZERO, size),
			style.colour(ROLE_DANGER_BRIGHT if danger else ROLE_METAL_MID),
			false, style.frame_width
		)
		if chevron:
			var height: float = minf(size.y - 8.0, 12.0)
			var top := (size.y - height) * 0.5
			draw_colored_polygon(
				PackedVector2Array([
					Vector2(6.0, top + height),
					Vector2(11.0, top),
					Vector2(16.0, top + height),
				]),
				style.colour(ROLE_DANGER_BRIGHT)
			)


## One rack bay's code-drawn marks: the section 3.2 ember frame when this bay is the
## selected rack (the fitted cells are marked by their own names, T7).
class BayMarks extends Control:
	var style: Resource = null
	var filled: Array[int] = []
	var selected: bool = false

	func configure(new_style: Resource, new_filled: Array[int], is_selected: bool) -> void:
		style = new_style
		filled = new_filled
		selected = is_selected
		queue_redraw()

	func marked_cells() -> Array[int]:
		return filled

	func is_selected() -> bool:
		return selected

	func _draw() -> void:
		if style == null or not selected:
			return
		draw_rect(
			Rect2(Vector2.ZERO, size),
			style.colour(ROLE_DANGER_BRIGHT),
			false,
			style.selected_frame_width
		)


## One rack bay's SALVO strip: the engraved ledge, the three `ui_seg_*` drum cells and
## the 13 px `SALVO s` caption beside them (T8: no hidden head line - the digits and the
## label are adjacent).
class SalvoStrip extends Control:
	var style: Resource = null
	var _caption: Label = null
	var _cells: Array[TextureRect] = []
	var _seg: Array[Texture2D] = []
	var _blank: Texture2D = null
	var _shown: Array = []
	var _figure: int = -1

	func configure(new_style: Resource, segments: Array[Texture2D], blank: Texture2D) -> void:
		style = new_style
		_seg = segments
		_blank = blank
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		if _caption == null:
			_caption = Label.new()
			_caption.name = "Caption"
			_caption.theme_type_variation = &"StationCaption"
			_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(_caption)
		_caption.text = style.salvo_caption
		_caption.add_theme_color_override(&"font_color", style.colour(ROLE_CAPTION))
		var ledge := Rect2(Vector2.ZERO, size)
		_caption.position = style.salvo_caption_pos(ledge) - Vector2(0.0, 6.0)
		var cells: int = style.salvo_cells
		while _cells.size() > cells:
			var removed: TextureRect = _cells.pop_back()
			remove_child(removed)
			removed.queue_free()
		while _cells.size() < cells:
			var cell := TextureRect.new()
			cell.name = "Salvo%d" % _cells.size()
			cell.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			cell.stretch_mode = TextureRect.STRETCH_SCALE
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(cell)
			_cells.append(cell)
		for index: int in _cells.size():
			var rect: Rect2 = style.salvo_cell_rect(index, ledge)
			_cells[index].position = rect.position
			_cells[index].size = rect.size
		set_figure(_figure)
		queue_redraw()

	## The cycle figure in hundredths of a second, -1 for a rack with no travelling member
	## (blanks, never a zero figure that would read as 0.00 s).
	func set_figure(figure: int) -> void:
		_figure = figure
		_shown = _format(figure)
		for index: int in _cells.size():
			var digit: int = _shown[index]
			var cut: Texture2D = _blank
			if digit >= 0 and digit < _seg.size():
				cut = _seg[digit]
			_cells[index].texture = cut

	## The digits as drawn: 0..9 per cell, -1 for a blank.
	func cells() -> Array:
		return _shown.duplicate()

	func figure() -> int:
		return _figure

	## The three cells' own text, `"073"` style, for a probe that wants the readout.
	func figure_text() -> String:
		var text := ""
		for digit: int in _shown:
			text += "-" if digit < 0 else str(digit)
		return text

	func cell_nodes() -> Array[TextureRect]:
		return _cells

	func caption_node() -> Label:
		return _caption

	func _format(figure: int) -> Array:
		var out: Array = []
		for index: int in maxi(style.salvo_cells, 0):
			out.append(-1)
		if figure < 0:
			return out
		var text := str(clampi(figure, 0, SALVO_MAX))
		var count: int = mini(text.length(), out.size())
		var offset: int = out.size() - count
		## Mockup A's approved figure is zero-padded (`073` = 0.73 s), not blank-padded:
		## a cadence reads as a three-digit drum figure.
		for index: int in offset:
			out[index] = 0
		for index: int in count:
			out[offset + index] = text.substr(text.length() - count + index, 1).to_int()
		return out

	func _draw() -> void:
		if style == null:
			return
		var box := StyleBoxFlat.new()
		box.bg_color = style.colour(ROLE_LEDGE_BG)
		box.corner_radius_top_left = 6
		box.corner_radius_top_right = 6
		box.corner_radius_bottom_left = 6
		box.corner_radius_bottom_right = 6
		draw_style_box(box, Rect2(Vector2.ZERO, size))
		draw_rect(
			Rect2(Vector2.ZERO, size), style.colour(ROLE_METAL_MID), false, style.frame_width
		)
		for index: int in _cells.size():
			var rect := Rect2(_cells[index].position, _cells[index].size)
			draw_rect(rect, style.colour(ROLE_CELL_BG), true)


## One row's plate: the theme's `ui_panel_frame` nine-patch (A4.1, `PanelRaised`) with the
## section 3.1/3.1b danger frame over it when the row is in a danger state. Without the
## theme box the row's recorded recess tone returns (the palette's own reversal path).
class RowPlate extends Control:
	var style: Resource = null
	var _danger: bool = false

	func configure(new_style: Resource) -> void:
		style = new_style
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()

	## The danger treatment: a 1 px code-drawn frame in `accent_danger` - the digits
	## themselves never recolour (section 3.7's own rule, reused here verbatim).
	func set_danger(danger: bool) -> void:
		if _danger == danger:
			return
		_danger = danger
		queue_redraw()

	func danger() -> bool:
		return _danger

	func _draw() -> void:
		if style == null:
			return
		var frame: StyleBox = get_theme_stylebox(&"panel", &"PanelRaised")
		if frame != null:
			draw_style_box(frame, Rect2(Vector2.ZERO, size))
		else:
			var box := StyleBoxFlat.new()
			box.bg_color = style.colour(ROLE_ITEM_BG)
			box.corner_radius_top_left = 6
			box.corner_radius_top_right = 6
			box.corner_radius_bottom_left = 6
			box.corner_radius_bottom_right = 6
			draw_style_box(box, Rect2(Vector2.ZERO, size))
		draw_rect(
			Rect2(Vector2.ZERO, size),
			style.colour(ROLE_DANGER if _danger else ROLE_METAL_MID),
			false, style.frame_width
		)


## The console's own chrome, one node and one `_draw` pass, over the host's panel and
## under every interactive one. **Amendment 4:** the bay cards and the wells halves wear
## the theme's `ui_panel_frame` nine-patch (A4.1, `PanelRaised`), every bay cell the game's
## `ui_slot_weapon_*` slot chrome (A4.2, the `SlotButtonWeapon` family), and the salvo
## ledges keep their code-drawn band (A4.5: the seven-seg strip stands untouched).
class ConsolePanels extends Control:
	var style: Resource = null
	var bays: Array[Rect2] = []
	var cells: Array[Rect2] = []
	var ledges: Array[Rect2] = []
	var wells: Array[Rect2] = []
	## The theme's own chrome boxes, read fresh on every configure so a theme re-band moves
	## this pane with every sibling panel: the panel frame and the weapon slot plate.
	var frame_box: StyleBox = null
	var slot_box: StyleBox = null

	func configure(
		new_style: Resource,
		new_bays: Array[Rect2],
		new_cells: Array[Rect2],
		new_ledges: Array[Rect2],
		new_wells: Array[Rect2]
	) -> void:
		style = new_style
		bays = new_bays
		cells = new_cells
		ledges = new_ledges
		wells = new_wells
		frame_box = get_theme_stylebox(&"panel", &"PanelRaised")
		slot_box = get_theme_stylebox(&"normal", &"SlotButtonWeapon")
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()

	func _draw() -> void:
		if style == null:
			return
		for rect: Rect2 in wells:
			_frame(rect)
		for rect: Rect2 in bays:
			_frame(rect, ROLE_BAY_BG, 8)
		for rect: Rect2 in cells:
			_slot(rect)
		for rect: Rect2 in ledges:
			_plate(rect, ROLE_LEDGE_BG, 6)

	## Section 5.3's panel frame (A4.1): the `ui_panel_frame` nine-patch - 32 px patch
	## margin, the theme's 1 px border convention - so a bay card or a wells half reads as
	## every sibling panel. Without a theme box a bay's recorded recess tone returns (the
	## palette's own reversal path); a wells half simply draws nothing.
	func _frame(rect: Rect2, role: StringName = &"", radius: int = 0) -> void:
		if frame_box != null:
			draw_style_box(frame_box, rect)
		elif not role.is_empty():
			_plate(rect, role, radius)

	## A4.2: the cell wears the game's weapon-slot chrome - the `SlotButtonWeapon` family's
	## own plate, the one FITTING's slots draw (a `SlotButton` at the cell's box). Without
	## the theme's slot plate the pre-S20 machined recess returns.
	func _slot(rect: Rect2) -> void:
		if slot_box != null:
			draw_style_box(slot_box, rect)
			return
		_recess(rect)

	## A raised band: the fill plus a 1 px border.
	func _plate(rect: Rect2, role: StringName, radius: int) -> void:
		var box := StyleBoxFlat.new()
		box.bg_color = style.colour(role)
		box.corner_radius_top_left = radius
		box.corner_radius_top_right = radius
		box.corner_radius_bottom_left = radius
		box.corner_radius_bottom_right = radius
		draw_style_box(box, rect)
		draw_rect(rect, style.colour(ROLE_METAL_MID), false, style.frame_width)

	## A machined cell recess: the dark fill plus the two edge tones (top/left shadow,
	## bottom/right catch light) - the mockup's recess language, code-drawn.
	func _recess(rect: Rect2) -> void:
		var box := StyleBoxFlat.new()
		box.bg_color = style.colour(ROLE_CELL_BG)
		box.corner_radius_top_left = 6
		box.corner_radius_top_right = 6
		box.corner_radius_bottom_left = 6
		box.corner_radius_bottom_right = 6
		draw_style_box(box, rect)
		var width: float = style.frame_width
		var dark: Color = style.colour(ROLE_METAL_DARK)
		var light: Color = style.colour(ROLE_METAL_LIGHT)
		draw_line(rect.position, Vector2(rect.end.x, rect.position.y), dark, width, true)
		draw_line(rect.position, Vector2(rect.position.x, rect.end.y), dark, width, true)
		draw_line(Vector2(rect.position.x, rect.end.y), rect.end, light, width, true)
		draw_line(Vector2(rect.end.x, rect.position.y), rect.end, light, width, true)


@onready var _console: Control = %Console
## The scene's own nine-slice slot for the console master; **its texture is cleared at
## build** (A4.1: the master retires from the pane).
@onready var _plate: NinePatchRect = %ConsolePlate
@onready var _title: Label = %PaneTitle
@onready var _subtitle: Label = %PaneSubtitle
@onready var _hint: Label = %PaneHint
@onready var _tag: Label = %PanelTag
@onready var _rack_rows: VBoxContainer = %RackRows
@onready var _inventory_margin: Control = %InventoryMargin
@onready var _inventory_caption: Label = %InventoryCaption
@onready var _inventory_scroll: ScrollContainer = %InventoryScroll
@onready var _inventory_rows: Control = %InventoryRows
@onready var _ammo_margin: Control = %AmmoMargin
@onready var _ammo_caption: Label = %AmmoCaption
@onready var _ammo_scroll: ScrollContainer = %AmmoScroll
@onready var _rows: Control = %ArmoryRows

## The style in force (`ArmoryStyle`, a `CockpitStyle`): every colour, metric and asset
## path on this surface comes from here (section 3.9 rule 5).
var _style: Resource = null
## The console's chrome layer (the bays' and wells' frames, the cells' slot chrome and
## the salvo ledges); the code-drawn recess below is the fallback for a theme-less frame.
var _chrome: Control = null
## The twelve `ui_seg_*` cuts, shared by every bay's SALVO strip.
var _seg: Array[Texture2D] = []
var _seg_blank: Texture2D = null

var _payloads: Array[Dictionary] = []
## The rack chips and inventory rows the current frame drew, for the read-backs
## (`rack_rows()` / `inventory_rows()`) and for `focus_primary`'s walk. Both are
## rebuilt on every refresh: a rack's shape is player-composed, so it is not a fixed
## node set, and a freed chip is released with `queue_free` so the plate whose
## `_drop_data` started the write is still alive while that write finishes.
var _rack_views: Array[Dictionary] = []
var _inventory_views: Array[Dictionary] = []
var _selected_row: Button = null
var _tweens: Array[Tween] = []
## The selected rack (0-based), the bay that wears the section 3.2 ember frame - the same
## rack ordinal the cluster's lamp lights. It follows focus and never writes anything.
var _selected_rack: int = 0


func _ready() -> void:
	_build_console()
	_build_rows()
	_build_racks()
	_build_inventory()
	_apply_tokens()
	_connect_scroll()
	resized.connect(_lay)
	_lay()
	_refresh_all()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_apply_tokens()
		_lay()


func _exit_tree() -> void:
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()


## STATION_HUB section 12.4 plus 09 section 11: `&"credits"` moves every price and tag,
## `&"ammo"` and `&"cargo"` the held figures (an ammo purchase moves both), and the racks
## and the inventory follow `&"fits"` (the fit a rack's cells live in), `&"modules"` (the
## bag its `OWNED ×<n>` figure and every drag spend from), `&"ships"` (the active hull's W
## cells) and `&"batteries"` (a rack write's own signal).
func refresh_profile(key: StringName) -> void:
	if key == &"credits" or key == &"ammo" or key == &"cargo":
		_refresh_rows()
	if key == &"fits" or key == &"ships" or key == &"batteries":
		_refresh_racks()
	if key == &"modules" or key == &"fits" or key == &"ships" or key == &"batteries":
		_refresh_inventory()


## The focus order: the racks' barrels first (rack order, each chip's own plate), then
## the inventory rows - the pane's one action source - then the ammunition rows, then the
## pane's own footer and the rail (STATION_HUB section 10).
func focus_primary() -> void:
	for view: Dictionary in _rack_views:
		for barrel: Dictionary in view[&"barrels"]:
			var control := barrel[&"name"] as Button
			if control != null and control.visible and not control.disabled:
				control.grab_focus()
				return
	for view: Dictionary in _inventory_views:
		var row := view[&"row"] as Button
		if row != null and row.visible and not row.disabled:
			row.grab_focus()
			return
	for payload: Dictionary in _payloads:
		var row: Button = payload[&"row"]
		if not row.disabled:
			row.grab_focus()
			return


## The style in force (section 3.9 rule 5's read-back).
func style() -> Resource:
	return _style


## Swap the whole style at runtime, from an `ArmoryStyle` resource: restyle and relayout
## with no code edit.
func set_style(new_style: Resource) -> void:
	if new_style == null:
		return
	_style = new_style
	_apply_style()


## Swap the style from a `.tres` path (`ArmoryStyle.ARMORY_USER_PATH` by default).
func set_style_file(path: String) -> void:
	set_style(StyleScript.load_style(path))


## The selected rack (0-based) whose bay wears the ember frame.
func selected_rack() -> int:
	return _selected_rack


## Mark one rack as the selected bay (nothing is written - the frame is presentation).
func set_selected_rack(rack: int) -> void:
	var wanted: int = rack if rack >= 0 and rack < _rack_views.size() else -1
	if wanted == _selected_rack:
		return
	_selected_rack = wanted
	for view: Dictionary in _rack_views:
		_style_bay(view)


## The keyboard half of the selection seam: the drawn `(1)`..`(5)` hints (`RACK_KEY`) are
## 09 section 11's own rack keys, so a digit moves the section 3.2 ember frame to that bay.
## Presentation only - `set_selected_rack` writes nothing.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	for rack in RACK_COUNT:
		if event.is_action_pressed(RACK_ACTION % (rack + 1)):
			set_selected_rack(rack)
			get_viewport().set_input_as_handled()
			return


## The pointer half of the remove gesture the chrome advertises (RIGHT-CLICK TO PULL): a
## right-button press over a fitted cell returns its barrel to the inventory. Read off
## the hovered control and its ancestors, so the cell's own children (the name plate, the
## `x`) do not have to re-implement it.
func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var button := event as InputEventMouseButton
	if not button.pressed or button.button_index != MOUSE_BUTTON_RIGHT:
		return
	var hovered := get_viewport().gui_get_hovered_control()
	while hovered != null and hovered != self:
		if hovered is BarrelCell:
			var cell := hovered as BarrelCell
			remove_barrel(cell.rack, cell.slot)
			accept_event()
			return
		hovered = hovered.get_parent_control()


## ------------------------------------------------------------------ the console


## Mount the console's own geometry: the console is the style's **derivation from the
## host rect** (P6), and the bay grid, the wells band and the item grids fill it.
func _build_console() -> void:
	if _style == null:
		_style = StyleScript.load_style()
	_seg.clear()
	for digit: int in 10:
		_seg.append(_style.texture(_style.seg_path(str(digit))))
	_seg_blank = _style.texture(_style.seg_path(_style.seg_blank_cell))
	_chrome = ConsolePanels.new()
	_chrome.name = "ConsolePanels"
	_console.add_child(_chrome)
	_console.move_child(_chrome, 1)
	_stretch(_chrome)
	## The bays live in a `VBoxContainer` whose own stacking the layout pass corrects on
	## every sort (the S5 suites read it by child index); the two scroll grids are plain
	## `Control`s, so nothing re-lays the cards and rows their own pass placed.
	_rack_rows.sort_children.connect(_lay_bays)
	_apply_style()


## Fill a child control to its parent's rect (the pane's own children are positioned by
## the layout pass, but the chrome panel is a pure fill).
static func _stretch(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Re-read the style into every part of the console: the chrome, the group boxes and the
## bay grid. Called once at build and again on a restyle.
func _apply_style() -> void:
	if _style == null or not is_node_ready():
		return
	## A4.1: the scripted console master retires from the pane - clearing the nine-slice's
	## texture is what unwires it (the master itself stays on disk; the module host's own
	## panel frame is the pane's outer edge now).
	_plate.texture = null
	_title.text = "ARMORY"
	_subtitle.text = SUBTITLE % [RACK_COUNT, Catalog.AMMO_PACKS.size()]
	_hint.text = PANE_HINT
	_tag.text = TAG_LIST_PREFIX + TAG_LIST_SEPARATOR.join(_id_list())
	_apply_tokens()
	_lay()
	for view: Dictionary in _rack_views:
		_style_bay(view)
	for payload: Dictionary in _payloads:
		_refresh_row(payload)
	for view: Dictionary in _inventory_views:
		_refresh_inventory_row(view)


## P6's one layout entry: every rect the pane draws derives from its own rect (the host
## the station shell gave it) through the style. Safe to call before the host has a size
## (a zero host derives zero rects and nothing is clipped).
func _lay() -> void:
	if _style == null or not is_node_ready():
		return
	var host := Rect2(Vector2.ZERO, size)
	var console: Rect2 = _style.console_rect(host)
	_console.position = console.position
	_console.size = console.size
	var band: Rect2 = _style.bays_band(console)
	_rack_rows.position = band.position - console.position
	_rack_rows.size = band.size
	_rack_rows.custom_minimum_size = band.size
	_position_chrome()
	_lay_half(
		_inventory_margin, _inventory_caption, _inventory_scroll,
		_shift(_style.well_half_rect(0, console), -console.position)
	)
	_lay_half(
		_ammo_margin, _ammo_caption, _ammo_scroll,
		_shift(_style.well_half_rect(1, console), -console.position)
	)
	## The captions read their own counts (they cannot go stale) - refreshed here, on
	## every layout pass, so a resize and a profile change tell the same story.
	if _inventory_caption != null:
		_inventory_caption.text = INVENTORY_CAPTION % _inventory_views.size()
	if _ammo_caption != null:
		_ammo_caption.text = AMMO_CAPTION % _payloads.size()
	_lay_bays()
	_lay_inventory()
	_lay_cards()
	_update_chrome()


## The pane's own chrome inside the console: the title and the hint on the top line, the
## caption and the id list on the second (all 13 px captions on the light ramp, the title
## the theme's own 20 px).
func _position_chrome() -> void:
	if _style == null:
		return
	## The chrome sits in the host band **above** the console (the mockup's own
	## composition): the title on the top line, the caption and the id list under it, the
	## hint opposite the title - all clear of the bays.
	var width: float = maxf(size.x, 0.0)
	var top: float = _console.position.y
	_title.position = Vector2(20.0, maxf(top - 58.0, 0.0))
	_title.size = Vector2(240.0, 30.0)
	_subtitle.position = Vector2(20.0, maxf(top - 28.0, 0.0))
	_subtitle.size = Vector2(maxf(width - 460.0, 0.0), 18.0)
	_hint.position = Vector2(maxf(width - 460.0, 0.0), maxf(top - 58.0, 0.0))
	_hint.size = Vector2(440.0, 18.0)
	_tag.position = Vector2(maxf(width - 460.0, 0.0), maxf(top - 28.0, 0.0))
	_tag.size = Vector2(440.0, 18.0)


## A rect moved by an offset (Rect2 has no `- Vector2` operator).
static func _shift(rect: Rect2, by: Vector2) -> Rect2:
	return Rect2(rect.position + by, rect.size)


## One wells half: the margin is the half's own box and its scrolling grid fills it; its
## caption sits **above** the box, on the band gap the mockup puts it on, so the item grid
## keeps the half's whole height (the 68 px rows the design rules).
func _lay_half(margin: Control, caption: Label, scroll: ScrollContainer, rect: Rect2) -> void:
	if margin == null:
		return
	var band: float = _style.caption_band
	margin.position = rect.position
	margin.size = rect.size
	margin.custom_minimum_size = Vector2.ONE
	if caption != null:
		caption.position = Vector2(4.0, -band)
		caption.size = Vector2(maxf(rect.size.x - 8.0, 0.0), band)
	if scroll == null:
		return
	scroll.position = Vector2.ZERO
	scroll.size = Vector2(maxf(rect.size.x, 0.0), maxf(rect.size.y, 0.0))


## Lay the rack bays out in the five-across band. The container is a `VBoxContainer` by
## the existing suites' own contract (`%RackRows` is cast to one and read by child index),
## so its own stacking is corrected here on every sort - the positions are exact before
## any layout pass, which is what lets a headless suite read them.
func _lay_bays() -> void:
	if _style == null or _rack_rows == null or _console == null:
		return
	var console: Rect2 = Rect2(Vector2.ZERO, _console.size)
	var band: Rect2 = _style.bays_band(console)
	var index := 0
	for child: Node in _rack_rows.get_children():
		var control := child as Control
		if control == null:
			continue
		var bay: Rect2 = _style.bay_rect(index, console)
		control.position = bay.position - band.position
		control.custom_minimum_size = Vector2.ONE
		control.size = bay.size
		index += 1
	_rack_rows.custom_minimum_size = band.size
	_rack_rows.size = _rack_rows.custom_minimum_size
	for child: Node in _rack_rows.get_children():
		var bay_control := child as Control
		if bay_control == null:
			continue
		_position_bay(bay_control)
	_update_chrome()


## One bay's own children at the mockup's own offsets: the head's label, key and state
## chip along the top, the cells in their 2x2 grid and the ledge at the foot.
func _position_bay(bay: Control) -> void:
	if _style == null or bay == null:
		return
	var rect := Rect2(Vector2.ZERO, bay.size)
	_position_head(bay.get_node_or_null(^"Box/Head") as Control)
	_position_cells(bay.get_node_or_null(^"Box/Barrels") as Control)
	_position_drop_cells(bay.get_node_or_null(^"Box/Cells") as Control)
	var strip := bay.get_node_or_null(^"Box/Salvo") as SalvoStrip
	if strip != null:
		strip.position = _style.ledge_rect(rect).position
		strip.size = _style.ledge_rect(rect).size
		strip.configure(_style, _seg, _seg_blank)
		strip.set_figure(strip.figure())
	var marks := bay.get_node_or_null(^"Box/BayMarks") as BayMarks
	if marks != null:
		marks.position = Vector2.ZERO
		marks.size = bay.size
	var chip := bay.get_node_or_null(^"Box/Head/Chip") as Control
	if chip != null:
		chip.position = _style.head_chip_rect(rect).position
		chip.size = _style.head_chip_rect(rect).size


## One bay's head, at the mockup's offsets: `B<n>` and its key hint at the left, the state
## chip with its label at the right. The head's own rect is the bay's, so the offsets are
## bay-relative; the containing box reflows its children on every sort, so the positions
## are re-applied here each time (the suites read the labels by name).
func _position_head(head: Control) -> void:
	if _style == null or head == null:
		return
	var bay := Rect2(Vector2.ZERO, _bay_size_of(head))
	var label := head.get_node_or_null(^"Label") as Control
	if label != null:
		label.position = Vector2(_style.cell_margin, (_style.bay_head - 18.0) * 0.5)
		label.size = Vector2(40.0, 18.0)
	var key := head.get_node_or_null(^"Key") as Control
	if key != null:
		key.position = Vector2(_style.cell_margin + 30.0, (_style.bay_head - 18.0) * 0.5)
		key.size = Vector2(36.0, 18.0)
	var chip := head.get_node_or_null(^"Chip") as Control
	if chip != null:
		chip.position = _style.head_chip_rect(bay).position
		chip.size = _style.head_chip_rect(bay).size
	var state := head.get_node_or_null(^"State") as Control
	if state != null:
		var chip_box: Rect2 = _style.head_chip_rect(bay)
		state.position = chip_box.position + Vector2(16.0, (_style.head_chip.y - 18.0) * 0.5)
		state.size = Vector2(chip_box.size.x - 20.0, 18.0)


## One bay child's own bay size: the rect of the `RackRow` it lives in, walked up from the
## child, so a head or chip list laid out from its ancestor's rect can never read a stale
## or zero box (the intermediate containers fill the bay only after their own sort).
func _bay_size_of(control: Control) -> Vector2:
	var node: Node = control.get_parent()
	while node != null:
		if node is RackRow:
			return (node as Control).size
		node = node.get_parent()
	return Vector2.ZERO


## One bay's fitted chips, each inside its own slot-chrome cell, with the `x` in the
## cell's top-right corner.
##
## Both children clip their text, so a plain row gives each of them a **zero** width: the
## `x`'s own box is the top-right corner and the name plate takes the rest of the cell,
## which keeps both hit targets hittable through every layout pass (the D7/S10 lesson).
func _position_cells(barrels: Control) -> void:
	if _style == null or barrels == null:
		return
	var bay := Rect2(Vector2.ZERO, _bay_size_of(barrels))
	var index := 0
	for child: Node in barrels.get_children():
		var chip := child as Control
		if chip == null:
			continue
		## The grid slot is the cell's **position in the rack** (its own order), never its
		## W-cell index: a bay can hold W5..W7, and those indices must not address the grid.
		var cell: Rect2 = _style.bay_cell_rect(index, bay)
		chip.position = cell.position
		chip.size = cell.size
		_position_cell_children(chip)
		index += 1


## One chip's own children: the name plate over the whole cell but its bottom strip (the
## chip's own drag zone), the `x`'s box in the top-right corner, and the two name lines.
func _position_cell_children(chip: Control) -> void:
	var cell := Rect2(Vector2.ZERO, chip.size)
	var name_button := chip.get_node_or_null(^"Name") as Control
	if name_button != null:
		## The chip is a Container: the name plate takes every column the `x` does not
		## (EXPAND) and stops 10 px short of the cell's foot, which stays the chip's own
		## drag zone (a press there is the barrel drag the suites drive).
		name_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		name_button.custom_minimum_size = Vector2(0.0, maxf(cell.size.y - 10.0, 0.0))
		name_button.position = Vector2.ZERO
		name_button.size = Vector2(maxf(cell.size.x - 24.0, 0.0), maxf(cell.size.y - 10.0, 0.0))
	var close := chip.get_node_or_null(^"Close") as Control
	if close != null:
		close.size_flags_horizontal = Control.SIZE_SHRINK_END
		close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		close.custom_minimum_size = Vector2(24.0, 24.0)
		close.position = Vector2(maxf(cell.size.x - 26.0, 0.0), 0.0)
		close.size = Vector2(24.0, 24.0)
	var plate := chip.get_node_or_null(^"Name") as Control
	var name_label := plate.get_node_or_null(^"NamePlate") as Control if plate != null else null
	var variant_label := plate.get_node_or_null(^"Variant") as Control if plate != null else null
	var has_variant := variant_label != null and not (variant_label as Label).text.is_empty()
	if name_label != null:
		var top: float = 4.0 if has_variant else (plate.size.y - 18.0) * 0.5
		name_label.position = Vector2(6.0, top)
		name_label.size = Vector2(maxf(cell.size.x - 24.0, 0.0), 18.0)
	if variant_label != null:
		variant_label.position = Vector2(6.0, 22.0)
		variant_label.size = Vector2(maxf(cell.size.x - 24.0, 0.0), 18.0)


## One bay's empty cells: the `DROP HERE` cue centred in each recess. Every pad sits in
## its **own** grid slot (the slot it was built for), never in its child order: the pads
## only exist for the empty slots, so counting them from zero would land the first cue on
## the fitted chip and leave the bay's last slot bare.
func _position_drop_cells(cells: Control) -> void:
	if _style == null or cells == null:
		return
	var bay := Rect2(Vector2.ZERO, _bay_size_of(cells))
	for child: Node in cells.get_children():
		var pad := child as DropCell
		if pad == null:
			continue
		var cell: Rect2 = _style.bay_cell_rect(pad.slot, bay)
		pad.position = cell.position
		pad.size = cell.size
		var cue := pad.get_node_or_null(^"Cue") as Control
		if cue != null:
			cue.position = Vector2.ZERO
			cue.size = cell.size


## The barrel inventory's rows, in the left half's 2x3 grid. The grid's rect is the
## scroll's own (the panel's item rects are item-grid-local); the rows are plain `Control`s
## so nothing re-stacks them.
func _lay_inventory() -> void:
	if _style == null or _inventory_rows == null or _inventory_scroll == null:
		return
	var grid := Rect2(Vector2.ZERO, _inventory_scroll.size)
	var index := 0
	for child: Node in _inventory_rows.get_children():
		var control := child as Control
		if control == null:
			continue
		var rect: Rect2 = _style.item_rect(index, grid)
		control.position = rect.position
		control.custom_minimum_size = Vector2.ONE
		control.size = rect.size
		_position_inventory_item(control, rect)
		index += 1
	## Only the content height is declared: the grid's width is the scroll's viewport (a
	## declared width would feed the scroll's own minimum back into itself).
	_inventory_rows.custom_minimum_size = Vector2(0.0, _grid_content_height(index, grid))
	_inventory_rows.size = Vector2(grid.size.x, _grid_content_height(index, grid))


## The ammunition cards' grid in the right half, the same 2x3.
func _lay_cards() -> void:
	if _style == null or _rows == null or _ammo_scroll == null:
		return
	var grid := Rect2(Vector2.ZERO, _ammo_scroll.size)
	var index := 0
	for child: Node in _rows.get_children():
		var control := child as Control
		if control == null:
			continue
		var rect: Rect2 = _style.item_rect(index, grid)
		control.position = rect.position
		control.custom_minimum_size = Vector2.ONE
		control.size = rect.size
		_position_card(control, rect)
		index += 1
	_rows.custom_minimum_size = Vector2(0.0, _grid_content_height(index, grid))
	_rows.size = Vector2(grid.size.x, _grid_content_height(index, grid))


## A grid's own content height: `count` items on the visible row height, so a grid that
## outgrows its half drives the scroll instead of clipping (the item height derives from
## the visible rows, not the item count).
func _grid_content_height(count: int, grid: Rect2) -> float:
	if count <= 0 or _style == null:
		return grid.size.y
	var columns: int = maxi(_style.item_columns, 1)
	var rows: int = int(ceil(float(count) / float(columns)))
	var visible: int = maxi(_style.item_rows, 1)
	var row_h: float = (grid.size.y - float(visible - 1) * _style.item_gap) / float(visible)
	return float(rows) * row_h + float(maxi(rows - 1, 0)) * _style.item_gap


## One inventory row's own children: the icon, the name and the OWNED figure.
func _position_inventory_item(row: Control, rect: Rect2) -> void:
	var icon := row.get_node_or_null(^"Icon") as Control
	if icon != null:
		icon.position = _style.item_icon_rect(rect).position
		icon.size = Vector2(_style.item_icon, _style.item_icon)
	var name_label := row.get_node_or_null(^"Name") as Control
	if name_label != null:
		name_label.position = Vector2(_style.item_icon + 16.0, (rect.size.y - 18.0) * 0.5)
		name_label.size = Vector2(maxf(rect.size.x - _style.item_icon - 140.0, 0.0), 18.0)
	var status := row.get_node_or_null(^"Status") as Control
	if status != null:
		status.position = Vector2(maxf(rect.size.x - 116.0, 0.0), (rect.size.y - 18.0) * 0.5)
		status.size = Vector2(108.0, 18.0)
		var value := status.get_node_or_null(^"Value") as Control
		if value != null:
			value.position = Vector2(0.0, 0.0)
			value.size = status.size


## One pack card's own children, at the card's four lines: title + price, meta + state
## chip, the worded held line, the state line + BUY chip.
func _position_card(card: Control, rect: Rect2) -> void:
	var inset: float = ROW_TEXT_INSET
	var icon := card.get_node_or_null(^"Icon") as Control
	if icon != null:
		icon.position = Vector2(inset, maxf((rect.size.y - _style.item_icon) * 0.5, 0.0))
		icon.size = Vector2(_style.item_icon, _style.item_icon)
	var text_x: float = inset + _style.item_icon + 8.0
	var title := card.get_node_or_null(^"Title") as Control
	if title != null:
		title.position = Vector2(text_x, _card_line(0))
		title.size = Vector2(maxf(rect.size.x - text_x - 84.0, 0.0), 18.0)
	var price := card.get_node_or_null(^"Price") as Control
	if price != null:
		price.position = Vector2(maxf(rect.size.x - 76.0 - inset, 0.0), _card_line(0))
		price.size = Vector2(76.0, 18.0)
		var value := price.get_node_or_null(^"Value") as Control
		if value != null:
			value.position = Vector2.ZERO
			value.size = Vector2(76.0, 18.0)
	var meta := card.get_node_or_null(^"Meta") as Control
	if meta != null:
		meta.position = Vector2(text_x, _card_line(1))
		meta.size = Vector2(maxf(rect.size.x - text_x - 112.0, 0.0), 18.0)
	var status := card.get_node_or_null(^"Status") as Control
	if status != null:
		status.position = Vector2(maxf(rect.size.x - 104.0 - inset, 0.0), _card_line(1) - 2.0)
		status.size = Vector2(104.0, 22.0)
		var value := status.get_node_or_null(^"Value") as Control
		if value != null:
			value.position = Vector2(16.0, 2.0)
			value.size = Vector2(status.size.x - 20.0, 18.0)
	var held := card.get_node_or_null(^"Held") as Control
	if held != null:
		held.position = Vector2(text_x, _card_line(2))
		held.size = Vector2(maxf(rect.size.x - text_x - inset, 0.0), 36.0)
		var value := held.get_node_or_null(^"Value") as Control
		if value != null:
			value.position = Vector2.ZERO
			value.size = Vector2(held.size.x, 18.0)
		var caption := held.get_node_or_null(^"Caption") as Control
		if caption != null:
			caption.position = Vector2(0.0, 18.0)
			caption.size = Vector2(held.size.x, 18.0)
	var buy := card.get_node_or_null(^"Buy") as Control
	if buy != null:
		buy.position = Vector2(maxf(rect.size.x - 64.0 - inset, 0.0), _card_line(3))
		buy.size = Vector2(64.0, 16.0)
		var label := buy.get_node_or_null(^"Label") as Control
		if label != null:
			label.position = Vector2(4.0, 2.0)
			label.size = Vector2(buy.size.x - 8.0, 18.0)


## One card line's top offset inside the 68 px base card.
func _card_line(index: int) -> float:
	return CARD_LINE_FIRST + CARD_LINE_PITCH * float(index)


## Hand the console's chrome node the rects the style derives (all console-local): the
## bays (A4.1 frames), the wells halves (A4.1 frames), the four slot-chrome cells of every
## bay (A4.2) and the salvo ledges.
func _update_chrome() -> void:
	if _chrome == null or _style == null:
		return
	var console := Rect2(Vector2.ZERO, _console.size)
	var bays: Array[Rect2] = []
	var cells: Array[Rect2] = []
	var ledges: Array[Rect2] = []
	for index in _rack_rows.get_child_count():
		var bay: Rect2 = _style.bay_rect(index, console)
		bays.append(bay)
		for cell in 4:
			cells.append(_style.bay_cell_rect(cell, bay))
		ledges.append(_style.ledge_rect(bay))
	var wells: Array[Rect2] = [
		_style.well_half_rect(0, console), _style.well_half_rect(1, console)
	]
	_chrome.configure(_style, bays, cells, ledges, wells)


## ------------------------------------------------------------------ the token lookup


func _apply_tokens() -> void:
	for payload: Dictionary in _payloads:
		_apply_icon_token(payload)
	for view: Dictionary in _inventory_views:
		_apply_icon_token(view)


func _apply_icon_token(payload: Dictionary) -> void:
	var icon: TextureRect = payload[&"icon"]
	if icon != null and bool(payload[&"tinted"]):
		var tint: Color = _token(ROLE_TEXT_PRIMARY)
		tint.a = ROW_ICON_IDLE_ALPHA
		icon.modulate = tint


## One colour, from the style's palette (section 3.9 rule 5: this pane keeps no colour of
## its own). The theme is the fallback for the frame between the scene loading and the
## style being installed, the same silent fallback the D6 surfaces had.
func _token(token: StringName) -> Color:
	if _style != null:
		return _style.colour(token)
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.WHITE


## A caption label: the pane's one 13 px label idiom (the `StationCaption` variation,
## registered in `Router.FONT_SIZE_ITEMS`, with an ink role override).
func _make_caption(text: String, role: StringName = ROLE_CAPTION) -> Label:
	var label := Label.new()
	label.theme_type_variation = &"StationCaption"
	label.text = text
	label.add_theme_color_override(&"font_color", _token(role))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## ------------------------------------------------------------------ the pack cards


func _id_list() -> PackedStringArray:
	var ids := PackedStringArray()
	for pack: Dictionary in Catalog.AMMO_PACKS:
		ids.append(String(pack.get(&"id", &"")))
	return ids


func _build_rows() -> void:
	_payloads.clear()
	for pack: Dictionary in Catalog.AMMO_PACKS:
		_payloads.append(_build_card(pack))
	_lay_cards()


## One ammunition **card** (T4/P2/P5): the pack's name and price, its rounds-per-pack,
## the worded held line, the section 5.1 state tag and state line, and the `BUY` chip, on
## the theme's panel-frame plate (A4.1). Every cell the S5 suites read is still built here
## (`Title`, `Meta`, `Held`/`Value` + `Held`/`Caption`, `Price`/`Value` + `Price`/`Caption`,
## `Status`), so the state lines and figures keep one home.
func _build_card(pack: Dictionary) -> Dictionary:
	var pack_id: StringName = pack.get(&"id", &"")
	var name_text := String(pack.get(&"name", ""))
	var rounds := int(pack.get(&"rounds", 0))
	var cost := int(pack.get(&"cost", 0))
	var complete := pack_id != &"" and not name_text.is_empty() and rounds > 0
	var card := Button.new()
	card.name = "Ammo%s" % String(pack_id).to_pascal_case()
	card.toggle_mode = true
	card.focus_mode = Control.FOCUS_ALL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.disabled = not complete
	card.clip_contents = true
	var frame := RowPlate.new()
	frame.name = "RowPlate"
	card.add_child(frame)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.configure(_style)
	var icon := _make_icon(String(pack.get(&"icon", "")), _style.item_icon)
	if icon != null:
		card.add_child(icon)
	var title := _make_caption(name_text if complete else TAG_UNAVAILABLE, ROLE_BONE)
	title.name = "Title"
	card.add_child(title)
	var meta := _make_caption(ROUNDS_CAPTION % rounds if complete else META_INCOMPLETE)
	meta.name = "Meta"
	card.add_child(meta)
	var price := Control.new()
	price.name = "Price"
	price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(price)
	var price_value := _make_caption("")
	price_value.name = "Value"
	price.add_child(price_value)
	var price_caption := _make_caption("")
	price_caption.name = "Caption"
	price.add_child(price_caption)
	var held := Control.new()
	held.name = "Held"
	held.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(held)
	var held_value := _make_caption("")
	held_value.name = "Value"
	held.add_child(held_value)
	var held_caption := _make_caption("")
	held_caption.name = "Caption"
	held.add_child(held_caption)
	var status := ChipPlate.new()
	status.name = "Status"
	card.add_child(status)
	var tag := _make_caption(TAG_EMPTY)
	tag.name = "Value"
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_child(tag)
	var tag_caption := _make_caption("")
	tag_caption.name = "Caption"
	status.add_child(tag_caption)
	var buy := Button.new()
	buy.name = "Buy"
	## A4.2: `BUY` is a pressable chip, so it wears the `StationButton` plate
	## (`ui_button_plate_*`) instead of the code-drawn chip. Mouse-only (FOCUS_NONE): the
	## card keeps the pane's focus order, and a press on the chip buys through the same
	## handler the card's own press uses.
	buy.theme_type_variation = &"StationButton"
	buy.focus_mode = Control.FOCUS_NONE
	buy.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.add_child(buy)
	var buy_label := _make_caption(BUY_CHIP, ROLE_CAPTION)
	buy_label.name = "Label"
	buy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	buy.add_child(buy_label)
	var payload := {
		&"id": pack_id,
		&"name": name_text,
		&"rounds": rounds,
		&"cost": cost,
		&"complete": complete,
		&"row": card,
		&"plate": frame,
		&"icon": icon,
		&"tinted": _is_flat_glyph(String(pack.get(&"icon", ""))),
		&"title": title,
		&"meta": meta,
		&"held": held_value,
		&"held_caption": held_caption,
		&"price": price_value,
		&"price_caption": price_caption,
		&"tag": tag,
		&"status": status,
		&"buy": buy,
	}
	if complete:
		card.pressed.connect(_on_row_pressed.bind(payload))
		buy.pressed.connect(_on_row_pressed.bind(payload))
		card.focus_entered.connect(_on_row_focused.bind(card, payload))
		card.mouse_entered.connect(_on_row_hovered.bind(payload, true))
		card.mouse_exited.connect(_on_row_hovered.bind(payload, false))
	_rows.add_child(card)
	frame.configure(_style)
	status.configure(_style, false, false)
	_position_card(card, Rect2(Vector2.ZERO, Vector2(320.0, 68.0)))
	return payload


func _make_label(variation: StringName, text: String) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_icon(icon_path: String, cell: float) -> TextureRect:
	if icon_path.is_empty():
		return null
	var tinted := _is_flat_glyph(icon_path)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(cell, cell)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = load(_icon_source(icon_path))
	var base := _token(ROLE_TEXT_PRIMARY) if tinted else Color.WHITE
	base.a = ROW_ICON_IDLE_ALPHA
	icon.modulate = base
	return icon


func _is_flat_glyph(icon_path: String) -> bool:
	return FLAT_GLYPH_ICONS.has(icon_path)


func _icon_source(icon_path: String) -> String:
	if icon_path.ends_with(".svg"):
		return icon_path
	if not _is_flat_glyph(icon_path):
		return icon_path
	return TINT_DIR + icon_path.get_file()


func _connect_scroll() -> void:
	## The scroll cue has no other home: the station shell owns no list of its own.
	for scroll: ScrollContainer in [_inventory_scroll, _ammo_scroll]:
		if scroll != null and scroll.has_signal(&"scroll_started"):
			scroll.connect(&"scroll_started", _on_scroll_started)


func _on_scroll_started() -> void:
	AudioManager.play_ui(AudioManager.UiCue.SCROLL)


func _on_row_focused(row: Button, payload: Dictionary) -> void:
	AudioManager.play_ui(AudioManager.UiCue.HOVER)
	if _selected_row != null and _selected_row != row and is_instance_valid(_selected_row):
		_selected_row.set_pressed_no_signal(false)
	_selected_row = row
	row.set_pressed_no_signal(true)
	status_requested.emit(_row_hint(payload), false)
	_inspect_row(payload, true)


func _on_row_hovered(payload: Dictionary, hovered: bool) -> void:
	_inspect_row(payload, hovered)
	var icon: TextureRect = payload[&"icon"]
	if icon == null:
		return
	var target := 1.0 if hovered else ROW_ICON_IDLE_ALPHA
	var tween := _make_tween()
	tween.tween_property(icon, "modulate:a", target, HOVER_SECONDS)


func _on_row_pressed(payload: Dictionary) -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	var row: Button = payload[&"row"]
	row.set_pressed_no_signal(true)
	_selected_row = row
	_inspect_row(payload, true)
	var profile := _profile()
	if profile == null:
		return
	var bought := bool(
		profile.call(
			&"buy_ammo", payload[&"id"], int(payload[&"rounds"]), int(payload[&"cost"])
		)
	)
	if not bought:
		## The refusal text and the denied cue belong to the shell, which hears
		## purchase_failed; the row only marks its own price cell (section 5.6) and
		## wears the section 3.1b danger frame.
		_pulse(payload[&"price"] as Label)
		_style_danger(payload, true)
		return
	AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
	status_requested.emit(
		STATUS_BOUGHT % [String(payload[&"name"]).to_upper(), int(payload[&"rounds"])], false
	)


func _refresh_rows() -> void:
	for payload: Dictionary in _payloads:
		_refresh_row(payload)


## One ammunition card, in the S5 model (10 section 6.1): the purchase delivers **cargo
## units**, so the held line counts the hold's own units expressed in **rounds** (P5:
## `HELD 60 ROUNDS - HOLD 30 UNITS`) against the family's advisory unit ceiling. The four
## state lines follow the same two figures, so a card that has bought nothing yet reads
## EMPTY even while the magazine a previous launch loaded still holds rounds - which is
## exactly what the player is about to buy.
func _refresh_row(payload: Dictionary) -> void:
	if not is_node_ready():
		return
	var price: Label = payload[&"price"]
	var tag: Label = payload[&"tag"]
	var held: Label = payload[&"held"]
	var caption: Label = payload[&"held_caption"]
	if not bool(payload[&"complete"]):
		held.text = HELD_FORMAT % [0, 0]
		caption.text = META_INCOMPLETE
		tag.text = TAG_UNAVAILABLE
		price.text = PRICE_FORMAT % UNAVAILABLE_VALUE
		price.remove_theme_color_override(&"font_color")
		_style_danger(payload, true)
		return
	var profile := _profile()
	var affordable := profile == null or bool(profile.call(&"can_afford", int(payload[&"cost"])))
	if affordable:
		price.remove_theme_color_override(&"font_color")
	else:
		price.add_theme_color_override(&"font_color", _token(ROLE_DANGER))
	price.text = PRICE_FORMAT % _format_int(int(payload[&"cost"]))
	var pack_id: StringName = payload[&"id"]
	var held_units := 0
	var capacity := 0
	if profile != null:
		held_units = int(profile.call(&"ammo_units", pack_id))
		capacity = _unit_cap(profile, pack_id)
	var rounds_held := held_units * maxi(1, int(Catalog.ROUNDS_PER_CARGO_UNIT))
	held.text = HELD_FORMAT % [rounds_held, capacity]
	var over_cap := false
	if held_units <= 0:
		tag.text = TAG_EMPTY
		caption.text = META_NO_ROUNDS
	elif held_units > capacity:
		tag.text = TAG_OVER_CAP
		caption.text = META_ADVISORY
		over_cap = true
	elif held_units == capacity:
		tag.text = TAG_AT_CAP
		caption.text = META_NO_CAP
	else:
		tag.text = TAG_IN_STOCK
		caption.text = META_BELOW_CAPACITY
	## Section 3.10: danger/refusal states reuse section 3.1/3.1b verbatim as row
	## treatments - the label plus a 1 px code-drawn frame; digits never recolour.
	_style_danger(payload, over_cap or not affordable)


## The section 3.1/3.1b row treatment on one ammunition card: the code-drawn frame, the
## state chip's own shape (the chevron when the state is the dangerous one) and the state
## label in the danger role (its own text never recoloured by the load).
func _style_danger(payload: Dictionary, danger: bool) -> void:
	var plate: RowPlate = payload.get(&"plate", null)
	if plate != null:
		plate.set_danger(danger)
	var tag: Label = payload.get(&"tag", null)
	var over_cap: bool = tag != null and tag.text == TAG_OVER_CAP
	var status: ChipPlate = payload.get(&"status", null)
	if status != null:
		status.configure(_style, danger, over_cap)
	if tag == null:
		return
	if danger:
		## A4.3/L227: the danger label is the bright ember. `accent_danger` can never clear
		## 4.5:1 on any fill (its ceiling is 4.38:1 against pure black); the bright pair
		## measures 4.86:1 on `chip_danger_bg`.
		tag.add_theme_color_override(&"font_color", _token(ROLE_DANGER_BRIGHT))
	else:
		tag.remove_theme_color_override(&"font_color")


## The `MAX` figure of one ammunition card: the family's advisory `ammo_max` expressed in
## cargo units, rounded **up** like the purchase's own unit arithmetic
## (`PlayerProfile._ammo_units_for`), so a family whose ceiling is not a multiple of
## `ROUNDS_PER_CARGO_UNIT` still shows the smallest number of units that reaches it.
## Never 0: the line would read `HOLD 0 UNITS` for a family the catalogue ships.
func _unit_cap(profile: ProfileScript, pack_id: StringName) -> int:
	var rounds := int(profile.call(&"ammo_max", pack_id))
	var per_unit := maxi(1, int(Catalog.ROUNDS_PER_CARGO_UNIT))
	return maxi(1, ceili(float(rounds) / float(per_unit)))


func _row_hint(payload: Dictionary) -> String:
	return STATUS_HINT % [
		String(payload[&"name"]).to_upper(),
		_format_int(int(payload[&"cost"])),
	]


## The row's identity for the inspector's title: its name and price phrase, the same
## values `_row_hint` prints, with the key-hint verb kept for the status strip alone.
func _row_title(payload: Dictionary) -> String:
	return INSPECT_TITLE_FORMAT % [
		String(payload[&"name"]).to_upper(),
		_format_int(int(payload[&"cost"])),
	]


## CONTRACTS section 23.1: the inspector's additive hover surface. The row's own
## identity line is the title, the catalogue description is the body, and a row that is
## not buyable wears the danger colour. A leave clears both by handing the shell
## `title == ""`.
func _inspect_row(payload: Dictionary, shown: bool) -> void:
	if not shown:
		inspect_requested.emit("", "", false)
		return
	inspect_requested.emit(
		_row_title(payload),
		Catalog.describe(StringName(payload[&"id"])),
		not bool(payload.get(&"complete", true))
	)


## --------------------------------------------------------------------- the racks


func _build_racks() -> void:
	_refresh_racks()


func _build_inventory() -> void:
	_refresh_inventory()


## Release one container's children at the end of the frame: the plate whose own
## `_drop_data` (or `pressed`) started the write that triggered this refresh is still on
## the stack, so it may not be freed under it (CONTRACTS section 16 rule 10's hazard,
## cured here by `queue_free` rather than by a fixed node set - a rack's shape is
## player-composed, so it has no fixed shaped to pre-build).
static func _clear(node: Node) -> void:
	for child: Node in node.get_children():
		node.remove_child(child)
		child.queue_free()


## Redraw every rack from the profile: the active hull's composed racks as
## `battery_groups` derives them (`B1..B5`, in `weapon_1..5` order), each rack as a bay -
## `B<n>` and its key hint on the head with the `READY`/`OVER CAP` chip, the four
## slot-chrome cells (the fitted ones named, the empty ones offering `DROP HERE`) and the
## ledge with the rack's own cycle figure (seconds x 100, the slowest member's cycle: 09
## section 11).
func _refresh_racks() -> void:
	_clear(_rack_rows)
	_rack_views.clear()
	var profile := _profile()
	if profile == null:
		_lay_bays()
		return
	var hull := _active_hull(profile)
	var groups: Array = profile.call(&"battery_groups", hull) if hull != &"" else []
	var cells := _weapon_cells(profile)
	for rack in RACK_COUNT:
		var refs: Array = groups[rack] if rack < groups.size() else []
		_rack_views.append(_build_rack(rack, refs, cells))
	_lay()


func _build_rack(rack: int, refs: Array, cells: Array) -> Dictionary:
	var row := RackRow.new()
	row.name = "Rack%d" % (rack + 1)
	row.armory = self
	row.rack = rack
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.clip_contents = false
	row.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	var box := PanelContainer.new()
	box.name = "Box"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	row.add_child(box)
	var marks := BayMarks.new()
	marks.name = "BayMarks"
	marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(marks)
	## `Head` and `Barrels` are plain `Control`s: a container would re-stack their children
	## after the pane's own layout pass (the mockup's grid is not a box layout), so the
	## bay's rects are written once per pass and nothing moves them again.
	var head := Control.new()
	head.name = "Head"
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(head)
	var label := _make_caption(RACK_LABEL % (rack + 1), ROLE_BONE)
	label.name = "Label"
	head.add_child(label)
	var key := _make_caption(RACK_KEY % (rack + 1), ROLE_CAPTION)
	key.name = "Key"
	head.add_child(key)
	var chip := ChipPlate.new()
	chip.name = "Chip"
	head.add_child(chip)
	var state := _make_caption(RACK_READY, ROLE_CAPTION)
	state.name = "State"
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(state)
	var cell_boxes := Control.new()
	cell_boxes.name = "Cells"
	cell_boxes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(cell_boxes)
	var barrels := Control.new()
	barrels.name = "Barrels"
	barrels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(barrels)
	var strip := SalvoStrip.new()
	strip.name = "Salvo"
	box.add_child(strip)
	var views: Array[Dictionary] = []
	for index in refs.size():
		views.append(_build_barrel(rack, index, int(refs[index]), cells, barrels))
	## The empty cells fill the grid slots the fitted ones leave, in order.
	for slot in range(refs.size(), 4):
		_build_drop_cell(rack, slot, cell_boxes)
	var cycle := _rack_cycle(refs, cells)
	var state_text: String = RACK_STATE_OVER if _rack_cells_count(refs) >= WeaponComponent.BATTERY_CELLS_MAX else RACK_READY
	state.text = state_text
	chip.configure(_style, state_text == RACK_STATE_OVER, state_text == RACK_STATE_OVER)
	state.add_theme_color_override(
		&"font_color",
		_token(ROLE_DANGER_BRIGHT if state_text == RACK_STATE_OVER else ROLE_CAPTION)
	)
	var salvo_line: String = RACK_SALVO % cycle if cycle > 0.0 else RACK_READY
	state.tooltip_text = salvo_line
	_rack_rows.add_child(row)
	## The bay box (a `PanelContainer`) sizes its children to itself on every sort, and the
	## ledge follows its own resize: both re-enter the bay layout, so the strip, the head
	## and the cells end every pass where the style put them (the old pane's own lesson).
	if not box.sort_children.is_connected(_position_bay.bind(row)):
		box.sort_children.connect(_position_bay.bind(row))
	if not strip.resized.is_connected(_position_bay.bind(row)):
		strip.resized.connect(_position_bay.bind(row))
	_position_head(head)
	_position_cells(barrels)
	_position_bay(row)
	var view := {
		&"rack": rack,
		&"row": row,
		&"label": label.text,
		&"state": state,
		&"chip": chip,
		&"cells_node": cell_boxes,
		&"salvo": salvo_line,
		&"barrels": views,
		&"cells": _rack_cell_list(refs),
		&"marks": marks,
		&"strip": strip,
		&"figure": _salvo_figure(cycle),
	}
	_style_bay(view)
	return view


## The number of cells one rack's own record holds (09 section 12's hardcap read).
static func _rack_cells_count(refs: Array) -> int:
	return refs.size()


## One barrel chip: the drag source (the name plate), the visible name block on two 13 px
## lines (T3) and the `x` that returns the barrel to the inventory. Both bind the
## barrel's **address** (rack, slot) as the rack stands now, because the whole rack is
## redrawn by the next profile change.
func _build_barrel(
	rack: int, slot: int, cell: int, cells: Array, parent: Control
) -> Dictionary:
	var chip := BarrelCell.new()
	chip.name = "Barrel%d" % (slot + 1)
	chip.armory = self
	chip.rack = rack
	chip.slot = slot
	chip.mouse_filter = Control.MOUSE_FILTER_STOP
	chip.clip_contents = true
	var entry := StringName(String(cells[cell])) if cell >= 0 and cell < cells.size() else &""
	var full_name := BARREL_TEXT % [cell + 1, _module_name(_base_id(_profile(), entry))]
	var name_button := BarrelName.new()
	name_button.name = "Name"
	name_button.armory = self
	name_button.rack = rack
	name_button.slot = slot
	name_button.theme_type_variation = &"StationButton"
	name_button.focus_mode = Control.FOCUS_ALL
	name_button.text = full_name
	name_button.custom_minimum_size = Vector2.ZERO
	name_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	name_button.tooltip_text = full_name
	for state: StringName in [
		&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"
	]:
		name_button.add_theme_color_override(state, Color(0, 0, 0, 0))
	chip.add_child(name_button)
	## The two name lines live **inside the name plate**: a Button does not aggregate its
	## children's minimum sizes, so the visible name cannot grow the chip's own minimum and
	## push the bay past its drawn width (a Container would).
	var parts := _split_name(full_name)
	var name_label := _make_caption(parts[0], ROLE_BONE)
	name_label.name = "NamePlate"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_button.add_child(name_label)
	var variant_label := _make_caption(parts[1], ROLE_CAPTION)
	variant_label.name = "Variant"
	variant_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_button.add_child(variant_label)
	var close := Button.new()
	close.name = "Close"
	## A4.2: the `X` is a pressable chip and wears the `StationButton` plate (it was flat
	## under the bespoke language); its 24 px box keeps the S10 hit target.
	close.theme_type_variation = &"StationButton"
	close.focus_mode = Control.FOCUS_ALL
	close.text = BARREL_CLOSE
	close.clip_text = true
	close.custom_minimum_size = Vector2.ZERO
	close.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close.add_theme_color_override(&"font_color", _token(ROLE_CAPTION))
	close.pressed.connect(_on_remove_barrel.bind(rack, slot))
	chip.add_child(close)
	parent.add_child(chip)
	if not chip.sort_children.is_connected(_position_cell_children.bind(chip)):
		chip.sort_children.connect(_position_cell_children.bind(chip))
	_position_cell_children(chip)
	name_button.focus_entered.connect(_on_barrel_focused.bind(rack, cell, entry))
	chip.mouse_entered.connect(_on_barrel_inspected.bind(rack, cell, entry, true))
	chip.mouse_exited.connect(_on_barrel_inspected.bind(rack, cell, entry, false))
	return {&"cell": cell, &"name": name_button, &"close": close, &"text": full_name}


## The full barrel name on two 13 px lines: everything before the name's last word on the
## first line, that word (the variant) on the second - so the widest catalogue names
## (`MINE LAYER MKI`) stay inside a 117 px cell at 13 px. A single-word name reads on one
## line and the second label stays empty.
static func _split_name(full_name: String) -> Array[String]:
	var cut := full_name.rfind(" ")
	if cut <= 0:
		return [full_name, ""]
	return [full_name.substr(0, cut), full_name.substr(cut + 1)]


## One empty cell: the `DROP HERE` cue and the physical drop zone (the body-drop route).
## `slot` is the grid position it fills, not a W-cell index.
func _build_drop_cell(rack: int, slot: int, parent: Control) -> void:
	var pad := DropCell.new()
	pad.name = "Cell%d" % (slot + 1)
	pad.armory = self
	pad.rack = rack
	pad.slot = slot
	pad.mouse_filter = Control.MOUSE_FILTER_STOP
	var cue := _make_caption(RACK_INSTALL_CUE)
	cue.name = "Cue"
	cue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cue.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pad.add_child(cue)
	parent.add_child(pad)


## Focus on a barrel makes its rack the selected bay (the section 3.2 ember frame) and
## publishes the barrel's own line to the inspector.
func _on_barrel_focused(rack: int, cell: int, entry: StringName) -> void:
	set_selected_rack(rack)
	_inspect_barrel(rack, cell, entry, true)


func _on_barrel_inspected(rack: int, cell: int, entry: StringName, hovered: bool) -> void:
	_inspect_barrel(rack, cell, entry, hovered)


## CONTRACTS section 23.1 plus P4: a fitted barrel's inspector line. The title reuses the
## chip's own `BARREL_TEXT` line (never a second format string) and the body carries two
## lines - the cell module's catalogue description, then its salvo/dps facts.
func _inspect_barrel(rack: int, cell: int, entry: StringName, shown: bool) -> void:
	if not shown or entry == &"":
		inspect_requested.emit("", "", false)
		return
	var base := _base_id(_profile(), entry)
	var title := BARREL_TEXT % [cell + 1, _module_name(base)]
	inspect_requested.emit(title, _barrel_body(base, rack, cell), false)


## The barrel's two-line inspector body: the catalogue description then the facts line
## (P4/MED-3). Both derive from the catalogue and the component's own tables.
func _barrel_body(base: StringName, rack: int, cell: int) -> String:
	var family := WeaponComponent.weapon_id(base)
	var cycle := WeaponComponent.interval_of(family)
	var salvo: String = STATS_INSTANT if cycle <= 0.0 else "%.2f s" % cycle
	var stats := INSPECT_STATS % [salvo, WeaponComponent.dps_of(family), RACK_LABEL % (rack + 1), cell + 1]
	var described := Catalog.describe(base)
	if described.is_empty():
		return stats
	return described + "\n" + stats


## One bay's own marks and its SALVO strip: the fitted cells (T7: the name marks a fitted
## cell), the ember frame when the bay is selected, and the cycle figure.
func _style_bay(view: Dictionary) -> void:
	var marks: BayMarks = view.get(&"marks", null)
	if marks != null:
		var filled: Array[int] = []
		for ref: Variant in view[&"cells"]:
			filled.append(int(ref))
		marks.configure(_style, filled, int(view[&"rack"]) == _selected_rack)
	var strip: SalvoStrip = view.get(&"strip", null)
	_position_bay(view[&"row"] as Control)
	if strip != null and view.has(&"figure"):
		strip.set_figure(int(view[&"figure"]))


## One rack's cells, as the pane's own read-back hands them out: the W-cell layout
## indices the rack holds, in its own order.
static func _rack_cell_list(refs: Array) -> Array:
	var cells: Array = []
	for ref: Variant in refs:
		cells.append(int(ref))
	return cells


## One rack's salvo gate, the same arithmetic the component fires on (`max` of its
## members' cadences, `WeaponComponent.interval_of`): the rack's slowest member. 0.0 for
## a rack with no travelling member, which reads READY.
##
## A cell holds whatever the fit stores - a base id for a delivered fit, a **rolled
## instance** (`mod_0002`) for a bought or dropped one - so the cell resolves to its
## catalogue base id first. `weapon_id` only strips a `w_` prefix and answers `""` for an
## instance (measured: `weapon_id("mod_0002")` is `""`), which left every instance-keyed
## rack's SALVO drum blank. A base-keyed cell resolves to itself.
func _rack_cycle(refs: Array, cells: Array) -> float:
	var cycle := 0.0
	var profile := _profile()
	for ref: Variant in refs:
		var cell := int(ref)
		if cell < 0 or cell >= cells.size():
			continue
		var base := _base_id(profile, StringName(String(cells[cell])))
		var family := WeaponComponent.weapon_id(base)
		if family == &"":
			continue
		cycle = maxf(cycle, WeaponComponent.interval_of(family))
	return cycle


## The approved figure (Mockup A: `073` = 0.73 s): the cycle in **hundredths** of a
## second, three cells, zero-padded. 0 s has no figure and reads blanks.
func _salvo_figure(cycle: float) -> int:
	if cycle <= 0.0:
		return -1
	return clampi(int(round(cycle * 100.0)), 0, SALVO_MAX)


## The inventory: one row per owned weapon id, in catalogue order, each one a drag
## source. `OWNED ×n` is `PlayerProfile.instances_of(base_id)` - the number of cells one
## install can pair - which is the same figure S4's strip showed.
func _refresh_inventory() -> void:
	_clear(_inventory_rows)
	_inventory_views.clear()
	var rows := inventory_rows()
	if rows.is_empty():
		var empty := _make_caption(INVENTORY_EMPTY)
		empty.name = "Empty"
		_inventory_rows.add_child(empty)
		_lay()
		return
	for entry: Dictionary in rows:
		_build_inventory_row(entry)
	_lay()


func _build_inventory_row(entry: Dictionary) -> Dictionary:
	var base_id: StringName = entry[&"base"]
	var row := InventoryRow.new()
	row.name = "Owned%s" % String(base_id).to_pascal_case()
	row.armory = self
	row.base_id = base_id
	row.focus_mode = Control.FOCUS_ALL
	row.clip_contents = true
	row.custom_minimum_size = Vector2.ONE
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var frame := RowPlate.new()
	frame.name = "RowPlate"
	row.add_child(frame)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.configure(_style)
	var icon_path := ModuleData.icon_path(base_id)
	var icon := _make_icon(icon_path, _style.item_icon)
	if icon != null:
		row.add_child(icon)
	var name_label := _make_caption(String(entry[&"name"]), ROLE_BONE)
	name_label.name = "Name"
	row.add_child(name_label)
	var status := Control.new()
	status.name = "Status"
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(status)
	var status_value := _make_caption("")
	status_value.name = "Value"
	status_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.add_child(status_value)
	var status_caption := _make_caption("")
	status_caption.name = "Caption"
	status.add_child(status_caption)
	var view := {
		&"base": base_id,
		&"name": String(entry[&"name"]),
		&"owned": int(entry[&"owned"]),
		&"draw": int(entry[&"draw"]),
		&"row": row,
		&"plate": frame,
		&"icon": icon,
		&"tinted": _is_flat_glyph(icon_path),
		&"status": status_value,
	}
	row.focus_entered.connect(_on_inventory_focused.bind(base_id, String(entry[&"name"])))
	row.mouse_entered.connect(_on_inventory_inspected.bind(base_id, String(entry[&"name"]), true))
	row.mouse_exited.connect(_on_inventory_inspected.bind(base_id, String(entry[&"name"]), false))
	_inventory_rows.add_child(row)
	_refresh_inventory_row(view)
	_inventory_views.append(view)
	return view


## One inventory row's own figure (the bag's pairing count) and its ink.
func _refresh_inventory_row(view: Dictionary) -> void:
	if not is_node_ready():
		return
	var status: Label = view[&"status"]
	status.text = INVENTORY_TEXT % ["OWNED", int(view[&"owned"])]
	status.add_theme_color_override(&"font_color", _token(ROLE_CAPTION))
	_position_inventory_item(view[&"row"] as Control, Rect2(Vector2.ZERO, (view[&"row"] as Control).size))


func _on_inventory_focused(base_id: StringName, name_text: String) -> void:
	_inspect_module(base_id, name_text, true)


func _on_inventory_inspected(base_id: StringName, name_text: String, hovered: bool) -> void:
	_inspect_module(base_id, name_text, hovered)


func _inspect_module(base_id: StringName, name_text: String, shown: bool) -> void:
	if not shown:
		inspect_requested.emit("", "", false)
		return
	inspect_requested.emit(name_text, Catalog.describe(base_id), false)


## The owned weapon rows, in catalogue order: every `weapons` module of the catalogue
## the bag holds at least one instance of (`instances_of`, S4's own pairing count). The
## module table is the catalogue's own order, so no second list exists.
func inventory_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var profile := _profile()
	if profile == null:
		return rows
	for key: Variant in ModuleData.MODULES:
		var base_id := StringName(str(key))
		if ModuleData.fit_slot_of(base_id) != WEAPON_SLOT:
			continue
		var owned := (profile.call(&"instances_of", base_id) as Array).size()
		if owned <= 0:
			continue
		rows.append({
			&"base": base_id,
			&"name": _module_name(base_id),
			&"owned": owned,
			&"draw": int(ModuleData.module(base_id).get(&"draw", 0)),
		})
	return rows


## Every drawn rack as `{rack, label, state, salvo, barrels, cells, figure}` - `barrels`
## is one `{cell, name, close, text}` per fitted cell and `cells` the rack's W-cell
## indices in its own order. Probes and suites read the racks through this rather than
## walking the tree.
func rack_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for view: Dictionary in _rack_views:
		var barrels: Array = []
		for barrel: Dictionary in view[&"barrels"]:
			barrels.append({
				&"cell": int(barrel[&"cell"]),
				&"text": String(barrel[&"text"]),
			})
		rows.append({
			&"rack": int(view[&"rack"]),
			&"label": String(view[&"label"]),
			&"state": (view[&"state"] as Label).text,
			&"salvo": String(view[&"salvo"]),
			&"cells": view[&"cells"],
			&"barrels": barrels,
			&"figure": int(view[&"figure"]),
		})
	return rows


## One bay's SALVO readout as the pane drew it: the strip's three cells (`-1` = blank) and
## the figure it was handed (-1 for a rack with no travelling member).
func salvo_readout(rack: int) -> Dictionary:
	if rack < 0 or rack >= _rack_views.size():
		return {&"figure": -1, &"cells": []}
	var strip: SalvoStrip = _rack_views[rack][&"strip"]
	return {
		&"figure": int(_rack_views[rack][&"figure"]),
		&"cells": strip.cells() if strip != null else [],
		&"text": strip.figure_text() if strip != null else "",
	}


## One bay's code-drawn marks (the fitted cells and the selected frame).
func bay_marks(rack: int) -> BayMarks:
	if rack < 0 or rack >= _rack_views.size():
		return null
	return _rack_views[rack][&"marks"]


## Every bay's rect as drawn (the five-across band, in the console's own space).
func bay_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	if _style == null:
		return out
	var console := Rect2(_console.position, _console.size)
	for index in _rack_views.size():
		out.append(_style.bay_rect(index, console))
	return out


## The wells band's two halves as drawn.
func well_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	if _style == null:
		return out
	var console := Rect2(_console.position, _console.size)
	out.append(_style.well_half_rect(0, console))
	out.append(_style.well_half_rect(1, console))
	return out


## The console's own size as drawn.
func block_size() -> Vector2:
	return _console.size


## The inventory rows as drawn, in order, `{base, name, owned, draw, text}`.
func inventory_view_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for view: Dictionary in _inventory_views:
		rows.append({
			&"base": view[&"base"],
			&"name": view[&"name"],
			&"owned": int(view[&"owned"]),
			&"draw": int(view[&"draw"]),
			&"text": (view[&"status"] as Label).text,
		})
	return rows


## ------------------------------------------------------------- the drag interface


## The payload an inventory row drags: its base id. `{}` (a drag the engine cancels, and
## a `null` return from `_get_drag_data`) for a base the bag holds none of.
func drag_inventory(base_id: StringName) -> Dictionary:
	var profile := _profile()
	if profile == null or base_id == &"":
		return {}
	if (profile.call(&"instances_of", base_id) as Array).is_empty():
		return {}
	return {DRAG_KEY_KIND: DRAG_INVENTORY, DRAG_KEY_BASE: base_id}


## The payload a barrel chip drags: its address in the racks.
func drag_barrel(rack: int, slot: int) -> Dictionary:
	if rack < 0 or rack >= _rack_views.size():
		return {}
	var refs: Array = _rack_views[rack][&"cells"]
	if slot < 0 or slot >= refs.size():
		return {}
	return {DRAG_KEY_KIND: DRAG_BARREL, DRAG_KEY_RACK: rack, DRAG_KEY_POSITION: slot}


## Whether one drop would be accepted, without writing anything: the pure half of
## `drop`, which is what `_can_drop_data` answers the engine with. `position` is
## `DROP_RACK_BODY` for a drop on the rack itself and a barrel's index for a drop on that
## barrel.
func can_drop(rack: int, slot: int, payload: Variant) -> bool:
	var data := _payload_of(payload)
	if data.is_empty():
		return false
	var profile := _profile()
	if profile == null:
		return false
	var hull := _active_hull(profile)
	if String(data[DRAG_KEY_KIND]) == String(DRAG_INVENTORY):
		## An inventory weapon installs into the rack's next free W cell: a drop on a
		## barrel has no meaning (a swap needs a barrel of the same kind to seat, and the
		## install route is the rack's own body).
		if slot != DROP_RACK_BODY:
			return false
		return _can_install(profile, hull, rack, StringName(data[DRAG_KEY_BASE]))
	if String(data[DRAG_KEY_KIND]) == String(DRAG_BARREL):
		var from_rack := int(data[DRAG_KEY_RACK])
		var from_position := int(data[DRAG_KEY_POSITION])
		## A drop on the rack's own body appends to the **target** rack (the same point
		## `drop` uses), so the preview and the write cannot disagree about the address.
		var to_slot := slot if slot != DROP_RACK_BODY else _rack_end(rack)
		return _can_move(hull, from_rack, from_position, rack, to_slot)
	return false


## Perform one drop: the writing half of the drag interface, exactly the action
## `can_drop` previewed. `false` (with the footer's refusal) when the drop is refused -
## and a refused drop writes nothing at all, fit, bag and rack record alike.
func drop(rack: int, slot: int, payload: Variant) -> bool:
	var data := _payload_of(payload)
	if data.is_empty():
		return false
	if String(data[DRAG_KEY_KIND]) == String(DRAG_INVENTORY):
		return install_weapon(rack, StringName(data[DRAG_KEY_BASE]))
	if String(data[DRAG_KEY_KIND]) == String(DRAG_BARREL):
		var from_rack := int(data[DRAG_KEY_RACK])
		var from_position := int(data[DRAG_KEY_POSITION])
		var to_slot := slot if slot != DROP_RACK_BODY else _rack_end(rack)
		return move_barrel(from_rack, from_position, rack, to_slot)
	return _refuse(REFUSAL_FIT_ILLEGAL)


## The payload dictionary of a drop, `{}` for anything that is not one of the two the
## pane hands out (the engine hands back whatever `_get_drag_data` returned, so this is
## the one place a malformed payload is rejected).
static func _payload_of(payload: Variant) -> Dictionary:
	if not payload is Dictionary:
		return {}
	var data: Dictionary = payload
	if not data.has(DRAG_KEY_KIND):
		return {}
	return data


## The last barrel position of one rack's chip list, the insert point of a drop on the
## rack's own body: the rack's own order, so a between-rack drag appends there and a
## within-rack drag lands past its last barrel (a no-op the profile's guards refuse,
## which is the honest reading - the rack's body is not a barrel to swap with).
func _rack_end(rack: int) -> int:
	if rack < 0 or rack >= _rack_views.size():
		return 0
	return (_rack_views[rack][&"cells"] as Array).size()


## One rack's own cell count, read from the profile's derived racks (the same list the
## pane draws), so the pane's preview and the profile's transaction measure the same
## thing. 0 for a rack the hull's record does not reach.
func _rack_cells_of(profile: ProfileScript, hull: StringName, rack: int) -> int:
	if profile == null or hull == &"" or rack < 0:
		return 0
	var groups: Array = profile.call(&"battery_groups", hull)
	if rack >= groups.size():
		return 0
	return (groups[rack] as Array).size()


## ------------------------------------------------------------------ the rack actions


## Install one inventory weapon into one rack's next free W cell (09 section 11): the
## profile's composed `fit_into_rack`, which pairs the next in-bag instance of the base
## into the cell and records the cell in the rack, atomically over the fit, the bag and
## the record. Refused, writing nothing, when the rack is outside `B1..B5`, the bag holds
## none of the base, every W cell is taken, or the candidate fit is illegal - the
## mandatory set and `fit_legal` are checked **before** the first write, here by the
## preview and again inside the transaction (CONTRACTS section 13 rule 6).
func install_weapon(rack: int, base_id: StringName) -> bool:
	var profile := _profile()
	if profile == null or base_id == &"":
		return false
	var hull := _active_hull(profile)
	var refusal := _install_refusal(profile, hull, rack, base_id)
	if not refusal.is_empty():
		return _refuse(refusal)
	var index := int(profile.call(&"free_weapon_cell", hull))
	## The seed materialises the fit the launch flies, so the transaction's own candidate
	## is the fit this pane drew; a refusal drops it again (`_seed_fit`'s own rule).
	var seeded := _seed_fit(profile, hull)
	if not bool(profile.call(&"fit_into_rack", hull, rack, index, base_id)):
		_unseed_fit(profile, hull, seeded)
		return _refuse(REFUSAL_FIT_ILLEGAL)
	AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
	status_requested.emit(
		STATUS_INSTALLED % [_module_name(base_id), RACK_LABEL % (rack + 1)], false
	)
	return true


## Move one barrel within or between racks (09 section 11: "re-orders and swaps"). Pure
## record surgery in the profile (`move_rack_cell`): the cell keeps its barrel and gains a
## different trigger, so no fit and no bag write happens. Refused, writing nothing, for an
## address that holds no barrel, a target rack outside `B1..B5`, or the same address.
func move_barrel(
	from_rack: int, from_position: int, to_rack: int, to_position: int
) -> bool:
	var profile := _profile()
	if profile == null:
		return false
	var hull := _active_hull(profile)
	if not _can_move(hull, from_rack, from_position, to_rack, to_position):
		return _refuse(REFUSAL_FIT_ILLEGAL)
	if not bool(
		profile.call(&"move_rack_cell", hull, from_rack, from_position, to_rack, to_position)
	):
		return _refuse(REFUSAL_FIT_ILLEGAL)
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	status_requested.emit(
		STATUS_MOVED % [
			_rack_barrel_name(profile, from_rack, from_position), RACK_LABEL % (to_rack + 1)
		],
		false
	)
	return true


## The `x` (or the right-click): the barrel returns to the inventory and its cell is
## emptied
## (`clear_rack_cell`, the composed remove plus the record update). Refused, writing
## nothing, for an address that holds no barrel or a cell the mandatory set protects
## (unreachable for a W cell, measured: `FitData.MANDATORY_SLOT_KEYS` is
## `[engines, power]`).
func remove_barrel(rack: int, slot: int) -> bool:
	var profile := _profile()
	if profile == null:
		return false
	var hull := _active_hull(profile)
	var index := _rack_cell_at(rack, slot)
	if index < 0:
		return _refuse(REFUSAL_FIT_ILLEGAL)
	var name_text := _rack_barrel_name(profile, rack, slot)
	var seeded := _seed_fit(profile, hull)
	if not bool(profile.call(&"clear_rack_cell", hull, index)):
		_unseed_fit(profile, hull, seeded)
		return _refuse(REFUSAL_FIT_ILLEGAL)
	AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
	status_requested.emit(STATUS_REMOVED % name_text, false)
	return true


func _on_remove_barrel(rack: int, slot: int) -> void:
	remove_barrel(rack, slot)


## One barrel chip's address -> its W-cell layout index, -1 for an address the drawn
## racks do not hold.
func _rack_cell_at(rack: int, slot: int) -> int:
	if rack < 0 or rack >= _rack_views.size():
		return -1
	var cells: Array = _rack_views[rack][&"cells"]
	if slot < 0 or slot >= cells.size():
		return -1
	return int(cells[slot])


## One barrel's display name, read from the address: the fits' own base name, `""` for an
## address that holds nothing.
func _rack_barrel_name(profile: ProfileScript, rack: int, slot: int) -> String:
	var index := _rack_cell_at(rack, slot)
	if index < 0:
		return ""
	return _module_name(_base_id(profile, StringName(String(_weapon_cells(profile)[index]))))


## The install's preview, without a write: `""` when the install would be accepted, else
## the pin's own refusal wording. Every guard the transaction makes is made here too, so
## the pane and the profile cannot disagree about a drop (CONTRACTS section 13 rule 6).
func _install_refusal(
	profile: ProfileScript, hull: StringName, rack: int, base_id: StringName
) -> String:
	if rack < 0 or rack >= RACK_COUNT:
		return REFUSAL_FIT_ILLEGAL
	if not _is_weapon_base(base_id):
		return REFUSAL_FIT_ILLEGAL
	## 09 section 12's hardcap: a battery holds `BATTERY_CELLS_MAX` cells, so a drop
	## onto a full rack is refused before the hull's own free cell is read (the profile's
	## `fit_into_rack` refuses it again inside the transaction).
	if _rack_cells_of(profile, hull, rack) >= WeaponComponent.BATTERY_CELLS_MAX:
		return REFUSAL_W_SLOTS_FULL
	if (profile.call(&"instances_of", base_id) as Array).is_empty():
		return REFUSAL_NO_WEAPONS
	var index := int(profile.call(&"free_weapon_cell", hull))
	if index < 0:
		return REFUSAL_W_SLOTS_FULL
	return _cell_refusal(profile, hull, index, base_id)


## Whether one install would be accepted: the boolean half of `_install_refusal`, which is
## what `can_drop` answers with.
func _can_install(
	profile: ProfileScript, hull: StringName, rack: int, base_id: StringName
) -> bool:
	return _install_refusal(profile, hull, rack, base_id).is_empty()


## Whether one barrel move would be accepted: the source must hold a barrel, the target
## rack must be inside `B1..B5`, the target slot must not be negative and the two
## addresses must differ. 09 section 12's four-cell cap refuses the move that would
## **grow** the target past it -- an append past its last barrel; a move onto an occupied
## position is the swap and leaves the target's length alone, so a swap into a four-cell
## battery stays legal. Pure reads - a move writes no fit, so there is nothing else to
## judge.
func _can_move(
	hull: StringName, from_rack: int, from_position: int, to_rack: int, to_position: int
) -> bool:
	if hull == &"" or to_rack < 0 or to_rack >= RACK_COUNT or to_position < 0:
		return false
	if from_rack == to_rack and from_position == to_position:
		return false
	if _rack_cell_at(from_rack, from_position) < 0:
		return false
	if from_rack != to_rack:
		var target_cells := _rack_cells_of(_profile(), hull, to_rack)
		if to_position >= target_cells:
			return target_cells < WeaponComponent.BATTERY_CELLS_MAX
	return true


## The candidate's own legality, judged with the same `ShipFit.fit_legal` the profile
## re-checks on commit: the pin's overload line from `fit_legal`'s power block, or the
## catch-all. `""` when the candidate is legal.
func _cell_refusal(
	profile: ProfileScript, hull: StringName, index: int, entry: StringName
) -> String:
	var candidate := _with_cell(_resolved_fit(profile, hull), WEAPON_SLOT, index, entry)
	var legal := ShipFit.fit_legal(hull, _base_fit(profile, candidate))
	if bool(legal[&"legal"]):
		return ""
	return _fit_refusal(legal)


## The third pinned refusal's own test, byte-equivalent to the FITTING pane's: a fit
## illegal for a reason that is not the power budget has no finer wording than the
## catch-all (CONTRACTS section 16 rule 9).
func _fit_refusal(legal: Dictionary) -> String:
	var power: Dictionary = legal.get(&"power", {})
	if not bool(power.get(&"legal", true)):
		var draws := int(power.get(&"draw", 0))
		var out := int(power.get(&"out", 0))
		return REFUSAL_OVERLOAD % [draws, out, draws - out]
	return REFUSAL_FIT_ILLEGAL


## A refusal: the denied cue and the wording in this pane's footer - `status_requested`,
## never a dialog (STATION_HUB section 5.1).
func _refuse(message: String) -> bool:
	AudioManager.play_ui(AudioManager.UiCue.DENIED)
	status_requested.emit(message, true)
	return false


## ------------------------------------------------------------------- the fit reads


## A fit with every cell exchanged for the base catalogue id behind it, through the
## profile's own `base_fit` (CONTRACTS section 15): the shape `ShipFit` reads. Every
## legality judgement in this pane goes through it, because a fit cell holds an instance
## id.
func _base_fit(profile: ProfileScript, fit: Dictionary) -> Dictionary:
	if profile == null:
		return fit
	var translated: Variant = profile.call(&"base_fit", fit)
	return translated if translated is Dictionary else fit


## `fit` with one cell set, in `fit_for`'s own shape: the same composition the profile's
## own `_with_cell` makes, so a preview and its commit judge one candidate (CONTRACTS
## section 13).
static func _with_cell(
	fit: Dictionary, slot_key: StringName, index: int, module_id: StringName
) -> Dictionary:
	var out: Dictionary = fit.duplicate(true)
	if slot_key == POWER_SLOT:
		out[slot_key] = String(module_id)
		return out
	var cells: Array = out.get(slot_key, out.get(String(slot_key), []))
	while cells.size() <= index:
		cells.append("")
	cells[index] = String(module_id)
	out[slot_key] = cells
	return out


## The fit the panel shows and writes against: the account's own when it holds one, else
## 09 section 9's `ShipFit.standard_fit` - the same resolution `game.gd:_launch_fit_for`
## launches with, so a rack cannot promise a cell the launch would not fly.
func _resolved_fit(profile: ProfileScript, hull: StringName) -> Dictionary:
	if profile != null and hull != &"":
		var stored: Dictionary = profile.call(&"fit_for", hull)
		if _holds_a_module(stored):
			return stored
	return ShipFit.standard_fit(hull)


## Materialise the fit the launch already flies, for the transactions that need one
## written: the composed calls read the module they hand back out of the hull's *stored*
## fit, so a hull the account holds no fit for would refuse to empty the very cells this
## pane draws. The seed writes the same fit the resolution above reads, so the two agree;
## nothing else in the panel writes a whole fit.
##
## **Answers whether it wrote**, because a seed a refusal made pointless must be dropped
## again (`_unseed_fit`): a refused action has to leave the store exactly as it found it
## (CONTRACTS section 16 rules 7-8).
func _seed_fit(profile: ProfileScript, hull: StringName) -> bool:
	var stored: Dictionary = profile.call(&"fit_for", hull)
	if _holds_a_module(stored):
		return false
	var standard := ShipFit.standard_fit(hull)
	if standard.is_empty():
		return false
	profile.call(&"set_fit", hull, standard)
	return true


## Undo a seed whose transaction refused, so the hull is back to holding no stored fit
## and `fits()` reads exactly what it read before the action was taken.
static func _unseed_fit(profile: ProfileScript, hull: StringName, seeded: bool) -> void:
	if seeded:
		profile.call(&"clear_fit", hull)


## Whether a fit holds any module at all: the launch's own test, so an all-empty stored fit
## falls back to the standard fit on both sides.
static func _holds_a_module(fit: Dictionary) -> bool:
	for key: StringName in ShipFit.FIT_SLOT_KEYS:
		var raw: Variant = fit.get(key, fit.get(String(key), null))
		if raw is Array:
			for entry: Variant in raw as Array:
				if String(entry) != "":
					return true
		elif raw is String or raw is StringName:
			if String(raw) != "":
				return true
	return false


## The active hull's W cells, one entry per cell in 09 section 4 item 5's layout order.
## `ShipFit.grid_cells` names every W cell and its layout index and the fit the launch
## resolves supplies the module at that index (`""` for an empty cell, and `""` for a cell
## past the end of a short standard fit), so the list is exactly as long as the hull has W
## cells and an index in it is a cell. Instance ids are handed back as they are stored; the
## callers resolve them through `base_module_id`.
func _weapon_cells(profile: ProfileScript) -> Array:
	var hull := _active_hull(profile)
	var cells: Array = []
	var fitted: Array = []
	if profile != null and hull != &"":
		var raw: Variant = _resolved_fit(profile, hull).get(WEAPON_SLOT, [])
		if raw is Array:
			fitted = raw
	for cell: Dictionary in ShipFit.grid_cells(hull):
		if bool(cell[&"gap"]) or cell[&"type"] != WEAPON_SLOT:
			continue
		var index := int(cell[&"index"])
		cells.append(String(fitted[index]) if index >= 0 and index < fitted.size() else "")
	return cells


## Whether a base id is a weapon module (the rack record's own domain): the drag and the
## install both refuse anything else, so a utility module can never enter a rack.
static func _is_weapon_base(base_id: StringName) -> bool:
	return ModuleData.fit_slot_of(base_id) == WEAPON_SLOT


func _active_hull(profile: ProfileScript) -> StringName:
	if profile == null:
		return &""
	return StringName(profile.call(&"active_ship"))


func _base_id(profile: ProfileScript, entry: StringName) -> StringName:
	if profile == null or entry == &"":
		return entry
	return StringName(profile.call(&"base_module_id", entry))


func _module_name(module_id: StringName) -> String:
	var name_text := String(ModuleData.module(module_id).get(&"name", ""))
	return name_text.to_upper() if not name_text.is_empty() else String(module_id).to_upper()


## ------------------------------------------------------------------- the refresh


func _refresh_all() -> void:
	_refresh_rows()
	_refresh_racks()
	_refresh_inventory()


func _profile() -> ProfileScript:
	## Autoloads are children of /root; STATION_HUB section 12.4 names a bare
	## ^"PlayerProfile" path, which would resolve against this node instead, so the
	## lookup is anchored at the tree root the way router.gd anchors its services.
	if not is_inside_tree():
		return null
	var service := get_tree().root.get_node_or_null(NodePath(PROFILE_SERVICE))
	if service == null:
		return null
	var profile: ProfileScript = service
	return profile


func _pulse(node: CanvasItem) -> void:
	if node == null:
		return
	var tween := _make_tween()
	tween.tween_property(node, "modulate:a", PULSE_MIN_ALPHA, PULSE_DOWN_SECONDS).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "modulate:a", 1.0, PULSE_UP_SECONDS).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "modulate:a", PULSE_MIN_ALPHA, PULSE_DOWN_SECONDS).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "modulate:a", 1.0, PULSE_UP_SECONDS).set_trans(Tween.TRANS_SINE)


func _make_tween() -> Tween:
	for index in range(_tweens.size() - 1, -1, -1):
		if not _tweens[index].is_valid():
			_tweens.remove_at(index)
	var tween := create_tween()
	_tweens.append(tween)
	return tween


func _format_int(value: int) -> String:
	var digits := str(absi(value))
	var grouped := ""
	var count := 0
	for index in range(digits.length() - 1, -1, -1):
		grouped = digits[index] + grouped
		count += 1
		if count % 3 == 0 and index > 0:
			grouped = " " + grouped
	return ("-" if value < 0 else "") + grouped
