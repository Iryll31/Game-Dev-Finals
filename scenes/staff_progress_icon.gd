extends Sprite2D

const STAFF_ICON: Texture2D = preload("res://items/complete piece.png")
const TARGET_ICON_SIZE: float = 22.0


func _ready() -> void:
	texture = STAFF_ICON
	z_index = 0
	var tex_size := texture.get_size()
	if tex_size.x > 0.0 and tex_size.y > 0.0:
		var scale_factor := TARGET_ICON_SIZE / maxf(tex_size.x, tex_size.y)
		scale = Vector2(scale_factor, scale_factor)
	offset = Vector2.ZERO
