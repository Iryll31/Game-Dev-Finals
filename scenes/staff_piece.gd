extends Area2D

@export_range(1, 4) var piece_number: int = 1
@export var spawn_from_chest := false

const PIECE_TEXTURES: Array[String] = [
	"res://items/piece 1.png",
	"res://items/piece 2.png",
	"res://items/piece 3.png",
	"res://items/piece 4.png",
]
const DISPLAY_SCALE := Vector2(0.5, 0.5)

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _float_tween: Tween
var _can_be_collected := true
var _initialized := false


func _ready() -> void:
	if spawn_from_chest:
		return
	_initialize_piece()


func setup_from_chest(number: int) -> void:
	piece_number = number
	spawn_from_chest = true
	_initialize_piece()
	reveal_from_chest()


func _initialize_piece() -> void:
	if _initialized:
		return
	_initialized = true

	var piece_index := piece_number - 1
	if piece_index < 0 or piece_index >= PIECE_TEXTURES.size():
		push_warning("Invalid staff piece number: %d" % piece_number)
		return

	if GameManager.has_staff_piece_collected(piece_index):
		queue_free()
		return

	_sprite.sprite_frames = _create_piece_frames(load(PIECE_TEXTURES[piece_index]))
	_sprite.play(&"default")
	scale = DISPLAY_SCALE
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not spawn_from_chest:
		_start_float_animation()


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


func _create_piece_frames(texture: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	frames.add_animation(&"default")
	frames.set_animation_loop(&"default", true)
	frames.set_animation_speed(&"default", 4.0)
	frames.add_frame(&"default", texture, 1.0)
	frames.add_frame(&"default", texture, 1.0)
	return frames


func _on_body_entered(body: Node2D) -> void:
	if not _can_be_collected or not (body is CharacterBody2D):
		return

	var piece_index := piece_number - 1
	GameManager.collect_staff_piece(piece_index)
	AudioManager.play_sfx("staff_collect")
	StaffObtainedPopup.show_popup(piece_number)
	queue_free()
