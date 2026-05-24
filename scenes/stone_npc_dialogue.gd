extends Area2D

enum Phase { IDLE, SHOWING_LINE, CHOOSING, DONE }

@export_multiline var intro_text := "UNIT... you have awakened. Good. I feared the darkness had already taken everything"
@export_multiline var followup_text := "I am Aldric. Or rather — what remains of me in these stones. The witch Morrga came without warning. She took my staff and scattered it across these floors."
@export_multiline var quest_text := "I built you to protect this place. Now I need you to protect me. Find the four pieces of my staff. Restore it. Only then can the corruption be undone."
@export var interact_prompt := "Press E to talk"
@export var choice_prompt := "Press E to talk again  |  Press Q to leave"
@export var line_display_seconds := 3.0
@export var dialogue_font_size := 14
@export var prompt_font_size := 12
@export var dialogue_label_size := Vector2(360, 96)
@export var dialogue_label_offset := Vector2(-180, -88)

var _phase := Phase.IDLE
var _player_nearby := false
var _prompt_label: Label
var _dialogue_label: Label


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if not _player_nearby or _phase == Phase.SHOWING_LINE:
		return

	match _phase:
		Phase.IDLE:
			if Input.is_action_just_pressed("interact"):
				_start_intro()
		Phase.CHOOSING:
			if Input.is_action_just_pressed("interact"):
				_show_followup()
			elif Input.is_action_just_pressed("leave_dialogue"):
				_leave_dialogue()
		Phase.DONE:
			if Input.is_action_just_pressed("interact"):
				_show_followup()


func _on_body_entered(body: Node2D) -> void:
	if not (body is CharacterBody2D):
		return

	_player_nearby = true
	_refresh_prompt()


func _on_body_exited(body: Node2D) -> void:
	if not (body is CharacterBody2D):
		return

	_player_nearby = false
	_hide_prompt()


func _refresh_prompt() -> void:
	if not _player_nearby or _phase == Phase.SHOWING_LINE:
		return

	match _phase:
		Phase.IDLE, Phase.DONE:
			_show_prompt(interact_prompt)
		Phase.CHOOSING:
			_show_prompt(choice_prompt)


func _start_intro() -> void:
	_phase = Phase.SHOWING_LINE
	_hide_prompt()
	_show_dialogue_line(intro_text, _on_intro_finished)


func _on_intro_finished() -> void:
	_phase = Phase.CHOOSING
	_refresh_prompt()


func _show_followup() -> void:
	_phase = Phase.SHOWING_LINE
	_hide_prompt()
	_show_dialogue_line(followup_text, _on_followup_finished)


func _on_followup_finished() -> void:
	_show_dialogue_line(quest_text, _on_quest_finished)


func _on_quest_finished() -> void:
	_phase = Phase.DONE
	_refresh_prompt()


func _leave_dialogue() -> void:
	_clear_dialogue_label()
	_phase = Phase.DONE
	_refresh_prompt()


func _show_dialogue_line(text: String, on_finished: Callable) -> void:
	_clear_dialogue_label()

	_dialogue_label = Label.new()
	_dialogue_label.text = text
	_dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_label.position = dialogue_label_offset
	_dialogue_label.size = dialogue_label_size
	_dialogue_label.z_index = 30
	_dialogue_label.add_theme_font_size_override("font_size", dialogue_font_size)
	add_child(_dialogue_label)

	var tween := create_tween()
	tween.tween_interval(line_display_seconds)
	tween.tween_property(_dialogue_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(_clear_dialogue_label)
	tween.tween_callback(on_finished)


func _clear_dialogue_label() -> void:
	if _dialogue_label == null:
		return

	_dialogue_label.queue_free()
	_dialogue_label = null


func _show_prompt(text: String) -> void:
	var prompt_size := Vector2(168, 24)
	var prompt_position := Vector2(-84, -28)
	if text == choice_prompt:
		prompt_size = Vector2(300, 28)
		prompt_position = Vector2(-150, -32)

	if _prompt_label != null:
		_prompt_label.text = text
		_prompt_label.position = prompt_position
		_prompt_label.size = prompt_size
		return

	_prompt_label = Label.new()
	_prompt_label.text = text
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.position = prompt_position
	_prompt_label.size = prompt_size
	_prompt_label.z_index = 30
	_prompt_label.add_theme_font_size_override("font_size", prompt_font_size)
	add_child(_prompt_label)


func _hide_prompt() -> void:
	if _prompt_label == null:
		return

	_prompt_label.queue_free()
	_prompt_label = null
