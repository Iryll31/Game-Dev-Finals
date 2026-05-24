extends Area2D

@export var prompt_message := "There's no turning back"

var _prompt_label: Label


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if not (body is CharacterBody2D):
		return

	_show_prompt()


func _on_body_exited(body: Node2D) -> void:
	if not (body is CharacterBody2D):
		return

	_hide_prompt()


func _show_prompt() -> void:
	if _prompt_label != null:
		_prompt_label.text = prompt_message
		return

	_prompt_label = Label.new()
	_prompt_label.text = prompt_message
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.position = Vector2(-90, -44)
	_prompt_label.size = Vector2(180, 20)
	_prompt_label.z_index = 30
	_prompt_label.add_theme_font_size_override("font_size", 10)
	add_child(_prompt_label)


func _hide_prompt() -> void:
	if _prompt_label == null:
		return

	_prompt_label.queue_free()
	_prompt_label = null
