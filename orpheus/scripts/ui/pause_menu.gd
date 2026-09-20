extends CanvasLayer
## Pause menu. Toggled with ESC or P while playing. Runs even when the game is paused.

const UiStyle = preload("res://scripts/ui/ui_style.gd")

@onready var root: Control = $Root
@onready var paused_label: Label = $Root/Center/Box/PausedLabel
@onready var resume_button: Button = $Root/Center/Box/ResumeButton
@onready var restart_button: Button = $Root/Center/Box/RestartButton
@onready var music_button: Button = $Root/Center/Box/MusicButton


func _ready() -> void:
	root.theme = UiStyle.get_theme()
	UiStyle.style_title(paused_label, 64, UiStyle.GOLD)
	resume_button.pressed.connect(resume)
	restart_button.pressed.connect(_on_restart_pressed)
	music_button.pressed.connect(_on_music_pressed)
	_update_music_text()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if GameState.state == GameState.State.PLAYING:
		pause()
	elif GameState.state == GameState.State.PAUSED:
		resume()
	get_viewport().set_input_as_handled()


func pause() -> void:
	get_tree().paused = true
	GameState.set_state(GameState.State.PAUSED)
	root.visible = true
	_update_music_text()
	resume_button.grab_focus()


func resume() -> void:
	AudioManager.play("click")
	get_tree().paused = false
	GameState.set_state(GameState.State.PLAYING)
	root.visible = false


func _on_restart_pressed() -> void:
	AudioManager.play("click")
	get_tree().paused = false
	GameState.skip_title = true
	get_tree().reload_current_scene()


func _on_music_pressed() -> void:
	AudioManager.play("click")
	AudioManager.set_music_muted(not AudioManager.music_muted)
	_update_music_text()


func _update_music_text() -> void:
	music_button.text = "MUSIC: OFF" if AudioManager.music_muted else "MUSIC: ON"
