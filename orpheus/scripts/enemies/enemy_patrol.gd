extends Area2D
## Shade Crawler: a small shadow creature that patrols a platform.
## Touching it hurts; landing on its head defeats it (and bounces you).
## Origin is at its feet.

const Effects = preload("res://scripts/effects/effects.gd")

const SPEED := 55.0
const PLAYER_HALF_HEIGHT := 19.0

## Patrol limits (world x). Set by the level from the platform's shape.
var patrol_min_x := 0.0
var patrol_max_x := 0.0
var direction := 1

var _time := 0.0
var _alive := true


func _ready() -> void:
	if patrol_max_x <= patrol_min_x:
		patrol_min_x = position.x - 64.0
		patrol_max_x = position.x + 64.0
	position.x = clampf(position.x, patrol_min_x, patrol_max_x)
	_time = randf() * 10.0


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_time += delta
	position.x += float(direction) * SPEED * delta
	if position.x >= patrol_max_x:
		position.x = patrol_max_x
		direction = -1
	elif position.x <= patrol_min_x:
		position.x = patrol_min_x
		direction = 1
	_check_player()
	queue_redraw()


func _check_player() -> void:
	for body in get_overlapping_bodies():
		var player = body
		if not player.is_in_group("player") or not player.is_alive():
			continue
		var feet_y: float = player.global_position.y + PLAYER_HALF_HEIGHT
		if player.velocity.y > 0.0 and feet_y < global_position.y - 4.0:
			_defeat(player)
		else:
			player.hurt()
		return


func _defeat(player) -> void:
	_alive = false
	set_deferred("monitoring", false)
	player.bounce()
	GameState.add_score(GameState.STOMP_POINTS)
	AudioManager.play("stomp")
	Effects.burst(get_tree(), global_position + Vector2(0.0, -10.0), Color(1.0, 0.4, 0.75), 18, 200.0, 0.6)
	Effects.text(get_tree(), global_position + Vector2(0.0, -30.0), "+%d" % GameState.STOMP_POINTS, Color("#ffd35a"))
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 0.1), 0.15)
	tween.tween_callback(queue_free)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(float(direction), 1.0))
	var outline := Color("#0d0620")
	var body := Color("#2a1650")
	var body_light := Color("#43257f")
	var eye := Color("#ff5fa2")
	var squash := sin(_time * 8.0) * 1.0
	# Legs (four tiny stubs that take turns)
	for i in 4:
		var lx := -10.0 + float(i) * 6.5
		var lift := maxf(0.0, sin(_time * 10.0 + float(i) * 1.6)) * 3.0
		draw_rect(Rect2(lx - 1.0, -5.0 - lift, 4.0, 5.0 + lift), outline)
		draw_rect(Rect2(lx, -4.0 - lift, 2.0, 4.0 + lift), body)
	# Body dome, built from stacked pixel rows
	var rows := [[-9.0, 9.0, -6.0], [-12.0, 12.0, -12.0], [-13.0, 13.0, -18.0], [-10.0, 10.0, -22.0]]
	for r in rows:
		var x0: float = r[0]
		var x1: float = r[1]
		var y: float = r[2] - squash
		draw_rect(Rect2(x0 - 2.0, y - 2.0, x1 - x0 + 4.0, 8.0), outline)
	for r in rows:
		var x0: float = r[0]
		var x1: float = r[1]
		var y: float = r[2] - squash
		draw_rect(Rect2(x0, y, x1 - x0, 6.0), body)
	draw_rect(Rect2(-8.0, -22.0 - squash, 10.0, 3.0), body_light)
	# Little horns
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -22.0 - squash), Vector2(-11, -30.0 - squash), Vector2(-4, -22.0 - squash)]), outline)
	draw_colored_polygon(PackedVector2Array([Vector2(4, -22.0 - squash), Vector2(9, -30.0 - squash), Vector2(10, -22.0 - squash)]), outline)
	# Glowing eyes
	draw_circle(Vector2(3.0, -14.0 - squash), 6.0, Color(eye.r, eye.g, eye.b, 0.18))
	draw_circle(Vector2(9.0, -14.0 - squash), 5.0, Color(eye.r, eye.g, eye.b, 0.18))
	draw_rect(Rect2(2.0, -17.0 - squash, 3.0, 5.0), eye)
	draw_rect(Rect2(8.0, -17.0 - squash, 3.0, 5.0), eye)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
