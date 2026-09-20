extends Area2D
## The end portal: an ancient stone doorway. It is dormant until the player has
## collected enough Echo Shards, then it blazes with light. Origin is at the
## bottom centre of the doorway.

const Effects = preload("res://scripts/effects/effects.gd")
const PixelArt = preload("res://scripts/systems/pixel_art.gd")

var _energy := 0.2
var _time := 0.0
var _entered := false
var _was_open := false
var _glow: Sprite2D
var _motes: CPUParticles2D
var _rune_seed := []


func _ready() -> void:
	_glow = PixelArt.make_glow(Color(0.7, 0.45, 1.0, 0.0), 180.0)
	_glow.position = Vector2(0.0, -95.0)
	add_child(_glow)

	_motes = CPUParticles2D.new()
	_motes.position = Vector2(0.0, -20.0)
	_motes.amount = 24
	_motes.lifetime = 2.2
	_motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_motes.emission_rect_extents = Vector2(34.0, 4.0)
	_motes.direction = Vector2(0.0, -1.0)
	_motes.spread = 12.0
	_motes.gravity = Vector2.ZERO
	_motes.initial_velocity_min = 30.0
	_motes.initial_velocity_max = 70.0
	_motes.scale_amount_min = 2.0
	_motes.scale_amount_max = 3.0
	_motes.color = Color(0.85, 0.7, 1.0, 0.8)
	_motes.material = PixelArt.additive_material()
	_motes.emitting = false
	add_child(_motes)

	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in 14:
		_rune_seed.append(rng.randi())

	body_entered.connect(_on_body_entered)
	_energy = _energy_target()


func _process(delta: float) -> void:
	_time += delta
	var target := _energy_target()
	_energy = move_toward(_energy, target, delta * 1.2)
	var open := GameState.has_enough_echoes()
	_glow.modulate.a = _energy * (0.6 + 0.12 * sin(_time * 2.5))
	_motes.emitting = open
	if open and not _was_open:
		_was_open = true
		AudioManager.play("portal", 1.2)
		Effects.ring(get_tree(), global_position + Vector2(0.0, -95.0), Color(0.8, 0.6, 1.0, 0.9), 110.0, 0.8)
		Effects.text(get_tree(), global_position + Vector2(0.0, -215.0), "THE PORTAL IS OPEN", Color("#c9a8ff"))
	queue_redraw()


func _energy_target() -> float:
	if GameState.has_enough_echoes():
		return 1.0
	var progress := float(GameState.echoes) / float(maxi(GameState.required_echoes, 1))
	return 0.2 + 0.4 * clampf(progress, 0.0, 1.0)


func _draw() -> void:
	var stone := Color("#4b5679")
	var stone_light := Color("#6a789f")
	var stone_dark := Color("#33405f")
	var outline := Color("#141a30")
	var open := GameState.has_enough_echoes()

	# --- a faint pillar of light so the goal can be spotted from far away
	var beam_alpha := 0.04 + 0.10 * _energy
	for i in 3:
		var inset := float(i) * 10.0
		draw_rect(Rect2(-34.0 + inset, -1000.0, 68.0 - inset * 2.0, 940.0), Color(0.75, 0.55, 1.0, beam_alpha * (0.5 + float(i) * 0.3)))

	# --- the swirling doorway (drawn first, behind the frame)
	var center := Vector2(0.0, -95.0)
	var base := Color(0.16, 0.1, 0.3).lerp(Color(0.45, 0.25, 0.85), _energy)
	draw_rect(Rect2(-40, -150, 80, 150), base)
	draw_circle(Vector2(0.0, -150.0), 40.0, base)
	for i in 5:
		var fi := float(i)
		var shrink := 1.0 - fi * 0.17
		var layer := base.lerp(Color(0.85, 0.6, 1.0), fi * 0.16 * _energy)
		layer.a = 0.55
		draw_rect(Rect2(-40.0 * shrink, -150.0 * shrink - 6.0, 80.0 * shrink, 150.0 * shrink + 6.0), layer)
		draw_circle(Vector2(0.0, -150.0 * shrink - 6.0), 40.0 * shrink, layer)
	# Rotating swirl arms
	for i in 4:
		var radius := 12.0 + float(i) * 7.0
		var spin := _time * (1.4 + float(i) * 0.5) * (1.0 if i % 2 == 0 else -1.0)
		var arm := Color(0.95, 0.85, 1.0, 0.15 + 0.5 * _energy)
		draw_arc(center, radius, spin, spin + PI * 0.9, 20, arm, 3.0)
	# Bright core
	draw_circle(center, 7.0 + 3.0 * sin(_time * 3.0), Color(1.0, 0.95, 1.0, 0.25 + 0.6 * _energy))

	# --- stone frame: two pillars and an arch
	draw_rect(Rect2(-68, -152, 28, 152), outline)
	draw_rect(Rect2(40, -152, 28, 152), outline)
	draw_rect(Rect2(-66, -150, 24, 150), stone)
	draw_rect(Rect2(42, -150, 24, 150), stone)
	draw_rect(Rect2(-66, -150, 7, 150), stone_light)
	draw_rect(Rect2(42, -150, 7, 150), stone_light)
	for i in 6:
		var y := -22.0 - float(i) * 24.0
		draw_rect(Rect2(-66, y, 24, 2), stone_dark)
		draw_rect(Rect2(42, y, 24, 2), stone_dark)
	draw_arc(Vector2(0.0, -150.0), 52.0, PI, TAU, 40, outline, 30.0)
	draw_arc(Vector2(0.0, -150.0), 52.0, PI, TAU, 40, stone, 24.0)
	draw_arc(Vector2(0.0, -150.0), 58.0, PI, TAU, 40, stone_light, 6.0)
	# Keystone
	draw_rect(Rect2(-12, -212, 24, 24), outline)
	draw_rect(Rect2(-10, -210, 20, 20), stone_light)
	# Bases
	draw_rect(Rect2(-76, -14, 44, 14), outline)
	draw_rect(Rect2(32, -14, 44, 14), outline)
	draw_rect(Rect2(-74, -12, 40, 12), stone_dark)
	draw_rect(Rect2(34, -12, 40, 12), stone_dark)

	# --- ancient runes on the pillars: dim when dormant, glowing when open
	var rune := Color("#2a3556").lerp(Color("#7df9e6"), clampf(_energy * 1.2 - 0.2, 0.0, 1.0))
	for i in 7:
		var s: int = _rune_seed[i]
		var y := -30.0 - float(i) * 17.0
		var glyph := s % 3
		for side in [-54.0, 54.0]:
			var x: float = side
			draw_line(Vector2(x, y), Vector2(x, y + 9.0), rune, 2.0)
			if glyph == 0:
				draw_line(Vector2(x, y + 2.0), Vector2(x + 5.0, y), rune, 2.0)
			elif glyph == 1:
				draw_line(Vector2(x - 4.0, y + 4.0), Vector2(x + 4.0, y + 4.0), rune, 2.0)
			else:
				draw_line(Vector2(x, y + 9.0), Vector2(x - 5.0, y + 5.0), rune, 2.0)
	# Sparkles orbiting the doorway once open
	if open:
		for i in 8:
			var a := _time * 0.9 + float(i) * TAU / 8.0
			var p := center + Vector2(cos(a) * 46.0, sin(a) * 92.0)
			draw_rect(Rect2(p.x - 1.5, p.y - 1.5, 3.0, 3.0), Color(0.9, 0.8, 1.0, 0.8))


func _on_body_entered(body) -> void:
	if _entered or not body.is_in_group("player") or not GameState.can_control():
		return
	if GameState.has_enough_echoes():
		_entered = true
		AudioManager.play("portal", 0.8)
		Effects.ring(get_tree(), global_position + Vector2(0.0, -95.0), Color(0.9, 0.8, 1.0, 0.9), 120.0, 0.7)
		body.enter_portal(global_position + Vector2(0.0, -80.0))
	else:
		var missing := GameState.required_echoes - GameState.echoes
		AudioManager.play("locked")
		GameState.show_message("The portal needs %d more Echo%s..." % [missing, "" if missing == 1 else "es"])
