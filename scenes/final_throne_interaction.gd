extends Area2D

const FINAL_PIECE_INDEX := 3
const PROMPT_TEXT := "This throneroom is eerily empty...\n(E to interact)"
const QUESTION_TEXT_1 := "What exactly happened here?"
const QUESTION_TEXT_2 := "What happened to this kingdom?"
const QUESTION_TEXT_3 := "Maybe the Wizard can give me more answers..."
const CONTINUE_TEXT := "\n\n(Press E)"
const THANKS_TEXT := "Thank you for Playing!"
const FALLBACK_INTERACT_DISTANCE := 180.0
const FINAL_SCREEN_FADE_SECONDS := 0.5
const FINAL_BLACK_SECONDS := 3.0
const THRONE_ROOM_BGM_PATH := "../AudioStreamPlayer2"

var _player_nearby := false
var _sequence_running := false
var _prompt_label: Label
var _final_piece_taken := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	input_event.connect(_on_input_event)
	GameManager.staff_piece_collected.connect(_on_staff_piece_collected)
	_final_piece_taken = GameManager.has_staff_piece_collected(FINAL_PIECE_INDEX)
	monitoring = true
	input_pickable = true


func _process(_delta: float) -> void:
	if not _final_piece_taken:
		return
	_refresh_player_proximity()
	if not _player_nearby or _sequence_running:
		return
	if Input.is_action_just_pressed("interact"):
		_start_ending_sequence()


func _on_input_event(viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if not _final_piece_taken or not _player_nearby or _sequence_running:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		viewport.set_input_as_handled()
		_start_ending_sequence()


func _on_body_entered(body: Node2D) -> void:
	if not (body is CharacterBody2D) or not _final_piece_taken:
		return
	_player_nearby = true
	_show_prompt(PROMPT_TEXT)


func _on_body_exited(body: Node2D) -> void:
	if not (body is CharacterBody2D):
		return
	_player_nearby = false
	_hide_prompt()


func _on_staff_piece_collected(piece_index: int) -> void:
	if piece_index == FINAL_PIECE_INDEX:
		_final_piece_taken = true
		call_deferred("_try_show_prompt_for_overlapping_player")


func _start_ending_sequence() -> void:
	_sequence_running = true
	_hide_prompt()
	await _show_dialogue_line(QUESTION_TEXT_1 + CONTINUE_TEXT)
	await _wait_for_interact_pressed()
	await _show_dialogue_line(QUESTION_TEXT_2 + CONTINUE_TEXT)
	await _wait_for_interact_pressed()
	await _show_dialogue_line(QUESTION_TEXT_3, 2.8)
	await _fade_out_throne_room_music(FINAL_BLACK_SECONDS)
	await _fade_to_black(FINAL_BLACK_SECONDS)
	await _show_final_message(THANKS_TEXT)


func _show_prompt(text: String) -> void:
	if _prompt_label != null:
		_prompt_label.text = text
		return
	_prompt_label = Label.new()
	_prompt_label.text = text
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.position = Vector2(-130, -90)
	_prompt_label.size = Vector2(260, 48)
	_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt_label.z_index = 50
	_prompt_label.add_theme_font_size_override("font_size", 11)
	add_child(_prompt_label)


func _hide_prompt() -> void:
	if _prompt_label == null:
		return
	_prompt_label.queue_free()
	_prompt_label = null


func _try_show_prompt_for_overlapping_player() -> void:
	for body in get_overlapping_bodies():
		if body is CharacterBody2D:
			_on_body_entered(body)
			return
	_refresh_player_proximity()


func _refresh_player_proximity() -> void:
	var player := _get_player()
	if player == null:
		return

	var is_close := global_position.distance_to(player.global_position) <= FALLBACK_INTERACT_DISTANCE
	if is_close and not _player_nearby:
		_player_nearby = true
		_show_prompt(PROMPT_TEXT)
	elif not is_close and _player_nearby:
		_player_nearby = false
		_hide_prompt()


func _get_player() -> Node2D:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		return player
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.get_node_or_null("Player") as Node2D


func _show_dialogue_line(text: String, seconds: float = 0.0) -> void:
	var layer := CanvasLayer.new()
	layer.name = "EndingDialogueLayer"
	layer.layer = 150
	var content := Control.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(content)
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.62)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(center)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 30)
	center.add_child(label)
	get_tree().root.add_child(layer)
	content.modulate.a = 0.0
	var tween := content.create_tween()
	tween.tween_property(content, "modulate:a", 1.0, 0.35)
	if seconds <= 0.0:
		await tween.finished
		return
	tween.tween_interval(seconds)
	tween.tween_property(content, "modulate:a", 0.0, 0.35)
	tween.tween_callback(layer.queue_free)
	await tween.finished


func _wait_for_interact_pressed() -> void:
	await get_tree().process_frame
	while not Input.is_action_just_pressed("interact"):
		await get_tree().process_frame
	_remove_ending_layers()


func _remove_ending_layers() -> void:
	for child in get_tree().root.get_children():
		if child is CanvasLayer and child.name == "EndingDialogueLayer":
			child.queue_free()


func _fade_to_black(seconds: float) -> void:
	var layer := CanvasLayer.new()
	layer.name = "EndingBlackLayer"
	layer.layer = 150
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var overlay := ColorRect.new()
	overlay.color = Color.BLACK
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(overlay)
	get_tree().root.add_child(layer)
	overlay.modulate.a = 0.0
	var tween := overlay.create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.75)
	tween.tween_interval(seconds)
	await tween.finished


func _fade_out_throne_room_music(seconds: float) -> void:
	var player := get_node_or_null(THRONE_ROOM_BGM_PATH) as AudioStreamPlayer
	if player == null or not player.playing:
		return
	var tween := player.create_tween()
	tween.tween_property(player, "volume_db", -60.0, minf(seconds, 1.5))
	tween.tween_callback(player.stop)


func _show_final_message(text: String) -> void:
	var layer := CanvasLayer.new()
	layer.name = "EndingDialogueLayer"
	layer.layer = 150
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var content := Control.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(content)
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.82)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(center)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 32)
	center.add_child(label)
	get_tree().root.add_child(layer)
	content.modulate.a = 0.0
	var tween := content.create_tween()
	tween.tween_property(content, "modulate:a", 1.0, FINAL_SCREEN_FADE_SECONDS)
	await tween.finished
	GameManager.emit_signal("game_won")
	get_tree().paused = true
