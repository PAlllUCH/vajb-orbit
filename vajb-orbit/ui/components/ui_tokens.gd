class_name UiTokens
extends RefCounted
## One source for the theme-token read and the integer grouping every UI surface
## used to carry privately (CODE_AUDIT 2026-10-19, P1 item 5). The station
## panels read it through `StationPanel._token`; the rest of the UI delegates
## its own `_token` here, so a token fallback or the grouping rule moves in one
## place.
##
## `format_int` delegates to the one grouping rule CONTRACTS section 23.1 pins
## (`StationCatalog.group_int`), so the HUD, the cargo overlay and the station
## cannot drift.
##
## Reversal: copy the three-line theme read back into the surface that needs it.

const TOKENS_TYPE: StringName = &"Tokens"
const CatalogScript := preload("res://game/station_catalog.gd")


## The live theme's colour for one token, the caller's fallback when the theme
## does not carry it.
static func colour(control: Control, token: StringName, fallback: Color = Color.WHITE) -> Color:
	if control.has_theme_color(token, TOKENS_TYPE):
		return control.get_theme_color(token, TOKENS_TYPE)
	return fallback


## The house integer grouping: `1 234 567`, negative values keep their sign.
static func format_int(value: int) -> String:
	return CatalogScript.group_int(value)
