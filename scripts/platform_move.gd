extends Node2D

@export var speed: float = 60.0
@export var range: float = 120.0
@export var horizontal: bool = true

var distance_traveled: float = 0.0
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	direction = Vector2.RIGHT if horizontal else Vector2.DOWN
	set_process(true)

func _process(delta: float) -> void:
	var movement = direction * speed * delta
	position += movement
	distance_traveled += movement.length()
	if distance_traveled >= range:
		distance_traveled = 0.0
		direction = -direction
