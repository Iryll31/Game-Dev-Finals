extends Area2D

@export_multiline var dialogue_text := ""
@export var interact_prompt := "Press E to talk"
@export var cooldown_seconds := 3.0
@export var use_random_followups := false
@export var random_followup_dialogues: Array[String] = []
@export var dialogue_label_size := Vector2(220, 48)
@export var dialogue_label_offset := Vector2(-110, -58)

var _has_spoken_once := false
var _player_nearby := false
var _can_talk := true
var _prompt_label: Label


func _ready() -> void:
	randomize()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if _player_nearby and _can_talk and Input.is_action_just_pressed("interact"):
		_talk()


func _on_body_entered(body: Node2D) -> void:
	if not (body is CharacterBody2D):
		return

	_player_nearby = true
	if _can_talk:
		_show_prompt(interact_prompt)


func _on_body_exited(body: Node2D) -> void:
	if not (body is CharacterBody2D):
		return

	_player_nearby = false
	_hide_prompt()


func _show_prompt(text: String) -> void:
	if _prompt_label != null:
		_prompt_label.text = text
		return

	_prompt_label = Label.new()
	_prompt_label.text = text
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.position = Vector2(-72, -24)
	_prompt_label.size = Vector2(144, 20)
	_prompt_label.z_index = 30
	_prompt_label.add_theme_font_size_override("font_size", 10)
	add_child(_prompt_label)


func _hide_prompt() -> void:
	if _prompt_label == null:
		return

	_prompt_label.queue_free()
	_prompt_label = null


func _talk() -> void:
	_can_talk = false
	_hide_prompt()
	_show_dialogue(_get_dialogue_text())


func _get_dialogue_text() -> String:
	if use_random_followups and _has_spoken_once and not random_followup_dialogues.is_empty():
		return random_followup_dialogues.pick_random()

	_has_spoken_once = true
	return dialogue_text


func _show_dialogue(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.position = dialogue_label_offset
	label.size = dialogue_label_size
	label.z_index = 30
	label.add_theme_font_size_override("font_size", 10)
	add_child(label)

	var tween := create_tween()
	tween.tween_interval(cooldown_seconds)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)
	tween.tween_callback(_finish_cooldown)


func _finish_cooldown() -> void:
	_can_talk = true
	if _player_nearby:
		_show_prompt(interact_prompt)
