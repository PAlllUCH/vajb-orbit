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

const CHIP_SIZE := Vector2(96.0, 32.0)
const CHIP_TEXT := "INSPECT"


func _ready() -> void:
	custom_minimum_size = CHIP_SIZE
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if text.is_empty():
		text = CHIP_TEXT
	pressed.connect(_on_pressed)


## N37's dimmed cluster state: `disabled` alone carries it - the theme's own
## `font_disabled_color` is `text_dim`, so the state is never a colour-only channel.
func set_dimmed(dimmed: bool) -> void:
	disabled = dimmed


func _on_pressed() -> void:
	inspect_chip_pressed.emit()
