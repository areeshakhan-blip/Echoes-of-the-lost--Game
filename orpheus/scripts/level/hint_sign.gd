extends Node2D
## An ancient stone tablet that shows a short tip when the player walks near.
## Origin is at the bottom centre. The level sets "text".

var text := ""

var _label: Label
var _player: Node2D
var _time := 0.0


func _ready() -> void:
	_label = Label.new()
	_label.text = text
	_label.size = Vector2(320.0, 76.0)
	_label.position = Vector2(-160.0, -150.0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 19)
	_label.add_theme_color_override("font_color", Color("#f4f0ff"))
	_label.add_theme_color_override("font_outline_color", Color("#0c0826"))
	_label.add_theme_constant_override("outline_size", 5)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.05, 0.03, 0.16, 0.85)
	box.border_color = Color(0.49, 0.98, 0.9, 0.7)
	box.set_border_width_all(2)
	box.set_corner_radius_all(4)
	box.content_margin_left = 10.0
	box.content_margin_right = 10.0
	_label.add_theme_stylebox_override("normal", box)
	_label.modulate.a = 0.0
	_label.z_index = 20
	add_child(_label)


func _process(delta: float) -> void:
	_time += delta
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
	var target := 0.0
	if _player != null:
		var offset := _player.global_position - global_position
		if absf(offset.x) < 230.0 and absf(offset.y) < 140.0:
			target = 1.0
	_label.modulate.a = move_toward(_label.modulate.a, target, delta * 4.0)
	queue_redraw()


func _draw() -> void:
	var stone := Color("#4b5679")
	var stone_light := Color("#6a789f")
	var outline := Color("#141a30")
	# Slab with a rounded top
	draw_rect(Rect2(-15, -46, 30, 46), outline)
	draw_rect(Rect2(-13, -44, 26, 44), stone)
	draw_rect(Rect2(-13, -44, 6, 44), stone_light)
	draw_rect(Rect2(-11, -50, 22, 6), outline)
	draw_rect(Rect2(-9, -49, 18, 5), stone)
	# Glowing rune that gently pulses
	var pulse := 0.6 + 0.4 * sin(_time * 2.5)
	var glow := Color(0.49, 0.98, 0.9, pulse)
	draw_rect(Rect2(-1, -38, 3, 20), glow)
	draw_rect(Rect2(-6, -32, 5, 3), glow)
	draw_rect(Rect2(2, -26, 5, 3), glow)
