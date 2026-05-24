extends Label


func _ready() -> void:
	z_index = 2
	GameManager.key_progress_changed.connect(_on_key_progress_changed)
	call_deferred("_update_text")


func _exit_tree() -> void:
	if GameManager.key_progress_changed.is_connected(_on_key_progress_changed):
		GameManager.key_progress_changed.disconnect(_on_key_progress_changed)


func _on_key_progress_changed(_collected: int, _total: int) -> void:
	_update_text()


func _update_text() -> void:
	var scene_path := _get_key_display_scene_path()
	var total := GameManager.get_key_total_for_scene(scene_path)
	visible = total > 0
	if not visible:
		text = ""
		return
	text = "%d/%d" % [
		GameManager.get_key_count_for_scene(scene_path),
		total,
	]


func _get_key_display_scene_path() -> String:
	if get_tree().current_scene == null:
		return ""
	return get_tree().current_scene.scene_file_path
