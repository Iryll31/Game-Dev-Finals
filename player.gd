extends CharacterBody2D

# -- Movement Constants ---------------------------------------------------
const SPEED          : float = 130.0
const JUMP_VELOCITY  : float = -350.0
const GRAVITY        : float = 900.0
const MAX_FALL_SPEED : float = 600.0

# -- Shooting -------------------------------------------------------------
const PROJECTILE_SCENE : String = "res://player/Projectile.tscn"
var _projectile_packed : PackedScene

# -- Nodes ----------------------------------------------------------------
@onready var animated_sprite_2d : AnimatedSprite2D = $AnimatedSprite2D
@onready var shoot_point        : Marker2D         = $ShootPoint
@onready var coyote_timer       : Timer            = $CoyoteTimer
@onready var jump_buffer_timer  : Timer            = $JumpBufferTimer
@onready var invincibility_timer: Timer            = $InvicibilityTimer
@onready var hurt_flash_timer   : Timer            = $HurtFlashTimer

# -- State ----------------------------------------------------------------
var _is_invincible : bool = false
var _facing_right  : bool = true
var _was_on_floor  : bool = false

# -- Shoot cooldown -------------------------------------------------------
const SHOOT_COOLDOWN : float = 0.25
var _shoot_timer    : float = 0.0

# -- Respawn --------------------------------------------------------------
var _spawn_position : Vector2 = Vector2.ZERO

func _ready() -> void:
    _spawn_position = global_position
    if ResourceLoader.exists(PROJECTILE_SCENE):
        _projectile_packed = load(PROJECTILE_SCENE)
    if hurt_flash_timer != null and not hurt_flash_timer.is_connected("timeout", self, "_on_hurt_flash_timer_timeout"):
        hurt_flash_timer.connect("timeout", self, "_on_hurt_flash_timer_timeout")
    if invincibility_timer != null and not invincibility_timer.is_connected("timeout", self, "_on_invincibility_timer_timeout"):
        invincibility_timer.connect("timeout", self, "_on_invincibility_timer_timeout")
    GameManager.connect("game_over", self, "_on_game_over")

func _physics_process(delta: float) -> void:
    _apply_gravity(delta)
    _handle_coyote_jump()
    _handle_movement()
    _handle_shooting(delta)
    _animate()
    move_and_slide()
    _check_fell_off_screen()

func _apply_gravity(delta: float) -> void:
    if not is_on_floor():
        velocity.y = min(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
    _was_on_floor = is_on_floor()

func _handle_coyote_jump() -> void:
    if _was_on_floor and not is_on_floor():
        coyote_timer.start()

    if Input.is_action_just_pressed("jump"):
        jump_buffer_timer.start()

    var can_jump := is_on_floor() or not coyote_timer.is_stopped()
    if not jump_buffer_timer.is_stopped() and can_jump:
        velocity.y = JUMP_VELOCITY
        coyote_timer.stop()
        jump_buffer_timer.stop()
        AudioManager.play_sfx("jump")

    if Input.is_action_just_released("jump") and velocity.y < JUMP_VELOCITY * 0.5:
        velocity.y = JUMP_VELOCITY * 0.5

func _handle_movement() -> void:
    var direction := Input.get_axis("move_left", "move_right")
    if direction != 0.0:
        velocity.x = direction * SPEED
        _facing_right = direction > 0.0
        shoot_point.position.x = abs(shoot_point.position.x) * sign(direction)
    else:
        velocity.x = move_toward(velocity.x, 0.0, SPEED)

func _handle_shooting(delta: float) -> void:
    _shoot_timer = max(_shoot_timer - delta, 0.0)
    if _projectile_packed and Input.is_action_just_pressed("shoot") and _shoot_timer <= 0.0:
        _fire_projectile()
        _shoot_timer = SHOOT_COOLDOWN

func _fire_projectile() -> void:
    var projectile := _projectile_packed.instantiate()
    get_parent().add_child(projectile)
    projectile.global_position = shoot_point.global_position
    projectile.direction = Vector2.RIGHT if _facing_right else Vector2.LEFT
    AudioManager.play_sfx("shoot")

func _animate() -> void:
    animated_sprite_2d.flip_h = not _facing_right
    if not is_on_floor():
        animated_sprite_2d.play("jump" if velocity.y < 0 else "fall")
    elif abs(velocity.x) > 10.0:
        animated_sprite_2d.play("walk")
    else:
        animated_sprite_2d.play("idle")

func take_damage(amount: int = 1) -> void:
    if _is_invincible:
        return
    GameManager.take_damage(amount)
    AudioManager.play_sfx("player_hit")
    _start_invincibility()

func _start_invincibility() -> void:
    _is_invincible = true
    if invincibility_timer != null:
        invincibility_timer.start()
    _flash_hurt()

func _flash_hurt() -> void:
    animated_sprite_2d.modulate = Color(1, 0.3, 0.3)
    if hurt_flash_timer != null:
        hurt_flash_timer.start()

func _on_hurt_flash_timer_timeout() -> void:
    animated_sprite_2d.modulate = Color.WHITE

func _on_invincibility_timer_timeout() -> void:
    _is_invincible = false

func _check_fell_off_screen() -> void:
    if global_position.y > get_viewport_rect().size.y + 200:
        _die()

func _die() -> void:
    AudioManager.play_sfx("player_death")
    GameManager.take_damage(GameManager.health)

func respawn() -> void:
    var checkpoint := GameManager.checkpoint_pos
    global_position = checkpoint if checkpoint != Vector2.ZERO else _spawn_position
    velocity = Vector2.ZERO
    _is_invincible = false
    animated_sprite_2d.modulate = Color.WHITE

func _on_game_over() -> void:
    get_tree().change_scene_to_file("res://ui/GameOver.tscn")
