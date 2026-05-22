extends Control

@onready var retry_button: Button = %RetryButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	retry_button.pressed.connect(_retry)
	quit_button.pressed.connect(get_tree().quit)
	retry_button.grab_focus()

func _retry() -> void:
	GameManager.reset_run()
	get_tree().change_scene_to_file(GameManager.FLOOR_SCENES[0])
