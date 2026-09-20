extends Area2D
## An Echo Shard: a glowing crystal fragment of the lost echoes.

const Effects = preload("res://scripts/effects/effects.gd")
const PixelArt = preload("res://scripts/systems/pixel_art.gd")

const CRYSTAL := Color("#6ff5e0")
const CRYSTAL_LIGHT := Color("#d6fff8")
const CRYSTAL_DARK := Color("#2fb5b0")

var _time := 0.0
var _phase := 0.0
var _collected := false
var _glow: Sprite2D


func _ready() -> void:
	_phase = randf() * TAU
	_glow = PixelArt.make_glow(Color(0.3, 1.0, 0.9, 0.55), 46.0)
	add_child(_glow)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_glow.modulate.a = 0.45 + 0.15 * sin(_time * 3.0 + _phase)
	queue_redraw()


func _draw() -> void:
	var bob := sin(_time * 2.6 + _phase) * 4.0
	var half_width := 9.0 + sin(_time * 3.0 + _phase) * 1.5
	var top := Vector2(0.0, -16.0 + bob)
	var right := Vector2(half_width, bob)
	var bottom := Vector2(0.0, 16.0 + bob)
	var left := Vector2(-half_width, bob)
	var middle := Vector2(0.0, bob)
	draw_colored_polygon(PackedVector2Array([top, right, bottom, left]), CRYSTAL)
	draw_colored_polygon(PackedVector2Array([top, right, middle]), CRYSTAL_LIGHT)
	draw_colored_polygon(PackedVector2Array([bottom, left, middle]), CRYSTAL_DARK)
	draw_polyline(PackedVector2Array([top, right, bottom, left, top]), Color("#0c0826"), 2.0)
	# Twinkle
	var twinkle := maxf(0.0, sin(_time * 4.0 + _phase * 2.0))
	if twinkle > 0.5:
		draw_rect(Rect2(6.0, -14.0 + bob, 2.0, 2.0), Color(1, 1, 1, twinkle))


func _on_body_entered(body: Node2D) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	GameState.collect_echo()
	var pitch := minf(1.0 + 0.05 * float(GameState.echoes - 1), 1.5)
	AudioManager.play("collect", pitch)
	Effects.burst(get_tree(), global_position, Color(0.5, 1.0, 0.92), 14, 170.0, 0.6, 60.0)
	Effects.ring(get_tree(), global_position, Color(0.5, 1.0, 0.92, 0.9), 40.0, 0.4)
	Effects.text(get_tree(), global_position + Vector2(0.0, -24.0), "+%d" % GameState.ECHO_POINTS, Color("#ffd35a"))
	queue_free()
