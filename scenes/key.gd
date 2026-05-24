extends Area2D

@export var key_id: int = 0
@export var spawn_from_chest := false

const DISPLAY_SCALE := Vector2(0.6, 0.6)

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _float_tween: Tween
var _can_be_collected := true
var _initialized := false


func _ready() -> void:
	if spawn_from_chest:
		return
	_initialize_key()


func setup_from_chest(id: int) -> void:
	key_id = id
	spawn_from_chest = true
	_initialize_key()
	reveal_from_chest()


func _initialize_key() -> void:
	if _initialized:
		return
	_initialized = true

	if GameManager.is_key_collected(key_id):
		queue_free()
		return

	scale = DISPLAY_SCALE
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not spawn_from_chest:
		_sprite.play(&"default")


func reveal_from_chest() -> void:
	_can_be_collected = false
	set_deferred("monitoring", false)
	modulate.a = 0.0
	scale = DISPLAY_SCALE * 0.25

	var reveal_tween := create_tween()
	reveal_tween.set_parallel(true)
	reveal_tween.tween_property(self, "modulate:a", 1.0, 0.35)
	reveal_tween.tween_property(self, "scale", DISPLAY_SCALE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	reveal_tween.chain().tween_callback(_enable_collection)


func _enable_collection() -> void:
	_can_be_collected = true
	set_deferred("monitoring", true)
	_sprite.play(&"default")
	call_deferred("_try_collect_overlapping_player")
	_start_float_animation()


func _try_collect_overlapping_player() -> void:
	for body in get_overlapping_bodies():
		if body is CharacterBody2D:
			_on_body_entered(body)
			return


func _start_float_animation() -> void:
	if _float_tween != null:
		_float_tween.kill()

	var base_y := position.y
	_float_tween = create_tween().set_loops()
	_float_tween.tween_property(self, "position:y", base_y - 5.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_float_tween.tween_property(self, "position:y", base_y + 5.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_body_entered(body: Node2D) -> void:
	if not _can_be_collected or not (body is CharacterBody2D):
		return

	GameManager.collect_key("", key_id)
	AudioManager.play_sfx("key_collect")
	KeyObtainedPopup.show_popup(key_id)
	queue_free()
