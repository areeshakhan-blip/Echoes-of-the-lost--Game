extends CanvasLayer
## In-game HUD: ECHOES top-left, SCORE top-right, checkpoint progress top-centre,
## plus a message line, a damage flash and a soft vignette.

const PixelArt = preload("res://scripts/systems/pixel_art.gd")
const UiStyle = preload("res://scripts/ui/ui_style.gd")

@onready var root: Control = $Root
@onready var vignette: TextureRect = $Root/Vignette
@onready var flash: ColorRect = $Root/Flash
@onready var echo_panel: PanelContainer = $Root/EchoPanel
@onready var echo_label: Label = $Root/EchoPanel/EchoLabel
@onready var score_panel: PanelContainer = $Root/ScorePanel
@onready var score_label: Label = $Root/ScorePanel/ScoreLabel
@onready var checkpoint_panel: PanelContainer = $Root/CheckpointPanel
@onready var checkpoint_label: Label = $Root/CheckpointPanel/CheckpointLabel
@onready var message_label: Label = $Root/MessageLabel
@onready var hint_label: Label = $Root/HintLabel

var _message_tween: Tween
var _score_tween: Tween


func _ready() -> void:
	root.theme = UiStyle.get_theme()

	vignette.texture = PixelArt.get_vignette_texture()
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	UiStyle.style_title(echo_label, 26, UiStyle.TEAL)
	UiStyle.style_title(score_label, 26, UiStyle.GOLD)
	echo_label.add_theme_constant_override("outline_size", 4)
	score_label.add_theme_constant_override("outline_size", 4)
	checkpoint_label.add_theme_font_size_override("font_size", 18)
	checkpoint_label.add_theme_color_override("font_color", UiStyle.VIOLET)

	echo_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 18)
	score_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	score_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 18)
	checkpoint_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	checkpoint_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 18)

	UiStyle.style_title(message_label, 34, UiStyle.TEXT)
	message_label.anchor_right = 1.0
	message_label.offset_top = 96.0
	message_label.offset_bottom = 150.0
	message_label.modulate.a = 0.0

	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.add_theme_color_override("font_color", Color(0.85, 0.85, 1.0, 0.55))
	hint_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 16)

	GameState.echoes_changed.connect(_on_echoes_changed)
	GameState.score_changed.connect(_on_score_changed)
	GameState.checkpoint_reached.connect(_on_checkpoint_reached)
	GameState.player_died.connect(_on_player_died)
	GameState.state_changed.connect(_on_state_changed)
	GameState.message_requested.connect(show_message)

	_on_echoes_changed(GameState.echoes, GameState.total_echoes)
	_on_score_changed(GameState.score)
	_on_checkpoint_reached(GameState.checkpoint_index, GameState.total_checkpoints)
	_on_state_changed(GameState.state)


func show_message(text: String) -> void:
	message_label.text = text
	message_label.modulate.a = 1.0
	if _message_tween:
		_message_tween.kill()
	_message_tween = create_tween()
	_message_tween.tween_property(message_label, "modulate:a", 0.0, 0.6).set_delay(1.6)


func _on_echoes_changed(collected: int, total: int) -> void:
	echo_label.text = "ECHOES: %d/%d" % [collected, total]


func _on_score_changed(new_score: int) -> void:
	score_label.text = "SCORE: %04d" % new_score
	score_panel.pivot_offset = score_panel.size * 0.5
	if _score_tween:
		_score_tween.kill()
	_score_tween = create_tween()
	score_panel.scale = Vector2(1.12, 1.12)
	_score_tween.tween_property(score_panel, "scale", Vector2.ONE, 0.2)


func _on_checkpoint_reached(index: int, total: int) -> void:
	checkpoint_label.text = "CHECKPOINT: %d/%d" % [index, total]


func _on_player_died() -> void:
	flash.color = Color(1.0, 0.3, 0.5, 0.45)
	var tween := create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.5)


func _on_state_changed(new_state: int) -> void:
	# The HUD is only shown while actually playing
	root.visible = new_state == GameState.State.PLAYING or new_state == GameState.State.PAUSED
