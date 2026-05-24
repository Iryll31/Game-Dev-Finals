extends Label


func _ready() -> void:
	z_index = 0
	GameManager.staff_progress_changed.connect(_on_staff_progress_changed)
	GameManager.staff_piece_collected.connect(_on_staff_piece_collected)
	call_deferred("_update_text")


func _enter_tree() -> void:
	call_deferred("_update_text")


func _exit_tree() -> void:
	if GameManager.staff_progress_changed.is_connected(_on_staff_progress_changed):
		GameManager.staff_progress_changed.disconnect(_on_staff_progress_changed)
	if GameManager.staff_piece_collected.is_connected(_on_staff_piece_collected):
		GameManager.staff_piece_collected.disconnect(_on_staff_piece_collected)


func _on_staff_progress_changed(collected: int, total: int) -> void:
	text = "%d/%d" % [collected, total]


func _on_staff_piece_collected(_piece_index: int) -> void:
	_update_text()


func _update_text() -> void:
	text = "%d/%d" % [GameManager.get_staff_collected_count(), GameManager.STAFF_PIECES]
