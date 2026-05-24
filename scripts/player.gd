extends CharacterBody2D


const SPEED = 130.0
const JUMP_VELOCITY = -370.0
const HURT_ANIMATION := &"hurt"
const DEATH_ANIMATION := &"death"
const HURT_FALLBACK_SECONDS := 0.35
const DEATH_FALLBACK_SECONDS := 0.8

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var _trap_invincible := false
var _is_hurt := false
var _is_dead := false


func _ready() -> void:
	add_to_group("player")
	if not GameManager.game_over.is_connected(_on_game_over):
		GameManager.game_over.connect(_on_game_over)
	call_deferred("_apply_checkpoint_spawn")


func _apply_checkpoint_spawn() -> void:
	var scene_path := _get_scene_path()
	var scene_start_pos := global_position

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

	GameManager.register_stage_entry_spawn(scene_start_pos, scene_path)

	if GameManager.has_checkpoint_for_scene(scene_path):
		global_position = GameManager.checkpoint_pos
		_snap_camera_to_player()
		call_deferred("_snap_camera_to_player")


func _physics_process(delta):
	if _is_dead:
		if not is_on_floor():
			velocity.y += gravity * delta
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		return

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
	if _is_hurt:
		pass
	elif is_on_floor():
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


func is_trap_invincible() -> bool:
	return _trap_invincible


func grant_trap_invincibility(seconds: float) -> void:
	_trap_invincible = true
	var cooldown := get_tree().create_timer(seconds)
	cooldown.timeout.connect(_on_trap_invincibility_ended, CONNECT_ONE_SHOT)


func _on_trap_invincibility_ended() -> void:
	_trap_invincible = false


func take_damage(amount: int = 1) -> void:
	if _trap_invincible or _is_dead:
		return
	GameManager.take_damage(amount)
	if GameManager.is_game_over or GameManager.health <= 0:
		return
	AudioManager.play_sfx("player_hit")
	play_damage_feedback()


func play_damage_feedback() -> void:
	_flash_screen()
	_play_hurt_animation()


func play_death_feedback() -> void:
	AudioManager.play_sfx("player_death")
	_flash_screen()
	_play_temporary_death_animation()


func _on_game_over() -> void:
	if _is_dead:
		return
	call_deferred("_play_game_over_death_sequence")


func _play_game_over_death_sequence() -> void:
	_is_dead = true
	velocity = Vector2.ZERO
	AudioManager.play_sfx("player_death")
	_flash_screen()
	await _play_animation_once(DEATH_ANIMATION, DEATH_FALLBACK_SECONDS)
	_go_to_game_over_screen()


func _go_to_game_over_screen() -> void:
	if get_tree() != null:
		get_tree().change_scene_to_file("res://ui/GameOver.tscn")


func _play_hurt_animation() -> void:
	if _is_hurt or _is_dead:
		return
	_is_hurt = true
	await _play_animation_once(HURT_ANIMATION, HURT_FALLBACK_SECONDS)
	_is_hurt = false


func _play_temporary_death_animation() -> void:
	if _is_dead:
		return
	var was_hurt := _is_hurt
	_is_hurt = true
	await _play_animation_once(DEATH_ANIMATION, DEATH_FALLBACK_SECONDS)
	_is_hurt = was_hurt


func _play_animation_once(animation_name: StringName, fallback_seconds: float) -> void:
	if animated_sprite_2d.sprite_frames == null or not animated_sprite_2d.sprite_frames.has_animation(animation_name):
		await get_tree().create_timer(fallback_seconds).timeout
		return

	animated_sprite_2d.modulate = Color.WHITE
	animated_sprite_2d.play(animation_name)
	await animated_sprite_2d.animation_finished


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
