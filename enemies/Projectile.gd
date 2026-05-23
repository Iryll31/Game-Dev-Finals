extends Area2D

const SPEED     : float = 400.0
const DAMAGE    : int   = 1

var direction   : Vector2 = Vector2.RIGHT
var _bounces    : int = 0   # Used in boss phase 2 (set externally)
var max_bounces : int = 0

@onready var sprite         : AnimatedSprite2D = $AnimatedSprite2D
@onready var lifetime_timer : Timer            = $LifetimeTimer

func _ready() -> void:
	sprite.flip_h = direction.x < 0
	lifetime_timer.start()
	connect("body_entered",  _on_body_entered)
	connect("area_entered",  _on_area_entered)

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		body.take_damage(DAMAGE)
		_destroy()
	elif body is TileMapLayer or body.is_in_group("walls"):
		if _bounces < max_bounces:
			_bounce()
		else:
			_destroy()

func _on_area_entered(area: Node) -> void:
	if area.is_in_group("enemy_hitbox"):
		area.get_parent().take_damage(DAMAGE)
		_destroy()

func _bounce() -> void:
	_bounces += 1
	direction.y = -direction.y  # simple wall bounce

func _destroy() -> void:
	queue_free()

func _on_lifetime_timer_timeout() -> void:
	_destroy()
