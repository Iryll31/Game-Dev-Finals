extends Area2D

@export_range(1, 4) var staff_piece_number := 1
@export var prompt_text := "Press E to open"

const STAFF_PIECE_SCENE: PackedScene = preload("res://scenes/StaffPiece.tscn")
const SMOKE_SCENE: PackedScene = preload("res://sprites/smoke_chest.tscn")

@onready var _chest_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _loot_point: Marker2D = $LootPoint

var _player_nearby := false
var _is_opened := false
var _is_opening := false
var _prompt_label: Label


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if _is_piece_already_collected():
		_show_opened_state()
		return

	_chest_sprite.play(&"idle")


func _process(_delta: float) -> void:
	if not _player_nearby or _is_opened or _is_opening:
		return

	if Input.is_action_just_pressed("interact"):
		_open_chest()


func _on_body_entered(body: Node2D) -> void:
	if not (body is CharacterBody2D):
		return

	_player_nearby = true
	if not _is_opened and not _is_opening:
		_show_prompt(prompt_text)


func _on_body_exited(body: Node2D) -> void:
	if not (body is CharacterBody2D):
		return

	_player_nearby = false
	_hide_prompt()


func _open_chest() -> void:
	_is_opening = true
	_hide_prompt()
	AudioManager.play_sfx("chest_open")
	_chest_sprite.play(&"open")
	await _chest_sprite.animation_finished
	_is_opened = true
	_is_opening = false
	await _play_smoke_effect()
	_spawn_staff_piece()


func _play_smoke_effect() -> void:
	var smoke: Node2D = SMOKE_SCENE.instantiate()
	get_tree().current_scene.add_child(smoke)
	smoke.global_position = _loot_point.global_position

	var smoke_sprite: AnimatedSprite2D = smoke.get_node("AnimatedSprite2D")
	AudioManager.play_sfx("success")
	smoke_sprite.play(&"default")
	await smoke_sprite.animation_finished
	smoke.queue_free()


func _spawn_staff_piece() -> void:
	var staff_piece: Node2D = STAFF_PIECE_SCENE.instantiate()
	staff_piece.set("spawn_from_chest", true)
	get_tree().current_scene.add_child(staff_piece)
	staff_piece.global_position = _loot_point.global_position
	staff_piece.call("setup_from_chest", staff_piece_number)


func _is_piece_already_collected() -> bool:
	return GameManager.has_staff_piece_collected(staff_piece_number - 1)


func _show_opened_state() -> void:
	_is_opened = true
	_chest_sprite.play(&"open")
	_chest_sprite.pause()
	_chest_sprite.frame = _chest_sprite.sprite_frames.get_frame_count(&"open") - 1


func _show_prompt(text: String) -> void:
	if _prompt_label != null:
		_prompt_label.text = text
		return

	_prompt_label = Label.new()
	_prompt_label.text = text
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.position = Vector2(-60, -36)
	_prompt_label.size = Vector2(120, 20)
	_prompt_label.z_index = 30
	_prompt_label.add_theme_font_size_override("font_size", 10)
	add_child(_prompt_label)


func _hide_prompt() -> void:
	if _prompt_label == null:
		return

	_prompt_label.queue_free()
	_prompt_label = null
