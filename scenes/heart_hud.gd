extends Node2D

const HEART_SPACING: int = 18
const HEART_FULL: Texture2D = preload("res://player/Hearts/PNG/basic/heart.png")
const HEART_EMPTY: Texture2D = preload("res://player/Hearts/PNG/basic/background.png")
const HEART_BORDER: Texture2D = preload("res://player/Hearts/PNG/basic/border.png")

var _full_hearts: Array[AnimatedSprite2D] = []


func _ready() -> void:
	GameManager.health_changed.connect(_on_health_changed)
	_build_hearts(GameManager.MAX_HEALTH)
	_update_hearts(GameManager.health, GameManager.MAX_HEALTH)


func _exit_tree() -> void:
	if GameManager.health_changed.is_connected(_on_health_changed):
		GameManager.health_changed.disconnect(_on_health_changed)


func _on_health_changed(new_hp: int, max_hp: int) -> void:
	if max_hp != _full_hearts.size():
		_build_hearts(max_hp)
	_update_hearts(new_hp, max_hp)


func _build_hearts(max_hp: int) -> void:
	for child in get_children():
		child.queue_free()
	_full_hearts.clear()

	for index in range(max_hp):
		var heart_position := Vector2(index * HEART_SPACING, 0)

		var empty_heart := Sprite2D.new()
		empty_heart.texture = HEART_EMPTY
		empty_heart.position = heart_position
		add_child(empty_heart)

		var full_heart := AnimatedSprite2D.new()
		full_heart.sprite_frames = _create_heart_frames()
		full_heart.animation = &"default"
		full_heart.position = heart_position
		full_heart.play()
		add_child(full_heart)
		_full_hearts.append(full_heart)

		var border := Sprite2D.new()
		border.texture = HEART_BORDER
		border.position = heart_position
		add_child(border)


func _create_heart_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	frames.add_animation(&"default")
	frames.set_animation_loop(&"default", true)
	frames.set_animation_speed(&"default", 2.0)
	frames.add_frame(&"default", HEART_FULL)
	frames.add_frame(&"default", HEART_FULL)
	return frames


func _update_hearts(new_hp: int, max_hp: int) -> void:
	var visible_hearts: int = clampi(new_hp, 0, max_hp)
	for index in range(_full_hearts.size()):
		_full_hearts[index].visible = index < visible_hearts
