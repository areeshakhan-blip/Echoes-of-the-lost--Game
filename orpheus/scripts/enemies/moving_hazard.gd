extends Area2D
## A spiked wisp-orb that glides back and forth along a line.
## Set "travel" for the direction/distance and "phase" to offset the timing.

const PixelArt = preload("res://scripts/systems/pixel_art.gd")

var travel := Vector2(0.0, 72.0)
var period := 2.4
var phase := 0.0

var _origin := Vector2.ZERO
var _time := 0.0


func _ready() -> void:
	_origin = position
	add_child(PixelArt.make_glow(Color(1.0, 0.25, 0.6, 0.5), 44.0))


func _physics_process(delta: float) -> void:
	_time += delta
	position = _origin + travel * sin(_time * TAU / period + phase)
	for body in get_overlapping_bodies():
		var target = body
		if target.is_in_group("player"):
			target.hurt()
	queue_redraw()


func _draw() -> void:
	# Faint track showing where the orb travels
	var track_start := _origin - position - travel
	var track_end := _origin - position + travel
	draw_line(track_start, track_end, Color(1.0, 0.4, 0.7, 0.18), 2.0)
	# Spikes
	for i in 8:
		var angle := float(i) * TAU / 8.0 + _time * 1.5
		var tip := Vector2.from_angle(angle) * 21.0
		var side_a := Vector2.from_angle(angle - 0.25) * 11.0
		var side_b := Vector2.from_angle(angle + 0.25) * 11.0
		draw_colored_polygon(PackedVector2Array([side_a, tip, side_b]), Color("#ff5fa2"))
	# Body
	draw_circle(Vector2.ZERO, 13.0, Color("#140a2e"))
	draw_circle(Vector2.ZERO, 10.0, Color("#3a1a70"))
	draw_circle(Vector2.ZERO, 5.0 + sin(_time * 5.0), Color("#ff9ac8"))
