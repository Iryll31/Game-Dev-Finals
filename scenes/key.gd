extends Area2D


func _ready() -> void:
	if GameManager.has_key_for_scene():
		queue_free()
		return

	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not (body is CharacterBody2D):
		return

	GameManager.collect_key()
	queue_free()
