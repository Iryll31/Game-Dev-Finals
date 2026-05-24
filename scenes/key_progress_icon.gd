extends AnimatedSprite2D

const KEY_TEXTURE: Texture2D = preload("res://items/key-white.png")
const KEY_FRAME_SIZE: int = 32
const KEY_FRAME_COUNT: int = 12


func _ready() -> void:
	z_index = 2
	sprite_frames = _create_key_frames()
	animation = &"default"
	scale = Vector2(0.75, 0.75)
	play()
	GameManager.key_progress_changed.connect(_on_key_progress_changed)
	call_deferred("_update_visibility")


func _exit_tree() -> void:
	if GameManager.key_progress_changed.is_connected(_on_key_progress_changed):
		GameManager.key_progress_changed.disconnect(_on_key_progress_changed)


func _on_key_progress_changed(_collected: int, _total: int) -> void:
	_update_visibility()


func _update_visibility() -> void:
	if get_tree().current_scene == null:
		visible = false
		return
	visible = GameManager.get_key_total_for_scene(get_tree().current_scene.scene_file_path) > 0


func _create_key_frames() -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	frames.add_animation(&"default")
	frames.set_animation_loop(&"default", true)
	frames.set_animation_speed(&"default", 10.0)

	for index in range(KEY_FRAME_COUNT):
		var frame: AtlasTexture = AtlasTexture.new()
		frame.atlas = KEY_TEXTURE
		frame.region = Rect2(index * KEY_FRAME_SIZE, 0, KEY_FRAME_SIZE, KEY_FRAME_SIZE)
		frames.add_frame(&"default", frame)

	return frames
