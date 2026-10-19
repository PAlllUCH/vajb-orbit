class_name ShipSlots
extends RefCounted
## One source for 09 section 1's slot glyph stems and the 48 px slot art path.
## The armory, fitting, shipyard and ship-status panes each carried the same
## three constants before 2026-10-19; the map is now read here only.
##
## Reversal: copy the table back into the pane that needs it.

const STEMS: Dictionary = {
	&"engines": "engine",
	&"power": "power",
	&"weapons": "w",
	&"shields": "s",
	&"armour": "h",
	&"computers": "c",
	&"boosters": "b",
	&"utility": "u",
}
const GLYPH_DIR := "res://assets/icons/slot/"
const GLYPH_TEMPLATE := "icon_slot_%s.svg"


## The glyph stem for a fit slot key, empty for an unknown key.
static func stem(slot_key: StringName) -> String:
	return String(STEMS.get(slot_key, ""))


## The slot's shipped 48 px glyph, null for an unknown key or a missing file.
static func glyph(slot_key: StringName) -> Texture2D:
	var value := stem(slot_key)
	if value.is_empty():
		return null
	var path := GLYPH_DIR + GLYPH_TEMPLATE % value
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


## The slot's glyph path, empty for an unknown key.
static func glyph_path(slot_key: StringName) -> String:
	var value := stem(slot_key)
	if value.is_empty():
		return ""
	return GLYPH_DIR + GLYPH_TEMPLATE % value
