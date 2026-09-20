extends Node2D
## Draws Orpheus in a chunky pixel-art style, animated in code (run cycle,
## breathing, squash and stretch, flowing cape). One art pixel = 2 screen pixels.
## The node's origin is at Orpheus' feet.

const U := 2.0

const OUTLINE := Color("#140d2e")
const CLOAK := Color("#4a3fb0")
const CLOAK_LIGHT := Color("#6a5fe0")
const CLOAK_DARK := Color("#33297f")
const HOOD := Color("#2c2472")
const SKIN := Color("#f3cfa6")
const GOLD := Color("#ffd35a")
const GOLD_DARK := Color("#c9922e")
const GLOW := Color("#7df9e6")
const BOOT := Color("#1c1440")

var _time := 0.0
var _run_phase := 0.0
var _velocity := Vector2.ZERO
var _grounded := true
var _facing := 1
var _squash := Vector2.ONE
var _outline_pass := false


func update_state(delta: float, velocity: Vector2, grounded: bool, facing: int, invulnerable: float) -> void:
	_time += delta
	_velocity = velocity
	_grounded = grounded
	_facing = facing
	if grounded and absf(velocity.x) > 20.0:
		_run_phase += delta * (8.0 + absf(velocity.x) / 25.0)
	_squash = _squash.lerp(Vector2.ONE, clampf(12.0 * delta, 0.0, 1.0))
	scale = Vector2(float(_facing) * _squash.x, _squash.y)
	# Flicker while respawn-protected
	if invulnerable > 0.0 and int(_time * 16.0) % 2 == 0:
		modulate.a = 0.4
	else:
		modulate.a = 1.0
	queue_redraw()


func on_jump() -> void:
	_squash = Vector2(0.78, 1.25)


func on_land(strength: float) -> void:
	_squash = Vector2(1.0 + 0.3 * strength, 1.0 - 0.3 * strength)


func _draw() -> void:
	# Soft magical aura
	draw_circle(Vector2(0.0, -20.0), 30.0, Color(0.4, 0.95, 0.9, 0.05))
	draw_circle(Vector2(0.0, -20.0), 22.0, Color(0.4, 0.95, 0.9, 0.06))
	draw_circle(Vector2(0.0, -20.0), 14.0, Color(0.4, 0.95, 0.9, 0.07))
	_outline_pass = true
	_draw_body()
	_outline_pass = false
	_draw_body()


func _px(x: float, y: float, w: float, h: float, color: Color) -> void:
	if _outline_pass:
		draw_rect(Rect2((x - 1.0) * U, (y - 1.0) * U, (w + 2.0) * U, (h + 2.0) * U), OUTLINE)
	else:
		draw_rect(Rect2(x * U, y * U, w * U, h * U), color)


func _draw_body() -> void:
	var moving := _grounded and absf(_velocity.x) > 20.0
	var swing := sin(_run_phase)
	var bob := 0.0
	if _grounded and not moving:
		bob = roundf(sin(_time * 3.0) * 0.6)

	# Legs
	var leg_a_x := -3.0
	var leg_b_x := 1.0
	var leg_a_h := 4.0
	var leg_b_h := 4.0
	if not _grounded:
		if _velocity.y < 0.0:
			leg_a_h = 3.0
			leg_b_h = 3.0
			leg_b_x += 1.0
		else:
			leg_a_x -= 1.0
			leg_b_x += 1.0
	elif moving:
		leg_a_x += roundf(swing * 2.0)
		leg_b_x -= roundf(swing * 2.0)
		leg_a_h = 4.0 - roundf(maxf(0.0, -swing) * 2.0)
		leg_b_h = 4.0 - roundf(maxf(0.0, swing) * 2.0)
	_px(leg_a_x, -leg_a_h, 3.0, leg_a_h, BOOT)
	_px(leg_b_x, -leg_b_h, 3.0, leg_b_h, BOOT)

	# Cape trailing behind (streams out when fast, lifts when jumping)
	var stream := clampf(absf(_velocity.x) / 250.0, 0.0, 1.0)
	var lift := clampf(-_velocity.y / 300.0, -1.0, 1.0)
	for i in 4:
		var fi := float(i)
		var cx := -5.0 - fi * 1.5 - stream * fi * 1.2
		var cy := -13.0 + fi * 2.2 - lift * fi * 1.5 + roundf(sin(_time * 9.0 + fi) * 0.6 * stream)
		_px(roundf(cx), roundf(cy) + bob, 3.0, 4.0, CLOAK_DARK)

	# Lyre on the back
	_px(-8.0, -14.0 + bob, 1.0, 7.0, GOLD)
	_px(-6.0, -14.0 + bob, 1.0, 7.0, GOLD)
	_px(-8.0, -14.0 + bob, 3.0, 1.0, GOLD)
	_px(-7.0, -12.0 + bob, 1.0, 4.0, GLOW)

	# Robe
	_px(-4.0, -14.0 + bob, 8.0, 4.0, CLOAK)
	_px(-5.0, -10.0 + bob, 10.0, 4.0, CLOAK)
	_px(-5.0, -6.0 + bob, 10.0, 3.0, CLOAK_DARK)
	_px(-5.0, -4.0, 10.0, 1.0, GOLD)
	_px(-4.0, -9.0 + bob, 8.0, 1.0, GOLD)
	_px(-2.0, -13.0 + bob, 1.0, 3.0, CLOAK_LIGHT)

	# Front arm swings while running
	var arm_y := -12.0 + bob
	if moving:
		arm_y += roundf(swing * 1.5)
	_px(2.0, arm_y, 2.0, 5.0, CLOAK_LIGHT)
	_px(2.0, arm_y + 5.0, 2.0, 2.0, SKIN)

	# Head: hood, face, glowing eye, gold circlet
	_px(-4.0, -21.0 + bob, 8.0, 7.0, HOOD)
	_px(-3.0, -22.0 + bob, 5.0, 1.0, HOOD)
	_px(-5.0, -19.0 + bob, 1.0, 4.0, HOOD)
	_px(0.0, -19.0 + bob, 4.0, 4.0, SKIN)
	_px(-4.0, -16.0 + bob, 8.0, 1.0, GOLD_DARK)
	if int(_time * 0.7) % 5 != 0 or fmod(_time, 1.0) > 0.12:
		_px(2.0, -18.0 + bob, 1.0, 2.0, GLOW)
