extends Node
## Global game state (autoload "GameState").
## Holds the run's score, echoes, checkpoint and game state, and registers the
## input actions so the game works without any Input Map setup.

signal state_changed(new_state: int)
signal score_changed(new_score: int)
signal echoes_changed(collected: int, total: int)
signal checkpoint_reached(index: int, total: int)
signal player_died
signal level_completed
signal message_requested(text: String)

enum State { TITLE, PLAYING, PAUSED, WON }

const ECHO_POINTS := 100
const STOMP_POINTS := 50
const COMPLETION_BONUS := 500

var state: State = State.TITLE
var score: int = 0
var echoes: int = 0
var total_echoes: int = 0
var required_echoes: int = 6
var deaths: int = 0
var elapsed_time: float = 0.0
var checkpoint_position: Vector2 = Vector2.ZERO
var checkpoint_index: int = 0
var total_checkpoints: int = 0
## Set to true before reloading the scene to skip the title screen (replay).
var skip_title: bool = false


func _ready() -> void:
	_register_input_actions()


func _process(delta: float) -> void:
	if state == State.PLAYING:
		elapsed_time += delta


## Called by the level every time it loads. Resets the whole run.
func begin_level(spawn_position: Vector2, echo_total: int, checkpoint_total: int, echoes_needed: int) -> void:
	score = 0
	echoes = 0
	deaths = 0
	elapsed_time = 0.0
	total_echoes = echo_total
	required_echoes = echoes_needed
	total_checkpoints = checkpoint_total
	checkpoint_position = spawn_position
	checkpoint_index = 0
	state = State.TITLE
	score_changed.emit(score)
	echoes_changed.emit(echoes, total_echoes)


func set_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state
	state_changed.emit(state)


func can_control() -> bool:
	return state == State.PLAYING


func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)


func collect_echo() -> void:
	echoes += 1
	add_score(ECHO_POINTS)
	echoes_changed.emit(echoes, total_echoes)


func has_enough_echoes() -> bool:
	return echoes >= required_echoes


func set_checkpoint(position_in_world: Vector2, index: int) -> void:
	checkpoint_position = position_in_world
	checkpoint_index = index
	checkpoint_reached.emit(index, total_checkpoints)


func register_death() -> void:
	deaths += 1
	player_died.emit()


func show_message(text: String) -> void:
	message_requested.emit(text)


func complete_level() -> void:
	if state == State.WON:
		return
	add_score(COMPLETION_BONUS)
	set_state(State.WON)
	level_completed.emit()


func format_time() -> String:
	var total_seconds := int(elapsed_time)
	return "%d:%02d" % [total_seconds / 60, total_seconds % 60]


# ---------------------------------------------------------------- input
func _register_input_actions() -> void:
	_add_key_action(&"left", [KEY_A, KEY_LEFT])
	_add_key_action(&"right", [KEY_D, KEY_RIGHT])
	_add_key_action(&"jump", [KEY_SPACE, KEY_W, KEY_UP])
	_add_key_action(&"restart", [KEY_R])
	_add_key_action(&"pause", [KEY_ESCAPE, KEY_P])
	_add_key_action(&"mute", [KEY_M])
	# Gamepad support (optional extra)
	_add_joy_button(&"jump", JOY_BUTTON_A)
	_add_joy_button(&"left", JOY_BUTTON_DPAD_LEFT)
	_add_joy_button(&"right", JOY_BUTTON_DPAD_RIGHT)
	_add_joy_axis(&"left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis(&"right", JOY_AXIS_LEFT_X, 1.0)


func _ensure_action(action_name: StringName) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, 0.5)


func _add_key_action(action_name: StringName, keys: Array) -> void:
	_ensure_action(action_name)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action_name, event)


func _add_joy_button(action_name: StringName, button: JoyButton) -> void:
	_ensure_action(action_name)
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action_name, event)


func _add_joy_axis(action_name: StringName, axis: JoyAxis, value: float) -> void:
	_ensure_action(action_name)
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	InputMap.action_add_event(action_name, event)
