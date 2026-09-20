extends Area2D
## An ancient brazier-obelisk. Touching it saves the respawn point.
## Origin is at the bottom centre.

const Effects = preload("res://scripts/effects/effects.gd")
const PixelArt = preload("res://scripts/systems/pixel_art.gd")

## Set by the level (1, 2, 3 ... from left to right).
var index := 1

var _active := false
var _energy := 0.0
var _time := 0.0
var _glow: Sprite2D


func _ready() -> void:
	_glow = PixelArt.make_glow(Color(0.4, 1.0, 0.9, 0.0), 90.0)
	_glow.position = Vector2(0.0, -100.0)
	add_child(_glow)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	var target := 1.0 if _active else 0.0
	_energy = move_toward(_energy, target, delta * 2.0)
	_glow.modulate.a = _energy * (0.55 + 0.1 * sin(_time * 3.0))
	queue_redraw()


func _draw() -> void:
	var stone := Color("#4b5679")
	var stone_light := Color("#6a789f")
	var stone_dark := Color("#33405f")
	var outline := Color("#141a30")
	# Plinth
	draw_rect(Rect2(-20, -12, 40, 12), outline)
	draw_rect(Rect2(-18, -10, 36, 10), stone_dark)
	draw_rect(Rect2(-14, -22, 28, 12), outline)
	draw_rect(Rect2(-12, -20, 24, 10), stone)
	# Pillar
	draw_rect(Rect2(-11, -82, 22, 62), outline)
	draw_rect(Rect2(-9, -80, 18, 60), stone)
	draw_rect(Rect2(-9, -80, 5, 60), stone_light)
	draw_rect(Rect2(-13, -88, 26, 10), outline)
	draw_rect(Rect2(-11, -86, 22, 6), stone_light)
	# Rune: dim when asleep, glowing teal when lit
	var rune := Color("#2a3556").lerp(Color("#7df9e6"), _energy)
	draw_rect(Rect2(-1, -68, 3, 30), rune)
	draw_rect(Rect2(-6, -62, 5, 3), rune)
	draw_rect(Rect2(2, -54, 5, 3), rune)
	draw_rect(Rect2(-6, -46, 5, 3), rune)
	# Floating crystal on top
	var bob := sin(_time * 2.0) * 3.0
	var crystal := Color("#4b5a86").lerp(Color("#7df9e6"), _energy)
	var top := Vector2(0.0, -122.0 + bob)
	var mid := Vector2(0.0, -108.0 + bob)
	var pts := PackedVector2Array([top, Vector2(8, -108.0 + bob), Vector2(0, -94.0 + bob), Vector2(-8, -108.0 + bob)])
	draw_colored_polygon(pts, crystal)
	draw_colored_polygon(PackedVector2Array([top, Vector2(8, -108.0 + bob), mid]), crystal.lightened(0.5))
	draw_polyline(PackedVector2Array([top, Vector2(8, -108.0 + bob), Vector2(0, -94.0 + bob), Vector2(-8, -108.0 + bob), top]), outline, 2.0)


func _on_body_entered(body: Node2D) -> void:
	if _active or not body.is_in_group("player"):
		return
	_active = true
	GameState.set_checkpoint(global_position + Vector2(0.0, -20.0), index)
	AudioManager.play("checkpoint")
	Effects.burst(get_tree(), global_position + Vector2(0.0, -100.0), Color(0.5, 1.0, 0.92), 24, 200.0, 0.8, 20.0)
	Effects.ring(get_tree(), global_position + Vector2(0.0, -100.0), Color(0.5, 1.0, 0.92, 0.9), 70.0, 0.6)
	Effects.text(get_tree(), global_position + Vector2(0.0, -130.0), "CHECKPOINT!", Color("#7df9e6"))
