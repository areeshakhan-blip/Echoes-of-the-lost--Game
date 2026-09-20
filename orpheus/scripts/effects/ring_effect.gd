extends Node2D
## An expanding, fading ring. Frees itself when finished.

var _color := Color.WHITE
var _max_radius := 56.0
var _duration := 0.5
var _time := 0.0


func setup(color: Color, max_radius: float, duration: float) -> void:
	_color = color
	_max_radius = max_radius
	_duration = duration


func _process(delta: float) -> void:
	_time += delta
	if _time >= _duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := clampf(_time / _duration, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - t, 3.0)
	var radius := lerpf(4.0, _max_radius, eased)
	var faded := Color(_color.r, _color.g, _color.b, (1.0 - t) * _color.a)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, faded, 3.0)
	draw_arc(Vector2.ZERO, radius * 0.7, 0.0, TAU, 32, Color(faded.r, faded.g, faded.b, faded.a * 0.5), 2.0)
