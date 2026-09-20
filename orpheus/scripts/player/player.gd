extends CharacterBody2D
## Orpheus, the player. Movement is tuned for a responsive, forgiving feel:
## quick acceleration, variable jump height, coyote time and jump buffering.

const Effects = preload("res://scripts/effects/effects.gd")

signal jumped
signal landed(fall_speed: float)
signal died

# --- movement (the level layout was tested against these exact numbers)
const MAX_SPEED := 250.0
const GROUND_ACCEL := 2400.0
const GROUND_FRICTION := 2800.0
const AIR_ACCEL := 1600.0
const AIR_FRICTION := 500.0
const GRAVITY := 1700.0
const FALL_GRAVITY_MULTIPLIER := 1.4   # falling is a little heavier than rising
const MAX_FALL_SPEED := 900.0
const JUMP_VELOCITY := -650.0
const JUMP_CUT_MULTIPLIER := 0.45      # releasing jump early makes a shorter hop
const COYOTE_TIME := 0.10              # can still jump just after leaving a ledge
const JUMP_BUFFER_TIME := 0.12         # a jump pressed just before landing still counts
const STOMP_BOUNCE := -480.0

# --- life cycle
const RESPAWN_DELAY := 0.8
const INVULNERABLE_TIME := 1.2
const HALF_HEIGHT := 19.0

enum Mode { ALIVE, DEAD, FROZEN }

var mode: Mode = Mode.ALIVE
var facing: int = 1
## The player is respawned when they fall below this y position.
var death_y: float = 4000.0

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _was_on_floor := false
var _respawn_timer := 0.0
var _invulnerable_timer := 0.0
var _shake := 0.0
var _look_ahead := 0.0

@onready var camera: Camera2D = $Camera2D
@onready var visual = $Visual
@onready var body_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0


func _process(delta: float) -> void:
	var target_look := 0.0
	if mode == Mode.ALIVE:
		target_look = float(facing) * 70.0 * clampf(absf(velocity.x) / MAX_SPEED, 0.0, 1.0)
	_look_ahead = lerpf(_look_ahead, target_look, clampf(3.0 * delta, 0.0, 1.0))
	var shake_offset := Vector2.ZERO
	if _shake > 0.1:
		shake_offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
		_shake = lerpf(_shake, 0.0, clampf(10.0 * delta, 0.0, 1.0))
	camera.offset = Vector2(_look_ahead, 0.0) + shake_offset


func _physics_process(delta: float) -> void:
	if _invulnerable_timer > 0.0:
		_invulnerable_timer -= delta

	if mode == Mode.DEAD:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			respawn()
		return
	if mode == Mode.FROZEN:
		return

	var controllable := GameState.can_control()
	var direction := 0.0
	var jump_pressed := false
	var jump_released := false
	if controllable:
		direction = Input.get_axis("left", "right")
		jump_pressed = Input.is_action_just_pressed("jump")
		jump_released = Input.is_action_just_released("jump")
		if Input.is_action_just_pressed("restart"):
			respawn()
			return

	# Gravity (heavier on the way down)
	if not is_on_floor():
		var pull := GRAVITY
		if velocity.y > 0.0:
			pull *= FALL_GRAVITY_MULTIPLIER
		velocity.y = minf(velocity.y + pull * delta, MAX_FALL_SPEED)

	# Coyote time + jump buffering
	if is_on_floor():
		_coyote_timer = COYOTE_TIME
	else:
		_coyote_timer -= delta
	if jump_pressed:
		_jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		_jump_buffer_timer -= delta
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		_on_jump()
	if jump_released and velocity.y < 0.0:
		velocity.y *= JUMP_CUT_MULTIPLIER

	# Horizontal movement
	var on_floor := is_on_floor()
	var accel := 0.0
	if direction != 0.0:
		accel = GROUND_ACCEL if on_floor else AIR_ACCEL
		facing = 1 if direction > 0.0 else -1
	else:
		accel = GROUND_FRICTION if on_floor else AIR_FRICTION
	velocity.x = move_toward(velocity.x, direction * MAX_SPEED, accel * delta)

	var fall_speed := velocity.y
	move_and_slide()

	var on_floor_now := is_on_floor()
	if on_floor_now and not _was_on_floor:
		_on_landed(fall_speed)
	_was_on_floor = on_floor_now

	if global_position.y > death_y:
		_die()
		return

	visual.update_state(delta, velocity, on_floor_now, facing, _invulnerable_timer)


# ---------------------------------------------------------------- public API
func is_alive() -> bool:
	return mode == Mode.ALIVE


## Called by hazards. Ignored while respawn-protected.
func hurt() -> void:
	if mode != Mode.ALIVE or _invulnerable_timer > 0.0:
		return
	if not GameState.can_control():
		return
	_die()


## Bounce upwards, e.g. after landing on an enemy.
func bounce() -> void:
	velocity.y = STOMP_BOUNCE
	_coyote_timer = 0.0
	visual.on_jump()


func respawn() -> void:
	global_position = GameState.checkpoint_position
	velocity = Vector2.ZERO
	mode = Mode.ALIVE
	body_shape.set_deferred("disabled", false)
	visual.visible = true
	_invulnerable_timer = INVULNERABLE_TIME
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	_was_on_floor = false
	camera.force_update_scroll()
	camera.reset_smoothing()
	AudioManager.play("respawn")
	Effects.burst(get_tree(), global_position, Color(0.5, 1.0, 0.9), 18, 160.0, 0.6, 0.0)
	Effects.ring(get_tree(), global_position, Color(0.5, 1.0, 0.9, 0.9), 50.0, 0.45)


## Called by the portal: pulls Orpheus in and then ends the level.
func enter_portal(center: Vector2) -> void:
	if mode == Mode.FROZEN:
		return
	mode = Mode.FROZEN
	velocity = Vector2.ZERO
	body_shape.set_deferred("disabled", true)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", center, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(visual, "scale", Vector2(0.05, 0.05), 0.9).set_delay(0.2)
	tween.chain().tween_callback(_finish_portal)


func set_camera_limits(left: int, top: int, right: int, bottom: int) -> void:
	camera.limit_left = left
	camera.limit_top = top
	camera.limit_right = right
	camera.limit_bottom = bottom


func snap_camera() -> void:
	camera.force_update_scroll()
	camera.reset_smoothing()


func add_shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


# ---------------------------------------------------------------- internals
func _finish_portal() -> void:
	visual.visible = false
	GameState.complete_level()


func _die() -> void:
	mode = Mode.DEAD
	velocity = Vector2.ZERO
	_respawn_timer = RESPAWN_DELAY
	body_shape.set_deferred("disabled", true)
	visual.visible = false
	GameState.register_death()
	AudioManager.play("hurt")
	Effects.burst(get_tree(), global_position, Color(1.0, 0.45, 0.75), 26, 260.0, 0.8)
	Effects.burst(get_tree(), global_position, Color(0.55, 0.95, 1.0), 14, 180.0, 0.7)
	add_shake(12.0)
	died.emit()


func _on_jump() -> void:
	AudioManager.play("jump", randf_range(0.96, 1.08))
	visual.on_jump()
	Effects.burst(get_tree(), global_position + Vector2(0.0, HALF_HEIGHT), Color(0.75, 0.7, 1.0, 0.8), 5, 70.0, 0.3, 80.0)
	jumped.emit()


func _on_landed(fall_speed: float) -> void:
	if fall_speed > 260.0:
		AudioManager.play("land", 1.0, -4.0)
		visual.on_land(clampf(fall_speed / 700.0, 0.2, 1.0))
		Effects.burst(get_tree(), global_position + Vector2(0.0, HALF_HEIGHT), Color(0.75, 0.7, 1.0, 0.8), 6, 90.0, 0.35, 120.0)
	landed.emit(fall_speed)
