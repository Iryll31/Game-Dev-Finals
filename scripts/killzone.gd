extends Area2D


@onready var timer: Timer = $Timer

var _is_triggered := false


func _on_body_entered(body: Node2D) -> void:
	if _is_triggered or not (body is CharacterBody2D):
		return

	_is_triggered = true
	monitoring = false
	print("You died!")
	_play_player_death_feedback(body)
	Engine.time_scale=0.5
	var collision_shape := body.get_node_or_null("CollisionShape2D")
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	timer.start()


func _on_timer_timeout() -> void:
	Engine.time_scale=1
	if GameManager.has_checkpoint() and ResourceLoader.exists(GameManager.checkpoint_scene_path):
		get_tree().change_scene_to_file(GameManager.checkpoint_scene_path)
	else:
		get_tree().reload_current_scene()


func _play_player_death_feedback(body: Node2D) -> void:
	if body.has_method("play_death_feedback"):
		body.play_death_feedback()
		return

	AudioManager.play_sfx("player_death")
