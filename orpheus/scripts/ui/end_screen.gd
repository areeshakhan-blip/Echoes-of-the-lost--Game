extends CanvasLayer
## Victory screen shown when the player steps through the portal.

const UiStyle = preload("res://scripts/ui/ui_style.gd")
const PixelArt = preload("res://scripts/systems/pixel_art.gd")

@onready var root: Control = $Root
@onready var title_label: Label = $Root/Center/Box/TitleLabel
@onready var rank_label: Label = $Root/Center/Box/RankLabel
@onready var score_label: Label = $Root/Center/Box/ScoreLabel
@onready var echoes_label: Label = $Root/Center/Box/EchoesLabel
@onready var time_label: Label = $Root/Center/Box/TimeLabel
@onready var deaths_label: Label = $Root/Center/Box/DeathsLabel
@onready var replay_button: Button = $Root/Center/Box/ReplayButton
@onready var hint_label: Label = $Root/Center/Box/HintLabel

var _showing := false
## Input is ignored briefly so a jump press right before the portal can't skip the results.
var _input_lock := 0.0


func _ready() -> void:
	root.theme = UiStyle.get_theme()
	UiStyle.style_title(title_label, 52, UiStyle.GOLD)
	UiStyle.style_title(rank_label, 28, UiStyle.VIOLET)
	for label in [score_label, echoes_label, time_label, deaths_label]:
		label.add_theme_font_size_override("font_size", 30)
	score_label.add_theme_color_override("font_color", UiStyle.GOLD)
	echoes_label.add_theme_color_override("font_color", UiStyle.TEAL)
	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.add_theme_color_override("font_color", Color(0.85, 0.85, 1.0, 0.6))
	replay_button.pressed.connect(replay)
	GameState.level_completed.connect(show_results)
	_add_falling_lights()


func _process(delta: float) -> void:
	if not _showing or _input_lock <= 0.0:
		return
	_input_lock -= delta
	if _input_lock <= 0.0:
		replay_button.disabled = false
		replay_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not _showing or _input_lock > 0.0:
		return
	if event.is_action_pressed("restart") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		replay()


func show_results() -> void:
	_showing = true
	score_label.text = "FINAL SCORE: %04d" % GameState.score
	echoes_label.text = "ECHOES COLLECTED: %d/%d" % [GameState.echoes, GameState.total_echoes]
	time_label.text = "TIME: %s" % GameState.format_time()
	deaths_label.text = "FALLS AND HITS: %d" % GameState.deaths
	rank_label.text = _rank_text()
	AudioManager.play("win")
	root.visible = true
	_input_lock = 1.0
	replay_button.disabled = true
	root.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(root, "modulate:a", 1.0, 0.8)


func replay() -> void:
	if not _showing:
		return
	_showing = false
	AudioManager.play("click")
	GameState.skip_title = true
	get_tree().paused = false
	get_tree().reload_current_scene()


func _rank_text() -> String:
	if GameState.echoes >= GameState.total_echoes:
		return "PERFECT RESONANCE - EVERY ECHO FOUND"
	if GameState.echoes >= GameState.total_echoes - 2:
		return "BRILLIANT ECHO"
	return "FAINT ECHO - SOME REMAIN HIDDEN"


func _add_falling_lights() -> void:
	var lights := CPUParticles2D.new()
	lights.position = Vector2(640.0, -20.0)
	lights.amount = 60
	lights.lifetime = 7.0
	lights.preprocess = 7.0
	lights.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	lights.emission_rect_extents = Vector2(660.0, 10.0)
	lights.direction = Vector2(0.0, 1.0)
	lights.spread = 12.0
	lights.gravity = Vector2.ZERO
	lights.initial_velocity_min = 40.0
	lights.initial_velocity_max = 90.0
	lights.scale_amount_min = 2.0
	lights.scale_amount_max = 5.0
	lights.color = Color(1.0, 0.85, 0.4, 0.7)
	lights.material = PixelArt.additive_material()
	root.add_child(lights)
