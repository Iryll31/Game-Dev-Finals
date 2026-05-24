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
