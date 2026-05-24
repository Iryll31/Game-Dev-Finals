extends CharacterBody2D


const SPEED = 130.0
const JUMP_VELOCITY = -370.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	call_deferred("_apply_checkpoint_spawn")


func _apply_checkpoint_spawn() -> void:
	var scene_path := _get_scene_path()

	var death_spawn := GameManager.consume_death_respawn(scene_path)
	if death_spawn != Vector2.ZERO:
		global_position = death_spawn
		_snap_camera_to_player()
		call_deferred("_snap_camera_to_player")
		return

	var transition_spawn := GameManager.consume_transition_spawn(scene_path)
	if transition_spawn != Vector2.ZERO:
		global_position = transition_spawn
		_snap_camera_to_player()
		call_deferred("_snap_camera_to_player")
		return

	if GameManager.has_stage_entry_spawn(scene_path):
		global_position = GameManager.get_stage_entry_spawn(scene_path)
		_snap_camera_to_player()
		call_deferred("_snap_camera_to_player")
		return

	if GameManager.has_checkpoint_for_scene(scene_path):
		global_position = GameManager.checkpoint_pos
		_snap_camera_to_player()
		call_deferred("_snap_camera_to_player")


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if (Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept")) and is_on_floor():
		velocity.y = JUMP_VELOCITY

#get input direction: -1, 0, 1
	var direction = Input.get_axis("move_left", "move_right")
	if direction == 0.0:
		direction = Input.get_axis("ui_left", "ui_right")
	
	#flip sprite
	if direction > 0:
		animated_sprite_2d.flip_h = false
	elif direction < 0:
		animated_sprite_2d.flip_h = true 
		
		#play animations
	if is_on_floor():
		if direction == 0:
			animated_sprite_2d.play("idle")
		else:
			animated_sprite_2d.play("walk")
	else:
		animated_sprite_2d.play("jump")
		
		
		#apply movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


func _snap_camera_to_player() -> void:
	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return

	camera.reset_smoothing()
	camera.force_update_scroll()


func take_damage(amount: int = 1) -> void:
	GameManager.take_damage(amount)
	AudioManager.play_sfx("player_hit")
	play_damage_feedback()


func play_damage_feedback() -> void:
	_flash_screen()
	_flash_player_red()


func play_death_feedback() -> void:
	AudioManager.play_sfx("player_death")
	play_damage_feedback()


func _flash_player_red() -> void:
	animated_sprite_2d.modulate = Color(1.0, 0.1, 0.1)
	var tween := create_tween()
	tween.tween_property(animated_sprite_2d, "modulate", Color.WHITE, 0.25)


func _flash_screen() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	var flash := ColorRect.new()
	flash.color = Color(1.0, 1.0, 1.0, 0.8)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(flash)
	get_tree().root.add_child(layer)

	var tween := layer.create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.18)
	tween.tween_callback(layer.queue_free)


func _get_scene_path() -> String:
	if owner != null and owner.scene_file_path != "":
		return owner.scene_file_path
	if get_tree().current_scene != null:
		return get_tree().current_scene.scene_file_path
	return ""
