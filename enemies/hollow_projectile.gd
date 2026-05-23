extends Area2D

const SPEED  : float = 250.0
const DAMAGE : int   = 1

var direction : Vector2 = Vector2.RIGHT

@onready var lifetime_timer : Timer     = $LifetimeTimer
@onready var ray             : RayCast2D = $RayCast2D

func _ready() -> void:
	lifetime_timer.start()
	connect("body_entered", _on_body_entered)
	lifetime_timer.connect("timeout", _on_lifetime_timer_timeout)

func _physics_process(delta: float) -> void:
	# Update raycast direction to match movement
	ray.target_position = direction * 10

	# Check if raycast hits anything solid ahead
	if ray.is_colliding():
		var collider := ray.get_collider()
		if collider is TileMapLayer:
			queue_free()
			return

	position += direction * SPEED * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.take_damage(DAMAGE)
		queue_free()

func _on_lifetime_timer_timeout() -> void:
	queue_free()
