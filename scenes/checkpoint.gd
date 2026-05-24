extends Area2D

@onready var spawn_marker := get_node_or_null("Marker2D") as Marker2D
@onready var checkpoint_light := get_node_or_null("AnimatedSprite2D/PointLight2D") as PointLight2D

var _activated := false
var _player_nearby := false
var _prompt_label: Label
var _scene_path := ""


func _ready() -> void:
	_scene_path = _get_scene_path()
	if spawn_marker != null:
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)
		_refresh_activated_state()
		call_deferred("_refresh_activated_state")
	_animate_light()


func _process(_delta: float) -> void:
	if spawn_marker == null or not _player_nearby:
		return

	if not Input.is_action_just_pressed("interact"):
		return

	if not _activated:
		_activate_checkpoint()
	else:
		_rest_at_checkpoint()


func _exit_tree() -> void:
	if _player_nearby and AudioManager != null:
		AudioManager.stop_checkpoint_bgm(0.0)


func _on_body_entered(body: Node2D) -> void:
	if not (body is CharacterBody2D):
		return

	_player_nearby = true
	AudioManager.play_checkpoint_bgm()
	_show_prompt("Press E to rest")


func _on_body_exited(body: Node2D) -> void:
	if not (body is CharacterBody2D):
		return

	_player_nearby = false
	AudioManager.stop_checkpoint_bgm()
	_hide_prompt()


func _activate_checkpoint() -> void:
	if spawn_marker == null:
		return

	_scene_path = _get_scene_path()
	GameManager.set_checkpoint(spawn_marker.global_position, _scene_path)
	_activated = true
	_hide_prompt()
	if GameManager.is_at_full_health():
		CheckpointMessagePopup.show_message(
			"Checkpoint saved.\nYou are already at full health.",
			"Checkpoint"
		)
	else:
		GameManager.restore_full_health()
		AudioManager.play_sfx("success")
		CheckpointMessagePopup.show_message(
			"Checkpoint saved.\nHealth restored to 5 hearts.",
			"Checkpoint"
		)


func _rest_at_checkpoint() -> void:
	if spawn_marker == null:
		return

	if GameManager.is_at_full_health():
		CheckpointMessagePopup.show_message(
			"You are already at full health.\nNo healing needed.",
			"Full health"
		)
		return

	GameManager.restore_full_health()
	AudioManager.play_sfx("success")
	CheckpointMessagePopup.show_message(
		"Your health has been restored.\nYou are back to 5 hearts.",
		"Rested"
	)


func _get_scene_path() -> String:
	if owner != null and owner.scene_file_path != "":
		return owner.scene_file_path
	if get_tree().current_scene != null:
		return get_tree().current_scene.scene_file_path
	return ""


func _refresh_activated_state() -> void:
	if spawn_marker == null:
		return

	_scene_path = _get_scene_path()
	_activated = (
		GameManager.has_checkpoint_for_scene(_scene_path)
		and GameManager.checkpoint_pos.distance_to(spawn_marker.global_position) < 1.0
	)


func _animate_light() -> void:
	if checkpoint_light == null:
		return

	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(checkpoint_light, "energy", 1.2, 0.45)
	tween.parallel().tween_property(checkpoint_light, "scale", Vector2(2.25, 2.25), 0.45)
	tween.tween_property(checkpoint_light, "energy", 1.85, 0.55)
	tween.parallel().tween_property(checkpoint_light, "scale", Vector2(2.65, 2.65), 0.55)


func _show_prompt(text: String) -> void:
	if _prompt_label != null:
		_prompt_label.text = text
		return

	_prompt_label = Label.new()
	_prompt_label.text = text
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.position = Vector2(-54, -50)
	_prompt_label.size = Vector2(140, 20)
	_prompt_label.z_index = 20
	add_child(_prompt_label)


func _hide_prompt() -> void:
	if _prompt_label == null:
		return

	_prompt_label.queue_free()
	_prompt_label = null
