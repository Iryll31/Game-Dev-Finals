extends CanvasLayer

@onready var pause_menu: Control = %PauseMenu

var is_paused := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu.resume_requested.connect(_resume_game)
	pause_menu.restart_requested.connect(_restart_floor)
	pause_menu.quit_requested.connect(_quit_game)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_pause"):
		if is_paused:
			_resume_game()
		else:
			_pause_game()
		get_viewport().set_input_as_handled()

func _pause_game() -> void:
	is_paused = true
	get_tree().paused = true
	pause_menu.open()

func _resume_game() -> void:
	is_paused = false
	get_tree().paused = false
	pause_menu.close()

func _restart_floor() -> void:
	get_tree().paused = false
	GameManager.health = GameManager.MAX_HEALTH
	GameManager.health_changed.emit(GameManager.health, GameManager.MAX_HEALTH)
	get_tree().reload_current_scene()

func _quit_game() -> void:
	get_tree().paused = false
	get_tree().quit()
