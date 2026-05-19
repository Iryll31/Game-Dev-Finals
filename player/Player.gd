
extends CharacterBody2D

# ── Movement Constants ───────────────────────────────────────────────────
const SPEED          : float = 180.0
const JUMP_VELOCITY  : float = -380.0
const GRAVITY        : float = 900.0
const MAX_FALL_SPEED : float = 600.0

# ── Shooting ─────────────────────────────────────────────────────────────
const PROJECTILE_SCENE : String = "res://player/Projectile.tscn"
var _projectile_packed : PackedScene

# ── Nodes ────────────────────────────────────────────────────────────────
@onready var sprite            : AnimatedSprite2D = $AnimatedSprite2D
@onready var shoot_point       : Marker2D         = $ShootPoint
@onready var coyote_timer      : Timer            = $CoyoteTimer
@onready var jump_buffer_timer : Timer            = $JumpBufferTimer
@onready var invincibility_timer : Timer          = $InvincibilityTimer
@onready var hurt_flash_timer  : Timer            = $HurtFlashTimer

# ── State ────────────────────────────────────────────────────────────────
var _is_invincible  : bool = false
var _facing_right   : bool = true
var _was_on_floor   : bool = false

# ── Shoot cooldown ───────────────────────────────────────────────────────
const SHOOT_COOLDOWN : float = 0.25
var _shoot_timer    : float = 0.0

# ── Respawn ──────────────────────────────────────────────────────────────
var _spawn_position : Vector2 = Vector2.ZERO

# ────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_projectile_packed = load(PROJECTILE_SCENE)
	_spawn_position    = global_position
	# Connect GameManager signals
	GameManager.connect("game_over", _on_game_over)

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_coyote_jump()
	_handle_movement()
	_handle_shooting(delta)
	_animate()
	move_and_slide()
	_check_fell_off_screen()

# ── Gravity ──────────────────────────────────────────────────────────────
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = min(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
	else:
		if not _was_on_floor:
			# Just landed
			pass
	_was_on_floor = is_on_floor()

# ── Coyote Time + Jump Buffer ─────────────────────────────────────────────
func _handle_coyote_jump() -> void:
	# Start coyote window when player walks off an edge
	if _was_on_floor and not is_on_floor():
		coyote_timer.start()

	# Jump input buffering
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer.start()

	# Execute jump if on floor, coyote window, or buffer active
	var can_jump := is_on_floor() or not coyote_timer.is_stopped()
	if not jump_buffer_timer.is_stopped() and can_jump:
		velocity.y = JUMP_VELOCITY
		coyote_timer.stop()
		jump_buffer_timer.stop()
		AudioManager.play_sfx("jump")

	# Variable jump height — release early for smaller hop
	if Input.is_action_just_released("jump") and velocity.y < JUMP_VELOCITY * 0.5:
		velocity.y = JUMP_VELOCITY * 0.5

# ── Horizontal Movement ───────────────────────────────────────────────────
func _handle_movement() -> void:
	var dir := Input.get_axis("move_left", "move_right")
	velocity.x = dir * SPEED
	if dir != 0.0:
		_facing_right = dir > 0.0
		shoot_point.position.x = abs(shoot_point.position.x) * sign(dir)

# ── Shooting ──────────────────────────────────────────────────────────────
func _handle_shooting(delta: float) -> void:
	_shoot_timer = max(_shoot_timer - delta, 0.0)
	if Input.is_action_just_pressed("shoot") and _shoot_timer <= 0.0:
		_fire_projectile()
		_shoot_timer = SHOOT_COOLDOWN

func _fire_projectile() -> void:
	var p : Node2D = _projectile_packed.instantiate()
	get_parent().add_child(p)
	p.global_position = shoot_point.global_position
	p.direction = Vector2.RIGHT if _facing_right else Vector2.LEFT
	AudioManager.play_sfx("shoot")

# ── Animation ─────────────────────────────────────────────────────────────
func _animate() -> void:
	sprite.flip_h = not _facing_right
	if not is_on_floor():
		sprite.play("jump" if velocity.y < 0 else "fall")
	elif abs(velocity.x) > 10.0:
		sprite.play("run")
	else:
		sprite.play("idle")

# ── Damage ────────────────────────────────────────────────────────────────
func take_damage(amount: int = 1) -> void:
	if _is_invincible:
		return
	GameManager.take_damage(amount)
	AudioManager.play_sfx("player_hit")
	_start_invincibility()

func _start_invincibility() -> void:
	_is_invincible = true
	invincibility_timer.start()
	_flash_hurt()

func _flash_hurt() -> void:
	sprite.modulate = Color(1, 0.3, 0.3)
	hurt_flash_timer.start()

func _on_hurt_flash_timer_timeout() -> void:
	sprite.modulate = Color.WHITE

func _on_invincibility_timer_timeout() -> void:
	_is_invincible = false

# ── Death / Respawn ───────────────────────────────────────────────────────
func _check_fell_off_screen() -> void:
	if global_position.y > get_viewport_rect().size.y + 200:
		_die()

func _die() -> void:
	AudioManager.play_sfx("player_death")
	# GameManager handles life deduction and game_over signal
	GameManager.take_damage(GameManager.health)  # kill instantly

func respawn() -> void:
	var cp := GameManager.checkpoint_pos
	global_position = cp if cp != Vector2.ZERO else _spawn_position
	velocity = Vector2.ZERO
	_is_invincible = false
	sprite.modulate = Color.WHITE

func _on_game_over() -> void:
	# Handled by UI — change scene to game-over screen
	get_tree().change_scene_to_file("res://ui/GameOver.tscn")
