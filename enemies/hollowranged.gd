extends CharacterBody2D

enum Type { MELEE, RANGED }
@export var type          : Type  = Type.RANGED
@export var patrol_speed  : float = 55
@export var max_health    : int   = 2
@export var gem_drop      : int   = 2
@export var patrol_range  : float = 100.0

const GRAVITY          : float = 900.0
const DAMAGE_TO_PLAYER : int   = 1
const PROJECTILE_SCENE : String = "res://enemies/hollow_projectile.tscn"

@onready var sprite       : AnimatedSprite2D = $AnimatedSprite2D
@onready var wall_detector: RayCast2D        = $WallDetector
@onready var shoot_point  : Marker2D         = $ShootPoint
@onready var hurt_timer   : Timer            = $HurtTimer
@onready var shoot_timer  : Timer            = $ShootTimer

var health         : int   = max_health
var _facing_right  : bool  = true
var _spawn_x       : float
var _is_dead       : bool  = false
var _is_hurt       : bool  = false
var _flip_cooldown : float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	_spawn_x = global_position.x
	_update_shoot_point_direction()
	if type == Type.RANGED:
		shoot_timer.start()
	shoot_timer.connect("timeout", _on_shoot_timer_timeout)
	hurt_timer.connect("timeout", _on_hurt_timer_timeout)
	$HitboxArea2D.connect("body_entered", _on_hitbox_body_entered)
	# Connect animation finished signal for death
	sprite.connect("animation_finished", _on_animation_finished)

func _physics_process(delta: float) -> void:
	# Stop all processing when dead
	if _is_dead:
		return
	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0
	# Patrol
	_flip_cooldown = max(_flip_cooldown - delta, 0.0)
	_patrol()
	sprite.flip_h = not _facing_right
	move_and_slide()

func _patrol() -> void:
	var dir := 1.0 if _facing_right else -1.0

	if _flip_cooldown <= 0.0:
		if abs(global_position.x - _spawn_x) >= patrol_range:
			_flip()
		elif is_on_wall():
			_flip()
		elif is_on_floor() and not wall_detector.is_colliding():
			_flip()

	velocity.x = patrol_speed * dir

	# ── Animation: walk or idle
	if abs(velocity.x) > 0:
		sprite.play("walk")
	else:
		sprite.play("idle")

func _flip() -> void:
	_facing_right = not _facing_right
	wall_detector.target_position.x = -wall_detector.target_position.x
	_update_shoot_point_direction()
	_flip_cooldown = 0.4

# ── Taking Damage 
func take_damage(amount: int = 1) -> void:
	if _is_hurt or _is_dead:
		return
	health -= amount
	_is_hurt = true
	_play_animation_if_exists(&"hurt", &"walk")
	sprite.modulate = Color(1.5, 0.5, 0.5)
	hurt_timer.start()
	if health <= 0:
		_die()

func _on_hurt_timer_timeout() -> void:
	_is_hurt = false
	sprite.modulate = Color.WHITE
	if not _is_dead:
		sprite.play("walk")                  

func _die() -> void:
	_is_dead = true
	velocity = Vector2.ZERO
	sprite.modulate = Color.WHITE
	sprite.play("death")                    
	set_physics_process(false)
	# queue_free() called in _on_animation_finished

func _on_animation_finished() -> void:
	if sprite.animation == "death":
		for i in gem_drop:
			_spawn_gem()
		queue_free()                         
	elif sprite.animation == "shoot":
		sprite.play("walk")                 
	elif sprite.animation == "hurt":
		sprite.play("walk")                 

func _spawn_gem() -> void:
	var gem_scene := load("res://items/Gem.tscn") as PackedScene
	if gem_scene:
		var gem := gem_scene.instantiate()
		get_parent().add_child(gem)
		gem.global_position = global_position

# ── Player Contact Damage
func _on_hitbox_body_entered(body: Node) -> void:
	if body.is_in_group("player") or body.has_method("take_damage"):
		body.take_damage(DAMAGE_TO_PLAYER)

# ── Ranged Shot
func _on_shoot_timer_timeout() -> void:
	if type != Type.RANGED:
		return
	_play_animation_if_exists(&"shoot", &"walk")
	var proj_scene := load(PROJECTILE_SCENE) as PackedScene
	if not proj_scene:
		return
	var proj := proj_scene.instantiate() as Node2D
	get_parent().add_child(proj)
	proj.global_position = shoot_point.global_position
	var player := _get_player()
	if player and global_position.distance_to(player.global_position) < 300:
		proj.direction = (player.global_position - global_position).normalized()
	else:
		proj.direction = Vector2.RIGHT if _facing_right else Vector2.LEFT


func _play_animation_if_exists(animation_name: StringName, fallback_name: StringName) -> void:
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(animation_name):
		sprite.play(animation_name)
	elif sprite.sprite_frames != null and sprite.sprite_frames.has_animation(fallback_name):
		sprite.play(fallback_name)


func _update_shoot_point_direction() -> void:
	shoot_point.position.x = abs(shoot_point.position.x) * (1.0 if _facing_right else -1.0)


func _get_player() -> Node2D:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		return player
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.get_node_or_null("Player") as Node2D
