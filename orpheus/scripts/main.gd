extends Node
## Entry point. The level is already running behind the title screen;
## pressing PLAY hands control to the player and starts the music.

@onready var title_screen = $TitleScreen


func _ready() -> void:
	title_screen.play_pressed.connect(_start_game)
	if GameState.skip_title:
		# Restarted from the pause menu or the victory screen: go straight in.
		GameState.skip_title = false
		title_screen.hide_immediately()
		_start_game()
	else:
		GameState.set_state(GameState.State.TITLE)


func _start_game() -> void:
	GameState.set_state(GameState.State.PLAYING)
	AudioManager.start_music()
