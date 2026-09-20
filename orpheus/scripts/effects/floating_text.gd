extends Node2D
## Text that drifts upwards and fades out ("+100", "CHECKPOINT!").


func setup(message: String, color: Color) -> void:
	z_index = 50
	var label := Label.new()
	label.text = message
	label.size = Vector2(240.0, 32.0)
	label.position = Vector2(-120.0, -16.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#0c0826"))
	label.add_theme_constant_override("outline_size", 8)
	add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 56.0, 0.9).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.45)
	tween.chain().tween_callback(queue_free)
