extends CanvasLayer
## Title screen shown over the live level. Press PLAY (or Enter/Space) to start.

signal play_pressed

const UiStyle = preload("res://scripts/ui/ui_style.gd")

@onready var root: Control = $Root
@onready var title_label: Label = $Root/Center/Box/TitleLabel
@onready var subtitle_label: Label = $Root/Center/Box/SubtitleLabel
@onready var tagline_label: Label = $Root/Center/Box/TaglineLabel
@onready var play_button: Button = $Root/Center/Box/PlayButton
@onready var controls_label: Label = $Root/Center/Box/ControlsLabel
@onready var credit_label: Label = $Root/Center/Box/CreditLabel

var _time := 0.0
var _starting := false


func _ready() -> void:
	root.theme = UiStyle.get_theme()
	UiStyle.style_title(title_label, 104, UiStyle.GOLD)
	UiStyle.style_title(subtitle_label, 36, UiStyle.TEAL)
	tagline_label.add_theme_font_size_override("font_size", 22)
	tagline_label.add_theme_color_override("font_color", Color("#cfc8ff"))
	controls_label.add_theme_font_size_override("font_size", 17)
	controls_label.add_theme_color_override("font_color", Color(0.85, 0.85, 1.0, 0.7))
	credit_label.add_theme_font_size_override("font_size", 16)
	credit_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.95, 0.6))
	play_button.pressed.connect(_on_play_pressed)
	play_button.grab_focus()


func _process(delta: float) -> void:
	_time += delta
	subtitle_label.modulate.a = 0.75 + 0.25 * sin(_time * 2.0)


func hide_immediately() -> void:
	_starting = true
	root.visible = false
	set_process(false)


func _on_play_pressed() -> void:
	if _starting:
		return
	_starting = true
	AudioManager.play("click")
	play_pressed.emit()
	var tween := create_tween()
	tween.tween_property(root, "modulate:a", 0.0, 0.4)
	tween.tween_callback(hide_immediately)
