extends CharacterBody2D

enum Type { MELEE, RANGED }

@export var type          : Type  = Type.MELEE
@export var patrol_speed  : float = 70.0
@export var max_health    : int   = 3
@export var gem_drop      : int   = 1
@export var patrol_range  : float = 120.0

const GRAVITY          : float = 900.0
const DAMAGE_TO_PLAYER : int   = 1
const PROJECTILE_SCENE : String = "res://enemies/hollow_projectile.tscn"

@onready var sprite       : AnimatedSprite2D = $AnimatedSprite2D
@onready var wall_detector: RayCast2D        = $WallDetector
@onready var hurt_timer   : Timer            = $HurtTimer
@onready var shoot_timer  : Timer            = $ShootTimer

var health         : int   = max_health
var _facing_right  : bool  = true
var _spawn_x       : float
var _is_hurt       : bool  = false
var _is_dead       : bool  = false
var _flip_cooldown : float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	_spawn_x = global_position.x
	if type == Type.RANGED:
		shoot_timer.start()
	shoot_timer.connect("timeout", _on_shoot_timer_timeout)
	hurt_timer.connect("timeout", _on_hurt_timer_timeout)
	$HitboxArea2D.connect("body_entered", _on_hitbox_body_entered)
	sprite.connect("animation_finished", _on_animation_finished)

func _physics_process(delta: float) -> void:
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
	if not is_on_floor():
		return

	var past_left  : bool = global_position.x < _spawn_x - patrol_range
	var past_right : bool = global_position.x > _spawn_x + patrol_range
	var hits_wall  : bool = wall_detector.is_colliding()

	if _flip_cooldown == 0.0 and (hits_wall or (_facing_right and past_right) or (not _facing_right and past_left)):
		_flip()
		_flip_cooldown = 0.6

	velocity.x = patrol_speed * (1.0 if _facing_right else -1.0)

	# ── Animation: walk or idle ──
	if abs(velocity.x) > 0:
		sprite.play("walk")
	else:
		sprite.play("idle")

func _flip() -> void:
	_facing_right = not _facing_right
	wall_detector.target_position.x = abs(wall_detector.target_position.x) * (1.0 if _facing_right else -1.0)
	global_position.x += 6.0 * (1.0 if _facing_right else -1.0)

#  Take Damage 
func take_damage(amount: int = 1) -> void:
	if _is_hurt or _is_dead:
		return
	health -= amount
	_is_hurt = true
	sprite.play("hurt")                      
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
	# queue_free() is called in _on_animation_finished when "death" finishes

func _on_animation_finished() -> void:
	if sprite.animation == "death":
		for i in gem_drop:
			_spawn_gem()
		queue_free()                         
	elif sprite.animation == "attack":
		sprite.play("walk")                  
	elif sprite.animation == "hurt":
		sprite.play("walk")                  

func _spawn_gem() -> void:
	var gem_scene := load("res://items/Gem.tscn") as PackedScene
	if gem_scene:
		var gem := gem_scene.instantiate()
		get_parent().add_child(gem)
		gem.global_position = global_position

# Player Contact Damage 
func _on_hitbox_body_entered(body: Node) -> void:
	if body.is_in_group("player") or body.has_method("take_damage"):
		sprite.play("attack")
		body.take_damage(DAMAGE_TO_PLAYER)

# Ranged Shot 
func _on_shoot_timer_timeout() -> void:
	if type != Type.RANGED:
		return
	var proj_scene := load(PROJECTILE_SCENE) as PackedScene
	if not proj_scene:
		return
	var proj := proj_scene.instantiate() as Node2D
	get_parent().add_child(proj)
	proj.global_position = global_position
	var player := get_tree().get_first_node_in_group("player")
	if player and global_position.distance_to(player.global_position) < 300:
		proj.direction = (player.global_position - global_position).normalized()
	else:
		proj.direction = Vector2.RIGHT if _facing_right else Vector2.LEFT
