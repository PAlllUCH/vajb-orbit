extends Button
## N37's INSPECT chip (UI_SPEC section 12.3): the row's trailing action cell, always
## present. A flat `ActionInline` chip - the base theme `Button`, no asset, 96x32 (UI_SPEC
## section 8's P1 `ActionInline`) - that publishes the row's own sheet payload through the
## pane's `sheet_requested` signal. It carries no state of its own beyond its label, so
## showing or hiding it is the pane's business and A5.5 is untouched.
##
## The chip is a real focusable control (FOCUS_ALL) so the keyboard route - focus the chip,
## `ui_accept` - opens the same sheet the pointer does. A grid cell's cluster chip is the
## same component in `disabled` state until the cluster has a target (N37).

signal inspect_chip_pressed

const ChromeFamily := preload("res://ui/theme/chrome_family.gd")

const CHIP_SIZE := Vector2(96.0, 32.0)
const CHIP_TEXT := "INSPECT"

## S36-F1 (A4, F5): the pane's cluster chip expands to 452 px wide, past C3's 160 band
## ceiling, so it reverts to the native pre-swap button (no C3 plate). Set before the chip
## enters the tree (its `_ready` reads it).
var wear_chrome := true


func _ready() -> void:
	custom_minimum_size = CHIP_SIZE
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	## S36 (UI_SPEC section 15.1): the chip wears C3 `ui_inline_chip` at the measured
	## nine-slice margins, states by tint (A7) - unless it is the out-of-band cluster chip.
	if wear_chrome:
		ChromeFamily.apply_chip(self)
	if text.is_empty():
		text = CHIP_TEXT
	pressed.connect(_on_pressed)


## N37's dimmed cluster state: `disabled` alone carries it - the theme's own
## `font_disabled_color` is `text_dim`, so the state is never a colour-only channel.
func set_dimmed(dimmed: bool) -> void:
	disabled = dimmed


func _on_pressed() -> void:
	inspect_chip_pressed.emit()
