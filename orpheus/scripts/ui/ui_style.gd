extends RefCounted
## One shared look for every menu and HUD element, built in code.

const GOLD := Color("#ffd35a")
const TEAL := Color("#7df9e6")
const VIOLET := Color("#b48cff")
const INK := Color("#0c0826")
const TEXT := Color("#f4f0ff")

static var _theme: Theme = null


static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	var theme := Theme.new()
	theme.default_font_size = 22

	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_outline_color", "Label", INK)
	theme.set_constant("outline_size", "Label", 6)

	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.05, 0.03, 0.16, 0.78)
	panel.border_color = Color(TEAL.r, TEAL.g, TEAL.b, 0.6)
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(4)
	panel.content_margin_left = 16.0
	panel.content_margin_right = 16.0
	panel.content_margin_top = 8.0
	panel.content_margin_bottom = 8.0
	theme.set_stylebox("panel", "PanelContainer", panel)

	theme.set_stylebox("normal", "Button", _button_box(Color(0.12, 0.09, 0.32, 0.95), TEAL))
	theme.set_stylebox("hover", "Button", _button_box(Color(0.2, 0.15, 0.5, 1.0), GOLD))
	theme.set_stylebox("pressed", "Button", _button_box(Color(0.3, 0.22, 0.65, 1.0), GOLD))
	var focus := _button_box(Color(0, 0, 0, 0), GOLD)
	focus.draw_center = false
	theme.set_stylebox("focus", "Button", focus)
	theme.set_font_size("font_size", "Button", 26)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", GOLD)
	theme.set_color("font_pressed_color", "Button", GOLD)
	theme.set_color("font_focus_color", "Button", TEXT)

	_theme = theme
	return _theme


static func _button_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(3)
	box.set_corner_radius_all(4)
	box.content_margin_left = 24.0
	box.content_margin_right = 24.0
	box.content_margin_top = 10.0
	box.content_margin_bottom = 10.0
	return box


## Big title-style text with a thick outline.
static func style_title(label: Label, size: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", maxi(6, size / 6))
