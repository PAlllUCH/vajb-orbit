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
## 15 section 7's naming grammar has exactly one builder (`Auction.rolled_name`), the
## one the AUCTION's own rows read; this pane calls it rather than growing a second
## copy of the grammar (K2's deviation 7). The same file carries the three rarity
## tokens' names and their hex fallbacks (STATION_HUB section 5.10).
const AuctionScript := preload("res://game/auction.gd")

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

## ------------------------------------------------- the S3 instance surface (15 section 7)
## STATION_HUB section 5.3's 2026-09-22 S3 amendment: a base id owning more than one
## instance carries a `▸` expander whose sub-rows are the instances themselves - the
## rolled name in its rarity tint and the instance's own ACTION. The expander's two
## words are the pin's own glyph, and the sub-row is indented inside the row's own
## inner margin, so the two surfaces read as one list.
const EXPANDER_CLOSED := "▸"
const EXPANDER_OPEN := "▾"
const EXPANDER_WIDTH := 28.0
const SUBROW_INDENT := 24
const SUBROW_PREFIX := "Instance"

## 15 section 7's two-line stat block: the base module's catalogue stats on one line
## and one line per rolled affix below it. Measured values only - the catalogue's own
## `effects` dict and 15 section 3/4's own rows - because nothing here is applied to a
## flight stat (15 section 9.3: stored, named, priced and displayed).
const BASE_LINE_FORMAT := "BASE DRAW %d"
const STAT_JOIN := " · "
const AFFIX_JOIN := " · "
const BLOCK_SEPARATOR := "\n"
const STAT_ADD_SUFFIX := " ADD"
const STAT_MULT_SUFFIX := " MULT"
const MULTIPLIER_PREFIX := "×"

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
@onready var _footer: VBoxContainer = %PaneFooter
@onready var _remove: Button = %RemoveButton

## The OWNED MODULES rows: {id, name, slot, draw, empty, owned, action, row, icon, tinted,
## instances, subrows, expander}.
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
## The instance ids behind each row of the built set, in render order: one base id's instances
## moving (an install taking one out of the bag, a roll adding one) has to rebuild the rows even
## when the base id set itself does not move, which `_row_ids` alone cannot see.
var _row_signature: Array[String] = []
## The instance ids the built sub-rows carry, so a refresh can tell whether the module the
## meter is previewing is still on screen.
var _instance_ids: Array[StringName] = []
## The base ids whose `▸` expander is open. Kept across a rebuild, so the sub-row list a player
## opened survives the very transaction it just made.
var _expanded: Dictionary = {}
## The instance stat block (15 section 7's second line and its affix lines), built in script
## under the footer's selection line: no scene file carries it, the way the rows carry their own
## nodes. Empty and hidden while the selected cell holds nothing.
var _stat_block: Label = null
var _selected_row: Button = null
var _tweens: Array[Tween] = []


func _ready() -> void:
	## The two words the pane's own controls carry, named here so a test can read them off the
	## script instead of off the scene file.
	_owned_caption.text = OWNED_CAPTION
	_remove.text = REMOVE_ACTION
	_connect_scroll()
	_remove.pressed.connect(_on_remove_pressed)
	_mount_stat_block()
	_apply_tokens()
	_refresh_all()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_apply_tokens()
		_refresh_footer()


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
##
## The id may be an **instance** id (a sub-row's own ACTION) or a base id; the slot a fit cell
## is judged against is the catalogue's, so the id is translated first (CONTRACTS section 15).
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


## The stat block's own text, read back for probes and tests: the selected cell's base line
## plus one line per rolled affix (15 section 7's two-line block), "" while the cell is empty.
func stat_block_text() -> String:
	return "" if _stat_block == null else _stat_block.text


## The base id's held instances, summed the way STATION_HUB section 5.3's `OWNED ×<n>` counts
## them: every key of the bag whose `base_module_id` is that base, its count added.
func owned_total(base_id: StringName) -> int:
	return _owned_total(_profile(), base_id)


## The instance ids a base id's sub-rows list, in creation order: `[]` for a base the pane has
## no row for, and the bag's own held ids (a fitted instance is out of the bag).
func subrow_ids(base_id: StringName) -> Array[StringName]:
	for payload: Dictionary in _payloads:
		if payload[&"id"] == base_id:
			var ids: Array[StringName] = []
			for entry: Dictionary in payload.get(&"subrows", []):
				ids.append(entry[&"id"])
			return ids
	return [] as Array[StringName]


## Whether one base id's `▸` expander is open.
func expanded(base_id: StringName) -> bool:
	return bool(_expanded.get(base_id, false))


## Open or close one base id's expander, the sub-row list's own door for a probe or a test.
## Answers whether the base id has an expander at all (STATION_HUB section 5.3: one appears
## only when the base id owns more than one instance).
func toggle_expander(base_id: StringName) -> bool:
	for payload: Dictionary in _payloads:
		if payload[&"id"] != base_id:
			continue
		if payload.get(&"expander", null) == null:
			return false
		_on_expander_pressed(base_id)
		return true
	return false


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
##
## `module_id` is the entry the cell will hold - an instance id from a sub-row, or a base id -
## and the judgement reads the candidate's **base ids** (CONTRACTS section 15): a fit cell
## stores the instance id while `ShipFit` reads base ids, so an untranslated candidate would
## score as draw 0 and would miss two instances of one duplicate-guarded module.
func install_module(module_id: StringName) -> bool:
	var profile := _profile()
	var cell := _row_target_cell(module_id)
	if profile == null or cell.is_empty():
		return false
	var hull := _active_hull(profile)
	var slot_key: StringName = cell[&"type"]
	var index := int(cell[&"index"])
	var candidate := _candidate_fit(profile, hull, slot_key, index, module_id)
	var legal := ShipFit.fit_legal(hull, _base_fit(profile, candidate))
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
##
## The sum is over the bag's own keys and not `module_count(base_id)`, which answers one
## record's count: since save v6 an instance is its own key at `count` 1, so three `w_laser`
## instances are three keys with `module_count(&"w_laser") == 0` (K1's measured note).
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


## One base id's held instances, in creation order, through the profile's own pinned accessor
## (CONTRACTS section 15's `instances_of`, which answers the bag's keys at `count` 1 and never
## a fitted one). `[]` for a base the profile does not carry or a null profile.
func _instances_of(profile: ProfileScript, base_id: StringName) -> Array[StringName]:
	if profile == null or base_id == &"":
		return [] as Array[StringName]
	var ids: Array[StringName] = []
	var raw: Variant = profile.call(&"instances_of", base_id)
	if raw is Array:
		for entry: Variant in raw as Array:
			ids.append(StringName(str(entry)))
	return ids


## The base id's held total, summed the way `_owned_counts` sums it: every bag key whose
## `base_module_id` is that base, its count added. `module_count(base_id)` cannot answer this
## for an instance-keyed bag (see `_owned_counts`).
func _owned_total(profile: ProfileScript, base_id: StringName) -> int:
	var total := 0
	if profile == null or base_id == &"":
		return total
	for key: Variant in profile.call(&"modules"):
		var entry := StringName(str(key))
		var held := int(profile.call(&"module_count", entry))
		if held <= 0:
			continue
		if StringName(profile.call(&"base_module_id", entry)) == base_id:
			total += held
	return total


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


## The built row set's own signature: one entry per row for its base id and one per instance
## behind it, so a base id whose instances moved (an install took one out of the bag, a roll
## added one) rebuilds the rows even though the base id set did not move. `_row_ids` alone
## cannot see that, and the sub-rows are exactly what the rebuild owes.
func _row_signature_of(profile: ProfileScript, ids: Array[StringName]) -> Array[String]:
	var signature: Array[String] = []
	for base_id: StringName in ids:
		signature.append(String(base_id))
		for instance_id: StringName in _instances_of(profile, base_id):
			signature.append(String(instance_id))
	return signature


func _refresh_rows(profile: ProfileScript) -> void:
	var ids := _owned_ids(_owned_counts(profile))
	var signature := _row_signature_of(profile, ids)
	if not _rows_built or signature != _row_signature:
		_rows_built = true
		_row_signature = signature
		if ids.is_empty():
			_build_empty_row()
		else:
			_build_rows(ids, profile)
		_row_ids = ids
	for payload: Dictionary in _payloads:
		_refresh_row(payload, profile)
	if _candidate != &"" and not _row_ids.has(_candidate) and not _instance_ids.has(_candidate):
		_candidate = &""


## Rebuild the rows, then refresh each one. A rebuild during a signal handler (the profile
## emits profile_changed from inside a transaction) detaches the old nodes first and frees them
## deferred, which is the one safe way to remove the very Button whose press is still on the
## stack.
func _build_rows(ids: Array[StringName], profile: ProfileScript) -> void:
	_clear_rows()
	for base_id: StringName in ids:
		_payloads.append(_build_row(base_id, profile))
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
	_instance_ids.clear()
	_selected_row = null
	for child: Node in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()


## One base id's aggregate row (STATION_HUB section 5.3). Its name is the catalogue's - unless
## the base id owns exactly one instance, in which case the row is that instance's own row and
## carries its 15 section 7 rolled name in its rarity tint (for a Common, which is what the v5
## migration mints, the rolled name *is* the plain 09 name, so the pre-instance surface is
## unchanged). A base id owning more than one instance carries the `▸` expander and keeps the
## catalogue name: no single rolled name would be true for it, and the sub-rows carry them all.
func _build_row(base_id: StringName, profile: ProfileScript) -> Dictionary:
	var module_row := ModuleCatalog.module(base_id)
	var icon_path := String(module_row.get(&"icon", ""))
	var instances := _instances_of(profile, base_id)
	var single := instances.size() == 1
	var record := _instance_record(profile, instances[0]) if single else {}
	var name_text := _instance_name(base_id, record)
	var row := Button.new()
	row.name = "Module%s" % String(base_id).to_pascal_case()
	row.toggle_mode = true
	row.focus_mode = Control.FOCUS_ALL
	row.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row.set_meta(&"id", base_id)
	var box := _make_inner(row)
	var expander: Button = null
	if instances.size() > 1:
		expander = _make_expander(base_id, box)
	var icon := _make_icon(icon_path)
	if icon != null:
		box.add_child(icon)
	var title_box := _make_title_box(name_text, _meta_of(module_row))
	box.add_child(title_box)
	var title := title_box.get_node_or_null(^"Title") as Label
	var tint := _rarity_token(record) if single else &""
	if title != null and tint != &"":
		title.add_theme_color_override(&"font_color", _rarity_color(tint))
	var owned := _make_cell(box, COL_OWNED, "Owned")
	var action := _make_cell(box, COL_ACTION, "Action")
	var payload := {
		&"id": base_id,
		&"base": base_id,
		&"name": name_text,
		&"slot": StringName(module_row.get(&"slot", &"")),
		&"draw": int(module_row.get(&"draw", 0)),
		&"empty": false,
		&"row": row,
		&"icon": icon,
		&"tinted": _is_flat_glyph(icon_path),
		&"title": title,
		&"tint": tint,
		&"owned": owned,
		&"action": action,
		&"subrows": [],
		&"expander": expander,
	}
	row.pressed.connect(_on_module_pressed.bind(payload))
	row.focus_entered.connect(_on_module_focused.bind(row, payload))
	row.mouse_entered.connect(_on_module_hovered.bind(payload, true))
	row.mouse_exited.connect(_on_module_hovered.bind(payload, false))
	_rows.add_child(row)
	if bool(_expanded.get(base_id, false)):
		_build_subrows(payload, profile)
	return payload


## The `▸` expander one multi-instance row carries (STATION_HUB section 5.3's S3 amendment):
## the pin's own glyph, its own control, so the aggregate row's own ACTION keeps working. It
## sits first in the row's inner box, ahead of the icon, and takes the pointer itself. Its chrome
## is the row's own (a plain `Button`, no theme variation), so the two read as one control.
func _make_expander(base_id: StringName, box: HBoxContainer) -> Button:
	var button := Button.new()
	button.name = "Expander%s" % String(base_id).to_pascal_case()
	button.text = EXPANDER_OPEN if bool(_expanded.get(base_id, false)) else EXPANDER_CLOSED
	button.custom_minimum_size = Vector2(EXPANDER_WIDTH, 0.0)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(_on_expander_pressed.bind(base_id))
	box.add_child(button)
	return button


## One indented sub-row per instance of an expanded base id: the 15 section 7 full rolled name
## in its rarity tint, the row's own meta and the **instance's** own ACTION (STATION_HUB
## section 5.3). The press installs *that* instance, so the fit cell stores its id and
## REMOVE/SWAP hand the same one back (CONTRACTS section 15, L80).
func _build_subrows(payload: Dictionary, profile: ProfileScript) -> void:
	var base_id: StringName = payload[&"base"]
	var module_row := ModuleCatalog.module(base_id)
	var icon_path := String(module_row.get(&"icon", ""))
	for instance_id: StringName in _instances_of(profile, base_id):
		var record := _instance_record(profile, instance_id)
		var row := Button.new()
		row.name = SUBROW_PREFIX + String(instance_id).to_pascal_case()
		row.toggle_mode = true
		row.focus_mode = Control.FOCUS_ALL
		row.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
		row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		row.set_meta(&"id", instance_id)
		var box := _make_inner(row, SUBROW_INDENT)
		var icon := _make_icon(icon_path)
		if icon != null:
			box.add_child(icon)
		var title_box := _make_title_box(_instance_name(base_id, record), _meta_of(module_row))
		box.add_child(title_box)
		var title := title_box.get_node_or_null(^"Title") as Label
		var tint := _rarity_token(record)
		if title != null and tint != &"":
			title.add_theme_color_override(&"font_color", _rarity_color(tint))
		## The aggregate row's `OWNED ×<n>` cell is one column wide and the ACTION cell is the
		## next; the spacer keeps the sub-row's ACTION under the row's own, so the list reads as
		## one column of actions.
		box.add_child(_make_spacer(COL_OWNED))
		var action := _make_cell(box, COL_ACTION, "Action")
		var sub := {
			&"id": instance_id,
			&"base": base_id,
			&"entry": instance_id,
			&"empty": false,
			&"row": row,
			&"icon": icon,
			&"tinted": _is_flat_glyph(icon_path),
			&"title": title,
			&"tint": tint,
			&"action": action,
		}
		row.pressed.connect(_on_subrow_pressed.bind(sub))
		row.focus_entered.connect(_on_subrow_focused.bind(row, sub))
		row.mouse_entered.connect(_on_subrow_hovered.bind(sub, true))
		row.mouse_exited.connect(_on_subrow_hovered.bind(sub, false))
		_rows.add_child(row)
		payload[&"subrows"].append(sub)
		_instance_ids.append(instance_id)


func _make_spacer(width: float) -> Control:
	var spacer := Control.new()
	spacer.name = "Spacer"
	spacer.custom_minimum_size = Vector2(width, 0.0)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer


## The record behind one inventory id, `{}` for an id the bag does not carry (a delivered
## module in a standard fit, for one) - the catalogue name is then the honest display name.
func _instance_record(profile: ProfileScript, entry: StringName) -> Dictionary:
	if profile == null or entry == &"":
		return {}
	var record: Variant = profile.call(&"instance", entry)
	if record is Dictionary:
		return record
	return {}


## One module's display name: 15 section 7's full rolled name through the shared builder when
## the bag carries the record, the catalogue's own name otherwise. The catalogue spells its
## names in title case (`Laser MkII`), so nothing here upper-cases them - the rolled name is
## the document's own string.
func _instance_name(base_id: StringName, record: Dictionary) -> String:
	if not record.is_empty():
		var rolled := String(AuctionScript.rolled_name(record))
		if not rolled.is_empty():
			return rolled
	var name_text := String(ModuleCatalog.module(base_id).get(&"name", ""))
	return name_text if not name_text.is_empty() else String(base_id)


## The rarity-token name a record's name cell is tinted with, `&""` for a record with no
## rarity (a delivered module) - STATION_HUB section 5.10's three tokens.
func _rarity_token(record: Dictionary) -> StringName:
	var rarity := StringName(str(record.get("rarity", "")))
	if rarity == &"":
		return &""
	return AuctionScript.rarity_token(rarity)


## One rarity's tint: the theme's `rarity_*` token first (STATION_HUB section 5.10's own three,
## with the fallback hexes for a theme that predates them).
func _rarity_color(token: StringName) -> Color:
	if token == &"":
		return _token(&"text_primary")
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return AuctionScript.rarity_fallback(_rarity_of(token))


func _rarity_of(token: StringName) -> StringName:
	for rarity: Variant in AuctionScript.RARITY_TOKENS:
		if AuctionScript.RARITY_TOKENS[rarity] == token:
			return StringName(str(rarity))
	return &"common"


## The entry one aggregate row's own ACTION acts on: the base id's first held instance, in the
## bag's own order. For a base-keyed record (`add_module`'s own shape, every pre-v6 fixture)
## that is the base id itself, which is what keeps the pre-instance surface byte-identical.
func _row_entry(profile: ProfileScript, base_id: StringName) -> StringName:
	var ids := _instances_of(profile, base_id)
	return ids[0] if not ids.is_empty() else base_id


## The entry a payload acts on: its own instance id for a sub-row, the base's first held
## instance for an aggregate row.
func _payload_entry(payload: Dictionary) -> StringName:
	if payload.has(&"entry"):
		return payload[&"entry"]
	var base_id: StringName = payload.get(&"base", payload.get(&"id", &""))
	return _row_entry(_profile(), base_id)


## The row's meta, `SLOT <TYPE> · DRAW <n>`: the module's own slot type and its 09 section 3
## draw, both catalogue values.
func _meta_of(module_row: Dictionary) -> String:
	var slot := String(module_row.get(&"slot", &"")).to_upper()
	return META_FORMAT % [slot, int(module_row.get(&"draw", 0))]


func _refresh_row(payload: Dictionary, profile: ProfileScript) -> void:
	if bool(payload.get(&"empty", false)):
		return
	var base_id: StringName = payload.get(&"base", payload[&"id"])
	var owned: Label = payload[&"owned"]
	var action: Label = payload[&"action"]
	owned.text = OWNED_FORMAT % _owned_total(profile, base_id)
	action.text = String(module_action(_payload_entry(payload)))
	var expander: Variant = payload.get(&"expander", null)
	if expander is Button:
		var marker: Button = expander
		if is_instance_valid(marker):
			marker.text = EXPANDER_OPEN if bool(_expanded.get(base_id, false)) else EXPANDER_CLOSED
	for sub: Dictionary in payload.get(&"subrows", []):
		var sub_action: Label = sub[&"action"]
		sub_action.text = String(module_action(sub[&"id"]))


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


func _make_inner(button: Button, indent := 0) -> HBoxContainer:
	var inner := MarginContainer.new()
	inner.name = "RowInner"
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override(&"margin_left", ROW_INNER_MARGIN.x + indent)
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
##
## The row's own ACTION acts on the base id's first held instance (`_row_entry`), so an account
## whose base id owns exactly one instance presses the instance, and a base-keyed record - every
## pre-v6 fixture - presses its own id, exactly as before.
func _on_module_pressed(payload: Dictionary) -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	var row: Button = payload[&"row"]
	row.set_pressed_no_signal(true)
	_selected_row = row
	## Reading a row is also previewing it: the meter's candidate line is about the module the
	## player is acting on, so a refused press leaves the arithmetic that refused it on screen.
	var entry: StringName = _payload_entry(payload)
	_candidate = entry
	if module_action(entry) == ACTION_SELECT:
		_notice(ACTION_SELECT, false)
		return
	install_module(entry)


## One sub-row, pressed: the same composed install, on **that instance's** id, so the fit cell
## holds the instance and its own affixes and rarity travel with it (CONTRACTS section 15).
func _on_subrow_pressed(payload: Dictionary) -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	var row: Button = payload[&"row"]
	row.set_pressed_no_signal(true)
	_selected_row = row
	_candidate = payload[&"entry"]
	if module_action(payload[&"entry"]) == ACTION_SELECT:
		_notice(ACTION_SELECT, false)
		return
	install_module(payload[&"entry"])


## The `▸` expander's own press: the base id's flag flips and the rows are rebuilt so the
## sub-rows appear (or go) at once. The flag survives the rebuild, which is what makes the
## sub-row list a player opened survive the transaction they then made in it.
func _on_expander_pressed(base_id: StringName) -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	_expanded[base_id] = not bool(_expanded.get(base_id, false))
	var profile := _profile()
	var ids := _owned_ids(_owned_counts(profile))
	_row_signature = _row_signature_of(profile, ids)
	_build_rows(ids, profile)
	_row_ids = ids
	for payload: Dictionary in _payloads:
		_refresh_row(payload, profile)
	_refresh_footer()


func _on_module_focused(row: Button, payload: Dictionary) -> void:
	AudioManager.play_ui(AudioManager.UiCue.HOVER)
	if _selected_row != null and _selected_row != row and is_instance_valid(_selected_row):
		_selected_row.set_pressed_no_signal(false)
	_selected_row = row
	row.set_pressed_no_signal(true)
	_candidate = _payload_entry(payload)
	_refresh_footer()


func _on_subrow_focused(row: Button, payload: Dictionary) -> void:
	_on_module_focused(row, payload)


func _on_module_hovered(payload: Dictionary, hovered: bool) -> void:
	## The pointer previews the same candidate the ring does; leaving the row hands the meter
	## back to the selected cell's own module.
	var icon: TextureRect = payload[&"icon"]
	if icon != null and is_instance_valid(icon):
		var tween := _make_tween()
		tween.tween_property(
			icon, "modulate:a", 1.0 if hovered else ROW_ICON_IDLE_ALPHA, HOVER_SECONDS
		)
	_candidate = _payload_entry(payload) if hovered else &""
	_refresh_footer()


func _on_subrow_hovered(payload: Dictionary, hovered: bool) -> void:
	_on_module_hovered(payload, hovered)


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
		_apply_rarity_colour(_line, _selection_tint(profile, fit))
	_refresh_stat_block(profile, fit)
	_remove.disabled = not can_remove()


## STATION_HUB section 5.3's meter, as text: the fit the launch flies (`PWR <Σ> / <out>`) and,
## with a cell selected, the candidate's own line. The numbers are `fit_legal`'s `power`
## dictionary, never a second arithmetic - and the fit they are read from is the **base-id**
## translation of the fit the pane shows, because a cell holds an instance id (CONTRACTS
## section 15; without the translation every fitted instance would score as draw 0 - K0 H6).
func _meter_line(profile: ProfileScript, hull: StringName, fit: Dictionary) -> String:
	var power := _power_of(profile, hull, fit)
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
## player is reading (the focused or hovered OWNED MODULES row or sub-row), and the resolved fit
## itself when no such module is being read or the module's catalogue slot is not the selected
## cell's - a preview that never invents a fit. The candidate is judged on base ids, like every
## other legality read here.
func _candidate_power(profile: ProfileScript, hull: StringName, fit: Dictionary) -> Dictionary:
	if _selected.is_empty() or _candidate == &"":
		return _power_of(profile, hull, fit)
	var slot_key: StringName = _selected[&"type"]
	if _candidate_slot(profile, _candidate) != slot_key:
		return _power_of(profile, hull, fit)
	return _power_of(
		profile, hull, _candidate_fit(profile, hull, slot_key, int(_selected[&"index"]), _candidate)
	)


## An over-budget candidate is the pin's own danger state: the line renders in the danger colour
## and ends `— OVER BY <n>` (the suffix `_meter_line` appended).
func _meter_danger(profile: ProfileScript, hull: StringName, fit: Dictionary) -> bool:
	if _selected.is_empty():
		return false
	return not bool(_candidate_power(profile, hull, fit)[&"legal"])


## `ShipFit.fit_legal`'s own power dictionary, read through the base-id translation: a fit cell
## holds an instance id, so the untranslated fit would be scored with draw 0 per instance cell.
func _power_of(profile: ProfileScript, hull: StringName, fit: Dictionary) -> Dictionary:
	return ShipFit.fit_legal(hull, _base_fit(profile, fit))[&"power"]


## The selected cell's line, `<TYPE><n> · <MODULE NAME or EMPTY> · OWNED ×<n>`, or the pin's own
## word for the no-selection state. STATION_HUB section 5.3's S3 amendment: where the cell holds
## an instance, the name is 15 section 7's **full rolled name** (the same shared builder the
## AUCTION's rows use) and the `OWNED ×<n>` tail keeps counting the base id's held instances -
## the base's aggregate, not the one record's count.
func _selection_line(profile: ProfileScript, fit: Dictionary) -> String:
	if _selected.is_empty():
		return ACTION_SELECT
	var slot_key: StringName = _selected[&"type"]
	var index := int(_selected[&"index"])
	var entry := _cell_module(fit, slot_key, index)
	var base := _base_id(profile, entry)
	var owned := 0
	var name_text := CELL_EMPTY
	if base != &"":
		var record := _instance_record(profile, entry)
		name_text = _instance_name(base, record)
		owned = _owned_total(profile, base)
	return SELECTION_FORMAT % [String(_selected[&"token"]), index + 1, name_text, owned]


## The rarity token the selected cell's name is tinted with, `&""` when the cell is empty or
## holds a module the bag does not carry.
func _selection_tint(profile: ProfileScript, fit: Dictionary) -> StringName:
	if _selected.is_empty():
		return &""
	var entry := _cell_module(fit, StringName(_selected[&"type"]), int(_selected[&"index"]))
	return _rarity_token(_instance_record(profile, entry))


## A name cell's colour: the theme's rarity token, or no override at all when the entry carries
## no rarity (the default label colour is `rarity_common`).
func _apply_rarity_colour(label: Label, token: StringName) -> void:
	if token == &"":
		label.remove_theme_color_override(&"font_color")
		return
	label.add_theme_color_override(&"font_color", _rarity_color(token))


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
## `module_id` (the entry - an instance id or a base id). The profile composes the same candidate
## from its own `resolved_fit` before it writes (CONTRACTS section 13), so the pane's preview and
## the profile's re-check judge one fit.
func _candidate_fit(
	profile: ProfileScript, hull: StringName, slot_key: StringName, index: int,
	module_id: StringName
) -> Dictionary:
	return _with_cell(_resolved_fit(profile, hull), slot_key, index, module_id)


## The same fit with every cell exchanged for the base catalogue id behind it, through the
## profile's own `base_fit` (CONTRACTS section 15): the shape `ShipFit` reads. Every legality
## judgement in this pane goes through it, because a cell holds an instance id.
func _base_fit(profile: ProfileScript, fit: Dictionary) -> Dictionary:
	if profile == null:
		return fit
	var translated: Variant = profile.call(&"base_fit", fit)
	if translated is Dictionary:
		return translated
	return fit


## A module entry's catalogue slot key in the fit's own spelling (`engine` -> `engines`),
## `&""` for an entry the catalogue cannot name. An instance id is translated to its base id
## first: `ModuleCatalog.slot_of` reads base ids only.
func _candidate_slot(profile: ProfileScript, entry: StringName) -> StringName:
	return _slot_key_of(_base_id(profile, entry))


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


## The cell one module's row acts on: the selected cell when it is of the module's own catalogue
## type, `{}` otherwise - the pin's `SELECT A CELL` state. The id may be an instance id, so the
## type is read through the base-id translation.
func _row_target_cell(module_id: StringName) -> Dictionary:
	if _selected.is_empty() or module_id == &"":
		return {}
	if _candidate_slot(_profile(), module_id) != StringName(_selected[&"type"]):
		return {}
	return _selected


## The fit stores a module *instance* id (15 section 6) and the catalogue reads base ids, so
## every id the pane names goes through the profile's own bridge.
func _base_id(profile: ProfileScript, entry: StringName) -> StringName:
	if profile == null or entry == &"":
		return entry
	return StringName(profile.call(&"base_module_id", entry))


## ------------------------------------------------------- the stat block (15 section 7)
##
## STATION_HUB section 5.3's S3 amendment: where the selected cell holds an instance, the pane
## adds the instance's stat block below the selection line - "the base module's catalogue stats
## plus one line per rolled affix (15 section 7's two-line block)". Nothing here is applied to
## a flight stat (15 section 9.3): every number is read off the catalogue's own `effects` dict
## or off 15 section 3/4's own rows, so the block cannot promise a stat the game does not roll.


## The block's own node, built in script under the footer's selection line: no scene file
## carries it (the pane's rows carry their own nodes the same way), so the frozen
## `fitting_panel.tscn` needs no edit for this surface.
func _mount_stat_block() -> void:
	if _stat_block != null and is_instance_valid(_stat_block):
		return
	_stat_block = _make_label(&"StationCaption", "")
	_stat_block.name = "StatBlock"
	_stat_block.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stat_block.visible = false
	_footer.add_child(_stat_block)
	_footer.move_child(_stat_block, _line.get_index() + 1)


## The block for the selected cell: the base module's catalogue stats, then one line per rolled
## affix. Empty and hidden while the cell holds nothing (or holds a module the bag does not
## carry and the catalogue cannot name).
func _refresh_stat_block(profile: ProfileScript, fit: Dictionary) -> void:
	if _stat_block == null or not is_instance_valid(_stat_block):
		return
	var text := ""
	if not _selected.is_empty():
		var entry := _cell_module(fit, StringName(_selected[&"type"]), int(_selected[&"index"]))
		text = _stat_block_of(profile, entry)
	_stat_block.text = text
	_stat_block.visible = not text.is_empty()


## One entry's block: the base line plus one line per affix, joined by `BLOCK_SEPARATOR`.
## `""` for an empty cell or an id the catalogue does not ship.
func _stat_block_of(profile: ProfileScript, entry: StringName) -> String:
	if entry == &"":
		return ""
	var base := _base_id(profile, entry)
	var module_row := ModuleCatalog.module(base)
	if module_row.is_empty():
		return ""
	var lines := PackedStringArray()
	lines.append(_base_stats_line(module_row))
	for line: String in _affix_lines(_instance_record(profile, entry)):
		lines.append(line)
	return BLOCK_SEPARATOR.join(lines)


## 15 section 7's first line: the base module's catalogue stats, as the catalogue carries them
## - its draw and every `effects` entry (`shield_add` 200 -> `SHIELD +200`, `damage_add` 0.15
## -> `DAMAGE +15 %`, `speed_mult` 1.15 -> `SPEED ×1.15`). A row with no effects (every weapon
## row) shows its draw alone.
func _base_stats_line(module_row: Dictionary) -> String:
	var parts := PackedStringArray([BASE_LINE_FORMAT % int(module_row.get(&"draw", 0))])
	var effects: Dictionary = module_row.get(&"effects", {})
	for key: Variant in effects:
		parts.append(stat_line(StringName(str(key)), float(effects[key])))
	return STAT_JOIN.join(parts)


## 15 section 7's second line onward: one line per rolled affix, in the record's own order.
## A prefix reads `<NAME> · <STAT> <value>` from 15 section 3's row and the value the record
## carries; a suffix reads `<NAME> · <perk>` with 15 section 4's own perk prose verbatim.
func _affix_lines(record: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	if record.is_empty():
		return lines
	for raw: Variant in _rows_of(record.get("prefixes")):
		var id := StringName(str(_row_id_of(raw)))
		var prefix: Variant = ModuleCatalog.PREFIXES.get(id, null)
		if not prefix is Dictionary:
			continue
		var row: Dictionary = prefix
		var value := 0.0
		if raw is Dictionary:
			value = float((raw as Dictionary).get("value", 0.0))
		var label := String(row.get(&"name", String(id))).to_upper()
		var stat := stat_line(
			StringName(str(row.get(&"stat", &""))), value, StringName(str(row.get(&"unit", &"")))
		)
		lines.append(label + AFFIX_JOIN + stat)
	for raw: Variant in _rows_of(record.get("suffixes")):
		var id := StringName(str(_row_id_of(raw)))
		var suffix: Variant = ModuleCatalog.SUFFIXES.get(id, null)
		if not suffix is Dictionary:
			continue
		var row: Dictionary = suffix
		lines.append(
			String(row.get(&"name", "of " + String(id))).to_upper()
			+ AFFIX_JOIN
			+ String(row.get(&"perk", ""))
		)
	return lines


## One stat as its display line: the catalogue's own key as the label (`shield_add` ->
## `SHIELD`, `fire_rate_mult` -> `FIRE RATE`) and the value in the unit 15 section 3's `unit`
## column names, or - for the base line, whose `effects` dict has no unit column - the unit the
## magnitude implies (a fraction is a percentage, anything else a plain number).
static func stat_line(
	stat_key: StringName, value: float, unit: StringName = &""
) -> String:
	var key := String(stat_key)
	if key.ends_with("_mult") or key.ends_with("_multiplier"):
		return "%s %s%s" % [stat_label(stat_key), MULTIPLIER_PREFIX, String.num(value, 2)]
	var text := ""
	match String(unit):
		"percent":
			text = signed_percent(value)
		"points":
			text = "%+d pp" % int(roundf(value * 100.0))
		"units":
			text = signed_number(value)
		_:
			text = signed_percent(value) if absf(value) < 1.0 else signed_number(value)
	return "%s %s" % [stat_label(stat_key), text]


## A catalogue stat key as a label: upper case, `_` as a space, and the arithmetic the value
## already carries (`+`, `−`, `×`) dropped from the word (`shield_add` -> `SHIELD`).
static func stat_label(stat_key: StringName) -> String:
	var words := String(stat_key).to_upper().replace("_", " ")
	for suffix: String in [STAT_ADD_SUFFIX, STAT_MULT_SUFFIX, " MULTIPLIER"]:
		if words.ends_with(suffix):
			return words.substr(0, words.length() - suffix.length())
	return words


static func signed_percent(value: float) -> String:
	return "%+d %%" % int(roundf(value * 100.0))


static func signed_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%+d" % int(roundf(value))
	return "%+.2f" % value


## The `{id, value}` prefix rows and the plain suffix ids one record carries, through the same
## two shapes `PlayerProfile._affix_rows`/`_affix_names` normalise to (a hand-built fixture may
## hand in either).
func _rows_of(raw: Variant) -> Array:
	return raw as Array if raw is Array else []


func _row_id_of(raw: Variant) -> String:
	if raw is Dictionary:
		return str((raw as Dictionary).get("id", ""))
	if raw is String or raw is StringName:
		return String(raw)
	return ""


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
		_apply_name_tint(payload)
		for sub: Dictionary in payload.get(&"subrows", []):
			_apply_name_tint(sub)


## Re-apply one row's or sub-row's rarity tint from the theme (STATION_HUB section 5.10's three
## tokens): the tint is an override, so a theme change has to put it back.
func _apply_name_tint(payload: Dictionary) -> void:
	var title: Variant = payload.get(&"title", null)
	var tint: StringName = payload.get(&"tint", &"")
	if title is Label and is_instance_valid(title) and tint != &"":
		(title as Label).add_theme_color_override(&"font_color", _rarity_color(tint))


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
