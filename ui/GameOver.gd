extends Control

const FIRST_SCENE := "res://scenes/Stage 1.tscn"

@onready var retry_button: Button = get_node_or_null("CenterContainer/VBoxContainer/RetryButton") as Button


func _ready() -> void:
	if retry_button == null:
		push_error("GameOver screen is missing RetryButton.")
		return
	if not retry_button.pressed.is_connected(_on_retry_pressed):
		retry_button.pressed.connect(_on_retry_pressed)
	retry_button.grab_focus()


func _on_retry_pressed() -> void:
	GameManager.reset_run()
	get_tree().change_scene_to_file(FIRST_SCENE)
