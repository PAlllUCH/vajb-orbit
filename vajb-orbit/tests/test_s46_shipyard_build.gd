@tool
extends McpTestSuite
const Support := preload("res://tests/support.gd")
## Suite s46_shipyard_build: the SHIPYARD build view rebuilt as the AUCTION house style
## (STATION_HUB section 23.8 P54; 10 section 3.5's view law). One row per acceptance item:
##   1. the build view is two category sections in section 5.10's shelf idiom: HULLS
##      (10 section 3.1's nine recipe rows) then MODULES (header + the staged caption
##      `MODULE BUILDS LAND WITH THE MODULE CATALOGUE`, no rows);
##   2. each HULLS row is a `Button` + container children (the craft row's anatomy):
##      name + `<class> CLASS · <hull> · <slots>` meta, one `<n>× <name>` run per
##      material with the family glyph 24 at its own cut and `<held>/<needed>` from
##      `cargo_qty`, the labour line `<labour> CR LABOUR`, the READY / MISSING chip and
##      the BUILD ActionInline rightmost;
##   3. the row press opens the N28 sheet with the recipe's full bill (read-only);
##   4. the BUILD chip opens the confirm door through the S25 seam (CONFIRM PURCHASE,
##      A6's shipyard wording verbatim); the confirmed answer runs `queue_job`
##      unchanged and a refusal writes the shipped BUILD_REFUSED strip line;
##   5. `BUILD_HULL_FORMAT` / `BUILD_MODULE_FORMAT` are gone - no CR build figure
##      anywhere in the build view but the labour line;
##   6. the queue's commit/refund law stands untouched (model-level: commit at queue,
##      one build at a time, refund in full on cancel, one session then collect), and
##      the queue/scrap views keep their S27 wordings;
##   7. T-175's SHIPYARD rider: the pane subtitle renders through `StationCaption`
##      (the S41 cure, already shipped).
##
## The suite borrows the PlayerProfile autoload the way `test_s45_craft.gd` does
## (`save_path` repointed at a scratch file, every borrowed field handed back in
## `suite_teardown`), mounts the shipped panel scene ONCE, keeps `profile_changed`
## disconnected (the panel connects nothing itself; the shell drives
## `refresh_profile`) and rebuilds rows through `refresh_profile(&"cargo")` - the
## message-queue discipline S45's report disclosed. The transaction rows run on a
## throwaway `player_profile.gd` instance the way the s27 model rows do.

const PanelScene := preload("res://ui/station/shipyard_panel.tscn")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const ShipyardScript := preload("res://game/shipyard.gd")
const CatalogData := preload("res://game/station_catalog.gd")

const SUITE_ID := "s46_shipyard_build"
const SCRATCH_PROFILE := "user://test_s46_shipyard_build.cfg"
const MODEL_SAVE := "user://test_s46_shipyard_build_model.cfg"
const PROFILE_SERVICE: StringName = &"PlayerProfile"

const CORVETTE: StringName = &"ship_corvette"
const VANGUARD: StringName = &"ship_vanguard"
const TUNGSTEN: StringName = &"mineral_tungsten"
const COBALT: StringName = &"mineral_cobalt"
const WRECK_ALLOY: StringName = &"comp_scrap_2"

var _model: Node = null
var _profile: Node = null
var _host: Control = null
var _panel: Control = null
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_credits := 0
var _previous_cargo: Dictionary = {}
var _previous_fits: Dictionary = {}
var _previous_owned: Array = []
var _previous_modules: Dictionary = {}
var _previous_job: Dictionary = {}
var _previous_session := 0
var _statuses: Array[Array] = []
var _confirms: Array[Dictionary] = []
var _sheets: Array[Dictionary] = []


func suite_name() -> String:
	return SUITE_ID


func suite_setup(_ctx: Dictionary) -> void:
	_profile = Support.profile()
	if _profile == null:
		fail_setup("the PlayerProfile autoload is the account the pane reads")
		return
	_previous_path = String(_profile.get(&"save_path"))
	_previous_ship = StringName(_profile.call(&"active_ship"))
	_previous_credits = int(_profile.call(&"credits"))
	_previous_cargo = (_profile.get(&"_cargo") as Dictionary).duplicate(true)
	_previous_fits = _profile.call(&"fits")
	_previous_owned = _profile.call(&"owned_ships")
	_previous_modules = _profile.call(&"modules")
	_previous_job = _profile.call(&"shipyard_job")
	_previous_session = int(_profile.call(&"shipyard_session"))
	_profile.set(&"save_path", SCRATCH_PROFILE)
	Support.delete_file(SCRATCH_PROFILE)


func suite_teardown() -> void:
	_free_host()
	if _profile == null:
		return
	_profile.set(&"_credits", _previous_credits)
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_cargo", _previous_cargo)
	_profile.set(&"_fits", _previous_fits)
	_profile.set(&"_owned_ships", _previous_owned)
	_profile.set(&"_modules", _previous_modules)
	_profile.set(&"_shipyard_job", _previous_job)
	_profile.set(&"_shipyard_session", _previous_session)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	Support.delete_file(SCRATCH_PROFILE)
	_profile = null


func setup() -> void:
	if _model != null and is_instance_valid(_model):
		_model.free()
	_model = null
	_seed_account()
	_statuses.clear()
	_confirms.clear()
	_sheets.clear()
	if _panel == null or not is_instance_valid(_panel):
		_mount_panel()


func teardown() -> void:
	if _model != null and is_instance_valid(_model):
		_model.free()
	_model = null
	Support.delete_file(MODEL_SAVE)


## ------------------------------------- AC1: two category sections in the shelf idiom


func test_p54_two_sections_wear_the_shelf_idiom() -> void:
	var panel := _panel
	panel.call(&"_set_mode", "build")
	var list := panel.get_node_or_null(NodePath("%BuildList")) as VBoxContainer
	assert_true(list != null, "the build list ships")
	if list == null:
		return
	var children := list.get_children()
	assert_true(children.size() >= 12, "both sections' chrome and the nine rows")
	## The HULLS section: its caption, its column band, then ten-section 3.1's nine
	## recipe rows in `HULL_RECIPES`' own order.
	var hulls := children[0].get_node_or_null(NodePath("SectionLabel")) as Label
	assert_eq(String(hulls.text), "HULLS", "the first section's caption")
	assert_eq(hulls.theme_type_variation, StringName("SectionHeader"),
		"the section caption is the shelf idiom's own ink")
	var band := children[1].get_node_or_null(NodePath("HullBand")) as HBoxContainer
	assert_true(band != null, "the P40 column band ships")
	if band != null:
		var words: Array[String] = []
		for child: Node in band.get_children():
			var label := child as Label
			words.append(label.text if label != null else "")
		assert_eq(words, ["HULL", "MATERIALS", "LABOUR", "STATE", ""],
			"the band names the pinned columns, the chip's seat unnamed")
	var rows: Array[Button] = []
	var ids: Array[StringName] = []
	for index in range(2, 11):
		var button := children[index] as Button
		assert_true(button != null, "the HULLS section's row %d is a Button" % (index - 2))
		if button == null:
			return
		rows.append(button)
		ids.append(StringName(button.get_meta(&"id", &"")))
	assert_eq(ids, _buildable_ids(), "one row per 10 section 3.1 recipe, in order")
	## The MODULES section: its caption and the staged caption alone - the rows are
	## one pass away at the owner's word, the pin ships the caption.
	var modules := children[11].get_node_or_null(NodePath("SectionLabel")) as Label
	assert_eq(String(modules.text), "MODULES", "the second section's caption")
	var staged := children[12].get_node_or_null(NodePath("StagedCaption")) as Label
	assert_true(staged != null, "the staged caption ships")
	if staged != null:
		assert_eq(
			String(staged.text),
			"MODULE BUILDS LAND WITH THE MODULE CATALOGUE",
			"the pinned staged caption"
		)
		assert_eq(staged.theme_type_variation, StringName("StationCaption"),
			"the staged caption is the caption family's ink")
	for index in range(13, children.size()):
		assert_false(children[index] is Button, "no MODULES row ships (the staged caption only)")


## --------------------------------- AC2: the hull row carries the bill as materials


func test_p54_the_hull_row_carries_the_bill_as_materials() -> void:
	var panel := _panel
	panel.call(&"_set_mode", "build")
	var row := _build_row(panel, CORVETTE)
	assert_true(row != null, "the corvette's build row ships")
	if row == null:
		return
	assert_eq(row.custom_minimum_size.y, 76.0, "the AUCTION row height")
	assert_eq(String(row.get_meta(&"chrome_class", "")), "C4", "the C4 row strip chrome")
	var title := row.get_node_or_null(NodePath("RowInner/RowBox/TitleBox/Title")) as Label
	var meta := row.get_node_or_null(NodePath("RowInner/RowBox/TitleBox/Meta")) as Label
	assert_eq(String(title.text), "Spearhead", "the catalogue's own name")
	assert_eq(String(meta.text), "CORVETTE CLASS · 1300 HULL · 13 SLOTS",
		"the pinned meta: class word, hull, slot cells")
	assert_eq(
		title.text_overrun_behavior,
		TextServer.OVERRUN_TRIM_ELLIPSIS,
		"N45's trim law on the title"
	)
	assert_eq(
		meta.text_overrun_behavior,
		TextServer.OVERRUN_TRIM_ELLIPSIS,
		"N45's trim law on the meta"
	)
	## The materials bill as materials: one run per material, in the recipe's own
	## order, each carrying its glyph at its own cut and the held/needed read.
	var runs := row.get_node_or_null(NodePath("RowInner/RowBox/MaterialsBox")) as HBoxContainer
	assert_true(runs != null, "the materials cell ships")
	if runs == null:
		return
	assert_eq(runs.get_child_count(), 3, "one run per recipe material")
	var first := runs.get_child(0) as HBoxContainer
	var glyph := first.get_node_or_null(NodePath("Glyph")) as TextureRect
	var run_label := first.get_node_or_null(NodePath("RunLabel")) as Label
	var held_label := first.get_node_or_null(NodePath("HeldLabel")) as Label
	assert_eq(glyph.custom_minimum_size, Vector2(24.0, 24.0), "the family glyph at its own cut")
	assert_eq(glyph.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED,
		"the glyph never stretches")
	assert_eq(String(run_label.text), "60× TUNGSTEN ORE", "the <n>× <name> run idiom")
	assert_eq(String(held_label.text), "0/60", "the <held>/<needed> read from cargo_qty")
	var second := runs.get_child(1) as HBoxContainer
	assert_eq(
		String((second.get_node_or_null(NodePath("RunLabel")) as Label).text),
		"35× COBALT ORE",
		"the recipe's own order"
	)
	var third := runs.get_child(2) as HBoxContainer
	assert_eq(
		String((third.get_node_or_null(NodePath("RunLabel")) as Label).text),
		"4× WRECK ALLOY",
		"the component run names its catalogue name"
	)
	## The labour line - the build view's only CR figure.
	var labour_value := row.get_node_or_null(NodePath("RowInner/RowBox/LabourBox/Value")) as Label
	var labour_caption := row.get_node_or_null(NodePath("RowInner/RowBox/LabourBox/Caption")) as Label
	assert_eq(String(labour_value.text), "9 450", "the labour, house-grouped")
	assert_eq(String(labour_caption.text), "CR LABOUR", "the labour caption")
	## The BUILD ActionInline rightmost.
	var chip := row.get_node_or_null(NodePath("RowInner/RowBox/BuildChip")) as Button
	assert_true(chip != null, "the row carries its BUILD chip")
	if chip == null:
		return
	assert_eq(chip.custom_minimum_size, Vector2(96.0, 32.0), "the ActionInline size")
	assert_eq(String(chip.text), "BUILD", "the chip's word")
	assert_eq(String(chip.get_meta(&"chrome_class", "")), "C3", "the ActionInline chrome")
	assert_eq(chip.focus_mode, Control.FOCUS_NONE, "the row stays the focus unit")
	## The nine rows' order is `HULL_RECIPES`' own (the fighter leads it, the A6
	## example's bill reads off the corvette).
	var fighter := _build_row(panel, &"ship_fighter")
	var fighter_run := fighter.get_node_or_null(
		NodePath("RowInner/RowBox/MaterialsBox")
	) as HBoxContainer
	assert_eq(
		String(((fighter_run.get_child(0) as HBoxContainer)
			.get_node_or_null(NodePath("RunLabel")) as Label).text),
		"45× IRON ORE",
		"the fighter leads the ladder with the doc's own bill"
	)


## --------------------------------------------- AC2: the chips read the hold


func test_p54_the_state_chips_read_the_hold() -> void:
	var panel := _panel
	panel.call(&"_set_mode", "build")
	var texts := _chip_texts(panel)
	assert_eq(texts[_index_of(CORVETTE)], "MISSING 60× TUNGSTEN ORE",
		"the empty hold names the first short material in recipe order")
	## The corvette's own bill lands in the hold: its chip flips to READY, the rest
	## still name their own first short input.
	_profile.set(&"_cargo", {TUNGSTEN: 60, COBALT: 35, WRECK_ALLOY: 4})
	panel.call(&"refresh_profile", &"cargo")
	texts = _chip_texts(panel)
	assert_eq(texts[_index_of(CORVETTE)], "READY", "a covered bill reads READY")
	assert_eq(texts[_index_of(&"ship_fighter")], "MISSING 45× IRON ORE",
		"the neighbours keep their own reads")
	## A partial stack still reads short, with the shortfall not the need.
	_profile.set(&"_cargo", {TUNGSTEN: 59, COBALT: 35, WRECK_ALLOY: 4})
	panel.call(&"refresh_profile", &"cargo")
	texts = _chip_texts(panel)
	assert_eq(texts[_index_of(CORVETTE)], "MISSING 1× TUNGSTEN ORE",
		"the shortfall is what the chip names")
	## The state chip is label + 1 px frame over the flat fill - never colour alone.
	var row := _build_row(panel, CORVETTE)
	var chip := row.get_node_or_null(NodePath("RowInner/RowBox/State/StateChip")) as PanelContainer
	var box := chip.get_theme_stylebox(&"panel") as StyleBoxFlat
	assert_true(box != null, "the state chip carries its own flat box")
	if box != null:
		assert_eq(box.border_color, panel.call(&"_token", &"metal_mid"), "the 1 px frame")
		assert_eq(box.bg_color, panel.call(&"_token", &"armory_chip_bg"), "the chip fill")
		assert_eq(box.border_width_left, 1, "the frame is 1 px")


## --------------------------------------------- AC3: the row press opens the bill sheet


func test_p54_the_row_press_opens_the_bill_sheet() -> void:
	var panel := _panel
	panel.call(&"_set_mode", "build")
	var row := _build_row(panel, CORVETTE)
	row.pressed.emit()
	assert_eq(_sheets.size(), 1, "the row press opened one sheet request")
	if _sheets.is_empty():
		return
	var payload: Dictionary = _sheets[0]
	assert_eq(String(payload[&"name"]), "Spearhead", "the sheet's name row")
	assert_eq(
		String(payload[&"stats"]),
		"MATERIALS · 60× TUNGSTEN ORE · 35× COBALT ORE · 4× WRECK ALLOY\nLABOUR · 9 450 CR",
		"the recipe's full bill, read-only"
	)
	assert_false(payload.has(&"price") or payload.has(&"owned"),
		"no price and no owned count - the auction owns the buy price (N35)")


## --------------------------------- AC4: the BUILD door through the confirm seam


func test_p54_the_build_chip_opens_the_confirm_door() -> void:
	var panel := _panel
	panel.call(&"_set_mode", "build")
	var row := _build_row(panel, CORVETTE)
	var chip := row.get_node_or_null(NodePath("RowInner/RowBox/BuildChip")) as Button
	chip.pressed.emit()
	assert_eq(_confirms.size(), 1, "the chip opened one confirm request")
	if _confirms.is_empty():
		return
	var payload: Dictionary = _confirms[0]
	assert_eq(String(payload[&"title"]), "CONFIRM PURCHASE", "A6's title")
	assert_eq(
		String(payload[&"body"]),
		"ARE YOU SURE YOU WANT TO BUILD CORVETTE FOR 60× TUNGSTEN ORE · 35× COBALT ORE · 4× WRECK ALLOY + 9 450 CR LABOUR?",
		"A6's shipyard wording, the worked example verbatim"
	)
	assert_eq(String(payload[&"confirm_text"]), "OK", "the OK answer")
	assert_eq(String(payload[&"cancel_text"]), "CANCEL", "the CANCEL answer")
	assert_eq(StringName(payload[&"action"]), &"queue_build", "the door's action")
	assert_eq(StringName(payload[&"id"]), CORVETTE, "the door names the recipe")
	assert_eq(StringName(payload[&"kind"]), ShipyardScript.KIND_HULL, "the door names the kind")
	## The confirmed answer runs the transaction unchanged on the borrowed account:
	## the materials leave the hold and the labour leaves the credits at queue time
	## (10 section 3.3).
	_profile.set(&"_cargo", {TUNGSTEN: 60, COBALT: 35, WRECK_ALLOY: 4})
	panel.call(&"refresh_profile", &"cargo")
	var before := int(_profile.call(&"credits"))
	panel.call(&"confirm_action", StringName(payload[&"action"]), StringName(payload[&"id"]))
	assert_eq(int(_profile.call(&"credits")), before - 9450, "the labour left the balance")
	assert_eq(int(_profile.call(&"cargo_qty", TUNGSTEN)), 0, "the tungsten left the hold")
	assert_eq(int(_profile.call(&"cargo_qty", COBALT)), 0, "the cobalt left the hold")
	assert_eq(int(_profile.call(&"cargo_qty", WRECK_ALLOY)), 0, "the alloy left the hold")
	var job: Dictionary = _profile.call(&"shipyard_job")
	assert_eq(StringName(job[ShipyardScript.KEY_ID]), CORVETTE, "the job queued")
	assert_eq(StringName(job[ShipyardScript.KEY_KIND]), ShipyardScript.KIND_HULL, "as a hull")
	assert_eq(_statuses.size(), 1, "the confirmed run reported once")
	if _statuses.size() == 1:
		assert_false(bool(_statuses[0][1]), "a success is not a danger line")
		assert_eq(String(_statuses[0][0]), "QUEUED · SPEARHEAD", "the status wording")
	## The confirmed press can still refuse: the queue is one-build-at-a-time, and
	## the refusal writes the shipped strip line.
	_statuses.clear()
	_confirms.clear()
	var rebuilt := _build_row(panel, CORVETTE)
	var chip_again := rebuilt.get_node_or_null(NodePath("RowInner/RowBox/BuildChip")) as Button
	chip_again.pressed.emit()
	assert_eq(_confirms.size(), 1, "the chip opened the door again")
	if _confirms.size() < 1:
		return
	panel.call(
		&"confirm_action",
		StringName(_confirms[0][&"action"]),
		StringName(_confirms[0][&"id"])
	)
	assert_eq(int(_profile.call(&"credits")), before - 9450, "no second labour charge moved")
	assert_eq(_statuses.size(), 1, "the refusal answered on the strip")
	if _statuses.size() == 1:
		assert_true(bool(_statuses[0][1]), "a refusal is a danger line")
		assert_eq(
			String(_statuses[0][0]),
			"BUILD REFUSED · MISSING MATERIALS OR CREDITS",
			"the shipped section 5.6 wording"
		)


## --------------------------------- AC5: the CR band is gone


func test_p54_the_cr_band_is_gone() -> void:
	var panel := _panel
	var script := panel.get_script() as GDScript
	var constants := script.get_script_constant_map()
	assert_false(constants.has("BUILD_HULL_FORMAT"), "the hull CR format is retired")
	assert_false(constants.has("BUILD_MODULE_FORMAT"), "the module CR format is retired")
	panel.call(&"_set_mode", "build")
	var list := panel.get_node_or_null(NodePath("%BuildList")) as VBoxContainer
	var cr_labels := 0
	for label: Label in _all_labels(list):
		var text := String(label.text)
		assert_false(text.contains("TO BUY"), "no TO BUY figure in the build view")
		assert_false(text.contains("TO BUILD"), "no TO BUILD figure in the build view")
		if text.contains("CR"):
			cr_labels += 1
			assert_eq(text, "CR LABOUR", "the labour caption is the only CR text")
	assert_eq(cr_labels, 9, "exactly the nine labour captions carry CR")


## --------------------------------- AC6: the queue law stands, the views byte-stable


func test_p54_the_queue_law_stands() -> void:
	## The queue view's idle wording is the S27 line, untouched.
	var panel := _panel
	panel.call(&"_set_mode", "queue")
	var body := panel.get_node_or_null(NodePath("%QueueBody")) as Label
	assert_eq(
		String(body.text),
		"NO BUILD IN PROGRESS · ONE BUILD AT A TIME (10 §3.3)",
		"the queue view's idle wording, byte-stable"
	)
	## The scrap view keeps its S27 row shape (the one owned hull, 50 % of its bill).
	panel.call(&"_set_mode", "scrap")
	var scrap_list := panel.get_node_or_null(NodePath("%ScrapList")) as VBoxContainer
	var scrap_rows := 0
	for child: Node in scrap_list.get_children():
		if child is Button:
			scrap_rows += 1
			var recipe := ShipyardScript.hull_recipe(VANGUARD)
			var scrap := ShipyardScript.scrap_materials(recipe[ShipyardScript.KEY_MATERIALS])
			assert_eq(
				String((child as Button).text),
				"VANGUARD · %d CR OF MATERIALS" % ShipyardScript.materials_value(scrap),
				"the scrap row reads 50 % of the recipe materials"
			)
	assert_eq(scrap_rows, 1, "one row per owned hull")
	panel.call(&"_set_mode", "build")
	## The model-level law, on a throwaway account: commit at queue, one build at a
	## time, refund in full on cancel, one session then collect (10 section 3.3).
	_model = _make_model()
	_model.add_cargo(TUNGSTEN, 60)
	_model.add_cargo(COBALT, 35)
	_model.add_cargo(WRECK_ALLOY, 4)
	_model.set(&"_credits", 20000)
	var credits := int(_model.call(&"credits"))
	assert_true(ShipyardScript.queue_job(_model, ShipyardScript.KIND_HULL, CORVETTE), "queues")
	assert_eq(int(_model.call(&"cargo_qty", TUNGSTEN)), 0, "the materials left at queue time")
	assert_eq(int(_model.call(&"credits")), credits - 9450, "the labour left at queue time")
	assert_false(ShipyardScript.queue_job(_model, ShipyardScript.KIND_HULL, &"ship_fighter"),
		"one build at a time")
	assert_true(ShipyardScript.cancel_job(_model), "cancels before completion")
	assert_eq(int(_model.call(&"cargo_qty", TUNGSTEN)), 60, "the refund is in full")
	assert_eq(int(_model.call(&"credits")), credits, "the labour came back")
	assert_true(ShipyardScript.queue_job(_model, ShipyardScript.KIND_HULL, CORVETTE), "queues again")
	_model.call(&"set_shipyard_session", int(_model.call(&"shipyard_session")) + 1)
	assert_true(ShipyardScript.is_ready(_model), "one session makes it ready")
	assert_true(ShipyardScript.collect(_model), "the hull is delivered")
	assert_true(bool(_model.call(&"owns_ship", CORVETTE)), "the built hull entered the roster")
	assert_true(ShipyardScript.job(_model).is_empty(), "the queue is idle again")


## --------------------------------- T-175: the SHIPYARD rider


func test_t175_the_shipyard_captions_render_the_a1_ink() -> void:
	var panel := _panel
	var subtitle := panel.get_node_or_null(NodePath("%PaneSubtitle")) as Label
	assert_true(subtitle != null, "the pane subtitle ships")
	if subtitle == null:
		return
	assert_eq(subtitle.theme_type_variation, StringName("StationCaption"),
		"the subtitle renders through StationCaption (the S41 cure, already shipped)")
	assert_eq(String(subtitle.text), "YOUR HULLS · 1 IN THE HANGAR · SIDE VIEWS ONLY",
		"the subtitle's own format, unchanged")


## ------------------------------------------------------------------------- helpers


func _buildable_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id: StringName in ShipyardScript.buildable_hulls():
		ids.append(id)
	return ids


func _index_of(ship_id: StringName) -> int:
	return _buildable_ids().find(ship_id)


func _build_row(panel: Control, ship_id: StringName) -> Button:
	var rows := panel.get_node_or_null(NodePath("%BuildList")) as VBoxContainer
	if rows == null:
		return null
	for child: Node in rows.get_children():
		var button := child as Button
		if button != null and StringName(button.get_meta(&"id", &"")) == ship_id:
			return button
	return null


func _chip_texts(panel: Control) -> Array[String]:
	var texts: Array[String] = []
	var ids := _buildable_ids()
	var by_id: Dictionary = {}
	var rows := panel.get_node_or_null(NodePath("%BuildList")) as VBoxContainer
	if rows == null:
		return texts
	for child: Node in rows.get_children():
		var button := child as Button
		if button == null:
			continue
		var label := button.get_node_or_null(NodePath("RowInner/RowBox/State/StateChip/ChipLabel")) as Label
		if label != null:
			by_id[StringName(button.get_meta(&"id", &""))] = String(label.text)
	for id: StringName in ids:
		texts.append(String(by_id.get(id, "")))
	return texts


func _all_labels(root: Node) -> Array[Label]:
	var out: Array[Label] = []
	if root is Label:
		out.append(root)
	for child: Node in root.get_children():
		out.append_array(_all_labels(child))
	return out


func _make_model() -> Node:
	var model: Node = load("res://autoload/player_profile.gd").new()
	model.save_path = MODEL_SAVE
	return model


## A fresh account, written straight into the borrowed fields (the s44/s45 idiom):
## the setter doors emit per write, and this suite's shared pane pays one rebuild
## per test instead of one per field.
func _seed_account() -> void:
	var owned: Array[StringName] = [VANGUARD]
	_profile.set(&"_credits", 20000)
	_profile.set(&"_active_ship", VANGUARD)
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_cargo", {})
	_profile.set(&"_shipyard_job", {})
	_profile.set(&"_shipyard_session", 0)


func _mount_panel() -> void:
	if _host == null or not is_instance_valid(_host):
		_host = Control.new()
		_host.name = "S46BuildHost"
		_host.theme = ThemeRes
		_host.size = Vector2(1920.0, 1080.0)
		Support.profile().add_child(_host)
	_panel = PanelScene.instantiate() as Control
	_host.add_child(_panel)
	## `profile_changed` stays DISCONNECTED for this suite (the s45 idiom): the panel
	## connects nothing itself, and every read here is a fresh `refresh_profile`
	## rebuild or a captured signal.
	_panel.connect(&"status_requested", _on_status_requested)
	_panel.connect(&"confirm_requested", _on_confirm_requested)
	_panel.connect(&"sheet_requested", _on_sheet_requested)


func _free_host() -> void:
	if _panel != null and is_instance_valid(_panel):
		_panel.free()
	_panel = null
	if _host != null and is_instance_valid(_host):
		_host.free()
	_host = null


func _format_int(value: int) -> String:
	return CatalogData.group_int(value)


func _on_status_requested(message: String, danger: bool) -> void:
	_statuses.append([message, danger])


func _on_confirm_requested(payload: Dictionary) -> void:
	_confirms.append(payload)


func _on_sheet_requested(payload: Dictionary) -> void:
	_sheets.append(payload)
