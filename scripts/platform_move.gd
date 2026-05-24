extends Node2D

@export var speed: float = 60.0
@export var range: float = 120.0
@export var horizontal: bool = true
@export var carry_bodies := false

var distance_traveled: float = 0.0
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	direction = Vector2.RIGHT if horizontal else Vector2.DOWN
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	var movement := direction * speed * delta
	position += movement
	if carry_bodies:
		_carry_riding_bodies(movement)

	distance_traveled += movement.length()
	if distance_traveled >= range:
		distance_traveled = 0.0
		direction = -direction

func _carry_riding_bodies(movement: Vector2) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	for node in scene.find_children("*", "CharacterBody2D", true, false):
		var body := node as CharacterBody2D
		if body != null and _is_body_riding_platform(body):
			body.global_position += movement

func _is_body_riding_platform(body: CharacterBody2D) -> bool:
	if not body.is_on_floor():
		return false

	for index in range(body.get_slide_collision_count()):
		var collision: KinematicCollision2D = body.get_slide_collision(index)
		if collision == null:
			continue

		var collider := collision.get_collider() as Node
		if collider == self or (collider != null and is_ancestor_of(collider)):
			return true

	return false
