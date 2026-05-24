extends Area2D

@export_file("*.tscn") var target_scene: String
@export var prompt_text := "Press E to enter"
@export var requires_key := false
@export var required_key_count: int = 1
@export var door_display_name := ""
@export var required_key_display_name := ""
@export var locked_prompt_text := "You need a key first"
@export var requires_staff_piece := false
@export var locked_staff_prompt_text := "You need the staff piece first"
@export var use_target_spawn := false
@export var target_spawn_position := Vector2.ZERO

var _player_nearby := false
var _is_entering := false
var _prompt_label: Label
var _nearby_player: CharacterBody2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if _player_nearby and not _is_entering and Input.is_action_just_pressed("interact"):
		if requires_key and not GameManager.has_minimum_keys_for_scene(required_key_count):
			_show_prompt(_get_locked_prompt_text())
			return
		if requires_staff_piece and not GameManager.has_staff_piece_for_scene():
			_show_prompt(locked_staff_prompt_text)
			return
		_enter_target_scene()


func _on_body_entered(body: Node2D) -> void:
	if not (body is CharacterBody2D):
		return

	_player_nearby = true
	_nearby_player = body as CharacterBody2D
	_show_prompt(_get_current_prompt_text())


func _on_body_exited(body: Node2D) -> void:
	if not (body is CharacterBody2D):
		return

	_player_nearby = false
	if body == _nearby_player:
		_nearby_player = null
	_hide_prompt()


func _show_prompt(text: String) -> void:
	if _prompt_label != null:
		_prompt_label.text = text
		return

	_prompt_label = Label.new()
	_prompt_label.text = text
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.position = Vector2(-110, -44)
	_prompt_label.size = Vector2(220, 28)
	_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt_label.z_index = 30
	_prompt_label.add_theme_font_size_override("font_size", 10)
	add_child(_prompt_label)


func _hide_prompt() -> void:
	if _prompt_label == null:
		return

	_prompt_label.queue_free()
	_prompt_label = null


func _enter_target_scene() -> void:
	if target_scene == "" or not ResourceLoader.exists(target_scene):
		push_warning("Stage entrance target scene is missing: " + target_scene)
		return

	if requires_key:
		GameManager.has_key = false

	_is_entering = true
	monitoring = false
	_hide_prompt()
	if use_target_spawn:
		var current_scene := get_tree().current_scene
		if current_scene != null and current_scene.scene_file_path == target_scene and _nearby_player != null:
			_nearby_player.global_position = target_spawn_position
			_nearby_player.velocity = Vector2.ZERO
			await get_tree().physics_frame
			monitoring = true
			_is_entering = false
			return

		GameManager.set_transition_spawn(target_spawn_position, target_scene)
		GameManager.set_stage_entry_spawn(target_spawn_position, target_scene)
	get_tree().change_scene_to_file(target_scene)


func _get_current_prompt_text() -> String:
	if requires_key and not GameManager.has_minimum_keys_for_scene(required_key_count):
		return _get_locked_prompt_text()
	if requires_staff_piece and not GameManager.has_staff_piece_for_scene():
		return locked_staff_prompt_text

	return prompt_text


func _get_locked_prompt_text() -> String:
	if door_display_name != "" and required_key_display_name != "":
		return "%s is locked. You need %s." % [door_display_name, required_key_display_name]
	if door_display_name != "":
		return "%s is locked." % door_display_name
	return locked_prompt_text
