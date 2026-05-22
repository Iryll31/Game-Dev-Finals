extends Label


func _ready() -> void:
	GameManager.key_progress_changed.connect(_on_key_progress_changed)
	_update_text()


func _exit_tree() -> void:
	if GameManager.key_progress_changed.is_connected(_on_key_progress_changed):
		GameManager.key_progress_changed.disconnect(_on_key_progress_changed)


func _on_key_progress_changed(_collected: int, _total: int) -> void:
	_update_text()


func _update_text() -> void:
	text = "%d/1" % GameManager.get_key_progress()
