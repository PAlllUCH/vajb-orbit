extends VBoxContainer
## FITTING module panel: the active hull's SLOT LAYOUT grid (the shipyard's own recipe, made
## selectable), the OWNED MODULES rows, and the footer strip that carries the power meter, the
## selected cell's line and the per-cell REMOVE. Contract: docs/design/STATION_HUB.md sections
## 5.3 (the 2026-09-22 P2-B proper amendment), 5.1's host-pane construct, 10 and 12,
## docs/CONTRACTS.md section 13, docs/gameplay/09_ship_slots_modules.md sections 1, 2, 4, 7
## and 8.
##
## The pane requests and never mutates (STATION_HUB section 12.4, CONTRACTS section 13 rule 5):
## an install or a swap is the one composed `PlayerProfile.fit_module_at`, a remove the
## composed `clear_fit_slot`, and the pane reads `resolved_fit` (the launch's own fallback,
## the fit the preview and the commit both judge), `module_count`, `modules` and
## `ShipFit` only - it writes no fit, no inventory and no credits itself. Legality is previewed
## with the same `ShipFit.fit_legal` the profile re-checks on commit; a refused action renders
## one of the three pinned wordings in this pane's footer strip and in the shell's status
## strip, never a dialog, and nothing auto-removes (09 section 2).
##
## The SLOT LAYOUT grid is the shipyard's recipe: `ShipFit.grid_cells`, a 48 px
## `SlotButtonWeapon` plate per non-gap cell, a gap an empty 48 x 48 `Control`, the type's slot
## glyph, the caption `SLOT LAYOUT · <n> CELLS · <m> ENGINES`, `h_separation`/`v_separation` 4
## and the same 6 px glyph inset. Unlike the shipyard's display these cells are selectable: one
## at a time, `FOCUS_ALL`, the selection drawn with the plate's pressed state and the theme's
## shared focus ring on the focused cell (STATION_HUB section 10). A cell's identity is its
## `slot_key` plus its 09 section 4.5 layout index.
##
## Panel contract with the shell:
##   signal status_requested(message: String, danger: bool)   write the shell's footer strip
##   func refresh_profile(key: StringName) -> void             react to profile_changed
##   func focus_primary() -> void                              focus entry after a switch

const TOKENS_TYPE: StringName = &"Tokens"

const ProfileScript := preload("res://autoload/player_profile.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"

signal status_requested(message: String, danger: bool)

## ------------------------------------------------ the section 5.1 host-pane construct
const ROW_HEIGHT := 76.0
const ROW_GAP := 6
const COL_ICON := 48.0
const COL_OWNED := 160.0
const COL_ACTION := 160.0
const ROW_INNER_MARGIN := Vector2i(12, 8)
const COLUMN_SEPARATION := 12
const CELL_SEPARATION := 2
const ROW_ICON_IDLE_ALPHA := 0.72
const HOVER_SECONDS := 0.09

## ------------------------------------------------- the shipyard's own grid recipe (5.2)
const PLATE_VARIATION: StringName = &"SlotButtonWeapon"
const PLATE_SIZE := 48.0
const PLATE_SEPARATION := 4
## ui/components/slot_button.tscn insets its glyph 6 px inside the 48 px plate; the layout
## grid reuses that one number rather than inventing a second inset.
const PLATE_ICON_INSET := 6.0
## CONTRACTS section 11's caption, the shipyard's own string: the hull's slot count (gaps are
## not cells) and its ENGINE count.
const HARDPOINT_CAPTION := "SLOT LAYOUT · %d CELLS · %d ENGINES"

## 09 section 1's slot glyph per slot-type key. The glyph files are named by the document's own
## stems (`icon_slot_engine`, `icon_slot_power`, `icon_slot_w`, ...), which are not the API's
## key names, so the mapping is stated once here - the shipyard's own table, cell for cell.
const SLOT_GLYPHS: Dictionary = {
	&"engines": "engine",
	&"power": "power",
	&"weapons": "w",
	&"shields": "s",
	&"armour": "h",
	&"computers": "c",
	&"boosters": "b",
	&"utility": "u",
}
const SLOT_GLYPH_DIR := "res://assets/icons/slot/"
const SLOT_GLYPH_TEMPLATE := "icon_slot_%s.svg"

## The module catalogue's own slot key for an ENGINE module is 09 section 1's singular type
## name (`engine`), while the fit's set key is `engines` (`ShipFit.FIT_SLOT_KEYS`) - the same
## pair `ShipFit._engine_slot` bridges when it reads a legacy fit. This is the one alias the
## pane needs so a thruster row can find an ENGINE cell; no third spelling and no second key
## list is declared (CONTRACTS section 13 rule 1).
const SLOT_KEY_ALIASES: Dictionary = {&"engine": &"engines"}

## Audit anomaly C16, the OUTFITTING pane's own rule: these three catalogue weapon icons are
## flat Phase B glyphs (mean RGB about 40, 44, 47) that read as near-black shapes on the row
## chrome, so the row draws the derived icons/tint/ stencil moderated with Tokens/text_primary
## instead. Every other catalogue icon is painted and is drawn at full colour.
const FLAT_GLYPH_ICONS: Array[String] = [
	"res://assets/icons/weapon/icon_weapon_cannon.svg",
	"res://assets/icons/weapon/icon_weapon_mine.svg",
	"res://assets/icons/weapon/icon_weapon_plasma.svg",
]
const TINT_DIR := "res://assets/icons/tint/"

## ------------------------------------------------------------------------ the wordings
## Every string below is STATION_HUB section 5.3's, 09 section 2's or a catalogue string; none
## is this pass's invention. `SELECT A CELL` is the pin's own word for the no-selection state
## (its disabled ACTION) and doubles as the footer line's idle form, so the footer is never
## blank - the pin's own rule.
const ACTIVE_HULL := "ACTIVE HULL %s"
const OWNED_CAPTION := "OWNED MODULES"
const EMPTY_ROW := "NO MODULES OWNED · BUY THEM IN OUTFITTING"

const META_FORMAT := "SLOT %s · DRAW %d"
const OWNED_FORMAT := "OWNED ×%d"
const ACTION_FIT: StringName = &"FIT"
const ACTION_SWAP: StringName = &"SWAP"
const ACTION_SELECT: StringName = &"SELECT A CELL"

const SELECTION_FORMAT := "%s%d · %s · OWNED ×%d"
const CELL_EMPTY := "EMPTY"

const METER_IDLE := "PWR %d / %d"
const METER_CANDIDATE := "PWR %d / %d · CANDIDATE %d / %d"
const METER_OVER := " — OVER BY %d"

const REFUSAL_OVERLOAD := "%d / %d PWR — OVER BY %d"
const REFUSAL_MANDATORY := "MANDATORY CELL — SWAP ONLY, NEVER EMPTY"
const REFUSAL_FIT_ILLEGAL := "REFUSED · FIT ILLEGAL"

const REMOVE_ACTION := "REMOVE"

const POWER_SLOT: StringName = &"power"

@onready var _subtitle: Label = %PaneSubtitle
@onready var _scroll: ScrollContainer = %FittingScroll
@onready var _slot_caption: Label = %SlotCaption
@onready var _owned_caption: Label = %OwnedCaption
@onready var _grid: GridContainer = %SlotLayoutGrid
@onready var _rows: VBoxContainer = %ModuleRows
@onready var _meter: Label = %MeterLabel
@onready var _line: Label = %SelectionLine
@onready var _remove: Button = %RemoveButton

## The OWNED MODULES rows: {id, name, slot, draw, empty, owned, action, row, icon, tinted}.
var _payloads: Array[Dictionary] = []
## The grid's cells: {type, token, index, node} for every non-gap cell, row-major, which is also
## the pane's focus order for those cells.
var _cells: Array[Dictionary] = []
## The selected cell's identity: {} or {type, token, index}. Its node is looked up in `_cells`,
## so a rebuilt grid keeps the selection and a Dictionary comparison stays by value.
var _selected: Dictionary = {}
## The module id the meter previews (the focused or hovered OWNED MODULES row), &"" for none.
var _candidate: StringName = &""
## The hull the grid was built for, so a refresh of the same hull never frees its cells.
var _grid_hull: StringName = &""
## The footer line's override - a refusal (danger) or the `SELECT A CELL` notice - and whether
## it is drawn in the danger colour. Cleared by the next selection move.
var _line_override := ""
var _line_danger := false
## The row ids the current row set was built for, so a refresh that does not move the inventory
## never rebuilds what is already on screen.
var _row_ids: Array[StringName] = []
var _rows_built := false
var _selected_row: Button = null
var _tweens: Array[Tween] = []


func _ready() -> void:
	## The two words the pane's own controls carry, named here so a test can read them off the
	## script instead of off the scene file.
	_owned_caption.text = OWNED_CAPTION
	_remove.text = REMOVE_ACTION
	_connect_scroll()
	_remove.pressed.connect(_on_remove_pressed)
	_apply_tokens()
	_refresh_all()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_apply_tokens()


func _exit_tree() -> void:
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()


func refresh_profile(key: StringName) -> void:
	## STATION_HUB section 12.4: &"fits" and &"modules" rebuild this pane's grid, its OWNED
	## MODULES rows and its power meter; &"ships" moves the active hull, which is the grid's
	## own source. Every other key belongs to another panel.
	if key == &"fits" or key == &"modules" or key == &"ships":
		_refresh_all()


func focus_primary() -> void:
	## The focus order's first stop (STATION_HUB section 10): the SLOT LAYOUT cells, row-major.
	for payload: Dictionary in _cells:
		var plate: Button = payload[&"node"]
		if plate != null and is_instance_valid(plate) and not plate.disabled:
			plate.grab_focus()
			return
	for payload: Dictionary in _payloads:
		var row: Button = payload[&"row"]
		if row != null and is_instance_valid(row) and not row.disabled:
			row.grab_focus()
			return


## -------------------------------------------------------------------- the pane's own reads


## The active hull, the same source the grid, the caption, the fit and the meter read.
func active_hull() -> StringName:
	return _active_hull(_profile())


## The cell the pane has selected, `{type, token, index}`, or `{}` when nothing is selected.
func selected_cell() -> Dictionary:
	return _selected.duplicate()


## The OWNED MODULES row ids in render order, read back for probes and tests: one row per owned
## module id, ordered by `ShipFit.FIT_SLOT_KEYS` and then by catalogue order (STATION_HUB
## section 5.3). Empty in the empty state, which is one row and no module.
func module_row_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for payload: Dictionary in _payloads:
		if bool(payload.get(&"empty", false)):
			continue
		ids.append(payload[&"id"])
	return ids


## The ACTION word one owned module's row carries right now: `FIT` when a cell of the module's
## own type is selected and that cell is empty, `SWAP` when it already holds a module (the same
## composed call - the displaced one returns to the inventory), and `SELECT A CELL` when no
## cell is selected or the selected cell is of another type.
func module_action(module_id: StringName) -> StringName:
	var profile := _profile()
	if profile == null or module_id == &"":
		return &""
	var cell := _row_target_cell(module_id)
	if cell.is_empty():
		return ACTION_SELECT
	var hull := _active_hull(profile)
	var fit := _resolved_fit(profile, hull)
	var occupant := _cell_module(fit, StringName(cell[&"type"]), int(cell[&"index"]))
	return ACTION_SWAP if occupant != &"" else ACTION_FIT


## Select one cell by its 09 section 4.5 identity, the keyboard's and a probe's door into the
## same selection a click makes. False when the active hull carries no such cell.
func select_cell(slot_key: StringName, index: int) -> bool:
	for payload: Dictionary in _cells:
		if payload[&"type"] == slot_key and int(payload[&"index"]) == index:
			_select(payload, false)
			return true
	return false


func clear_selection() -> void:
	_selected = {}
	_candidate = &""
	_line_override = ""
	_line_danger = false
	_apply_selection()
	_refresh_rows(_profile())
	_refresh_footer()


## The meter's own text, read back for probes and tests: the idle form without a selection and
## the candidate's form with one.
func meter_text() -> String:
	return _meter.text


## The footer line's text, read back for probes and tests: the selected cell's line, the idle
## hint, or a refusal.
func footer_text() -> String:
	return _line.text


## -------------------------------------------------------------------------- the two actions


## Whether the per-cell REMOVE is offered: a cell is selected and it holds a module.
func can_remove() -> bool:
	var profile := _profile()
	if profile == null or _selected.is_empty():
		return false
	var hull := _active_hull(profile)
	var fit := _resolved_fit(profile, hull)
	return _cell_module(fit, StringName(_selected[&"type"]), int(_selected[&"index"])) != &""


## The composed install: `PlayerProfile.fit_module_at` on the selected cell (STATION_HUB
## section 5.3, CONTRACTS section 13). The candidate fit is judged with `ShipFit.fit_legal`
## first, so an illegal one is refused before anything is written and renders the pin's own
## wording; a module the inventory does not hold is refused by the profile.
func install_module(module_id: StringName) -> bool:
	var profile := _profile()
	var cell := _row_target_cell(module_id)
	if profile == null or cell.is_empty():
		return false
	var hull := _active_hull(profile)
	var slot_key: StringName = cell[&"type"]
	var index := int(cell[&"index"])
	var legal := ShipFit.fit_legal(hull, _candidate_fit(profile, hull, slot_key, index, module_id))
	if not bool(legal[&"legal"]):
		return _refuse(_fit_refusal(legal))
	if not bool(profile.call(&"fit_module_at", hull, slot_key, index, module_id)):
		return _refuse(REFUSAL_FIT_ILLEGAL)
	_clear_notice()
	AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
	return true


## The composed remove of the selected cell: `PlayerProfile.clear_fit_slot`. A cell whose key is
## in `ShipFit.MANDATORY_SLOT_KEYS` (`[engines, power]`, 09 section 4.1, the one source) is never
## emptied and answers the pin's own wording; the profile refuses it either way.
func remove_selected() -> bool:
	var profile := _profile()
	if profile == null or _selected.is_empty():
		return false
	var hull := _active_hull(profile)
	var slot_key: StringName = _selected[&"type"]
	var index := int(_selected[&"index"])
	if ShipFit.MANDATORY_SLOT_KEYS.has(slot_key):
		return _refuse(REFUSAL_MANDATORY)
	var module_id := _cell_module(_resolved_fit(profile, hull), slot_key, index)
	if module_id == &"":
		return false
	if not bool(profile.call(&"clear_fit_slot", hull, slot_key, index)):
		return _refuse(REFUSAL_FIT_ILLEGAL)
	_clear_notice()
	AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
	return true


## The third pinned refusal's own test: a fit that is illegal for a reason that is not the power
## budget has no finer wording, so the catch-all answers.
func _fit_refusal(legal: Dictionary) -> String:
	var power: Dictionary = legal.get(&"power", {})
	if not bool(power.get(&"legal", true)):
		var draws := int(power.get(&"draw", 0))
		var out := int(power.get(&"out", 0))
		return REFUSAL_OVERLOAD % [draws, out, draws - out]
	return REFUSAL_FIT_ILLEGAL


func _refuse(message: String) -> bool:
	AudioManager.play_ui(AudioManager.UiCue.DENIED)
	_notice(message, true)
	return false


## The footer line carries the words, the shell's strip carries the same line, and neither is a
## dialog (STATION_HUB section 5.3, section 12.4).
func _notice(message: String, danger: bool) -> void:
	_line_override = message
	_line_danger = danger
	status_requested.emit(message, danger)
	_refresh_footer()


## A successful action drops the line the previous refusal left behind and repaints the footer,
## so a press that worked never keeps reading the refusal it was told before: the footer comes
## back to the selected cell's own line and the shell's strip is handed that same line, the way
## `_notice` hands it a refusal (STATION_HUB section 5.3 - a refusal's line belongs to the press
## that made it, and this pane publishes its own line whenever it has one).
func _clear_notice() -> void:
	_line_override = ""
	_line_danger = false
	_refresh_footer()
	status_requested.emit(_line.text, false)


## -------------------------------------------------------------------------------- the grid


## Build (or keep) the SLOT LAYOUT grid for `hull`. The grid is a function of the hull's own
## matrix, so it is rebuilt when that matrix changes - a hull switch, or the first build. A
## refresh of the same hull keeps its cells and only re-applies the selection, which is what
## lets a cell stay selected across the very transaction the player just made.
func _sync_grid(hull: StringName) -> void:
	if hull == _grid_hull and not _cells.is_empty():
		_apply_selection()
		return
	_grid_hull = hull
	_cells.clear()
	_selected = {}
	_candidate = &""
	for child: Node in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	var cells: Array = ShipFit.grid_cells(hull)
	if cells.is_empty():
		## A hull id with no matrix (an unknown or an NPC hull) draws no cells at all and
		## leaves the grid and its caption empty, exactly as the shipyard's display does.
		_grid.columns = 1
		_slot_caption.text = ""
		return
	_grid.columns = ShipFit.grid_size(hull).x
	var slot_cells := 0
	for cell: Dictionary in cells:
		if bool(cell[&"gap"]):
			_grid.add_child(_make_gap_cell())
		else:
			_cells.append(_make_slot_cell(cell))
			slot_cells += 1
	var engines := int(ShipFit.grid_counts(hull).get(&"engines", 0))
	_slot_caption.text = HARDPOINT_CAPTION % [slot_cells, engines]


## The shipyard's own gap: an empty 48 x 48 `Control` carrying no plate.
func _make_gap_cell() -> Control:
	var cell := Control.new()
	cell.name = "Gap"
	cell.custom_minimum_size = Vector2(PLATE_SIZE, PLATE_SIZE)
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return cell


## One non-gap matrix cell. The recipe is the shipyard's: a 48 px `SlotButtonWeapon` plate and
## the type's slot glyph inset 6 px. Unlike the shipyard's display the plate is selectable
## (`FOCUS_ALL`, not `disabled`), so it draws the theme's shared focus ring while it holds the
## ring and its pressed plate while it is the selected cell. Its name carries its token and its
## 09 section 4.5 layout index.
func _make_slot_cell(cell: Dictionary) -> Dictionary:
	var slot_key: StringName = cell[&"type"]
	var plate := Button.new()
	plate.name = "Slot%s%02d" % [String(cell[&"token"]), int(cell[&"index"])]
	plate.theme_type_variation = PLATE_VARIATION
	plate.toggle_mode = true
	plate.focus_mode = Control.FOCUS_ALL
	plate.custom_minimum_size = Vector2(PLATE_SIZE, PLATE_SIZE)
	plate.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_grid.add_child(plate)
	var glyph := TextureRect.new()
	glyph.name = "Icon"
	glyph.custom_minimum_size = Vector2(
		PLATE_SIZE - PLATE_ICON_INSET * 2.0, PLATE_SIZE - PLATE_ICON_INSET * 2.0
	)
	glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.texture = _slot_glyph(slot_key)
	glyph.modulate = _token(&"text_dim")
	plate.add_child(glyph)
	glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glyph.offset_left = PLATE_ICON_INSET
	glyph.offset_top = PLATE_ICON_INSET
	glyph.offset_right = -PLATE_ICON_INSET
	glyph.offset_bottom = -PLATE_ICON_INSET
	var payload := {
		&"type": slot_key,
		&"token": String(cell[&"token"]),
		&"index": int(cell[&"index"]),
		&"node": plate,
	}
	plate.pressed.connect(_on_cell_pressed.bind(payload))
	plate.focus_entered.connect(_on_cell_focused.bind(payload))
	return payload


## 09 section 1's shipped slot glyph for a slot-type key: `icon_slot_<stem>_48.png`. Null for a
## type with no glyph (never one of the eight), so the cell then draws its plate alone.
func _slot_glyph(slot_key: StringName) -> Texture2D:
	var stem := String(SLOT_GLYPHS.get(slot_key, ""))
	if stem.is_empty():
		return null
	var path := SLOT_GLYPH_DIR + SLOT_GLYPH_TEMPLATE % stem
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _apply_selection() -> void:
	for payload: Dictionary in _cells:
		var plate: Button = payload[&"node"]
		if plate == null or not is_instance_valid(plate):
			continue
		plate.set_pressed_no_signal(_is_selected(payload))


func _is_selected(payload: Dictionary) -> bool:
	return (
		not _selected.is_empty()
		and payload[&"type"] == _selected[&"type"]
		and int(payload[&"index"]) == int(_selected[&"index"])
	)


## One cell, selected: the identity is kept (the grid may be rebuilt under it), the override
## clears, the rows' ACTION words move and the footer's line and meter follow. A click and a
## focus move both arrive here, so the keyboard's ring and the selection never disagree.
func _select(payload: Dictionary, clicked: bool) -> void:
	if clicked:
		AudioManager.play_ui(AudioManager.UiCue.CLICK)
	else:
		AudioManager.play_ui(AudioManager.UiCue.HOVER)
	_selected = {
		&"type": payload[&"type"],
		&"token": payload[&"token"],
		&"index": int(payload[&"index"]),
	}
	_line_override = ""
	_line_danger = false
	_apply_selection()
	_refresh_rows(_profile())
	_refresh_footer()


func _on_cell_pressed(payload: Dictionary) -> void:
	_select(payload, true)


func _on_cell_focused(payload: Dictionary) -> void:
	## A focus move is a selection move: one cell is selected at a time and the focused cell is
	## the ring the player is reading (STATION_HUB section 5.3, section 10).
	_select(payload, false)


## ------------------------------------------------------------------- the OWNED MODULES rows


## The owned module ids and their totals, one entry per base id: the inventory's own keys
## aggregated through `base_module_id`, and an id the catalogue cannot name (no name, no slot,
## no draw) never becomes a row.
func _owned_counts(profile: ProfileScript) -> Dictionary:
	var counts: Dictionary = {}
	if profile == null:
		return counts
	for key: Variant in profile.call(&"modules"):
		var entry := StringName(str(key))
		var held := int(profile.call(&"module_count", entry))
		if held <= 0:
			continue
		var base := StringName(profile.call(&"base_module_id", entry))
		if ModuleCatalog.module(base).is_empty():
			continue
		counts[base] = int(counts.get(base, 0)) + held
	return counts


## The row ids in render order: `ShipFit.FIT_SLOT_KEYS` first, catalogue order inside a group.
func _owned_ids(counts: Dictionary) -> Array[StringName]:
	var ids: Array[StringName] = []
	for slot_key: StringName in ShipFit.FIT_SLOT_KEYS:
		for module_id: StringName in ModuleCatalog.MODULES:
			if not counts.has(module_id):
				continue
			if _slot_key_of(module_id) == slot_key:
				ids.append(module_id)
	return ids


func _refresh_rows(profile: ProfileScript) -> void:
	var ids := _owned_ids(_owned_counts(profile))
	if not _rows_built or ids != _row_ids:
		_rows_built = true
		if ids.is_empty():
			_build_empty_row()
		else:
			_build_rows(ids)
		_row_ids = ids
	for payload: Dictionary in _payloads:
		_refresh_row(payload, profile)
	if _candidate != &"" and not ids.has(_candidate):
		_candidate = &""


## Rebuild the rows, then refresh each one. A rebuild during a signal handler (the profile
## emits profile_changed from inside a transaction) detaches the old nodes first and frees them
## deferred, which is the one safe way to remove the very Button whose press is still on the
## stack.
func _build_rows(ids: Array[StringName]) -> void:
	_clear_rows()
	for module_id: StringName in ids:
		_payloads.append(_build_row(module_id))
	_add_slack()


## The empty state (STATION_HUB section 5.3): an account that owns no modules shows one disabled
## row carrying the pin's own words.
func _build_empty_row() -> void:
	_clear_rows()
	var row := Button.new()
	row.name = "NoModules"
	row.disabled = true
	row.focus_mode = Control.FOCUS_NONE
	row.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	var box := _make_inner(row)
	var label := _make_label(&"StationValue", EMPTY_ROW)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(label)
	_rows.add_child(row)
	_payloads.append({&"id": &"", &"empty": true, &"row": row})


func _clear_rows() -> void:
	_payloads.clear()
	_row_ids.clear()
	_selected_row = null
	for child: Node in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()


func _build_row(module_id: StringName) -> Dictionary:
	var module_row := ModuleCatalog.module(module_id)
	var name_text := String(module_row.get(&"name", ""))
	var icon_path := String(module_row.get(&"icon", ""))
	var row := Button.new()
	row.name = "Module%s" % String(module_id).to_pascal_case()
	row.toggle_mode = true
	row.focus_mode = Control.FOCUS_ALL
	row.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row.set_meta(&"id", module_id)
	var box := _make_inner(row)
	var icon := _make_icon(icon_path)
	if icon != null:
		box.add_child(icon)
	box.add_child(_make_title_box(name_text, _meta_of(module_row)))
	var owned := _make_cell(box, COL_OWNED, "Owned")
	var action := _make_cell(box, COL_ACTION, "Action")
	var payload := {
		&"id": module_id,
		&"name": name_text,
		&"slot": StringName(module_row.get(&"slot", &"")),
		&"draw": int(module_row.get(&"draw", 0)),
		&"empty": false,
		&"row": row,
		&"icon": icon,
		&"tinted": _is_flat_glyph(icon_path),
		&"owned": owned,
		&"action": action,
	}
	row.pressed.connect(_on_module_pressed.bind(payload))
	row.focus_entered.connect(_on_module_focused.bind(row, payload))
	row.mouse_entered.connect(_on_module_hovered.bind(payload, true))
	row.mouse_exited.connect(_on_module_hovered.bind(payload, false))
	_rows.add_child(row)
	return payload


## The row's meta, `SLOT <TYPE> · DRAW <n>`: the module's own slot type and its 09 section 3
## draw, both catalogue values.
func _meta_of(module_row: Dictionary) -> String:
	var slot := String(module_row.get(&"slot", &"")).to_upper()
	return META_FORMAT % [slot, int(module_row.get(&"draw", 0))]


func _refresh_row(payload: Dictionary, profile: ProfileScript) -> void:
	if bool(payload.get(&"empty", false)):
		return
	var module_id: StringName = payload[&"id"]
	var owned: Label = payload[&"owned"]
	var action: Label = payload[&"action"]
	var held := 0
	if profile != null:
		held = int(profile.call(&"module_count", module_id))
	owned.text = OWNED_FORMAT % held
	action.text = String(module_action(module_id))


func _make_title_box(name_text: String, meta_text: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = "TitleBox"
	box.add_theme_constant_override(&"separation", CELL_SEPARATION)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := _make_label(&"StationValue", name_text)
	title.name = "Title"
	box.add_child(title)
	var meta := _make_label(&"StationCaption", meta_text)
	meta.name = "Meta"
	box.add_child(meta)
	return box


func _make_cell(parent: HBoxContainer, width: float, cell_name: String) -> Label:
	var box := VBoxContainer.new()
	box.name = cell_name
	box.custom_minimum_size = Vector2(width, 0.0)
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override(&"separation", CELL_SEPARATION)
	parent.add_child(box)
	var value := _make_label(&"StationValue", "")
	value.name = "Value"
	box.add_child(value)
	return value


func _make_label(variation: StringName, text: String) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_inner(button: Button) -> HBoxContainer:
	var inner := MarginContainer.new()
	inner.name = "RowInner"
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override(&"margin_left", ROW_INNER_MARGIN.x)
	inner.add_theme_constant_override(&"margin_top", ROW_INNER_MARGIN.y)
	inner.add_theme_constant_override(&"margin_right", ROW_INNER_MARGIN.x)
	inner.add_theme_constant_override(&"margin_bottom", ROW_INNER_MARGIN.y)
	button.add_child(inner)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := HBoxContainer.new()
	box.add_theme_constant_override(&"separation", COLUMN_SEPARATION)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(box)
	return box


func _make_icon(icon_path: String) -> TextureRect:
	if icon_path.is_empty():
		return null
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(COL_ICON, COL_ICON)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = load(_icon_source(icon_path))
	var base := _token(&"text_primary") if _is_flat_glyph(icon_path) else Color.WHITE
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


func _add_slack() -> void:
	var slack := Control.new()
	slack.name = "Slack"
	slack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rows.add_child(slack)


func _connect_scroll() -> void:
	## The scroll cue has no other home: the station shell owns no list of its own.
	if _scroll.has_signal(&"scroll_started"):
		_scroll.connect(&"scroll_started", _on_scroll_started)


func _on_scroll_started() -> void:
	AudioManager.play_ui(AudioManager.UiCue.SCROLL)


## One row, pressed: the ACTION's own word decides. `SELECT A CELL` is the pin's disabled state,
## so the press writes nothing and says so; FIT and SWAP are the one composed call.
func _on_module_pressed(payload: Dictionary) -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	var row: Button = payload[&"row"]
	row.set_pressed_no_signal(true)
	_selected_row = row
	## Reading a row is also previewing it: the meter's candidate line is about the module the
	## player is acting on, so a refused press leaves the arithmetic that refused it on screen.
	_candidate = payload[&"id"]
	if module_action(payload[&"id"]) == ACTION_SELECT:
		_notice(ACTION_SELECT, false)
		return
	install_module(payload[&"id"])


func _on_module_focused(row: Button, payload: Dictionary) -> void:
	AudioManager.play_ui(AudioManager.UiCue.HOVER)
	if _selected_row != null and _selected_row != row and is_instance_valid(_selected_row):
		_selected_row.set_pressed_no_signal(false)
	_selected_row = row
	row.set_pressed_no_signal(true)
	_candidate = payload[&"id"]
	_refresh_footer()


func _on_module_hovered(payload: Dictionary, hovered: bool) -> void:
	## The pointer previews the same candidate the ring does; leaving the row hands the meter
	## back to the selected cell's own module.
	var icon: TextureRect = payload[&"icon"]
	if icon != null and is_instance_valid(icon):
		var tween := _make_tween()
		tween.tween_property(
			icon, "modulate:a", 1.0 if hovered else ROW_ICON_IDLE_ALPHA, HOVER_SECONDS
		)
	_candidate = payload[&"id"] if hovered else &""
	_refresh_footer()


func _on_remove_pressed() -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	remove_selected()


## ------------------------------------------------------------------------------- the footer


func _refresh_footer() -> void:
	var profile := _profile()
	var hull := _active_hull(profile)
	var fit := _resolved_fit(profile, hull)
	_meter.text = _meter_line(profile, hull, fit)
	_apply_colour(_meter, _meter_danger(profile, hull, fit))
	if not _line_override.is_empty():
		_line.text = _line_override
		_apply_colour(_line, _line_danger)
	else:
		_line.text = _selection_line(profile, fit)
		_apply_colour(_line, false)
	_remove.disabled = not can_remove()


## STATION_HUB section 5.3's meter, as text: the fit the launch flies (`PWR <Σ> / <out>`) and,
## with a cell selected, the candidate's own line. The numbers are `fit_legal`'s `power`
## dictionary, never a second arithmetic.
func _meter_line(profile: ProfileScript, hull: StringName, fit: Dictionary) -> String:
	var power := _power_of(hull, fit)
	var draws := int(power[&"draw"])
	var out := int(power[&"out"])
	if _selected.is_empty():
		return METER_IDLE % [draws, out]
	var candidate := _candidate_power(profile, hull, fit)
	var line := METER_CANDIDATE % [draws, out, int(candidate[&"draw"]), int(candidate[&"out"])]
	if not bool(candidate[&"legal"]):
		line += METER_OVER % (int(candidate[&"draw"]) - int(candidate[&"out"]))
	return line


## The candidate's own arithmetic: the resolved fit with the selected cell set to the module the
## player is reading (the focused or hovered OWNED MODULES row), and the resolved fit itself
## when no such module is being read or its type is not the selected cell's - a preview that
## never invents a fit.
func _candidate_power(profile: ProfileScript, hull: StringName, fit: Dictionary) -> Dictionary:
	if _selected.is_empty() or _candidate == &"":
		return _power_of(hull, fit)
	var slot_key: StringName = _selected[&"type"]
	if _slot_key_of(_candidate) != slot_key:
		return _power_of(hull, fit)
	return _power_of(
		hull, _candidate_fit(profile, hull, slot_key, int(_selected[&"index"]), _candidate)
	)


## An over-budget candidate is the pin's own danger state: the line renders in the danger colour
## and ends `— OVER BY <n>` (the suffix `_meter_line` appended).
func _meter_danger(profile: ProfileScript, hull: StringName, fit: Dictionary) -> bool:
	if _selected.is_empty():
		return false
	return not bool(_candidate_power(profile, hull, fit)[&"legal"])


func _power_of(hull: StringName, fit: Dictionary) -> Dictionary:
	return ShipFit.fit_legal(hull, fit)[&"power"]


## The selected cell's line, `<TYPE><n> · <MODULE NAME or EMPTY> · OWNED ×<n>`, or the pin's own
## word for the no-selection state.
func _selection_line(profile: ProfileScript, fit: Dictionary) -> String:
	if _selected.is_empty():
		return ACTION_SELECT
	var slot_key: StringName = _selected[&"type"]
	var index := int(_selected[&"index"])
	var module_id := _base_id(profile, _cell_module(fit, slot_key, index))
	var owned := 0
	var name_text := CELL_EMPTY
	if module_id != &"":
		name_text = _module_name(module_id)
		if profile != null:
			owned = int(profile.call(&"module_count", module_id))
	return SELECTION_FORMAT % [String(_selected[&"token"]), index + 1, name_text, owned]


func _apply_colour(label: Label, danger: bool) -> void:
	if danger:
		label.add_theme_color_override(&"font_color", _token(&"accent_danger"))
	else:
		label.remove_theme_color_override(&"font_color")


## --------------------------------------------------------------- the pane's own arithmetic


## The fit the pane shows and previews, and the shape the profile's own composed transactions
## judge and write: the profile's `resolved_fit` - the account's stored fit when it holds a
## module, else 09 section 9's `ShipFit.standard_fit`, the same resolution
## `game.gd:_launch_fit_for` launches with - so the meter cannot promise a budget the launch
## would not fly and the preview and the commit read one fit.
func _resolved_fit(profile: ProfileScript, hull: StringName) -> Dictionary:
	if profile == null:
		return ShipFit.standard_fit(hull)
	var fit: Dictionary = profile.call(&"resolved_fit", hull)
	return fit


## The candidate fit one install or swap is judged on: the resolved fit with the one cell set to
## `module_id`. The profile composes the same candidate from its own `resolved_fit` before it
## writes (CONTRACTS section 13), so the pane's preview and the profile's re-check judge one fit.
func _candidate_fit(
	profile: ProfileScript, hull: StringName, slot_key: StringName, index: int,
	module_id: StringName
) -> Dictionary:
	return _with_cell(_resolved_fit(profile, hull), slot_key, index, module_id)


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


## The module id one fit cell holds, `&""` for an empty cell and for an index the hull does not
## carry. POWER is one id, not a set (CONTRACTS section 11 rule 1).
func _cell_module(fit: Dictionary, slot_key: StringName, index: int) -> StringName:
	if slot_key == POWER_SLOT:
		var single: Variant = fit.get(slot_key, fit.get(String(slot_key), ""))
		if single is Array:
			for entry: Variant in single as Array:
				if String(entry) != "":
					return StringName(String(entry))
			return &""
		return StringName(String(single)) if single != null else &""
	var raw: Variant = fit.get(slot_key, fit.get(String(slot_key), []))
	if not raw is Array:
		return &""
	var cells: Array = raw as Array
	if index < 0 or index >= cells.size():
		return &""
	return StringName(String(cells[index]))


## The catalogue's slot key of a module, in the fit's own spelling (`engine` -> `engines`), and
## `&""` for an id the catalogue does not carry.
func _slot_key_of(module_id: StringName) -> StringName:
	var slot: StringName = ModuleCatalog.slot_of(module_id)
	return SLOT_KEY_ALIASES.get(slot, slot)


## The cell one module's row acts on: the selected cell when it is of the module's own type,
## `{}` otherwise - the pin's `SELECT A CELL` state.
func _row_target_cell(module_id: StringName) -> Dictionary:
	if _selected.is_empty() or module_id == &"":
		return {}
	if _slot_key_of(module_id) != StringName(_selected[&"type"]):
		return {}
	return _selected


## The fit stores a module *instance* id (15 section 6) and the catalogue reads base ids, so
## every id the pane names goes through the profile's own bridge.
func _base_id(profile: ProfileScript, entry: StringName) -> StringName:
	if profile == null or entry == &"":
		return entry
	return StringName(profile.call(&"base_module_id", entry))


func _module_name(module_id: StringName) -> String:
	var name_text := String(ModuleCatalog.module(module_id).get(&"name", ""))
	return name_text.to_upper() if not name_text.is_empty() else String(module_id).to_upper()


func _active_hull(profile: ProfileScript) -> StringName:
	if profile == null:
		return &""
	return StringName(profile.call(&"active_ship"))


func _refresh_all() -> void:
	var profile := _profile()
	var hull := _active_hull(profile)
	_sync_grid(hull)
	_refresh_header(hull)
	_refresh_rows(profile)
	_refresh_footer()


## The header's one moving line: the hull whose grid and fit the pane is showing, named the way
## the shipyard's own tag names it.
func _refresh_header(hull: StringName) -> void:
	_subtitle.text = ACTIVE_HULL % _hull_name(hull)


func _hull_name(hull: StringName) -> String:
	var name_text := String(StationCatalog.ship(hull).get(&"name", ""))
	return name_text.to_upper() if not name_text.is_empty() else String(hull).to_upper()


func _apply_tokens() -> void:
	for payload: Dictionary in _cells:
		var glyph: TextureRect = (payload[&"node"] as Button).get_node_or_null(^"Icon") as TextureRect
		if glyph != null:
			glyph.modulate = _token(&"text_dim")
	for payload: Dictionary in _payloads:
		var icon: TextureRect = payload.get(&"icon", null)
		if icon != null and is_instance_valid(icon) and bool(payload.get(&"tinted", false)):
			var tint: Color = _token(&"text_primary")
			tint.a = ROW_ICON_IDLE_ALPHA
			icon.modulate = tint


func _token(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.WHITE


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


func _make_tween() -> Tween:
	for index in range(_tweens.size() - 1, -1, -1):
		if not _tweens[index].is_valid():
			_tweens.remove_at(index)
	var tween := create_tween()
	_tweens.append(tween)
	return tween
